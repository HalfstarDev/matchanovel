local save = require "matchanovel.save"
local M = {}

-- table of all lines of script
local script = {}
-- table of actions of all lines of script
local actions = {}
-- table of argument strings of all lines of script
local arguments = {}
-- table of position of all labels
local labels = {}


local define = true

--local definition = require "matchanovel.matchascript_novel"
local definition

function file_exists(name)
	local f = io.open(name, "r")
	return f ~= nil and io.close(f)
end

-- returns table with lines of file "filename"
local function load_file(filename)
	local external = file_exists("."..filename)
	if external then
		for line in io.lines("."..filename) do table.insert(script, line) end
	else
		local internal = sys.load_resource(filename)
		if internal then 
			local crlf = "\n"
			for line in (internal..crlf):gmatch("(.-)"..crlf) do
				table.insert(script, string.sub(line, 0, -1))
			end
		end
	end
end

-- removes spaces from start and end of string
local function remove_spaces(s)
	return string.match(s, "%s*(.*%S)%s*") or ""
end

-- replaces tabs with spaces
local function remove_tabs(s)
	return string.gsub(s, "	", " ")
end

local function hex_to_dec(hex)
	return tonumber("0x"..hex)
end

local function hex_to_rgb(hex)
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

local function read_variable(value)
	if not value then 
		return nil, "nil"
	end

	if #value == 0 then 
		return "", "string"
	end

	value = remove_spaces(value)
	if value == "true" then
		return true, "bool"
	elseif value == "false" then
		return false, "bool"
	elseif value == "nil" then
		return nil, "nil"
	end

	local str = string.match(value, "^[^\"]*\"([^\"]*)\"")
	if not str then 
		str = string.match(value, "^[^\']*\'([^\']*)\"")
	end
	if str then
		return str, "string"
	end

	local number = tonumber(value)
	local r, g, b = hex_to_rgb(value)
	if r then
		return vmath.vector3(r, g, b), "color"
	elseif number then
		return number, "number"
	else
		return value, "pointer"
	end
end





function M.get_var_from_savestate(var)
	local v, t = save.get_var(var)
	return v, t
end

function M.get_variable(v)
	local value, type = read_variable(v)
	if type == "pointer" then
		local v, t = M.get_var_from_savestate(value)
		return v, t
	else
		return value, type
	end
end

-- returns table of words from string
-- words are substrings seprated by spaces, if they aren't in quotation marks
local function get_words(line)
	if not line or line == "" then 
		return {} 
	end
	local word_table = {}

	while #line > 0 do
		line = remove_spaces(line)
		local quote = string.find(line, "\"")
		local space = string.find(line, " ")
		if space and (not quote or space < quote) then
			local word = string.sub(line, 1, space - 1)
			table.insert(word_table, word)
			line = string.sub(line, space + 1)
		elseif quote then
			if quote == 1 then 
				local quote2 = string.find(line, "\"", 2)
				if quote2 then 
					local word = string.sub(line, 2, quote2 - 1) or ""
					table.insert(word_table, word)
					line = string.sub(line, quote2 + 1)
				else
					table.insert(word_table, line)
					line = ""
					break
				end
			else
				local word = string.sub(line, 1, quote - 1)
				table.insert(word_table, word)
				line = string.sub(line, quote + 1)
			end
		else
			table.insert(word_table, line)
			line = ""
			break
		end
	end
	if #word_table == 0 then
		word_table[1] = ""
	end
	return word_table
end

-- returns indention of line (number of spaces or tabs on start of line)
local function get_indention(line)
	local indention = string.match(line or "", "^[%s	]*") or ""
	return #indention
end

