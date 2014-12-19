local function onConnected(firstConnect)
	ulx.SQLBans.createTables()
	ulx.SQLBans.fetchBans()
	timer.Simple(1, ulx.SQLBans.checkCurrentPlayers)
	
	if not firstConnect then
		RunConsoleCommand("ulx", "asay", "Good news, we've re-established connection to bans. Everything will be fine.")
	end
end
hook.Add("ZCore_MySQL_Connected", "BansConnected", onConnected)

local function onDisconnected()
	RunConsoleCommand("ulx", "asay", "Warning: We've lost connection to bans. It's possible that new bans will not save.")
end
hook.Add("ZCore_MySQL_Disconnected", "BansDisconnected", onDisconnected)

local function onPlayerConnect(player)
	local steamid = player.networkid

	if steamid ~= "BOT" then
		local queryStr = [[
			SELECT
				`name`,
				`timestamp`,
				`expiration`,
				`reason`
			FROM `bans` WHERE
				`steamid` = ']] .. ZCore.MySQL.escapeStr(steamid) .. [['
				AND (`type` = 'global' OR `type` = ']] .. ZCore.MySQL.escapeStr(GetConVarString("gamemode")) .. [[')
				AND `unbanned` = 0
				AND (`expiration` > ]] .. os.time() .. [[ OR `expiration` = 0)
			ORDER BY `timestamp` DESC
			LIMIT 1
		]]
		
		ZCore.MySQL.queryRow(queryStr, function(data)
			if data then
				game.ConsoleCommand(string.format("kickid %s %s\n", steamid, ulx.SQLBans.createKickMessage(data.reason, data.expiration)))
				ulx.SQLBans.alertConnectAttempt((string.len(data.name) > 0 and data.name or player.name), steamid, data.reason)
			end
		end)
	end
end
gameevent.Listen("player_connect")
hook.Add("player_connect", "BansPlayerConnect", onPlayerConnect)