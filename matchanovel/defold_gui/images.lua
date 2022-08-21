
local M = {}

local reader = false

local function load_data_from_engine_resource(filepath)
	local data = sys.load_resource(filepath)
	if data then
		return data
	else
		print("Error: load_file_from_engine_resource")
	end
end

local function load_data_from_file(filepath)
	local file, error = io.open("."..filepath, "rb")
	if file then
		local data = file:read("*a")
		file:close()
		return data
	else
		print("Error (io.open):", error)
	end
end

local function load_data(filepath)
	if reader then 
		return load_data_from_file(filepath)
	else
		return load_data_from_engine_resource(filepath)
	end
end

local function create_gui_texture(textures_table, filepath)
	local data = load_data(filepath)
	if data then
		local img = image.load(data, true)
		local ok, reason = gui.new_texture(filepath, img.width, img.height, img.type, img.buffer)
		if ok then
			textures_table[filepath] = true
		else
			print("Error (gui.new_texture):", reason)
		end
		return ok
	else
		print("Error (io.open):", error)
	end
end

local function load_gui_texture(textures_table, filepath)
	if textures_table[filepath] then
		return true
	else
		return create_gui_texture(textures_table, filepath)
	end
end

function M.set_gui_sprite(textures_table, node, filepath)
	if load_gui_texture(textures_table, filepath) then
		gui.set_texture(node, filepath)
	end
end








return M