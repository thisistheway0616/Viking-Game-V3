extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var shape_cast: ShapeCast2D = $ShapeCast2D

const SPEED = 50.0
const JUMP_VELOCITY = -450.0
const HEAVY_ATTACK_THRESHOLD: float = 0.3
const HEAVY_ATTACK_DELAY = 0.28
const LIGHT_ATTACK_DELAY = 0.1

# Combo Variables
var combo_count: int = 0
var combo_timer: float = 0.0
const COMBO_RESET_TIME: float = 0.8

# Damage Values
const LIGHT_DAMAGE = 1
const HEAVY_DAMAGE = 3

var attack_hold_timer: float = 0.0
var is_charging_attack: bool = false
var is_attacking: bool = false
var is_dead: bool = false
var current_attack_damage: int = 0

var max_health: int = 3
var current_health: int = max_health
var spawn_position: Vector2

func _ready() -> void:
	spawn_position = global_position
	# Ensure the hitbox starts disabled
	shape_cast.enabled = false

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	#Handle Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	#Combo reset logic: If player waits too long, reset combo to hit 0
	if not is_attacking and combo_count > 0:
		combo_timer += delta
		if combo_timer > COMBO_RESET_TIME:
			combo_count = 0
			print("Combo reset")
	
	#Handle Combat Input
	handle_combat_input(delta)
	
	#Block movement/jumping if attacking or hit
	if not is_attacking:
		handle_movement()
		handle_animations()
		
	move_and_slide()
	
func handle_movement() -> void:
	#Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	#Handle Horizontal Movement
	var direction := Input.get_axis("left" ,"right")
	if direction:
		velocity.x = direction * SPEED
		animated_sprite_2d.flip_h = direction < 0
		# Flip the hitbox:
		# If the sprite flips, move the Area2D to the other side
		# Alternatively, scale the Area2D's x by -1
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
func handle_animations() -> void:
	if not is_on_floor():
		animated_sprite_2d.play("jump")
	elif abs(velocity.x) > 1:
		animated_sprite_2d.play("walk")
	else:
		animated_sprite_2d.play("idle")
func handle_combat_input(delta: float) -> void:
	if Input.is_action_just_pressed("light_attack"):
		is_charging_attack = true
		attack_hold_timer = 0.0
		
	if is_charging_attack:
		attack_hold_timer += delta
		
		if Input.is_action_just_released("light_attack"):
			if attack_hold_timer >= HEAVY_ATTACK_THRESHOLD:
				perform_attack("heavy_attack", HEAVY_DAMAGE, HEAVY_ATTACK_DELAY)
				combo_count = 0 # Heavy attack resets combo
			else:
				combo_count += 1
				if combo_count > 4: combo_count = 1
				perform_attack("light_attack_" + str(combo_count), LIGHT_DAMAGE, LIGHT_ATTACK_DELAY)
				combo_timer = 0.0
			is_charging_attack = false
				
func perform_attack(anim_name: String, damage: int, hit_delay: float) -> void:
	is_attacking = true
	current_attack_damage = damage
	velocity.x = move_toward(velocity.x, 0, SPEED * 2)
	animated_sprite_2d.play(anim_name)
	
	# Enable the hitbox shortly after starting the animation
	# I have attached a timer for a specific frame
	await get_tree().create_timer(hit_delay).timeout
	
	shape_cast.position = velocity * 0.05
	shape_cast.enabled = true
	shape_cast.force_shapecast_update()
	
	if shape_cast.is_colliding():
		print("Found something: ", shape_cast.get_collider(0).name)
	else:
		print("Shapecast found nothing")
		for i in range(shape_cast.get_collision_count()):
			var collider = shape_cast.get_collider(i)
			var body = collider.get_parent()
			if not body.has_method("take_damage") and body != self:
				body = collider
				
			if body.has_method("take_damage") and body != self:
				body.take_damage(current_attack_damage)
	shape_cast.enabled = false
	
	shape_cast.position = Vector2(0,0)
	
	await animated_sprite_2d.animation_finished
	is_attacking = false
	
	if not is_dead and animated_sprite_2d.animation == anim_name:
		is_attacking = false
func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_health -= amount
	is_charging_attack = false # Cancel charge on hit
	combo_count = 0
	if current_health <= 0:
		die()
	else:
		handle_hit_state()
			
func handle_hit_state() -> void:
	is_attacking = true
	velocity = Vector2.ZERO
	animated_sprite_2d.play("hit")
	await get_tree().create_timer(0.5).timeout
	if not is_dead:
		is_attacking = false
	
func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	animated_sprite_2d.play("death")
	await animated_sprite_2d.animation_finished
	respawn_player()
		
func respawn_player() -> void:
	global_position = spawn_position
	current_health = max_health
	is_dead = false
	is_attacking = false
	animated_sprite_2d.play("idle")
