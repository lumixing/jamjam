package cliend

DISABLE_DOCKING :: #config(DISABLE_DOCKING, false)

import im "../odin-imgui"
import "../odin-imgui/imgui_impl_glfw"
import "../odin-imgui/imgui_impl_opengl3"

import "vendor:glfw"
import gl "vendor:OpenGL"

window: glfw.WindowHandle

ui_init :: proc() {
	assert(cast(bool)glfw.Init())

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 2)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, 1) // i32(true)

	window = glfw.CreateWindow(1280, 720, "Dear ImGui GLFW+OpenGL3 example", nil, nil)
	assert(window != nil)
	glfw.SetWindowPos(window, (1920 - 1280) / 2, (1080 - 720) / 2)

	glfw.MakeContextCurrent(window)
	glfw.SwapInterval(1) // vsync

	gl.load_up_to(3, 2, proc(p: rawptr, name: cstring) {
		(cast(^rawptr)p)^ = glfw.GetProcAddress(name)
	})

	im.CHECKVERSION()
	im.CreateContext()

	io := im.GetIO()
	io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad}
	when !DISABLE_DOCKING {
		io.ConfigFlags += {.DockingEnable}
		// io.ConfigFlags += {.ViewportsEnable}

		style := im.GetStyle()
		style.WindowRounding = 0
		style.Colors[im.Col.WindowBg].w = 1
	}

	im.FontAtlas_AddFontFromFileTTF(io.Fonts, "Inter-Regular.ttf", 20)

	im.StyleColorsDark()

	imgui_impl_glfw.InitForOpenGL(window, true)

	imgui_impl_opengl3.Init("#version 150")
}

ui_deinit :: proc() {
	defer glfw.Terminate()
	defer glfw.DestroyWindow(window)
	defer im.DestroyContext()
	defer imgui_impl_glfw.Shutdown()
	defer imgui_impl_opengl3.Shutdown()
}

ui_loop :: proc() {
	for !glfw.WindowShouldClose(window) {
		glfw.PollEvents()

		imgui_impl_opengl3.NewFrame()
		imgui_impl_glfw.NewFrame()
		im.NewFrame()

		im.DockSpaceOverViewport()
		im.ShowDemoWindow()

		if im.Begin("Window containing a quit button") {
			if im.Button("The quit button in question") {
				glfw.SetWindowShouldClose(window, true)
			}
		}
		im.End()

		im.Render()
		display_w, display_h := glfw.GetFramebufferSize(window)
		gl.Viewport(0, 0, display_w, display_h)
		gl.ClearColor(0, 0, 0, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		imgui_impl_opengl3.RenderDrawData(im.GetDrawData())

		when !DISABLE_DOCKING {
			backup_current_window := glfw.GetCurrentContext()
			im.UpdatePlatformWindows()
			im.RenderPlatformWindowsDefault()
			glfw.MakeContextCurrent(backup_current_window)
		}

		glfw.SwapBuffers(window)
	}
}