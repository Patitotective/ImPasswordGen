import std/[strutils, sequtils, browsers, os]

import imstyle
import niprefs
import passgen
import nimgl/[opengl, glfw]
import nimgl/imgui, nimgl/imgui/[impl_opengl, impl_glfw]

import src/[utils, prefsmodal, icons]

const
  resourcesDir = "data"
  configPath = "config.niprefs"

proc getPath(path: string): string = 
  # When running on an AppImage get the path from the AppImage resources
  when defined(appImage):
    result = getEnv"APPDIR" / resourcesDir / path.extractFilename()
  else:
    result = getAppDir() / path

proc getPath(path: PrefsNode): string = 
  path.getString().getPath()

proc drawAboutModal(app: var App) = 
  var center: ImVec2
  getCenterNonUDT(center.addr, igGetMainViewport())
  igSetNextWindowPos(center, Always, igVec2(0.5f, 0.5f))

  if igBeginPopupModal("About " & app.config["name"].getString(), flags = makeFlags(AlwaysAutoResize)):

    # Display icon image
    var
      texture: GLuint
      image = app.config["iconPath"].getPath().readImage()
    image.loadTextureFromData(texture)
    
    igImage(cast[ptr ImTextureID](texture), igVec2(64, 64)) # Or igVec2(image.width.float32, image.height.float32)

    igSameLine()
    
    igPushTextWrapPos(250)
    igTextWrapped(app.config["comment"].getString())
    igPopTextWrapPos()

    igSpacing()

    igTextWrapped("Credits: " & app.config["authors"].getSeq().mapIt(it.getString()).join(", "))

    if igButton("Ok"):
      igCloseCurrentPopup()

    igSameLine()

    igText(app.config["version"].getString())

    igEndPopup()

proc genPassword(app: var App) = 
  app.password = app.pg.getPassword().replace("%", "%%") # Since a single % mean format
  app.copyBtnText = "Copy " & FA_FilesO

proc copyPassword(app: var App) = 
  app.win.setClipboardString(app.password)
  app.copyBtnText = "Copied"

proc drawMenuBar(app: var App) =
  var openAbout, openPrefs = false

  if igBeginMenuBar():
    if igBeginMenu("File"):
      igMenuItem("Preferences " & FA_Cog, "Ctrl+P", openPrefs.addr)
      if igMenuItem("Quit " & FA_Times, "Ctrl+Q"):
        app.win.setWindowShouldClose(true)
      igEndMenu()

    if igBeginMenu("Edit"):
      if igMenuItem("Generate", "Ctrl+G"):
        app.genPassword()
      if igMenuItem("Copy " & FA_FilesO, "Ctrl+C"):
        app.copyPassword()

      igEndMenu()

    if igBeginMenu("About"):
      if igMenuItem("Website " & FA_Heart):
        app.config["website"].getString().openDefaultBrowser()

      igMenuItem("About " & app.config["name"].getString(), shortcut = nil, p_selected = openAbout.addr)

      igEndMenu() 

    igEndMenuBar()

  # See https://github.com/ocornut/imgui/issues/331#issuecomment-751372071
  if openPrefs:
    igOpenPopup("Preferences")
  if openAbout:
    igOpenPopup("About " & app.config["name"].getString())

  # These modals will only get drawn when igOpenPopup(name) are called, respectly
  app.drawAboutModal()
  app.drawPrefsModal()

proc drawMain(app: var App) = # Draw the main window
  igBegin(app.config["name"].getString(), flags = makeFlags(ImGuiWindowFlags.NoResize, NoMove, NoTitleBar, NoCollapse, MenuBar))
  igSetWindowPos(igVec2(0, 0), Always)

  app.drawMenuBar()

  let style = igGetStyle()
  var
    size: ImVec2 # All widgets size
    avail: ImVec2
    textSize: ImVec2
    btnsSize: ImVec2
    genBtnSize: ImVec2

  igGetContentRegionAvailNonUDT(avail.addr)

  # Calculate password text size
  igCalcTextSizeNonUDT(textSize.addr, app.password)

  if textSize.x > avail.x + 20:
    textSize.y += 17

  # Calculate buttons size
  igCalcTextSizeNonUDT(genBtnSize.addr, "Generate")

  btnsSize += genBtnSize
  btnsSize += style.itemSpacing
  btnsSize += genBtnSize
  btnsSize += style.framePadding * 4 # Two for each button

  genBtnSize.x += style.framePadding.x * 2
  genBtnSize.y = 0 # So it calculates it

  size += textSize
  size += btnsSize

  centerCursorY(size.y)

  igBeginChild("Password", igVec2(avail.x, textSize.y), false, makeFlags(HorizontalScrollbar))

  centerCursorX(textSize.x)
  igText(app.password)

  igEndChild()

  centerCursorX(btnsSize.x)

  if igButton("Generate", genBtnSize):
    app.genPassword()

  igSameLine()

  if igButton(app.copyBtnText, genBtnSize):
    app.copyPassword()

  # Update ImGUi window size to fit GLFW window size
  var width, height: int32
  app.win.getWindowSize(width.addr, height.addr)
  igSetWindowSize(igVec2(width.float32, height.float32), Always)

  igEnd()

