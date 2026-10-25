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
	var aim_reticle = controls.get_node("HUD/Crosshair")
	var pots = main.get_node("VillageProps/ClayPots")
	var thieves = main.get_node("Thieves")
	var village_life = main.get_node("VillageProps/VillageLife")
	
	print("✓ Nodes loaded and entered tree")
	assert(thieves.get_child_count() == 3, "Expected three thieves around the market")
	for thief in thieves.get_children():
		assert(thief.target == player, "Thief was not assigned the player target")
	print("✓ Three thieves spawned and assigned the player target")
	assert(village_life.get_node("Cow1") and village_life.get_node("Cow2"), "Village cows were not loaded")
	assert(village_life.get_node("Villager1") and village_life.get_node("Villager2"), "Village people were not loaded")
	assert(village_life.get_node("Car") and village_life.get_node("AutoRickshaw"), "Village vehicles were not loaded")
	print("✓ Village life, car, and auto-rickshaw loaded")
	assert(player.process_mode == Node.PROCESS_MODE_PAUSABLE, "Player must pause with the game")
	var boundary_query = PhysicsRayQueryParameters3D.create(Vector3(20, 1.5, 0), Vector3(24, 1.5, 0))
	var boundary_hit = main.get_world_3d().direct_space_state.intersect_ray(boundary_query)
	assert(not boundary_hit.is_empty(), "Perimeter boundary does not block the player")
	print("✓ Perimeter boundary blocks movement out of the village")
	
	# Test joystick
	player.set_joystick_input(Vector2(0, -1))
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("✓ Player moving, velocity: %s" % str(player.velocity))
	
	# Test camera drag
	var init_yaw = player.camera_gimbal.rotation.y
	player.handle_camera_drag(Vector2(50, 20))
	print("✓ Camera rotated from %f to %f" % [init_yaw, player.camera_gimbal.rotation.y])

	# Test movable aim reticle
	aim_reticle._move_to(Vector2(300, 200))
	assert(player.aim_screen_position == Vector2(300, 200), "Aim reticle did not update the player's firing aim")
	print("✓ Aim reticle moved and updated player aim")

	# Test fire
	player.trigger_fire()
	print("✓ Fire button triggered projectile")
	
	# Test Clay Pot hit
	var pot = pots.get_child(0)
	pot.hit(10.0, Vector3.FORWARD)
	print("✓ Pot broken status: %s" % str(pot.is_broken))

	# Test thief damage and health bar
	var thief = thieves.get_child(0)
	var starting_thief_health = thief.current_health
	thief.take_damage(25.0)
	assert(thief.current_health == starting_thief_health - 25.0, "Thief health did not decrease")
	assert(is_equal_approx(thief.health_fill.scale.x, 0.75), "Thief health bar did not update")
	var starting_player_health = player.current_health
	thief.global_position = player.global_position + Vector3(0, 0, 1.0)
	thief._attack_timer = 0.0
	await get_tree().physics_frame
	assert(player.current_health < starting_player_health, "Nearby thief did not attack the player")
	starting_player_health = player.current_health
	player.take_damage(10.0)
	assert(player.current_health == starting_player_health - 10.0, "Player melee damage did not apply")
	print("✓ Thief health bar, chase-range melee attack, and player damage work")

	thief.take_damage(thief.max_health)
	assert(thief._is_dead, "Defeated thief did not enter its death animation")
	print("✓ Defeated thief enters death animation")

	thieves.get_child(1).take_damage(thieves.get_child(1).max_health)
	assert(is_instance_valid(main.boss), "Neta Ji did not spawn after two thieves were defeated")
	assert(main.boss.target == player, "Neta Ji was not assigned the player target")
	assert(main.boss.guard_left_muzzle and main.boss.guard_right_muzzle, "Boss bodyguards are missing their firing points")
	main.boss._fire_guard_bullet(main.boss.guard_left_muzzle)
	var guard_bullet_found = false
	for child in main.get_children():
		if child is Projectile:
			guard_bullet_found = true
	assert(guard_bullet_found, "Bodyguard did not fire a bullet")
	print("✓ Neta Ji spawns after two thieves; bodyguards fire at the player")

	main._set_paused(true)
	assert(get_tree().paused and main.pause_menu.visible, "Pause menu did not pause the game")
	main._set_paused(false)
	assert(not get_tree().paused and not main.pause_menu.visible, "Pause menu did not resume the game")
	print("✓ Pause and resume menu work")

	main.boss.take_damage(main.boss.max_health)
	assert(main.boss._is_defeated, "Boss did not enter the defeat animation")
	await get_tree().create_timer(0.85).timeout
	assert(main._mission_complete and main.mission_complete_panel.visible, "Boss defeat did not show Mission Complete")
	assert(get_tree().paused, "Mission completion did not pause gameplay")
	get_tree().paused = false
	print("✓ Defeating Neta Ji ends the level with Mission Complete")

	player.take_damage(player.current_health)
	assert(player.current_health == 0.0, "Player death did not set health to zero")
	assert(get_tree().paused and main.game_over_panel.visible, "Player death did not show game over and pause the game")
	get_tree().paused = false
	print("✓ Player death opens the restart menu and pauses gameplay")
	
	print("=== ALL TESTS PASSED SUCCESSFULLY ===")
	get_tree().quit(0)
