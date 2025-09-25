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

# Make puzzle_layer a Control (so mouse_filter exists)
var puzzle_layer: Control = Control.new()

const ASSET_PATHS := {
	"title": "res://assets/title-f.png",
	"location1": "res://assets/location1.png",
	"location2": "res://assets/location2.png",
	"location3": "res://assets/location3.png",
	"computer_screen": "res://assets/computerscreen-f.png",
	"closet1": "res://assets/closet1-f.png",
	"closet2": "res://assets/closet2-f.png",
	"joeminer_old": "res://assets/joeminerold-f.png",
	"poster": "res://assets/posterwall.png",
	"safe_open_empty": "res://assets/safe6-f.png",
	"safe_open_key": "res://assets/safe5-f.png",
	"safe_locked": "res://assets/safe1-f.png",
	"safe_piece_a": "res://assets/safe2-f.png", 
	"safe_piece_b": "res://assets/safe3-f.png", 
	"safe_all_pieces": "res://assets/safe4-f.png",
}

var hotspots: Array[Area2D] = []
var puzzle_grid: Array = []
var empty_slot: Vector2 = Vector2(2,2) # row,col (row=2,col=2) is empty slot
var piece_size: Vector2 = Vector2(100, 100)
var computer_unlock_sound = preload("res://assets/computer-unlock.wav")
var key_sound = preload("res://assets/key-pickup.wav")
var desk_grab = preload("res://assets/desk-grab.wav")
var door_unlock = preload("res://assets/door-unlock.wav")
var computer_win = preload("res://assets/computer-win.wav")
var poster_interact = preload("res://assets/poster-interact.wav")
var puzzle_place = preload("res://assets/puzzle-place.wav")
var slide_move = preload("res://assets/slide-move.wav")
var footstep = preload("res://assets/footstep.wav")
var general_interact = preload("res://assets/general-interact.wav")
var bgm = preload("res://assets/bgm.ogg")

# Old-timey font styling
var old_timey_font: Font
var old_timey_font_large: Font

# Background music system
var bgm_player: AudioStreamPlayer
var bgm_muted: bool = false
var mute_button: Button

func _ready():
	_setup_old_timey_fonts()
	_setup_background_music()
	_setup_mute_button()
	var cursor = load("res://assets/cursor.png")
	Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, Vector2(0,16))

	# ensure puzzle_layer is a Control parent and occupies full rect
	_clear_puzzle_layer_init()

	# Start with title screen
	if GameState.current_location == "title":
		_show_title_screen()
	else:
		_set_location(GameState.current_location)

func _clear_puzzle_layer_init():
	# Make sure puzzle_layer is a Control and docked full-rect so it can eat clicks when active
	if is_instance_valid(puzzle_layer):
		puzzle_layer.queue_free()
	puzzle_layer = Control.new()
	puzzle_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	puzzle_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(puzzle_layer)

func _setup_old_timey_fonts():
	# Create old-timey fonts using Godot's built-in font system
	var custom_font_data = null
	if ResourceLoader.exists("res://assets/old_timey_font.ttf"):
		custom_font_data = load("res://assets/old_timey_font.ttf")
	
	if custom_font_data != null:
		# Use custom font if available
		old_timey_font = FontFile.new()
		old_timey_font.font_data = custom_font_data
	else:
		# Use Godot's fallback font with old-timey styling
		old_timey_font = ThemeDB.fallback_font.duplicate()
	
	# Create large font variant
	old_timey_font_large = old_timey_font.duplicate()
	
	# Apply old-timey styling to existing UI elements
	_apply_old_timey_styling()

