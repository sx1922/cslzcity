local player_GetAll = player.GetAll
zb.modes = zb.modes or {}

util.AddNetworkString("FadeScreen")

function zb.AddFade()
	net.Start("FadeScreen")
	net.Broadcast()
end

local forcemodeconvar = CreateConVar("zb_forcemode", "random", nil, "Set force mode (set to 'random' to disable)")
forcemodeconvar:SetString("random")
function zb:GetMode(round)
	if zb.modes[round] then return round end

	for name, mode in pairs(zb.modes) do
		if mode.Types and mode.Types[round] then
			return name
		end
	end

	-- A stale/invalid queue entry must never leave the server with a nil mode.
	-- Falling back to the base homicide mode keeps the round state machine alive
	-- while still allowing the next valid mode to be selected normally.
	return zb.modes.hmcd and "hmcd" or next(zb.modes)
end

function CurrentRound()
	if IsValid(ents.FindByClass( "trigger_changelevel" )[1]) then
		zb.nextround = "coop"
		zb.CROUND = zb.CROUND or "coop"
		return zb.modes["coop"] or zb.modes["hmcd"], zb.CROUND
	end

	zb.CROUND = zb.CROUND or "hmcd"
	if not zb.CROUND_MAIN or (zb.LASTCROUND != zb.CROUND) then
		zb.CROUND_MAIN = zb:GetMode(zb.CROUND)
		zb.LASTCROUND = zb.CROUND
	end

	local round = zb.CROUND_MAIN
	local mode = zb.modes[round]
	if not mode then
		-- Recover from a bad admin command or an old persisted queue without
		-- calling methods on nil during PreRound/EndRoundThink.
		zb.CROUND = "hmcd"
		zb.CROUND_MAIN = zb:GetMode(zb.CROUND)
		zb.LASTCROUND = zb.CROUND
		mode = zb.modes[zb.CROUND_MAIN]
	end

	return mode, zb.CROUND
end

function NextRound(round)
	if IsValid(ents.FindByClass( "trigger_changelevel" )[1]) then
		zb.nextround = "coop"
	else
		local resolved = round and zb:GetMode(round)
		if not resolved then
			print("[Z-City] ignored invalid next mode: " .. tostring(round))
			zb.nextround = "hmcd"
			return
		end
		-- Keep sub-mode keys (for example homicide/hideout) intact; GetMode
		-- resolves them to their owning mode when the round starts.
		zb.nextround = round
	end
end

function zb:PreRound()
	if ((((zb.Roundscount or 0) > 15) and !GetConVar("zb_dev"):GetBool()) or ( (player.GetCount() > 1) and zb.ROUND_STATE == 0 and zb.CheckRTVVotes() )) and !(zb.RoundsLeft and zb.CROUND == "cstrike") then
		zb.StartRTV(20)
		zb.ROUND_STATE = 0
		return
	end

	if zb.ROUND_STATE == 0 and #player_GetAll() > 1 then
		zb.END_TIME = nil

		local mode = CurrentRound()
		if not mode then return end
		zb.START_TIME = zb.START_TIME or CurTime() + (mode.start_time or 5)
		if zb.START_TIME < CurTime() then zb:RoundStart() end
	end
end

function zb:RoundThink()
	if zb.ROUND_STATE == 1 then
		local mode = CurrentRound()
		if mode and mode.RoundThink then mode:RoundThink() end
	end
end

hook.Add("CanListenOthers","RoundStartChat",function(output, input, isChat, teamonly, text)
	if zb.ROUND_STATE == 0 or zb.ROUND_STATE == 3 then return true, false end
end)

function zb:EndRound()
	if zb.ROUND_STATE == 3 then return end
	zb.ROUND_STATE = 3
	zb.Roundscount = (zb.Roundscount or 0) + 1

	local mode, round = CurrentRound()
	if not mode then
		zb.ROUND_STATE = 0
		return
	end

	net.Start("RoundInfo")
		net.WriteString(mode.name or "hmcd")
		net.WriteInt(zb.ROUND_STATE, 4)
	net.Broadcast()

	--PrintMessage(HUD_PRINTTALK, "Раунд закончен.")
	if mode.EndRound then mode:EndRound() end
	hook.Run("ZB_EndRound")
	zb.AddFade()

	hg.achievements.SavePlayerAchievements()
