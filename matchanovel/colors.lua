local save = require "matchanovel.save"

local M = {}

local v3 = vmath.vector3

M.html = {
	-- Black and white
	black			= v3(0.00),
	dimgray			= v3(0.41),
	gray			= v3(0.50),
	darkgray		= v3(0.66),
	silver			= v3(0.75),
	lightgray		= v3(0.83),
	gainsboro		= v3(0.86),
	whitesmoke		= v3(0.96),
	white			= v3(1.00),

	-- Basic colors
	red				= v3(1,  0,  0),
	maroon			= v3(.5, 0,  0),
	yellow			= v3(1,  1,  0),
	olive			= v3(.5, .5, 0),
	lime			= v3(0,  1,  0),
	green			= v3(0,  .5, 0),
	cyan			= v3(0,  1,  1),
	teal			= v3(0,  .5, .5),
	blue			= v3(0,  0,  1),
	navy			= v3(0,  0,  .5),
	magenta			= v3(1,  0,  1),
	purple			= v3(.5, 0,  .5),

	-- Extended colors
	darkred				= v3(139,0,0) / 255,
	brown				= v3(165,42,42) / 255,
	firebrick			= v3(165,42,42) / 255,
	crimson				= v3(220,20,60) / 255,
	tomato				= v3(255,99,71) / 255,
	coral				= v3(255,127,80) / 255,
	indianred			= v3(205,92,92) / 255,
	lightcoral			= v3(240,128,128) / 255,
	darksalmon			= v3(233,150,122) / 255,
	salmon				= v3(250,128,114) / 255,
	lightsalmon			= v3(255,160,122) / 255,
	orangered			= v3(255,69,0) / 255,
	darkorange			= v3(255,140,0) / 255,
	orange				= v3(255,165,0) / 255,
	gold				= v3(255,215,0) / 255,
	darkgoldenrod		= v3(184,134,11) / 255,
	goldenrod			= v3(218,165,32) / 255,
	palegoldenrod		= v3(238,232,170) / 255,
	darkkhaki			= v3(189,183,107) / 255,
	khaki				= v3(240,230,140) / 255,
	yellowgreen			= v3(154,205,50) / 255,
	darkolivegreen		= v3(85,107,47) / 255,
	olivedrab			= v3(107,142,35) / 255,
	lawngreen			= v3(124,252,0) / 255,
	chartreuse			= v3(127,255,0) / 255,
	greenyellow			= v3(173,255,47) / 255,
	darkgreen			= v3(0,100,0) / 255,
	forestgreen			= v3(34,139,34) / 255,
	limegreen			= v3(50,205,50) / 255,
	lightgreen			= v3(144,238,144) / 255,
	palegreen			= v3(152,251,152) / 255,
	darkseagreen		= v3(143,188,143) / 255,
	mediumspringgreen	= v3(0,250,154) / 255,
	springgreen			= v3(0,255,127) / 255,
	seagreen			= v3(46,139,87) / 255,
	mediumaquamarine	= v3(102,205,170) / 255,
	mediumseagreen		= v3(60,179,113) / 255,
	lightseagreen		= v3(32,178,170) / 255,
	darkslategray		= v3(47,79,79) / 255,
	darkcyan			= v3(0,139,139) / 255,
	lightcyan			= v3(224,255,255) / 255,
	darkturquoise		= v3(0,206,209) / 255,
	turquoise			= v3(64,224,208) / 255,
	mediumturquoise		= v3(72,209,204) / 255,
	paleturquoise		= v3(175,238,238) / 255,
	aquamarine			= v3(127,255,212) / 255,
	powderblue			= v3(176,224,230) / 255,
	cadetblue			= v3(95,158,160) / 255,
	steelblue			= v3(70,130,180) / 255,
	cornflowerblue		= v3(100,149,237) / 255,
	deepskyblue			= v3(0,191,255) / 255,
	dodgerblue			= v3(30,144,255) / 255,
	lightblue			= v3(173,216,230) / 255,
	skyblue				= v3(135,206,235) / 255,
	lightskyblue		= v3(135,206,250) / 255,
	midnightblue		= v3(25,25,112) / 255,
	darkblue			= v3(0,0,139) / 255,
	mediumblue			= v3(0,0,205) / 255,
	royalblue			= v3(65,105,225) / 255,
	blueviolet			= v3(138,43,226) / 255,
	indigo				= v3(75,0,130) / 255,
	darkslateblue		= v3(72,61,139) / 255,
	slateblue			= v3(106,90,205) / 255,
	mediumslateblue		= v3(123,104,238) / 255,
	mediumpurple		= v3(147,112,219) / 255,
	darkmagenta			= v3(139,0,139) / 255,
	darkviolet			= v3(148,0,211) / 255,
	darkorchid			= v3(153,50,204) / 255,
	mediumorchid		= v3(186,85,211) / 255,
	thistle				= v3(216,191,216) / 255,
	plum				= v3(221,160,221) / 255,
	violet				= v3(238,130,238) / 255,
	orchid				= v3(218,112,214) / 255,
	mediumvioletred		= v3(199,21,133) / 255,
	palevioletred		= v3(219,112,147) / 255,
	deeppink			= v3(255,20,147) / 255,
	hotpink				= v3(255,105,180) / 255,
	lightpink			= v3(255,182,193) / 255,
	pink				= v3(255,192,203) / 255,
	antiquewhite		= v3(250,235,215) / 255,
	beige				= v3(245,245,220) / 255,
	bisque				= v3(255,228,196) / 255,
	blanchedalmond		= v3(255,235,205) / 255,
	wheat				= v3(245,222,179) / 255,
	cornsilk			= v3(255,248,220) / 255,
	lemonchiffon		= v3(255,250,205) / 255,
	lightgoldenrodyellow= v3(250,250,210) / 255,
	lightyellow			= v3(255,255,224) / 255,
	saddlebrown			= v3(139,69,19) / 255,
	sienna				= v3(160,82,45) / 255,
	chocolate			= v3(210,105,30) / 255,
	peru				= v3(205,133,63) / 255,
	sandybrown			= v3(244,164,96) / 255,
	burlywood			= v3(222,184,135) / 255,
	tan					= v3(210,180,140) / 255,
	rosybrown			= v3(188,143,143) / 255,
	moccasin			= v3(255,228,181) / 255,
	navajowhite			= v3(255,222,173) / 255,
	peachpuff			= v3(255,218,185) / 255,
	mistyrose			= v3(255,228,225) / 255,
	lavenderblush		= v3(255,240,245) / 255,
	linen				= v3(250,240,230) / 255,
	oldlace				= v3(253,245,230) / 255,
	papayawhip			= v3(255,239,213) / 255,
	seashell			= v3(255,245,238) / 255,
	mintcream			= v3(245,255,250) / 255,
	slategray			= v3(112,128,144) / 255,
	lightslategray		= v3(119,136,153) / 255,
	lightsteelblue		= v3(176,196,222) / 255,
	lavender			= v3(230,230,250) / 255,
	floralwhite			= v3(255,250,240) / 255,
	aliceblue			= v3(240,248,255) / 255,
	ghostwhite			= v3(248,248,255) / 255,
	honeydew			= v3(240,255,240) / 255,
	ivory				= v3(255,255,240) / 255,
	azure				= v3(240,255,255) / 255,
	snow				= v3(255,250,250) / 255,
}

