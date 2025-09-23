Godot Game Jam Prototype

This project implements a minimal playable flow per your outline.

How to run
- Open Godot 4.5 and select this folder (`new-game-project`).
- Press F5 to play; `res://Main.tscn` is set as main.

Controls
- Click the yellow labels to interact (Poster, Computer, Desk, Safe, Closet).
- Press Tab to cycle rooms for quick testing.

Flow
- Poster reveals missing date: 2013-09-17 (computer password).
- Computer unlock -> “solve” article -> gain Puzzle Piece A.
- Desk -> find Puzzle Piece B and a note.
- Safe (requires both pieces) -> get Key.
- Closet (needs Key) -> mirror + surgery paper -> ending.

Files
- `GameState.gd` – global state singleton (autoload).
- `Main.tscn` + `Main.gd` – scene with hotspots, dialogs, and flow logic.

Notes
- Slide puzzle is simplified for now; swap in a real mini-game later.