end

function zb:CheckWinner(tbl)
	local playerTable = table.Copy(tbl)
	for i, players in pairs(playerTable) do
		if table.Count(players) == 0 then
			playerTable[i] = nil
			continue
		end

		playerTable[i] = i
	end

	local winner = (table.Count(playerTable) == 1 and table.Random(playerTable)) or (table.Count(playerTable) == 0 and 3) or false
	local shouldendround = winner and true or nil
	return shouldendround, winner
end

zb.ROUND_TIME = zb.ROUND_TIME or 300

function zb:ShouldRoundEnd()
	local time = zb.ROUND_TIME
	local mode = CurrentRound()
	if not mode then return false end

	-- 开局宽限期：等待异步出生/角色分配完成，避免空队伍在开局瞬间被误判为回合结束
	if zb.LAST_ROUNDSTART_TIME and (CurTime() - zb.LAST_ROUNDSTART_TIME) < 3 then return false end

	-- pcall 保护：模式判定报错时不再每 tick 刷错，回退为超时兜底（与未定义时的原行为一致）
	local ok, shouldroundend = true, nil
	if mode.ShouldRoundEnd then
		ok, shouldroundend = pcall(mode.ShouldRoundEnd, mode)
		if not ok then
			print("[Z-City] " .. tostring(zb.CROUND) .. " ShouldRoundEnd 报错: " .. tostring(shouldroundend))
			shouldroundend = nil
		end
	end

	if shouldroundend ~= false then
		local boringround = (zb.ROUND_START + time) < CurTime()

		if shouldroundend or boringround then
			-- 诊断：打印结束原因与各队存活数，用于排查“自动结束”
			local counts = {}
			if zb.CheckAliveTeams then
				local okT, tbl = pcall(zb.CheckAliveTeams, zb, true)
				if okT and istable(tbl) then
					for k, v in pairs(tbl) do counts[#counts + 1] = tostring(k) .. "=" .. #v end
				end
			end
			print(string.format("[Z-City] 回合结束判定: 模式=%s 原因=%s 本局时长=%.0f秒 存活[%s]",
				tostring(zb.CROUND),
				(shouldroundend and "模式条件" or "超时"),
				CurTime() - (zb.LAST_ROUNDSTART_TIME or CurTime()),
				table.concat(counts, ", ")))
		end

		if boringround and mode.BoringRoundFunction then
			PrintMessage(HUD_PRINTTALK, "因为太无聊，回合已终止。")

			mode:BoringRoundFunction()
		end

		return (shouldroundend and true) or (boringround)
	else
		return false
	end
end

function zb:EndRoundThink()
	if zb.ROUND_STATE == 1 and zb:ShouldRoundEnd() then zb:EndRound() end
	if zb.ROUND_STATE == 3 then
		local mode = CurrentRound()
		if not mode then return end
		if !zb.END_TIME then
			zb.END_TIME = (CurTime() + (mode.end_time or 5))
			if zb.nextround == "coop" and GetGlobalVar("coop_first_round_timer", 0) == 0 then

				zb.END_TIME = (CurTime() + (GetConVar("zb_dev"):GetBool() and 5 or 60))
				SetGlobalVar("coop_first_round_timer", zb.END_TIME)
			end
		end
		
		zb.SHOULD_FADE = zb.SHOULD_FADE != nil and zb.SHOULD_FADE or true

		if zb.SHOULD_FADE and (zb.END_TIME < CurTime() + 1.5) then
			zb.SHOULD_FADE = false

			for _, ply in player.Iterator() do
				ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0), 1, 7)
			end
		end

		if zb.END_TIME < CurTime() then
			zb.ROUND_STATE = 0

			zb.SHOULD_FADE = true

			hook.Run("ZB_PreRoundStart")
			hook.Run("TTTPrepareRound") -- stormfox2 random_round_weather

			local prevRound = zb.CROUND
			zb.CROUND = zb.nextround or "hmcd"
			print(string.format("[Z-City] 回合切换: %s -> %s (nextround=%s)", tostring(prevRound), tostring(zb.CROUND), tostring(zb.nextround)))
			local nextMode = CurrentRound()
			if nextMode and nextMode.CanLaunch then
				local ok, canLaunch = pcall(nextMode.CanLaunch, nextMode)
				if not ok or canLaunch == false then
					local failMsg = "[Z-City] 模式 " .. tostring(zb.CROUND) .. " 无法启动（地图点位/人数不满足），已回退到标准模式。"
					PrintMessage(HUD_PRINTTALK, failMsg)
					print(failMsg)
					zb.CROUND = "hmcd"
					zb.CROUND_MAIN = "hmcd"
					zb.LASTCROUND = "hmcd"
					nextMode = zb.modes.hmcd
				end
			end
			if nextMode and nextMode.shouldfreeze then zb:Freeze() end

			--PrintMessage(HUD_PRINTTALK, "Gamemode: " .. CurrentRound().PrintName or "None")

			local mode, round = CurrentRound()
			net.Start("RoundInfo")
				net.WriteString(mode.name or "hmcd")
				net.WriteInt(zb.ROUND_STATE, 4)
			net.Broadcast()

			hg.UpdateRoundTime(mode.ROUND_TIME, CurTime(), CurTime() + (mode.start_time or 5))

			self:KillPlayers()
			self:AutoBalance()

			if hg.PluvTown.Active then
				for _, ply in player.Iterator() do
					ply:SetNetVar("CurPluv", "pluv")
				end
			end

			local mode = CurrentRound()
			if mode then
				mode.saved = {}
				if mode.Intermission then
					local ok, err = pcall(mode.Intermission, mode)
					if not ok then ErrorNoHalt("[Z-City] " .. tostring(mode.name) .. " Intermission failed: " .. tostring(err) .. "\n") end
				end
				if mode.GiveEquipment then
					local ok, err = pcall(mode.GiveEquipment, mode)
					if not ok then ErrorNoHalt("[Z-City] " .. tostring(mode.name) .. " GiveEquipment failed: " .. tostring(err) .. "\n") end
				end
			end
		end
	end
