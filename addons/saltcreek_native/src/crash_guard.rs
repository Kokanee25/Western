//! The crash and freeze reports' native half (issue #624; the game's half is
//! src/debug/crash_reports.gd). Everything here works where the game's own code can't: on a thread
//! of its own, or inside a crash handler, with nothing of Godot's touched.
//!
//! - **Crashes.** Linux: a signal handler (SIGSEGV, SIGBUS, SIGILL, SIGFPE, SIGABRT) writes
//!   `crash.txt` (the signal, the address, which thread died) with plain system calls, then hands the
//!   signal to the handler that was there before (Godot's, which prints the backtrace and the
//!   GDScript one into the log). Windows: a vectored exception handler, for the fatal codes only,
//!   writes `crash.txt` and a minidump `crash.dmp` (`MiniDumpWriteDump`, written by the watchdog's
//!   thread while the dead one waits, so a stack overflow still gets one), then lets the exception
//!   go on to Godot's handler and Windows. A panic in this plugin writes `panic.txt` first (a Rust
//!   abort on Windows goes past every handler).
//! - **Freezes.** A watchdog thread: when the main thread hasn't finished a frame (`beat`) for
//!   `freeze_s` (5 s) it writes `freeze.txt` (how long, what part of the frame it was in, every
//!   thread: on Linux their states and, with gdb there, their stacks; on Windows the minidump
//!   `freeze.dmp`). If the frame comes back, `freeze.txt` says after how long (a stall; the game
//!   packs it, `recovered`). Still frozen at `end_s` (60 s) it ends the process: the main thread is
//!   made to crash (Linux a SIGSEGV sent to it, Windows its next instruction moved to a bad write)
//!   so Godot's handler prints where it was, GDScript included, and 10 s later the process is
//!   ended outright. Loading (`loading`) stands it down: a load gets `load_s` (300 s) before it
//!   counts as a freeze. It counts nothing before the first beat (the game's own start).
//!
//! An earlier watchdog for the soak was a GDScript thread (2026-10-13): it went silent with the
//! game (soaks #10-12). A GDScript thread runs through the engine (its calls, its prints, the
//! script language's locks), so a main thread stuck in the engine can hold it too; this thread
//! touches only the system.

use godot::prelude::*;
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, AtomicI64, AtomicU32, AtomicU64, Ordering};
use std::sync::{Mutex, OnceLock};
use std::thread::JoinHandle;
use std::time::{Duration, Instant};

static START: OnceLock<Instant> = OnceLock::new();
/// When the last frame ended (ms since START; 0: no frame yet).
static LAST_BEAT: AtomicU64 = AtomicU64::new(0);
/// What the main thread was last doing (PHASES).
static PHASE: AtomicU32 = AtomicU32::new(0);
static LOADING: AtomicI64 = AtomicI64::new(0);
static ON: AtomicBool = AtomicBool::new(false);
static ENDING: AtomicBool = AtomicBool::new(false);
static CRASHED: AtomicBool = AtomicBool::new(false);
static RECOVERED: AtomicBool = AtomicBool::new(false);
static FREEZE_MS: AtomicU64 = AtomicU64::new(5000);
static END_MS: AtomicU64 = AtomicU64::new(60000);
static LOAD_MS: AtomicU64 = AtomicU64::new(300000);
static MAIN_TID: AtomicU64 = AtomicU64::new(0);
/// Whether a freeze report asks gdb for the stacks (Linux; the tests leave it out: seconds each).
static STACKS: AtomicBool = AtomicBool::new(true);

/// The report folder as bytes (a C path on Linux, UTF-16 on Windows), set before the handlers are
/// armed and never moved after: the handlers read it with no lock.
const PATH_MAX: usize = 1024;
static mut DIR_BYTES: [u8; PATH_MAX] = [0; PATH_MAX];
static mut DIR_LEN: usize = 0;
#[cfg(windows)]
static mut DIR_WIDE: [u16; PATH_MAX] = [0; PATH_MAX];
#[cfg(windows)]
static mut DIR_WIDE_LEN: usize = 0;

struct Shared {
    dir: Option<PathBuf>,
    info: String,
    load_what: String,
    stop: bool,
    thread: Option<JoinHandle<()>>,
}

static SHARED: Mutex<Shared> =
    Mutex::new(Shared { dir: None, info: String::new(), load_what: String::new(), stop: false, thread: None });

const PHASES: [&str; 5] = [
    "before the first frame",
    "in a physics tick (a _physics_process, the physics step or what they wait on)",
    "in the frame's _process (scripts, the scene tree)",
    "after the frame's scripts: the draw, Godot's own work between frames",
    "loading",
];

fn ms() -> u64 {
    START.get_or_init(Instant::now).elapsed().as_millis() as u64
}

/// A fixed buffer to write a note into with no allocation (the crash handlers).
struct Buf {
    b: [u8; 2048],
    n: usize,
}