-- returns table of arguments from string
local function separate_arguments(argument_string)
	local arguments_table = {}

	if not argument_string or #argument_string == 0 then return arguments_table end
	
	-- set arguments from assignments ("x=y")
	local pattern = "(.*)%s(%S+)%s*%=%s*(%S+)(.*)"
	local rest_left, argument, value, rest_right = string.match(argument_string, pattern)
	while argument and value do
		arguments_table[argument] = value
		argument_string = rest_left..rest_right
		rest_left, argument, value, rest_right = string.match(argument_string, pattern)
	end

	--[[
	-- set arguments from flags ("-x")
	pattern = "(.*)%s+%-([%a%_]%S*)(.*)"
	local rest_left, flag, rest_right = string.match(argument_string, pattern)
	while flag do
		arguments_table[flag] = true
		argument_string = rest_left..rest_right
		rest_left, flag, rest_right = string.match(argument_string, pattern)
	end
	--]]

	-- set other arguments ("x")
	local words = get_words(argument_string)
	for i, v in pairs(words) do
		arguments_table[i] = v
	end

	return arguments_table
end

-- returns next line with same or smaller indention than current line
local function get_next_line(line)
	line = line or save.state.pos
	local current_indention = get_indention(script[line])
	local next_line = line + 1
	local indention = get_indention(script[next_line])
	while not indention or indention > current_indention do 
		next_line = next_line + 1
		if next_line > #script then return false end
		indention = get_indention(script[next_line])
	end
	return next_line
end

-- returns previous line with same or smaller indention than current line
local function get_previous_line(line)
	line = line or save.state.pos
	local current_indention = get_indention(script[line])
	local previous_line = line - 1
	local indention = get_indention(script[previous_line])
	while not indention or indention > current_indention do 
		previous_line = previous_line - 1
		if previous_line < 1 then return false end
		indention = get_indention(script[previous_line])
	end
	return previous_line
end

-- returns table of lines of all actions in block starting from given line.
-- lines are in same block if they are of same action, same indention, 
-- and are next of each other (disregaring empty lines)
local function get_action_block(starting_line)
	local current_action = actions[starting_line]
	local line = starting_line
	local action = current_action
	local action_block = {}
	while (action == "empty" or action == current_action) and line and line <= #script do
		if action == current_action then
			table.insert(action_block, line)
		end
		line = get_next_line(line)
		action = actions[line]
	end
	return action_block
end

-- returns boolean that is true if given line is the first in the action block that line is part of
local function is_start_of_action_block(starting_line)
	local current_action = actions[starting_line]
	local line = get_previous_line(starting_line)
	local action = actions[line]
	return action ~= current_action
end

-- returns last line in action block of given line
local function get_end_of_action_block(starting_line)
	local action_block = get_action_block(starting_line)
	local end_line = 1
	for k, v in pairs(action_block) do
		end_line = math.max(v, end_line)
	end
	return end_line
end

local function get_value(s)
	local str = string.match(s, "^[^\"]*\"([^\"]*)\"")
	if str then return str end

	local num = tonumber(s)
	if num then return num end
end

local function set_define(name, value_string)
	local value, type = read_variable(value_string)
	save.define(name, value, type)
end

local function execute_function(action, args)
	local f = definition.functions[action]
	if f then
		f(args)
	end
end




-- set table of definitons for the script file
function M.set_definition(definition_table)
	definition = definition_table
end

function M.add_file(filename)
	load_file(filename)
end

