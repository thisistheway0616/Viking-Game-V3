extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


const SPEED = 200.0
const JUMP_VELOCITY = -600.0
var attack_hold_timer: float = 0.0
const HEAVY_ATTACK_THRESHOLD: float = 0.3
var is_charging_attack: bool = false
var is_attacking: bool = false
var max_health: int = 3
var current_health: int = max_health
var is_dead: bool = false
var spawn_position: Vector2

func _ready():
	spawn_position = global_position

func _physics_process(delta: float) -> void:
	if not is_attacking:
		if not is_on_floor():
			animated_sprite_2d.play("jump")
		elif abs(velocity.x) > 1:
			animated_sprite_2d.play("walk")
		else:
			animated_sprite_2d.play("idle")
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Add animation

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	#Attacking
	#Left Mouse Click Hold Logic
	if Input.is_action_just_pressed("light_attack"):
		is_charging_attack = true
		attack_hold_timer = 0.0
	
	if is_charging_attack:
		attack_hold_timer += delta
		print("Timer: ", attack_hold_timer)
		
		if Input.is_action_just_released("light_attack"):
			print("Realeased! Final Time: ", attack_hold_timer)
			if attack_hold_timer >= HEAVY_ATTACK_THRESHOLD:
				perform_heavy_attack()
			else:
				perform_light_attack()
			is_charging_attack = false
	
	if Input.is_action_just_released("light_attack") and is_charging_attack and not is_attacking:
		perform_light_attack()
		is_charging_attack = false
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	if direction == 1.0:
		animated_sprite_2d.flip_h = false
	elif direction == -1.0:
		animated_sprite_2d.flip_h = true
func perform_light_attack():
	is_attacking = true
	print("Light Attack Triggered")
	animated_sprite_2d.play("light_attack")
	await animated_sprite_2d.animation_finished
	is_attacking = false
func perform_heavy_attack():
	is_attacking = true
	print("Heavy Attack Triggered")
	animated_sprite_2d.play("heavy_attack")
	await animated_sprite_2d.animation_finished
	is_attacking = false
func take_damage(amount: int):
	if is_dead or is_attacking:
		return
		
	current_health -= amount
	print("player hit! Health: ", current_health)
	
	if current_health <= 0:
		die()
	else:
		handle_hit_state()
func handle_hit_state():
	is_attacking = true
	velocity = Vector2.ZERO
	animated_sprite_2d.play("hit")
	
	await get_tree().create_timer(0.5).timeout
	
	is_attacking = false
	print("back in action!")
func die():
	is_dead = true
	is_attacking = true
	velocity = Vector2.ZERO
	animated_sprite_2d.play("death")
	await animated_sprite_2d.animation_finished
	respawn_player()
func respawn_player():
	current_health = max_health
	is_dead = false
	is_attacking = false
	global_position = spawn_position
	set_physics_process(true)
	animated_sprite_2d.play("idle")
