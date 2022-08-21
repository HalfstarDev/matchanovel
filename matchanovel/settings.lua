local files = require "matchanovel.engine.defold.filesys"

local M = {}

local app_id = "Untitled MatchaNovel project"
local file = "settings.ini"
local filename = files.get_save_file(app_id, file)

local settings_update = false
local checking_updates = true
local LB = "\r\n"

local setting_name = {}
local setting_value = {}

local settings_default = {}



local function write_settings()
	local file, error = io.open(filename, "wb")
	if file then
		file:write("[Settings]")
		for k, name in pairs(setting_name) do
			local val = setting_value[name]
			local text = LB..name.."="..tostring(val)
			file:write(text)
		end
		file:flush()
		file:close() 
		return true
	else
		print(error)
		return false
	end
end

local function string_to_value(s)
	local number = tonumber(s)
	if number then 
		return number
	elseif s == "true" then
		return true
	elseif s == "false" then
		return false
	else
		return s
	end
end

local function read_settings()
	for line in io.lines(filename) do 
		if string.sub(line, 1, 1) == "[" then 
		else
			local name, val = string.match(line, "([%w_]+)=(%w+)")
			val = string_to_value(val)
			setting_value[name] = val
		end
	end
end

local function file_exists(name)
	local file = io.open(name, "rb")
	if file then 
		io.close(file)
		return true
	else
		return false
	end
end




function M.set(name, value)
	if not setting_value[name] or setting_value[name] ~= value then
		setting_value[name] = value
		if checking_updates then
			settings_update = true
		else
			write_settings()
		end 
	end
end

function M.get(name)
	return setting_value[name]
end

function M.set_default(name, value)
	settings_default[name] = value
	M.set(name, value)
	setting_name[#setting_name + 1] = name
end

function M.check_updates()
	checking_updates = true
	if settings_update then
		if write_settings() then
			settings_update = false
		end
	end
end

function M.init()
	if file_exists(filename) then 
		read_settings()
	else
		write_settings()
	end

	if setting_value["volume_bgm"] then
		--msg.post("/sound#sound", "set_volume_bgm", {volume = setting_value["volume_bgm"] / 100})
	end
	if setting_value["fullscreen"] then
		if defos then 
			defos.set_fullscreen(true)
		end
	end
end

function M.calc_text_speed(value)
	if value > 0.99 then 
		return 10000
	elseif value > 0.5 then 
		return math.floor(value*140*2) - 70
	else
		return math.floor(value*60*2) + 10
	end
end

function M.calc_inverse_text_speed(value)
	if value > 210 then 
		return 1
	elseif value > 70 then 
		return (value + 70)/280
	else
		return (value - 10)/120
	end
end

function M.calc(id, value)
	if id == "speed_text" then 
		return M.calc_text_speed(value)
	else
		return math.floor(value*100)
	end
end

function M.calc_inverse(id, value)
	if id == "speed_text" then 
		return M.calc_inverse_text_speed(value)
	else
		return value/100
	end
end

function M.get_bar_value(id)
	local value = M.get(id)
	return M.calc_inverse(id, value)
end

function M.open_folder()
	files.open_folder(app_id)
end

M.set_default("text_speed", 50)
M.set_default("auto_speed", 50)
M.set_default("volume_music", 50)
M.set_default("volume_sound", 50)
M.set_default("font", "serif")
M.set_default("fullscreen", true)
M.set_default("skip_all", false)
M.set_default("lock", true)

return M