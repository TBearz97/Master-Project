extends Control

class_name CombatGrid

signal cell_clicked(cell: Vector2i)
signal token_clicked(combatant_id: String, cell: Vector2i)
signal token_dragged(combatant_id: String, cell: Vector2i)

const MIN_ZOOM := 0.35
const MAX_ZOOM := 3.0
const ZOOM_STEP := 1.1
const BASE_CELL_SIZE := 56.0
const GRID_PADDING := 24.0
const MIN_CELL_SIZE := 6.0

var board_columns: int = 12
var board_rows: int = 12
var combatants: Dictionary = {}
var selected_combatant_id: String = ""
var hover_cell := Vector2i(-1, -1)
var placement_source_id: String = ""
var preview_path: Array[Vector2i] = []
var preview_destination := Vector2i(-1, -1)
var zoom_level: float = 1.0
var pan_offset := Vector2.ZERO

var _is_panning := false
var _pan_pointer_index := -1
var _last_pan_position := Vector2.ZERO
var _dragging_token_id: String = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true

func setup(columns: int, rows: int, combatant_payloads: Dictionary) -> void:
	board_columns = maxi(columns, 1)
	board_rows = maxi(rows, 1)
	combatants = combatant_payloads.duplicate(true)
	_ensure_board_visible()
	queue_redraw()

func set_selected_combatant(combatant_id: String) -> void:
	selected_combatant_id = combatant_id
	queue_redraw()

func set_preview_path(path: Array, destination: Vector2i = Vector2i(-1, -1)) -> void:
	preview_path.clear()
	for point_variant in path:
		if point_variant is Vector2i:
			preview_path.append(point_variant)
	preview_destination = destination
	queue_redraw()

func clear_preview_path() -> void:
	preview_path.clear()
	preview_destination = Vector2i(-1, -1)
	queue_redraw()

func set_placement_source(combatant_id: String) -> void:
	placement_source_id = combatant_id
	queue_redraw()

func clear_placement_source() -> void:
	placement_source_id = ""
	queue_redraw()

func screen_point_to_cell(point: Vector2) -> Vector2i:
	var board_point: Vector2 = _screen_to_board(point)
	var cell_size: float = _get_cell_size()
	var local_point: Vector2 = board_point / cell_size
	if local_point.x < 0.0 or local_point.y < 0.0:
		return Vector2i(-1, -1)
	var column: int = int(floor(local_point.x))
	var row: int = int(floor(local_point.y))
	if column < 0 or row < 0 or column >= board_columns or row >= board_rows:
		return Vector2i(-1, -1)
	return Vector2i(column, row)

func get_combatant_id_at_cell(cell: Vector2i) -> String:
	for combatant_id_variant in combatants.keys():
		var combatant_id := str(combatant_id_variant)
		var payload: Dictionary = combatants[combatant_id]
		var grid_position := _vector2i_from_variant(payload.get("grid_position", Vector2i(-1, -1)))
		if grid_position == cell:
			return combatant_id
	return ""

