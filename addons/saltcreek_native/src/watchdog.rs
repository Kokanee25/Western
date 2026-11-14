//! The last layer of the game's quit (issue #435; GameQuit in src/main/game_quit.gd). Godot's
//! worker pool can hang in `Main::cleanup`: `exit_languages_threads` waits for every pool thread to
//! count itself idle, and two low-priority tasks overlapping at that switch leave the idle threads
//! uncounted for good (issue #392; `core/object/worker_thread_pool.cpp`, `_handle_runlevel`). The
//! game waits out its own tasks before it quits, but the engine's own (the pipeline cache's save)
//! can make the pair. So when the game asks to quit it arms this: a plain thread that, if the
//! process is still shutting down `seconds` after the shutdown began (`begin_count`: GameQuit calls
//! it as the scene tree's root leaves the tree, in `SceneTree::finalize` after the last frame),
//! flushes stdout and ends the process with the quit's exit code; and BACKSTOP_S after the quit was
//! asked whatever happens (a last frame that never ends). The cleanup that hangs comes after the
//! scene tree is freed and before the extensions' Scene level is deinitialised (main.cpp 4.7.2),
//! so a quit that gets that far stands the watchdog down (`stand_down`, from lib.rs) and joins its
//! thread before the library unloads. The count doesn't start at the quit: a drawn frame under
//! software Vulkan takes seconds, and the frame the quit is asked in is still drawn first (gdext's
//! MainLoop stage goes down only just before the Scene level, too late to start it).

use godot::prelude::*;
use std::sync::{Condvar, Mutex};
use std::thread::JoinHandle;
use std::time::{Duration, Instant};

extern "C" {
    fn fflush(stream: *mut std::ffi::c_void) -> i32;
    #[cfg(not(windows))]
    fn _exit(code: i32) -> !;
}

// Windows: ending the process outright. Its CRT's `_exit` still goes through ExitProcess, which
// runs every DLL's detach (the graphics driver's too) and can stall in turn.
#[cfg(windows)]
extern "system" {
    fn GetCurrentProcess() -> *mut std::ffi::c_void;
    fn TerminateProcess(process: *mut std::ffi::c_void, code: u32) -> i32;
}

/// Flush C's stdout (Godot prints through it) and end the process with `code`, now.
fn end_now(code: i32) -> ! {
    // SAFETY: plain C and system calls; nothing of Godot's is touched from this thread.
    unsafe {
        fflush(std::ptr::null_mut());
        #[cfg(windows)]
        {
            TerminateProcess(GetCurrentProcess(), code as u32);
            loop {
                std::thread::park();
            }
        }
        #[cfg(not(windows))]
        _exit(code)
    }
}

const BACKSTOP_S: f64 = 60.0;

struct State {
    down: bool,
    /// When to end the process (the backstop until the cleanup begins).
    deadline: Option<Instant>,
    seconds: f64,
    cleanup_from: Option<Instant>,
    thread: Option<JoinHandle<()>>,
}

static STATE: Mutex<State> = Mutex::new(State { down: false, deadline: None, seconds: 0.0, cleanup_from: None, thread: None });
static WAKE: Condvar = Condvar::new();

#[derive(GodotClass)]
#[class(init, base = RefCounted)]
pub struct QuitWatchdog {
    base: Base<RefCounted>,
}

#[godot_api]
impl QuitWatchdog {
    /// End the process with `code` if Godot's cleanup is still running `seconds` after it began
    /// (once; later calls are ignored). Call it just before `SceneTree.quit(code)`.
    #[func]
    fn arm(seconds: f64, code: i32) {
        let mut state = STATE.lock().unwrap();
        if state.thread.is_some() || state.down {
            return;
        }
        state.seconds = seconds.max(0.0);
        state.deadline = Some(Instant::now() + Duration::from_secs_f64(BACKSTOP_S));
        state.thread = std::thread::Builder::new()
            .name("saltcreek-quit-watchdog".into())
            .spawn(move || {
                let mut state = STATE.lock().unwrap();
                while !state.down {
                    let now = Instant::now();
                    let until = state.deadline.unwrap_or(now);
                    if now >= until {
                        let what = match state.cleanup_from {
                            Some(t) => format!("{:.1} s after the scene tree went", (now - t).as_secs_f64()),
                            None => format!("{:.0} s after the quit, the scene tree still up", BACKSTOP_S),
                        };
                        eprintln!("[quit] still shutting down {}: ending the process (exit {}), issue #435", what, code);
                        end_now(code);
                    }
                    state = WAKE.wait_timeout(state, until - now).unwrap().0;
                }
            })
            .ok();
    }

    /// Whether a quit armed it (for the tests).
    #[func]
    fn armed() -> bool {
        STATE.lock().unwrap().thread.is_some()
    }

    /// The shutdown has begun (the scene tree's root leaving it): the count starts.
    #[func]
    fn begin_count() {
        start_count();
    }
}

fn start_count() {
    let mut state = STATE.lock().unwrap();
    let now = Instant::now();
    state.cleanup_from = Some(now);
    if state.thread.is_some() {
        let by = now + Duration::from_secs_f64(state.seconds);
        state.deadline = Some(state.deadline.map_or(by, |d| d.min(by)));
        WAKE.notify_all();
    }
}

/// The quit got past the cleanup that can hang: stop the watchdog and wait for its thread to end.
pub fn stand_down() {
    let (handle, took) = {
        let mut state = STATE.lock().unwrap();
        state.down = true;
        (state.thread.take(), state.cleanup_from.map(|t| t.elapsed().as_secs_f64()))
    };
    WAKE.notify_all();
    if let Some(h) = handle {
        let _ = h.join();
        if let Some(s) = took {
            eprintln!("[quit] the shutdown reached the extensions {:.2} s after the scene tree went (watchdog stood down)", s);
        }
    }
}
