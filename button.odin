package syl

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"

Button_State :: enum {
    Default,
    Hover,
	Press,
}

Button :: struct {
	using box: Layout_Box,
    text: ^Text,
    style: ^Button_Styles_Override,
	button_state: Button_State,
    on_button_state_changed: proc(e: ^Button, to: Button_State),
    on_click: Maybe(any),
    on_mouse_over: Maybe(any),
}

button_destroy:: proc(button: ^Button) {
   button_deinit(button) 
    free(button)
}

button_deinit :: proc(button: ^Button) {
    if button == nil do return
    layout_box_deinit(button)
    if val, ok := button.on_click.? ; ok {
        free(val.data)
    }
    if val, ok := button.on_mouse_over.? ; ok {
        free(val.data)
    }
}

button_change_state :: proc(button: ^Button, state: Button_State) {
	if button.on_button_state_changed != nil {
		button.on_button_state_changed(button, state)
	}

    button.button_state = state

	if button.style_sheet == nil do return
    
    hover :=  &button.style_sheet.button.hover
    press :=  &button.style_sheet.button.press

    if button.style != nil {
        hover =    &button.style.hover
        press =    &button.style.press
    }
    
    rl.SetMouseCursor(.DEFAULT) 

    switch state {
    case .Default: 
        button_set_style(button, nil)
        if button.text != nil do text_set_style_from_box_style(button.text, nil)
    case .Hover:
        rl.SetMouseCursor(.POINTING_HAND) 
        button_set_style(button, hover)
        if button.text != nil do text_set_style_from_box_style(button.text, hover)
    case .Press:   
        button_set_style(button, press)
        if button.text != nil do text_set_style_from_box_style(button.text, press)
    }
}

button_dispatch :: proc(button: ^Button, message: Maybe(any)) {
    if m, ok := message.?; ok {
        if button.owner != nil {
            if h, ok := button.owner.handler.?; ok {
                h.handler(h.element, m.data)
            }
        }
    }
}

update_button :: proc(button: ^Button) {
    mouse_pos := rl.GetMousePosition()
    box_rect := rl.Rectangle{button.global_position.x, button.global_position.y, button.size.x, button.size.y}
    collide := rl.CheckCollisionPointRec(mouse_pos, box_rect)

    if collide && rl.IsMouseButtonPressed(.LEFT) {
        if button.button_state != .Press {
            button_dispatch(button, button.on_click)
            button_change_state(button, .Press)
        }
    } else if collide {
        if button.button_state != .Hover {
            button_dispatch(button, button.on_mouse_over)
            button_change_state(button, .Hover)
        }
    } else {
        if button.button_state != .Default {
            button_change_state(button, .Default)
        }
    }

    for child in button.children do element_update(child)
}

// Style ______________________________________________________________________
Button_Styles :: struct {
	normal: Box_Style,
	hover:   Box_Style_Override,
	press:   Box_Style_Override
}

Button_Styles_Override :: struct {
	normal:  Box_Style_Override,
	hover:   Box_Style_Override,
	press:   Box_Style_Override,
}

button_set_style_default :: proc(button: ^Button, style: ^Box_Style_Override, use_transitions: bool = true) {
    default := button.style_sheet.button.normal
    fallback: ^Box_Style_Override
    if button.style != nil {
        fallback = &button.style.normal
    }

    layout_box_set_style(button, style, fallback, default, use_transitions)
}

button_set_style :: proc(button: ^Button, style: ^Box_Style_Override, use_transitions: bool = true) {
    default := button.style_sheet.button.normal
    fallback: ^Box_Style_Override
    if button.style != nil {
        fallback = &button.style.normal
    }

    layout_box_set_style(button, style, fallback, default, use_transitions)
}

button_apply_style :: proc(button: ^Button, style: Box_Style_Override, use_transitions: bool = true) {
    layout_box_apply_style(button, style, use_transitions)
}