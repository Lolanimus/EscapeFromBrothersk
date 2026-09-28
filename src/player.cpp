#include "player.h"

#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/math.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/vector2.hpp>

using namespace godot;

void Player::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_speed", "speed"), &Player::set_speed);
    ClassDB::bind_method(D_METHOD("get_speed"), &Player::get_speed);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "speed", PROPERTY_HINT_RANGE, "0,1000,1"), "set_speed", "get_speed");
}

void Player::_process(double delta) {
    Input *input = Input::get_singleton();
    Vector2 direction = input->get_vector("move_left", "move_right", "move_up", "move_down");

    Vector2 next_position = get_position() + direction * speed * delta;
    const Vector2 viewport_size = get_viewport_rect().size;

    next_position.x = Math::clamp(next_position.x, radius, viewport_size.x - radius);
    next_position.y = Math::clamp(next_position.y, radius, viewport_size.y - radius);
    set_position(next_position);
}

void Player::_draw() {
    draw_circle(Vector2(), radius + 5.0, Color(0.12, 0.2, 0.34, 0.8));
    draw_circle(Vector2(), radius, Color(0.22, 0.66, 1.0));
    draw_circle(Vector2(-5.0, -4.0), 3.0, Color(0.92, 0.97, 1.0));
}

void Player::set_speed(double value) {
    speed = MAX(value, 0.0);
}

double Player::get_speed() const {
    return speed;
}
