# Escape from Brothersk

A small 2D game starter built with **Godot 4.5** and **C++ via GDExtension**.

The starter opens to a playable screen with a native C++ player. Move the blue
circle with `WASD` or the arrow keys.

## Requirements

- Godot 4.5
- Git
- Python 3 and SCons (`python3 -m pip install scons`)
- A C++ compiler (Xcode command-line tools, GCC, or MSVC)

The `godot-cpp` version should match the Godot minor version used to open the
project. This repository tracks the `4.5` branch.

## First-time setup

```sh
git submodule update --init --recursive
python3 -m scons platform=macos arch=arm64
```

Build commands for other common platforms:

```sh
# Linux
python3 -m scons platform=linux

# Windows (run in a Visual Studio developer shell)
python -m scons platform=windows
```

After building, open `project.godot` in Godot and press **F6** or **F5**.

## Development builds

The default build is a debug build. Re-run the matching SCons command whenever
the C++ code changes. To make an optimized build:

```sh
python3 -m scons platform=macos arch=arm64 target=template_release
```

## Layout

- `src/` — native game code and GDExtension registration
- `scenes/` — Godot scenes
- `escape_from_brothersk.gdextension` — native library configuration
- `SConstruct` — native build configuration
- `godot-cpp/` — official bindings, included as a Git submodule

