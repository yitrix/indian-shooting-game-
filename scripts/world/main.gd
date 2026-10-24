class_name MainLevel
extends Node3D

## Main scene controller: connects VirtualControls with Player and manages gameplay UI.

const PlayerClass = preload("res://scripts/player/player.gd")
const VirtualControlsClass = preload("res://scripts/ui/virtual_controls.gd")
const ClayPotClass = preload("res://scripts/world/clay_pot.gd")

@onready var player: PlayerClass = $Player
@onready var virtual_controls: VirtualControlsClass = $VirtualControls
@onready var pots_container: Node3D = $VillageProps/ClayPots
@onready var pots_counter_label: Label = $VirtualControls/HUD/TopBar/PotsCounterLabel
@onready var help_panel: Panel = $VirtualControls/HUD/HelpPanel
@onready var help_toggle_btn: Button = $VirtualControls/HUD/HelpToggleButton

var pots_broken_count: int = 0
var total_pots_count: int = 0


func _ready() -> void:
	_connect_controls()
	_initialize_pots()
	_setup_help_overlay()


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
	
	# Connect Fire Button to Player
	virtual_controls.fire_triggered.connect(func():
		player.trigger_fire()
	)


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


func _update_pot_counter() -> void:
	if is_instance_valid(pots_counter_label):
		pots_counter_label.text = "🏺 Pots Shattered: %d / %d" % [pots_broken_count, total_pots_count]


func _setup_help_overlay() -> void:
	if is_instance_valid(help_toggle_btn) and is_instance_valid(help_panel):
		help_toggle_btn.pressed.connect(func():
			help_panel.visible = not help_panel.visible
		)
