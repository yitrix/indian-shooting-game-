class_name AimReticle
extends Control

signal aim_moved(screen_position: Vector2)

var _touch_index: int = -1
var _dragging_mouse: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center_reticle()
	get_viewport().size_changed.connect(_clamp_to_viewport)
	aim_moved.emit(get_global_rect().get_center())


func _draw() -> void:
	var center = size * 0.5
	var color = Color(1.0, 1.0, 1.0, 0.9)
	draw_arc(center, 10.0, 0.0, TAU, 24, color, 2.0, true)
	draw_line(center + Vector2(-22.0, 0.0), center + Vector2(-13.0, 0.0), color, 2.0, true)
	draw_line(center + Vector2(13.0, 0.0), center + Vector2(22.0, 0.0), color, 2.0, true)
	draw_line(center + Vector2(0.0, -22.0), center + Vector2(0.0, -13.0), color, 2.0, true)
	draw_line(center + Vector2(0.0, 13.0), center + Vector2(0.0, 22.0), color, 2.0, true)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touch_index == -1 and _contains_position(event.position):
				_touch_index = event.index
				_move_to(event.position)
				get_viewport().set_input_as_handled()
		elif event.index == _touch_index:
			_touch_index = -1
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_move_to(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not _dragging_mouse and _contains_position(event.position):
				_dragging_mouse = true
				_move_to(event.position)
				get_viewport().set_input_as_handled()
		else:
			if _dragging_mouse:
				get_viewport().set_input_as_handled()
			_dragging_mouse = false
	elif event is InputEventMouseMotion and _dragging_mouse:
		_move_to(event.position)
		get_viewport().set_input_as_handled()


func _contains_position(screen_position: Vector2) -> bool:
	return get_global_rect().has_point(screen_position)


func _move_to(screen_position: Vector2) -> void:
	var viewport_rect = get_viewport().get_visible_rect()
	var half_size = size * 0.5
	var clamped_position = Vector2(
		clampf(screen_position.x, viewport_rect.position.x + half_size.x, viewport_rect.end.x - half_size.x),
		clampf(screen_position.y, viewport_rect.position.y + half_size.y, viewport_rect.end.y - half_size.y)
	)
	global_position = clamped_position - half_size
	aim_moved.emit(clamped_position)


func _center_reticle() -> void:
	var viewport_size = get_viewport_rect().size
	global_position = viewport_size * 0.5 - size * 0.5


func _clamp_to_viewport() -> void:
	_move_to(get_global_rect().get_center())
