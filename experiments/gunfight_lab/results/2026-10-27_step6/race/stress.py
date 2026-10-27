import multiprocessing, time, sys
def burn(end):
    while time.time() < end: pass
end = time.time() + float(sys.argv[1])
ps = [multiprocessing.Process(target=burn, args=(end,)) for _ in range(int(sys.argv[2]))]
[p.start() for p in ps]; [p.join() for p in ps]
