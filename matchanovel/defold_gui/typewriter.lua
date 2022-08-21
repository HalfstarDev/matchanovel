-- Import typewriter in gui scripts with:
-- local typewriter = require "typewriter.typewriter"

local M = {}

local typewriters = {}
local current

local v3 = vmath.vector3
local string_sub = string.sub
local string_byte = string.byte
local string_find = string.find

-- Defold functions
local gui_animate = gui.animate
local gui_clone = gui.clone
local gui_cancel_animation = gui.cancel_animation
local gui_delete_node = gui.delete_node
local gui_get_font = gui.get_font
local gui_get_font_resource = gui.get_font_resource
local gui_get_node = gui.get_node
local gui_get_size = gui.get_size
local gui_set_alpha = gui.set_alpha
local gui_set_line_break = gui.set_line_break
local gui_set_parent = gui.set_parent
local gui_set_position = gui.set_position
local gui_set_scale = gui.set_scale
local gui_set_size = gui.set_size
local gui_set_text = gui.set_text
local resource_get_text_metrics = resource.get_text_metrics




local EASING_LINEAR = gui.EASING_LINEAR

local function animate_alpha(node, to, duration, delay, done)
	gui_animate(node, "color.w", to, EASING_LINEAR, duration, delay, done)
end

local function letters_animated()
	if current.state == "typing" then 
		current.state = "waiting"
	end
end

local function animate_letter(node, delay, last)
	if last then 
		animate_alpha(node, 1, current.letter_fadein, delay, letters_animated)
	else
		animate_alpha(node, 1, current.letter_fadein, delay)
	end
end

local function fade_done()
	current.state = "empty"
	msg.post("#", "typewriter_next")
end

local function fade_letter(node, delay, last)
	if last then 
		animate_alpha(node, 0, current.letter_fadeout, delay, fade_done)
	else
		animate_alpha(node, 0, current.letter_fadeout, delay)
	end
end




function get_utf8_length(s)
	local c = string_byte(s)
	if c <= 0 then
		return 1
	elseif c <= 127 then
		return 1
	elseif 194 <= c and c <= 223 then
		return 2
	elseif 224 <= c and c <= 239 then
		return 3
	elseif 240 <= c and c <= 244 then
		return 4
	else
		return 1
	end
end

-- is the character a Chinese, Japanese, or Korean character (or other with utf8_length of 3) 
local function is_cjk(char)
	local c = string_byte(char)
	return 223 < c and c < 245
end

local function create_character_table(text)
	local character_table = {}
	local n = #text
	while n and n>0 do
		local first = string_sub(text, 0, 1)
		local utf8_length = get_utf8_length(first)
		local length = math.min(utf8_length, n)
		local character = string_sub(text, 0, length)
		text = string_sub(text, length + 1)
		n = #text
		table.insert(character_table, character)
	end
	return character_table
end

local function get_letter(n)
	if not current.letter_nodes[n] then
		current.letter_nodes[n] = gui_clone(current.node)
		gui_set_parent(current.letter_nodes[n], current.parent, false)
	end
	return current.letter_nodes[n]
end


local function delete_letters()
	for k, node in pairs(current.letter_nodes) do
		gui_delete_node(node)
	end
	current.letter_nodes = {}

	if current.instant_node then
		gui_delete_node(current.instant_node)
		current.instant_node = nil
	end
end


