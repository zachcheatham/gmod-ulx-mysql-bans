function ulx.gban(calling_ply, target_ply, minutes, reason)
	if target_ply:IsBot() then
		ULib.tsayError( calling_ply, "Cannot ban a bot", true )
		return
	end
	
	ulx.SQLBans.ban(target_ply:SteamID(), reason, minutes, calling_ply, true, function()
		local time = "for #i minute(s)"
		if minutes == 0 then time = "permanently" end
		local str = "#A globally banned #T " .. time
		if reason and reason ~= "" then str = str .. " (#s)" end
		ulx.fancyLogAdmin(calling_ply, str, target_ply, minutes ~= 0 and minutes or reason, reason)
	end)
end
local gban = ulx.command("Utility", "ulx gban", ulx.gban, "!gban")
gban:addParam{type=ULib.cmds.PlayerArg}
gban:addParam{type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0}
gban:addParam{type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons}
gban:defaultAccess(ULib.ACCESS_ADMIN)
gban:help("Bans target from all servers.")

function ulx.gbanid(calling_ply, steamid, minutes, reason)
	steamid = steamid:upper()
	if not ULib.isValidSteamID(steamid) then
		ULib.tsayError(calling_ply, "Invalid steamid.")
		return
	end

	ulx.SQLBans.ban(steamid, reason, minutes, calling_ply, true, function()
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
		local str = "#A globally banned steamid #s "
		displayid = steamid
		if name then
			displayid = displayid .. "(" .. name .. ") "
		end
		str = str .. time
		if reason and reason ~= "" then str = str .. " (#4s)" end
		ulx.fancyLogAdmin(calling_ply, str, displayid, minutes ~= 0 and minutes or reason, reason)
	end)
end
local gbanid = ulx.command("Utility", "ulx gbanid", ulx.gbanid)
gbanid:addParam{type=ULib.cmds.StringArg, hint="steamid"}
gbanid:addParam{type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0}
gbanid:addParam{type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons}
gbanid:defaultAccess(ULib.ACCESS_SUPERADMIN)
gbanid:help("Bans steamid from all servers.")

function ulx.mysqlbansimport(calling_ply)
	local bans, err = ULib.parseKeyValues(ULib.fileRead(ULib.BANS_FILE))
	
	if err then
		ULib.tsayError(calling_ply, "We were unable to parse the bans file. Maybe it's missing or not formatted correctly?")
		return
	end
	
	ULib.tsay(calling_ply, "Ban import started. The server may freeze for a few seconds!")
	
	local totalBans = table.Count(bans)
	local completedBans = 0
	
	local server = ZCore.Util.getServerIP()
	local sqlServer = ZCore.MySQL.escapeStr(server)
	local sqlBanType = ZCore.MySQL.escapeStr(GetConVarString("gamemode"))
	
	for steamid, ban in pairs(bans) do	
		if type(ban) == "table" and type(steamid) == "string" then			
			local admin = ban.admin and string.Explode("(", string.Replace(ban.admin, ")", "")) or {"CONSOLE", ""}
			
			local sqlSteamID = ZCore.MySQL.escapeStr(steamid)
			local sqlName = ZCore.MySQL.escapeStr(ban.name and ban.name or "")
			local sqlReason = ZCore.MySQL.escapeStr(ban.reason)
			local sqlAdminName = ZCore.MySQL.escapeStr(admin[1])
			local sqlAdminSteamID = ZCore.MySQL.escapeStr(admin[2])
			local timestamp = ban.time and tonumber(ban.time) or 0
			local expiration = ban.unban and tonumber(ban.unban) or 0
			
			local queryStr = [[
				INSERT INTO `bans`
					(
						`steamid`,
						`name`,
						`reason`,
						`timestamp`,
						`expiration`,
						`admin_steamid`,
						`admin_name`,
						`server`,
						`type`
					)
					VALUES (
						']] .. sqlSteamID .. [[',
						']] .. sqlName .. [[',
						']] .. sqlReason .. [[',
						]] .. timestamp .. [[,
						]] .. expiration .. [[,
						']] .. sqlAdminSteamID .. [[',
						']] .. sqlAdminName .. [[',
						']] .. sqlServer .. [[',
						']] .. sqlBanType .. [['
					)
			]]
			
			ZCore.MySQL.query(queryStr, function()
				completedBans = completedBans + 1
				ULib.tsay(calling_ply, "Completed " .. completedBans .. "/" .. totalBans .. " bans.")
				
				if completedBans == totalBans then
					ULib.tsay(calling_ply, "All bans have been imported. Don't do this again or you'll have duplicates!")
				end
			end)
		end
	end
