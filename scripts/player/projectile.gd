class_name Projectile
extends Node3D

## Magic low-poly projectile fired by the player.
## Travels forward along direction vector, produces glowing trail, and impacts objects.

@export var speed: float = 28.0
@export var lifetime: float = 3.5
@export var damage: float = 25.0

var direction: Vector3 = Vector3.FORWARD
var _time_alive: float = 0.0
var _is_exploding: bool = false

@onready var area: Area3D = $Area3D
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var trail_particles: CPUParticles3D = $TrailParticles
@onready var impact_particles: CPUParticles3D = $ImpactParticles


func _ready() -> void:
	if is_instance_valid(area):
		area.body_entered.connect(_on_collision)
		area.area_entered.connect(_on_area_collision)


func _physics_process(delta: float) -> void:
	if _is_exploding:
		return
		
	global_position += direction * speed * delta
	_time_alive += delta
	
	if _time_alive >= lifetime:
		queue_free()


func setup(spawn_pos: Vector3, shoot_dir: Vector3) -> void:
	global_position = spawn_pos
	direction = shoot_dir.normalized()
	if direction.is_normalized():
		look_at(global_position + direction, Vector3.UP)


func _on_collision(body: Node) -> void:
	if _is_exploding:
		return
	_handle_hit(body)


func _on_area_collision(other_area: Area3D) -> void:
	if _is_exploding:
		return
	_handle_hit(other_area)


func _handle_hit(target: Node) -> void:
	_is_exploding = true
	
	# Interact with targets that implement hit or break methods
	if target.has_method("hit"):
		target.hit(damage, direction)
	elif target.get_parent() and target.get_parent().has_method("hit"):
		target.get_parent().hit(damage, direction)
		
	# Trigger impact visuals
	if is_instance_valid(mesh):
		mesh.visible = false
	if is_instance_valid(trail_particles):
		trail_particles.emitting = false
	if is_instance_valid(impact_particles):
		impact_particles.emitting = true
		
	# Disable collision area
	if is_instance_valid(area):
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)
		
	# Allow impact particles to finish before freeing
	var timer = get_tree().create_timer(0.45)
	timer.timeout.connect(queue_free)
