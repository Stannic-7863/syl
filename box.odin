package syl

import "core:fmt"
import rl "vendor:raylib"
import "core:math"

Layout_Direction :: enum {
	Top_To_Bottom,
	Left_To_Right,
}

Box_State :: enum {
    Default,
    Hover,
}

Box :: struct {
	using base: Base_Element,
	style: Box_Style,
    state: Box_State,
}

// Main layout calculation: fit -> grow -> position
calculate_layout :: proc(element: Element) {
    fit_sizing_width(element)
    grow_sizing(element)
    text_wrap(element)
    fit_sizing_height(element)
    update_layout(element)
}

// Step 1: Calculate minimum required sizes bottom-up
fit_sizing_width :: proc(element: Element) -> [2]f32 {
    #partial switch e in element {
    case ^Box:
        return box_fit_sizing_width(e)
    case ^Text:
        return text_fit_sizing_width(e)
    }
	return {0,0}
}

fit_sizing_height :: proc(element: Element) -> [2]f32 {
    #partial switch e in element {
    case ^Box:
        return box_fit_sizing_height(e)
    }
	return {0,0}
}

box_fit_sizing_width :: proc(box: ^Box) -> [2]f32 {
    width: f32
    gap := box.style.gap
    
    switch box.style.layout_direction {
    case .Left_To_Right:
        // Horizontal layout: sum widths along x-axis
        for child in box.children {
            child_size := fit_sizing_width(child)
            width += child_size.x
        }
        
        // Add gaps between children
        if len(box.children) > 0 {
            gaps := f32(len(box.children) - 1) * gap
            width += gaps
        }
    case .Top_To_Bottom:
        // Vertical layout: take max width along cross-axis
        for child in box.children {
            child_size := fit_sizing_width(child)
            width = max(width, child_size.x)
        }
    }
    
    if box.style.sizing == .Fixed {
        return box.base.size
    }
    
    // Add horizontal padding
    width += box.style.padding_left + box.style.padding_right
    
    // Update box width only
    box.size.x = max(box.size.x, width)
    
    return box.size
}

box_fit_sizing_height :: proc(box: ^Box) -> [2]f32 {
    height: f32
    gap := box.style.gap
    
    // Determine primary axis based on layout direction
    primary_axis := box.style.layout_direction == .Left_To_Right ? 0 : 1

    switch box.style.layout_direction {
    case .Top_To_Bottom:
        // Vertical layout: sum heights along y-axis
        for child in box.children {
            child_size := fit_sizing_height(child)
            height += child_size.y
        }
        
        // Add gaps between children
        if len(box.children) > 0 {
            gaps := f32(len(box.children) - 1) * gap
            height += gaps
        }
    case .Left_To_Right:
        // Horizontal layout: take max height along cross-axis
        for child in box.children {
            child_size := fit_sizing_height(child)
            height = max(height, child_size.y)
        }
    }
    
    if box.style.sizing == .Fixed {
        return box.base.size
    }
    
    // Add vertical padding
    height += box.style.padding_top + box.style.padding_bottom
    
    // Update box height only
    box.size.y = max(box.size.y, height)
    
    return box.size
}

// Step 2: Expand children that want to grow
grow_sizing :: proc(element: Element) {
    #partial switch e in element {
    case ^Box:
        box_grow_sizing(e)
	}
}

