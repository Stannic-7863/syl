package syl
/*

import "core:fmt"

Layout_Direction :: enum {
	Top_To_Bottom,
	Left_To_Right,
}

Box :: struct {
	using base: Base_Element,
	style: Box_Style,
}

// Main layout calculation: fit -> grow -> position
calculate_layout :: proc(element: Element) {
    fit_sizing(element)
    grow_sizing(element)
    update_layout(element)
}

// Step 1: Calculate minimum required sizes bottom-up
fit_sizing :: proc(element: Element) -> [2]f32 {
    #partial switch e in element {
    case ^Box:
        return box_fit_sizing(e)
    }
	return {0,0}
}

box_fit_sizing :: proc(box: ^Box) -> [2]f32 {
    size: [2]f32
    gap := box.style.gap

    // Calculate content size along both axes
    for child in box.children {
        child_size := fit_sizing(child)
        size.y += child_size.y
        size.x = max(size.x, child_size.x)
    }

    if box.style.sizing == .Fixed {
        fmt.println(box.base.id, " FIT SIZE: ", box.base.size)
        return box.base.size
    }

    // Add gaps between children along primary axis
    if len(box.children) > 0 {
        gaps := f32(len(box.children) - 1) * gap
        size.y += gaps
    }

    // Add padding
    size.x += box.style.padding_left + box.style.padding_right
    size.y += box.style.padding_top + box.style.padding_bottom

    box.size = size

    fmt.println(box.base.id, " FIT SIZE: ", box.base.size)
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
    
    // Calculate available space
    remaining := [2]f32{
        clamp(box.size.x - box.style.padding_left - box.style.padding_right, 0, box.size.x),
        clamp(box.size.y - box.style.padding_top - box.style.padding_bottom, 0, box.size.y),
    }

    // Subtract gaps from primary axis
    if len(box.children) > 0 {
        gaps := f32(len(box.children) - 1) * gap
        remaining.y -= gaps
    }
    
    if box.style.sizing == .Fit {
        remaining = {0,0}
    }

    fmt.println("\n________________BOX GROW CHILDREN: ", box.base.id)
    fmt.println("remaining ", remaining)

    // Calculate space taken by non-expanding children on primary axis
    fixed_primary: f32 = 0
    expand_count_primary := 0

    for child in box.children {
        base := get_base(child)
        child_size := get_size(child)
        sizing := base.base_style.sizing
        
        // Check if child wants to expand on primary axis
        should_expand_primary := sizing == .Expand || sizing == .Expand_Vertical
        
        if should_expand_primary {
            expand_count_primary += 1
        } else {
            fixed_primary += child_size.y
        }
    }

    fmt.println("fixed_primary ", fixed_primary)
    fmt.println("expand_count_primary ", expand_count_primary)

    // Calculate expansion size for primary axis
    expand_size_primary: f32 = 0
    if expand_count_primary > 0 {
        expand_size_primary = clamp((remaining.y - fixed_primary) / f32(expand_count_primary), 0, 100000)
    }

    fmt.println("expand_size_primary ", expand_size_primary)

    // Apply expansion to children
    for child in box.children {
        base := get_base(child)
        sizing := base.base_style.sizing
        new_size := get_size(child)
        
        // Expand on primary axis if needed
        should_expand_primary := sizing == .Expand || sizing == .Expand_Vertical
        
        if should_expand_primary && expand_size_primary > 0 {
            new_size.y = max(new_size.y, expand_size_primary)
        }
        
        set_size(child, new_size)
        grow_sizing(child)
    }
}

// Step 3: Position all children
update_layout :: proc(element: Element) {
    #partial switch e in element {
    case ^Box:
        update_box_layout(e)
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

box :: proc(
	children:       ..Element, 
    ref:              Maybe(^^Box) = nil,
	layout_direction: Maybe(Layout_Direction) = nil,
	gap:              Maybe(f32) = nil,
	id:              Maybe(string) = nil,
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
) -> Element {
	box := new(Box)
	box.base.base_style = &box.style.base
	box.size = size
    if r, ok := id.?; ok {
        box.base.id = r
    }
    if r, ok := ref.?; ok {
        r^ = box
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
}*/