func _apply_old_timey_styling():
	# Style the info label
	if info_label:
		info_label.add_theme_font_override("font", old_timey_font)
		info_label.add_theme_font_size_override("font_size", 14)
		info_label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5)) # Sepia tone
		info_label.add_theme_color_override("font_shadow_color", Color(0.2, 0.1, 0.0)) # Dark shadow
		info_label.add_theme_constant_override("shadow_offset_x", 2)
		info_label.add_theme_constant_override("shadow_offset_y", 2)
	
	# Style popup elements
	if popup_title:
		popup_title.add_theme_font_override("font", old_timey_font_large)
		popup_title.add_theme_font_size_override("font_size", 18)
		popup_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
		popup_title.add_theme_color_override("font_shadow_color", Color(0.3, 0.2, 0.1))
		popup_title.add_theme_constant_override("shadow_offset_x", 2)
		popup_title.add_theme_constant_override("shadow_offset_y", 2)
	
	if popup_body:
		popup_body.add_theme_font_override("font", old_timey_font)
		popup_body.add_theme_font_size_override("font_size", 14)
		popup_body.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
		popup_body.add_theme_color_override("font_shadow_color", Color(0.2, 0.1, 0.0))
		popup_body.add_theme_constant_override("shadow_offset_x", 1)
		popup_body.add_theme_constant_override("shadow_offset_y", 1)
	
	if popup_line:
		popup_line.add_theme_font_override("font", old_timey_font)
		popup_line.add_theme_font_size_override("font_size", 14)
		popup_line.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
	
	if popup_button_primary:
		popup_button_primary.add_theme_font_override("font", old_timey_font)
		popup_button_primary.add_theme_font_size_override("font_size", 14)
		popup_button_primary.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
		popup_button_primary.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.7))
	
	if popup_button_secondary:
		popup_button_secondary.add_theme_font_override("font", old_timey_font)
		popup_button_secondary.add_theme_font_size_override("font_size", 14)
		popup_button_secondary.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
		popup_button_secondary.add_theme_color_override("font_hover_color", Color(0.9, 0.8, 0.6))

func _setup_background_music():
	# Create background music player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = bgm
	bgm_player.volume_db = -6.0  # 60% volume (approximately -6dB)
	bgm_player.autoplay = true
	# Set loop on the AudioStream itself
	if bgm_player.stream:
		bgm_player.stream.loop = true
	add_child(bgm_player)

func _setup_mute_button():
	# Create mute button in top right corner
	mute_button = Button.new()
	mute_button.text = "🔊"
	mute_button.position = Vector2(650, 10)  # Top right corner
	mute_button.size = Vector2(60, 30)
	mute_button.pressed.connect(_toggle_bgm_mute)
	
	# Style the mute button
	mute_button.add_theme_font_override("font", old_timey_font)
	mute_button.add_theme_font_size_override("font_size", 12)
	mute_button.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
	mute_button.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.7))
	
	# Remove borders and background
	mute_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	mute_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	mute_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	mute_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	add_child(mute_button)

func _toggle_bgm_mute():
	bgm_muted = !bgm_muted
	if bgm_muted:
		bgm_player.volume_db = -80.0  # Mute
		mute_button.text = "🔇"
	else:
		bgm_player.volume_db = -6.0  # 60% volume
		mute_button.text = "🔊"

func _restart_bgm():
	# Restart background music when game is restarted
	if bgm_player and not bgm_muted:
		bgm_player.play()

# --- Hotspot & Room Handling ---
func _clear_hotspots():
	for h in hotspots:
		if is_instance_valid(h):
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
	# If leaving computer, clear puzzle pieces (they live under puzzle_layer)
	if loc != "computer_screen":
		_clear_puzzle()
	
	# Play footstep sound when changing locations (except for title screen and first load)
	if GameState.current_location != loc and GameState.current_location != "title" and loc != "title":
		play_sound(footstep)
	
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
	if GameState.closet_opened:
		return ""
	var lines := []
	# Inventory (keep your existing placeholders but make them visible)
	if GameState.has_badge: lines.append("")
	if GameState.has_paper_intro: lines.append("")
	if GameState.puzzle_piece_a: lines.append("Piece A ")
	if GameState.puzzle_piece_b: lines.append("Piece B ")
	if GameState.has_key: lines.append("Key ")
	if GameState.title_screen_shown:
		lines.append("\nHint: Press Tab to switch rooms.")
	return "".join(lines)

func _input(event: InputEvent) -> void:
	# Tab key: handle leaving computer specially when puzzle active
	if event.is_action_pressed("ui_focus_next"):
		# If on computer screen and puzzle is active, Tab will clear the puzzle and allow exit
		if GameState.current_location == "computer_screen" and GameState.puzzle_active:
			_clear_puzzle()
			GameState.puzzle_active = false
			_set_location("location1")
			return

		# Otherwise normal tab room test switch (keep legacy behavior)
		if GameState.current_location == "location1":
			_set_location("location2")
		elif GameState.current_location == "location2":
			_set_location("location3")
		else:
			_set_location("location1")

	# Skip puzzle with K (testing)
	if event is InputEventKey and event.pressed and event.keycode == KEY_K:
		if not GameState.slide_puzzle_solved and GameState.current_location == "computer_screen":
			_skip_slide_puzzle()

