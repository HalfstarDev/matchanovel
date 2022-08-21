local matchascript = require "matchanovel.matchascript"
local save = require "matchanovel.save"
local settings = require "matchanovel.settings"

local system = require "matchanovel.engine.defold.system"
local messages = require "matchanovel.engine.defold.messages"

local pronouns = require "matchanovel.extensions.pronouns"


local M = {}

local choices

M.state = "uninitialized"
M.pause_active = false



function M.post(receiver, message_id, message)
	messages.post(receiver, message_id, message)
end

function M.exit()
	system.exit()
end





local objects = {
	"textbox",
	"sprites",
	"background",
	"choices",
	"menu",
	"sound",
}



local function execute_string_global(s)
	local string = string.gsub(s, "variables.", "__temp_global_variables.")
	__temp_global_variables = variables
	local f = loadstring("return ("..string..")")
	local result = f()
	__temp_global_variables = nil
	return result
end

local function execute_string_sandbox(s)
	local sandbox_libraries = {"math", "vmath", "string", "tonumber"}
	sandbox = variables
	sandbox.math = math
	sandbox.vmath = vmath
	sandbox.string = string
	sandbox.tonumber = tonumber

	local string = string.gsub(s, "[%a_][%w_%.]*", "sandbox.%0")
	local f = loadstring("return ("..string..")")
	local result = f()
	sandbox = nil
	return result
end

local function is_x_in_a(x, a)
	for k, v in pairs(a) do
		if v == a then return true end
	end
end

local function is_all_capitalized(s)
	if type(s) == "string" then
		local upper = string.upper(s)
		local lower = string.lower(s)
		return s == upper and s ~= lower
	end
end

local function is_capitalized(s)
	if type(s) == "string" then
		local first_letter = string.match(s, "^%a")
		if first_letter then
			local upper = string.upper(first_letter)
			local lower = string.lower(first_letter)
			return first_letter == upper and first_letter ~= lower
		end
	end
end

local function capitalize_first(s)
	return s:gsub("%a", string.upper, 1)
end

local function substitute_in_expression(w)
	local result = ""
	local before_dot, after_dot = string.match(w, "([%a_][%w_]*)%.([%a_][%w_]*)")
	local is_in_lib = before_dot and sandbox[before_dot]
	local add_quotes = false
	if before_dot == "system" and after_dot then
		result = system.get(after_dot) or ""
		add_quotes = true
	elseif is_in_lib or w == "__STRIPPED_QUOTE__" then
		result = w
	else
		local name = string.lower(w)
		local var_value, var_type = save.get_var(name)
		if var_type and var_type == "string" then
			add_quotes = true
		end
		if var_value then
			result = var_value
		else
			result = w
		end
	end
	if is_all_capitalized(w) then
		result = string.upper(result)
	elseif after_dot and is_capitalized(after_dot) then
		result = capitalize_first(result)
	elseif is_capitalized(w) then
		result = capitalize_first(result)
	end
	if add_quotes and result then 
		result = "\""..result.."\""
	end
	return tostring(result)
end

local stripped_quotes = {}

local function strip_quote(s)
	table.insert(stripped_quotes, s)
	return "__STRIPPED_QUOTE__"
end

local function strip_quotes(s)
	stripped_quotes = {}
	return string.gsub(s, "[\"\'][^\"\']*[\"\']", strip_quote)
	 
end

local function return_quote(s)
	local value = stripped_quotes[1]
	table.remove(stripped_quotes, 1)
	return value
end

local function return_quotes(s)
	return string.gsub(s, "__STRIPPED_QUOTE__", return_quote)
end

local function execute_string(s)
	sandbox = {}
	sandbox.math = math
	sandbox.vmath = vmath
	sandbox.string = string
	--sandbox.tonumber = tonumber

	local string = strip_quotes(s)
	string = string.gsub(string, "[%a_][%w_%.]*", substitute_in_expression)
	string = return_quotes(string)
	
	local temp = _G
	_G = sandbox
	local f = loadstring("return "..string)
	local result = ""
	if f then 
		result = f()
	end
	_G = temp
	sandbox = nil
	return result
end

local function add_escapes(s)
	return string.gsub(s, "%W", "%%%0")
end

-- replaces all instances of {x} with value of x
function M.interpolate_string(s)
	local left = "{"
	local right = "}"
	local expression = string.match(s, left.."([^{]*)"..right)
	while expression do
		local value = execute_string(expression) or ""
		value = tostring(value)
		local pattern = add_escapes(left..expression..right)
		s = string.gsub(s, pattern, value)
		expression = string.match(s, left.."([^{]+)"..right)
	end
	return s
end

local function jump(args)
	matchascript.jump_to_label(args[1])
end

local function call(args)
	save.push_call_stack()
	matchascript.jump_to_label(args[1])
end

