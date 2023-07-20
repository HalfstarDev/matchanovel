local M = {}

local theme
local themes = {}

themes.default = {
	type = "default",
	color_menu_back = vmath.vector3(0, 0, 0),
	color_menu_front = vmath.vector3(1, 1, 1),
	color_textbox_back = vmath.vector3(1, 1, 1),
	color_textbox_front = vmath.vector3(0.25, 0.16, 0.03),
	alpha_save_hover = 0.5,
	font_text = "serif",
	font_text_outline = vmath.vector4(1, 1, 1, 0.2),
	font_menu = "font_menu",
	font_tabs_scale = 1.0,
	font_text_tracking = 0,
	font_text_leading = 1,
}

themes.dark = {
	type = "dark",
	color_menu_back = vmath.vector3(0, 0, 0),
	color_menu_front = vmath.vector3(1, 1, 1),
	color_textbox_back = vmath.vector3(0, 0, 0),
	color_textbox_front = vmath.vector3(1, 1, 1),
	font_text = "serif",
	font_text_outline = vmath.vector4(0, 0, 0, 0.2),
	font_menu = "font_menu",
	font_tabs_scale = 1.0,
}

themes.light = {
	type = "light",
	color_menu_back = vmath.vector3(1, 1, 1),
	color_menu_front = vmath.vector3(0.25, 0.16, 0.03),
	color_textbox_back = vmath.vector3(1, 1, 1),
	color_textbox_front = vmath.vector3(0.25, 0.16, 0.03),
	font_text = "serif",
	font_menu = "font_menu",
	font_tabs_scale = 1.0,
}

themes.dyslexia = {
	type = "dyslexia",
	color_menu_back = vmath.vector3(1, 1, 1),
	color_menu_front = vmath.vector3(0.20, 0.20, 0.20),
	color_textbox_back = vmath.vector3(1, 1, 1),
	color_textbox_front = vmath.vector3(0.20, 0.20, 0.20),
	alpha_save_hover = 0.9,
	font_text = "dyslexia",
	font_menu = "dyslexia",
	font_tabs_scale = 1.4,
	font_text_tracking = 0.025,
	font_text_leading = 1,
}

theme = themes.default

function M.get(id)
	return theme[id] or themes.default[id]
end

function M.set(id)
	theme = themes[id] or theme or themes.default
end

return M