func _skip_slide_puzzle():
	GameState.slide_puzzle_solved = true
	GameState.puzzle_piece_a = true
	GameState.puzzle_active = false
	_clear_puzzle()
	_set_location("computer_screen")

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
	# Apply old-timey styling to hotspot labels
	l.add_theme_font_override("font", old_timey_font)
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6)) # Golden yellow
	l.add_theme_color_override("font_shadow_color", Color(0.3, 0.2, 0.0)) # Dark shadow
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
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

	# If puzzle is active, do not add hotspots (prevents leaving by click)
	if GameState.puzzle_active:
		return

	match loc:
		"location1":
			_add_hotspot(Rect2(180, 220, 160, 90), "", func(): _on_computer())
			_add_hotspot(Rect2(560, 250, 130, 100), "", func(): _on_desk())
			_add_hotspot(Rect2(680, 20, 230, 250), "", func(): _set_location("location2"))
		"location2":
			_add_hotspot(Rect2(450, 60, 150, 170), "", func(): _on_poster())
			_add_hotspot(Rect2(40, 170, 140, 100), "", func(): _set_location("location1"))
			_add_hotspot(Rect2(680, 220, 140, 100), "", func(): _set_location("location3"))
		"location3":
			_add_hotspot(Rect2(320, 120, 170, 220), "", func(): _on_closet())
			_add_hotspot(Rect2(80, 50, 115, 160), "", func(): _on_safe())
			_add_hotspot(Rect2(10, 200, 60, 200), "", func(): _set_location("location2"))
		"computer_screen":
			# only add Back hotspot when puzzle is not active
			if not GameState.puzzle_active:
				_add_hotspot(Rect2(40, 220, 140, 100), "", func(): _set_location("location1"))
		"poster":
			_add_hotspot(Rect2(0, 0, 720, 480), "", func(): _set_location("location2"))
		"safe_locked", "safe_piece_a", "safe_piece_b":
			_add_hotspot(Rect2(0, 0, 720, 480), "", func(): _set_location("location3"))
		"safe_open_key":
			_add_hotspot(Rect2(350, 300, 100, 100), "Take Key", func():
				GameState.has_key = true
				GameState.safe_opened = true
				_set_location("safe_open_empty")
			)
		"safe_open_empty":
			_add_hotspot(Rect2(0, 0, 720, 480), "", func(): _set_location("location3"))

# --- Room Interactions ---
func _on_poster():
	_set_location("poster")
	play_sound(poster_interact)

func _on_computer():
	if not GameState.computer_unlocked:
		_show_input_dialog("Computer Login", "Enter password (missing date, YYYY-MM-DD):", "Unlock", func(): _attempt_login(), "Cancel", func(): popup.hide())
		return

	# move to computer background first
	_set_location("computer_screen")
	play_sound(computer_unlock_sound)

	# start puzzle (this sets puzzle_active and also clears hotspots right away)
	if not GameState.slide_puzzle_solved:
		_start_slide_puzzle()
	else:
		_show_text_dialog("Computer", "Nothing else useful here.", "OK", func(): popup.hide())
		play_sound(general_interact)

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
		_show_text_dialog("Desk", "Taped underneath this unassuming desk is half of a puzzle piece", "OK", func(): popup.hide())
		play_sound(desk_grab)
	else:
		_show_text_dialog("Desk", "Nothing else under here.", "OK", func(): popup.hide())
		play_sound(general_interact)

func _on_safe():
	_safe_screens()
	if GameState.safe_opened:
		_show_text_dialog("Safe", "Already open. I took the key.", "OK", func(): popup.hide())
		play_sound(general_interact)
		return
	if GameState.can_open_safe():
		GameState.safe_opened = true
		GameState.has_key = true
		_show_text_dialog("Safe", "The pieces fit. The safe clicks open, revealing a key.", "Continue", func(): popup.hide())
		play_sound(key_sound)
	else:
		_show_text_dialog("Safe", "It seems as though two puzzle pieces are required to open this safe.", "OK", func(): popup.hide())
		play_sound(general_interact)
	
func _on_closet():
	if not GameState.has_key:
		_show_text_dialog("Closet", "Locked. I need a key.", "OK", func(): popup.hide())
		play_sound(general_interact)
		return
	if not GameState.closet_opened:
		GameState.closet_opened = true
		info_label.text = _make_info_text()
		_show_image_overlay(ASSET_PATHS["closet1"])
		_show_text_dialog("Closet", "The closet is now open. I can see inside.", "Look Inside", func(): _reveal_identity())
		play_sound(door_unlock)
	else:
		_reveal_identity()

