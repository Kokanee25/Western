"""Mantaflow's Python classes put back on their bases, so Blender's fluid scripts run in the pip bpy.

The pip `bpy` module (4.5 to 5.2, at least) registers every Mantaflow class with no base: its
`LevelsetGrid` is `(LevelsetGrid, object)`, so it has no `setConst` (a `Grid<Real>` method) and
every gas bake stops at once ("'LevelsetGrid' object has no attribute 'setConst'"). Blender's own
builds don't. The types are immutable, so their method resolution order is written in place (the
tuple attribute lookup and the methods' type checks both walk), from Mantaflow's class hierarchy.
Imported before a bake; does nothing where the classes already have their bases.
"""
import ctypes

import bpy  # noqa: F401  (loads the manta module)
import manta

# Mantaflow's classes and their parents (extern/mantaflow: grid.h, levelset.h, shapes.h, mesh.h).
PARENTS = {
    "GridBase": "PbClass", "Grid<Real>": "GridBase", "Grid<Vec3>": "GridBase", "Grid<int>": "GridBase",
    "LevelsetGrid": "Grid<Real>", "MACGrid": "Grid<Vec3>", "FlagGrid": "Grid<int>",
    "FluidSolver": "PbClass", "Shape": "PbClass", "Box": "Shape", "Sphere": "Shape", "Cylinder": "Shape",
    "Slope": "Shape", "NullShape": "Shape", "Mesh": "PbClass",
}
_P = ctypes.sizeof(ctypes.c_void_p)
_MRO = 43 * _P  # PyTypeObject.tp_mro (CPython 3.11 to 3.13)
_keep = []


def _chain(name):
    return [getattr(manta, name)] + (_chain(PARENTS[name]) if name in PARENTS else [])


def relink():
    if manta.GridBase in manta.LevelsetGrid.__mro__:
        return False
    for name in PARENTS:
        t = getattr(manta, name)
        mro = tuple(_chain(name)) + (object,)
        slot = ctypes.c_void_p.from_address(id(t) + _MRO)
        assert slot.value == id(t.__mro__), "tp_mro isn't where this CPython keeps it"
        _keep.append(mro)
        slot.value = id(mro)
        ctypes.pythonapi.PyType_Modified(ctypes.py_object(t))
    return True


relink()