func get_reachable_path(start: Vector2i, goal: Vector2i, blocked_cells: Array[Vector2i] = [], max_cost: int = -1) -> Array[Vector2i]:
	if not _is_valid_cell(start) or not _is_valid_cell(goal):
		return []
	if start == goal:
		return [start]

	var blocked_lookup: Dictionary = {}
	for blocked_cell in blocked_cells:
		blocked_lookup[blocked_cell] = true
	blocked_lookup.erase(start)
	blocked_lookup.erase(goal)

	var frontier: Array[Vector2i] = [start]
	var came_from: Dictionary = {start: start}
	var steps: Dictionary = {start: 0}

	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == goal:
			break
		for neighbor in _get_neighbors(current):
			if blocked_lookup.has(neighbor) or came_from.has(neighbor):
				continue
			var next_cost := int(steps.get(current, 0)) + 1
			if max_cost >= 0 and next_cost > max_cost:
				continue
			came_from[neighbor] = current
			steps[neighbor] = next_cost
			frontier.append(neighbor)

	if not came_from.has(goal):
		return []

	var path: Array[Vector2i] = []
	var cursor := goal
	while cursor != start:
		path.push_front(cursor)
		cursor = came_from[cursor]
	path.push_front(start)
	return path

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_MIDDLE:
		if event.pressed:
			_is_panning = true
			_pan_pointer_index = event.button_index
			_last_pan_position = event.position
		else:
			_is_panning = false
			_pan_pointer_index = -1
		return

	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_zoom_at(event.position, ZOOM_STEP)
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_zoom_at(event.position, 1.0 / ZOOM_STEP)
		return

	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not event.pressed:
		_dragging_token_id = ""
		return

	var cell: Vector2i = screen_point_to_cell(event.position)
	if not _is_valid_cell(cell):
		return
	var combatant_id := get_combatant_id_at_cell(cell)
	if not combatant_id.is_empty():
		_dragging_token_id = combatant_id
		token_clicked.emit(combatant_id, cell)
		return
	cell_clicked.emit(cell)

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _is_panning and _pan_pointer_index == MOUSE_BUTTON_MIDDLE:
		pan_offset += event.position - _last_pan_position
		_last_pan_position = event.position
		_ensure_board_visible()
		queue_redraw()
		return

	hover_cell = screen_point_to_cell(event.position)
	if not _dragging_token_id.is_empty() and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		var drag_cell: Vector2i = screen_point_to_cell(event.position)
		if _is_valid_cell(drag_cell):
			token_dragged.emit(_dragging_token_id, drag_cell)
	elif _dragging_token_id.is_empty() and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
		pass
	elif (event.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
		_dragging_token_id = ""
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		hover_cell = Vector2i(-1, -1)
		queue_redraw()
	elif what == NOTIFICATION_RESIZED:
		_ensure_board_visible()
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging_token_id = ""

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.09, 0.11), true)
	var cell_size: float = _get_cell_size()
	var board_origin: Vector2 = _get_board_origin()
	var board_size: Vector2 = Vector2(float(board_columns) * cell_size, float(board_rows) * cell_size)
	var board_rect := Rect2(board_origin, board_size)
	draw_rect(board_rect, Color(0.13, 0.15, 0.18), true)
	var grid_line_width: float = clampf(cell_size * 0.04, 1.0, 2.0)

	for column in range(board_columns + 1):
		var x: float = board_origin.x + float(column) * cell_size
		draw_line(Vector2(x, board_origin.y), Vector2(x, board_origin.y + board_size.y), Color(0.26, 0.30, 0.34), grid_line_width)
	for row in range(board_rows + 1):
		var y: float = board_origin.y + float(row) * cell_size
		draw_line(Vector2(board_origin.x, y), Vector2(board_origin.x + board_size.x, y), Color(0.26, 0.30, 0.34), grid_line_width)

	_draw_hover(board_origin, cell_size)
	_draw_preview_path(board_origin, cell_size)
	_draw_combatants(board_origin, cell_size)

func _draw_hover(board_origin: Vector2, cell_size: float) -> void:
	if not _is_valid_cell(hover_cell):
		return
	var rect := Rect2(board_origin + Vector2(float(hover_cell.x) * cell_size, float(hover_cell.y) * cell_size), Vector2(cell_size, cell_size))
	draw_rect(rect, Color(0.9, 0.9, 1.0, 0.08), true)

func _draw_preview_path(board_origin: Vector2, cell_size: float) -> void:
	if preview_path.size() > 1:
		for index in range(preview_path.size() - 1):
			var from_center := _cell_center(board_origin, cell_size, preview_path[index])
			var to_center := _cell_center(board_origin, cell_size, preview_path[index + 1])
			draw_line(from_center, to_center, Color(0.34, 0.78, 0.98), max(3.0, cell_size * 0.12))
	for path_cell in preview_path:
		var rect := Rect2(board_origin + Vector2(float(path_cell.x) * cell_size, float(path_cell.y) * cell_size), Vector2(cell_size, cell_size))
		draw_rect(rect, Color(0.34, 0.78, 0.98, 0.12), true)
	if _is_valid_cell(preview_destination):
		var destination_rect := Rect2(board_origin + Vector2(float(preview_destination.x) * cell_size, float(preview_destination.y) * cell_size), Vector2(cell_size, cell_size))
		draw_rect(destination_rect, Color(0.72, 0.95, 0.74, 0.18), true)