impl Buf {
    const fn new() -> Buf {
        Buf { b: [0; 2048], n: 0 }
    }
    fn s(&mut self, s: &str) -> &mut Buf {
        for &c in s.as_bytes() {
            if self.n < self.b.len() {
                self.b[self.n] = c;
                self.n += 1;
            }
        }
        self
    }
    fn u(&mut self, mut v: u64) -> &mut Buf {
        let mut d = [0u8; 20];
        let mut i = 20;
        loop {
            i -= 1;
            d[i] = b'0' + (v % 10) as u8;
            v /= 10;
            if v == 0 {
                break;
            }
        }
        for &c in &d[i..] {
            if self.n < self.b.len() {
                self.b[self.n] = c;
                self.n += 1;
            }
        }
        self
    }
    fn x(&mut self, v: u64) -> &mut Buf {
        self.s("0x");
        let mut started = false;
        for k in (0..16).rev() {
            let h = ((v >> (k * 4)) & 0xf) as u8;
            if h != 0 || started || k == 0 {
                started = true;
                let c = if h < 10 { b'0' + h } else { b'a' + h - 10 };
                if self.n < self.b.len() {
                    self.b[self.n] = c;
                    self.n += 1;
                }
            }
        }
        self
    }
    fn bytes(&self) -> &[u8] {
        &self.b[..self.n]
    }
}

/// The common lines of a crash note: when, what the main thread was doing, the build.
fn note_head(b: &mut Buf) {
    let now = ms();
    let beat = LAST_BEAT.load(Ordering::Relaxed);
    b.s("at ").u(now).s(" ms after the game started");
    if beat > 0 {
        b.s(", the last frame ended ").u(now.saturating_sub(beat)).s(" ms before");
    }
    b.s("\nthe main thread was ").s(PHASES[(PHASE.load(Ordering::Relaxed) as usize).min(PHASES.len() - 1)]).s("\n");
    if ENDING.load(Ordering::Relaxed) {
        b.s("(this is the watchdog ending a freeze: the main thread made to crash so Godot's handler prints where it was)\n");
    }
}

// --- Linux -----------------------------------------------------------------------------------

#[cfg(target_os = "linux")]
mod sys {
    use super::*;
    use std::fs;
    use std::mem::MaybeUninit;

    const SIGNALS: [i32; 5] = [libc::SIGSEGV, libc::SIGBUS, libc::SIGILL, libc::SIGFPE, libc::SIGABRT];
    static mut OLD: [MaybeUninit<libc::sigaction>; 5] = [MaybeUninit::uninit(); 5];
    static ARMED: AtomicBool = AtomicBool::new(false);

    pub fn tid() -> u64 {
        // SAFETY: a plain system call.
        unsafe { libc::syscall(libc::SYS_gettid) as u64 }
    }

