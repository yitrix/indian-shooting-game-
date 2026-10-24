class_name MobileVirtualJoystick
extends Control

## Virtual Joystick for mobile touch controls.
## Supports dynamic floating or fixed placement, multi-touch isolation, and vector clamping.

signal joystick_moved(direction: Vector2)
signal joystick_released

@export_group("Joystick Configuration")
@export var deadzone: float = 8.0
@export var max_radius: float = 70.0
@export var dynamic_position: bool = true
@export var return_to_default_on_release: bool = true

@export_group("Visuals")
@export var base_color: Color = Color(0.12, 0.12, 0.15, 0.45)
@export var border_color: Color = Color(0.95, 0.78, 0.45, 0.8)
@export var knob_color: Color = Color(0.98, 0.82, 0.42, 0.9)
@export var knob_border_color: Color = Color(1.0, 1.0, 1.0, 0.95)
@export var border_width: float = 3.0

var current_touch_id: int = -1
var default_base_pos: Vector2 = Vector2.ZERO
var base_pos: Vector2 = Vector2.ZERO
var knob_pos: Vector2 = Vector2.ZERO
var output_vector: Vector2 = Vector2.ZERO
var is_active: bool = false


func _ready() -> void:
	default_base_pos = size * 0.5
	base_pos = default_base_pos
	knob_pos = base_pos
	queue_redraw()


func _draw() -> void:
	var draw_base = base_pos
	var draw_knob = knob_pos
	
	# Draw outer base circle
	draw_circle(draw_base, max_radius, base_color)
	draw_arc(draw_base, max_radius, 0.0, TAU, 48, border_color, border_width, true)
	
	# Subtle inner ring
	draw_arc(draw_base, max_radius * 0.4, 0.0, TAU, 32, Color(border_color.r, border_color.g, border_color.b, 0.3), 1.5, true)
	
	# Draw inner knob circle
	var knob_radius: float = max_radius * 0.38
	draw_circle(draw_knob, knob_radius, knob_color)
	draw_arc(draw_knob, knob_radius, 0.0, TAU, 32, knob_border_color, border_width * 0.8, true)


func _input(event: InputEvent) -> void:
	# Handle Screen Touch
	if event is InputEventScreenTouch:
		if event.pressed:
			if current_touch_id == -1 and _is_inside_touch_area(event.position):
				_start_touch(event.index, event.position)
		elif event.index == current_touch_id:
			_end_touch()
			
	# Handle Screen Drag
	elif event is InputEventScreenDrag:
		if event.index == current_touch_id:
			_update_knob(event.position)
			
	# Desktop Mouse Support for testing without touch emulation
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if current_touch_id == -1 and _is_inside_touch_area(event.position):
					_start_touch(-2, event.position)
			elif current_touch_id == -2:
				_end_touch()
				
	elif event is InputEventMouseMotion:
		if current_touch_id == -2:
			_update_knob(event.position)


func _is_inside_touch_area(global_pos: Vector2) -> bool:
	return get_global_rect().has_point(global_pos)


func _start_touch(touch_id: int, global_pos: Vector2) -> void:
	current_touch_id = touch_id
	is_active = true
	var local_pos = global_pos - global_position
	
	if dynamic_position:
		base_pos = local_pos
		knob_pos = local_pos
	else:
		_update_knob(global_pos)
		
	queue_redraw()


func _update_knob(global_pos: Vector2) -> void:
	var local_pos = global_pos - global_position
	var delta = local_pos - base_pos
	var distance = delta.length()
	
	if distance > deadzone:
		var effective_distance = min(distance, max_radius)
		var factor = (effective_distance - deadzone) / (max_radius - deadzone)
		output_vector = delta.normalized() * factor
	else:
		output_vector = Vector2.ZERO
		
	if distance > max_radius:
		knob_pos = base_pos + delta.normalized() * max_radius
	else:
		knob_pos = local_pos
		
	joystick_moved.emit(output_vector)
	queue_redraw()


func _end_touch() -> void:
	current_touch_id = -1
	is_active = false
	output_vector = Vector2.ZERO
	
	if return_to_default_on_release and dynamic_position:
		base_pos = default_base_pos
		knob_pos = default_base_pos
	else:
		knob_pos = base_pos
		
	joystick_released.emit()
	queue_redraw()


func get_output() -> Vector2:
	return output_vector

