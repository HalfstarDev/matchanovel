local M = {}

local load_resource = sys.load_resource
local get_save_file = sys.get_save_file
local load_file = sys.load
local save_file = sys.save
local open_url = sys.open_url

-- path separator character for current OS
local SEP = package.config:sub(1,1)

local function get_path(path)
	return string.gsub(path, "[/\\]", SEP)
end

function M.load_file(filename)
	filename = get_path(filename)
	return load_file(filename)
end

function M.save_file(filename, table)
	filename = get_path(filename)
	return save_file(filename, table)
end

function M.write_binary(filename, data)
	filename = get_path(filename)
	local file = io.open(filename, "wb")
	file:write(data)
	file:flush()
	file:close()
end

function M.read_binary(filename)
	filename = get_path(filename)
	local file = io.open(filename, "rb")
	if file then
		local s = file:read("*a")
		file:close()
		return s
	end
end

function M.does_file_exist(filename)
	filename = get_path(filename)
	if sys.exists then
		return sys.exists(filename)
	else
		local file = io.open(filename, "r")
		if file then
			file:close()
			return true
		end
	end
end

function M.load_script(filename)
	filename = get_path(filename)
	local loaded = {}
	local external = file_exists("."..filename)
	if external then
		for line in io.lines("."..filename) do
			line = string.gsub(line, "\r", "")
			line = string.gsub(line, "\n", "")
			table.insert(loaded, line)
		end
	else
		filename = string.gsub(filename, "\\", "/")
		local internal, error = load_resource(filename)
		if error then
			print("load_script error:", error)
		elseif internal then 
			local crlf = "\n"
			for line in (internal..crlf):gmatch("(.-)"..crlf) do
				line = string.gsub(line, "\r", "")
				line = string.gsub(line, "\n", "")
				table.insert(loaded, string.sub(line, 0, -1))
			end
		end
	end
	return loaded
end

function M.get_save_file(application_id, filename)
	filename = get_path(filename)
	return get_save_file(application_id, filename)
end

function M.open_folder(application_id)
	open_url(get_save_file(application_id, ""))
end

return M