    fn sig_name(sig: i32) -> &'static str {
        match sig {
            libc::SIGSEGV => "SIGSEGV (a bad memory access)",
            libc::SIGBUS => "SIGBUS (a bad memory access)",
            libc::SIGILL => "SIGILL (an illegal instruction)",
            libc::SIGFPE => "SIGFPE (an arithmetic fault)",
            libc::SIGABRT => "SIGABRT (abort: an assertion or a Rust panic)",
            _ => "a signal",
        }
    }

    /// Write `b` to DIR/name, from a signal handler (open, write, close only).
    unsafe fn write_file(name: &str, b: &[u8], append: bool) {
        let mut path = [0u8; PATH_MAX + 32];
        let n = DIR_LEN;
        if n == 0 {
            return;
        }
        std::ptr::copy_nonoverlapping(&raw const DIR_BYTES as *const u8, path.as_mut_ptr(), n);
        path[n] = b'/';
        let nb = name.as_bytes();
        path[n + 1..n + 1 + nb.len()].copy_from_slice(nb);
        path[n + 1 + nb.len()] = 0;
        let flags = libc::O_WRONLY | libc::O_CREAT | if append { libc::O_APPEND } else { libc::O_TRUNC };
        let fd = libc::open(path.as_ptr() as *const libc::c_char, flags, 0o644);
        if fd >= 0 {
            libc::write(fd, b.as_ptr() as *const libc::c_void, b.len());
            libc::close(fd);
        }
    }

    extern "C" fn handler(sig: i32, info: *mut libc::siginfo_t, ctx: *mut libc::c_void) {
        // SAFETY: only async-signal-safe calls (prctl, syscall, open/write/close, sigaction, raise);
        // the note's buffer is on this stack.
        unsafe {
            if ON.load(Ordering::Relaxed) && !CRASHED.swap(true, Ordering::SeqCst) {
                let mut b = Buf::new();
                b.s("crash: ").s(sig_name(sig));
                if !info.is_null() {
                    b.s(", address ").x((*info).si_addr() as u64);
                    if (*info).si_code <= 0 {
                        b.s(" (sent, not a fault)");
                    }
                }
                let mut name = [0u8; 17];
                libc::prctl(libc::PR_GET_NAME, name.as_mut_ptr() as libc::c_ulong, 0, 0, 0);
                let len = name.iter().position(|&c| c == 0).unwrap_or(16);
                let t = tid();
                b.s("\nthread ").u(t).s(" '").s(std::str::from_utf8(&name[..len]).unwrap_or("?")).s("'");
                b.s(if t == MAIN_TID.load(Ordering::Relaxed) { " (the main thread)\n" } else { " (not the main thread)\n" });
                note_head(&mut b);
                b.s("Godot's own handler follows: its backtrace, and the GDScript one, are in the log (godot.log)\n");
                write_file("crash.txt", b.bytes(), false);
            }
            // Hand it on: the handler that was there (Godot's) gets it as if this one never was.
            let i = SIGNALS.iter().position(|&s| s == sig).unwrap_or(0);
            libc::sigaction(sig, OLD[i].as_ptr(), std::ptr::null_mut());
            let old = &*OLD[i].as_ptr();
            if old.sa_sigaction == libc::SIG_DFL || old.sa_sigaction == libc::SIG_IGN || (*info).si_code <= 0 {
                // A sent signal isn't raised again by returning: raise it (blocked till we return).
                libc::raise(sig);
            } else if old.sa_flags & libc::SA_SIGINFO != 0 {
                let f: extern "C" fn(i32, *mut libc::siginfo_t, *mut libc::c_void) = std::mem::transmute(old.sa_sigaction);
                f(sig, info, ctx);
            } else {
                let f: extern "C" fn(i32) = std::mem::transmute(old.sa_sigaction);
                f(sig);
            }
        }
    }

    pub fn arm() {
        if ARMED.swap(true, Ordering::SeqCst) {
            return;
        }
        // SAFETY: sigaction with a handler that only makes system calls; OLD is written once here
        // before any of these signals can reach the new handler.
        unsafe {
            // gdb (the freeze report) may attach to this process from its child.
            libc::prctl(libc::PR_SET_PTRACER, libc::PR_SET_PTRACER_ANY as libc::c_ulong, 0, 0, 0);
            for (i, &sig) in SIGNALS.iter().enumerate() {
                let mut sa: libc::sigaction = std::mem::zeroed();
                sa.sa_sigaction = handler as *const () as usize;
                sa.sa_flags = libc::SA_SIGINFO | libc::SA_ONSTACK;
                libc::sigemptyset(&mut sa.sa_mask);
                libc::sigaction(sig, &sa, OLD[i].as_mut_ptr());
            }
        }
    }

    pub fn write_note(name: &str, text: &str, append: bool) {
        // SAFETY: open/write/close on the folder set at install.
        unsafe { write_file(name, text.as_bytes(), append) }
    }

    /// The handlers that were there put back (the library is about to unload: a signal after
    /// that would jump into nothing).
    pub fn disarm() {
        if !ARMED.swap(false, Ordering::SeqCst) {
            return;
        }
        // SAFETY: OLD holds what arm() replaced.
        unsafe {
            for (i, &sig) in SIGNALS.iter().enumerate() {
                libc::sigaction(sig, OLD[i].as_ptr(), std::ptr::null_mut());
            }
        }
    }

    /// Every thread: its name, state and wait channel, then gdb's backtraces if gdb is here.
    pub fn freeze_detail() -> String {
        let mut out = String::from("\n## Threads (/proc)\n");
        if let Ok(rd) = fs::read_dir("/proc/self/task") {
            let mut tids: Vec<u64> = rd.filter_map(|e| e.ok()?.file_name().to_str()?.parse().ok()).collect();
            tids.sort();
            for t in tids {
                let base = format!("/proc/self/task/{}", t);
                let comm = fs::read_to_string(format!("{}/comm", base)).unwrap_or_default();
                let stat = fs::read_to_string(format!("{}/stat", base)).unwrap_or_default();
                let state = stat.rsplit(") ").next().and_then(|s| s.split(' ').next()).unwrap_or("?").to_string();
                let wchan = fs::read_to_string(format!("{}/wchan", base)).unwrap_or_default();
                let main = if t == MAIN_TID.load(Ordering::Relaxed) { "  <- the main thread" } else { "" };
                out += &format!("{} {:<16} {} {}{}\n", t, comm.trim(), state, wchan.trim(), main);
            }
        }
        out += "\n## Stacks (gdb)\n";
        let pid = std::process::id().to_string();
        match std::process::Command::new("gdb")
            .args(["-p", &pid, "-batch", "-nx", "-ex", "set pagination off", "-ex", "thread apply all bt 40"])
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::piped())
            .spawn()
        {
            Ok(mut child) => {
                let t0 = Instant::now();
                loop {
                    match child.try_wait() {
                        Ok(Some(_)) => break,
                        Ok(None) if t0.elapsed() < Duration::from_secs(40) => std::thread::sleep(Duration::from_millis(100)),
                        _ => {
                            let _ = child.kill();
                            out += "(gdb took over 40 s: stopped)\n";
                            break;
                        }
                    }
                }
                if let Ok(o) = child.wait_with_output() {
                    out += &String::from_utf8_lossy(&o.stdout);
                    let err = String::from_utf8_lossy(&o.stderr);
                    if !err.trim().is_empty() {
                        out += "\n(gdb said)\n";
                        out += &err;
                    }
                }
            }
            Err(_) => out += "(no gdb here: the threads' states above only)\n",
        }
        out
    }

    pub fn freeze_dump() -> String {
        String::new()
    }

    /// The end of a freeze: SIGSEGV to the main thread, for Godot's handler's backtraces.
    pub fn make_main_crash() {
        // SAFETY: tgkill to this process's own main thread.
        unsafe {
            libc::syscall(libc::SYS_tgkill, libc::getpid(), MAIN_TID.load(Ordering::Relaxed) as libc::c_long, libc::SIGSEGV);
        }
    }

    pub fn end_now(code: i32) -> ! {
        // SAFETY: plain C calls.
        unsafe {
            libc::fflush(std::ptr::null_mut());
            libc::_exit(code)
        }
    }

    pub fn wait_crash(_ms: u32) -> bool {
        false
    }

    pub fn serve_crash() {}
}

