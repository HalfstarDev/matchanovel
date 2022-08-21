-- use this to test integration with your engine, so you can swap the system functions step by step with these stubs

local M = {}

function M.post(receiver, message_id, message)
	print("post message "..message_id.." to: "..receiver)
end

return M