box_grow_sizing :: proc(box: ^Box) {
    gap := box.style.gap
    
    // Determine primary and cross axis based on layout direction
    primary_axis := box.style.layout_direction == .Left_To_Right ? 0 : 1
    cross_axis := 1 - primary_axis
    
    // Calculate available space
    remaining := [2]f32{
        box.size.x - box.style.padding_left - box.style.padding_right,
        box.size.y - box.style.padding_top - box.style.padding_bottom,
    }

    growable := [dynamic]^Base_Element{}
    defer delete(growable)

    for child in box.children {
        base := get_base(child)
        remaining[primary_axis] -= base.size[primary_axis]

        sizing := base.base_style.sizing
        should_expand_primary := 
            sizing == .Expand || 
            (primary_axis == 0 && sizing == .Expand_Horizontal) ||
            (primary_axis == 1 && sizing == .Expand_Vertical)

        if should_expand_primary {
            append_elem(&growable, base)
        }

        should_expand_cross:= 
            sizing == .Expand || 
            (cross_axis == 0 && sizing == .Expand_Horizontal) ||
            (cross_axis == 1 && sizing == .Expand_Vertical)

        if should_expand_cross {
            base.size[cross_axis] = max(base.size[cross_axis], remaining[cross_axis])
        }
    }

    // Subtract gaps from primary axis
    if len(box.children) > 0 {
        gaps := f32(len(box.children) - 1) * gap
        remaining[primary_axis] -= gaps
    }

    if remaining.x < 0 do remaining.x = 0
    if remaining.y < 0 do remaining.y = 0

    redistribute := len(growable) > 0 && remaining[primary_axis] > 0

    // Expand children
    for redistribute && remaining[primary_axis] > 0 {
        smallest := growable[0].size[primary_axis]
        second_smallest := math.INF_F32
        to_add := remaining[primary_axis]

        // Find the size of the smallest and the second smallest element
        for child in growable {
            if child.size[primary_axis] < smallest {
                second_smallest = smallest
                smallest = child.size[primary_axis]
            }
            if child.size[primary_axis] > smallest {
                second_smallest = min(second_smallest, child.size[primary_axis])
                to_add = second_smallest - smallest
            }
        }

        to_add = min(to_add, remaining[primary_axis] / f32(len(growable)))

        // Make the smallest elements as big as the second smallest element
        for child in growable {
            if child.size[primary_axis] == smallest {
                child.size[primary_axis] += to_add
                remaining[primary_axis] -= to_add
            }
        }
    }

    for child in box.children do grow_sizing(child)
}

/*
box_grow_sizing :: proc(box: ^Box) {
    gap := box.style.gap
    
    // Determine primary and cross axis based on layout direction
    primary_axis := box.style.layout_direction == .Left_To_Right ? 0 : 1
    cross_axis := 1 - primary_axis
    
    // Calculate available space
    remaining := [2]f32{
        clamp(box.size.x - box.style.padding_left - box.style.padding_right, 0, 100000),
        clamp(box.size.y - box.style.padding_top - box.style.padding_bottom, 0, 100000),
    }

    if box.id == "parent" {
        fmt.println("size: ", box.size)
        fmt.println("remaining: ", remaining)
    }

    // Subtract gaps from primary axis
    if len(box.children) > 0 {
        gaps := f32(len(box.children) - 1) * gap
        remaining[primary_axis] -= gaps
    }

    //?
    /*if box.style.sizing == .Fit {
        remaining = {0,0}
    }*/

    // Calculate space taken by non-expanding children on primary axis
    fixed_primary: f32 = 0
    expand_count_primary := 0

    for child in box.children {
        base := get_base(child)
        child_size := get_size(child)
        sizing := base.base_style.sizing
        
        // Check if child wants to expand on primary axis
        should_expand_primary := 
            sizing == .Expand || 
            (primary_axis == 0 && sizing == .Expand_Horizontal) ||
            (primary_axis == 1 && sizing == .Expand_Vertical)
        
        if should_expand_primary {
            expand_count_primary += 1
        } else {
            fixed_primary += child_size[primary_axis]
        }
    }

    // Calculate expansion size for primary axis
    expand_size_primary: f32 = 0
    if expand_count_primary > 0 {
        expand_size_primary = clamp((remaining[primary_axis] - fixed_primary) / f32(expand_count_primary), 0, 10000)
    }

    // Apply expansion to children
    for child in box.children {
        base := get_base(child)
        sizing := base.base_style.sizing
        new_size := get_size(child)
        
        // Expand on primary axis if needed
        should_expand_primary := 
            sizing == .Expand || 
            (primary_axis == 0 && sizing == .Expand_Horizontal) ||
            (primary_axis == 1 && sizing == .Expand_Vertical)
        
        if should_expand_primary {
            new_size[primary_axis] = max(new_size[primary_axis], expand_size_primary)
        }
        
        // Expand on cross axis if needed
        should_expand_cross := 
            sizing == .Expand || 
            (cross_axis == 0 && sizing == .Expand_Horizontal) || // x
            (cross_axis == 1 && sizing == .Expand_Vertical) // y
        
        if should_expand_cross {
            new_size[cross_axis] = max(new_size[cross_axis], remaining[cross_axis])
        }
       
        set_size(child, new_size)
        grow_sizing(child)
    }
}
*/

