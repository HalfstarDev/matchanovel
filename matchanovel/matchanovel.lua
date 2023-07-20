local matchascript = require "matchanovel.matchascript"
local save = require "matchanovel.save"
local settings = require "matchanovel.settings"

local system = require "matchanovel.engine.defold.system"
local messages = require "matchanovel.engine.defold.messages"
local images = require "matchanovel.defold_gui.images"

local pronouns = require "matchanovel.extensions.pronouns"
local _fmod = require "matchanovel.fmod"


local M = {}

local choices

M.state = "uninitialized"
M.pause_active = false
M.loremipsum = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum."


local objects = {
	"textbox",
	"sprites",
	"background",
	"choices",
	"menu",
	"sound",
	"particles_back",
}

local urls = {
	["save.folder"] = save.get_url()
}


function M.post(receiver, message_id, message)
	messages.post(receiver, message_id, message)
end

local function exit(code)
	system.exit(code)
end

function M.exit(code)
	exit(code)
end

local function action_exit(args)
	local code
	local arg = args[0]
	if arg and #arg > 0 then
		code = tonumber(arg)
	end
	exit(code)
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
		result = system.get(after_dot)
		if result == nil then
			result = ""
		end
		add_quotes = true
	elseif before_dot == "settings" and after_dot then
		result = settings.get_variable(after_dot)
		if result == nil then
			result = ""
		end
		if result == nil then
			result = ""
		end
		add_quotes = true
	elseif before_dot == "save" and after_dot then
		if after_dot == "folder" then
			result = save.get_url()
		end
		if result == nil then
			result = ""
		end
		add_quotes = true
	elseif is_in_lib or w == "__STRIPPED_QUOTE__" then
		result = w
	else
		local name = string.lower(w)
		local var_value, var_type = save.get_var(name)
		if var_type and var_type == "string" then
			add_quotes = true
		end
		if var_value or var_type == "bool" or var_type == "nil" then
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
		result = "\""..tostring(result).."\""
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

	local string = strip_quotes(s)
	string = string.gsub(string, "[%a_][%w_%.]*", substitute_in_expression)
	string = return_quotes(string)
	string = string.gsub(string, "\\", "\\\\")
	
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
		local value = execute_string(expression)
		if value ~= nil then
			value = tostring(value)
		else
			value = ""
		end
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
		matchascript.jump_to_line(pop + 1)
	end
end

local function change_sprite(name, spr)
	M.post("sprites", "set_sprite", {name = name, spr = spr})
end

local function flip_sprite(name)
	local var_id = name..".flip_x"
	local flip_x = save.get_var(var_id)
	save.set_var(var_id, not flip_x, "bool")
	M.post("sprites", "update_flip", {name = name})
end

local function separate_from_dot(s)
	local before_last_dot, after_last_dot = string.match(s, "(.*)%.([^%.]*)$")
	return before_last_dot, after_last_dot
end

local function has_alternative_sprite(name, expression)
	local filename = "/assets/images/sprites/"..name.."_"..expression..".png"
	if images.exists(filename) then
		return filename
	end
end

local function set_expression(name, expression)
	if expression then
		if expression == "default" then
			save.set_var(name..".expression", nil)
		else
			save.set_var(name..".expression", expression)
		end
	end
end

local function say(args)
	M.state = "say"
	local name
	local expression_name
	local text
	if args.right then 
		name = args.left
		text = args.right
	else
		name = args.name
		text = args.text or args[0]
	end
	local interpolated_text = M.interpolate_string(text)

	if name then
		local before_dot, after_dot = separate_from_dot(name)
		if before_dot and after_dot then
			name = before_dot
			local expression = after_dot
			local sprite = save.get_var(name.."."..expression..".sprite")
			name = string.lower(name)
			if sprite then
				save.set_var("_temp_expression_name", name, "string")
				save.set_var("_temp_expression_sprite", expression, "string")
				change_sprite(name, sprite)
			elseif has_alternative_sprite(name, expression) then
				save.set_var("_temp_expression_name", name, "string")
				save.set_var("_temp_expression_sprite", expression, "string")
				change_sprite(name, expression)
			end
			expression_name = save.get_var(name.."."..expression..".name")
			if expression_name then
				name = expression_name
			end
		end
		if not expression_name then
			local expression = save.get_var(name..".expression")
			if expression then
				expression_name = save.get_var(name.."."..expression..".name")
				if expression_name then
					name = expression_name
				end
			end
		end
	end
	
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
		elseif before_dot == "textbox" or before_dot == "text" then
			M.post("textbox", "action_set", {name = name, value = value, value_string = value_string})
		elseif before_dot == "settings" then
			settings.set(after_dot, value)
			M.apply_setting(after_dot, value)
		elseif before_dot == "audio" or before_dot == "music" or before_dot == "sound" then
			M.post("sound", "action_set", {name = name, value = value, value_string = value_string})
		elseif before_dot == "system" then
			if after_dot == "window_title" then
				system.set_window_title(value)
			end
		elseif before_dot == "debug" then
			if after_dot == "console" then
				if defos then
					defos.set_console_visible(value == true)
				end
			end
		end
	end
	if after_dot then
		if after_dot == "sprite" then 
			M.post("sprites", "action_set_sprite", {name = before_dot, spr = value})
		elseif after_dot == "stencil_height" then
			M.post("sprites", "action_set_stencil_height", {name = before_dot, value = value})
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

