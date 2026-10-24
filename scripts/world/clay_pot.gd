class_name ClayPot
extends StaticBody3D

## Traditional Indian Clay Pot (Matka / Ghada).
## Can be hit by player projectiles, breaking into fragments with dust VFX.

signal pot_broken

@export var max_health: float = 1.0
@export var is_destructible: bool = true

@onready var main_mesh: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var break_particles: CPUParticles3D = $BreakParticles

var is_broken: bool = false


func hit(_damage: float, hit_direction: Vector3 = Vector3.ZERO) -> void:
	if is_broken or not is_destructible:
		return
		
	is_broken = true
	pot_broken.emit()
	
	# Disable collision and hide intact mesh
	if is_instance_valid(collision_shape):
		collision_shape.set_deferred("disabled", true)
	if is_instance_valid(main_mesh):
		main_mesh.visible = false
		
	# Trigger clay dust and shard burst
	if is_instance_valid(break_particles):
		break_particles.direction = hit_direction.normalized() + Vector3(0, 0.4, 0)
		break_particles.emitting = true
		
	var timer = get_tree().create_timer(1.2)
	timer.timeout.connect(queue_free)