// --- Windows ---------------------------------------------------------------------------------

#[cfg(windows)]
mod sys {
    use super::*;
    use std::sync::atomic::AtomicPtr;
    use windows_sys::Win32::Foundation::{CloseHandle, GENERIC_WRITE, HANDLE, INVALID_HANDLE_VALUE};
    use windows_sys::Win32::Storage::FileSystem::{
        CreateFileW, WriteFile, CREATE_ALWAYS, FILE_APPEND_DATA, FILE_ATTRIBUTE_NORMAL, FILE_SHARE_READ, OPEN_ALWAYS,
    };
    use windows_sys::Win32::System::Diagnostics::Debug::{
        AddVectoredExceptionHandler, GetThreadContext, RemoveVectoredExceptionHandler, MiniDumpWithIndirectlyReferencedMemory, MiniDumpWithThreadInfo,
        MiniDumpWithUnloadedModules, MiniDumpWriteDump, SetThreadContext, CONTEXT, CONTEXT_CONTROL_AMD64,
        EXCEPTION_POINTERS, MINIDUMP_EXCEPTION_INFORMATION,
    };
    use windows_sys::Win32::System::Threading::{
        CreateEventW, GetCurrentProcess, GetCurrentProcessId, GetCurrentThreadId, OpenThread, ResumeThread, SetEvent,
        SuspendThread, TerminateProcess, WaitForSingleObject, THREAD_GET_CONTEXT, THREAD_SET_CONTEXT,
        THREAD_SUSPEND_RESUME,
    };

    static ARMED: AtomicBool = AtomicBool::new(false);
    static VEH: AtomicPtr<core::ffi::c_void> = AtomicPtr::new(std::ptr::null_mut());
    static CRASH_EVENT: AtomicPtr<core::ffi::c_void> = AtomicPtr::new(std::ptr::null_mut());
    static DONE_EVENT: AtomicPtr<core::ffi::c_void> = AtomicPtr::new(std::ptr::null_mut());
    static CRASH_PTRS: AtomicPtr<EXCEPTION_POINTERS> = AtomicPtr::new(std::ptr::null_mut());
    static CRASH_TID: AtomicU32 = AtomicU32::new(0);

    pub fn tid() -> u64 {
        // SAFETY: a plain system call.
        unsafe { GetCurrentThreadId() as u64 }
    }

    unsafe fn open(name: &str, append: bool) -> HANDLE {
        let mut path = [0u16; PATH_MAX + 32];
        let n = DIR_WIDE_LEN;
        if n == 0 {
            return INVALID_HANDLE_VALUE;
        }
        std::ptr::copy_nonoverlapping(&raw const DIR_WIDE as *const u16, path.as_mut_ptr(), n);
        path[n] = b'\\' as u16;
        let mut k = n + 1;
        for c in name.encode_utf16() {
            path[k] = c;
            k += 1;
        }
        path[k] = 0;
        let (access, disp) = if append { (FILE_APPEND_DATA, OPEN_ALWAYS) } else { (GENERIC_WRITE, CREATE_ALWAYS) };
        CreateFileW(path.as_ptr(), access, FILE_SHARE_READ, std::ptr::null(), disp, FILE_ATTRIBUTE_NORMAL, std::ptr::null_mut())
    }

    unsafe fn write_file(name: &str, b: &[u8], append: bool) {
        let h = open(name, append);
        if h != INVALID_HANDLE_VALUE {
            let mut done = 0u32;
            WriteFile(h, b.as_ptr(), b.len() as u32, &mut done, std::ptr::null_mut());
            CloseHandle(h);
        }
    }

    pub fn write_note(name: &str, text: &str, append: bool) {
        // SAFETY: CreateFileW/WriteFile on the folder set at install.
        unsafe { write_file(name, text.as_bytes(), append) }
    }

