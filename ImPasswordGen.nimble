# Package

version          = "0.3.0"
author           = "Patitotective"
description      = "A simple password generator GUI application made with ImGui"
license          = "MIT"
namedBin["main"] = "ImPasswordGen"

# Dependencies

requires "nim >= 1.6.2"
requires "nake >= 1.9.4"
requires "nimgl >= 1.3.2"
requires "chroma >= 0.2.4"
requires "passgen >= 0.2.0"
requires "stb_image >= 2.5"
requires "imstyle >= 0.3.4 & < 0.4.0"
requires "niprefs >= 0.3.4 & < 0.4.0"

import std/[strformat, os]

let arch = if existsEnv("ARCH"): getEnv("ARCH") else: "amd64"
let outPath = if existsEnv("OUTPATH"): getEnv("OUTPATH") else: &"{namedBin[\"main\"]}-{version}-{arch}" & (when defined(Windows): ".exe" else: "")
let flags = getEnv("FLAGS")

task buildApp, "Build the application":
  exec "nimble install -d -y"
  exec fmt"nim cpp -d:release --app:gui --out:{outPath} --cpu:{arch} {flags} main.nim"

task runApp, "Build and run the application":
  exec "nimble buildApp"

  exec fmt"./{outPath}"

