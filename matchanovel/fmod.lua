local save = require "matchanovel.save"
local settings = require "matchanovel.settings"

local M = {}

local banks = {}
local events = {}
local instances = {}
local playing = {}
local tracked_objects = {}
local volume_type = {}
local audio_sources = {}
local listener_attr
local fmod_3d_max_x_position = 1
local fmod_3d_max_x_pan = 1

local bank_path = "/assets/audio/fmod/"



local function fmod_missing()
	if not fmod then
		print("Error: You have to install the FMOD extension to use a FMOD bank.")
		return true
	end
end

local function check_banks()
	M.load_bank("Master")
	M.load_bank("Master.strings")
	
	local bank = save.get_var("fmod.bank")
	if bank then
		M.load_bank(bank)
	end

	local i = 1
	bank = save.get_var("fmod.bank_"..i)
	while bank do
		M.load_bank(bank)
		i = i + 1
		bank = save.get_var("fmod.bank_"..i)
	end
end


function M.unload_all()
	fmod.studio.system:unload_all()
end

function M.load_bank(name)
	if fmod_missing() then return end
	if name and not banks[name] then
		local bank = resource.load(bank_path..name..".bank")
		if bank then
			banks[name] = fmod.studio.system:load_bank_memory(bank, fmod.STUDIO_LOAD_BANK_NORMAL)
		end
	end
end

function M.get_event(name)
	if fmod_missing() then return end
	local id = "event:/"..name
	if not events[id] then
		events[id] = fmod.studio.system:get_event(id)
	end
	return events[id]
end

function M.create_instance(event_name, instance_name)
	if fmod_missing() then return end
	local name = instance_name or event_name
	local event = M.get_event(event_name)
	if not instances[name] then
		instances[name] = event:create_instance()
	end
end

function M.get_instance(name)
	if fmod_missing() then return end
	if not instances[name] then
		M.create_instance(name)
	end
	return instances[name]
end

function M.set_listener_attributes()
	if fmod_missing() then return end
	listener_attr.position = vmath.vector3(0.0)
	listener_attr.velocity = vmath.vector3(0.0)
	fmod.studio.system:set_listener_attributes(0, listener_attr)
end

function M.set_3d_attributes(event_name, x)
	if fmod_missing() then return end
	local instance = M.get_instance(event_name)
	if instance then
		local attributes = fmod._3D_ATTRIBUTES()
		attributes.position = vmath.vector3(x, 0, 0)
		attributes.velocity = vmath.vector3(0.0)
		attributes.forward = vmath.vector3(0.0, 1.0, 0.0)
		attributes.up = vmath.vector3(0.0, 0.0, -1.0)
		instance:set_3d_attributes(attributes)
	end
end

function M.set_parameter_by_name(instance_name, name, value, ignoreseekspeed)
	if fmod_missing() then return end
	local instance = M.get_instance(instance_name)
	if instance then
		instance:set_parameter_by_name(name, value, ignoreseekspeed)
	end
end

local function get_volume_music()
	return settings.get("volume_music") / 100 or 1
end

local function get_volume_sound()
	return settings.get("volume_sound") / 100 or 1
end

local function get_volume(name)
	local audio_type = save.get_var(name..".audio_type")
	if audio_type then
		if audio_type == "sound" then
			return get_volume_sound()
		elseif audio_type == "music" then
			return get_volume_music()
		end
	end
	return get_volume_sound()
end

local function set_volume(name, volume)
	if fmod_missing() then return end
	local instance = M.get_instance(name)
	if instance then
		instance:set_volume(volume)
	end
end

function M.start(name)
	if fmod_missing() then return end
	local instance = M.get_instance(name)
	if instance then
		instance:start()
		local volume = get_volume(name) or 1
		instance:set_volume(volume)
		playing[name] = true
	end
end

function M.stop(name, fade)
	if fmod_missing() then return end
	if instances[name] then
		if fade then
			instances[name]:stop(fmod.STUDIO_STOP_ALLOWFADEOUT)
		else
			instances[name]:stop(fmod.STUDIO_STOP_IMMEDIATE)
		end
		playing[name] = nil
	end
end

function M.stop_all()
	for name, _ in pairs(playing) do
		M.stop(name, false)
	end
	playing = {}
end

function M.track_object(object, event)
	tracked_objects[object] = event
end

function M.untrack_object(object)
	tracked_objects[object] = false
end

function M.set_audio_source(id, pan)
	local distance_max = save.get_var("fmod.distance_max") or 1
	audio_sources[id] = pan * distance_max
end

function M.play(event, audio_type, bank, source)
	if bank then
		M.load_bank(bank)
	end
	if audio_type then
		volume_type[event] = audio_type
	end
	if event then
		M.start(event)
		set_volume(event, get_volume(event))
		if source then
			M.track_object(source, event)
		end
	end
end

function M.statement(s, args)
	args = args or {}
	if fmod_missing() then return end
	check_banks()
	local fmod_bank = save.get_var(s..".fmod.bank")
	local fmod_event = save.get_var(s..".fmod.event")
	local fmod_source = save.get_var(s..".fmod.source")
	local audio_type = args.audio_type or save.get_var(s..".audio_type")

	M.play(fmod_event, audio_type, fmod_bank, fmod_source)

	--[[
	if fmod_bank then
		M.load_bank(fmod_bank)
	end
	if audio_type then
		volume_type[s] = audio_type
	end
	if fmod_event then
		M.start(fmod_event)
		set_volume(fmod_event, get_volume(s))
		if fmod_source then
			M.track_object(fmod_source, fmod_event)
		end
	end
	--]]
end

function M.check_for_statement(s)
	local found_statement_function = false
	local statement_fmod_event = save.get_var(s..".fmod.event")
	if statement_fmod_event then
		M.statement(s)
		found_statement_function = true
	end
	local statement_fmod_stop_all = save.get_var("fmod.stop_all")
	if statement_fmod_stop_all then
		M.stop_all()
		found_statement_function = true
	end
	return found_statement_function
end

function M.init()
	if fmod_missing() then return end
	check_banks()
	listener_attr = fmod._3D_ATTRIBUTES()
	listener_attr.forward = vmath.vector3(0.0, 1.0, 0.0)
	listener_attr.up = vmath.vector3(0.0, 0.0, -1.0)
	M.set_listener_attributes()
end

function M.update()
	if not fmod then return end
	for name, event in pairs(tracked_objects) do
		if audio_sources[name] then
			local x = audio_sources[name]
			M.set_3d_attributes(event, x)
		end
	end
end

return M
