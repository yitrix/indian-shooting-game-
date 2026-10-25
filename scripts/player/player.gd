class_name Player
extends CharacterBody3D

## Third-person mobile player controller.
## Integrates camera-relative movement, smooth yaw/pitch camera drag, procedural animation, and projectile firing.

@export_group("Movement")
@export var move_speed: float = 6.5
@export var acceleration: float = 14.0
@export var deceleration: float = 18.0
@export var turn_speed: float = 12.0
@export var gravity: float = 24.0

@export_group("Camera Settings")
@export var min_pitch_deg: float = -62.0
@export var max_pitch_deg: float = 32.0
@export var camera_sensitivity: float = 0.25

@export_group("Combat")
@export var projectile_scene: PackedScene = preload("res://scenes/player/projectile.tscn")
@export var fire_cooldown: float = 0.28
@export var magazine_size: int = 12
@export var reload_duration: float = 1.4
@export var max_health: float = 100.0

signal ammo_changed(current_ammo: int, magazine_capacity: int, reloading: bool)
signal health_changed(current_health: float, health_capacity: float)
signal died

# Node References
@onready var visuals: Node3D = $Visuals
@onready var camera_gimbal: Node3D = $CameraGimbal
@onready var spring_arm: SpringArm3D = $CameraGimbal/SpringArm3D
@onready var camera: Camera3D = $CameraGimbal/SpringArm3D/Camera3D
@onready var muzzle: Marker3D = $Visuals/CharacterMesh/ArmRight/Gun/Muzzle
@onready var arm_left: Node3D = $Visuals/CharacterMesh/ArmLeft
@onready var arm_right: Node3D = $Visuals/CharacterMesh/ArmRight
@onready var muzzle_flash: OmniLight3D = $Visuals/CharacterMesh/ArmRight/Gun/Muzzle/MuzzleFlash
@onready var muzzle_flash_mesh: MeshInstance3D = $Visuals/CharacterMesh/ArmRight/Gun/Muzzle/MuzzleFlashMesh
@onready var gunshot_audio: AudioStreamPlayer3D = $Visuals/CharacterMesh/ArmRight/Gun/GunshotAudio

var external_input_vector: Vector2 = Vector2.ZERO
var can_fire: bool = true
var current_ammo: int = 0
var current_health: float = 100.0
var is_reloading: bool = false
var walk_cycle: float = 0.0
var initial_body_y: float = 0.0
var aim_screen_position: Vector2 = Vector2.ZERO
var _is_dead: bool = false


func _ready() -> void:
	current_ammo = magazine_size
	current_health = max_health
	if is_instance_valid(visuals):
		initial_body_y = visuals.position.y
	if is_instance_valid(muzzle_flash):
		muzzle_flash.visible = false
	if is_instance_valid(muzzle_flash_mesh):
		muzzle_flash_mesh.visible = false
	ammo_changed.emit(current_ammo, magazine_size, is_reloading)
	health_changed.emit(current_health, max_health)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	_apply_gravity(delta)
	_handle_movement(delta)
	_update_procedural_animations(delta)
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fire"):
		trigger_fire()
	if event.is_action_pressed("reload"):
		reload_weapon()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0:
			velocity.y = -0.5


func _handle_movement(delta: float) -> void:
	# Combine Virtual Joystick input with keyboard WASD fallback
	var input_dir: Vector2 = external_input_vector
	if input_dir.length_squared() < 0.01:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		
	# Calculate move direction relative to camera gimbal
	var cam_basis = camera_gimbal.global_transform.basis
	var forward = -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	
	var right = cam_basis.x
	right.y = 0.0
	right = right.normalized()
	
	var wish_dir = (forward * -input_dir.y + right * input_dir.x).limit_length(1.0)
	
	if wish_dir.length_squared() > 0.02:
		var target_vel = wish_dir * move_speed
		velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)
		
		# Smoothly rotate character visuals toward movement direction
		var target_angle = atan2(wish_dir.x, wish_dir.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, turn_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)


