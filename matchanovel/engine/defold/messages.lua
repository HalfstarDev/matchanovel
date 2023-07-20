local M = {}

-- Object names mapped to Defold URLs
local defold_objects = {
	textbox = "textbox",
	sprites = "sprites",
	background = "background#background",
	choices = "choices#choices",
	menu = "menu#menu",
	quickmenu = "quickmenu#quickmenu",
	sound = "sound#sound",
	debug = "debug",
	title = "title#title",
	particles_back = "particles_back#particles",
	particles_front = "particles_front#particles",
}

-- Defold function to post message to objects
function M.post(receiver, message_id, message)
	msg.post(defold_objects[receiver], message_id, message)
end

return M