local function multiply(args)
	local name = args.left or args.name or args[1]
	local value_string = args.right or args.value or args[2]
	local value, _ = matchascript.get_variable(value_string)
	local value_a, _ = matchascript.get_variable(name)
	local value_a_number = tonumber(value_a) or 0
	local value_b_number = tonumber(value) or 0
	local product = value_a_number * value_b_number
	save.set_var(name, product)
	matchascript.next()
end

local function divide(args)
	local name = args.left or args.name or args[1]
	local value_string = args.right or args.value or args[2]
	local value, _ = matchascript.get_variable(value_string)
	local value_a, _ = matchascript.get_variable(name)
	local value_a_number = tonumber(value_a) or 0
	local value_b_number = tonumber(value) or 1
	if value_b_number and value_b_number ~= 0 then
		local result = value_a_number / value_b_number
		save.set_var(name, result)
	end
	matchascript.next()
end

local function modulo(args)
	local name = args.left or args.name or args[1]
	local value_string = args.right or args.value or args[2]
	local value, _ = matchascript.get_variable(value_string)
	local value_a, _ = matchascript.get_variable(name)
	local value_a_number = tonumber(value_a) or 0
	local value_b_number = tonumber(value)
	if value_b_number then
		local result = value_a_number % value_b_number
		save.set_var(name, result)
	end
	matchascript.next()
end

local function concatenate(args)
	local name = args.left or args.name or args[1]
	local value_string = args.right or args.value or args[2]
	local value, _ = matchascript.get_variable(value_string)
	local value_a, _ = matchascript.get_variable(name)
	local value_a_string = tostring(value_a) or ""
	local value_b_string = tostring(value) or ""
	local result = value_a_string .. value_b_string
	save.set_var(name, result, "string")
	matchascript.next()
end





local function scene(args)
	local scene            = args.scene    or args[1]
	local duration         = args.duration or args.t  or save.get_var("scene.duration")
	local transition       = args.transition          or save.get_var("scene.transition")
	local color            = args.color               or save.get_var("scene.color")
	local transition_color = args.transition_color    or save.get_var("scene.transition_color")
	local stub             = args.stub                or save.get_var(scene..".stub")
	
	save.set_var("scene.current", scene, "string")
	save.set_var("scene.current_color", color, "string")

	local var_color = save.get_var(scene..".color")
	if not color and var_color then
		color = var_color
	end
	
	local message = {scene = scene, transition = transition, duration = duration, color = color, transition_color = transition_color, stub = stub}
	M.post("background", "scene", message)
	matchascript.next()
end

local function insert_z(name, above, below)
	local z
	if above == "back" or below == "back" then
		z = 1
	elseif above == "front" or below == "front" then
		z = #save.state.sprites + 1
	elseif above then
		local other_z = save.get_var(above..".z")
		if other_z then
			z = other_z + 1
		end
	elseif below then
		local other_z = save.get_var(below..".z")
		if other_z then
			z = other_z - 1
		end
	else
		z = #save.state.sprites + 1
	end
	for k, v in pairs(save.state.sprites) do
		local old_z = save.get_var(k..".z")
		if old_z and z and old_z >= z then
			save.set_var(k..".z", old_z + 1)
		end
	end
	if z then
		save.set_var(name..".z", z)
	end
end

