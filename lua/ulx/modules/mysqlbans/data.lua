function ulx.SQLBans.createTables()
	ZCore.MySQL.query([[
		CREATE TABLE IF NOT EXISTS `bans` (
			`id` int(11) NOT NULL AUTO_INCREMENT,
			`steamid` varchar(20) NOT NULL,
			`name` varchar(32) DEFAULT NULL,
			`reason` text,
			`timestamp` int(10) NOT NULL,
			`expiration` int(10) NOT NULL,
			`admin_steamid` varchar(20) NOT NULL,
			`admin_name` varchar(32) NOT NULL,
			`unbanned` tinyint(1) NOT NULL DEFAULT '0',
			`unban_admin_name` varchar(32) DEFAULT NULL,
			`unban_admin_steamid` varchar(20) DEFAULT NULL,
			`server` varchar(21) NOT NULL,
			`type` varchar(32) NOT NULL,
			PRIMARY KEY (`id`)
		)
	]])
end

function ulx.SQLBans.fetchBans()
	local queryStr = [[
		SELECT
			`id`,
			`steamid`,
			`name`,
			`reason`,
			`timestamp`,
			`expiration`,
			`admin_name`
		FROM `bans`
		WHERE
			(`type` = 'global' OR `type` = ']] .. ZCore.MySQL.escapeStr(GetConVarString("gamemode")) .. [[')
			AND (`expiration` > ]] .. os.time() .. [[ OR `expiration` = 0)
			AND `unbanned` = 0
	]]

	ZCore.MySQL.query(queryStr, function(data)
		-- BACKUP OLD BANS
		if not ULib.fileExists("data/ulib/bans_old.txt") then
			ServerLog("First run detected. Backing up bans.txt to bans_old.txt...")
			ULib.fileWrite("data/ulib/bans_old.txt", ULib.fileRead(ULib.BANS_FILE))
		end
	
		table.Empty(ULib.bans)
		
		for _, ban in ipairs(data) do
			local t = {}
			t.id = ban.id
			t.name = ban.name
			t.reason = ban.reason
			t.time = ban.timestamp
			t.unban = ban.expiration
			t.admin = ban.admin_name
			
			ULib.bans[ban.steamid] = t
		end
		
		-- THIS IS THE ONLY F**CKING WAY TO GET XGUI TO UPDATE
		-- SOMEDAY I'LL WRITE MY OWN XGUI TAB FOR THIS
		ULib.addBan("XGUI_SUCKS")
	end)
end