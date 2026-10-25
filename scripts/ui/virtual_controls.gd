class_name VirtualControls
extends CanvasLayer

## Root manager for all mobile UI on-screen controls:
## Virtual Joystick (left), Touch Camera Drag (right), and Action/Fire Button.

const MobileVirtualJoystick = preload("res://scripts/ui/virtual_joystick.gd")
const TouchLookZone = preload("res://scripts/ui/touch_look_zone.gd")
const FireButton = preload("res://scripts/ui/fire_button.gd")

signal joystick_moved(direction: Vector2)
signal look_dragged(relative: Vector2)
signal aim_moved(screen_position: Vector2)
signal fire_triggered
signal reload_triggered

@onready var joystick: MobileVirtualJoystick = $LeftTouchArea/VirtualJoystick
@onready var look_zone: TouchLookZone = $RightTouchArea/TouchLookZone
@onready var fire_button: FireButton = $ActionArea/FireButton
@onready var reload_button: Button = $HUD/ReloadButton
@onready var aim_reticle: Control = $HUD/Crosshair


func _ready() -> void:
	if is_instance_valid(joystick):
		joystick.joystick_moved.connect(func(dir: Vector2): joystick_moved.emit(dir))
		joystick.joystick_released.connect(func(): joystick_moved.emit(Vector2.ZERO))

	if is_instance_valid(look_zone):
		look_zone.excluded_controls = [fire_button, reload_button, aim_reticle]
		look_zone.look_dragged.connect(func(rel: Vector2): look_dragged.emit(rel))

	if is_instance_valid(aim_reticle):
		aim_reticle.connect("aim_moved", func(screen_position: Vector2):
			aim_moved.emit(screen_position)
		)

	if is_instance_valid(fire_button):
		fire_button.fire_pressed.connect(func(): fire_triggered.emit())

	if is_instance_valid(reload_button):
		reload_button.pressed.connect(func(): reload_triggered.emit())


func get_joystick_vector() -> Vector2:
	if is_instance_valid(joystick):
		return joystick.get_output()
	return Vector2.ZERO
