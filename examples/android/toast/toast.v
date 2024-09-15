// Copyright(C) 2019-2021 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
import gg
import gx
// import math
import sokol.sapp
import sokol.gfx
import sokol.sgl
import time
import jni
import jni.auto

const pkg = 'io.v.android.ex.VToastActivity'
const bg_color = gx.white

@[export: 'JNI_OnLoad']
fn jni_on_load(vm &jni.JavaVM, reserved voidptr) int {
	println(@FN + ' called')
	jni.set_java_vm(vm)
	$if android {
		// V consts - can't be used since `JNI_OnLoad`
		// is called by the Java VM before the lib
		// with V's init code is loaded and called.
		jni.setup_android('io.v.android.ex.VToastActivity')
	}
	return int(jni.Version.v1_6)
}

struct App {
mut:
	gg &gg.Context

	pip_3d      sgl.Pipeline
	texture     gfx.Image
	init_flag   bool
	frame_count int

	mouse_x int = -1
	mouse_y int = -1
	// time
	ticks i64
}

fn (a App) show_toast(text string) {
	println(@FN + ': "${text}"')
	$if android {
		jor := auto.call_static_method(jni.sig(pkg, @FN, 'void', text), text)
		println('V jni.CallResult: ${jor} showing toast')
	}
}

fn frame(mut app App) {
	ws := gg.window_size()

	min := if ws.width < ws.height { f32(ws.width) } else { f32(ws.height) }

	app.gg.begin()
	sgl.defaults()

	sgl.viewport(int((f32(ws.width) * 0.5) - (min * 0.5)), int((f32(ws.height) * 0.5) - (min * 0.5)),
		int(min), int(min), true)
	draw_triangle()

	app.gg.end()
}

fn draw_triangle() {
	sgl.defaults()
	sgl.begin_triangles()
	sgl.v2f_c3b(0.0, 0.5, 255, 0, 0)
	sgl.v2f_c3b(-0.5, -0.5, 0, 0, 255)
	sgl.v2f_c3b(0.5, -0.5, 0, 255, 0)
	sgl.end()
}

fn init(mut app App) {
	desc := sapp.create_desc()
	gfx.setup(&desc)
	sgl_desc := sgl.Desc{}
	sgl.setup(&sgl_desc)
}

fn cleanup(mut app App) {
	gfx.shutdown()
}

fn event(ev &gg.Event, mut app App) {
	if ev.typ == .mouse_move {
		app.mouse_x = int(ev.mouse_x)
		app.mouse_y = int(ev.mouse_y)
	}
	if ev.typ == .touches_began || ev.typ == .touches_moved {
		if ev.num_touches > 0 {
			touch_point := ev.touches[0]
			app.mouse_x = int(touch_point.pos_x)
			app.mouse_y = int(touch_point.pos_y)
		}
	}
	if ev.typ == .touches_ended || ev.typ == .mouse_up {
		if ev.num_touches > 0 {
			app.show_toast('Hello from V in toast!')
		}
	}
	// println('$app.mouse_x,$app.mouse_y')
}

//[console]
fn main() {
	// App init
	mut app := &App{
		gg: unsafe { nil }
	}

	app.gg = gg.new_context(
		width:         200
		height:        400
		create_window: true
		window_title:  'Toast Demo'
		user_data:     app
		bg_color:      bg_color
		frame_fn:      frame
		init_fn:       init
		cleanup_fn:    cleanup
		event_fn:      event
	)

	app.ticks = time.ticks()
	app.gg.run()
}