    /// A minidump of the whole process (every thread's stack) to DIR/name.
    unsafe fn dump(name: &str, tid: u32, ptrs: *mut EXCEPTION_POINTERS) -> bool {
        let h = open(name, false);
        if h == INVALID_HANDLE_VALUE {
            return false;
        }
        let info = MINIDUMP_EXCEPTION_INFORMATION { ThreadId: tid, ExceptionPointers: ptrs, ClientPointers: 0 };
        let kind = MiniDumpWithThreadInfo | MiniDumpWithUnloadedModules | MiniDumpWithIndirectlyReferencedMemory;
        let ok = MiniDumpWriteDump(
            GetCurrentProcess(),
            GetCurrentProcessId(),
            h,
            kind,
            if ptrs.is_null() { std::ptr::null() } else { &info },
            std::ptr::null(),
            std::ptr::null(),
        );
        CloseHandle(h);
        ok != 0
    }

    fn fatal(code: i32) -> Option<&'static str> {
        Some(match code as u32 {
            0xC0000005 => "EXCEPTION_ACCESS_VIOLATION (a bad memory access)",
            0xC00000FD => "EXCEPTION_STACK_OVERFLOW",
            0xC000001D => "EXCEPTION_ILLEGAL_INSTRUCTION",
            0xC0000096 => "EXCEPTION_PRIV_INSTRUCTION",
            0xC0000094 => "EXCEPTION_INT_DIVIDE_BY_ZERO",
            0xC0000006 => "EXCEPTION_IN_PAGE_ERROR",
            0xC0000374 => "STATUS_HEAP_CORRUPTION",
            0xC000008C => "EXCEPTION_ARRAY_BOUNDS_EXCEEDED",
            _ => return None,
        })
    }

    unsafe extern "system" fn handler(ptrs: *mut EXCEPTION_POINTERS) -> i32 {
        const CONTINUE_SEARCH: i32 = 0;
        if ptrs.is_null() || (*ptrs).ExceptionRecord.is_null() {
            return CONTINUE_SEARCH;
        }
        let rec = &*(*ptrs).ExceptionRecord;
        let what = match fatal(rec.ExceptionCode) {
            Some(w) => w,
            None => return CONTINUE_SEARCH,
        };
        // A vectored handler sees an exception before anything handles it (first chance), and a
        // driver may take one and carry on: so up to three are noted, each over the one before
        // (the last before the process dies is the crash), and the watchdog isn't stopped by one.
        static NOTED: AtomicU32 = AtomicU32::new(0);
        if !ON.load(Ordering::Relaxed) || NOTED.fetch_add(1, Ordering::SeqCst) >= 3 {
            return CONTINUE_SEARCH;
        }
        let t = GetCurrentThreadId();
        let mut b = Buf::new();
        b.s("crash: ").s(what).s(" (").x(rec.ExceptionCode as u32 as u64).s(") at ").x(rec.ExceptionAddress as u64);
        if rec.ExceptionCode as u32 == 0xC0000005 && rec.NumberParameters >= 2 {
            b.s(if rec.ExceptionInformation[0] == 1 { ", writing " } else { ", reading " }).x(rec.ExceptionInformation[1] as u64);
        }
        b.s("\nthread ").u(t as u64);
        b.s(if t as u64 == MAIN_TID.load(Ordering::Relaxed) { " (the main thread)\n" } else { " (not the main thread)\n" });
        note_head(&mut b);
        b.s("crash.dmp has every thread's stack (python3 tools/crash_report.py FILE reads it); Godot's own handler's backtrace is in godot.log\n");
        b.s("(noted as it was raised: had the game gone on, something handled it and it wasn't the crash)\n");
        write_file("crash.txt", b.bytes(), false);
        // The dump from the watchdog's thread (this stack may be the one that overflowed); this one
        // waits for it. With no watchdog, from here.
        let ev = CRASH_EVENT.load(Ordering::SeqCst);
        let done = DONE_EVENT.load(Ordering::SeqCst);
        if !ev.is_null() && !done.is_null() {
            CRASH_PTRS.store(ptrs, Ordering::SeqCst);
            CRASH_TID.store(t, Ordering::SeqCst);
            SetEvent(ev);
            WaitForSingleObject(done, 30000);
        } else {
            dump("crash.dmp", t, ptrs);
        }
        CONTINUE_SEARCH
    }

    pub fn arm() {
        if ARMED.swap(true, Ordering::SeqCst) {
            return;
        }
        // SAFETY: plain system calls; the handler reads only atomics and DIR_WIDE (set before).
        unsafe {
            CRASH_EVENT.store(CreateEventW(std::ptr::null(), 0, 0, std::ptr::null()), Ordering::SeqCst);
            DONE_EVENT.store(CreateEventW(std::ptr::null(), 0, 0, std::ptr::null()), Ordering::SeqCst);
            VEH.store(AddVectoredExceptionHandler(1, Some(handler)), Ordering::SeqCst);
        }
    }

    /// The handler taken out (the library is about to unload).
    pub fn disarm() {
        if !ARMED.swap(false, Ordering::SeqCst) {
            return;
        }
        let h = VEH.swap(std::ptr::null_mut(), Ordering::SeqCst);
        if !h.is_null() {
            // SAFETY: the handle AddVectoredExceptionHandler gave.
            unsafe {
                RemoveVectoredExceptionHandler(h);
            }
        }
    }

    /// The watchdog's wait: true when a crash asks for its dump.
    pub fn wait_crash(ms: u32) -> bool {
        let ev = CRASH_EVENT.load(Ordering::SeqCst);
        if ev.is_null() {
            std::thread::sleep(Duration::from_millis(ms as u64));
            return false;
        }
        // SAFETY: a wait on our own event.
        unsafe { WaitForSingleObject(ev, ms) == 0 }
    }

    pub fn serve_crash() {
        // SAFETY: the dead thread waits on DONE_EVENT while this writes its dump.
        unsafe {
            dump("crash.dmp", CRASH_TID.load(Ordering::SeqCst), CRASH_PTRS.load(Ordering::SeqCst));
            let done = DONE_EVENT.load(Ordering::SeqCst);
            if !done.is_null() {
                SetEvent(done);
            }
        }
    }

    pub fn freeze_detail() -> String {
        String::from("\nEvery thread's stack is in freeze.dmp (python3 tools/crash_report.py FILE reads it).\n")
    }

    pub fn freeze_dump() -> String {
        // SAFETY: a dump of this process from this (the watchdog's) thread.
        if unsafe { dump("freeze.dmp", 0, std::ptr::null_mut()) } {
            "freeze.dmp written\n".into()
        } else {
            "freeze.dmp couldn't be written\n".into()
        }
    }

    extern "C" fn freeze_trap() -> ! {
        // SAFETY: deliberately not: a write to an address no one owns, so the exception handlers
        // (ours, then Godot's: its backtrace and the GDScript one) run on the main thread.
        unsafe {
            std::ptr::write_volatile(16 as *mut u64, 0);
        }
        loop {
            std::thread::park();
        }
    }

    /// The end of a freeze: the main thread's next instruction moved to `freeze_trap`.
    pub fn make_main_crash() {
        // SAFETY: the main thread is suspended while its context is changed; the new stack top is
        // below its own, aligned as after a call.
        unsafe {
            let h = OpenThread(THREAD_SUSPEND_RESUME | THREAD_GET_CONTEXT | THREAD_SET_CONTEXT, 0, MAIN_TID.load(Ordering::Relaxed) as u32);
            if h.is_null() {
                return;
            }
            if SuspendThread(h) != u32::MAX {
                let mut ctx: CONTEXT = std::mem::zeroed();
                ctx.ContextFlags = CONTEXT_CONTROL_AMD64;
                if GetThreadContext(h, &mut ctx) != 0 {
                    ctx.Rsp = ((ctx.Rsp - 512) & !15) - 8;
                    ctx.Rip = freeze_trap as *const () as usize as u64;
                    SetThreadContext(h, &ctx);
                }
                ResumeThread(h);
            }
            CloseHandle(h);
        }
    }

    pub fn end_now(code: i32) -> ! {
        // SAFETY: ending this process.
        unsafe {
            TerminateProcess(GetCurrentProcess(), code as u32);
        }
        loop {
            std::thread::park();
        }
    }
}

