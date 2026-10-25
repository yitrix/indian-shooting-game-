class_name Projectile
extends Node3D

## Low-poly bullet fired by the player.
## Sweeps along its flight path so fast shots still hit small targets.

@export var speed: float = 65.0
@export var lifetime: float = 3.5
@export var damage: float = 25.0

var direction: Vector3 = Vector3.FORWARD
var _time_alive: float = 0.0
var _is_exploding: bool = false
var _shooter_rid: RID

@onready var area: Area3D = $Area3D
@onready var mesh: Node3D = $BulletMesh
@onready var trail_particles: CPUParticles3D = $TrailParticles
@onready var impact_particles: CPUParticles3D = $ImpactParticles


func _ready() -> void:
	if is_instance_valid(area):
		area.body_entered.connect(_on_collision)
		area.area_entered.connect(_on_area_collision)


func _physics_process(delta: float) -> void:
	if _is_exploding:
		return

	var next_position = global_position + direction * speed * delta
	var query = PhysicsRayQueryParameters3D.create(global_position, next_position)
	query.collision_mask = area.collision_mask
	query.collide_with_areas = true
	query.exclude = [area.get_rid()]
	if _shooter_rid.is_valid():
		query.exclude.append(_shooter_rid)
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		global_position = hit.position
		_handle_hit(hit.collider)
		return

	global_position = next_position
	_time_alive += delta
	
	if _time_alive >= lifetime:
		queue_free()


func setup(spawn_pos: Vector3, shoot_dir: Vector3, shooter: CollisionObject3D = null) -> void:
	global_position = spawn_pos
	direction = shoot_dir.normalized()
	if shooter == null:
		shooter = get_parent() as CollisionObject3D
	if shooter is CollisionObject3D:
		_shooter_rid = shooter.get_rid()
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
	if not is_instance_valid(target):
		return
	_is_exploding = true
	
	var receiver: Node = target
	while is_instance_valid(receiver):
		if receiver.has_method("hit"):
			receiver.hit(damage, direction)
			break
		if receiver.has_method("take_damage"):
			receiver.take_damage(damage)
			break
		receiver = receiver.get_parent()
		
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
