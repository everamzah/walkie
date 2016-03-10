-- Limit chat by distance [shout]
-- Original mod by Muhammad Rifqi Priyo Susanto (srifqi)

-- Copyright 2016 James Stevenson
-- License: GPL3

walkie = {}
walkie.hud = {}
walkie.waypoints = {}
walkie.broadcasters = {}
walkie.channel = {}


local displayer = 0.1 

-- Parameter
--local DISTANCE = 64

local player_transfer_distance = tonumber(minetest.setting_get(
		"player_transfer_distance"))
local DISTANCE = player_transfer_distance * 16

local DISTANCESQ = DISTANCE ^ 2


-- Intercomm UI
local function terminal_display(user, pos, input)
	minetest.sound_play({name = "walkie_blip", gain = 1.0}, {to_player = user:get_player_name()})
	input = minetest.formspec_escape(input)

	local term_broadcast = "true"
	local term_name = "myDumbTerminal"
	local hint = "Did you know? You can sprint with the run key."

	local info = "Welcome to Lumaria! We hope you enjoy your stay. This statement is made rather large by the fact that I need to test the very limits of my modding capabilities; meaning formatting."

	local output_quit = "Bye bye!"

	local cmd_table = {"+", "broadcast", "bye", "echo", "help",
			"hi", "hint", "info", "list", "name", "quit"}

	local feedback = ""

	-- Get table with command/args
	local command = input
	local args = {}
	if command:match("%w") then
		for i in command:gmatch"%S+" do
			table.insert(args, i)
		end
		--print(dump(args))
		command = args[1]
	end
	--print(command)

	local name = user:get_player_name()
	local output = ""
	if command == "" then
		command = "Yes Master?"
		output = ""

		feedback = ""

	elseif command == "+" then
		local new_args = {}
		--print(#args)
		--print(type(tonumber(args[2])))

		for i=2, #args do
			if type(tonumber(args[i])) == "number" then
				new_args[i] = tonumber(args[i])
			else
				output = "Err"
				break
			end
		end
		--print(dump(new_args))

		command = input
		local math = 0
		for _, v in pairs(new_args) do
			math = math + v
			--print(math)
		end
		if output ~= "Err" then
			output = tostring(math)
		end

		feedback = ""

	elseif command == "broadcast" then
		output = "Broadcasting to all players with a walkie talkie on any channel."

		feedback = ""

	elseif command == "bye" then
		output = minetest.formspec_escape(output_quit)

		feedback = ""

	elseif command == "echo" then
		local new_input = input
		if new_input:len() >= 40 then
			print("trimming")
			command = new_input:sub(1, 40) .. "$"
			print(command)
		else
			command = input
		end
		--print(dump(args))
		if type(args[2]) == "string" then
			for i = 2, #args do
				--print(args[i])
				if output == "" then
					output = args[i]
				else
					output = output .. " " .. args[i]
				end
			end
		else
			output = "Invalid usage, type help echo for more information."
		end

		feedback = ""

	elseif command == "help" then
		command = input
		if args[2] then
			output = "I don't know about " .. args[2]
			feedback = "Type help for a list of commands."
		else
			output = ""
			for i=1, #cmd_table do
				output = output .. cmd_table[i] .. " "
			end
			feedback = "Type help <cmd> for more information"
		end

	elseif command == "hi" then
		output = "Hello."

		feedback = ""

	elseif command == "hint" then
		output = minetest.formspec_escape(hint)

		feedback = ""

	elseif command == "info" then
		output = minetest.formspec_escape(info)

		feedback = ""

	elseif command == "list" then
		local chatters = ""
		for _, player in pairs(minetest.get_connected_players()) do
			if player:get_inventory():contains_item("main", "walkie:talkie") then
				chatters = chatters .. player:get_player_name() .. " "
			end
		end
		if chatters == "" then
			output = "No one seems to have a walkie talkie."
		else
			output = chatters
		end

		feedback = "Players on Ch#1 or near intercomm listed."

	elseif command == "name" then
		command = input
		local args = args[2]
		if args then
			if args == term_name then
				output = "Correct!"
			elseif args ~= "" then
				output = "Station name is now " .. args
			else
				output = "Invalid usage. Type help name for more information."
			end
		else
			output = "Station name is " .. term_name
		end

		feedback = ""

	elseif command == "quit" then
		output = "There is no escape."

		feedback = "Press [ESC] to exit."

	else
		output = "Unknown command. Type help for a list."
		feedback = ""
	end

	--print(output)
	--print(#output)

	if #output > 40 then
		local old_output = output
		local pos = 0
		local old_pos = 0
		local ln1 = ""
		local ln2 = ""
		local ln3 = ""
		local new_output

		for p in old_output:gmatch"." do
			pos = pos + 1
			if pos >= 40 and p == " " and ln1 == "" then
				--print("hit ln1")
				ln1 = old_output:sub(1, pos)
				ln2 = old_output:sub(pos + 1, -1)
				old_pos = pos
			end
			if pos >= 80 and p == " " and ln2 ~= "" then
				--print("hit ln2")
				ln2 = old_output:sub(old_pos + 1, pos)
				ln3 = old_output:sub(pos + 1, 120)
				break
			end
		end

		new_output = ln1 .. "\n" .. ln2 .. "\n" .. ln3
		--print(new_output)
		--print(old_output:len())
		if old_output:len() > 120 then
			output = new_output .. "\n\n" .. minetest.formspec_escape(feedback) .. "\n" .. minetest.formspec_escape("[more]")
		else
			output = new_output .. "\n\n" .. minetest.formspec_escape(feedback)
		end
		--print(output)
	else
		output = output .. "\n\n\n\n" .. minetest.formspec_escape(feedback)
	end
	--print(output)

	local formspec = "size[8.8,5.9]" ..
			default.gui_bg_img ..
			"checkbox[-.1,-.15;add_waypoint;Broadcast Intercomm Location;" ..
				term_broadcast ..
			 "]" ..
			"box[-.1,.8;8.78,4.5;gray]" ..
			"label[0,1;> " .. command .. "]" .. -- input
			"label[0,1.5;" .. output .. "]" ..
			"field[0.18,5.6;8,1;cmd;;]" ..
			"button_exit[7.78,5.3;1.15,1;enter;OK]"

	minetest.after(displayer, function ()
		minetest.show_formspec(name, "walkie:intercomm", formspec)
	end)

	local sent_form = minetest.show_formspec(name, "walkie:intercomm", formspec)
	return sent_form
end

--
-- Walkie Intercomm
--

minetest.register_node("walkie:intercomm", {
	description = "Intercommunications Module",
	drawtype = "signlike",
	tiles = {"walkie_intercomm.png"},
	is_ground_content = false,
	inventory_image = "walkie_intercomm.png",
	wield_image = "walkie_intercomm.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	light_source = 8,
	sunlight_propagates = true,
	walkable = false,
	selection_box = {type="wallmounted"},
	groups = {cracky = 3, attached_node = 1},
	legacy_wallmounted = true,
	sounds = {
		footstep = {name = "default_hard_footstep", gain = 0.5},
		dig = {name = "walkie_blip", gain = 1.0},
		dug = {name = "walkie_blip", gain = 1.0},
		place = {name = "walkie_blip", gain = 1.0},
		place_failed = {name = "walkie_blip", gain = 1.0}
	},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Intercomm")
	end,
	--[[
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local intercomms = walkie.waypoints[placer:get_player_name()].intercomms
		if not intercomms then
			walkie.waypoints[placer:get_player_name()].intercomms = {[1]=pos}
		else
			table.insert(intercomms, pos)
		end
	end,
	--]]
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local sound = minetest.sound_play({name = "walkie_blip", gain = 1.0},
				{pos = pointed_thing.under,
				max_hear_distance = 32,
				object = clicker,
				loop = true})
		minetest.after(displayer * math.random(1, 2), function ()
			minetest.sound_stop(sound)
		end)

		terminal_display(clicker, pos, "")
	end
})

minetest.register_craft({
	output = "walkie:intercomm",
	recipe = {
		{"default:copper_ingot", "", "default:copper_ingot"},
		{"", "default:mese_crystal", ""},
		{"default:copper_ingot", "", "default:copper_ingot"}
	}
})

local function get_broadcasters(player_name)
	local names = ""
	for i=1, #minetest.get_connected_players() do
		local players = minetest.get_connected_players()
		local name = players[i]:get_player_name()
		local player_entry = walkie.waypoints[name]

		if not player_entry then
			print("No player entry in walkies.waypoints?")
			return
		end

		if player_entry.broadcast == "true" and
				name ~= player_name then
			names = names .. name .. ","
		end
	end
	names = string.sub(names, 1, -2)
	walkie.broadcasters[player_name] = names
	if names == "" then
		names = "No waypoints"
	end
	return names
end

minetest.register_craftitem("walkie:talkie", {
	description = "Walkie Talkie",
	inventory_image = "walkie_talkie.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		local sound = minetest.sound_play({name = "walkie_blip", gain = 1.0},
				{pos = user:getpos(),
				max_hear_distance = 32,
				object = user,
				loop = true})
		minetest.after(displayer * math.random(1, 2), function ()
			minetest.sound_stop(sound)
		end)
		local name = user:get_player_name()
		local idx = walkie.waypoints[name].selected_waypoint_idx or 0
		minetest.show_formspec(name, "walkie:talkie",
			"size[5.25,6]" ..
			default.gui_bg_img ..
			"field[.3,1;1.75,1;channel;Channel:;" ..
				walkie.channel[name] ..
			"]" ..
			"button_exit[1.75,.7;1,1;close;OK]" ..
			"checkbox[0,1.5;broadcast;Broadcast your location;" ..
				walkie.waypoints[name].broadcast  ..
			"]" ..
			"checkbox[0,2.25;toggle_waypoint;Show selected waypoint;" ..
				walkie.waypoints[name].show_waypoint ..
			"]" ..
			"table[0,3.25;5,2.5;waypoints;" ..
				get_broadcasters(user:get_player_name()) ..
			";" .. idx .."]"
		)
		--print(walkie.waypoints[name].selected_waypoint_idx)
	end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	--[[
	print(formname)
	print(dump(fields))
	print("End sent fields")
	print("")
	--]]

	if formname == "walkie:intercomm" then
		if fields.quit == "true" then
			if fields.cmd then
				local input = fields.cmd
				minetest.after(displayer, function ()
					terminal_display(player, {x=0,y=0,z=0}, input)
				end)
			end
		end
	end

	if formname ~= "walkie:talkie" then
		return
	end

	local name = player:get_player_name()
	if fields.waypoints then
		local waypoints_table = minetest.explode_table_event(fields.waypoints)
		
		local bstring = walkie.broadcasters[name]
		local bstring_tab = {}
		for word in string.gmatch(bstring, "([^,]+)") do
			--print(word)
			table.insert(bstring_tab, word)
		end

		--print(bstring_tab[waypoints_table.row])
		walkie.waypoints[name].selected_waypoint = bstring_tab[waypoints_table.row]
		walkie.waypoints[name].selected_waypoint_idx = waypoints_table.row
	end


	if fields.broadcast == "true" then
		walkie.waypoints[name].broadcast = "true"
	elseif fields.broadcast == "false" then
		walkie.waypoints[name].broadcast = "false"
	end


	local input = tonumber(fields.channel)
	if not input
			or input > 30912 or input < 1 then
		return
	else
		walkie.channel[name] = input
	end


	if fields.toggle_waypoint == "true" then
		walkie.waypoints[name].show_waypoint = "true"
	elseif fields.toggle_waypoint == "false" then
		walkie.waypoints[name].show_waypoint = "false"
	end

end)

minetest.register_craft({
	output = "walkie:talkie",
	recipe = {
		{"default:copper_ingot", "default:steel_ingot", "default:copper_ingot"},
		{"default:steel_ingot", "default:diamond", "default:steel_ingot"},
		{"default:copper_ingot", "default:steel_ingot", "default:copper_ingot"}
	}
})



-- Always join on channel 1
minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	walkie.channel[name] = 1
	walkie.waypoints[name] = {}
	walkie.waypoints[name].broadcast = "false"
	walkie.waypoints[name].show_waypoint = "false"
	walkie.waypoints[name].selected_waypoint = ""
	walkie.broadcasters[name] = {}
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	walkie.channel[name] = nil
	walkie.hud[name] = nil
	walkie.waypoints[name] = nil
	walkie.broadcasters[name] = nil
end)


local server_owner = minetest.setting_get("name")
local function is_owner(name)
	-- TODO: Make special priv, instead of relying on name value
	return name == server_owner
end

local function has_walkie(player)
	return player:get_inventory():contains_item("main",
			"walkie:talkie")
end

local function near_intercomm(pos)
	return minetest.find_node_near(pos, 8, {"walkie:intercomm"})
end


-- CHAT
-- Limit chat by distance given in DISTANCE parameter
-- Conditional shout based using walkie talkie item

minetest.register_on_chat_message(function(name, message)
	if is_owner(name) then
		return false
	end

	if message == "/spawn" then
		minetest.chat_send_player(name, "Use a Ruby Warpstone to get back to spawn.")
		return true
	elseif message == "/sethome" then
		minetest.chat_send_player(name, "Use an Emerald Warpstone to set your home.")
		return true
	end

	minetest.log("action", "CHAT: <" .. name .. "> " .. message)

	local shouter = minetest.get_player_by_name(name)
	local spos = shouter:getpos()
	
	-- Minetest library (modified)
	local function vdistancesq(a,b) local x,y,z = a.x-b.x,a.y-b.y,a.z-b.z return x*x+y*y+z*z end

	if not has_walkie(shouter) and not near_intercomm(spos) then
		for _, player in ipairs(minetest.get_connected_players()) do
			local dest = player:get_player_name()
			if not dest then
				return true
			end
			if dest ~= name then
				if is_owner(dest) or vdistancesq(spos, player:getpos()) <= DISTANCESQ then
					minetest.chat_send_player(dest, "<" .. name .. "> " .. message)
				end
			end
		end
		return true
	elseif near_intercomm(spos) and not has_walkie(shouter) then
		for _, player in ipairs(minetest.get_connected_players()) do
			local dest = player:get_player_name()
			if not dest then
				return true
			end
			if dest ~= name then
				if is_owner(dest)
						or (has_walkie(player) and walkie.channel[dest] == 1)
						or near_intercomm(player:getpos())
						or vdistancesq(spos, player:getpos()) <= DISTANCESQ then
					minetest.chat_send_player(dest, "<" .. name .. "> " .. message)
				end
			end
		end
		return true
	elseif near_intercomm(spos) and has_walkie(shouter) then
		for _, player in ipairs(minetest.get_connected_players()) do
			local dest = player:get_player_name()
			if not dest then
				return true
			end
			if dest ~= name then
				if is_owner(dest)
						or (has_walkie(player) and walkie.channel[dest] == 1)
						or (has_walkie(player) and walkie.channel[dest] == walkie.channel[name])
						or vdistancesq(spos, player:getpos()) <= DISTANCESQ then
					minetest.chat_send_player(dest, "<" .. name .. "> " .. message)
				end
			end
		end
		return true
	elseif has_walkie(shouter) and not near_intercomm(spos) then
		for _, player in ipairs(minetest.get_connected_players()) do
			local dest = player:get_player_name()
			if not dest then
				return true
			end
			if dest ~= name then
				if is_owner(dest)
						or (has_walkie(player) and walkie.channel[dest] == walkie.channel[name])
						or near_intercomm(player:getpos())
						or vdistancesq(spos, player:getpos()) <= DISTANCESQ then
					minetest.chat_send_player(dest, "<" .. name .. "> " .. message)
				end
			end
		end
		return true
	end
end)

-- Check for walkie

minetest.register_globalstep(function(dtime)
	displayer = dtime
	--print(displayer)
	for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local pos = vector.round(player:getpos())
		--walkie.waypoints[name].location = pos

		local wielded = player:get_wielded_item():get_name()
		if not wielded then return end

		if wielded == "walkie:talkie" then
			local chatters = {}
			for _, player in pairs(minetest.get_connected_players()) do
				--if player:get_player_name() ~= name then
					if player:get_inventory():contains_item("main", "walkie:talkie") and
							walkie.channel[name] == walkie.channel[player:get_player_name()] then
						table.insert(chatters, player:get_player_name())
					end
				--end
			end
			local hud = walkie.hud[name]
			if not hud then
				hud = {}
				walkie.hud[name] = hud
				hud.comms = player:hud_add({
					hud_elem_type = "text",
					name = "Comms",
					number = 0xFFFFFF,
					position = {x=0, y=1},
					offset = {x=8, y=-8},
					text = "Channel: " .. walkie.channel[name] .. "\n" .. "Players: " .. tostring(#chatters),
					scale = {x=200, y=60},
					alignment = {x=1, y=-1},
				})
				return
			else -- HUD already initialized for this player
				player:hud_change(hud.comms,
						"text",
						"Channel: " ..
						walkie.channel[name] ..
						"\n" .. "Players: " ..
						tostring(#chatters))
			end

			if walkie.waypoints[name].show_waypoint == "true" and
					not walkie.hud[name].waypoint then
				if walkie.waypoints[name].selected_waypoint == "" then
					return
				elseif walkie.waypoints[name].selected_waypoint == nil then
					return
				else
					walkie.hud[name].waypoint = player:hud_add({
						hud_elem_type = "waypoint",
						name = "player name",
						text = " Nodes",
						number = 0xFFFFFF,
						world_pos = {x=13,y=-26111,z=30}
					})
				end
			elseif walkie.waypoints[name].show_waypoint == "true" then
				if walkie.waypoints[name].selected_waypoint == "" then
					return
				elseif walkie.waypoints[name].selected_waypoint == nil then
					return
				else
					local waypoint = walkie.waypoints[name].selected_waypoint
					local waypoint_player = minetest.get_player_by_name(waypoint)
					if not waypoint_player then return end
					player:hud_change(walkie.hud[name].waypoint,
						"world_pos",
						waypoint_player:getpos())
				end
			else
				player:hud_remove(walkie.hud[name].waypoint)
				walkie.hud[name].waypoint = nil
			end
		else
			local hud = walkie.hud[name]
			if hud then
				player:hud_remove(walkie.hud[name].comms)
				player:hud_remove(walkie.hud[name].broadcast)
				player:hud_remove(walkie.hud[name].waypoint)
				walkie.hud[name] = nil

			end
		end
	end
end)

minetest.register_chatcommand("dw", {
	func = function ()
		print(dump(walkie))
	end
})

minetest.register_chatcommand("me", {
	params = "<action>",
	description = "Perform an action for nearby players.",
	privs = {shout = true},
	func = function(name, param)
		local shouter = minetest.get_player_by_name(name)
		if not shouter then
			return
		end
		local spos = shouter:getpos()
		
		-- Minetest library (modified)
		local function vdistancesq(a, b)
			local x,y,z = a.x-b.x,a.y-b.y,a.z-b.z
			return x*x+y*y+z*z
		end
		
		for _, player in ipairs(minetest.get_connected_players()) do
			if not player:get_player_name() ~= nil then
				if player:get_player_name() ~= name then
					local pos = player:getpos()
					if vdistancesq(spos, pos) <= DISTANCESQ then
						minetest.chat_send_player(player:get_player_name(), "* " .. name .. " " .. param)
					end
				end
			end
		end
		return true, "* " .. name .. " " .. param
	end
})

minetest.register_chatcommand("msg", {
        params = "<name> <message>",
        description = "Send a private message",
        privs = {shout = true},
        func = function(name, param)
		if minetest.get_player_by_name(name):get_inventory():contains_item("main", "walkie:talkie") then
			local sendto, message = param:match("^(%S+)%s(.+)$")
			if not sendto then
				return false, "Invalid usage, see /help msg."
			end
			if not minetest.get_player_by_name(sendto) then
				return false, "The player " .. sendto
						.. " is not online."
			end
			if not minetest.get_player_by_name(sendto):get_inventory():contains_item("main", "walkie:talkie") then
				return false, sendto .. " doesn't have a walkie talkie!"
			end
			minetest.log("action", "PM from " .. name .. " to " .. sendto
					.. ": " .. message)
			minetest.chat_send_player(sendto, "PM from " .. name .. ": "
					.. message)
			return true, "Message sent."
		else
			return false, "You need a walkie talkie."
		end
        end
})

