extends RefCounted
## Gunfire travels through walls; seeing the source still requires line of sight.

static func notify(scene: Node, origin: Vector2) -> void:
	for policeman in scene.get_tree().get_nodes_in_group("police"):
		if policeman.has_method("hear_gunfire"):
			policeman.hear_gunfire(origin)
