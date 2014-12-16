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