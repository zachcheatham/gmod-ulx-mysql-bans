ulx.SQLBans = {}
	
include("mysqlbans/settings.lua")
include("mysqlbans/util.lua")
include("mysqlbans/data.lua")
include("mysqlbans/hooks.lua")
include("mysqlbans/permissions.lua")
include("mysqlbans/overrides.lua")

function ulx.SQLBans.ban(steamid, reason, length, admin, global, onSuccess)
	local ply = false
	
	for _, p in ipairs(player.GetAll()) do
		if p:SteamID() == steamid then
			ply = p
			break
		end
	end
	
	length = tonumber(length)
	
	local name = IsValid(ply) and ply:Name() or nil
	local adminName = IsValid(admin) and admin:Name() or "CONSOLE"
	local adminSteamID = IsValid(admin) and admin:SteamID() or ""
	local timestamp = os.time()
	local expiration = length == 0 and 0 or os.time() + (length * 60)
	local banType = global and "global" or GetConVarString("gamemode")
	local server = ZCore.Util.getServerIP()
	
	local sqlSteamID = ZCore.MySQL.escapeStr(steamid)
	local sqlName = name and ("'" .. ZCore.MySQL.escapeStr(name) .. "'") or "NULL"
	local sqlReason = ZCore.MySQL.escapeStr(reason)
	local sqlAdminName = ZCore.MySQL.escapeStr(adminName)
	local sqlAdminSteamID = ZCore.MySQL.escapeStr(adminSteamID)
	local sqlBanType = ZCore.MySQL.escapeStr(banType)
	local sqlServer = ZCore.MySQL.escapeStr(server)
	
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
				]] .. sqlName .. [[,
				']] .. sqlReason .. [[',
				]] .. timestamp .. [[,
				]] .. expiration .. [[,
				']] .. sqlAdminSteamID .. [[',
				']] .. sqlAdminName .. [[',
				']] .. sqlServer .. [[',
				']] .. sqlBanType .. [['
			)
	]]
	
	ZCore.MySQL.query(queryStr, function(data, lastInsertID)
		-- Callback
		if onSuccess then
			onSuccess()
		end
	
		-- Kick from server
		local strTime = time ~= 0 and string.format( "for %s minute(s)", time ) or "permanently"
		local showReason = ulx.SQLBans.createKickMessage(reason, expiration)

		if IsValid(ply) then
			ply:Kick(showReason)
		end
		
		game.ConsoleCommand(string.format("kickid %s %s\n", steamid, showReason or ""))
		
		-- Save into local storage (FOR F**KING XGUI)
		local t = {}
		t.name = name
		t.reason = reason
		t.time = timestamp
		t.unban = expiration
		t.admin = adminName
		t.id = lastInsertID

		ULib.bans[steamid] = t
		
		-- Fake call so XGUI updates.
		-- We put "XGUI_SUCKS" so we don't create a loop since addBan calls this
		ULib.addBan("XGUI_SUCKS")
	end)
end

function ulx.SQLBans.unban(steamid, admin, callback)
	local sqlSteamID = ZCore.MySQL.escapeStr(steamid)
	local adminName = IsValid(admin) and ZCore.MySQL.escapeStr(admin:Name()) or "CONSOLE"
	local adminSteamID = IsValid(admin) and ZCore.MySQL.escapeStr(admin:SteamID()) or ""
	
	ZCore.MySQL.query([[
		UPDATE `bans`
			SET
				`unbanned` = 1,
				`unban_admin_name` = ']] .. adminName .. [[',
				`unban_admin_steamid` = ']] .. adminSteamID .. [['
			WHERE
				(`expiration` = 0 OR `expiration` > ]] .. os.time() .. [[)
				AND `steamid` = ']] .. steamid .. [[']]
	, callback)
	
	-- Remove from local storage (FOR F**KING XGUI)
	ULib.bans[steamid] = nil
	
	-- Fake call so XGUI updates.
	-- We put "XGUI_SUCKS" so we don't create a loop since unBan calls this
	ULib.unban(steamid, "XGUI_SUCKS")
end