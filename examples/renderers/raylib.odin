package main

import syl "../.."
import renderer "../../renderer/raylib"
import "core:fmt"
import "core:math/ease"
import rl "vendor:raylib"

BLUE :: [4]u8{0, 0, 255, 255}
BLACK :: [4]u8{0, 0, 0, 255}
RED :: [4]u8{255, 0, 0, 255}
GREEN :: [4]u8{0, 255, 0, 255}
YELLOW :: [4]u8{255, 255, 0, 255}
BLANK :: [4]u8{0, 0, 0, 0}
WHITE :: [4]u8{255, 255, 255, 255}

SCREEN_W :: 800
SCREEN_H :: 500

style_sheet := syl.StyleSheet {
	box = {
		default = {
			background_color = BLANK,
			padding_right = 10,
			padding_left = 10,
			padding_bottom = 10,
			padding_top = 10,
			gap = 10,
			transitions = {background_color = {duration = 0.4, ease = .Cubic_In}},
		},
		hover = {background_color = RED},
	},
}

redish := [4]u8{69,36,44, 255}
redisht := [4]u8{207,106,111, 255}
grayish := [4]u8{44,44,44, 255}
grayish2 := [4]u8{131,131,131, 255}
gr := [4]u8{26,26,26, 255}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE} | {.WINDOW_TOPMOST})
	rl.InitWindow(SCREEN_W, SCREEN_H, "Syl in Raylib")
	rl.SetTargetFPS(60)

	syl.font = rl.LoadFontEx("Roboto-Regular.ttf", 18, nil, 0)

	app := syl.box(size={SCREEN_W, SCREEN_H}, children = {
		syl.center(
			syl.box(padding=10, gap=10, background_color=gr, children = {
				syl.box(syl.text("Schedule Meeting")),
				syl.box(border_color=grayish, sizing=syl.Expand, children = {
					syl.box(width_sizing=.Expand, padding=10, children = {
						syl.box(syl.text("Andres"))
					}),
					syl.box(width_sizing=.Expand, children = {
						syl.box(layout_direction = .Left_To_Right, width_sizing=.Expand, padding=10, gap=10, children = {
							syl.text("Date", color=grayish2), syl.box(width_sizing=.Expand), syl.box(syl.text("May 20, 2025", color=grayish2)),
						}),
						syl.box(layout_direction = .Left_To_Right, width_sizing=.Expand, padding=10, gap=10, children = {
							syl.text("Time", color=grayish2), syl.box(width_sizing=.Expand), syl.box(syl.text("09:30 AM", color=grayish2)),
						}),
						syl.box(layout_direction = .Left_To_Right, width_sizing=.Expand, padding=10, gap=10, children = {
							syl.text("Duration", color=grayish2), syl.box(width_sizing=.Expand), syl.box(syl.text("30 Minutes", color=grayish2)),
						}),
					})
				}),
				syl.box(width_sizing=.Expand, layout_direction=.Left_To_Right, gap=10, children = {
					syl.box(syl.text("Decline", color=redisht), padding=8, background_color=redish),
					syl.box(syl.text("Reschedule"), sizing=syl.Expand, padding=8, background_color=grayish),
				})
			}),
		)
	})
	

	/*
	app := syl.box(
		style_sheet = &style_sheet,
		layout_direction = .Left_To_Right,
		size = {SCREEN_W, SCREEN_H},
		background_color = BLANK,
		children = {
			syl.box(
				layout_direction = .Top_To_Bottom,
				gap = 0,
				padding = 0,
				width = 150,
				sizing = {.Fixed, .Expand},
				background_color = BLANK,
				children = {
					syl.box(syl.text("option 1"), width_sizing = .Expand, padding = 10),
					syl.box(syl.text("option 2"), width_sizing = .Expand, padding = 10),
					syl.box(syl.text("option 3"), width_sizing = .Expand, padding = 10),
					syl.box(syl.text("option 4"), width_sizing = .Expand, padding = 10),
					syl.box(syl.text("option 5"), width_sizing = .Expand, padding = 10),
					syl.box(syl.text("option 6"), width_sizing = .Expand, padding = 10),
					syl.box(syl.text("option 7"), width_sizing = .Expand, padding = 10),
				},
			),
			syl.box(
				id = "main",
				sizing = syl.Expand,
				background_color = BLANK,
				padding = 10,
				children = {
					syl.text(
						"Odin is a general-purpose programming language with distinct typing built for high performance, modern systems and data-oriented programming. Odin is the C alternative for the Joy of Programming.",
						color = BLACK,
					),
				},
			),
		},
	)
	app := syl.box(
		size = {250, 60},
		background_color = RED,
		layout_direction = .Left_To_Right,
		children = {
			syl.box(sizing = syl.Expand, background_color = BLANK),
			syl.box(sizing = syl.Expand, background_color = BLANK),
			syl.box(syl.box(size = {200,50}), sizing = syl.Expand, background_color = GREEN),
		}
	)*/

	syl.calculate_layout(app)

	for !rl.WindowShouldClose() {
		syl.calculate_layout(app)
		syl.update(app)
		syl.update_transitions()

		rl.BeginDrawing()
		rl.ClearBackground(cast(rl.Color)[4]u8{43,43,43,255})
		renderer.draw(app)
		size := 40
		//for row in 0..<50 do rl.DrawLine(0, i32(row*size), 800, i32(row*size), rl.GRAY)
		//for col in 0..<50 do rl.DrawLine(i32(col*size), 0, i32(col*size), 400, rl.GRAY)
		rl.EndDrawing()
	}

	rl.CloseWindow()
}
