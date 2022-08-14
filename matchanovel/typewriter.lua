-- Import typewriter in gui scripts with:
-- local typewriter = require "typewriter.typewriter"

local M = {}

local typewriters = {}
local current


local function animate_alpha(node, to, duration, delay, done)
	gui.animate(node, "color.w", to, gui.EASING_LINEAR, duration, delay, done)
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

local function is_a_in_b(a, b)
	for _, v in ipairs(b) do
		if a == v then 
			return true
		end
	end
	return false
end

local function is_special_char(char)
	local special = {"ä", "ö", "ü", "Ä", "Ö", "Ü", "ß"}
	return is_a_in_b(char, special)
end

local function create_character_table(text)
	local character_table = {}
	local n = #text
	for i = 1, n do
		if #text == 0 then break end
		if is_special_char(string.sub(text, 0, 2)) then
			table.insert(character_table, string.sub(text, 0, 2))
			text = string.sub(text, 3)
		else
			table.insert(character_table, string.sub(text, 0, 1))
			text = string.sub(text, 2)
		end
	end
	return character_table
end

local function get_letter(n)
	if not current.letter_nodes[n] then
		current.letter_nodes[n] = gui.clone(current.node)
		gui.set_parent(current.letter_nodes[n], current.parent, false)
	end
	return current.letter_nodes[n]
end

local function delete_letters()
	for k, node in pairs(current.letter_nodes) do
		gui.delete_node(node)
	end
	current.letter_nodes = {}

	if current.instant_node then
		gui.delete_node(current.instant_node)
		current.instant_node = nil
	end
end

local function set_letters(line_table, instant)
	for _, node in pairs(current.letter_nodes) do
		gui.cancel_animation(node, "color.w")
		gui.set_alpha(node, 0)
		gui.set_text(node, "")
	end

	local font_resource = gui.get_font_resource(gui.get_font(current.node))
	local text = "X"
	local metrics = resource.get_text_metrics(font_resource, text)
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
			metrics = resource.get_text_metrics(font_resource, text.."X")
			local letter = get_letter(n_letters)
			gui.set_text(letter, character)
			gui.cancel_animation(letter, "position")
			gui.cancel_animation(letter, "color.w")
			gui.set_position(letter, vmath.vector3((metrics.width - width), (1-k)*height, 0))
			gui.set_scale(letter, vmath.vector3(1, 1, 1))
			if instant then 
				gui.set_alpha(letter, 1)
			else
				gui.set_alpha(letter, 0)
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

	local font_resource = gui.get_font_resource(gui.get_font(current.node))
	local text = "X"
	local metrics = resource.get_text_metrics(font_resource, text)
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
			metrics = resource.get_text_metrics(font_resource, text.."X")
			local letter = get_letter(n_letters)
			gui.animate(letter, "position", vmath.vector3((metrics.width - width), (1-k)*height, 0), gui.EASING_LINEAR, current.zoom_speed)
			text = text..character
		end
	end
end

local function split_text_into_lines(text, max_width)
	local font_resource = gui.get_font_resource(gui.get_font(current.node))
	local options = {line_break = true}
	local metrics = resource.get_text_metrics(font_resource, text, options)
	local lines = 1
	local first = true
	local text_table = {}
	text_table[1] = ""
	local next_word
	while(metrics.width > max_width and next_word ~= "") do
		local next_space = string.find(text, " ") or #text
		next_word = string.sub(text, 0, next_space)
		local line_metrics = resource.get_text_metrics(font_resource, text_table[lines]..next_word, options)
		if (line_metrics.width > max_width and not first) then
			lines = lines + 1
			text_table[lines] = next_word
			text = string.sub(text, next_space+1)
			if next_word == "" then 
				metrics = resource.get_text_metrics(font_resource, text, options)
			else
				metrics = resource.get_text_metrics(font_resource, text.." "..next_word, options)
			end
		else
			text_table[lines] = text_table[lines]..next_word
			text = string.sub(text, next_space+1) 
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

	local width = gui.get_size(current.node).x / current.scale
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
	current.node = gui.get_node(id)
	current.parent = gui.clone(current.node)
	gui.set_parent(current.parent, current.node, true)
	gui.set_scale(current.parent, vmath.vector3(1, 1, 1))
	gui.set_text(current.parent, "")
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

function M.set_instant_text(text)
	local duration = 0.1
	if not current.instant_node then 
		current.instant_node = gui.clone(current.node)
		gui.set_parent(current.instant_node, current.node)
		gui.set_scale(current.instant_node, vmath.vector3(current.scale, current.scale, 1))
		gui.set_position(current.instant_node, vmath.vector3(0, 0, 0))
		gui.set_size(current.instant_node, gui.get_size(current.node) / current.scale)
		gui.set_line_break(current.instant_node, true)
	end
	gui.set_alpha(current.instant_node, 1)
	gui.set_alpha(current.parent, 0)
	gui.set_text(current.instant_node, text)
end

function M.hide_instant_text()
	if current.instant_node then
		gui.delete_node(current.instant_node)
		current.instant_node = nil
	end
	gui.set_alpha(current.parent, 1)
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
		local width = gui.get_size(current.node).x / current.scale
		local lines = split_text_into_lines(current.text, width)
		reposition_letters(lines)
	end
end 

function M.redraw()
	delete_letters()
	if current.state == "empty" then return end
	start_typewriter(current.text, true)
end

function M.set_scale(scale)
	current.scale = scale
	gui.set_scale(current.parent, vmath.vector3(scale, scale, 1))
end

-- Change zoom of text while keeping same line width.
function M.zoom(scale)
	current.scale = scale
	gui.animate(current.parent, "scale", vmath.vector3(scale, scale, 1), gui.EASING_LINEAR, current.zoom_speed)
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
