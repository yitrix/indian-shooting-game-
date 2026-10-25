class_name MainLevel
extends Node3D

## Main scene controller: connects VirtualControls with Player and manages gameplay UI.

const PlayerClass = preload("res://scripts/player/player.gd")
const VirtualControlsClass = preload("res://scripts/ui/virtual_controls.gd")
const ClayPotClass = preload("res://scripts/world/clay_pot.gd")
const ThiefEnemyClass = preload("res://scripts/world/thief_enemy.gd")
const NetaBossScene = preload("res://scenes/world/neta_boss.tscn")

@onready var player: PlayerClass = $Player
@onready var virtual_controls: VirtualControlsClass = $VirtualControls
@onready var pots_container: Node3D = $VillageProps/ClayPots
@onready var thieves_container: Node3D = $Thieves
@onready var pots_counter_label: Label = $VirtualControls/HUD/TopBar/PotsCounterLabel
@onready var ammo_label: Label = $VirtualControls/HUD/AmmoLabel
@onready var health_label: Label = $VirtualControls/HUD/HealthLabel
@onready var help_panel: Panel = $VirtualControls/HUD/HelpPanel
@onready var help_toggle_btn: Button = $VirtualControls/HUD/HelpToggleButton
@onready var pause_button: Button = $VirtualControls/HUD/PauseButton
@onready var pause_menu: Panel = $VirtualControls/HUD/PauseMenu
@onready var resume_button: Button = $VirtualControls/HUD/PauseMenu/ResumeButton
@onready var pause_restart_button: Button = $VirtualControls/HUD/PauseMenu/PauseRestartButton
@onready var game_over_panel: Panel = $VirtualControls/HUD/GameOverPanel
@onready var game_over_restart_button: Button = $VirtualControls/HUD/GameOverPanel/GameOverRestartButton
@onready var boss_health_label: Label = $VirtualControls/HUD/BossHealthLabel
@onready var boss_taunt_label: Label = $VirtualControls/HUD/BossTauntLabel
@onready var mission_complete_panel: Panel = $VirtualControls/HUD/MissionCompletePanel
@onready var mission_restart_button: Button = $VirtualControls/HUD/MissionCompletePanel/MissionRestartButton

var pots_broken_count: int = 0
var total_pots_count: int = 0
var thieves_defeated: int = 0
var boss: NetaBoss
var _game_over: bool = false
var _mission_complete: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	_connect_controls()
	_initialize_pots()
	_setup_thieves()
	_setup_help_overlay()
	_setup_game_menus()
	_build_village_boundary()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if _game_over or _mission_complete:
			return
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _connect_controls() -> void:
	if not is_instance_valid(player) or not is_instance_valid(virtual_controls):
		return
		
	# Connect Joystick to Player
	virtual_controls.joystick_moved.connect(func(dir: Vector2):
		player.set_joystick_input(dir)
	)
	
	# Connect Camera Look Drag to Player
	virtual_controls.look_dragged.connect(func(rel: Vector2):
		player.handle_camera_drag(rel)
	)
	virtual_controls.aim_moved.connect(func(screen_position: Vector2):
		player.set_aim_screen_position(screen_position)
	)
	player.set_aim_screen_position(get_viewport().get_visible_rect().size * 0.5)
	
	# Connect Fire Button to Player
	virtual_controls.fire_triggered.connect(func():
		player.trigger_fire()
	)
	virtual_controls.reload_triggered.connect(func():
		player.reload_weapon()
	)
	player.ammo_changed.connect(_on_ammo_changed)
	player.health_changed.connect(_on_player_health_changed)
	_on_ammo_changed(player.current_ammo, player.magazine_size, player.is_reloading)
	_on_player_health_changed(player.current_health, player.max_health)


func _setup_thieves() -> void:
	for thief in thieves_container.get_children():
		if thief is ThiefEnemyClass:
			thief.process_mode = Node.PROCESS_MODE_PAUSABLE
			thief.set_target(player)
			thief.died.connect(_on_thief_died)


func _on_thief_died() -> void:
	thieves_defeated += 1
	if thieves_defeated == 2:
		_spawn_boss()


func _spawn_boss() -> void:
	if is_instance_valid(boss) or _game_over:
		return
	boss = NetaBossScene.instantiate()
	boss.position = Vector3(0.0, 0.0, -1.5)
	boss.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(boss)
	boss.set_target(player)
	boss.health_changed.connect(_on_boss_health_changed)
	boss.taunt_changed.connect(_on_boss_taunt_changed)
	boss.defeated.connect(_on_boss_defeated)
	boss_health_label.text = "Neta Ji: %d / %d" % [roundi(boss.current_health), roundi(boss.max_health)]
	boss_taunt_label.text = "NETA JI: My promises are renewable. Results are still pending."
	boss_health_label.visible = true
	boss_taunt_label.visible = true


func _on_boss_health_changed(current_health: float, health_capacity: float) -> void:
	boss_health_label.text = "Neta Ji: %d / %d" % [roundi(current_health), roundi(health_capacity)]


func _on_boss_taunt_changed(line: String) -> void:
	boss_taunt_label.text = line


func _on_boss_defeated() -> void:
	_mission_complete = true
	get_tree().paused = true
	mission_complete_panel.visible = true
	boss_health_label.visible = false
	boss_taunt_label.visible = false


func _initialize_pots() -> void:
	if not is_instance_valid(pots_container):
		return
		
	for child in pots_container.get_children():
		if child is ClayPotClass:
			total_pots_count += 1
			child.pot_broken.connect(_on_pot_broken)
			
	_update_pot_counter()


func _on_pot_broken() -> void:
	pots_broken_count += 1
	_update_pot_counter()


