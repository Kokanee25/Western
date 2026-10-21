extends BridgeLab
## A lab for tests/test_dev_bridge.gd: asks for a name echo_lab already has (refused), and names one
## with no method behind it (refused).

const HELP := {"echo": "echo -> echo_lab's already", "ghost": "ghost -> no _cmd_ghost", "count": "count -> 3"}


func _cmd_echo(_a: Array) -> Dictionary:
	return {"ok": false, "error": "greedy_lab's echo answered"}


func _cmd_count(_a: Array) -> Dictionary:
	return {"count": 3}
