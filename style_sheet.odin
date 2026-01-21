package syl

Style_Sheet :: struct {
	box: Box_Style,
	text: Text_Style,
	button: Button_Styles,
}

// Set the values of non-overridden properties of Element and its children from the given StyleSheet
element_set_style_sheet :: proc(element: ^Element, style: ^Style_Sheet, use_transitions: bool = true) {
	element.style_sheet = style

	#partial switch element.type {
	case .Box:
		box := cast(^Box)element
		box_set_style(box, box.style, use_transitions)
	case .Text:
		text := cast(^Text)element
		if text.is_button_text do return
		if !(.Color in text.overrides) {
			text.color = style.text.color
		}
	case .Button:
		button := cast(^Button)element
		b_style:  = button.style != nil ? &button.style.normal : nil
		button_set_style(button, b_style, use_transitions)
		if button.text != nil {
			button.text.style_sheet = style
			text_set_style_from_box_style(button.text, b_style)
		}
	}
}

element_set_style_sheet_recursive :: proc(element: ^Element, style: ^Style_Sheet, animate_properties: bool = true) {
	element_set_style_sheet(element, style, animate_properties)
	for child in element.children do element_set_style_sheet_recursive(child, style, animate_properties)
}