-- create tables of actions from script file
function M.init()
	for k, line in pairs(script) do
		arguments[k] = {}
		local action

		line = remove_tabs(line)
		line = remove_spaces(line)

		if line == "" then 
			action = "empty"
			arguments[k][0] = ""
		end

		-- check keyword command ("keyword arguments")
		if not action then
			local keyword = string.match(line, "%S*")
			for _, action_name in pairs(definition.actions) do
				if keyword == action_name then
					action = action_name
					arguments[k][0] = string.match(line, "%S*%s*(.*)") or ""
				end
			end
		end

		-- check prefix command ("PREFIXarguments")
		if not action then
			for action_name, prefix in pairs(definition.prefixes) do
				local p = string.sub(line, 1, #prefix)
				if p == prefix then 
					action = action_name
					arguments[k][0] = remove_spaces(string.sub(line, #prefix + 1) or "") or ""
				end
			end
		end

		-- check suffix command ("argumentsSUFFIX")
		if not action then
			for action_name, suffix in pairs(definition.suffixes) do
				local s = string.sub(line, -#suffix)
				if s == suffix then 
					action = action_name
					arguments[k][0] = remove_spaces(string.sub(line, 1, -#suffix - 1) or "") or ""
				end
			end
		end

		-- check for operator command ("argument[1]OPERATORargument[2]")
		--[[
		This will prioritize the operator the furthest to the left
		and if two start at the same position, the longer one will be prioritized, so for
			alice: The function is y = a * b + c
		it will match ":", and not "="
		so you can put any operator to the right of the first in the line without worrying about conflicts
		--]] 
		
		if not action then
			local max_operator_length = 1
			for _, operator in pairs(definition.operators) do
				max_operator_length = math.max(max_operator_length, #operator)
			end
			local operator_length = 0
			for length = max_operator_length, 1, -1 do
				for action_name, operator in pairs(definition.operators) do
					if #operator == length then
						local op = string.gsub(operator, ".", "%%%0")
						arg_left, arg_right = string.match(line, "^%s*(.-)%s*"..op.."%s*(.*)")
						local is_furthes_to_left = arg_left and ((not arguments[k].left) or #arg_left < #arguments[k].left)
						local is_equally_far_to_left = arg_left and arguments[k].left and #arg_left == #arguments[k].left
						local is_longer = #operator > operator_length
						if is_furthes_to_left or (is_equally_far_to_left and is_longer) then
							action = action_name
							arguments[k].left = arg_left
							arguments[k].right = arg_right
							arguments[k][0] = line
							operator_length = #operator
						end
					end
				end
				--if matched then break end
			end
		end

		if not action then
			action = "default"
			arguments[k][0] = line
		elseif action == "label" then
			labels[arguments[k][0]] = k
			action = "label"
			define = false
		end
		
		-- set action
		actions[k] = action or "none"
		
		-- set arguments 
		if arguments[k][0] then
			local argument_table = separate_arguments(arguments[k][0])
			for i, v in pairs(argument_table) do
				arguments[k][i] = v
			end
		end

		if define then 
			execute_function(actions[k], arguments[k])
		end
	end
end

-- execute the action on the current line
function M.execute()
	local action = actions[save.state.pos]
	local args = arguments[save.state.pos]
	
	for _, extension in pairs(definition.extensions) do
		if extension.before_action then
			extension.before_action(action, args)
		end
	end
	
	if action == "none" or action == "empty" then
		M.next()
	else
		execute_function(action, args)
	end
end

-- set the current line of script
function M.set_line(line)
	save.state.pos = line
end

-- jump to given line and execute it
function M.jump_to_line(line)
	M.set_line(line)
	M.execute()
end

-- jump to line of given label and execute it
function M.jump_to_label(label)
	local line = labels[label]
	if line then
		M.jump_to_line(line)
	end
end

-- go to the next line with same or smaller indention and execute it
function M.next()
	if not define then
		local next_line = get_next_line()
		M.jump_to_line(next_line)
	end
end

-- go to the next line (regardless of indention) and execute it
function M.next_step()
	local next_line = save.state.pos + 1
	M.jump_to_line(next_line)
end

-- returns table of lines of all actions in block starting from current line
function M.get_current_action_block(starting_line)
	return get_action_block(save.state.pos)
end

-- returns argument of given line
function M.get_argument(line)
	return arguments[line]
end

-- returns boolean that is true if current line is the first in the action block that line is part of
function M.current_line_is_start_of_action_block()
	return is_start_of_action_block(save.state.pos)
end

-- returns last line in action block of current line
function M.get_end_of_current_action_block()
	return get_end_of_action_block(save.state.pos)
end

-- replaces all instances of {x} with value of x
function M.interpolate_string(s)
	local left = "{"
	local right = "}"
	local name = string.match(s, left.."([^{]+)"..right)
	while name do
		local value = M.get_var_from_savestate(name) or ""
		s = string.gsub(s, left..name..right, value)
		name = string.match(s, left.."([^{]+)"..right)
	end
	return s
end


-- jump to line of given by label "start" and execute it 
function M.start()
	M.jump_to_label("start")
end

local function add_line_to_script(line)
	table.insert(script, line)
end


return M