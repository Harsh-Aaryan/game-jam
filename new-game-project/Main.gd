extends Node2D

@onready var background: Sprite2D = $Background
@onready var ui_layer: CanvasLayer = $UI
@onready var info_label: Label = $UI/Info
@onready var popup: PopupPanel = $UI/Popup
@onready var popup_title: Label = $UI/Popup/Margin/VBox/Title
@onready var popup_body: Label = $UI/Popup/Margin/VBox/Body
@onready var popup_line: LineEdit = $UI/Popup/Margin/VBox/Line
@onready var popup_button_primary: Button = $UI/Popup/Margin/VBox/Buttons/Primary
@onready var popup_button_secondary: Button = $UI/Popup/Margin/VBox/Buttons/Secondary
@onready var puzzle_layer: Node2D = Node2D.new()

const ASSET_PATHS := {
	"location1": "res://assets/location1.png",
	"location2": "res://assets/location2.png",
	"location3": "res://assets/location3.png",
	"computer_screen": "res://assets/computerscreen-f.png",
	"closet1": "res://assets/closet1-f.png",
	"closet2": "res://assets/closet2-f.png",
	"joeminer_old": "res://assets/joeminerold-f.png",
}

var hotspots: Array[Area2D] = []
var puzzle_grid: Array = []
var empty_slot: Vector2 = Vector2(2,2)
var piece_size: Vector2 = Vector2(100, 100) # adjust to your puzzle piece size

func _ready():
	_set_location(GameState.current_location)
	var cursor = load("res://assets/cursor.png")
	Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, Vector2(0,16))
	add_child(puzzle_layer)

# --- Hotspot & Room Handling ---
func _clear_hotspots():
	for h in hotspots:
		h.queue_free()
	hotspots.clear()

func _clear_room_text() -> void:
	for child in get_children():
		if child is Label or child is RichTextLabel:
			child.queue_free()
	if info_label:
		info_label.text = ""

func _set_location(loc: String) -> void:
	_clear_hotspots()
	_clear_room_text()
	_clear_image_overlays()
	if loc != "computer_screen":
		puzzle_layer.queue_free()
		puzzle_layer = Node2D.new()
		add_child(puzzle_layer)
	GameState.current_location = loc
	_update_background(loc)
	_update_hotspots_for_location(loc)

func _update_background(loc: String) -> void:
	var path: String = ASSET_PATHS.get(loc, "")
	if path != "" and ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		background.texture = tex
		background.centered = false
		background.position = Vector2.ZERO
	else:
		background.texture = null
	info_label.text = _make_info_text()

func _make_info_text() -> String:
	var lines := []
	lines.append("Inventory: ")
	if GameState.has_badge: lines.append("Badge ")
	if GameState.has_paper_intro: lines.append("Intro Paper ")
	if GameState.puzzle_piece_a: lines.append("Piece A ")
	if GameState.puzzle_piece_b: lines.append("Piece B ")
	if GameState.has_key: lines.append("Key ")
	lines.append("\nHint: Press Tab to switch rooms.")
	return "".join(lines)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"):
		# Tab key switches rooms for testing
		if GameState.current_location == "location1":
			_set_location("location2")
		elif GameState.current_location == "location2":
			_set_location("location3")
		else:
			_set_location("location1")

func _add_hotspot(rect: Rect2, label: String, on_press: Callable) -> void:
	var area := Area2D.new()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	cs.shape = shape
	cs.position = rect.position + rect.size * 0.5
	area.position = Vector2.ZERO
	area.add_child(cs)
	add_child(area)
	var l := Label.new()
	l.text = label
	l.position = rect.position
	l.modulate = Color(1,1,0)
	add_child(l)

	var finger_cursor = preload("res://assets/cursor.png")
	var eye_cursor = preload("res://assets/interact.png")
	area.mouse_entered.connect(func():
		Input.set_custom_mouse_cursor(eye_cursor, Input.CURSOR_ARROW, Vector2(16, 16))
	)
	area.mouse_exited.connect(func():
		Input.set_custom_mouse_cursor(finger_cursor, Input.CURSOR_ARROW, Vector2(6, 28))
	)
	area.input_event.connect(func(_viewport, e, _shape_idx):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			on_press.call()
		)

	hotspots.append(area)
	hotspots.append(l)

