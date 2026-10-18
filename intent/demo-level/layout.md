# Demo Level Layout

The demo uses seven rooms and one alternate side passage. Storage is the selected
room variant; there is no showers room in this layout.

```text
┌──────────────┬──────────────────────────┬────────────────────┬────────────────────┐
│ Starting     │ Cell block               │ Guard office       │ Storage            │
│ cell         │                          │                    │                    │
└─────── door ─┤                 door ────┤                    ├──── door ──────────┤
               │                          └────── door ─────────┴────── door ────────┘
               │                                      Central corridor              │
               └──── door ────┐              ┌──────────── door ──────── door ─────┘
                              │              │ Exercise yard              │ Exit    │
                              │ Alternate    │                            │         │
                              │ passage ─────┤                    door ───┤         │
                              └──────────────┴────────────────────────────┴─ exit ───┘
```

## World geometry

Coordinates are Godot world-space rectangles in `(x, y, width, height)` form.

| Area | Rectangle |
| --- | --- |
| Starting cell | `(100, 100, 250, 250)` |
| Cell block | `(350, 100, 500, 500)` |
| Guard office | `(850, 100, 400, 300)` |
| Storage | `(1250, 100, 400, 300)` |
| Central corridor | `(850, 400, 800, 200)` |
| Exercise yard | `(850, 600, 600, 500)` |
| Exit | `(1450, 600, 200, 500)` |
| Alternate passage (not a room) | `(350, 600, 500, 200)` |

## Route graph

- Main route: starting cell → cell block → guard office → storage → central corridor → exercise yard → exit.
- Cross-connection: cell block → central corridor.
- Alternate route: cell block → alternate passage → exercise yard.
- The exit room has an outward opening reserved for the level-completion behavior.

All connections are physical gaps in static walls. Scene-level tests traverse both
the main and alternate routes using the configured movement actions and verify the
area reached from the player's observable world position.