func _update_procedural_animations(delta: float) -> void:
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	
	if is_on_floor() and horizontal_speed > 0.4:
		walk_cycle += delta * horizontal_speed * 2.8
		# Bobbing
		visuals.position.y = initial_body_y + abs(sin(walk_cycle * 2.0)) * 0.08
		# Arm swinging
		if is_instance_valid(arm_left):
			arm_left.rotation.x = sin(walk_cycle) * 0.45
		if is_instance_valid(arm_right):
			arm_right.rotation.x = -sin(walk_cycle) * 0.35
		# Subtle forward lean
		visuals.rotation.x = lerp(visuals.rotation.x, deg_to_rad(4.5), 10.0 * delta)
	else:
		# Return to idle
		walk_cycle = 0.0
		visuals.position.y = lerp(visuals.position.y, initial_body_y, 12.0 * delta)
		visuals.rotation.x = lerp(visuals.rotation.x, 0.0, 10.0 * delta)
		if is_instance_valid(arm_left):
			arm_left.rotation.x = lerp(arm_left.rotation.x, 0.0, 10.0 * delta)
		if is_instance_valid(arm_right):
			arm_right.rotation.x = lerp(arm_right.rotation.x, 0.0, 10.0 * delta)


## Public API called by TouchLookZone
func handle_camera_drag(drag_delta: Vector2) -> void:
	# Horizontal yaw on gimbal
	camera_gimbal.rotate_y(deg_to_rad(-drag_delta.x * camera_sensitivity))
	
	# Vertical pitch on spring arm
	var pitch_change = deg_to_rad(-drag_delta.y * camera_sensitivity)
	var new_pitch = spring_arm.rotation.x + pitch_change
	var min_pitch = deg_to_rad(min_pitch_deg)
	var max_pitch = deg_to_rad(max_pitch_deg)
	spring_arm.rotation.x = clamp(new_pitch, min_pitch, max_pitch)


## Public API called by VirtualJoystick
func set_joystick_input(input_vector: Vector2) -> void:
	external_input_vector = input_vector


func set_aim_screen_position(screen_position: Vector2) -> void:
	aim_screen_position = screen_position


func take_damage(amount: float) -> void:
	if amount <= 0.0 or _is_dead:
		return
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		_is_dead = true
		set_physics_process(false)
		$CollisionShape3D.set_deferred("disabled", true)
		died.emit()


## Public API called by FireButton
func trigger_fire() -> void:
	if _is_dead or not can_fire or is_reloading or current_ammo <= 0 or projectile_scene == null:
		return
		
	can_fire = false
	current_ammo -= 1
	ammo_changed.emit(current_ammo, magazine_size, is_reloading)
	_shoot_projectile()
	
	# Visual firing recoil
	if is_instance_valid(arm_right):
		arm_right.rotation.x = deg_to_rad(-65.0)
	if is_instance_valid(muzzle_flash):
		muzzle_flash.visible = true
	if is_instance_valid(muzzle_flash_mesh):
		muzzle_flash_mesh.visible = true
	if is_instance_valid(gunshot_audio):
		gunshot_audio.play()
		
	var timer = get_tree().create_timer(0.08)
	timer.timeout.connect(func():
		if is_instance_valid(muzzle_flash):
			muzzle_flash.visible = false
		if is_instance_valid(muzzle_flash_mesh):
			muzzle_flash_mesh.visible = false
	)
	
	var cd_timer = get_tree().create_timer(fire_cooldown)
	cd_timer.timeout.connect(func(): can_fire = true)


func reload_weapon() -> void:
	if _is_dead or is_reloading or current_ammo >= magazine_size:
		return

	is_reloading = true
	ammo_changed.emit(current_ammo, magazine_size, is_reloading)
	await get_tree().create_timer(reload_duration).timeout
	if not is_inside_tree():
		return

	current_ammo = magazine_size
	is_reloading = false
	ammo_changed.emit(current_ammo, magazine_size, is_reloading)


func _shoot_projectile() -> void:
	var spawn_pos: Vector3 = muzzle.global_position if is_instance_valid(muzzle) else global_position + Vector3(0, 1.2, 0)
	var shoot_dir: Vector3 = _get_aim_direction(spawn_pos)
	
	var proj = projectile_scene.instantiate()
	get_parent().add_child(proj)
	if proj.has_method("setup"):
		proj.setup(spawn_pos, shoot_dir, self)


func _get_aim_direction(from_point: Vector3) -> Vector3:
	# Center of screen raycast
	var space_state = get_world_3d().direct_space_state
	var ray_origin = camera.project_ray_origin(aim_screen_position)
	var ray_normal = camera.project_ray_normal(aim_screen_position)
	var ray_end = ray_origin + ray_normal * 75.0
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [get_rid()]
	var result = space_state.intersect_ray(query)
	
	var target_point: Vector3
	if result:
		target_point = result.position
	else:
		target_point = ray_end
		
	return (target_point - from_point).normalized()
