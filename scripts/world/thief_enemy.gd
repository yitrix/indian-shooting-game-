class_name ThiefEnemy
extends CharacterBody3D

signal health_changed(current_health: float, max_health: float)
signal died

@export var max_health: float = 100.0
@export var patrol_speed: float = 1.6
@export var chase_speed: float = 3.8
@export var detection_range: float = 15.0
@export var melee_range: float = 1.55
@export var melee_damage: float = 10.0
@export var attack_cooldown: float = 1.2
@export var patrol_offset_a: Vector3 = Vector3(-3.0, 0.0, 0.0)
@export var patrol_offset_b: Vector3 = Vector3(3.0, 0.0, 0.0)

@onready var health_fill: MeshInstance3D = $Visuals/HealthBar/Fill
@onready var visuals: Node3D = $Visuals

var current_health: float
var target: Node3D
var _patrol_home: Vector3
var _patrol_target: Vector3
var _patrolling_to_b: bool = true
var _attack_timer: float = 0.0
var _walk_phase: float = 0.0
var _is_dead: bool = false
var _health_fill_base_scale: Vector3


func _ready() -> void:
	current_health = max_health
	_patrol_home = global_position
	_patrol_target = _patrol_home + patrol_offset_b
	_health_fill_base_scale = health_fill.scale
	health_changed.emit(current_health, max_health)
	_update_health_bar()


func set_target(player: Node3D) -> void:
	target = player


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_attack_timer = maxf(0.0, _attack_timer - delta)
	var destination = _get_destination()
	var speed = patrol_speed
	if is_instance_valid(target) and _horizontal_distance_to(target) <= detection_range:
		speed = chase_speed

	var direction = destination - global_position
	direction.y = 0.0
	if direction.length_squared() > 0.12:
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		visuals.rotation.y = lerp_angle(visuals.rotation.y, atan2(direction.x, direction.z), 8.0 * delta)
		_walk_phase += delta * speed * 5.0
		visuals.position.y = absf(sin(_walk_phase)) * 0.045
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 3.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 3.0 * delta)
		visuals.position.y = lerpf(visuals.position.y, 0.0, 10.0 * delta)
		if speed == patrol_speed:
			_patrolling_to_b = not _patrolling_to_b
			_patrol_target = _patrol_home + (patrol_offset_b if _patrolling_to_b else patrol_offset_a)

	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = -0.5
	move_and_slide()

	if is_instance_valid(target) and _horizontal_distance_to(target) <= melee_range and _attack_timer <= 0.0:
		if target.has_method("take_damage"):
			target.take_damage(melee_damage)
		_attack_timer = attack_cooldown


func _get_destination() -> Vector3:
	if is_instance_valid(target) and _horizontal_distance_to(target) <= detection_range:
		return target.global_position
	return _patrol_target


func _horizontal_distance_to(other: Node3D) -> float:
	var offset = other.global_position - global_position
	offset.y = 0.0
	return offset.length()


func take_damage(amount: float) -> void:
	if _is_dead or amount <= 0.0:
		return

	current_health = maxf(0.0, current_health - amount)
	_update_health_bar()
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		_die()


func _update_health_bar() -> void:
	if not is_instance_valid(health_fill):
		return
	var health_ratio = clampf(current_health / max_health, 0.0, 1.0)
	health_fill.scale = Vector3(_health_fill_base_scale.x * health_ratio, _health_fill_base_scale.y, _health_fill_base_scale.z)
	health_fill.position.x = -0.31 * (1.0 - health_ratio)


func _die() -> void:
	_is_dead = true
	died.emit()
	set_physics_process(false)
	$CollisionShape3D.set_deferred("disabled", true)
	var death_tween = create_tween()
	death_tween.set_parallel(true)
	death_tween.tween_property(visuals, "rotation:z", deg_to_rad(82.0), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	death_tween.tween_property(visuals, "position:y", -0.38, 0.45)
	death_tween.tween_property(visuals, "scale", Vector3(0.82, 0.82, 0.82), 0.45)
	death_tween.chain().tween_callback(queue_free)
