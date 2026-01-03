package main

import rl "vendor:raylib"
import renderer "../../renderer/raylib"
import syl "../.."

BLUE :: [4]u8{0,0,255,255}
RED :: [4]u8{255,0,0,255}
GREEN:: [4]u8{0,255,0,255}
YELLOW :: [4]u8{255,255,0,255}
BLANK :: [4]u8{0,0,0,0}
WHITE :: [4]u8{255,255,255,255}

style := syl.Style {
	box = {
		layout_direction = .Top_To_Bottom,
		background_color = BLUE,
		gap = 10,
		padding_top = 10,
		padding_right = 10,
		padding_left = 10,
		padding_bottom = 10,
	},
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE} | {.WINDOW_TOPMOST})
	rl.InitWindow(800, 400, "Syl in Raylib")
	rl.SetTargetFPS(60)

	app := syl.box(
		syl.box(size={150,20}),
		syl.box(
			syl.box(size={30,30}, background_color=RED),
			syl.box(size={30,30}, background_color=RED),
			syl.box(size={30,30}, background_color=RED),
			syl.box(size={30,30}, background_color=RED),
			syl.box(size={30,30}, background_color=RED),
			layout_direction = .Left_To_Right
		),
		syl.box(size={150,20}),
		syl.box(
			syl.box(size={30,30}, background_color=RED),
			syl.box(size={30,30}, background_color=RED),
			syl.box(size={30,30}, background_color=RED),
		),
		syl.box(size={150,20}),
		syl.box(size={150,20}),
		background_color = BLANK,
	)

	syl.apply_style(&style, app)
	syl.update(app)
	syl.update(app)

    for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.WHITE) 
			renderer.draw(app)
			size := 40
			//for row in 0..<50 do rl.DrawLine(0, i32(row*size), 800, i32(row*size), rl.GRAY)
			//for col in 0..<50 do rl.DrawLine(i32(col*size), 0, i32(col*size), 400, rl.GRAY)
		rl.EndDrawing()
    }

    rl.CloseWindow()
}