local function show(args)
	local name       = args.name     or args[1] or save.get_var("show.name")
	local at         = args.at       or args[2] or save.get_var(name..".at")
	local duration   = args.duration or args.t  or save.get_var("show.duration")
	local transition = args.transition          or save.get_var("show.transition")
	local color      = args.color               or save.get_var("show.color")
	local above      = args.above               or save.get_var("show.above")
	local below      = args.below               or save.get_var("show.below")
	local easing     = args.easing              or save.get_var("show.easing")
	local delay      = args.delay               or save.get_var("show.delay")
	local wait       = args.wait
	if above then
		below = nil
	end
	local message = {
		name = name,
		at = at,
		duration = duration,
		transition = transition,
		color = color,
		above = above,
		below = below,
		easing = easing,
		delay = delay,
	}
	if color then
		save.set_var(name..".color", color)
	end
	insert_z(name, above, below)
	save.state.sprites[name] = true
	
	M.post("sprites", "show", message)
	if not wait then
		matchascript.next()
	end
end

local function hide(args)
	local name       = args.name     or args[1] or save.get_var("hide.name")
	local to         = args.to       or args[2] or save.get_var("hide.to")
	local duration   = args.duration or args.t  or save.get_var("hide.duration")
	local transition = args.transition          or save.get_var("hide.transition")
	local easing     = args.easing              or save.get_var("hide.easing")
	local delay      = args.delay               or save.get_var("hide.delay")
	local wait       = args.wait
	local message = {
		name = name,
		to = to,
		duration = duration,
		transition = transition,
		easing = easing,
		delay = delay,
	}
	M.post("sprites", "hide", message)
	if not wait then
		matchascript.next()
	end
end

local function move(args)
	local name     = args.name     or args[1] or save.get_var("move.name")
	local to       = args.to       or args[2] or save.get_var("move.to")
	local duration = args.duration or args.t  or save.get_var("move.duration")
	local color    = args.color               or save.get_var("move.color")
	local above    = args.above               or save.get_var("move.above")
	local below    = args.below               or save.get_var("move.below")
	local easing   = args.easing              or save.get_var("move.easing")
	local delay    = args.delay               or save.get_var("move.delay")
	local loop_1   = args.loop_1              or save.get_var("move.loop_1")
	local loop_2   = args.loop_2              or save.get_var("move.loop_2")
	local wait     = args.wait
	if above then
		below = nil
	end
	local message = {
		name = name,
		to = to,
		duration = duration,
		color = color,
		above = above,
		below = below,
		easing = easing,
		delay = delay,
		loop_1 = loop_1,
		loop_2 = loop_2,
	}
	if color then
		save.set_var(name..".color", color)
	end
	M.post("sprites", "move", message)
	if not wait then
		matchascript.next()
	end
end

local function flip(args)
	local name     = args.name     or args[1]
	local duration = args.duration or args.t  or save.get_var("flip.duration") or 1
	local message = {
		name = name,
		duration = duration,
	}
	M.post("sprites", "flip", message)
	matchascript.next()
end



local function choice(args)
	if matchascript.current_line_is_start_of_action_block() then 
		M.state = "choices"
		choices = matchascript.get_current_action_block()
		local text = {}
		for k, v in pairs(choices) do
			local arg = matchascript.get_argument(v)[0]
			text[k] = M.interpolate_string(arg) or arg
		end
		choice_receiver = save.get_var("choice.receiver") or "choices"
		M.post(choice_receiver, "show_text_choices", {text = text})
		M.post("textbox", "hide")
	else
		local line = matchascript.get_end_of_current_action_block()
		matchascript.set_line(line)
		matchascript.next()
	end
end

local function play(args)
	local file
	local group, var_type
	local source

	if args[2] then
		group = args[1]
		file = args[2]
		source = args.source
	else
		file = args[1]
		group, var_type = save.get_var("sound.group")
		if group == nil then
			group = "music"
		end
	end

	local volume = args.volume
	local pan = args.pan
	
	if group == "music" then 
		M.post("sound", "play_music", {id = file})
	elseif group == "sound" then 
		M.post("sound", "play_sfx", {id = file, source = source})
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

