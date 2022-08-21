local M = {}

local sys_info = sys.get_sys_info()
local engine_info = sys.get_engine_info()

M.name = sys_info.system_name
M.is_windows = M.name == "Windows"
M.is_linux = M.name == "Linux"
M.is_macos = M.name == "Darwin"
M.is_android = M.name == "Android"
M.is_ios = M.name == "iPhone OS"
M.is_html = M.name == "HTML5"
M.is_switch = M.name == "Switch"
M.is_mobile = M.is_android or M.is_ios

M.language = sys_info.language
M.is_debug  = engine_info.is_debug
M.engine_version  = engine_info.version


local function get_time()
	return os.date("%Y"), os.date("%m"), os.date("%d"), os.date("%T")
end

function M.get(name)
	if name == "get" then return end
	for k, v in pairs(M) do
		if name == k then 
			return v
		end
	end
	if name == "time" then 
		return os.time()
	elseif name == "time_string" then 
		return os.date("%Y-%m-%d %T")
	elseif name == "time_date" then 
		return os.date("%Y-%m-%d")
	elseif name == "time_year" then 
		return os.date("%Y")
	elseif name == "time_month" then 
		return os.date("%m")
	elseif name == "time_day" then 
		return os.date("%d")
	elseif name == "time_clock" then 
		return os.date("%T")
	elseif name == "time_hour" then 
		return os.date("%H")
	elseif name == "time_minute" then 
		return os.date("%M")
	elseif name == "time_second" then 
		return os.date("%S")
	elseif name == "time_weekday" then 
		return os.date("%w")
	elseif name == "os_clock" then 
		return os.clock()
	elseif name == "is_fullscreen" then 
		return defos.is_fullscreen()
	--elseif name == "mouse_x" then 
	--elseif name == "mouse_y" then
	end
end

function M.exit()
	sys.exit(0)
end

return M