end

hook.Add("PlayerInitialSpawn", "zb_SendRoundInfo", function(ply)
	if zb.CROUND then
		local mode,round = CurrentRound()
		net.Start("RoundInfo")
			net.WriteString(mode.name or "hmcd")
			net.WriteInt(zb.ROUND_STATE, 4)
		net.Send(ply)
	end

	if ply.SyncVars then ply:SyncVars() end
end)

util.AddNetworkString("RoundInfo")
function zb:Think(time)
	if (zb.thinkTime or CurTime()) > time then return end
	zb.thinkTime = time + 1
	zb:PreRound()
	zb:RoundThink()
	zb:EndRoundThink()
end

hook.Add("Think", "zb-think", function() zb:Think(CurTime()) end)

function zb:KillPlayers()
	local mode = CurrentRound()
	if not mode then return end
	for i, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end

		ply:GiveExp(math.random(4,15))

		if ply:Alive() and mode.DontKillPlayer and mode:DontKillPlayer(ply) then
			hg.organism.Clear(ply.organism)
			hg.FakeUp(ply,true,true)

			continue
		end
		
		if ply:FlashlightIsOn() then ply:Flashlight(false) end

		ply:KillSilent()
		ply:Spawn()
		if IsValid(ply) and ply:Alive() and ply.SetPlayerClass then
			ply:SetPlayerClass()
		end
	end
end

zb.forcemode = zb.forcemode or "random"

local forcemode = zb.forcemode

function zb.GetModes()
	local newtbl = {}
	for name,tbl in pairs(zb.modes) do
		table.insert(newtbl,name)
	end
	return newtbl
end

ZBATTLE_BIGMAP = 5700

hook.Add("InitPostEntity", "loadbigmap", function()
	local filik = file.Read("zbattle/mapsizes.json", "DATA")

	if filik then
		local tbl = util.JSONToTable(filik)

		if tbl[game.GetMap()] then
			ZBATTLE_BIGMAP = tbl[game.GetMap()]
		end
	end
end)

COMMANDS.bigmap = {
	function(ply, args)
		if not ply:IsAdmin() then ply:ChatPrint("你没有访问权限") return end
		ZBATTLE_BIGMAP = tonumber(args[1])
		ply:ChatPrint("大地图的距离：" .. ZBATTLE_BIGMAP)
		zb.RerollChances()

		file.CreateDir("zbattle")

		local tbl = util.JSONToTable(file.Read("zbattle/mapsizes.json", "DATA") or util.TableToJSON({[game.GetMap()] = ZBATTLE_BIGMAP}))

		tbl[game.GetMap()] = ZBATTLE_BIGMAP

		file.Write("zbattle/mapsizes.json", util.TableToJSON(tbl))

		ply:ChatPrint("已保存到文件中")
	end,
	0
}


