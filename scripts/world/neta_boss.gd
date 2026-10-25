class_name NetaBoss
extends CharacterBody3D

signal health_changed(current_health: float, max_health: float)
signal taunt_changed(line: String)
signal defeated

const BulletScene = preload("res://scenes/player/projectile.tscn")

@export var max_health: float = 300.0
@export var fire_interval: float = 1.25
@export var bullet_damage: float = 8.0

@onready var health_fill: MeshInstance3D = $Visuals/HealthBar/Fill
@onready var guard_left_muzzle: Marker3D = $Visuals/GuardLeft/Muzzle
@onready var guard_right_muzzle: Marker3D = $Visuals/GuardRight/Muzzle
@onready var visuals: Node3D = $Visuals

var current_health: float
var target: Node3D
var _fire_timer: float = 0.8
var _taunt_timer: float = 4.5
var _taunt_index: int = 0
var _is_defeated: bool = false
var _health_fill_base_scale: Vector3
var _taunts: PackedStringArray = [
	"NETA JI: My promises are renewable. Results are still pending.",
	"NETA JI: I have built a bridge to tomorrow. The opening date is confidential.",
	"NETA JI: The village budget is safe. It is hiding somewhere.",
	"NETA JI: Please admire my progress report. It has many impressive charts."
]


func _ready() -> void:
	current_health = max_health
	_health_fill_base_scale = health_fill.scale
	health_changed.emit(current_health, max_health)
	_update_health_bar()
	taunt_changed.emit(_taunts[0])


func set_target(player: Node3D) -> void:
	target = player


func _physics_process(delta: float) -> void:
	if _is_defeated:
		return
	_fire_timer -= delta
	_taunt_timer -= delta
	if _taunt_timer <= 0.0:
		_taunt_index = (_taunt_index + 1) % _taunts.size()
		taunt_changed.emit(_taunts[_taunt_index])
		_taunt_timer = 5.0
	if is_instance_valid(target):
		visuals.rotation.y = lerp_angle(
			visuals.rotation.y,
			atan2(target.global_position.x - global_position.x, target.global_position.z - global_position.z),
			3.0 * delta
		)
		if _fire_timer <= 0.0 and global_position.distance_to(target.global_position) <= 24.0:
			_fire_guard_bullet(guard_left_muzzle)
			_fire_guard_bullet(guard_right_muzzle)
			_fire_timer = fire_interval


func _fire_guard_bullet(muzzle: Marker3D) -> void:
	if not is_instance_valid(muzzle) or not is_instance_valid(target):
		return
	var bullet = BulletScene.instantiate()
	bullet.speed = 20.0
	bullet.damage = bullet_damage
	get_parent().add_child(bullet)
	var aim_point = target.global_position + Vector3.UP * 0.9
	bullet.setup(muzzle.global_position, (aim_point - muzzle.global_position).normalized(), self)


func take_damage(amount: float) -> void:
	if _is_defeated or amount <= 0.0:
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
	health_fill.scale.x = _health_fill_base_scale.x * health_ratio
	health_fill.position.x = -0.67 * (1.0 - health_ratio)


func _die() -> void:
	_is_defeated = true
	set_physics_process(false)
	$CollisionShape3D.set_deferred("disabled", true)
	taunt_changed.emit("NETA JI: I would like to thank the people... for waiting.")
	var death_tween = create_tween()
	death_tween.set_parallel(true)
	death_tween.tween_property(visuals, "rotation:z", deg_to_rad(82.0), 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	death_tween.tween_property(visuals, "position:y", -0.45, 0.7)
	death_tween.tween_property(visuals, "scale", Vector3(0.75, 0.75, 0.75), 0.7)
	death_tween.chain().tween_callback(_finish_defeat)


func _finish_defeat() -> void:
	defeated.emit()
	queue_free()
