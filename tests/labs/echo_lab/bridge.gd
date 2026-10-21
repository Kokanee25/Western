extends BridgeLab
## A lab for tests/test_dev_bridge.gd: its own commands, one that takes game time, one the bridge
## already has (refused).

const HELP := {
	"echo": "echo WORDS -> the words back",
	"later": "later SECONDS -> answers after that much game time",
	"ping": "ping -> taken by the bridge: refused",
}


func _cmd_echo(a: Array) -> Dictionary:
	log_event("echo", " ".join(a))
	return {"said": " ".join(a), "player_at": arr(player.global_position)}


func _cmd_later(a: Array) -> Dictionary:
	await seconds(float(a[0]))
	return {"waited": float(a[0])}


func _cmd_ping(_a: Array) -> Dictionary:
	return {"ok": false, "error": "a lab's ping answered"}