zb.BigMaps = {
	["mu_smallotown_v2_snow"] = true,
	["mu_smallotown_v2_13"] = true,
	["mu_smallotown_v2_13_night"] = true,
}

function zb.GetAvailableModes()
	zb.tdm_checkpoints()

	local newtbl = {}

	for i, name in pairs(zb.GetModes()) do

		local tbl = zb.modes[name]
		if (tbl.CanLaunch and tbl:CanLaunch()) and
		(
			( not tbl.ForBigMaps ) or
			( zb.GetWorldSize() > ZBATTLE_BIGMAP )
		) then
			if tbl.SubModes then
				for i, name2 in pairs(tbl:SubModes()) do
					table.insert(newtbl, name2)
				end
			else
				table.insert(newtbl, name)
			end
		end
	end

	return newtbl
end

zb.ModesPlaytime = zb.ModesPlaytime or {}

function zb.GetModesPlaytime()
	local tbl = zb.GetAvailableModes()
	local newtbl = {}
	local count = 0

	for i, name in ipairs(tbl) do
		local amt = zb.ModesPlaytime[name] or 0
		newtbl[name] = amt
		count = count + amt
	end

	return newtbl, count
end

function zb.GetModePlaytime(name)
	return zb.ModesPlaytime[name] or 0
end

function zb.SetModePlaytime(name, set)
	zb.ModesPlaytime[name] = set
end

function zb.AddModePlaytime(name, add)
	zb.ModesPlaytime[name] = (zb.ModesPlaytime[name] or 0) + add
end

function zb.AddCurrentModePlayed()
	if not CurrentRound() then return end
	local mode = CurrentRound()
	local name = mode.name

	if mode.SubModes then
		name = mode.Type or "hmcd"
	end

	zb.AddModePlaytime(name, 1)
end

function zb.GetChance(name, addtbl)
	local mode = zb:GetMode(name)
	local tbl = zb.modes[mode]

	local newtbl = tbl.Types and tbl.Types[name] or tbl

	return newtbl.ChanceFunction and newtbl:ChanceFunction(addtbl or {}) or zb.ModesChances[name] or newtbl.Chance or 0.1
end

function zb.GetModesChances()
	local tbl = zb.GetAvailableModes()
	local newtbl = {}

	for i, name in pairs(tbl) do
		newtbl[name] = zb.GetChance(name)
	end

	return newtbl
end

function zb.WeightedChanceMode(modes_chances)
	local weight = 0

	local newchancestbl = {}
	for name, chance in pairs(modes_chances) do
		local newchance = zb.GetChance(name, {rounds = zb.RoundList}) or chance
		newchancestbl[name] = newchance
		weight = weight + newchance * 100
	end

	local random = math.random(weight)

	local count = 0
	for name, chance in RandomPairs(modes_chances) do
		count = count + (newchancestbl[name] or chance) * 100

		if count >= random then
			return name
		end
	end

	return "hmcd"
end

function zb.GetWorldSize()
	/*
	local world = game.GetWorld()
	local worldMin = world:GetInternalVariable("m_WorldMins")
	local worldMax = world:GetInternalVariable("m_WorldMaxs")
	local size = worldMin:Distance(worldMax)

	return size + (zb.BigMaps[ game.GetMap() ] and 5000 or 0)
	*/

	local dist = 0
	local pts = zb.GetMapPoints( "RandomSpawns" )

	-- 地图没有保存过 RandomSpawns 点位时视为不限大小：
	-- 否则返回 0 会把所有 ForBigMaps 模式（tdm 等）从随机池中排除，导致每局都随机到同一批模式
	if not pts or #pts < 2 then return math.huge end

	for _, pnt in pairs(pts) do
		for _, pnt2 in pairs(pts) do
			dist = math.max(dist, pnt.pos:DistToSqr(pnt2.pos))
		end
	end

	return math.sqrt(dist)
end

