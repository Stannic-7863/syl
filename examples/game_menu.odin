package main

import syl "../"
import renderer "../renderer/raylib"
import "core:math/ease"
import rl "vendor:raylib"

SCREEN_W :: 800
SCREEN_H :: 500

BACKGROUND_COLOR :: [4]u8{17,45,58, 255}
WHITE :: [4]u8{255, 255, 255, 255}
PRIMARY_COLOR :: [4]u8{236,155,92, 255} // orange
SECONDARY_COLOR :: [4]u8{160,223,227, 255}
PRIMARY_TEXT_COLOR :: [4]u8{25,16,0, 255} // black
MUTED :: [4]u8{46,79,90, 255}

style_sheet := syl.Style_Sheet {
	box = {
		default = {
			padding = {0,0,0,10},
			transitions = {
				padding = {0.15, .Cubic_Out}
			}
		},
	},
	button = {
		default = {
			text_color = SECONDARY_COLOR,
			font_size = 18,
			background_color = BACKGROUND_COLOR,
			padding = {10,30,10,30},
			border_color = MUTED,
			transitions = {
				background_color = {0.2, .Cubic_Out},
				padding = {0.05, .Linear},
			},
		},
		hover = {
			background_color = PRIMARY_COLOR,
			text_color = PRIMARY_TEXT_COLOR,
			border_color = PRIMARY_COLOR,
		},
		press = {
			background_color = WHITE,
			transitions = syl.Box_Transitions{
				background_color = {0, .Linear}
			}
		}
	},
	text = {
		color = SECONDARY_COLOR,
		font_size = 18
	}
}

container_style := syl.Box_Style_Delta {
	padding = [4]f32{0,0,0,10}
}

container_style_reset := syl.Box_Style_Delta {
	padding = [4]f32{0,0,0,0}
}

Game_UI :: struct {
	using base: syl.Box,
	count: int,
	container: ^syl.Box,
	sub_menus: struct {
		start: ^syl.Box,
		settings: ^syl.Box,
		network: ^syl.Box,
		credits: ^syl.Box,
		exit: ^syl.Box,
	},
	current_menu: ^syl.Box,
}

Message :: enum {
	Start,
	Settings,
	Network,
	Credits,
	Exit,
}

game_ui_update :: proc(game_ui: ^Game_UI, msg: ^Message) {
	if game_ui.current_menu != nil {
		syl.box_apply_style_delta(game_ui.current_menu, container_style_reset, nil, style_sheet.box.default)
		syl.element_remove_child(game_ui.container, game_ui.current_menu)
	}

	switch msg^ {
		case .Start:
			game_ui.current_menu = game_ui.sub_menus.start
			syl.element_add_child(game_ui.container, game_ui.sub_menus.start)
			syl.box_apply_style_delta(game_ui.sub_menus.start, container_style, nil, style_sheet.box.default)
		case .Network:
			game_ui.current_menu = game_ui.sub_menus.network
			syl.element_add_child(game_ui.container, game_ui.sub_menus.network)
			syl.box_apply_style_delta(game_ui.sub_menus.network, container_style, nil, style_sheet.box.default)
		case .Settings:
			game_ui.current_menu = game_ui.sub_menus.settings
			syl.element_add_child(game_ui.container, game_ui.sub_menus.settings)
			syl.box_apply_style_delta(game_ui.sub_menus.settings, container_style, nil, style_sheet.box.default)
		case .Credits:
			game_ui.current_menu = game_ui.sub_menus.credits
			syl.element_add_child(game_ui.container, game_ui.sub_menus.credits)
			syl.box_apply_style_delta(game_ui.sub_menus.credits, container_style, nil, style_sheet.box.default)
		case .Exit:
			game_ui.current_menu = game_ui.sub_menus.exit
			syl.element_add_child(game_ui.container, game_ui.sub_menus.exit)
			syl.box_apply_style_delta(game_ui.sub_menus.exit, container_style, nil, style_sheet.box.default)
	}
}

game_ui_destroy :: proc(game_ui: ^Game_UI) {
	free(game_ui)
}

game_menu_ui :: proc() -> ^Game_UI {
	game_ui := new(Game_UI)
	// This allows the box to receive messages
	handler := syl.make_handler(game_ui, syl.Box, Message, game_ui_update, game_ui_destroy)

	game_ui.sub_menus.start = start()
	game_ui.sub_menus.settings = settings()
	game_ui.sub_menus.network = network()
	game_ui.sub_menus.credits = credits()
	game_ui.sub_menus.exit = exit()

	// With a handler syl.box will initialize Game_UI instead creating a new Box
	game_ui.box = syl.box(size = {SCREEN_H, SCREEN_H}, style_sheet = &style_sheet, handler = handler, children = {
		syl.center(
			syl.box(
				syl.box(gap=10, children = {
					syl.button(text_content="START", width=200, on_mouse_over = Message.Start),
					syl.button(text_content="SETTINGS", width=200, on_mouse_over = Message.Settings),
					syl.button(text_content="NETWORK", width=200, on_mouse_over = Message.Network),
					syl.button(text_content="CREDITS", width=200, on_mouse_over = Message.Credits),
					syl.button(text_content="EXIT", width=200, on_mouse_over = Message.Exit),
				}),
				syl.box(ref=&game_ui.container, width=200, height_sizing=.Expand),
				layout_direction = .Left_To_Right
			)
		)
	})

	return game_ui
}

start :: proc() -> ^syl.Box {
	return syl.box(gap=10, children = {
		syl.button(text_content="CONTINUE", width=200),
		syl.button(text_content="NEW GAME", width=200),
	}),
}

settings :: proc() -> ^syl.Box {
	return syl.box(gap=10, children = {
		syl.button(text_content="AUDIO", width=200),
		syl.button(text_content="VIDEO", width=200),
		syl.button(text_content="CONTROLS", width=200),
		syl.button(text_content="GAMEPLAY", width=200),
	}),
}

network :: proc() -> ^syl.Box {
	return syl.box(gap=10, children = {
		syl.button(text_content="CONNECT TO SERVER", width=240),
		syl.button(text_content="HOST GAME", width=240),
		syl.button(text_content="DISCONNECT", width=240),
	}),
}

credits :: proc() -> ^syl.Box {
	return syl.box(gap=10, sizing=syl.Expand, children = {
		syl.center(
			syl.text("Programmer: CRSOLVER", wrap = false),
		),
	}),
}

exit :: proc() -> ^syl.Box {
	return syl.box(sizing=syl.Expand, children = {
		syl.center(
			syl.box(
				syl.text("ARE YOU SURE?", wrap = false),
				syl.box(
					syl.button(text_content="YES", width=100),
					syl.button(text_content="NO", width=100),
					layout_direction = .Left_To_Right,
					padding = 0,
					gap = 10
				),
				gap=10,
				padding=0,
			)
		)
	}),
}

main :: proc() {
	rl.SetConfigFlags({.MSAA_4X_HINT})
	rl.InitWindow(SCREEN_W, SCREEN_H, "Game Settings")
	rl.SetTargetFPS(60)

	app := game_menu_ui()

	for !rl.WindowShouldClose() {
		syl.calculate_layout(app)
		syl.element_update(app)
		syl.update_transitions()

		rl.BeginDrawing()
		rl.ClearBackground(cast(rl.Color)BACKGROUND_COLOR)
		renderer.render(app)
		rl.EndDrawing()
	}

	rl.CloseWindow()
}