-- aliases
M.html.grey			= M.html.gray
M.html.dimgrey		= M.html.dimgray
M.html.darkgrey		= M.html.darkgray
M.html.lightgrey	= M.html.lightgray
M.html.aqua			= M.html.cyan
M.html.fuchsia		= M.html.magenta



local function hex_to_dec(hex)
	return tonumber("0x"..hex)
end

function M.hex_to_rgb(hex)
	if not type(hex) == "string" then return false end
	local r_hex, g_hex, b_hex = string.match(hex, "^#(%w%w)(%w%w)(%w%w)")
	if r_hex and g_hex and b_hex then
		local r = hex_to_dec(r_hex)/255
		local g = hex_to_dec(g_hex)/255
		local b = hex_to_dec(b_hex)/255
		return r, g, b
	else
		return false
	end
end

function M.string_to_color(s)
	if not s then return end
	if s.x and s.y and s.z then return s end
	
	local r, g, b = M.hex_to_rgb(s)
	if r and g and b then
		return vmath.vector4(r, g, b, 1)
	end

	local color_name
	color_name = string.gsub(s, "_", "")
	color_name = string.gsub(color_name, " ", "")
	color_name = string.lower(color_name)
	local result = M.html[color_name]
	if result then
		return result
	end
end

function M.get_color(name)
	local color = M.string_to_color(name)
	local type
	if color then 
		return color
	end
	
	color, type = save.get_var(name..".color")

	if type == "color" then 
		return color
	end

	if color then 
		return M.string_to_color(color)
	end
	
	local r = save.get_var(name..".r") or save.get_var(name..".color.r")
	local g = save.get_var(name..".g") or save.get_var(name..".color.g")
	local b = save.get_var(name..".b") or save.get_var(name..".color.b")
	if r or g or b then
		return vmath.vector4(r or 0, g or 0, b or 0, 1)
	end
end

return M