--local pronouns = require "matchanovel.extensions.pronouns"

local save = require "matchanovel.save"

local M = {}

local pronouns = {}

pronouns.she = {
	they = "she",
	them = "her",
	their = "her",
	theirs = "hers",
	themself = "herself",
	themselves = "herself",
	verb_end = "s",
	plural = false,
}

pronouns.he = {
	they = "he",
	them = "him",
	their = "his",
	theirs = "his",
	themself = "himself",
	themselves = "himself",
	verb_end = "s",
	plural = false,
}

pronouns.they = {
	they = "they",
	them = "them",
	their = "their",
	theirs = "theirs",
	themself = "themself",
	themselves = "themselves",
	verb_end = "",
	plural = true,
}


local function set_var(name, value)
end
local function get_var(name)
end


function M.interpolate_string(s)
	--{a??looks,look} -> {name??term_singular,term_plural}
	if name then
		if get_var(name..".plural") then
			return term_plural
		else
			return term_singular
		end
	else
		if get_var("plural") then
			return term_plural
		else
			return term_singular
		end
	end
end

function M.before_action(action, args)
	if action == "set" then
		local name
		local before_dot, after_dot = string.match(args.left, "([%a_][%w_]*)%.([%a_][%w_]*)")
		if args.left == "pronouns" then
			name = ""
		elseif before_dot and after_dot and after_dot == "pronouns" then
			name = before_dot.."."
		end

		local pronoun = args.right
		local pronoun_string = string.match(pronoun, "[%w/]+")

		if name and pronoun_string and pronouns[pronoun_string] then 
			for k, v in pairs(pronouns[pronoun_string]) do
				--print(name..k, v, type(v))
				save.set_var(name..k, v, type(v))
			end
		end
	end
end



return M