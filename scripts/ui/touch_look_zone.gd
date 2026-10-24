class_name TouchLookZone
extends Control

## Right-side camera drag zone for touch devices.
## Converts swipe/drag gestures into camera look delta, filtering out UI elements like buttons.

signal look_dragged(relative: Vector2)
signal look_started
signal look_ended

@export var sensitivity: Vector2 = Vector2(0.2, 0.16)
@export var excluded_controls: Array[Control] = []

var current_touch_id: int = -1
var is_dragging: bool = false
var last_position: Vector2 = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if current_touch_id == -1 and _can_capture_touch(event.position):
				current_touch_id = event.index
				is_dragging = true
				last_position = event.position
				look_started.emit()
		elif event.index == current_touch_id:
			_end_drag()

	elif event is InputEventScreenDrag:
		if event.index == current_touch_id:
			var delta = event.relative
			var scaled_delta = Vector2(delta.x * sensitivity.x, delta.y * sensitivity.y)
			look_dragged.emit(scaled_delta)
			last_position = event.position

	# Desktop fallback using right mouse button or left click on empty zone
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or (event.button_index == MOUSE_BUTTON_LEFT and Input.is_key_pressed(KEY_ALT)):
			if event.pressed:
				if current_touch_id == -1 and _can_capture_touch(event.position):
					current_touch_id = -99
					is_dragging = true
					last_position = event.position
					look_started.emit()
			elif current_touch_id == -99:
				_end_drag()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			# If left click occurs directly inside look zone and not on excluded controls
			if event.pressed:
				if current_touch_id == -1 and _can_capture_touch(event.position):
					current_touch_id = -98
					is_dragging = true
					last_position = event.position
					look_started.emit()
			elif current_touch_id == -98:
				_end_drag()

	elif event is InputEventMouseMotion:
		if current_touch_id in [-98, -99]:
			var delta = event.relative
			var scaled_delta = Vector2(delta.x * sensitivity.x, delta.y * sensitivity.y)
			look_dragged.emit(scaled_delta)


func _can_capture_touch(pos: Vector2) -> bool:
	if not get_global_rect().has_point(pos):
		return false
		
	for ctrl in excluded_controls:
		if is_instance_valid(ctrl) and ctrl.is_visible_in_tree() and ctrl.get_global_rect().has_point(pos):
			return false
			
	return true


func _end_drag() -> void:
	current_touch_id = -1
	is_dragging = false
	look_ended.emit()
