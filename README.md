# Escape from Brothersk

A small 2D game starter built with **Godot 4.5** and **GDScript**.

Move the blue circle with `WASD` or the arrow keys. Movement is normalized
diagonally and the player stays within the viewport.

## Requirements

- Godot 4.5 (standard edition)

## First-time setup

1. Clone or download this repository.
2. Import `project.godot` in Godot.
3. Open the project and press **F5** to run.

No native compiler, build step, or submodule setup is required.

## Development

Edit `scripts/player.gd` in Godot's script editor. Select the Player node in
`scenes/main.tscn` to adjust its exported `speed` property in the Inspector.
Movement actions are configured under **Project > Project Settings > Input Map**.

## Layout

- `scripts/` — GDScript game code
- `scenes/` — Godot scenes
- `project.godot` — project settings and input actions
- `docs/` — game design notes
