shader_type canvas_item;

// supports shader uniforms with type hint source_color
uniform vec4 input_color : source_color = vec4(0.0952, 0.8355, 0.9494, 1);
uniform vec4 transparent_color : source_color = vec4(0.95, 0.24, 0.52, 0.6);

// and any vec4 as color with this comment in front
/* source_color */ uniform vec4 not_type_hinted = vec4(1, 0.8549, 0.102, 1);

// Color.BLACK <- technically you can also view these


// 						picking and selecting also works the same
uniform vec4 picker_color : source_color = vec4(0.9049, 0.5072, 0.0389, 1);