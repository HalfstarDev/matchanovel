
local M = {}

local reader = false

local function create_gui_texture_reader(textures_table, filepath)
	print(filepath)
	local file, error = io.open(filepath, "rb")
	if file then
		local data = file:read("*a")
		file:close()

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

local function create_gui_texture(textures_table, filepath)
	local data = sys.load_resource(filepath)
	if data then
		local img = image.load(data, true)
		local ok, reason = gui.new_texture(filepath, img.width, img.height, img.type, img.buffer)
		if ok then
			textures_table[filepath] = true
		else
			print("Error (gui.new_texture):", reason)
		end
		return ok
	end
end

local function load_gui_texture(textures_table, filepath)
	if textures_table[filepath] then
		return true
	else
		if reader then 
			return create_gui_texture_reader(textures_table, "."..filepath)
		else
			return create_gui_texture(textures_table, filepath)
		end 
	end
end

function M.set_gui_sprite(textures_table, node, filepath)
	if load_gui_texture(textures_table, filepath) then
		if reader then 
			filepath = "."..filepath
		end
		gui.set_texture(node, filepath)
	end
end






function M.set_sprite_from_file(self, filepath, sprite)
	--[[
	local data = sys.load_resource(filepath)
	local image_resource = imageloader.load{
		data = data
	}
	resource.set_texture(go.get(sprite, 'texture0'), image_resource.header, image_resource.buffer)
	--]]
end




return M