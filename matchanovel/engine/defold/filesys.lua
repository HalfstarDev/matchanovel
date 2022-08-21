local M = {}

local load_resource = sys.load_resource
local get_save_file = sys.get_save_file
local load_file = sys.load
local save_file = sys.save
local open_url = sys.open_url

function M.load_file(filename)
	return load_file(filename)
end

function M.save_file(filename, table)
	return save_file(filename, table)
end

function M.load_script(filename)
	local loaded = {}
	local external = file_exists("."..filename)
	if external then
		for line in io.lines("."..filename) do table.insert(loaded, line) end
	else
		local internal = load_resource(filename)
		if internal then 
			local crlf = "\n"
			for line in (internal..crlf):gmatch("(.-)"..crlf) do
				table.insert(loaded, string.sub(line, 0, -1))
			end
		end
	end
	return loaded
end

function M.get_save_file(application_id, file_name)
	return get_save_file(application_id, file_name)
end

function M.open_folder(application_id)
	open_url(get_save_file(application_id, ""))
end

return M