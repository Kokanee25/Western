class_name TestCase
extends Node
## Base class for headless tests. Methods named test_* run in file order; they may await.
## Run everything with:  godot --headless --fixed-fps 60 -s res://tests/run_tests.gd

var current_test := ""
var failures: Array[String] = []


## Called before and after each test. Override; may await.
func before_each() -> void:
	pass


func after_each() -> void:
	pass


func check(condition: bool, message: String) -> bool:
	if not condition:
		failures.append("%s: %s" % [current_test, message])
	return condition


func check_eq(actual: Variant, expected: Variant, message: String) -> bool:
	return check(actual == expected, "%s (expected %s, got %s)" % [message, expected, actual])


func check_near(actual: float, expected: float, tolerance: float, message: String) -> bool:
	return check(absf(actual - expected) <= tolerance, "%s (expected %.4f ± %.4f, got %.4f)" % [message, expected, tolerance, actual])


func physics_frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func process_frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


## Wait on physics frames until `condition` is true or `max_frames` pass. Returns whether it held.
func wait_until(condition: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if condition.call():
			return true
		await get_tree().physics_frame
	return condition.call()