local function action_return(args)
	local pop = save.pop_call_stack()
	if pop then
		matchascript.jump_to_line(pop)
	end
end

local function say(args)
	M.state = "say"
	local name
	local text
	if args.right then 
		name = args.left
		text = args.right
	else
		name = args.name
		text = args.text or args[0]
	end
	local interpolated_text = M.interpolate_string(text)
	M.post("textbox", "say", {text = interpolated_text, name = name})
	M.post("choices", "delete")
end

local function set(args)
	local name = args.left or args.name or args[1]
	local value_string = args.right or args.value or args[2]

	local value, var_type = matchascript.get_variable(value_string)
	if not value and not var_type then 
		value = execute_string(value_string) or ""
		if value and value ~= "" and tonumber(value) then 
			var_type = "number"
		else
			var_type = "string"
		end
	end
	save.set_var(name, value, var_type)

	local before_dot = string.match(name, "[%a_][%w_]*")
	local after_dot = string.match(name, "[%a_][%w_]*$")
	if before_dot then
		if before_dot == "scene" then
			M.post("background", "action_set", {name = name, value = value, value_string = value_string})
		end
	end
	if after_dot then
		if after_dot == "sprite" then 
			M.post("sprites", "action_set_sprite", {name = before_dot, spr = value})
		end
	end
	
	matchascript.next()
end

local function add(args)
	local name = args.left or args.name or args[1]
	local value_string = args.right or args.value or args[2]
	local value, _ = matchascript.get_variable(value_string)
	local value_a, _ = matchascript.get_variable(name)
	local value_a_number = tonumber(value_a) or 0
	local value_b_number = tonumber(value) or 0
	local sum = value_a_number + value_b_number
	save.set_var(name, sum)
	matchascript.next()
end

local function addone(args)
	local name = args.name or args[1] or args[0]
	local var, _ = matchascript.get_variable(name)
	local value = tonumber(var) or 0
	local sum = value + 1
	save.set_var(name, sum)
	matchascript.next()
end

local function subtract(args)
	local name = args.left or args.name or args[1]
	local value_string = args.right or args.value or args[2]
	local value, _ = matchascript.get_variable(value_string) or value_string
	local value_a, _ = matchascript.get_variable(name)
	local value_a_number = tonumber(value_a) or 0
	local value_b_number = tonumber(value) or 0
	local sum = value_a_number - value_b_number
	save.set_var(name, sum)
	matchascript.next()
end

local function scene(args)
	local scene = args.scene or args[1]
	local transition = args.transition or save.get_var("scene.transition")
	local duration = args.duration or args.t or save.get_var("scene.duration")
	local color = args.color or save.get_var("scene.color")
	local transition_color = args.transition_color or save.get_var("scene.transition_color")
	
	save.set_var("scene.current", scene, "string")
	save.set_var("scene.current_color", color, "string")
	local message = {scene = scene, transition = transition, duration = duration, color = color, transition_color = transition_color}
	M.post("background", "scene", message)
	matchascript.next()
end

local function show(args)
	local name = args[1]
	local at = args.at or args[2]
	local transition = args.transition or save.get_var("show.transition")
	local duration = args.duration or args.t or save.get_var("show.duration")
	local color = args.color or save.get_var("show.color")
	local wait = args.wait
	M.post("sprites", "show", {name = name, at = at, transition = transition, duration = duration, color = color})
	if not wait then
		matchascript.next()
	end
end

local function hide(args)
	local name = args[1]
	local to = args.to or args[2]
	local transition = args.transition or save.get_var("hide.transition")
	local duration = args.duration or args.t or save.get_var("hide.duration")
	local wait = args.wait
	M.post("sprites", "hide", {name = name, to = to, transition = transition, duration = duration})
	if not wait then
		matchascript.next()
	end
end

local function move(args)
	local name = args.name or args[1]
	local to = args.to or args[2]
	local duration = args.duration or args.t or save.get_var("move.duration")
	local wait = args.wait
	M.post("sprites", "move", {name = name, to = to, duration = duration})
	if not wait then
		matchascript.next()
	end
end



local function choice()
	if matchascript.current_line_is_start_of_action_block() then 
		M.state = "choices"
		choices = matchascript.get_current_action_block()
		local text = {}
		for k, v in pairs(choices) do
			text[k] = matchascript.get_argument(v)
		end
		M.post("choices", "show_text_choices", {text = text})
		M.post("textbox", "hide")
	else
		local line = matchascript.get_end_of_current_action_block()
		matchascript.set_line(line)
		matchascript.next()
	end
end

local function play_old(args)
	local file = args[1]
	M.post("sound", "play", {id = file})
	matchascript.next()
end