end
local mysqlbansimport = ulx.command("MySQL Bans", "ulx mysqlbansimport", ulx.mysqlbansimport)
mysqlbansimport:defaultAccess(ULib.ACCESS_SUPERADMIN)
mysqlbansimport:help("Transfers all ULX bans to MySQL.")

local function overrideCommands()
	-- Override ulx ban
	ULib.cmds.translatedCmds["ulx ban"].fn = function(calling_ply, target_ply, minutes, reason)
		if target_ply:IsBot() then
			ULib.tsayError( calling_ply, "Cannot ban a bot", true )
			return
		end
		
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
			ULib.tsayError( ply, "Error editing ban: You must have access to ulx ban, " .. ply:Nick() .. "!", true )
			return
		end

		local steamID = args[1]
		local bantime = tonumber( args[2] )
		local reason = args[3]
		local name = args[4]

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

		-- Reason
		local argInfo = cmd.args[4]
		local success, err = argInfo.type:parseAndValidate( ply, reason, argInfo, accessPieces[3] )
		if not success then
			ULib.tsayError( ply, "Error editing ban: You did not specify a valid reason, " .. ply:Nick() .. "!", true )
			return
		end

		local queryStr = [[
			DELETE FROM `bans`
			WHERE
				`unbanned` = 0
				AND (`expiration` = 0 OR `expiration` > ]] .. os.time() .. [[)
				AND `steamid` = ']] .. steamid .. [[']]

		ZCore.MySQL.query(queryStr, function()
			ulx.SQLBans.ban(steamid, reason, bantime, ply, false)
		end)
	end
end

if SERVER then
	hook.Add("InitPostEntity", "SQLBans_CommandOverride", overrideCommands)
end