local function action_fmod(args)
	if args[1] == "play" then
		local event
		local audio_type
		if args[2] == "music" then
			audio_type = "music"
			event = args[3]
		elseif args[2] == "sound" then
			audio_type = "sound"
			event = args[3]
		else
			audio_type = "sound"
			event = args[2]
		end
		local fmod_bank = args.fmod_bank
		local source = args.source
		event = event or args.fmod_event
		_fmod.play(event, audio_type, fmod_bank, source)
	elseif args[1] == "stop" then
		local event
		local audio_type
		if args[2] == "music" then
			audio_type = "music"
			event = args[3]
		elseif args[2] == "sound" then
			audio_type = "sound"
			event = args[3]
		else
			audio_type = "sound"
			event = args[2]
		end
		event = event or args.fmod_event
		local fade = args.fade
		_fmod.stop(event, fade)
	else
		local event = args.fmod_event or args[1]
		local audio_type = args.audio_type
		local fmod_bank = args.fmod_bank
		local source = args.source
		_fmod.play(event, audio_type, fmod_bank, source)
	end
	matchascript.next()
end

local function wait()
	M.post("textbox", "wait", {for_click = false})
end 

local function title()
	M.post("textbox", "end_skip")
	M.post("menu", "title")
end 

local function action_print(args)
	local text = args[0] or ""
	local s = M.interpolate_string(text)
	print(s)
	matchascript.next()
end

local function label(args)
	matchascript.next()
end

local function none(args)
	--pprint(args)
end

local function empty(args)
	matchascript.next()
end

local else_false = false

local function action_if_true(v)
	if v then
		matchascript.next_step()
	else
		else_false = true
		matchascript.next()
		else_false = false
	end
end

local function action_if_false(v)
	action_if_true(not v)
end

local function action_if(args)
	action_if_true(execute_string(args[0]))
end

local function action_else(args)
	if else_false then
		else_false = false
		matchascript.next_step()
	else
		matchascript.next()
	end
end

local function action_elseif(args)
	if else_false then
		else_false = false
		action_if(args)
	else
		matchascript.next()
	end
end

local function action_system_maximize()
	system.maximize()
	matchascript.next()
end

local function action_system_minimize()
	system.minimize()
	matchascript.next()
end

-- manually ends an action block
local function action_end()
	matchascript.next()
end

local function skip_stop()
	M.post("textbox", "end_skip")
	matchascript.next()
end

local function open_url(args)
	local url = args[1] or args.url
	local target = args.target
	local name = args.name
	url = urls[url] or url
	if url then
		system.open_url(url, target, name)
	end
	matchascript.next()
end

local function check_for_statement_function(s)
	s = string.lower(s)
	local found_statement_function = false

	local before_dot, after_dot = string.match(s, "([%a_][%w_]*)%.([%a_][%w_]*)")

	if before_dot then
		local statement_sprite = save.get_var(s..".sprite")
		local statement_name = save.get_var(s..".name")
		local statement_color = save.get_var(s..".color")

		if after_dot == "default" then
			set_expression(before_dot, after_dot)
			found_statement_function = true
			local args = {name = before_dot, color = "white", wait = true}
			show(args)
			-- TODO: change no not show, but only change color (but then check at next show for name.expression.color)
		elseif after_dot == "flip" then
			flip_sprite(before_dot)
			found_statement_function = true
		end
		
		if statement_sprite then
			set_expression(before_dot, after_dot)
			change_sprite(before_dot, statement_sprite)
			found_statement_function = true
		elseif has_alternative_sprite(before_dot, after_dot) then
			set_expression(before_dot, after_dot)
			change_sprite(before_dot, after_dot)
			found_statement_function = true
		end
		
		if statement_name then
			set_expression(before_dot, after_dot)
			found_statement_function = true
		end
		if statement_color then
			local name = before_dot
			local args = {name = name, color = statement_color, wait = true}
			show(args)
			set_expression(name, after_dot)
			save.set_var(name..".color", statement_color)
			found_statement_function = true
		end
	end

	if _fmod and _fmod.check_for_statement(s) then
		found_statement_function = true
	end

	return found_statement_function
end