func _reveal_identity():
	_clear_image_overlays()
	_show_image_overlay(ASSET_PATHS["closet2"], ASSET_PATHS["joeminer_old"])
	_show_text_dialog("Closet", "Inside is a mirror and paperwork revealing I altered my appearence. I recognize myself — I'm Joe Miner.", 
		"Continue", func(): _end_game()
	)

func _end_game():
	if not GameState.game_over:
		GameState.game_over = true
		# Stop background music when game is completed
		if bgm_player:
			bgm_player.stop()
		_show_text_dialog("The End", "I wanted to forget...",
			"Restart", func(): GameState.reset(); _restart_bgm(); _set_location("title"); popup.hide(),
			"Quit", func(): get_tree().quit()
		)

func _look_inside_closet():
	GameState.closet_looked_at = true
	_show_image_overlay(ASSET_PATHS["closet2"], ASSET_PATHS["joeminer_old"])
	_show_text_dialog("Closet", "Inside is a standing mirror and paperwork: evidence of plastic surgery to hide my identity. I recognize myself in the mirror.", "Continue", func(): _close_closet_view())

func _close_closet_view():
	_clear_image_overlays()
	popup.hide()

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
	_clear_image_overlays()
	var main_sprite = Sprite2D.new()
	main_sprite.texture = load(image_path)
	if main_sprite.texture:
		main_sprite.centered = true
		main_sprite.position = get_viewport_rect().size / 2
	main_sprite.name = "image_overlay_main"
	add_child(main_sprite)
	if overlay_path != "":
		var overlay_sprite = Sprite2D.new()
		overlay_sprite.texture = load(overlay_path)
		if overlay_sprite.texture:
			overlay_sprite.centered = true
			overlay_sprite.position = get_viewport_rect().size / 2
		overlay_sprite.name = "image_overlay_secondary"
		add_child(overlay_sprite)

func _clear_image_overlays():
	for child in get_children():
		if child.name.begins_with("image_overlay"):
			child.queue_free()

func _show_title_screen():
	_clear_hotspots()
	_clear_room_text()
	_clear_image_overlays()
	
	# Set title background
	_update_background("title")
	
	_add_hotspot(Rect2(0, 0, 720, 480), "", func(): _start_game())
	
	var start_label = Label.new()
	start_label.text = "Click anywhere to start"
	start_label.position = Vector2(360 - 100, 400) # Center horizontally, near bottom
	start_label.add_theme_font_override("font", old_timey_font)
	start_label.add_theme_font_size_override("font_size", 16)
	start_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6)) # Golden yellow
	start_label.add_theme_color_override("font_shadow_color", Color(0.3, 0.2, 0.0)) # Dark shadow
	start_label.add_theme_constant_override("shadow_offset_x", 2)
	start_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(start_label)
	hotspots.append(start_label)

func _start_game():
	GameState.title_screen_shown = true
	GameState.current_location = "location1"
	_set_location("location1")

# --- Slide Puzzle ---
func _start_slide_puzzle():
	# Mark puzzle active and clear hotspots so clicks cannot leave
	GameState.slide_puzzle_solved = false
	GameState.puzzle_active = true
	_clear_hotspots()
	_clear_puzzle()
	_create_slide_puzzle_pieces()

func _clear_puzzle():
	# Remove existing puzzle layer and recreate a Control that can eat clicks when active
	if is_instance_valid(puzzle_layer):
		puzzle_layer.queue_free()
	puzzle_layer = Control.new()
	puzzle_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	puzzle_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(puzzle_layer)
	# clear grid state - pieces will be added as children of puzzle_layer
	for row in puzzle_grid:
		for piece in row:
			if piece != null and is_instance_valid(piece):
				piece.queue_free()
	puzzle_grid.clear()

