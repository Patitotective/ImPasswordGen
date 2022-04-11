# Package

version          = "0.1.1"
author           = "Patitotective"
description      = "A simple password generator GUI application made with ImGui"
license          = "MIT"
namedBin["main"] = "ImPasswordGen"
binDir           = "build"
installFiles     = @["config.niprefs", "assets/icon.png", "assets/style.niprefs", "assets/ProggyVector Regular.ttf", "assets/forkawesome-webfont.ttf"]

# Dependencies

requires "nim >= 1.6.2"
requires "chroma >= 0.2.4"
requires "niprefs >= 0.1.0"
requires "https://github.com/Patitotective/ImStyle >= 0.1.0"
requires "nimgl >= 1.3.2"
requires "stb_image >= 2.5"
requires "passgen >= 0.2.0"
