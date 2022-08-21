local files = require "matchanovel.engine.defold.filesys"

local M = {}

local app_id = "Untitled MatchaNovel project"
local path_settings = files.get_save_file(app_id, "settings.dat")
local path_global = files.get_save_file(app_id, "global.dat")

local saves_limit = 999
local quicksaves_limit = 1
local autosaves_limit = 1
local miniflags_write_limit = 10

local used = {}
local used_quick = 0
local next_quicksave = 1
local checked_save_number = 0
local checked_save_max = 0
local loaded_table = {}
local defined_variables = {}
local defined_variables_type = {}
local flag_write_global = false
local miniflags_write_global = 0
--local max_save = 4

M.state = {}
M.state.pos = 0
M.state.log = {}
M.state.log_names = {}
M.state.var = {}
M.state.var_type = {}
M.state.call_stack = {}
M.state.sprites = {}
--M.state.sprites.current = {}

M.global = {}
M.global.read_lines = {}
M.global.var = {}
M.global.max_written_save_slot = 1


local function get_digits(number)
	return #(number.."")
end

local function get_number_string(number, max)
	local n = get_digits(number)
	local m = get_digits(max)
	if n > m then return "error" end
	local number_string = ""..number
	for i = 1, m - n do
		number_string = "0"..number_string
	end
	return number_string
end

local function create_strings(y, m, d, t)
	if y then
		return y.."-"..m.."-"..d.."\n"..t
		--return y.."-"..m.."-"..d, t
	else
		return false, false
	end
end

local function get_time()
	return os.date("%Y"), os.date("%m"), os.date("%d"), os.date("%T")
end

local function get_path(slot, quick, auto)
	if quick then 
		local n = get_number_string(slot, quicksaves_limit)
		return files.get_save_file(app_id, "quicksave_"..n..".dat")
	elseif auto then 
		local n = get_number_string(slot, autosaves_limit)
		return files.get_save_file(app_id, "autosave_"..n..".dat")
	else
		local n = get_number_string(slot, saves_limit)
		return files.get_save_file(app_id, "save_"..n..".dat")
	end
end

local function quicksave_number_to_slot(number)
	return (quicksaves_limit - number + next_quicksave - 1) % quicksaves_limit + 1
end

local function read_slot(slot, quick, auto)
	if quick then
		slot = quicksave_number_to_slot(slot)
	end
	local p = get_path(slot, quick, auto)
	return files.load_file(p)
end





function M.check_quicksave_number()
	for i = 1, quicksaves_limit do
		local loaded = read_slot(i, true, false)
		if next(loaded) then
			used_quick = i
			next_quicksave = i % quicksaves_limit + 1
		else
			return
		end
	end
end

function M.check_save_number(n)
	local found_empty = false
	for i = checked_save_number + 1, checked_save_number + n do
		local loaded = read_slot(i, false, false)
		if next(loaded) then
			checked_save_max = i
			used[i] = true
		else
			found_empty = true
		end
	end
	checked_save_number = checked_save_number + n
	if not found_empty then
		return M.check_save_number(n)
	end
	return checked_save_number > saves_limit
end

function M.get_text(slot, quick, auto)
	if quick then
		slot = quicksave_number_to_slot(slot)
	end
	local loaded = read_slot(slot, quick, auto)
	return create_strings(loaded.y, loaded.m, loaded.d, loaded.t)
end

function M.get_current_text()
	local y, m, d, t = get_time()
	return create_strings(y, m, d, t)
end

function M.write(slot, quick, auto)
	local filename = get_path(slot, quick, auto)
	local y, m, d, t = get_time()
	M.state.y = y
	M.state.m = m
	M.state.d = d
	M.state.t = t
	files.save_file(filename, M.state)
	if not quick and not auto then
		used[slot] = true
	end
	checked_save_max = math.max(slot, checked_save_max)
	--max_save = math.max(slot, max_save)
	M.set_global_sys_var("max_save", math.max(slot, M.global.max_save or 1))
	return create_strings(y, m, d, t)
end

function M.write_save(slot, quick, auto)
	return M.write(slot, quick, auto)
end

