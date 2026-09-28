#include "register_types.h"

#include "player.h"

#include <godot_cpp/godot.hpp>

using namespace godot;

void initialize_escape_from_brothersk_module(ModuleInitializationLevel level) {
    if (level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }

    GDREGISTER_CLASS(Player);
}

void uninitialize_escape_from_brothersk_module(ModuleInitializationLevel level) {
    if (level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }
}

extern "C" {

GDExtensionBool GDE_EXPORT escape_from_brothersk_library_init(
        GDExtensionInterfaceGetProcAddress get_proc_address,
        const GDExtensionClassLibraryPtr library,
        GDExtensionInitialization *initialization) {
    GDExtensionBinding::InitObject init_obj(get_proc_address, library, initialization);

    init_obj.register_initializer(initialize_escape_from_brothersk_module);
    init_obj.register_terminator(uninitialize_escape_from_brothersk_module);
    init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

    return init_obj.init();
}

}