#[cfg(not(any(target_os = "linux", windows)))]
mod sys {
    use super::*;
    use std::fs;
    pub fn tid() -> u64 {
        0
    }
    pub fn arm() {}
    pub fn disarm() {}
    pub fn write_note(name: &str, text: &str, append: bool) {
        use std::io::Write;
        if let Some(d) = SHARED.lock().ok().and_then(|s| s.dir.clone()) {
            let mut o = fs::OpenOptions::new();
            o.create(true);
            if append {
                o.append(true);
            } else {
                o.write(true).truncate(true);
            }
            if let Ok(mut f) = o.open(d.join(name)) {
                let _ = f.write_all(text.as_bytes());
            }
        }
    }
    pub fn freeze_detail() -> String {
        String::new()
    }
    pub fn freeze_dump() -> String {
        String::new()
    }
    pub fn make_main_crash() {}
    pub fn end_now(code: i32) -> ! {
        std::process::exit(code)
    }
    pub fn wait_crash(ms: u32) -> bool {
        std::thread::sleep(Duration::from_millis(ms as u64));
        false
    }
    pub fn serve_crash() {}
}

// --- The watchdog ----------------------------------------------------------------------------

fn watch() {
    let mut reported_at: Option<u64> = None; // the beat the report was about
    loop {
        if sys::wait_crash(200) {
            sys::serve_crash();
            continue;
        }
        {
            let s = SHARED.lock().unwrap();
            if s.stop {
                return;
            }
        }
        if !ON.load(Ordering::Relaxed) || CRASHED.load(Ordering::Relaxed) {
            continue;
        }
        // The load first, then the frame: a load's end stamps the frame before it lowers the count,
        // so a count read as 0 comes with the end's stamp.
        let loading = LOADING.load(Ordering::SeqCst) > 0;
        let beat = LAST_BEAT.load(Ordering::SeqCst);
        if beat == 0 {
            continue; // the game's own start: nothing counts till its first frame
        }
        let now = ms();
        let since = now.saturating_sub(beat);
        if let Some(b) = reported_at {
            if beat != b {
                sys::write_note(
                    "freeze.txt",
                    &format!("\nrecovered: a frame finished again {:.1} s after the last one (a stall, not a freeze)\n", (beat - b) as f64 / 1000.0),
                    true,
                );
                RECOVERED.store(true, Ordering::SeqCst);
                reported_at = None;
                continue;
            }
            let end = END_MS.load(Ordering::Relaxed);
            let limit = if loading { LOAD_MS.load(Ordering::Relaxed) + end } else { end };
            if end > 0 && since >= limit {
                end_freeze(since);
            }
            continue;
        }
        let limit = if loading { LOAD_MS.load(Ordering::Relaxed) } else { FREEZE_MS.load(Ordering::Relaxed) };
        if since >= limit {
            report_freeze(since, loading);
            reported_at = Some(beat);
        }
    }
}

