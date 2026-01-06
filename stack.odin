package syl

Stack :: struct {
	using base: Base_Element,
	style: Box_Style,
}

update_stack_layout :: proc(stack: ^Stack) {
	for child in stack.children do update_layout(child)
}

stack :: proc(
	children:       ..Element, 
	background_color: Maybe([4]u8) = nil,
	size:             [2]f32 = {0,0},
	width:            Maybe(f32) = nil,
	height:           Maybe(f32) = nil,
) -> Element {
	stack := new(Stack)
	stack.base.base_style = &stack.style.base
	stack.size = size

	if val, ok := background_color.?; ok {
		stack.style.background_color = val
		stack.overrides += { .Background_Color }
	}

	for child in children do set_parent(child, stack)
	append_elems(&stack.children, ..children)
	return stack
}
