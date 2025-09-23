Godot Game Jam Prototype

This project implements a minimal playable flow per your outline.

Quick setup
- Install Godot 4.5 (or matching 4.x).
- Open Godot → Import/Scan → select this folder (`new-game-project`).
- Ensure these background images exist in `res://assets/`:
  - `location1.png` – classroom (Missing Poster, Computer, Desk)
  - `location2.png` – safe room (Safe, Small Door)
  - `location3.png` – closet (Closet/Mirror)
  Copy your existing images from the workspace root into `new-game-project/assets/` and rename if needed.

Run the game
- Press F5 (Play the Project). Main scene is `res://Main.tscn`.
- You should see yellow hotspot labels over the background.

Controls
- Left-click a yellow label to interact.
- Tab cycles rooms quickly for testing (Location1 → Location2 → Location3 → back).
- In popups:
  - Use the text field to type the computer password.
  - Click the primary button to confirm; secondary to cancel/close.

Goal and flow
- You awaken in a classroom with a badge and a note (implied inventory).
- Investigate in any order; the intended flow:
  1) Poster: reveals missing date for Joe Miner — use this as the password.
     - Password format: YYYY-MM-DD
     - Current value in prototype: 2013-09-17
  2) Computer: enter the password. Click Solve to “assemble” the article.
     - Grants Puzzle Piece A.
  3) Desk: search under the desk.
     - Grants Puzzle Piece B and hints about a new identity.
  4) Safe (in the conjoined room): requires both pieces.
     - Opens and gives you a Key.
  5) Closet (third room): unlock with the Key to reach the ending.
     - Shows mirror and surgery verification → ending screen with Restart/Quit.

Testing shortcuts
- You can visit rooms out of order using Tab.
- The Computer puzzle is abstracted to a “Solve” button for now.

Where to change things
- Password/date: edit `Main.gd` inside `_on_poster()` text and `_attempt_login()` check.
- Inventory/flags and reset: `GameState.gd`.
- Hotspot rectangles or labels: see `_update_hotspots_for_location()` in `Main.gd`.
- Background images: replace files in `res://assets/` with the same names.

Troubleshooting
- Error: Expected new line after "\" (in .gd files)
  - Cause: file contains visible "\t" instead of a real tab. Fix by Find: `\t` → Replace with a real Tab, save.
- Error: Unindent doesn't match the previous indentation level
  - Ensure commas in multi-argument function calls are at the end of a line, not alone on a new line.
- Background not visible
  - Confirm images exist at `res://assets/location1.png` etc. Reimport if needed (right-click → Reimport).

Files
- `GameState.gd` – global state (autoload). Tracks inventory and progress.
- `Main.tscn` + `Main.gd` – scene, UI popups, hotspots, and flow logic.

Next steps (nice-to-have)
- Replace the computer “Solve” with an actual slide puzzle mini-game.
- Convert labels to invisible hotspots with hover outlines/tooltips.
- Add inventory UI, sounds, transitions, and save/load.

