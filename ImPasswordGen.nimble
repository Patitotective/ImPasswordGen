# Package

version          = "0.1.1"
author           = "Patitotective"
description      = "A simple password generator GUI application made with ImGui"
license          = "MIT"
namedBin["main"] = "ImPasswordGen"

# Dependencies

requires "nim >= 1.6.2"
requires "nake >= 1.9.4"
requires "nimgl >= 1.3.2"
requires "chroma >= 0.2.4"
requires "niprefs >= 0.2.2"
requires "stb_image >= 2.5"
requires "passgen >= 0.2.0"
requires "https://github.com/Patitotective/ImStyle >= 0.1.0"

task buildApp, "Build the application":
  exec "nimble install -d -y"
  exec "nim cpp -d:release --app:gui " & "-o:" & namedBin["main"] & " main"

task runApp, "Build and run the application":
  exec "nimble install -d -y"
  exec "nim cpp -r -d:release --app:gui " & "-o:" & namedBin["main"] & " main"