func _on_ammo_changed(current_ammo: int, magazine_capacity: int, reloading: bool) -> void:
	if not is_instance_valid(ammo_label):
		return
	if reloading:
		ammo_label.text = "RELOADING..."
	else:
		ammo_label.text = "Ammo: %d / %d" % [current_ammo, magazine_capacity]


func _on_player_health_changed(current_health: float, health_capacity: float) -> void:
	if is_instance_valid(health_label):
		health_label.text = "Health: %d / %d" % [roundi(current_health), roundi(health_capacity)]


func _update_pot_counter() -> void:
	if is_instance_valid(pots_counter_label):
		pots_counter_label.text = "🏺 Pots Shattered: %d / %d" % [pots_broken_count, total_pots_count]


func _setup_help_overlay() -> void:
	if is_instance_valid(help_toggle_btn) and is_instance_valid(help_panel):
		help_toggle_btn.pressed.connect(func():
			help_panel.visible = not help_panel.visible
		)


func _setup_game_menus() -> void:
	pause_button.pressed.connect(func(): _set_paused(true))
	resume_button.pressed.connect(func(): _set_paused(false))
	pause_restart_button.pressed.connect(_restart_game)
	game_over_restart_button.pressed.connect(_restart_game)
	mission_restart_button.pressed.connect(_restart_game)
	player.died.connect(_show_game_over)


func _set_paused(paused: bool) -> void:
	if _game_over or _mission_complete:
		return
	get_tree().paused = paused
	pause_menu.visible = paused


func _show_game_over() -> void:
	_game_over = true
	pause_menu.visible = false
	game_over_panel.visible = true
	pause_button.disabled = true
	get_tree().paused = true


func _restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _build_village_boundary() -> void:
	var boundary_root = Node3D.new()
	boundary_root.name = "VillageBoundary"
	add_child(boundary_root)

	var foliage = StandardMaterial3D.new()
	foliage.albedo_color = Color(0.16, 0.29, 0.12, 1)
	foliage.roughness = 1.0
	var trunk_material = StandardMaterial3D.new()
	trunk_material.albedo_color = Color(0.27, 0.16, 0.09, 1)
	trunk_material.roughness = 1.0

	_add_boundary_wall(boundary_root, Vector3(-22.0, 1.5, 0), Vector3(0.7, 3.0, 44.0))
	_add_boundary_wall(boundary_root, Vector3(22.0, 1.5, 0), Vector3(0.7, 3.0, 44.0))
	_add_boundary_wall(boundary_root, Vector3(0, 1.5, -22.0), Vector3(44.0, 3.0, 0.7))
	_add_boundary_wall(boundary_root, Vector3(0, 1.5, 22.0), Vector3(44.0, 3.0, 0.7))

	var bush_mesh = SphereMesh.new()
	bush_mesh.radius = 1.0
	bush_mesh.height = 2.0
	bush_mesh.radial_segments = 7
	bush_mesh.rings = 4
	bush_mesh.material = foliage
	var trunk_mesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.16
	trunk_mesh.bottom_radius = 0.25
	trunk_mesh.height = 2.4
	trunk_mesh.radial_segments = 6
	trunk_mesh.material = trunk_material

	var rng = RandomNumberGenerator.new()
	rng.seed = 71325
	for offset in range(-20, 21, 2):
		for edge in [-1.0, 1.0]:
			_add_boundary_bush(boundary_root, bush_mesh, Vector3(float(offset), 0.75, edge * 21.5), rng)
			_add_boundary_bush(boundary_root, bush_mesh, Vector3(edge * 21.5, 0.75, float(offset)), rng)
		if offset % 6 == 0:
			_add_boundary_tree(boundary_root, bush_mesh, trunk_mesh, Vector3(float(offset), 0.0, -21.2), rng)
			_add_boundary_tree(boundary_root, bush_mesh, trunk_mesh, Vector3(float(offset), 0.0, 21.2), rng)
			_add_boundary_tree(boundary_root, bush_mesh, trunk_mesh, Vector3(-21.2, 0.0, float(offset)), rng)
			_add_boundary_tree(boundary_root, bush_mesh, trunk_mesh, Vector3(21.2, 0.0, float(offset)), rng)


func _add_boundary_wall(parent: Node3D, position: Vector3, size: Vector3) -> void:
	var wall = StaticBody3D.new()
	wall.name = "CollisionBarrier"
	wall.collision_layer = 1
	wall.collision_mask = 0
	wall.position = position
	var shape_node = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	shape_node.shape = shape
	wall.add_child(shape_node)
	parent.add_child(wall)


func _add_boundary_bush(parent: Node3D, mesh: Mesh, position: Vector3, rng: RandomNumberGenerator) -> void:
	var bush = MeshInstance3D.new()
	bush.mesh = mesh
	bush.position = position + Vector3(0.0, rng.randf_range(-0.05, 0.18), 0.0)
	bush.scale = Vector3(rng.randf_range(0.85, 1.25), rng.randf_range(0.7, 1.15), rng.randf_range(0.85, 1.2))
	parent.add_child(bush)


func _add_boundary_tree(parent: Node3D, crown_mesh: Mesh, trunk_mesh: Mesh, position: Vector3, rng: RandomNumberGenerator) -> void:
	var tree = Node3D.new()
	tree.position = position
	parent.add_child(tree)
	var trunk = MeshInstance3D.new()
	trunk.mesh = trunk_mesh
	trunk.position.y = 1.2
	tree.add_child(trunk)
	var crown = MeshInstance3D.new()
	crown.mesh = crown_mesh
	crown.position.y = rng.randf_range(2.35, 2.7)
	crown.scale = Vector3(1.4, 1.5, 1.4)
	tree.add_child(crown)
