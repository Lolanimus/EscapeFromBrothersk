#ifndef ESCAPE_FROM_BROTHERSK_PLAYER_H
#define ESCAPE_FROM_BROTHERSK_PLAYER_H

#include <godot_cpp/classes/node2d.hpp>

namespace godot {

class Player : public Node2D {
    GDCLASS(Player, Node2D)

private:
    double speed = 280.0;
    float radius = 18.0f;

protected:
    static void _bind_methods();

public:
    void _process(double delta) override;
    void _draw() override;

    void set_speed(double value);
    double get_speed() const;
};

} // namespace godot

#endif
