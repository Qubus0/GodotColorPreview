@tool
extends EditorPlugin

var editor: Node = null
var editors: Array = []
var current_textedit: TextEdit
var hovering_line = null
var gutter_position: int = 0
var preview_gutter_name: String = "color_preview"
var picker_popup: Popup


func _enter_tree() -> void:
	initialize_picker()
	initialize_gutter()


func _exit_tree() -> void:
	exit_picker()
	exit_gutter()


func initialize_picker() -> void:
	if not picker_popup:
		picker_popup = preload("res://addons/ColorPreview/picker.tscn").instantiate()
		picker_popup.connect("popup_hide", on_picker_popup_close)
	picker_popup.hide()
	
	var picker = picker_popup.get_node("ColorPicker")
	if not picker.is_connected("color_changed", picker_color_changed):
		picker.connect("color_changed", picker_color_changed)

	var editor := get_editor_interface()
	if not picker_popup.is_inside_tree() or not editor.has_node(picker_popup.get_path()):
		editor.add_child(picker_popup)


func exit_picker() -> void:
	if picker_popup:
		picker_popup.queue_free()


func initialize_gutter() -> void:
	var script_editor := get_editor_interface().get_script_editor()
	if not script_editor.is_connected("editor_script_changed", editor_script_changed):
		script_editor.connect("editor_script_changed", editor_script_changed)
	get_all_text_editors(script_editor)
	for child in editors:
		if child and is_instance_valid(child) and child is TextEdit:
			add_color_gutter(child)


func exit_gutter() -> void:
	var script_editor := get_editor_interface().get_script_editor()
	get_all_text_editors(script_editor)
	for child in editors:
		if child is TextEdit:
			remove_color_gutter(child)


### ### ### GETTING AND KEEPING EDITORS ### ### ###

func get_all_text_editors(parent : Node) -> void:
	for child in parent.get_children():
		if child.get_child_count():
			get_all_text_editors(child)

		if child is TextEdit:
			editors.append(child)

			if child.is_connected("text_changed", text_changed):
				child.disconnect("text_changed", text_changed)
			child.connect("text_changed", text_changed, [child])

			if child.is_connected("caret_changed", caret_changed):
				child.disconnect("caret_changed", caret_changed)
			child.connect("caret_changed", caret_changed, [child])


func caret_changed(textedit: TextEdit) -> void:
	handle_change(textedit)


func text_changed(textedit : TextEdit) -> void:
	handle_change(textedit)


func handle_change(textedit : TextEdit) -> void:
	current_textedit = textedit
	if not current_textedit.is_connected("gui_input", textedit_clicked):
		current_textedit.connect("gui_input", textedit_clicked, [textedit])

	var editor = get_editor_interface()
	if not editors.has(textedit):
		editors.clear()
		get_all_text_editors(editor.get_script_editor())
	get_colors_from_textedit(textedit)


func editor_script_changed(script: Script) -> void:
	initialize_picker()
	initialize_gutter()
	if current_textedit:
		if current_textedit.is_connected("gui_input", textedit_clicked):
			current_textedit.disconnect("gui_input", textedit_clicked)
		current_textedit = null
	var editor = get_editor_interface()
	var script_editor = editor.get_script_editor()
	editors.clear()
	get_all_text_editors(script_editor)


### ### ### HANDLING GUTTERS ### ### ###

func has_color_preview_gutter(textedit: TextEdit) -> bool:
	for gutter_index in textedit.get_gutter_count() - 1:
		if gutter_index < 0:
			continue
		if textedit.get_gutter_name(gutter_index) == preview_gutter_name:
			return true
	return false


func add_color_gutter(textedit: TextEdit) -> void:
	if has_color_preview_gutter(textedit):
		return
	current_textedit = textedit
	textedit.add_gutter(gutter_position)
	textedit.set_gutter_width(gutter_position, 35)
	textedit.set_gutter_name(gutter_position, preview_gutter_name)
	textedit.set_gutter_type(gutter_position, TextEdit.GUTTER_TYPE_CUSTOM)
	textedit.set_gutter_custom_draw(gutter_position, gutter_draw_color_preview)


func remove_color_gutter(textedit: TextEdit) -> void:
	for gutter_index in textedit.get_gutter_count() - 1:
		if gutter_index < 0:
			continue
		var name = textedit.get_gutter_name(gutter_index)
		if name == preview_gutter_name:
			textedit.remove_gutter(gutter_position)


