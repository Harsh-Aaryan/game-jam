extends Node2D

# UI node references for popup dialogs and inventory display
@onready var background: Sprite2D = $Background
@onready var ui_layer: CanvasLayer = $UI
@onready var info_label: Label = $UI/Info
@onready var popup: PopupPanel = $UI/Popup
@onready var popup_title: Label = $UI/Popup/Margin/VBox/Title
@onready var popup_body: Label = $UI/Popup/Margin/VBox/Body
@onready var popup_line: LineEdit = $UI/Popup/Margin/VBox/Line
@onready var popup_button_primary: Button = $UI/Popup/Margin/VBox/Buttons/Primary
@onready var popup_button_secondary: Button = $UI/Popup/Margin/VBox/Buttons/Secondary

# Background image paths for each location
const ASSET_PATHS := {
	"location1": "res://assets/location1.png",
	"location2": "res://assets/location2.png",
	"location3": "res://assets/location3.png",
	"computer_screen": "res://assets/computerscreen-f.png",
}

# Array to track clickable hotspot areas
var hotspots: Array[Area2D] = []
var puzzle_grid: Array = []
var empty_slot: Vector2 = Vector2(2,2)
var piece_size: Vector2 = Vector2(100, 100) # adjust to your puzzle piece size

# Initialize game - set starting location and custom cursor
func _ready():
	_set_location(GameState.current_location)
	var cursor = load("res://assets/cursor.png")
	Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, Vector2(0,16))
	_apply_old_font_style()

# Remove all clickable hotspot areas when changing rooms
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

# Switch to a different location/room
func _set_location(loc: String) -> void:
	_clear_hotspots()
	_clear_room_text()
	GameState.current_location = loc
	_update_background(loc)
	_update_hotspots_for_location(loc)

# Load and display background image for current location
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
	lines.append("\nHint: Click hotspots. Press Tab to switch rooms.")
	return "".join(lines)

# Handle keyboard input - Tab key cycles through rooms for testing
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"):
		# Tab key switches rooms for testing
		if GameState.current_location == "location1":
			_set_location("location2")
		elif GameState.current_location == "location2":
			_set_location("location3")
		else:
			_set_location("location1")

# Create a clickable hotspot area with label and cursor changes
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
	
	# Create yellow label for the hotspot
	var l := Label.new()
	l.text = label
	l.position = rect.position
	l.modulate = Color(1,1,0)
	add_child(l)
	
	#Change cursor on interactable
	var finger_cursor = preload("res://assets/cursor.png")
	var eye_cursor = preload("res://assets/interact.png")
	area.mouse_entered.connect(func():
		Input.set_custom_mouse_cursor(eye_cursor, Input.CURSOR_ARROW, Vector2(16, 16))
	)
	area.mouse_exited.connect(func():
		Input.set_custom_mouse_cursor(finger_cursor, Input.CURSOR_ARROW, Vector2(6, 28))
	)
	
	# Handle left-click on hotspot
	area.input_event.connect(func(_viewport, e, _shape_idx):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			on_press.call()
		)
	
	area.input_event.connect(func(_viewport, e, _shape_idx):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			on_press.call())
	hotspots.append(area)
	hotspots.append(l)

# Set up clickable hotspots for each room/location
func _update_hotspots_for_location(loc: String) -> void:
	_clear_hotspots()
	match loc:
		"location1": # Classroom - Poster, Computer, Desk, door to Safe Room
			_add_hotspot(Rect2(40, 60, 140, 100), "Poster", func(): _on_poster())
			_add_hotspot(Rect2(300, 160, 160, 90), "Computer", func(): _on_computer())
			_add_hotspot(Rect2(520, 220, 180, 100), "Desk", func(): _on_desk())
			_add_hotspot(Rect2(700, 20, 120, 120), "Go to Safe Room", func(): _set_location("location2"))
		"location2": # Safe Room - Safe, doors back to Class and to Closet
			_add_hotspot(Rect2(360, 120, 180, 180), "Safe", func(): _on_safe())
			_add_hotspot(Rect2(40, 220, 140, 100), "Back to Class", func(): _set_location("location1"))
			_add_hotspot(Rect2(680, 220, 140, 100), "Small Door", func(): _set_location("location3"))
		"location3": # Closet - Closet/Mirror, door back to Safe Room
			_add_hotspot(Rect2(320, 120, 200, 220), "Closet", func(): _on_closet())
			_add_hotspot(Rect2(40, 220, 140, 100), "Back to Safe Room", func(): _set_location("location2"))
		"computer_screen":
			_add_hotspot(Rect2(40, 220, 140, 100), "Back", func(): _set_location("location1"))

# Show missing poster with the date needed for computer password
func _on_poster():
	# Show missing poster with date for password
	_show_text_dialog("Missing Poster",
		"Missing: Joe Miner. Went missing on 2013-09-17.\nPassword hint: The date (YYYY-MM-DD).",
		"OK",
		func(): popup.hide())

# Handle computer interaction - login then puzzle
func _on_computer():
	if not GameState.computer_unlocked:
		_show_input_dialog("Computer Login", "Enter password (missing date, YYYY-MM-DD):", "Unlock", func(): _attempt_login(), "Cancel", func(): popup.hide())
		return

	_set_location("computer_screen")

	if not GameState.slide_puzzle_solved:
		_start_slide_puzzle()
	else:
		_show_text_dialog("Computer", "Nothing else useful here.", "OK", func(): popup.hide())

# Check computer password and unlock if correct
func _attempt_login() -> void:
	if popup_line.text.strip_edges() == "2013-09-17":
		GameState.computer_unlocked = true
		popup.hide()
		_on_computer()
	else:
		popup_body.text = "Incorrect. Try again."

# Search desk for puzzle piece and identity clues
func _on_desk():
	if not GameState.desk_checked:
		GameState.desk_checked = true
		GameState.puzzle_piece_b = true
		_show_text_dialog("Desk", "Taped underneath is the other half of the puzzle and a note hinting at a new identity.", "OK", func(): popup.hide())
	else:
		_show_text_dialog("Desk", "Nothing else under here.", "OK", func(): popup.hide())

# Try to open safe with puzzle pieces
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

# Open closet with key to reach the ending
func _on_closet():
	if not GameState.has_key:
		_show_text_dialog("Closet", "Locked. You need a key.", "OK", func(): popup.hide())
		return
	if not GameState.closet_opened:
		GameState.closet_opened = true
		_show_text_dialog("Closet", "Inside is a standing mirror and paperwork: evidence of plastic surgery to hide your identity.", "Continue", func(): popup.hide())
	else:
		_end_game()

# Show ending dialog with restart/quit options
func _end_game():
	if not GameState.game_over:
		GameState.game_over = true
		_show_text_dialog("The End",
			"You recognize yourself in the mirror. You were Joe Miner, hidden behind a new identity.",
			"Restart",
			func():
				GameState.reset()
				_set_location(GameState.current_location)
				popup.hide(),
			"Quit",
			func(): get_tree().quit())

# Show popup dialog with title, message, and buttons
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

# Show popup dialog with text input field for passwords
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
