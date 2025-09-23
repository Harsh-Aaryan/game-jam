extends Node



var has_badge: bool = true
var has_paper_intro: bool = true
var computer_unlocked: bool = false
var slide_puzzle_solved: bool = false
var desk_checked: bool = false
var puzzle_piece_a: bool = false
var puzzle_piece_b: bool = false
var safe_opened: bool = false
var has_key: bool = false
var closet_opened: bool = false
var game_over: bool = false

var current_location: String = "location1"

func reset():
	has_badge = true
	has_paper_intro = true
	computer_unlocked = false
	slide_puzzle_solved = false
	desk_checked = false
	puzzle_piece_a = false
	puzzle_piece_b = false
	safe_opened = false
	has_key = false
	closet_opened = false
	game_over = false
	current_location = "location1"

func has_both_pieces() -> bool:
	return puzzle_piece_a && puzzle_piece_b

func can_open_safe() -> bool:
	return has_both_pieces()

func debug_state() -> Dictionary:
	return {
		"loc": current_location,
		"comp_unlocked": computer_unlocked,
		"puzzle": slide_puzzle_solved,
		"desk": desk_checked,
		"A": puzzle_piece_a,
		"B": puzzle_piece_b,
		"safe": safe_opened,
		"key": has_key,
		"closet": closet_opened,
		"over": game_over,
	}