local function play(args)
	local file
	local group, var_type
	if args[2] then
		group = args[1]
		file = args[2]
	else
		file = args[1]
		group, var_type = save.get_var("sound.group")
		if group == nil then
			group = "music"
		end
	end
	if group == "music" then 
		M.post("sound", "play_music", {id = file})
	elseif group == "sound" then 
		M.post("sound", "play_sfx", {id = file, file = file})
	elseif group == "voice" then 
		M.post("sound", "play_voice", {id = file})
	end
	matchascript.next()
end

local function stop(args)
	if args[1] == "music" then 
		M.post("sound", "stop_music", {id = args[2]})
	elseif args[1] == "sound" then 
		M.post("sound", "stop_sound", {id = args[2]})
	elseif args[1] == "voice" then 
		M.post("sound", "stop_voice", {})
	end
	matchascript.next()
end


local function label(args)
	matchascript.next()
end
local function none(args)
	matchascript.next()
end

local function action_if_true(v)
	if v then
		matchascript.next_step()
	else
		matchascript.next()
	end
end

local function action_if_false(v)
	action_if_true(not v)
end

local function action_if(args)
	action_if_true(execute_string(args[0]))
end

local function default(args)
	say(args)
end


local script_definition = {}
script_definition.actions = {
	"none",
	"label",
	"jump",
	"set",
	"add",
	"addone",
	"subtract",	
	"if",
	"comment",
	"say",
	"show",
	"hide",
	"hideall",
	"move",
	"scene",
	"play",
	"stop",
	"choice",
	"call",
	"return",
	"title",
	"empty",
	"default",
}
script_definition.prefixes = {
	choice = ">",
	comment = "--",
	label = "*",
	jump = "->",
}
script_definition.suffixes = {
	addone = "++",
	call = "()",
}
script_definition.operators = {
	say = ":",
	add = "+=",
	subtract = "-=",
	set = "=",
}
script_definition.functions = {
	jump = jump,
	set = set,
	say = say,
	show = show,
	hide = hide,
	scene = scene,
	play = play,
	stop = stop,
	move = move,
	choice = choice,
	call = call,
	add = add,
	addone = addone,
	subtract = subtract,
	label = label,
	comment = none,
	default = default,
	["return"] = action_return,
	["if"] = action_if,
}
script_definition.extensions = {pronouns}


local render_order = {
	"background",
	--"transition_bg",
	"sprites",
	"textbox",
	"choices",
	"quickmenu",
	--"event",
	--"pause_menu",
	--"transition",
	"title",
	--"config",
	"menu",
	--"border",
	"debug",
}
local input_order = {
	"textbox",
	"choices",
	"quickmenu",
	"choices",
	"title",
	"menu",
}

local function set_render_order()
	for k, v in pairs(render_order) do
		M.post(v, "set_render_order", {n = k})
	end
end

local function set_input_order()
	for k, v in pairs(input_order) do
		M.post(v, "acquire_input_focus", {})
	end
end





function M.add_file(path)
	matchascript.add_file(path)
end

function M.init(path)
	if path then 
		M.add_file(path)
	end
	save.set_save_folder_name("Untitled MatchaNovel project")
	save.init()
	matchascript.set_definition(script_definition)
	set_render_order()
	set_input_order()
	settings.init()
	matchascript.init()
	M.post("menu", "init")
end

function M.load(filename)
	if M.state == "uninitialized" then 
		M.init()
		M.state = "initialized"
	end
end

function M.start()
	M.post("textbox", "start")
	matchascript.start()
end

function M.textbox_done()
	if M.state == "say" then 
		matchascript.next()
	end
end

function M.choose(choice)
	matchascript.jump_to_line(choices[choice] + 1)
end

function M.set_font(font)
	M.post("textbox", "set_font", {font = font})
	M.post("choices", "set_font", {font = font})
end

function M.apply_setting(setting, value)
	if setting == "textspeed" then 
		M.post("textbox", "set_textspeed", {textspeed = value})
	elseif setting == "autospeed" then 
		M.post("textbox", "set_autospeed", {autospeed = value})
	elseif setting == "volume_bgm" then 
		M.post("sound", "set_volume_bgm", {volume = value})
	elseif setting == "volume_sfx" then 
		M.post("sound", "set_volume_sfx", {volume = value})
	end
end

function M.write_save(slot, quick, auto)
	save.write(slot, quick, auto)
end

function M.load_save(slot, quick, auto)
	local loaded
	if quick then
		loaded = save.quickload(slot)
	else
		loaded = save.load(slot)
	end
	if loaded then
		matchascript.jump_to_line(save.state.pos)
		for k, receiver in pairs(objects) do
			M.post(receiver, "loaded")
		end
	end
	return loaded
end

function M.quicksave()
	save.write(1, true, false)
end

function M.quickload()
	return M.load_save(1, true, false)
end

local function add_line_to_file()
end

function M.get_log(line)
	return save.get_log(line)
end

function M.get_log_size()
	return save.get_log_size()
end

function M.add_to_log(text, name)
	return save.add_to_log(text, name)
end


function M.continue()
end






return M