proc display(app: var App) = # Called in the main loop
  glfwPollEvents()

  igOpenGL3NewFrame()
  igGlfwNewFrame()
  igNewFrame()

  app.drawMain()

  igRender()

  let bgColor = igGetStyle().colors[WindowBg.ord]
  glClearColor(bgColor.x, bgColor.y, bgColor.z, bgColor.w)
  glClear(GL_COLOR_BUFFER_BIT)

  igOpenGL3RenderDrawData(igGetDrawData())  

proc initWindow(app: var App) = 
  glfwWindowHint(GLFWContextVersionMajor, 3)
  glfwWindowHint(GLFWContextVersionMinor, 3)
  glfwWindowHint(GLFWOpenglForwardCompat, GLFW_TRUE)
  glfwWindowHint(GLFWOpenglProfile, GLFW_OPENGL_CORE_PROFILE)
  glfwWindowHint(GLFWResizable, GLFW_TRUE)
  
  app.win = glfwCreateWindow(
    app.prefs["win/width"].getInt().int32, 
    app.prefs["win/height"].getInt().int32, 
    app.config["name"].getString(), 
    icon = false # Do not use default icon
  )

  if app.win == nil:
    quit(-1)

  # Set the window icon
  var icon = initGLFWImage(app.config["iconPath"].getPath().readImage())
  app.win.setWindowIcon(1, icon.addr)

  app.win.setWindowSizeLimits(app.config["minSize"][0].getInt().int32, app.config["minSize"][1].getInt().int32, GLFW_DONT_CARE, GLFW_DONT_CARE) # minWidth, minHeight, maxWidth, maxHeight
  app.win.setWindowPos(app.prefs["win/x"].getInt().int32, app.prefs["win/y"].getInt().int32)

  app.win.makeContextCurrent()

proc initPrefs(app: var App) = 
  when defined(appImage):
    # Put prefsPath right next to the AppImage
    let prefsPath = getEnv"APPIMAGE".parentDir / app.config["prefsPath"].getString()
  else:
    let prefsPath = getAppDir() / app.config["prefsPath"].getString()

  app.prefs = toPrefs({
    win: {
      x: 0,
      y: 0,
      width: 270,
      height: 200
    }
  }).initPrefs(prefsPath)

proc initconfig(app: var App, settings: PrefsNode) = 
  # Add the preferences with the values defined in config["settings"]
  for name, data in settings: 
    let settingType = parseEnum[SettingTypes](data["type"])
    if settingType == Section:
      app.initConfig(data["content"])  
    elif name notin app.prefs:
      app.prefs[name] = data["default"]

proc initApp(config: PObjectType): App = 
  result = App(config: config, password: "1mP4sw0rdG3n", copyBtnText: "Copy " & FA_FilesO)
  result.initPrefs()
  result.initConfig(result.config["settings"])

proc terminate(app: var App) = 
  var x, y, width, height: int32

  app.win.getWindowPos(x.addr, y.addr)
  app.win.getWindowSize(width.addr, height.addr)
  
  app.prefs["win/x"] = x
  app.prefs["win/y"] = y
  app.prefs["win/width"] = width
  app.prefs["win/height"] = height

  app.win.destroyWindow()

proc main() =
  var app = initApp(configPath.getPath().readPrefs())
  app.pg = newPassGen(passLen = app.prefs["length"].getInt(), flags = app.prefs.calcFlags())

  doAssert glfwInit()

  app.initWindow()

  doAssert glInit()

  let context = igCreateContext()
  let io = igGetIO()
  io.iniFilename = nil # Disable ini file

  app.font = io.fonts.addFontFromFileTTF(app.config["fontPath"].getPath(), app.config["fontSize"].getFloat())

  # Add ForkAwesome icon font
  var config = utils.newImFontConfig(mergeMode = true)
  var ranges = [FA_Min.uint16,  FA_Max.uint16]
  io.fonts.addFontFromFileTTF(app.config["iconFontPath"].getPath(), app.config["fontSize"].getFloat(), config.addr, ranges[0].addr)

  doAssert igGlfwInitForOpenGL(app.win, true)
  doAssert igOpenGL3Init()

  setIgStyle(app.config["stylePath"].getPath()) # Load application style

  while not app.win.windowShouldClose:
    app.display()
    app.win.swapBuffers()

  igOpenGL3Shutdown()
  igGlfwShutdown()
  context.igDestroyContext()

  app.terminate()

  glfwTerminate()

when isMainModule:
  main()