func _update_hotspots_for_location(loc: String) -> void:
	_clear_hotspots()
	match loc:
		"location1":
			_add_hotspot(Rect2(290, 220, 160, 90), "Computer", func(): _on_computer())
			_add_hotspot(Rect2(560, 250, 130, 100), "Desk", func(): _on_desk())
			_add_hotspot(Rect2(700, 20, 120, 120), "---->", func(): _set_location("location2"))
		"location2":
			_add_hotspot(Rect2(500, 60, 140, 100), "Poster", func(): _on_poster())
			_add_hotspot(Rect2(40, 170, 140, 100), "<----", func(): _set_location("location1"))
			_add_hotspot(Rect2(680, 220, 140, 100), "Small Door", func(): _set_location("location3"))
		"location3":
			_add_hotspot(Rect2(320, 120, 200, 220), "Closet", func(): _on_closet())
			_add_hotspot(Rect2(120, 120, 180, 180), "Safe", func(): _on_safe())
			_add_hotspot(Rect2(40, 220, 140, 100), "<----", func(): _set_location("location2"))
		"computer_screen":
			_add_hotspot(Rect2(40, 220, 140, 100), "Back", func(): _set_location("location1"))

# --- Room Interactions ---
func _on_poster():
	_show_text_dialog("Missing Poster", "Missing: Joe Miner. Went missing on 2013-09-17.\nPassword hint: The date (YYYY-MM-DD).", "OK", func(): popup.hide())

func _on_computer():
	if not GameState.computer_unlocked:
		_show_input_dialog("Computer Login", "Enter password (missing date, YYYY-MM-DD):", "Unlock", func(): _attempt_login(), "Cancel", func(): popup.hide())
		return

	_set_location("computer_screen")

	if not GameState.slide_puzzle_solved:
		_start_slide_puzzle()
	else:
		_show_text_dialog("Computer", "Nothing else useful here.", "OK", func(): popup.hide())

func _attempt_login() -> void:
	if popup_line.text.strip_edges() == "2013-09-17":
		GameState.computer_unlocked = true
		popup.hide()
		_on_computer()
	else:
		popup_body.text = "Incorrect. Try again."

func _on_desk():
	if not GameState.desk_checked:
		GameState.desk_checked = true
		GameState.puzzle_piece_b = true
		_show_text_dialog("Desk", "Taped underneath is the other half of the puzzle and a note hinting at a new identity.", "OK", func(): popup.hide())
	else:
		_show_text_dialog("Desk", "Nothing else under here.", "OK", func(): popup.hide())

func _on_safe():
	if GameState.safe_opened:
		_show_text_dialog("Safe", "Already open. The key is gone.", "OK", func(): popup.hide())
		return
	if GameState.can_open_safe():
		GameState.safe_opened = true
		GameState.has_key = true
		_show_text_dialog("Safe", "The pieces fit. The safe clicks open, revealing a key.", "Take Key", func(): popup.hide())
	else:
		_show_text_dialog("Safe", "Two puzzle pieces are required to open this safe.", "OK", func(): popup.hide())

func _on_closet():
	if not GameState.has_key:
		_show_text_dialog("Closet", "Locked. You need a key.", "OK", func(): popup.hide())
		return
	if not GameState.closet_opened:
		GameState.closet_opened = true
		_show_image_overlay(ASSET_PATHS["closet1"])
		_show_text_dialog("Closet", "The closet is now open. You can see inside.", "Look Inside", func(): _look_inside_closet(), "Close", func(): _close_closet_view())
	elif not GameState.closet_looked_at:
		_look_inside_closet()
	else:
		_end_game()

func _look_inside_closet():
	GameState.closet_looked_at = true
	_show_image_overlay(ASSET_PATHS["closet2"], ASSET_PATHS["joeminer_old"])
	_show_text_dialog("Closet", "Inside is a standing mirror and paperwork: evidence of plastic surgery to hide your identity. You recognize yourself in the mirror.", "Continue", func(): _close_closet_view())

func _close_closet_view():
	_clear_image_overlays()
	popup.hide()

func _end_game():
	if not GameState.game_over:
		GameState.game_over = true
		_show_text_dialog("The End", "You recognize yourself in the mirror. You were Joe Miner, hidden behind a new identity.", "Restart", func(): GameState.reset(); _set_location(GameState.current_location); popup.hide(), "Quit", func(): get_tree().quit())

# --- Popups ---
func _show_text_dialog(title: String, body: String, primary_text: String, primary_cb: Callable, secondary_text: String = "", secondary_cb: Callable = Callable()):
	popup_title.text = title
	popup_body.text = body
	popup_line.visible = false
	popup_button_primary.text = primary_text
	popup_button_primary.pressed.connect(primary_cb, Object.CONNECT_ONE_SHOT)
	if secondary_text != "":
		popup_button_secondary.text = secondary_text
		popup_button_secondary.visible = true
		popup_button_secondary.pressed.connect(secondary_cb, Object.CONNECT_ONE_SHOT)
	else:
		popup_button_secondary.visible = false
	popup.popup_centered()

