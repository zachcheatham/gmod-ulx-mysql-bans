function ulx.SQLBans.alertConnectAttempt(name, steamid, banReason)
	local message = string.format("Banned player %s <%s> (%s) tried to connect.", name, steamid, banReason)
	for _, ply in ipairs(player.GetAll()) do
		if ply:query("ulx seebannedconnects") then
			ply:ChatPrint(message)
		end
	end
end

function ulx.SQLBans.checkCurrentPlayers()
	for _, ply in ipairs(player.GetAll()) do
		if ULib.bans[ply:SteamID()] and (ULib.bans[ply:SteamID()].unban > os.time() or ULib.bans[ply:SteamID()].unban == 0) then
			local ban = ULib.bans[ply:SteamID()]
			ply:Kick(ulx.SQLBans.createKickMessage(ban.reason, ban.unban))
		end
	end
end

function ulx.SQLBans.createKickMessage(reason, expiration)
	local remaining = tonumber(expiration) - os.time()
	local kickReason
	
	if expiration == 0 then
		if string.len(reason) > 0 then
			kickReason = "You have been permanently banned for \"" .. reason .. "\""
		else
			kickReason = "You have been permanently banned"
		end
		
		if ulx.SQLBans.Settings.appealSite then
			kickReason = kickReason .. ". You may make an appeal at " .. ulx.SQLBans.Settings.appealSite
		end
	else
		if string.len(reason) > 0 then
			kickReason = "You have been banned for \"" .. reason .. "\"."
		else
			kickReason = "You have been banned."
		end

		if ulx.SQLBans.Settings.appealSite then
			kickReason = kickReason .. " Please wait " .. remaining  .. "s or make an appeal at " .. ulx.SQLBans.Settings.appealSite
		else
			kickReason = kickReason .. " Please wait " .. remaining  .. "s"
		end
	end
	
	return kickReason
end