func _draw_combatants(board_origin: Vector2, cell_size: float) -> void:
	for combatant_id_variant in combatants.keys():
		var combatant_id := str(combatant_id_variant)
		var payload: Dictionary = combatants[combatant_id]
		var grid_position := _vector2i_from_variant(payload.get("grid_position", Vector2i(-1, -1)))
		if not _is_valid_cell(grid_position):
			continue
		var center := _cell_center(board_origin, cell_size, grid_position)
		var radius: float = max(cell_size * 0.3, 8.0)
		var token_color := Color(0.91, 0.44, 0.38) if str(payload.get("type", "")) == "NPC" else Color(0.33, 0.72, 0.95)
		if combatant_id == selected_combatant_id:
			draw_circle(center, radius + 4.0, Color(0.96, 0.88, 0.48, 0.7))
		if combatant_id == placement_source_id:
			draw_circle(center, radius + 8.0, Color(0.72, 0.95, 0.74, 0.25))
		draw_circle(center, radius, token_color)
		if not payload.get("movement_path", []).is_empty():
			draw_circle(center, max(radius - 6.0, 5.0), Color(1.0, 1.0, 1.0, 0.28))
		var initial := str(payload.get("name", "?")).left(1).to_upper()
		var font := get_theme_default_font()
		var font_size := int(clampf(cell_size * 0.34, 11.0, 18.0))
		var text_size := font.get_string_size(initial, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(font, center - Vector2(text_size.x * 0.5, -text_size.y * 0.32), initial, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.08, 0.08, 0.08))

		var planned_position := _vector2i_from_variant(payload.get("planned_grid_position", Vector2i(-1, -1)))
		if _is_valid_cell(planned_position) and planned_position != grid_position:
			var planned_center := _cell_center(board_origin, cell_size, planned_position)
			draw_circle(planned_center, max(radius * 0.38, 5.0), Color(0.72, 0.95, 0.74, 0.95))

func _screen_to_board(point: Vector2) -> Vector2:
	return point - _get_board_origin()

func _get_board_origin() -> Vector2:
	return pan_offset

func _get_cell_size() -> float:
	var available_width: float = max(size.x - GRID_PADDING * 2.0, BASE_CELL_SIZE)
	var available_height: float = max(size.y - GRID_PADDING * 2.0, BASE_CELL_SIZE)
	var fit_size: float = min(available_width / float(max(board_columns, 1)), available_height / float(max(board_rows, 1)))
	return max(fit_size * zoom_level, MIN_CELL_SIZE)

func _cell_center(board_origin: Vector2, cell_size: float, cell: Vector2i) -> Vector2:
	return board_origin + Vector2((float(cell.x) + 0.5) * cell_size, (float(cell.y) + 0.5) * cell_size)

func _get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var candidate = cell + offset
		if _is_valid_cell(candidate):
			neighbors.append(candidate)
	return neighbors

func _is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < board_columns and cell.y < board_rows

func _zoom_at(screen_position: Vector2, factor: float) -> void:
	var previous_cell_size: float = _get_cell_size()
	var before: Vector2 = _screen_to_board(screen_position) / previous_cell_size
	zoom_level = clampf(zoom_level * factor, MIN_ZOOM, MAX_ZOOM)
	var after_cell_size: float = _get_cell_size()
	pan_offset = screen_position - before * after_cell_size
	_ensure_board_visible()
	queue_redraw()

func _ensure_board_visible() -> void:
	var cell_size: float = _get_cell_size()
	var board_pixel_size: Vector2 = Vector2(float(board_columns) * cell_size, float(board_rows) * cell_size)
	if board_pixel_size.x <= size.x:
		pan_offset.x = (size.x - board_pixel_size.x) * 0.5
	else:
		pan_offset.x = clampf(pan_offset.x, size.x - board_pixel_size.x - GRID_PADDING, GRID_PADDING)
	if board_pixel_size.y <= size.y:
		pan_offset.y = (size.y - board_pixel_size.y) * 0.5
	else:
		pan_offset.y = clampf(pan_offset.y, size.y - board_pixel_size.y - GRID_PADDING, GRID_PADDING)

func _vector2i_from_variant(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		var vector := value as Vector2
		return Vector2i(int(vector.x), int(vector.y))
	if value is Dictionary:
		return Vector2i(int(value.get("x", -1)), int(value.get("y", -1)))
	return Vector2i(-1, -1)