fn report_freeze(since: u64, loading: bool) {
    let (info, what) = {
        let s = SHARED.lock().unwrap();
        (s.info.clone(), s.load_what.clone())
    };
    let mut t = format!(
        "freeze: the main thread hasn't finished a frame for {:.1} s\n{}\nthe main thread is thread {}\nthe main thread was {}\n",
        since as f64 / 1000.0,
        info,
        MAIN_TID.load(Ordering::Relaxed),
        PHASES[(PHASE.load(Ordering::Relaxed) as usize).min(PHASES.len() - 1)]
    );
    if loading {
        t += &format!("it was loading ({}), past the {} s a load gets\n", what, LOAD_MS.load(Ordering::Relaxed) / 1000);
    }
    t += &format!(
        "the watchdog ends the process {} s after the last frame if it doesn't come back (its last act: the main thread made to crash, so Godot's handler prints its backtrace and the GDScript one in godot.log)\n",
        END_MS.load(Ordering::Relaxed) / 1000
    );
    sys::write_note("freeze.txt", &t, false);
    let mut more = sys::freeze_dump();
    if STACKS.load(Ordering::Relaxed) {
        more += &sys::freeze_detail();
    }
    sys::write_note("freeze.txt", &more, true);
}

fn end_freeze(since: u64) -> ! {
    ENDING.store(true, Ordering::SeqCst);
    sys::write_note(
        "freeze.txt",
        &format!("\nended: still frozen {:.0} s after the last frame; the main thread made to crash, then the process ended\n", since as f64 / 1000.0),
        true,
    );
    sys::make_main_crash();
    std::thread::sleep(Duration::from_secs(10));
    sys::write_note("freeze.txt", "the crash didn't end it in 10 s: ended outright\n", true);
    sys::end_now(124)
}

fn set_dir(dir: &str) {
    let b = dir.as_bytes();
    let n = b.len().min(PATH_MAX - 1);
    // SAFETY: written while the handlers are off (ON false), read only while ON.
    unsafe {
        let p = &raw mut DIR_BYTES;
        std::ptr::copy_nonoverlapping(b.as_ptr(), p as *mut u8, n);
        DIR_LEN = n;
        #[cfg(windows)]
        {
            let w: Vec<u16> = dir.replace('/', "\\").encode_utf16().take(PATH_MAX - 1).collect();
            let pw = &raw mut DIR_WIDE;
            std::ptr::copy_nonoverlapping(w.as_ptr(), pw as *mut u16, w.len());
            DIR_WIDE_LEN = w.len();
        }
    }
}

/// A panic anywhere in this plugin: a note first (on Windows a Rust abort passes every handler).
fn hook_panics() {
    static HOOKED: AtomicBool = AtomicBool::new(false);
    if HOOKED.swap(true, Ordering::SeqCst) {
        return;
    }
    let before = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |info| {
        if ON.load(Ordering::Relaxed) {
            let th = std::thread::current();
            sys::write_note(
                "panic.txt",
                &format!("panic in the native plugin, thread '{}' ({}): {}\n", th.name().unwrap_or("?"), sys::tid(), info),
                true,
            );
        }
        before(info);
    }));
}

#[derive(GodotClass)]
#[class(init, base = RefCounted)]
pub struct CrashGuard {
    base: Base<RefCounted>,
}

#[godot_api]
impl CrashGuard {
    /// Arm the handlers and start the watchdog, reports into `dir` (an absolute folder that
    /// exists), `info` at the top of a freeze report (the build). Call from the main thread.
    /// Again with another folder: the reports go there (the tests).
    #[func]
    fn install(dir: GString, info: GString) -> bool {
        START.get_or_init(Instant::now);
        ON.store(false, Ordering::SeqCst);
        set_dir(&dir.to_string());
        MAIN_TID.store(sys::tid(), Ordering::SeqCst);
        LAST_BEAT.store(0, Ordering::SeqCst);
        CRASHED.store(false, Ordering::SeqCst);
        RECOVERED.store(false, Ordering::SeqCst);
        ENDING.store(false, Ordering::SeqCst);
        {
            let mut s = SHARED.lock().unwrap();
            s.dir = Some(PathBuf::from(dir.to_string()));
            s.info = info.to_string();
            s.stop = false;
            if s.thread.is_none() {
                s.thread = std::thread::Builder::new().name("saltcreek-crash-watchdog".into()).spawn(watch).ok();
            }
        }
        sys::arm();
        hook_panics();
        ON.store(true, Ordering::SeqCst);
        true
    }