local function default(args)
	if check_for_statement_function(args[0]) then
		matchascript.next()
	else
		say(args)
	end
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
	"multiply",	
	"divide",
	"modulo",
	"concatenate",
	"if",
	"else",
	"elseif",
	"comment",
	"say",
	"show",
	"hide",
	"hideall",
	"move",
	"flip",
	"scene",
	"play",
	"stop",
	"choice",
	"call",
	"return",
	"title",
	"fmod",
	"wait",
	"end",
	"empty",
	"default",
	"skip.stop",
	"system.exit",
	"system.open_url",
	"system.maximize",
	"system.minimize",
	"debug.print",
}
script_definition.prefixes = {
	choice = ">",
	comment = "--",
	--label = "*",
	jump = "->",
}
script_definition.suffixes = {
	addone = "++",
	call = "()",
}
script_definition.operators = {
	say = ":",
	set = "=",
	add = "+=",
	subtract = "-=",
	multiply = "*=",
	divide = "/=",
	modulo = "%=",
	concatenate = "..=",
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
	flip = flip,
	choice = choice,
	call = call,
	add = add,
	addone = addone,
	subtract = subtract,
	multiply = multiply,
	divide = divide,
	modulo = modulo,
	concatenate = concatenate,
	label = label,
	title = title,
	fmod = action_fmod,
	wait = wait,
	comment = empty,
	none = none,
	default = default,
	["end"] = action_end,
	["return"] = action_return,
	["if"] = action_if,
	["else"] = action_else,
	["elseif"] = action_elseif,
	["skip.stop"] = skip_stop,
	["system.exit"] = action_exit,
	["system.open_url"] = open_url,
	["system.maximize"] = action_system_maximize,
	["system.minimize"] = action_system_minimize,
	["debug.print"] = action_print,
}
script_definition.extensions = {pronouns}


local render_order = {
	"background",
	"particles_back",
	--"transition_bg",
	"sprites",
	"particles_front",
	"textbox",
	"choices",
	"quickmenu",
	--"event",
	--"pause_menu",
	--"transition",
	--"title",
	--"config",
	"menu",
	--"border",
	"debug",
}
local input_order = {
	"sprites",
	"textbox",
	"choices",
	"quickmenu",
	"choices",
	--"title",
	"menu",
	"debug",
}

local function set_render_order()
	for k, v in pairs(render_order) do
		if k <= 15 and v then
			M.post(v, "set_render_order", {n = k})
		end
	end
end

local function set_input_order()
	for k, v in pairs(input_order) do
		M.post(v, "acquire_input_focus", {})
	end
end

local initialized = false



function M.add_file(path)
	matchascript.add_file(path)
end

function M.init()
	if initialized then return end
	--print("init")
	matchascript.load_scripts()
	--save.set_save_folder_name("Untitled MatchaNovel project")
	save.init()
	matchascript.set_definition(script_definition)
	set_render_order()
	set_input_order()
	settings.init()
	matchascript.init()
	M.post("menu", "init")
	if fmod then
		_fmod.init()
	end
	initialized = true
end

function M.load(filename)
	if M.state == "uninitialized" then 
		M.init()
		M.state = "initialized"
	end
end

function M.unload()
	M.post("sprites", "unload")
	M.post("background", "unload")
	M.post("particles_back", "unload")
	M.post("textbox", "unload")
	M.post("choices", "unload")
	M.post("quickmenu", "unload")
end

function M.start(label)
	M.unload()
	M.post("textbox", "start")
	M.post("sound", "start")
	matchascript.start(label)
end

function M.textbox_done()
	if M.state == "say" then
		-- if using temporary expression, return to previous expression
		local temp_expression_name = save.get_var("_temp_expression_name")
		if temp_expression_name then
			local previous_expression = save.get_var(temp_expression_name..".sprite")
			if previous_expression then
				change_sprite(temp_expression_name, previous_expression)
			end
			save.set_var("_temp_expression_name", nil, "nil")
			save.set_var("_temp_expression_sprite", nil, "nil")
		end
		
		matchascript.next()
	end
end

function M.wait_done()
	matchascript.next()
end

function M.choose(choice)
	matchascript.jump_to_line(choices[choice] + 1)
end

function M.set_font(font)
	M.post("textbox", "set_font", {font = font})
	M.post("choices", "set_font", {font = font})
end

function M.apply_setting(setting, value)
	if setting == "text_speed" then 
		M.post("textbox", "set_textspeed", {value = value/100})
	elseif setting == "auto_speed" then 
		M.post("textbox", "set_autospeed", {value = value/100})
	elseif setting == "font" then 
		M.post("menu", "set_font", {font = value})
	elseif setting == "fullscreen" then 
		M.post("menu", "set_fullscreen", {fullscreen = value})
	elseif setting == "lock" then 
		M.post("quickmenu", "set_lock", {lock = value})
	elseif setting == "volume_music" then 
		M.post("sound", "set_volume_bgm", {volume = value/100})
	elseif setting == "volume_sound" then 
		M.post("sound", "set_volume_sfx", {volume = value/100})
	elseif setting == "skip_all" then 
		-- nothing else needs to be done
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

function M.back_to_title()
	M.post("sound", "stop_music")
	-- play title music
end

function M.continue()
end


function M.autostart()
	return matchascript.label_exists("autostart")
end




return M
