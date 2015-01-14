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

function overrideXGUIElements()
	function xgui.ShowBanWindow( ply, ID, doFreeze, isUpdate, bandata )
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
			if bandata then
				name:SetText( bandata.name or "" )
				reason:SetText( bandata.reason or "" )
				if tonumber( bandata.unban ) ~= 0 then
					local btime = ( tonumber( bandata.unban ) - tonumber( bandata.time ) )
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
				if btime ~= 0 and bandata and btime * 60 + bandata.time < os.time() then
					Derma_Query( "WARNING! The new ban time you have specified will cause this ban to expire.\nThe minimum time required in order to change the ban length successfully is " 
							.. xgui.ConvertTime( os.time() - bandata.time ) .. ".\nAre you sure you wish to continue?", "XGUI WARNING",
						"Expire Ban", function()
							performUpdate(btime)
							xbans.RemoveBanDetailsWindow( bandata.steamID )
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
					local cmd = globalBan:GetChecked() and "gbanid" or "banid"
					RunConsoleCommand( "ulx", cmd, steamID:GetValue(), banpanel:GetValue(), reason:GetValue() )
				else
					local cmd = globalBan:GetChecked() and "gban" or "ban"
					RunConsoleCommand( "ulx", cmd, "$" .. ULib.getUniqueIDForPlayer( isOnline ), banpanel:GetValue(), reason:GetValue() )
				end
				xgui_banwindow:Remove()
			else
				-- I don't think it was my fault, but if the provided SteamID was invalid and it decides to ban
				-- by Name, it would ban me instead of failing. I removed that functionality.
				Derma_Message( "Invalid SteamID!" )
			end
		end

		if ply then name:SetText( ply:Nick() ) end
		if ID then steamID:SetText( ID ) else steamID:SetText( "STEAM_0:" ) end
	end
end

if CLIENT then
	hook.Add("InitPostEntity", "SQLBans_XGUIOverrides", overrideXGUIElements)
	--overrideXGUIElements()
end