local function set_letters(line_table, instant)
	for _, node in pairs(current.letter_nodes) do
		gui_cancel_animation(node, "color.w")
		gui_set_alpha(node, 0)
		gui_set_text(node, "")
	end

	local font_resource = gui_get_font_resource(gui_get_font(current.node))
	local text = "X"
	local metrics = resource_get_text_metrics(font_resource, text)
	local height = metrics.height
	local width = metrics.width

	if current.line_spacing_scale then
		height = height * current.line_spacing_scale
	end

	n_letters = 0
	for k, line in pairs(line_table) do
		text = ""
		local character_table = create_character_table(line)
		for j, character in pairs(character_table) do
			n_letters = n_letters + 1
			metrics = resource_get_text_metrics(font_resource, text.."X")
			local letter = get_letter(n_letters)
			gui_set_text(letter, character)
			gui_cancel_animation(letter, "position")
			gui_cancel_animation(letter, "color.w")
			gui_set_position(letter, v3((metrics.width - width), (1-k)*height, 0))
			gui_set_scale(letter, v3(1, 1, 1))
			if instant then 
				gui_set_alpha(letter, 1)
			else
				gui_set_alpha(letter, 0)
				animate_letter(letter, (n_letters-1)/current.textspeed, k == #line_table and j == #character_table)
			end
			text = text..character
		end
	end
	if instant or n_letters == 0 then 
		current.state = "waiting"
	end
end


local function reposition_letters(line_table)
	if not line_table then 
		return
	end

	local font_resource = gui_get_font_resource(gui_get_font(current.node))
	local text = "X"
	local metrics = resource_get_text_metrics(font_resource, text)
	local height = metrics.height
	local width = metrics.width

	if current.line_spacing_scale then
		height = height * current.line_spacing_scale
	end

	n_letters = 0
	for k, line in pairs(line_table) do
		text = ""
		local character_table = create_character_table(line)
		for j, character in pairs(character_table) do
			n_letters = n_letters + 1
			metrics = resource_get_text_metrics(font_resource, text.."X")
			local letter = get_letter(n_letters)
			gui_animate(letter, "position", v3((metrics.width - width), (1-k)*height, 0), EASING_LINEAR, current.zoom_speed)
			text = text..character
		end
	end
end

local function get_next_space(text)
	local next_space = 1
	for c in string.gmatch(text, ".") do
		if is_cjk(c) then 
			return next_space + get_utf8_length(c) - 1
		elseif c == " " then
			return next_space
		else
			next_space = next_space + 1
		end
	end
	return next_space
end



local function split_text_into_lines(text, max_width)
	local font_resource = gui_get_font_resource(gui_get_font(current.node))
	local options = {line_break = true}
	local metrics = resource_get_text_metrics(font_resource, text, options)
	local lines = 1
	local first = true
	local text_table = {}
	text_table[1] = ""
	local next_word
	while(metrics.width > max_width and next_word ~= "") do
		local next_space = get_next_space(text)
		next_word = string_sub(text, 0, next_space)
		local line_metrics = resource_get_text_metrics(font_resource, text_table[lines]..next_word, options)
		if (line_metrics.width > max_width and not first) then
			lines = lines + 1
			text_table[lines] = next_word
			text = string_sub(text, next_space+1)
			if next_word == "" then 
				metrics = resource_get_text_metrics(font_resource, text, options)
			else
				metrics = resource_get_text_metrics(font_resource, text.." "..next_word, options)
			end
		else
			text_table[lines] = text_table[lines]..next_word
			text = string_sub(text, next_space+1) 
			first = false
		end
	end
	text_table[lines] = text_table[lines]..text
	return text_table
end

local function start_typewriter(text, instant)
	text = text or ""
	current.state = "typing"
	current.text = text

	local width = gui_get_size(current.node).x / current.scale
	local lines = split_text_into_lines(text, width)
	set_letters(lines, instant)
end

local function end_typewriter()
	for _, node in pairs(current.letter_nodes) do
		animate_letter(node, 0)
	end
	current.state = "waiting"
end

local function fade_away()
	current.state = "fade_away"
	for k, node in pairs(current.letter_nodes) do
		fade_letter(node, 0, k == #current.letter_nodes)
	end
end

local function clear()
	for k, node in pairs(current.letter_nodes) do
		fade_letter(node, 0)
	end
	current.state = "waiting"
end





-- Create new typewriter. Only necessary if using multiple typewriters.
function M.new(options)
	if not options then options = {} end
	local new = {}
	new.state = "inactive"
	new.textspeed = options.textspeed or 70
	new.letter_fadein = options.letter_fadein or 0.2
	new.letter_fadeout = options.letter_fadeout or 0.2
	new.line_spacing_scale = options.line_spacing_scale or 1
	new.zoom_speed = 0.15
	new.scale = 1
	new.node = nil
	new.auto = false
	new.letter_nodes = {}

	local id = #typewriters + 1
	typewriters[id] = new
	current = new
	return id
end

-- Set the name of the text node that typewriter uses as base.
function M.set_node(id)
	current.node = gui_get_node(id)
	current.parent = gui_clone(current.node)
	gui_set_parent(current.parent, current.node, true)
	gui_set_scale(current.parent, v3(1, 1, 1))
	gui_set_text(current.parent, "")
end

-- Change options.
-- textspeed, letter_fadein, letter_fadeout, line_spacing_scale, zoom_speed
function M.set_options(options)
	if not options then return end
	current.textspeed = options.textspeed or current.textspeed
	current.letter_fadein = options.letter_fadein or current.letter_fadein
	current.letter_fadeout = options.letter_fadeout or current.letter_fadeout
	current.line_spacing_scale = options.line_spacing_scale or current.line_spacing_scale
	current.zoom_speed = options.zoom_speed or current.zoom_speed
end

-- Initialize typewriter on node_id, optional options.
function M.init(node_id, options)
	M.set_node(node_id)
	if options then 
		M.set_options(options)
	end
end

-- If you use the typewriter on different text nodes, you can change it by providing the id returned by new()
function M.change_typewriter(id)
	current = typewriters[id]
end

-- Clears old text and starts typing.
function M.start(text)
	start_typewriter(text, instant)
end

local function add_line_breaks(text, max_width)
	local text_lines = split_text_into_lines(text, max_width)
	local text_with_lines_breaks
	local first_line = true
	for k, v in pairs(text_lines) do
		if first_line then 
			text_with_lines_breaks = v
			first_line = false
		else
			text_with_lines_breaks = text_with_lines_breaks .. "\n" .. v
		end
	end
	return text_with_lines_breaks
end

local instant_text

function M.set_instant_text(text)
	instant_text = text
	local duration = 0.1
	if not current.instant_node then 
		current.instant_node = gui_clone(current.node)
		gui_set_parent(current.instant_node, current.node)
		gui_set_scale(current.instant_node, v3(current.scale, current.scale, 1))
		gui_set_position(current.instant_node, v3(0, 0, 0))
		gui_set_size(current.instant_node, gui_get_size(current.node) / current.scale)
		gui_set_line_break(current.instant_node, true)
	end
	gui_set_alpha(current.instant_node, 1)
	gui_set_alpha(current.parent, 0)

	local max_width = gui_get_size(current.instant_node).x
	local text_with_lines_breaks = add_line_breaks(text, max_width)

	gui_set_text(current.instant_node, text_with_lines_breaks)

	--[[
	current.instant_node = gui_clone(current.node)
	gui_set_text(current.instant_node, text)
	gui_set_alpha(current.instant_node, 0)
	animate_alpha(current.parent, 0, duration, 0, nil)
	animate_alpha(current.instant_node, 1, duration, duration, nil)
	--]]
end

function M.hide_instant_text()
	if current.instant_node then
		gui_delete_node(current.instant_node)
		current.instant_node = nil
	end
	instant_text = false
	--animate_alpha(current.parent, 1, 0.2, 0, nil)
	gui_set_alpha(current.parent, 1)
end

-- Finishes current text if still typing, removes text and asks for next text if already typed.
function M.next()
	if current.state == "typing" then
		end_typewriter()
	elseif current.state == "waiting" then
		fade_away()
	end
end

-- Clears current text from textbox without asking for next action.
function M.clear()
	clear()
end

-- Repositions the currently typed text, respecting changed zoom and width.
function M.reposition()
	if current and current.text then
		local width = gui_get_size(current.node).x / current.scale
		local lines = split_text_into_lines(current.text, width)
		reposition_letters(lines)
	end
end 

function M.redraw()
	delete_letters()
	if instant_text then 
		M.set_instant_text(instant_text)
	end
	if current.state == "empty" then return end
	start_typewriter(current.text, true)
end

function M.set_scale(scale)
	current.scale = scale
	gui_set_scale(current.parent, v3(scale, scale, 1))
end

-- Change zoom of text while keeping same line width.
function M.zoom(scale)
	current.scale = scale
	gui_animate(current.parent, "scale", v3(scale, scale, 1), EASING_LINEAR, current.zoom_speed)
	M.reposition()
end

-- Get the current state of the typewriter.
-- "inactive": typewrite is not in use
-- "typing": typewriter is not yet finished typing the current text
-- "waiting": typewriter is finished typing the current text and waits for next action
function M.get_state()
	return current.state
end

M.new()

return M
