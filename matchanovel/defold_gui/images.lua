local save = require "matchanovel.save"
local files = require "matchanovel.engine.defold.filesys"

local M = {}

local reader = false

local function load_data_from_engine_resource(filepath)
	local data = sys.load_resource(filepath)
	if data then
		return data
	else
		--print("Error: load_file_from_engine_resource")
		return false
	end
end

local function load_data_from_file(filepath)
	local file, error = io.open("."..filepath, "rb")
	if file then
		local data = file:read("*a")
		file:close()
		return data
	else
		--print("Error (io.open):", error)
		return false
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
			return ok
		else
			--print("Error (gui.new_texture):", reason)
			return false
		end
	else
		--print("Error (io.open):", error)
		return false
	end
end

function M.exists(filepath)
	return load_data(filepath)
end

function M.load_gui_texture(textures_table, filepath)
	if textures_table[filepath] then
		return true
	else
		return create_gui_texture(textures_table, filepath)
	end
end

function M.set_gui_sprite(textures_table, node, filepath)
	local loaded = M.load_gui_texture(textures_table, filepath)
	if loaded then
		gui.set_texture(node, filepath)
		return true
	else
		return false
	end
end

function M.save_screenshot()
	if screenshot then
		screenshot.png(function(self, image, w, h)
			local file = io.open("screenshot.png", "wb")
			file:write(image)
			file:flush()
			file:close()
		end)
	end
end

local screenshots = {}

local function set_node_to_png_buffer(node, buffer, id)
	local img = image.load(buffer)
	if screenshots[id] then
		local ok, reason = gui.set_texture_data(id, img.width, img.height, "rgba", img.buffer)
	else
		local ok, reason = gui.new_texture(id, img.width, img.height, "rgba", img.buffer)
		screenshots[id] = true
	end
	gui.set_texture(node, id)
end

local cached_screenshot = false
local loaded_screenshots = {}

function M.cache_screenshot()
	if screenshot then
		local window_w, window_h = window.get_size()
		local x, y, w, h
		if window_w / window_h > 16 / 9 then
			w = window_h * 16 / 9
			h = window_h
			x = (window_w - w) / 2
			y = 0
		else
			w = window_w
			h = window_w * 9 / 16
			x = 0
			y = (window_h - h) / 2
		end		
		screenshot.png(x, y, w, h, function(self, png, w, h)
			cached_screenshot = png
		end)
	end
end

function M.set_node_to_cached_screenshot(node_id)
	if not cached_screenshot then return end
	local node = gui.get_node(node_id)
	set_node_to_png_buffer(node, cached_screenshot, node_id)
end

function M.set_node_to_thumbnail(node_id, slot)
	if not loaded_screenshots[slot] then
		local filename = save.get_path(slot, nil, nil, "png")
		local data = files.read_binary(filename)
		if data then
			loaded_screenshots[slot] = data
		end
	end
	local loaded_screenshot = loaded_screenshots[slot]
	if loaded_screenshot then
		local node = gui.get_node(node_id)
		set_node_to_png_buffer(node, loaded_screenshot, node_id)
	end
end

function M.save_cached_screenshot(slot)
	local filename = save.get_path(slot, nil, nil, "png")
	files.write_binary(filename, cached_screenshot)
	loaded_screenshots[slot] = cached_screenshot
end






return M