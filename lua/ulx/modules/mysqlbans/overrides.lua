
ULib.ban = function(ply, time, reason, admin)
	if not time or type(time) ~= "number" then
		time = 0
	end
	
	Ulib.addBan(ply:SteamID(), time, reason, ply:Name(), admin)
end

ULib.kickban = function(ply, time, reason, admin)
	if not time or type(time) ~= "number" then
		time = 0
	end
	
	ULib.addBan(ply:SteamID(), time, reason, ply:Name(), admin)
end

function ULib.addBan(steamid, length, reason, name, admin)
	-- steamid is XGUI_SUCKS when we call this function in ulx.SQLBans.addban to update XGUI
	-- Don't want to create an infinite loop!	
	if steamid ~= "XGUI_SUCKS" then
		ulx.SQLBans.ban(steamid, reason, length, admin, false)
	end
end

function ULib.unban(steamid, admin)
	-- Admin is XGUI_SUCKS when we call this function in ulx.SQLBans.unban to update XGUI
	-- Don't want to create an infinite loop!
	if admin ~= "XGUI_SUCKS" then
		ulx.SQLBans.unban(steamid, admin)
	end
end

function ULib.refreshBans()
end

local function overrideCommands()
	-- Override ulx ban
	ULib.cmds.translatedCmds["ulx ban"].fn = function(calling_ply, target_ply, minutes, reason)
		if target_ply:IsBot() then
			ULib.tsayError( calling_ply, "Cannot ban a bot", true )
			return
		end
		
		return
		
		ulx.SQLBans.ban(target_ply:SteamID(), reason, minutes, calling_ply, false, function()
			local time = "for #i minute(s)"
			if minutes == 0 then time = "permanently" end
			local str = "#A banned #T " .. time
			if reason and reason ~= "" then str = str .. " (#s)" end
			ulx.fancyLogAdmin(calling_ply, str, target_ply, minutes ~= 0 and minutes or reason, reason)
		end)
	end
	
	-- Override ulx banid
	ULib.cmds.translatedCmds["ulx banid"].fn = function(calling_ply, steamid, minutes, reason)
		steamid = steamid:upper()
		if not ULib.isValidSteamID(steamid) then
			ULib.tsayError(calling_ply, "Invalid steamid.")
			return
		end

		ulx.SQLBans.ban(steamid, reason, minutes, calling_ply, false, function()
			local name
			local plys = player.GetAll()
			for i=1, #plys do
				if plys[i]:SteamID() == steamid then
					name = plys[i]:Nick()
					break
				end
			end

			local time = "for #i minute(s)"
			if minutes == 0 then time = "permanently" end
			local str = "#A banned steamid #s "
			displayid = steamid
			if name then
				displayid = displayid .. "(" .. name .. ") "
			end
			str = str .. time
			if reason and reason ~= "" then str = str .. " (#4s)" end
			ulx.fancyLogAdmin(calling_ply, str, displayid, minutes ~= 0 and minutes or reason, reason)
		end)
	end
	
	-- Override ulx unban
	ULib.cmds.translatedCmds["ulx unban"].fn = function(calling_ply, steamid)
		steamid = steamid:upper()
		if not ULib.isValidSteamID( steamid ) then
			ULib.tsayError( calling_ply, "Invalid steamid." )
			return
		end
		
		local name = ULib.bans[steamid] and ULib.bans[steamid].name
		
		ulx.SQLBans.unban(steamid, calling_ply, function()
			if name then
				ulx.fancyLogAdmin(calling_ply, "#A unbanned steamid #s", steamid .. " (" .. name .. ")")
			else
				ulx.fancyLogAdmin(calling_ply, "#A unbanned steamid #s", steamid)
			end
		end)
	end
	
	-- Override xgui modify ban
	xgui.cmds["updateBan"] = function(ply, args)
		local access, accessTag = ULib.ucl.query( ply, "ulx ban" )
		if not access then
			ULib.tsayError(ply, "Error editing ban: You must have access to ulx ban, " .. ply:Nick() .. "!", true )
			return
		end

		local steamID = args[1]
		local bantime = tonumber( args[2] )
		local reason = args[3]
		local name = (string.len(args[4]) > 0) and args[4] or nil

		-- Check restrictions
		local cmd = ULib.cmds.translatedCmds[ "ulx ban" ]
		local accessPieces = {}
		if accessTag then
			accessPieces = ULib.splitArgs( accessTag, "<", ">" )
		end
		
		-- Ban length
		local argInfo = cmd.args[3]
		local success, err = argInfo.type:parseAndValidate( ply, bantime, argInfo, accessPieces[2] )
		if not success then
			ULib.tsayError( ply, "Error editing ban: " .. err, true )
			return
		end
		
		local expiration = (bantime > 0) and ULib.bans[steamID].time + (bantime * 60) or 0

		-- Reason
		local argInfo = cmd.args[4]
		local success, err = argInfo.type:parseAndValidate( ply, reason, argInfo, accessPieces[3] )
		if not success then
			ULib.tsayError( ply, "Error editing ban: You did not specify a valid reason, " .. ply:Nick() .. "!", true )
			return
		end

		-- ID
		local id = ULib.bans[steamID].id
		
		local sqlName = name and ("'" .. ZCore.MySQL.escapeStr(name) .. "'") or "NULL"
		local queryStr = [[
			UPDATE `bans`
			SET
				`reason` = ']] .. ZCore.MySQL.escapeStr(reason) .. [[',
				`expiration` = ]] .. expiration .. [[,
				`name` = ]] .. sqlName .. [[
			WHERE
				`id` = ]] .. id

		ZCore.MySQL.query(queryStr, function()
			ULib.bans[steamID].reason = reason
			ULib.bans[steamID].unban = expiration
			ULib.bans[steamID].name = name
		
			-- UPDATE XGUI
			ULib.addBan("XGUI_SUCKS")
			
			--xgui.sendDataTable({}, "bans")
		end)
	end
	
	-- Override GMOD's ban function
	local pmeta = FindMetaTable("Player")
	function pmeta:Ban(minutes)
		if self:IsBot() then
			return
		end
		
		ulx.SQLBans.ban(self:SteamID(), nil, minutes, nil, false, function()
			local time = "for #i minute(s)"
			if minutes == 0 then time = "permanently" end
			local str = "#A banned #T " .. time
			if reason and reason ~= "" then str = str .. " (#s)" end
			ulx.fancyLogAdmin(ents.Create("NULL"), str, self, minutes ~= 0 and minutes or reason, reason)
		end)
	end
	
	-- Override TTT's ban function
	if pmeta.KickBan then
		function pmeta:KickBan(minutes, reason)
			if self:IsBot() then
				return
			end
			
			ulx.SQLBans.ban(self:SteamID(), reason, minutes, nil, false, function()
				local time = "for #i minute(s)"
				if minutes == 0 then time = "permanently" end
				local str = "#A banned #T " .. time
				if reason and reason ~= "" then str = str .. " (#s)" end
				ulx.fancyLogAdmin(ents.Create("NULL"), str, self, minutes ~= 0 and minutes or reason, reason)
			end)
		end
	end
end

if SERVER then
	hook.Add("InitPostEntity", "SQLBans_CommandOverride", overrideCommands)
end