function zb.GetRoundName(name)
	local mode = zb:GetMode(name)
	if not mode or not zb.modes[mode] then return end
	return zb.modes[mode].PrintName
end

zb.RoundList = zb.RoundList or {}
zb.QueuedModes = zb.QueuedModes or {}

function zb.CheckChances()
	if #zb.RoundList == 0 then
		zb.RerollChances()
	end

	local nextrnd = zb.nextround or zb.RoundList[1]
	print("Next round is: "..zb.GetRoundName(nextrnd).." ("..nextrnd..")")

	if #zb.QueuedModes > 0 then
		print("Queued game modes:")
		for i=1, #zb.QueuedModes do
			print("  "..i..": "..zb.GetRoundName(zb.QueuedModes[i]).." ("..zb.QueuedModes[i]..")")
		end
	else
		for i=1,#zb.RoundList do
			print("Round "..(i+1).." will be "..zb.GetRoundName(zb.RoundList[i]).." ("..zb.RoundList[i]..")")
		end
	end
end

function zb.RerollChances()
	zb.RoundList = {}

	local chances = zb.GetModesChances()

	for i = 1, 20 do
		local round = zb.WeightedChanceMode(chances)

		zb.RoundList[i] = round
	end

	zb.nextround = table.remove(zb.RoundList, 1)
end

function zb.GetModesInfo()
	local modesInfo = {}

	for name, mode in pairs(zb.modes) do
		if mode.Types then
			for name2, mode2 in pairs(mode.Types) do
				table.insert(modesInfo, {
					key = name2,
					name = (mode.PrintName or mode.name or name).."/"..name2,
					description = mode.Description or "",
					forBigMaps = mode.ForBigMaps or false,
					canlaunch = (mode:CanLaunch() and 1 or 0)
				})
			end
		else
			table.insert(modesInfo, {
				key = name,
				name = mode.PrintName or mode.name or name,
				description = mode.Description or "",
				forBigMaps = mode.ForBigMaps or false,
				canlaunch = (mode:CanLaunch() and 1 or 0)
			})
		end
	end

	return modesInfo
end


function zb.SetRoundList(newList)
	local newLista = table.Copy(newList)
	if #newLista > 0 then
		zb.nextround = table.remove(newLista, 1)
		zb.RoundList = newLista
	else
		zb.RerollChances()

		zb.nextround = table.remove(zb.RoundList, 1)
	end
end


util.AddNetworkString("ZB_SendModesInfo")
util.AddNetworkString("ZB_SendRoundList")
util.AddNetworkString("ZB_RequestRoundList")
util.AddNetworkString("ZB_UpdateRoundList")
util.AddNetworkString("ZB_NotifyRoundListChange")


function zb.SendModesInfoToClient(ply)
	net.Start("ZB_SendModesInfo")
		net.WriteTable(zb.GetModesInfo())
	net.Send(ply)
end


function zb.SendRoundListToClient(ply)
	net.Start("ZB_SendRoundList")
		net.WriteTable(zb.RoundList)
		net.WriteString(zb.nextround or "")
		net.WriteString(forcemodeconvar:GetString() or "random")
	net.Send(ply)
end

function zb.SyncForceModeToAdmins()
	for _, admin in ipairs(zb.GetAllAdmins()) do
		zb.SendRoundListToClient(admin)
	end
end


hook.Add("PlayerInitialSpawn", "ZB_SendModesOnSpawn", function(ply)
	if ply:IsAdmin() then
		timer.Simple(1, function()
			if IsValid(ply) then
				zb.SendModesInfoToClient(ply)
				zb.SendRoundListToClient(ply)
			end
		end)
	end
end)


net.Receive("ZB_RequestRoundList", function(len, ply)
	if IsValid(ply) and ply:IsAdmin() then
		zb.SendModesInfoToClient(ply)
		zb.SendRoundListToClient(ply)
	end
end)

