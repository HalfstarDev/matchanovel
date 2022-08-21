-- LÖVE engine is currently not officially supported. This is an example on how to integrage MatchaNovel with another Lua engine

local M = {}

local saved_file = {}

function M.load_script(file)
	local t = {}
	for line in love.filesystem.lines(file) do
		table.insert(t, line)
	end
	return t
end

-- TODO: load table from file with love.filesystem
function M.load_file(filename)
	return saved_file
end

-- TODO: write table to file with love.filesystem
function M.save_file(filename, table)
	saved_file = table
	return true
end

function M.get_save_file(application_id, file_name)
	return "save/"..file_name
end

function M.open_folder(application_id)
	print("open folder")
end


return M