    /// The thresholds, seconds: a freeze report after `freeze_s` without a frame, the process
    /// ended after `end_s` (0: never), a load given `load_s`.
    #[func]
    fn configure(freeze_s: f64, end_s: f64, load_s: f64) {
        FREEZE_MS.store((freeze_s.max(0.05) * 1000.0) as u64, Ordering::SeqCst);
        END_MS.store((end_s.max(0.0) * 1000.0) as u64, Ordering::SeqCst);
        LOAD_MS.store((load_s.max(0.0) * 1000.0) as u64, Ordering::SeqCst);
    }

    /// Whether a freeze report takes every thread's stack (gdb on Linux: seconds; the tests don't).
    #[func]
    fn set_stacks(on: bool) {
        STACKS.store(on, Ordering::SeqCst);
    }

    /// Stop watching (the handlers stay but only hand on); the thread is joined.
    #[func]
    fn uninstall() {
        ON.store(false, Ordering::SeqCst);
        stop_thread();
    }

    #[func]
    fn installed() -> bool {
        ON.load(Ordering::SeqCst)
    }

    /// The frame finished (the last thing in the frame's scripts).
    #[func]
    fn beat(&self) {
        LAST_BEAT.store(ms().max(1), Ordering::Relaxed);
        PHASE.store(3, Ordering::Relaxed);
    }

    /// What the main thread is in now: 1 a physics tick, 2 the frame's _process.
    #[func]
    fn phase(&self, p: i32) {
        PHASE.store(p.clamp(0, 4) as u32, Ordering::Relaxed);
    }

    /// A load starts (`on`, `what` it is) or ends: while one runs the watchdog waits `load_s`.
    /// Its end counts as a frame.
    #[func]
    fn loading(on: bool, what: GString) {
        if on {
            if LOADING.fetch_add(1, Ordering::SeqCst) == 0 {
                SHARED.lock().unwrap().load_what = what.to_string();
            }
            PHASE.store(4, Ordering::Relaxed);
        } else {
            // The frame stamped first: between the two the watchdog would see no load and a long
            // gap since the last frame.
            if LAST_BEAT.load(Ordering::SeqCst) > 0 {
                LAST_BEAT.store(ms().max(1), Ordering::SeqCst);
            }
            let left = LOADING.fetch_sub(1, Ordering::SeqCst) - 1;
            if left <= 0 {
                LOADING.store(0, Ordering::SeqCst);
            }
        }
    }

    #[func]
    fn is_loading() -> bool {
        LOADING.load(Ordering::SeqCst) > 0
    }

    /// A freeze report was written and the frames came back since (a stall); reading it clears it.
    #[func]
    fn take_recovered() -> bool {
        RECOVERED.swap(false, Ordering::SeqCst)
    }

    /// Write a note into the report folder (the game's black box can't from a crash).
    #[func]
    fn note(name: GString, text: GString, append: bool) {
        sys::write_note(&name.to_string(), &text.to_string(), append);
    }

    /// Crash on purpose, for trying the reports (`--crash-at`): `how` segv (a bad write on this
    /// thread), thread (the same on a thread of the plugin's own), panic (a Rust panic: caught by
    /// gdext and reported, not fatal), abort.
    #[func]
    fn crash_now(how: GString) {
        let how = how.to_string();
        match how.as_str() {
            "panic" => panic!("crash_now(panic): a panic on purpose (--crash-at)"),
            "abort" => std::process::abort(),
            "thread" => {
                let _ = std::thread::Builder::new().name("saltcreek-crash-test".into()).spawn(|| bad_write()).map(|h| h.join());
            }
            _ => bad_write(),
        }
    }
}

#[inline(never)]
fn bad_write() {
    // SAFETY: deliberately not (crash_now): a write to an address no one owns.
    unsafe {
        std::ptr::write_volatile(std::hint::black_box(8usize) as *mut u64, 0xdead);
    }
}

fn stop_thread() {
    let handle = {
        let mut s = SHARED.lock().unwrap();
        s.stop = true;
        s.thread.take()
    };
    if let Some(h) = handle {
        let _ = h.join();
    }
}

/// The library unloads (lib.rs): the watchdog's thread ends and the handlers go first.
pub fn stand_down() {
    ON.store(false, Ordering::SeqCst);
    stop_thread();
    sys::disarm();
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn buf_writes_numbers() {
        let mut b = Buf::new();
        b.s("a ").u(0).s(" ").u(1234567).s(" ").x(0xdeadbeef).s(" ").x(0);
        assert_eq!(std::str::from_utf8(b.bytes()).unwrap(), "a 0 1234567 0xdeadbeef 0x0");
    }
}