function overrideXGUIElements()
	function xgui.ShowBanWindow( ply, ID, doFreeze, isUpdate )
		if not LocalPlayer():query( "ulx ban" ) and not LocalPlayer():query( "ulx banid" ) then return end

		local xgui_banwindow = xlib.makeframe{ label=( isUpdate and "Edit Ban" or "Ban Player" ), w=285, h=200, skin=xgui.settings.skin }
		xlib.makelabel{ x=37, y=33, label="Name:", parent=xgui_banwindow }
		xlib.makelabel{ x=23, y=58, label="SteamID:", parent=xgui_banwindow }
		xlib.makelabel{ x=28, y=83, label="Reason:", parent=xgui_banwindow }
		xlib.makelabel{ x=10, y=108, label="Ban Length:", parent=xgui_banwindow }
		local reason = xlib.makecombobox{ x=75, y=80, w=200, parent=xgui_banwindow, enableinput=true, selectall=true, choices=ULib.cmds.translatedCmds["ulx ban"].args[4].completes }
		local banpanel = ULib.cmds.NumArg.x_getcontrol( ULib.cmds.translatedCmds["ulx ban"].args[3], 2 )
		banpanel:SetParent( xgui_banwindow )
		banpanel.interval:SetParent( xgui_banwindow )
		banpanel.interval:SetPos( 200, 105 )
		banpanel.val:SetParent( xgui_banwindow )
		banpanel.val:SetPos( 75, 125 )
		banpanel.val:SetWidth( 200 )
		local globalBan
		
		local name
		if not isUpdate then
			name = xlib.makecombobox{ x=75, y=30, w=200, parent=xgui_banwindow, enableinput=true, selectall=true }
			for k,v in pairs( player.GetAll() ) do
				name:AddChoice( v:Nick(), v:SteamID() )
			end
			name.OnSelect = function( self, index, value, data )
				self.steamIDbox:SetText( data )
			end
			
			xlib.makelabel{ x=14, y=147, label="Global Ban:", parent=xgui_banwindow }
			globalBan = xlib.makecheckbox{x=75, y=147, parent=xgui_banwindow}
		else
			name = xlib.maketextbox{ x=75, y=30, w=200, parent=xgui_banwindow, selectall=true }
			if xgui.data.bans[ID] then
				name:SetText( xgui.data.bans[ID].name or "" )
				reason:SetText( xgui.data.bans[ID].reason or "" )
				if tonumber( xgui.data.bans[ID].unban ) ~= 0 then
					local btime = ( tonumber( xgui.data.bans[ID].unban ) - tonumber( xgui.data.bans[ID].time ) )
					if btime % 31536000 == 0 then
						if #banpanel.interval.Choices >= 6 then
							banpanel.interval:ChooseOptionID(6)
						else
							banpanel.interval:SetText( "Years" )
						end
						btime = btime / 31536000
					elseif btime % 604800 == 0 then
						if #banpanel.interval.Choices >= 5 then
							banpanel.interval:ChooseOptionID(5)
						else
							banpanel.interval:SetText( "Weeks" )
						end
						btime = btime / 604800
					elseif btime % 86400 == 0 then
						if #banpanel.interval.Choices >= 4 then
							banpanel.interval:ChooseOptionID(4)
						else
							banpanel.interval:SetText( "Days" )
						end
						btime = btime / 86400
					elseif btime % 3600 == 0 then
						if #banpanel.interval.Choices >= 3 then
							banpanel.interval:ChooseOptionID(3)
						else
							banpanel.interval:SetText( "Hours" )
						end
						btime = btime / 3600
					else
						btime = btime / 60
						if #banpanel.interval.Choices >= 2 then
							banpanel.interval:ChooseOptionID(2)
						else
							banpanel.interval:SetText( "Minutes" )
						end
					end
					banpanel.val:SetValue( btime )
				end
			end
		end

		local steamID = xlib.maketextbox{ x=75, y=55, w=200, selectall=true, disabled=( isUpdate or not LocalPlayer():query( "ulx banid" ) ), parent=xgui_banwindow }
		name.steamIDbox = steamID --Make a reference to the steamID textbox so it can change the value easily without needing a global variable

		if doFreeze and ply then
			if LocalPlayer():query( "ulx freeze" ) then
				RunConsoleCommand( "ulx", "freeze", "$" .. ULib.getUniqueIDForPlayer( ply ) )
				steamID:SetDisabled( true )
				name:SetDisabled( true )
				xgui_banwindow:ShowCloseButton( false )
			else
				doFreeze = false
			end
		end
		xlib.makebutton{ x=165, y=170, w=75, label="Cancel", parent=xgui_banwindow }.DoClick = function()
			if doFreeze and ply and ply:IsValid() then
				RunConsoleCommand( "ulx", "unfreeze", "$" .. ULib.getUniqueIDForPlayer( ply ) )
			end
			xgui_banwindow:Remove()
		end
		xlib.makebutton{ x=45, y=170, w=75, label=( isUpdate and "Update" or "Ban!" ), parent=xgui_banwindow }.DoClick = function()
			if isUpdate then
				local function performUpdate(btime)
					RunConsoleCommand( "xgui", "updateBan", steamID:GetValue(), btime, reason:GetValue(), name:GetValue() )
					xgui_banwindow:Remove()
				end
				btime = banpanel:GetMinutes()
				if btime ~= 0 and xgui.data.bans[steamID:GetValue()] and btime * 60 + xgui.data.bans[steamID:GetValue()].time < os.time() then
					Derma_Query( "WARNING! The new ban time you have specified will cause this ban to expire.\nThe minimum time required in order to change the ban length successfully is " 
							.. xgui.ConvertTime( os.time() - xgui.data.bans[steamID:GetValue()].time ) .. ".\nAre you sure you wish to continue?", "XGUI WARNING",
						"Expire Ban", function()
							performUpdate(btime)
						end,
						"Cancel", function() end )
				else
					performUpdate(btime)
				end
				return
			end

			if ULib.isValidSteamID( steamID:GetValue() ) then
				local isOnline = false
				for k, v in ipairs( player.GetAll() ) do
					if v:SteamID() == steamID:GetValue() then
						isOnline = v
						break
					end
				end
				if not isOnline then
					if name:GetValue() == "" then
						local cmd = globalBan:GetChecked() and "gbanid" or "banid"
						RunConsoleCommand( "ulx", cmd, steamID:GetValue(), banpanel:GetValue(), reason:GetValue() )
					else
						RunConsoleCommand( "xgui", "updateBan", steamID:GetValue(), banpanel:GetMinutes(), reason:GetValue(), ( name:GetValue() ~= "" and name:GetValue() or nil ) )
					end
				else
					local cmd = globalBan:GetChecked() and "gban" or "ban"
					RunConsoleCommand( "ulx", cmd, "$" .. ULib.getUniqueIDForPlayer( isOnline ), banpanel:GetValue(), reason:GetValue() )
				end
				xgui_banwindow:Remove()
			else
				local ply = ULib.getUser( name:GetValue() )
				if ply then
					local cmd = globalBan:GetChecked() and "gban" or "ban"
					RunConsoleCommand( "ulx", cmd, "$" .. ULib.getUniqueIDForPlayer( ply ), banpanel:GetValue(), reason:GetValue() )
					xgui_banwindow:Remove()
					return
				end
				Derma_Message( "Invalid SteamID, player name, or multiple player targets found!" )
			end
		end

		if ply then name:SetText( ply:Nick() ) end
		if ID then steamID:SetText( ID ) else steamID:SetText( "STEAM_0:" ) end
	end
end

if CLIENT then
	hook.Add("InitPostEntity", "SQLBans_XGUIOverrides", overrideXGUIElements)
	overrideXGUIElements()
end