func _show_input_dialog(title: String, body: String, primary_text: String, primary_cb: Callable, secondary_text: String, secondary_cb: Callable):
	popup_title.text = title
	popup_body.text = body
	popup_line.text = ""
	popup_line.visible = true
	popup_button_primary.text = primary_text
	popup_button_primary.pressed.connect(primary_cb, Object.CONNECT_ONE_SHOT)
	popup_button_secondary.text = secondary_text
	popup_button_secondary.visible = true
	popup_button_secondary.pressed.connect(secondary_cb, Object.CONNECT_ONE_SHOT)
	popup.popup_centered()

func _show_image_overlay(image_path: String, overlay_path: String = ""):
	# Clear any existing image overlays
	_clear_image_overlays()
	
	# Create main image sprite
	var main_sprite = Sprite2D.new()
	main_sprite.texture = load(image_path)
	main_sprite.position = Vector2(360, 240) # Center of 720x480 screen
	main_sprite.name = "image_overlay_main"
	add_child(main_sprite)
	
	# Add overlay image if provided
	if overlay_path != "":
		var overlay_sprite = Sprite2D.new()
		overlay_sprite.texture = load(overlay_path)
		overlay_sprite.position = Vector2(360, 240) # Center of 720x480 screen
		overlay_sprite.name = "image_overlay_secondary"
		add_child(overlay_sprite)

func _clear_image_overlays():
	for child in get_children():
		if child.name.begins_with("image_overlay"):
			child.queue_free()

# --- Slide Puzzle ---
func _start_slide_puzzle():
	GameState.slide_puzzle_solved = false
	_clear_puzzle()
	_create_slide_puzzle_pieces()

func _clear_puzzle():
	if is_instance_valid(puzzle_layer):
		puzzle_layer.queue_free()
	puzzle_layer = Node2D.new()
	add_child(puzzle_layer)
	puzzle_grid.clear()
	
func _create_slide_puzzle_pieces():
	for row in range(3):
		puzzle_grid.append([])
		for col in range(3):
			if row == 2 and col == 2:
				puzzle_grid[row].append(null)
				empty_slot = Vector2(row, col)
				continue
			var piece = TextureRect.new()
			piece.texture = load("res://assets/puzzle_piece_%d_%d.png" % [row, col])
			piece.position = Vector2(col, row) * piece_size
			piece.name = "piece_%d_%d" % [row, col]
			piece.mouse_filter = Control.MOUSE_FILTER_STOP
			piece.gui_input.connect(func(event): _on_puzzle_piece_clicked(event, piece))
			puzzle_layer.add_child(piece)
			puzzle_grid[row].append(piece)

func _on_puzzle_piece_clicked(event: InputEvent, piece: TextureRect):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos = _find_piece_position(piece)
		if pos == Vector2(-1, -1):
			return
		if _is_adjacent(pos, empty_slot):
			_swap_piece(pos, empty_slot)
			empty_slot = pos
			if _check_slide_puzzle_solved():
				GameState.slide_puzzle_solved = true
				GameState.puzzle_piece_a = true
				_show_text_dialog("Puzzle Solved!", "You assembled a news article regarding Joe Miner.", "OK", func(): _set_location("computer_screen"))

func _find_piece_position(piece: TextureRect) -> Vector2:
	for row in range(3):
		for col in range(3):
			if puzzle_grid[row][col] == piece:
				return Vector2(row, col)
	return Vector2(-1, -1)

func _is_adjacent(pos_a: Vector2, pos_b: Vector2) -> bool:
	return (abs(pos_a.x - pos_b.x) == 1 and pos_a.y == pos_b.y) or (abs(pos_a.y - pos_b.y) == 1 and pos_a.x == pos_b.x)

func _swap_piece(pos_a: Vector2, pos_b: Vector2) -> void:
	var temp = puzzle_grid[pos_a.x][pos_a.y]
	puzzle_grid[pos_a.x][pos_a.y] = puzzle_grid[pos_b.x][pos_b.y]
	puzzle_grid[pos_b.x][pos_b.y] = temp
	if puzzle_grid[pos_a.x][pos_a.y] != null:
		puzzle_grid[pos_a.x][pos_a.y].position = Vector2(pos_a.y, pos_a.x) * piece_size
	if puzzle_grid[pos_b.x][pos_b.y] != null:
		puzzle_grid[pos_b.x][pos_b.y].position = Vector2(pos_b.y, pos_b.x) * piece_size

func _check_slide_puzzle_solved() -> bool:
	for row in range(3):
		for col in range(3):
			if row == 2 and col == 2:
				continue
			var p = puzzle_grid[row][col]
			if p == null or p.name != "piece_%d_%d" % [row, col]:
				return false
	return true