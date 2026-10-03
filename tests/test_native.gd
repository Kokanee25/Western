extends TestCase
## The native plugin (addons/saltcreek_native, Rust) loads in Godot 4.7.2 and its worker-thread
## round trip works: a job runs off the main thread and its result comes back as mesh arrays
## Godot accepts. Needs the library in addons/saltcreek_native/bin (CI builds it; here:
## `cargo build --release` in that folder, then copy target/release/libsaltcreek_native.so in).


func test_the_native_plugin_is_loaded() -> void:
	check(ClassDB.class_exists(&"NativeBench"), "NativeBench is registered by addons/saltcreek_native (build it: cargo build --release there)")


func test_a_job_runs_on_a_worker_thread_and_comes_back_as_a_mesh() -> void:
	if not ClassDB.class_exists(&"NativeBench"):
		return
	var bench: Node = ClassDB.instantiate(&"NativeBench")
	get_tree().root.add_child(bench)
	check(String(bench.version()).begins_with("saltcreek_native"), "version %s" % bench.version())
	check(bench.threads() >= 1, "threads %d" % bench.threads())
	check(bench.start_sphere(0.25, 64.0, 0.1), "a job starts")
	check(not bench.start_sphere(0.25, 64.0, 0.1), "one job at a time")
	bench.wait()
	check(bench.done(), "done after wait")
	var arrays: Array = bench.mesh_arrays()
	check_eq(arrays.size(), 3, "vertex, normal, colour arrays")
	var verts: PackedVector3Array = arrays[0]
	check(verts.size() > 0 and verts.size() % 3 == 0, "triangles: %d vertices" % verts.size())
	var mesh := ArrayMesh.new()
	var a := []
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX] = arrays[0]
	a[Mesh.ARRAY_NORMAL] = arrays[1]
	a[Mesh.ARRAY_COLOR] = arrays[2]
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	check_eq(mesh.get_surface_count(), 1, "Godot builds a mesh from the job's arrays")
	# A 0.25 m sphere at 64 cubes a metre is ~17,200 cubes; the bite takes some.
	check(bench.voxels() > 12000 and bench.voxels() < 17500, "voxels %d" % bench.voxels())
	check(bench.millis() > 0.0, "the worker's time is measured: %.1f ms" % bench.millis())
	bench.queue_free()
