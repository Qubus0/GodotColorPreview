@tool
extends EditorPlugin

var editor: Node = null
var editors = []
var gutter_position = 0
var gutter_name = "color_preview"
var gutter_texture = preload("res://addons/ColorPreview/Preview.png")


func _enter_tree() -> void:
	var editor = get_editor_interface()
	var script_editor = editor.get_script_editor()
	script_editor.connect("editor_script_changed", editor_script_changed)
	get_all_text_editors(script_editor)


func _exit_tree() -> void:
	var editor = get_editor_interface()
	var script_editor = editor.get_script_editor()
	get_all_text_editors(script_editor)
	for child in editors:
		if child is TextEdit:
			remove_color_gutter(child)


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
	var editor = get_editor_interface()
	# just in case the editor instance changes
	if not editors.has(textedit):
		editors.clear()
		get_all_text_editors(editor.get_script_editor())
	preview_colors(textedit)


func text_changed(textedit : TextEdit) -> void:
	var editor = get_editor_interface()
	if not editors.has(textedit):
		editors.clear()
		get_all_text_editors(editor.get_script_editor())
	preview_colors(textedit)


func editor_script_changed(script: Script) -> void:
	var editor = get_editor_interface()
	var script_editor = editor.get_script_editor()
	editors.clear()
	get_all_text_editors(script_editor)
	

func add_color_gutter(textedit: TextEdit) -> void:
	var has_preview := false
	for gutter in textedit.get_gutter_count() - 1:
		if textedit.get_gutter_name(gutter) == gutter_name:
			has_preview = true

	if not has_preview:
		textedit.add_gutter(gutter_position)
		textedit.set_gutter_type(gutter_position, TextEdit.GUTTER_TYPE_ICON)
		textedit.set_gutter_name(gutter_position, gutter_name)
		textedit.set_gutter_width(gutter_position, 35)

# 		custom gutter with color picker? not figured out yet
#		textedit.set_gutter_clickable(gutter_position, true)
#		textedit.set_gutter_type(gutter_position, TextEdit.GUTTER_TYPE_CUSTOM)
#		textedit.set_gutter_custom_draw(gutter_position, custom_draw)
#		textedit.set_gutter_draw(gutter_position, true)

#func custom_draw(line: int, gutter: int, area: Rect2):
#	var picker = preload("res://addons/ColorPreview/Picker.tscn")
#	picker.instantiate()


func remove_color_gutter(textedit: TextEdit) -> void:
	for gutter_index in textedit.get_gutter_count() - 1:
		if textedit.get_gutter_name(gutter_index) == "color_preview":
			textedit.remove_gutter(gutter_position)


func preview_colors(textedit: TextEdit) -> void:
	var all_lines = textedit.text.split("\n")
	var has_color = false
	
	for line_index in len(all_lines):
		var color = color_from_string(all_lines[line_index])
		if color != null:
			has_color = true
			add_color_gutter(textedit)
			textedit.set_line_gutter_icon(line_index, gutter_position, gutter_texture)
			textedit.set_line_gutter_item_color(line_index, gutter_position, color)
		else:
			textedit.set_line_gutter_icon(line_index, gutter_position, null)
	
	if not has_color:
		remove_color_gutter(textedit)


func color_from_string(string: String):
	var color_match = match_color_in_string(string)
	if !color_match:
		return null
	return color_from_regex_match(color_match)


func color_from_regex_match(regex_match: RegExMatch):
	var color_const = regex_match.get_string("const")
	if color_const and Color.find_named_color(color_const) != -1:
		return Color(color_const)

	var params = regex_match.get_string("params")
	if not "," in params:
		var color = color_from_string(params)
		if color:
			return color
		color = named_or_hex_color(params)
		if color:
			return color

	var parameters = params.split(",")
	match len(parameters):
		2:
			var color = color_from_string(parameters[0])
			if color:
				return Color(color, parameters[1].to_float())
			color = named_or_hex_color(parameters[0])
			if color:
				return Color(color , parameters[1].to_float())
		3:
			return Color(parameters[0].to_float(), parameters[1].to_float(), parameters[2].to_float())
		4:
			return Color(parameters[0].to_float(), parameters[1].to_float(), parameters[2].to_float(), parameters[3].to_float())
	return null


func named_or_hex_color(string: String):
	string = string.trim_prefix("\"").trim_prefix("\'").trim_suffix("\"").trim_suffix("\'")
	if string.is_valid_html_color() or Color.find_named_color(string) != -1:
		return Color(string)
	return null


func match_color_in_string(string: String) -> RegExMatch:
	var re = RegEx.new()
	re.compile("Color\\((?<params>(?R)*.*?)\\)")
	var color = re.search(string)
	if color:
		return color
	re.compile("Color\\.(?<const>[A-Z_]+)\\b")
	return re.search(string)