func gutter_draw_color_preview(line: int, gutter: int, area: Rect2) -> void:
	if not current_textedit or line > current_textedit.get_line_count() - 1:
		return
		
	var size: int 
	var offset := Vector2.ZERO
	# centering the preview square in the line because perfectionism
	if area.size.x < area.size.y:
		size = area.size.x
		offset = Vector2(0, (area.size.y - area.size.x) /2)
	else:
		size = area.size.y
		offset = Vector2((area.size.x - area.size.y) /2, 0)
	var icon_region := Rect2(area.position + offset, Vector2(size, size))
	
	# spacing the squares so they don't merge
	var padding = size / 6
	icon_region = icon_region.grow(-padding)
	
	var icon_corner_region = PackedVector2Array([
		icon_region.end,
		icon_region.end + Vector2(-icon_region.size.x / 2, 0.0),
		icon_region.end + Vector2(0.0, -icon_region.size.y / 2)
	])

	var mouse_pos := current_textedit.get_local_mouse_pos()
	var hovering := area.has_point(mouse_pos)
	var line_color = get_line_color(current_textedit, line)

	# black is falsey, comparing to null allows us to preview it
	if line_color is Color:
		line_color = line_color as Color
		
		if line_color.a < 1:	# transparent -> add checkered bg + no-alpha corner
			current_textedit.draw_rect(icon_region, Color.WHITE)
			current_textedit.draw_rect( Rect2(
				Vector2(icon_region.position.x + icon_region.size.x/2, icon_region.position.y), 
				icon_region.size/2
			), Color.DIM_GRAY)
			current_textedit.draw_rect( Rect2(
				Vector2(icon_region.position.x, icon_region.position.y + icon_region.size.y/2), 
				icon_region.size/2
			), Color.DIM_GRAY)
			
			current_textedit.draw_colored_polygon(icon_corner_region, Color(line_color, 1.0))
		
		current_textedit.draw_rect(icon_region, line_color)
		current_textedit.set_line_gutter_clickable(line, gutter_position, true)

		if hovering:
			hovering_line = line
	else:
		if hovering:
			hovering_line = null

	# not captured by the hovering check above
	# if left or right of gutter, forget the line
	if mouse_pos.x > area.end.x or mouse_pos.x < area.position.x:
		# in case the picker is open, remember the line even when moving away
		if not picker_popup or not picker_popup.visible:
			hovering_line = null


func get_colors_from_textedit(textedit: TextEdit) -> void:
	var all_lines = textedit.text.split("\n")
	var has_color := false

	for line_index in len(all_lines):
		var color = color_from_string(all_lines[line_index])
		if color != null:
			has_color = true
			set_line_color(textedit, line_index, color)
			textedit.set_gutter_draw(gutter_position, true)
		else:
			set_line_color(textedit, line_index)

	if not has_color:
		textedit.set_gutter_draw(gutter_position, false)


func set_line_color(textedit: TextEdit, line: int, color = null) -> void:
	textedit.set_line_gutter_metadata(line, gutter_position, color)


func get_line_color(textedit: TextEdit, line: int):
	var meta = textedit.get_line_gutter_metadata(line, gutter_position)
	return meta if meta is Color else null


### ### ### COLOR PICKER ### ### ###

func textedit_clicked(event: InputEvent, textedit: TextEdit) -> void:
	if hovering_line != null:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				var color = get_line_color(textedit, hovering_line)
				if color != null:
					picker_popup.get_node("ColorPicker").color = color
					picker_popup.position = event.global_position
					picker_popup.popup()


func picker_color_changed(new_color: Color) -> void:
	if hovering_line and current_textedit:
		set_line_color(current_textedit, hovering_line, new_color)


func on_picker_popup_close() -> void:
	if not hovering_line:
		return
	var text := current_textedit.get_line(hovering_line)
	var color_match : RegExMatch = match_color_in_string(text)
	var new_color = get_line_color(current_textedit, hovering_line)
	text = text.replace(color_match.get_string(), "Color" + str(new_color))
	current_textedit.set_line(hovering_line, text)


### ### ### COLOR INTERPRETATION ### ### ###

func color_from_string(string: String): # Color or null
	var color_match = match_color_in_string(string)
	if !color_match:
		return null
	return color_from_regex_match(color_match)


func color_from_regex_match(regex_match: RegExMatch): # Color or null
	var color_const = regex_match.get_string("const")
	if color_const != null and Color.find_named_color(color_const) != -1:
		return Color(color_const)

	var params = regex_match.get_string("params")
	if not "," in params:
		var color = color_from_string(params)
		if color != null:
			return color
		color = named_or_hex_color(params)
		if color != null:
			return color

	var parameters = params.split(",")
	match len(parameters):
		2:
			var color = color_from_string(parameters[0])
			if color != null:
				return Color(color, parameters[1].to_float())
			color = named_or_hex_color(parameters[0])
			if color != null:
				return Color(color , parameters[1].to_float())
		3:
			return Color(
				parameters[0].to_float(),
				parameters[1].to_float(),
				parameters[2].to_float(),
			)
		4:
			return Color(
				parameters[0].to_float(),
				parameters[1].to_float(),
				parameters[2].to_float(),
				parameters[3].to_float(),
			)
	return null


func named_or_hex_color(string: String): # Color or null
	string = string.trim_prefix("\"").trim_prefix("\'").trim_suffix("\"").trim_suffix("\'")
	if string.is_valid_html_color() or Color.find_named_color(string) != -1:
		return Color(string)
	return null


func match_color_in_string(string: String) -> RegExMatch:
	var re = RegEx.new()
	re.compile("Color\\((?<params>(?R)*.*?)\\)")
	var color = re.search(string)
	if color != null:
		return color
	re.compile("Color\\.(?<const>[A-Z_]+)\\b")
	return re.search(string)

