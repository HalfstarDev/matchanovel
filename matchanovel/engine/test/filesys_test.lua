-- use this to test integration with your engine, so you can swap the system functions step by step with these stubs

local M = {}

local saved_file = {}

function M.load_script()
	local t = {
		"label start",
		"To open a script, change filesys_test.lua to a module that supports your engine.",
	}
	return t
end

function M.load_file(filename)
	return saved_file
end

function M.save_file(filename, table)
	saved_file = table
	return true
end

function M.get_save_file(application_id, file_name)
	return file_name
end

function M.open_folder(application_id)
	print("open folder")
end


return M