function M.write_quicksave()
	local writing = M.write(next_quicksave, true, false)
	next_quicksave = next_quicksave % quicksaves_limit + 1
	if used_quick < quicksaves_limit then 
		used_quick = used_quick + 1
	end
	return writing
end

local function is_table(a)
	return not not next(a)
end

function M.load(slot)
	loaded_table = files.load_file(get_path(slot, false, false))
	local loaded = is_table(loaded_table)
	if loaded then
		M.state.pos = loaded_table.pos
		M.state.log = loaded_table.log
		M.state.var = loaded_table.var
		M.state.var_type = loaded_table.var_type
		M.state.call_stack = loaded_table.call_stack
		M.state.sprites = loaded_table.sprites
	end
	return loaded
end

function M.reset()
	M.state.pos = 0
	M.state.log = {}
	M.state.var = {}
	M.state.var_type = {}
	M.state.call_stack = {}
	M.state.sprites = {}
end

function M.quickload(number)
	local slot = quicksave_number_to_slot(number)
	loaded_table = files.load_file(get_path(slot, true, false))
	local loaded = is_table(loaded_table)
	if loaded then
		M.state.pos = loaded_table.pos
		M.state.log = loaded_table.log
		M.state.var = loaded_table.var
		M.state.var_type = loaded_table.var_type
		M.state.call_stack = loaded_table.call_stack
		M.state.sprites = loaded_table.sprites
	end
	return loaded
end

function M.get_loaded_table()
	return loaded_table
end

function M.get_save_max()
	return checked_save_max
end

function M.get_quicksave_max()
	return used_quick
end

function M.get_save_limit()
	return saves_limit
end

function M.get_quicksaves_limit()
	return quicksaves_limit
end

function M.is_used(slot)
	return used[slot]
end

function M.is_used_quick(slot)
	return slot <= used_quick
end

function M.open_folder()
	files.open_folder(app_id)
end

function M.set_var(name, value, type)
	M.state.var[name] = value
	M.state.var_type[name] = type
end

function M.define(name, value, type)
	defined_variables[name] = value
	defined_variables_type[name] = type
end

function M.get_var(name)
	local value = M.state.var[name] or defined_variables[name]
	local type = M.state.var_type[name] or defined_variables_type[name]
	if type == "pointer" then 
		local v, t = M.get_var(value)
		if v then
			return v, t
		else
			return value, "string"
		end
	else
		return value, type
	end
	
end

function M.get_type(name)
	return M.state.var_type[name] or defined_variables_type[name]
end

local function load_global()
	local loaded_table = files.load_file(path_global)
	if loaded_table then
		M.global = loaded_table or {}
	end
end

local function write_global()
	flag_write_global = false
	files.save_file(path_global, M.global)
end

function M.set_global_sys_var(name, value)
	if M.global[name] ~= value then
		M.global[name] = value
		flag_write_global = true
	end
end

function M.set_global_read(line)
	line = line or M.state.pos
	if not M.global.read_lines then 
		M.global.read_lines = {}
	end
	if line and not M.global.read_lines[line] then
		M.global.read_lines[line] = true
		flag_write_global = true
	end
end

function M.get_global_read(line)
	line = line or M.state.pos
	if line and M.global.read_lines then
		return M.global.read_lines[line]
	end
end

function M.add_to_log(text, name)
	if text then 
		table.insert(M.state.log, text)
		table.insert(M.state.log_names, name or "")
	end
end

function M.get_log(line)
	return M.state.log[line], M.state.log_names[line]
end

function M.get_log_size()
	return #M.state.log
end

function M.reset_log()
	M.state.log = {} 
	M.state.log_names = {} 
end

function M.push_call_stack(pos)
	pos = pos or M.state.pos
	table.insert(M.state.call_stack, pos)
end

function M.pop_call_stack()
	local n = #M.state.call_stack
	if n > 0 then 
		local pop = M.state.call_stack[n]
		table.remove(M.state.call_stack, n)
		return pop
	else
		return false
	end 
end

function M.set_save_folder_name(name)
	app_id = name
end

function M.update(dt)
	if flag_write_global then
		write_global()
	end
end

function M.init()
	load_global()
	M.check_save_number(M.global.max_save or 4)
end



return M