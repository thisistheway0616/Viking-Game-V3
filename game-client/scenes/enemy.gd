extends Node2D
var player_in_range = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		player_in_range = body
		body.take_damage(1)
		$Timer.start(0)
	pass # Replace with function body.


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
		$Timer.stop()
	pass # Replace with function body.


func _on_timer_timeout() -> void:
	if player_in_range:
		player_in_range.take_damage(1)
	pass # Replace with function body.
