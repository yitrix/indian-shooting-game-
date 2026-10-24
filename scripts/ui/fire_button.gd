class_name FireButton
extends Control

## Touch Fire Button for mobile actions.
## Features animated press states, custom vector styling, and multi-touch isolation.

signal fire_pressed
signal fire_released

@export var button_radius: float = 48.0
@export var normal_color: Color = Color(0.88, 0.35, 0.14, 0.85)
@export var pressed_color: Color = Color(1.0, 0.55, 0.20, 0.95)
@export var border_color: Color = Color(1.0, 0.92, 0.75, 0.9)
@export var icon_color: Color = Color(1.0, 1.0, 1.0, 0.95)

var current_touch_id: int = -1
var is_pressed: bool = false
var current_scale: float = 1.0
var target_scale: float = 1.0


func _ready() -> void:
	custom_minimum_size = Vector2(button_radius * 2.2, button_radius * 2.2)
	pivot_offset = size * 0.5
	resized.connect(func(): pivot_offset = size * 0.5)


func _process(delta: float) -> void:
	if not is_equal_approx(current_scale, target_scale):
		current_scale = lerp(current_scale, target_scale, 20.0 * delta)
		scale = Vector2(current_scale, current_scale)


func _draw() -> void:
	var center = size * 0.5
	var bg_col = pressed_color if is_pressed else normal_color
	
	# Outer glow/shadow
	draw_circle(center, button_radius + 4.0, Color(0.0, 0.0, 0.0, 0.2))
	# Main Button Base
	draw_circle(center, button_radius, bg_col)
	# Border
	draw_arc(center, button_radius, 0.0, TAU, 48, border_color, 3.5, true)
	
	# Fire Icon / Target Crosshair in center
	var flame_scale = button_radius * 0.45
	_draw_fire_glyph(center, flame_scale, icon_color)


func _draw_fire_glyph(center: Vector2, s: float, col: Color) -> void:
	# Draw stylized flame silhouette
	var points: PackedVector2Array = [
		center + Vector2(0, -s * 1.1),
		center + Vector2(s * 0.5, -s * 0.3),
		center + Vector2(s * 0.7, s * 0.4),
		center + Vector2(s * 0.35, s * 0.9),
		center + Vector2(0, s * 0.75),
		center + Vector2(-s * 0.35, s * 0.9),
		center + Vector2(-s * 0.7, s * 0.4),
		center + Vector2(-s * 0.5, -s * 0.3),
	]
	draw_colored_polygon(points, col)
	
	# Inner flame core
	var inner_points: PackedVector2Array = [
		center + Vector2(0, -s * 0.3),
		center + Vector2(s * 0.25, s * 0.3),
		center + Vector2(0, s * 0.6),
		center + Vector2(-s * 0.25, s * 0.3)
	]
	draw_colored_polygon(inner_points, Color(1.0, 0.95, 0.75, 0.95))


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if current_touch_id == -1 and _is_inside(event.position):
				_press(event.index)
		elif event.index == current_touch_id:
			_release()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if current_touch_id == -1 and _is_inside(event.position):
					_press(-1)
			elif current_touch_id == -1:
				_release()


func _is_inside(pos: Vector2) -> bool:
	var center = get_global_rect().get_center()
	return center.distance_to(pos) <= button_radius * 1.25


func _press(touch_id: int) -> void:
	current_touch_id = touch_id
	is_pressed = true
	target_scale = 0.9
	fire_pressed.emit()
	Input.action_press("fire")
	queue_redraw()


func _release() -> void:
	current_touch_id = -1
	is_pressed = false
	target_scale = 1.0
	fire_released.emit()
	Input.action_release("fire")
	queue_redraw()
