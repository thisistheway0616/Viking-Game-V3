extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer

var health: int = 5
var is_dead: bool = false
var player_in_range = null
var is_stunned: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_dead or is_stunned:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	move_and_slide()
	
# Hit by player logic
func take_damage(amount: int) -> void:
	if is_dead:
		return
		
	health -= amount
	print("Enemy hit! Health Remaining:", health)
	
	if health <= 0:
		die()
	else:
		handle_hit_animation()
		
func handle_hit_animation() -> void:
	is_stunned = true
	animated_sprite_2d.play("hit")
	velocity.x = 0
	await animated_sprite_2d.animation_finished
	if not is_dead:
		is_stunned = false
		animated_sprite_2d.play("idle")
func die() -> void:
	is_dead = true
	print("Enemy Died!")
	animated_sprite_2d.play("death")
	await animated_sprite_2d.animation_finished
	queue_free() # Removes enemy from the game


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body != self:
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
