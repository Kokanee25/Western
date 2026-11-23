"""A stand-in for numba where it can't be installed (PyPI refused in the cloud workspace, #938):
`njit` gives the function back, so the sound lab's models run as plain Python (the fiddle ~4 s an
audio second; piano.py swaps its partials' loop for numpy when it sees STANDIN). Use it only to
render: PYTHONPATH=tools/band/nonumba python3 tools/band/render_band.py <tune>."""
STANDIN = True


def njit(*a, **k):
    if len(a) == 1 and callable(a[0]) and not k:
        return a[0]
    return lambda f: f


prange = range