func _create_slide_puzzle_pieces() -> void:
	# Create grid with null in bottom-right, then place pieces and connect input
	puzzle_grid.clear()
	for row in range(3):
		puzzle_grid.append([])
		for col in range(3):
			if row == 2 and col == 2:
				puzzle_grid[row].append(null)
				empty_slot = Vector2(row, col)
				continue

			var piece = TextureRect.new()
			piece.texture = load("res://assets/puzzle_piece_%d_%d.png" % [row, col])
			# layout properties
			piece.expand = true
			piece.stretch_mode = TextureRect.STRETCH_SCALE
			piece.custom_minimum_size = piece_size
			piece.position = Vector2(col, row) * piece_size
			piece.name = "piece_%d_%d" % [row, col]
			# add to puzzle_layer (so we can clear them easily)
			puzzle_layer.add_child(piece)
			puzzle_grid[row].append(piece)
			# connect GUI input; bind the piece instance so handler gets it
			piece.gui_input.connect(Callable(self, "_on_piece_gui_input").bind(piece))

	# scramble after creation (keeps bottom-right slot empty)
	_scramble_puzzle()

func _scramble_puzzle() -> void:
	var pieces = []
	# collect all non-null pieces
	for row in puzzle_grid:
		for piece in row:
			if piece != null:
				pieces.append(piece)
	pieces.shuffle()
	var i = 0
	for row in range(3):
		for col in range(3):
			if puzzle_grid[row][col] != null:
				var piece = pieces[i]
				puzzle_grid[row][col] = piece
				# ensure piece parent is puzzle_layer
				if piece.get_parent() != puzzle_layer:
					piece.get_parent().remove_child(piece)
					puzzle_layer.add_child(piece)
				piece.position = Vector2(col, row) * piece_size
				i += 1
	# ensure empty_slot is accurate (still bottom-right unless you want to randomize)
	empty_slot = Vector2(2,2)

# handler for gui_input signal; receives bound piece as second arg
func _on_piece_gui_input(event: InputEvent, piece: TextureRect) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_piece_clicked(piece)

func _on_piece_clicked(piece: TextureRect) -> void:
	# find piece position (returns Vector2(row, col) or (-1,-1) if not found)
	var pos = _find_piece_position(piece)
	if pos == Vector2(-1, -1):
		return
	var row = int(pos.x)
	var col = int(pos.y)

	# directions are row, col pairs: up, down, left, right
	var directions = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]
	for d in directions:
		var nr = row + int(d.x)
		var nc = col + int(d.y)
		if nr >= 0 and nr < 3 and nc >= 0 and nc < 3:
			if puzzle_grid[nr][nc] == null:
				# move piece into empty slot
				puzzle_grid[nr][nc] = piece
				puzzle_grid[row][col] = null
				# update visual position
				piece.position = Vector2(nc, nr) * piece_size
				# update empty slot to previous location
				empty_slot = Vector2(row, col)
				# play slide move sound
				play_sound(slide_move)
				# check solved
				if _check_slide_puzzle_solved():
					GameState.slide_puzzle_solved = true
					GameState.puzzle_active = false
					GameState.puzzle_piece_a = true
					play_sound(puzzle_place)
					_clear_puzzle()
					_show_text_dialog("Puzzle Solved!", "You assembled the article.", "OK", func(): _set_location("computer_screen"))
				return

func _find_piece_position(piece: TextureRect) -> Vector2:
	for row in range(3):
		for col in range(3):
			if puzzle_grid[row][col] == piece:
				return Vector2(row, col) # row, col
	return Vector2(-1, -1)

func _is_adjacent(pos_a: Vector2, pos_b: Vector2) -> bool:
	# pos: Vector2(row, col)
	return (abs(pos_a.x - pos_b.x) == 1 and pos_a.y == pos_b.y) or (abs(pos_a.y - pos_b.y) == 1 and pos_a.x == pos_b.x)

func _swap_piece(pos_a: Vector2, pos_b: Vector2) -> void:
	# Not used now (logic in _on_piece_clicked), but keep consistent if used
	# pos = Vector2(row, col)
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
	play_sound(computer_win)
	return true
	
func _safe_screens():
	if GameState.safe_opened and GameState.has_key:
		_set_location("safe_open_empty")
		return
	if GameState.puzzle_piece_a and GameState.puzzle_piece_b and not GameState.safe_opened:
		_set_location("safe_open_key")
		return
	if GameState.puzzle_piece_a and not GameState.puzzle_piece_b:
		_set_location("safe_piece_a")
		return
	if GameState.puzzle_piece_b and not GameState.puzzle_piece_a:
		_set_location("safe_piece_b")
		return
	_set_location("safe_locked")
	
func play_sound(audio_stream: AudioStream):
	var player = AudioStreamPlayer.new()
	player.stream = audio_stream
	add_child(player)
	player.play()
	# optionally free after playback
	var duration = 0.0
	if player.stream:
		duration = player.stream.get_length()
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout
	player.queue_free()
