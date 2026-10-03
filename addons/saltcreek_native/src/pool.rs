//! The plugin's worker threads: a few long-lived threads taking jobs off one queue. Jobs hold no
//! Godot objects; they put their result where the main thread polls for it.

use std::sync::mpsc::{channel, Receiver, Sender};
use std::sync::{Arc, Mutex, OnceLock};

type Job = Box<dyn FnOnce() + Send + 'static>;

struct Pool {
    queue: Mutex<Sender<Job>>,
    threads: usize,
}

static POOL: OnceLock<Pool> = OnceLock::new();

fn pool() -> &'static Pool {
    POOL.get_or_init(|| {
        // Leave the main thread its core: the game is pinned on one.
        let threads = std::thread::available_parallelism().map(|n| n.get()).unwrap_or(2).saturating_sub(1).clamp(1, 4);
        let (tx, rx) = channel::<Job>();
        let rx: Arc<Mutex<Receiver<Job>>> = Arc::new(Mutex::new(rx));
        for i in 0..threads {
            let rx = Arc::clone(&rx);
            std::thread::Builder::new()
                .name(format!("saltcreek-worker-{}", i))
                .spawn(move || loop {
                    let job = match rx.lock() {
                        Ok(r) => r.recv(),
                        Err(_) => return,
                    };
                    match job {
                        Ok(f) => f(),
                        Err(_) => return,
                    }
                })
                .expect("worker thread");
        }
        Pool { queue: Mutex::new(tx), threads }
    })
}

/// Run `f` on a worker.
pub fn submit(f: impl FnOnce() + Send + 'static) {
    let _ = pool().queue.lock().unwrap().send(Box::new(f));
}

pub fn threads() -> usize {
    pool().threads
}