net.Receive("ZB_UpdateRoundList", function(len, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	local newList = net.ReadTable()
	local forceUpdate = net.ReadBool()

	zb.SetRoundList(newList)

	net.Start("ZB_NotifyRoundListChange")
		net.WriteString(ply:Nick())
	net.Send(zb.GetAllAdmins())

	for _, admin in ipairs(zb.GetAllAdmins()) do
		zb.SendRoundListToClient(admin)
	end
end)

function zb:RoundStart()
	local mode = CurrentRound()
	if not mode then return end
	if mode.shouldfreeze then zb:Unfreeze() end

	zb.ROUND_STATE = 1
	zb.LAST_ROUNDSTART_TIME = CurTime()
	zb.START_TIME = nil

	local mode, round = CurrentRound()

	VFIRE_DISABLED = (mode.name == "coop")

	zb.ROUND_BEGIN = CurTime()
	hg.UpdateRoundTime()

	net.Start("RoundInfo")
		net.WriteString(mode.name or "hmcd")
		net.WriteInt(zb.ROUND_STATE, 4)
	net.Broadcast()

	if forcemodeconvar:GetString() != "" and forcemodeconvar:GetString() ~= "random" then
		forcemode = forcemodeconvar:GetString()
		-- 强制模式生效提示：避免“每回合都是同一个模式”却无人知晓原因
		PrintMessage(HUD_PRINTTALK, "[Z-City] 本回合为强制模式: " .. tostring(forcemode) .. "（F6 面板切回 random 可解除）")
	elseif forcemodeconvar:GetString() == "random" then
		forcemode = "random"
	end

	zb.AddCurrentModePlayed()

	if mode.RoundStart then
		local ok, err = pcall(mode.RoundStart, mode)
		if not ok then
			ErrorNoHalt("[Z-City] " .. tostring(mode.name) .. " RoundStart failed: " .. tostring(err) .. "\n")
		end
	end

	local nextMode

	if #zb.RoundList == 0 then
		zb.RerollChances()
	end

	nextMode = table.remove(zb.RoundList, 1)

	local currentMode = mode.Type or round

	print("Next game mode is " .. nextMode)

	NextRound(forcemode ~= "random" and forcemode or (nextMode or "hmcd"))

	if mode.RoundStartPost then
		mode:RoundStartPost()
	end

	hook.Run("ZB_StartRound")

	//zb.GetAllPoints(true)

	for _, admin in ipairs(zb.GetAllAdmins()) do
		zb.SendRoundListToClient(admin)
	end
end

concommand.Add("zb_checkchances",function(ply) if ply:IsAdmin() then zb.CheckChances() end end)
concommand.Add("zb_rerollchances",function(ply) if ply:IsAdmin() then zb.RerollChances() zb.CheckChances() end end)

function zb.NotifyQueueEmptied()
	net.Start("QueueEmptiedNotification")
	net.Send(zb.GetAllAdmins())
end

hook.Add("PlayerInitialSpawn", "SendGameModesToClient", function(ply)
	if ply:IsAdmin() then
		local modesToSend = {}
		for key, mode in pairs(zb.modes) do
			table.insert(modesToSend, {key = key, name = mode.PrintName or mode.name})
		end

		net.Start("SendAvailableModes")
			net.WriteTable(modesToSend)
		net.Send(ply)
	end
end)

net.Receive("AdminSetGameMode", function(len, ply)
	if not ply:IsAdmin() then return end

	local command = net.ReadString()
	local modeKey = net.ReadString()
	local addToQueue = net.ReadBool() or false

	if command == "setmode" then
		NextRound(modeKey)
		ply:ChatPrint("游戏模式设置为：" .. modeKey)

		if addToQueue then
			table.insert(zb.QueuedModes, modeKey)
			zb.NotifyQueueModified(ply, "added " .. modeKey .. " to")

			zb.SyncQueueToAdmins()
		end
	elseif command == "setforcemode" then
		forcemodeconvar:SetString(modeKey)
		forcemode = modeKey

		if modeKey == "random" then
			ply:ChatPrint("强制模式已禁用")
			net.Start("ZB_NotifyRoundListChange")
				net.WriteString(ply:Nick())
			net.Send(zb.GetAllAdmins())
		else
			NextRound(forcemode)
			ply:ChatPrint("强制模式设置为：" .. modeKey)
		end

		zb.SyncForceModeToAdmins()

		if addToQueue then
			table.insert(zb.QueuedModes, modeKey)
			zb.NotifyQueueModified(ply, "added " .. modeKey .. " to")

			zb.SyncQueueToAdmins()
		end
	end
end)

net.Receive("AdminEndRound", function(len, ply)
	if not ply:IsAdmin() then return end

	ply:ChatPrint("回合结束！")
	zb:EndRound()
end)

function zb.SyncQueueToAdmins()
	timer.Simple(0.1, function()
		net.Start("SendGameQueue")
		net.WriteTable(zb.QueuedModes)
		net.Send(zb.GetAllAdmins())
	end)
end

net.Receive("AdminSetGameQueue", function(len, ply)
	if not ply:IsAdmin() then return end

	local modeQueue = net.ReadTable()
	zb.QueuedModes = modeQueue

	if #modeQueue == 0 then
		ply:ChatPrint("游戏模式队列已清空")
		zb.NotifyQueueModified(ply, "cleared")


		timer.Simple(0.2, function()
			net.Start("QueueEmptiedNotification")
			net.Send(zb.GetAllAdmins())
		end)
	else
		ply:ChatPrint("游戏模式队列已设置，共 " .. #modeQueue .. " 个模式")
		zb.NotifyQueueModified(ply, "updated")
	end

	zb.SyncQueueToAdmins()
end)

function zb.NotifyQueueModified(ply, action)
	local admins = zb.GetAllAdmins()

	local recipients = {}
	for _, admin in ipairs(admins) do
		if admin ~= ply then
			table.insert(recipients, admin)
		end
	end


	if #recipients > 0 then
		net.Start("QueueModifiedNotification")
		net.WriteString(IsValid(ply) and ply:Nick() or "Server")
		net.WriteString(action)
		net.Send(recipients)
	end
end

function zb:Unfreeze()
	for i, ply in player.Iterator() do
		if ply:Alive() then ply:Freeze(false) end
	end
end


function zb:Freeze()
	for i, ply in player.Iterator() do
		if ply:Alive() then ply:Freeze(true) end
	end
end

function zb.GetAllAdmins()
	local admins = {}
	for _, ply in player.Iterator() do
		if ply:IsAdmin() then
			table.insert(admins, ply)
		end
	end
	return admins
end

COMMANDS.setmode = {
	function(ply, args)
		if not ply:IsAdmin() then ply:ChatPrint("你没有访问权限") return end
		if not args[1] or (not zb:GetMode(args[1]) and args[1]~="random") then return end
		ply:ChatPrint(args[1])
		NextRound(args[1])
	end,
	0
}

COMMANDS.setforcemode = {
	function(ply, args)
		if not ply:IsAdmin() then ply:ChatPrint("你没有访问权限") return end
		if not args[1] or (not zb:GetMode(args[1]) and args[1]~="random") then return end
		ply:ChatPrint(args[1])
		forcemode = args[1]
		if args[1] ~= "random" then
			NextRound(args[1])
		end
	end, 0
}

COMMANDS.endround = {
	function(ply, args)
		if not ply:IsAdmin() then
			ply:ChatPrint("你没有访问权限")
			return
		end
	 	zb:EndRound()
	end, 0
}

if SERVER then
	util.AddNetworkString("SendAvailableModes")
	util.AddNetworkString("AdminSetGameMode")
	util.AddNetworkString("AdminEndRound")
	util.AddNetworkString("AdminSetGameQueue")
	util.AddNetworkString("RequestGameQueue")
	util.AddNetworkString("SendGameQueue")
	util.AddNetworkString("QueueEmptiedNotification")
	util.AddNetworkString("QueueModifiedNotification")

	hook.Add("PlayerInitialSpawn", "SendGameModesToClient", function(ply)
		if ply:IsAdmin() then
			local modesToSend = {}
			for key, mode in pairs(zb.modes) do
				table.insert(modesToSend, {key = key, name = mode.PrintName or mode.name})
			end

			net.Start("SendAvailableModes")
				net.WriteTable(modesToSend)
			net.Send(ply)
		end
	end)

	net.Receive("AdminSetGameMode", function(len, ply)
		if not ply:IsAdmin() then return end

		local command = net.ReadString()
		local modeKey = net.ReadString()
		local addToQueue = net.ReadBool() or false

		-- 安全解析：modeKey 可能是 Types 子键或无效键，直接索引 zb.modes 会对 nil 调方法导致切换静默失败
		local resolvedKey = nil
		if zb.modes[modeKey] then
			resolvedKey = modeKey
		else
			for name, m in pairs(zb.modes) do
				if m.Types and m.Types[modeKey] then
					resolvedKey = name
					break
				end
			end
		end

		if not resolvedKey then
			ply:ChatPrint("未知模式： " .. tostring(modeKey))
			return
		end

		local targetMode = zb.modes[resolvedKey]

		if not (ply:IsSuperAdmin() or ply:IsAdmin()) then
			if not targetMode.CanLaunch or not targetMode:CanLaunch() then
				ply:ChatPrint("此模式无法启动（无点数或被禁用）： " .. modeKey)
				return
			end
		end

		if command == "setmode" then
			NextRound(resolvedKey)
			ply:ChatPrint("游戏模式设置为：" .. modeKey)

			if addToQueue then
				table.insert(zb.QueuedModes, modeKey)
				zb.NotifyQueueModified(ply, "added " .. modeKey .. " to")

				zb.SyncQueueToAdmins()
			end
		elseif command == "setforcemode" then
			forcemodeconvar:SetString(modeKey)
			forcemode = modeKey

			if modeKey == "random" then
				ply:ChatPrint("强制模式已禁用")
			else
				if resolvedKey and zb.modes[resolvedKey] then
					NextRound(resolvedKey)
				end
				PrintMessage(HUD_PRINTTALK, "[Z-City] 已开启强制模式: " .. modeKey .. "（之后每回合都将是该模式，F6 面板切换为 random 可解除）")
				ply:ChatPrint("强制模式设置为：" .. modeKey)
			end

			zb.SyncForceModeToAdmins()

			if addToQueue then
				table.insert(zb.QueuedModes, modeKey)
				zb.NotifyQueueModified(ply, "added " .. modeKey .. " to")

				zb.SyncQueueToAdmins()
			end
		end
	end)

	function zb.SyncQueueToAdmins()
		timer.Simple(0.1, function()
			net.Start("SendGameQueue")
			net.WriteTable(zb.QueuedModes)
			net.Send(zb.GetAllAdmins())
		end)
	end

	net.Receive("AdminSetGameQueue", function(len, ply)
		if not ply:IsAdmin() then return end

		local modeQueue = net.ReadTable()
		zb.QueuedModes = modeQueue

		if #modeQueue == 0 then
			ply:ChatPrint("游戏模式队列已清空")
			zb.NotifyQueueModified(ply, "cleared")


			timer.Simple(0.2, function()
				net.Start("QueueEmptiedNotification")
				net.Send(zb.GetAllAdmins())
			end)
		else
			ply:ChatPrint("游戏模式队列已设置，共 " .. #modeQueue .. " 个模式")
			zb.NotifyQueueModified(ply, "updated")
		end

		zb.SyncQueueToAdmins()
	end)

end

-- 回合系统版本标记：用于确认服务器实际加载的文件版本
print("[Z-City] sv_roundsystem v20260824 已加载 (队列修复+诊断)")

COMMANDS.zbdebug = {
	function(ply, args)
		local function out(s)
			if IsValid(ply) then ply:ChatPrint(s) else print(s) end
		end

		out("[ZB-DEBUG] STATE=" .. tostring(zb.ROUND_STATE) .. " CROUND=" .. tostring(zb.CROUND) .. " CROUND_MAIN=" .. tostring(zb.CROUND_MAIN))
		out("[ZB-DEBUG] nextround=" .. tostring(zb.nextround) .. " zb_forcemode=" .. tostring(forcemodeconvar and forcemodeconvar:GetString() or "?"))
		out("[ZB-DEBUG] RoundList(" .. #(zb.RoundList or {}) .. "): " .. table.concat(zb.RoundList or {}, ", "))
		local ws, bigmap = "err", "err"
		local okWS, wsv = pcall(zb.GetWorldSize)
		if okWS then ws = string.format("%.0f", wsv) end
		bigmap = tostring(ws ~= "err" and (wsv > ZBATTLE_BIGMAP))
		out("[ZB-DEBUG] WorldSize=" .. ws .. " BigMapThreshold=" .. tostring(ZBATTLE_BIGMAP) .. " isBig=" .. bigmap)
		local avail = {}
		local okAV, avtbl = pcall(zb.GetAvailableModes)
		if okAV and istable(avtbl) then avail = avtbl end
		out("[ZB-DEBUG] 可随机模式(" .. #avail .. "): " .. table.concat(avail, ", "))
	end, 0
}