// Step 3: Position all children
update_layout :: proc(element: Element) {
    #partial switch e in element {
    case ^Box:
        update_box_layout(e)
    case ^Text:
        text_update_positions(e)
	}
}

update_box_layout :: proc(box: ^Box) {
    padding_top := box.style.padding_top
    padding_left := box.style.padding_left
    gap := box.style.gap
    
    // Determine primary and cross axis based on layout direction
    primary_axis := box.style.layout_direction == .Left_To_Right ? 0 : 1
    
    cursor := [2]f32{padding_left, padding_top}

    // Position all children
    for child in box.children {
        set_position(child, cursor)
        size := get_size(child)

        // Advance cursor along primary axis
        cursor[primary_axis] += size[primary_axis] + gap
        
        // Recursively layout children
        update_layout(child)
    }
}

box_change_state :: proc(box: ^Box) {
    switch box.state {
    case .Default:
        box.state = .Hover
        animate_color(&box.style.background_color, {0, 0,180,255}, 0.1)
    case .Hover:
        box.state = .Default
        animate_color(&box.style.background_color, {100,100,250,255}, 0.1)
    }
}

box :: proc(
	children:       ..Element, 
    ref:              Maybe(^^Box) = nil,
	layout_direction: Maybe(Layout_Direction) = nil,
	gap:              Maybe(f32) = nil,
	padding:          Maybe(f32) = nil,
	padding_top:      Maybe(f32) = nil,
	padding_right:    Maybe(f32) = nil,
	padding_bottom:   Maybe(f32) = nil,
	padding_left:     Maybe(f32) = nil,
	background_color: Maybe([4]u8) = nil,
	size:             [2]f32 = {0,0},
	width:            Maybe(f32) = nil,
	height:           Maybe(f32) = nil,
	sizing: 		  Maybe(Sizing) = nil,
    id: Maybe(string) = nil,
) -> Element {
	box := new(Box)
	box.base.base_style = &box.style.base
	box.size = size
    if r, ok := ref.?; ok {
        r^ = box
    }

    if i, ok := id.?; ok {
        box.id = i
    }

	// style overrides
	if val, ok := layout_direction.?; ok {
		box.style.layout_direction = val
		box.overrides += { .Layout_Direction }
	}

	if val, ok := gap.?; ok {
		box.style.gap = val
		box.overrides += { .Gap }
	}

	if val, ok := sizing.?; ok {
		box.style.sizing = val
		box.overrides += { .Sizing }
	}
	
	if val, ok := padding.?; ok {
		box.style.padding_top    = val
		box.style.padding_right  = val
		box.style.padding_bottom = val
		box.style.padding_left   = val
		box.overrides += { .Padding_All }
	}

	if val, ok := padding_top.?; ok {
		box.style.padding_top = val
		box.overrides += { .Padding_Top }
	}

	if val, ok := padding_right.?; ok {
		box.style.padding_right = val
		box.overrides += { .Padding_Right }
	}
	
	if val, ok := padding_bottom.?; ok {
		box.style.padding_bottom = val
		box.overrides += { .Padding_Bottom }
	}

	if val, ok := padding_left.?; ok {
		box.style.padding_left = val
		box.overrides += { .Padding_Left }
	}

	if val, ok := background_color.?; ok {
		box.style.background_color = val
		box.overrides += { .Background_Color }
	}

	for child in children do set_parent(child, box)
	append_elems(&box.children, ..children)
	return box
}

update_box :: proc(box: ^Box) {
    if !(.Background_Color in box.overrides) {
        mouse_pos := rl.GetMousePosition()
        box_rect := rl.Rectangle{box.global_position.x, box.global_position.y, box.size.x, box.size.y}
        collide := rl.CheckCollisionPointRec(mouse_pos, box_rect)
        if box.state == .Default && collide {
            box_change_state(box)
        }
        if box.state == .Hover && !collide {
            box_change_state(box)
        }
    }

    for child in box.children do update(child)
}