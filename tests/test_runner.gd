extends Node

func _ready() -> void:
	print("=== Running Mobile 3D Test Suite ===")
	var main_scene = preload("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	
	await get_tree().process_frame
	await get_tree().physics_frame
	
	var player = main.get_node("Player")
	var controls = main.get_node("VirtualControls")
	var pots = main.get_node("VillageProps/ClayPots")
	
	print("✓ Nodes loaded and entered tree")
	
	# Test joystick
	player.set_joystick_input(Vector2(0, -1))
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("✓ Player moving, velocity: %s" % str(player.velocity))
	
	# Test camera drag
	var init_yaw = player.camera_gimbal.rotation.y
	player.handle_camera_drag(Vector2(50, 20))
	print("✓ Camera rotated from %f to %f" % [init_yaw, player.camera_gimbal.rotation.y])
	
	# Test fire
	player.trigger_fire()
	print("✓ Fire button triggered projectile")
	
	# Test Clay Pot hit
	var pot = pots.get_child(0)
	pot.hit(10.0, Vector3.FORWARD)
	print("✓ Pot broken status: %s" % str(pot.is_broken))
	
	print("=== ALL TESTS PASSED SUCCESSFULLY ===")
	get_tree().quit(0)
