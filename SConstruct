#!/usr/bin/env python

import os

env = SConscript("godot-cpp/SConstruct")

env.Append(CPPPATH=["src"])

sources = Glob("src/*.cpp")

if env["platform"] == "macos":
    framework_name = "libescape_from_brothersk.{}.{}".format(env["platform"], env["target"])
    output_path = os.path.join("bin", framework_name + ".framework", framework_name)
else:
    output_path = os.path.join(
        "bin",
        "libescape_from_brothersk{}{}".format(env["suffix"], env["SHLIBSUFFIX"]),
    )

library = env.SharedLibrary(output_path, source=sources)
env.NoCache(library)
Default(library)
