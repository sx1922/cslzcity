MissionIntro = MissionIntro or {}

if not SERVER then return end

MissionIntro.SPAWN_ARMOR_RETRY_DELAYS = MissionIntro.SPAWN_ARMOR_RETRY_DELAYS or {
	0, 0.08, 0.15, 0.25, 0.4, 0.65, 1.0, 1.5, 2.0,
}

MissionIntro._spawnArmorRoundToken = MissionIntro._spawnArmorRoundToken or 0

local function MI_LogArmor(msg)
	if MissionIntro.Log then
		MissionIntro.Log(msg)
	else
		print("[MissionIntro][SpawnArmor] " .. tostring(msg))
	end
end

function MissionIntro.CancelScheduledSpawnArmor(ply)
	if not IsValid(ply) then return end
	ply._miSpawnArmorToken = (ply._miSpawnArmorToken or 0) + 1
end

function MissionIntro.ResetStoredPlayerArmor(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	-- 玩家实体跨生死保留 NW；须同时清当前值与上限，否则 ZHEV_Init 会沿用上一命的残甲/万甲上限
	if ZHEV and ZHEV.IsExtendedEnabled and ZHEV.IsExtendedEnabled() then
		local defaultMax = (ZHEV.GetDefaultMaxArmor and ZHEV.GetDefaultMaxArmor()) or 100
		if ZHEV.SetPlayerMaxArmor then
			ZHEV.SetPlayerMaxArmor(ply, defaultMax)
		end
		if ZHEV.SetPlayerArmor then
			ZHEV.SetPlayerArmor(ply, 0)
		end
	else
		if ZHEV and ZHEV.SetPlayerArmor then
			ZHEV.SetPlayerArmor(ply, 0)
		end
		ply:SetArmor(0)
	end
end

function MissionIntro.ClearSpawnArmorLifeState(ply)
	if not IsValid(ply) then return end
	ply._miSpawnArmorRoundToken = nil
	MissionIntro.CancelScheduledSpawnArmor(ply)
end

function MissionIntro.MarkSpawnArmorApplied(ply)
	if not IsValid(ply) then return end
	ply._miSpawnArmorRoundToken = MissionIntro._spawnArmorRoundToken
end

function MissionIntro.HasSpawnArmorForCurrentRound(ply)
	if not IsValid(ply) then return false end
	return ply._miSpawnArmorRoundToken == MissionIntro._spawnArmorRoundToken
end

function MissionIntro.IsZCityRoundActive()
	return zb and zb.ROUND_STATE == 1
end

-- Z City：仅在正式回合进行中（ROUND_STATE=1）才允许 PlayerSpawn 触发护甲；间歇重生不补满
function MissionIntro.ShouldScheduleSpawnArmorOnPlayerSpawn(ply)
	if MissionIntro.IsFakeUpPlayerRespawn(ply) then return false end

	local gm = engine.ActiveGamemode and engine.ActiveGamemode() or ""
	if gm == "sandbox" then return true end

	if zb and isnumber(zb.ROUND_STATE) then
		return zb.ROUND_STATE == 1
	end

	return true
end

function MissionIntro.GetPlayerSupportReinforceFactionId(ply)
	if not IsValid(ply) then return nil end

	local facId = ply:GetNWString("MissionIntro_FactionId", "")
	if facId == "" then
		facId = ply._missionIntroFaction
	end
	if (not isstring(facId) or facId == "") and MissionIntro.GetFactionId then
		facId = MissionIntro.GetFactionId(ply)
	end
	if not isstring(facId) or facId == "" then return nil end
	if MissionIntro.SupportReinforceFactionIds and MissionIntro.SupportReinforceFactionIds[facId] then
		return facId
	end

	return nil
end

function MissionIntro.ClearSupportReinforceSpawnArmor(ply)
	if not IsValid(ply) then return end
	MissionIntro.ClearSpawnArmorLifeState(ply)
	MissionIntro.ResetStoredPlayerArmor(ply)
end

function MissionIntro.BeginNewSpawnArmorRound(opts)
	opts = istable(opts) and opts or {}
	local prevToken = MissionIntro._spawnArmorRoundToken or 0
	MissionIntro._spawnArmorRoundToken = prevToken + 1

	-- hmcd 等：只换回合 token，勿 PreRound 全员 ZHEV/SCP 扫描（与 HMCD 开局叠在一起会卡）
	if opts.light then
		for _, ply in ipairs(player.GetAll()) do
			if not IsValid(ply) or not ply:IsPlayer() then continue end
			local hadRoundArmor = ply._miSpawnArmorRoundToken == prevToken
			local reinforceFac = MissionIntro.GetPlayerSupportReinforceFactionId
				and MissionIntro.GetPlayerSupportReinforceFactionId(ply)
			if hadRoundArmor or reinforceFac then
				if MissionIntro.ClearSupportReinforceSpawnArmor then
					MissionIntro.ClearSupportReinforceSpawnArmor(ply)
				else
					MissionIntro.ClearSpawnArmorLifeState(ply)
					MissionIntro.ResetStoredPlayerArmor(ply)
				end
			end
		end
		return
	end

	for _, ply in ipairs(player.GetAll()) do
		if not IsValid(ply) or not ply:IsPlayer() then continue end
		ply._miSpawnArmorRoundToken = nil
		MissionIntro.CancelScheduledSpawnArmor(ply)
		MissionIntro.ResetStoredPlayerArmor(ply)
		if MissionIntro.StripFacilityScpWeapons then
			MissionIntro.StripFacilityScpWeapons(ply)
		end
	end

	if MissionIntro.ClearFacilityScpGearForNonScpPlayers then
		MissionIntro.ClearFacilityScpGearForNonScpPlayers()
	end
end

function MissionIntro.ScheduleSpawnArmorRefreshForAll(delay)
	delay = tonumber(delay) or 0.5
	timer.Simple(delay, function()
		for _, ply in ipairs(player.GetAll()) do
			if not IsValid(ply) or not ply:IsPlayer() then continue end
			if MissionIntro.RefreshSpawnArmorForPlayer then
				MissionIntro.RefreshSpawnArmorForPlayer(ply)
			end
		end
	end)
end

function MissionIntro.IsFakeUpPlayerRespawn(ply)
	if not IsValid(ply) then return false end
	if ply._miFakeUpRespawning then return true end

	local lastUp = tonumber(ply.LastFakeUp)
	if lastUp and (CurTime() - lastUp) < 2.5 then
		return true
	end

	return false
end

function MissionIntro.ShouldGrantSpawnArmorNow(ply, opts)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	opts = opts or {}

	if opts.force then return true end
	if MissionIntro.IsFakeUpPlayerRespawn(ply) then return false end
	if MissionIntro.HasSpawnArmorForCurrentRound(ply) then return false end

	return true
end

function MissionIntro.ApplyExtendedSpawnArmor(ply, amount)
	if not IsValid(ply) or not ply:IsPlayer() then return false end

	amount = math.max(0, math.floor(tonumber(amount) or 0))
	if amount <= 0 then return false end

	if ZHEV and ZHEV.SetPlayerMaxArmor and ZHEV.SetPlayerArmor then
		ZHEV.SetPlayerMaxArmor(ply, amount)
		ZHEV.SetPlayerArmor(ply, amount)
		return true
	end

	if amount > 255 then
		MI_LogArmor(string.format("%s 需要 %d 护甲但 ZHEV 未加载，已截断为 255", ply:Nick(), amount))
	end

	ply:SetMaxArmor(math.min(amount, 255))
	ply:SetArmor(math.min(amount, 255))
	return true
end

function MissionIntro.GetFactionRoleSpawnArmor(ply)
	if MissionIntro.GetPlayerSpawnArmor then
		return MissionIntro.GetPlayerSpawnArmor(ply)
	end
	return nil
end

function MissionIntro.ApplyFactionRoleSpawnArmor(ply, opts)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if not MissionIntro.ShouldGrantSpawnArmorNow(ply, opts) then return false end

	local armor = MissionIntro.GetFactionRoleSpawnArmor(ply)
	if not armor or armor <= 0 then return false end

	local ok = MissionIntro.ApplyExtendedSpawnArmor(ply, armor)
	if ok then
		MissionIntro.MarkSpawnArmorApplied(ply)
		local facId = MissionIntro.GetFactionId and MissionIntro.GetFactionId(ply) or "?"
		MI_LogArmor(string.format("%s [%s] 回合护甲 %d", ply:Nick(), facId, armor))
	end

	return ok
end

-- 入场发奖 / 回合开始时强制按职阶重发（先清零残留 ZHEV 护甲）
function MissionIntro.RefreshSpawnArmorForPlayer(ply, opts)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if not MissionIntro.ShouldApplySpawnArmor or not MissionIntro.ShouldApplySpawnArmor(ply) then return false end

	opts = opts or {}
	MissionIntro.CancelScheduledSpawnArmor(ply)

	if opts.resetFirst ~= false then
		MissionIntro.ResetStoredPlayerArmor(ply)
	end

	if MissionIntro.GetFacilityScpConfiguredSpawnArmor then
		local scpArmor = MissionIntro.GetFacilityScpConfiguredSpawnArmor(ply)
		if scpArmor and scpArmor > 0 and MissionIntro.ApplyFacilityScpSpawnArmor then
			return MissionIntro.ApplyFacilityScpSpawnArmor(ply, { force = true, resetFirst = false }) == true
		end
	end

	return MissionIntro.ApplyFactionRoleSpawnArmor(ply, { force = true }) == true
end

function MissionIntro.TryApplySpawnArmorNow(ply, opts)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if not MissionIntro.ShouldApplySpawnArmor or not MissionIntro.ShouldApplySpawnArmor(ply) then return false end
	if not MissionIntro.ShouldGrantSpawnArmorNow(ply, opts) then return false end

	local armor = MissionIntro.GetPlayerSpawnArmor and MissionIntro.GetPlayerSpawnArmor(ply)
	if not armor or armor <= 0 then return false end

	return MissionIntro.ApplyFactionRoleSpawnArmor(ply, opts) == true
end

function MissionIntro.SchedulePlayerSpawnArmor(ply, delays, opts)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if not MissionIntro.ShouldGrantSpawnArmorNow(ply, opts) then return end

	delays = delays or MissionIntro.SPAWN_ARMOR_RETRY_DELAYS
	local token = (ply._miSpawnArmorToken or 0) + 1
	ply._miSpawnArmorToken = token

	for attempt, delay in ipairs(delays) do
		timer.Simple(delay, function()
			if not IsValid(ply) then return end
			if ply._miSpawnArmorToken ~= token then return end
			if not MissionIntro.ShouldApplySpawnArmor or not MissionIntro.ShouldApplySpawnArmor(ply) then return end
			if not MissionIntro.ShouldGrantSpawnArmorNow(ply, opts) then return end

			local armor = MissionIntro.GetPlayerSpawnArmor and MissionIntro.GetPlayerSpawnArmor(ply)
			if armor and armor > 0 then
				if attempt == 1 then
					MissionIntro.ResetStoredPlayerArmor(ply)
				end
				MissionIntro.ApplyFactionRoleSpawnArmor(ply, opts)
			end
		end)
	end
end

MissionIntro.ScheduleFactionRoleSpawnArmor = MissionIntro.SchedulePlayerSpawnArmor
MissionIntro.ApplyHammerfallSpawnArmor = MissionIntro.ApplyFactionRoleSpawnArmor
MissionIntro.ScheduleHammerfallSpawnArmor = MissionIntro.SchedulePlayerSpawnArmor

hook.Add("PlayerSpawn", "MissionIntro_FactionRoleSpawnArmor", function(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if MissionIntro.ShouldRunHeavyPlayerSpawnHooks and not MissionIntro.ShouldRunHeavyPlayerSpawnHooks(ply) then
		return
	end

	local facilityRound = MissionIntro.ShouldRunFacilityScpRoundMaintenance
		and MissionIntro.ShouldRunFacilityScpRoundMaintenance()
	local wantsArmor = MissionIntro.ShouldApplySpawnArmor and MissionIntro.ShouldApplySpawnArmor(ply)
	if not facilityRound and not wantsArmor then return end

	-- Homigrad 假死起身会 OverrideSpawn + Spawn()；勿清零万甲（否则 ZHEV 默认上限 500 盖掉 15000）
	if MissionIntro.IsFakeUpPlayerRespawn and MissionIntro.IsFakeUpPlayerRespawn(ply) then
		MissionIntro.CancelScheduledSpawnArmor(ply)
		return
	end

	-- 上一命残甲/SCP 万甲会留在 NW；每命重生先清，再按职阶重发（与是否同一回合无关）
	local hadExtended = ply:GetNWBool("ZHEV_Extended", false)
	local hadArmor = (tonumber(ply:Armor()) or 0) > 0
	if hadExtended or hadArmor then
		MissionIntro.ResetStoredPlayerArmor(ply)
	end
	ply._miSpawnArmorRoundToken = nil
	MissionIntro.CancelScheduledSpawnArmor(ply)

	if not MissionIntro.ShouldScheduleSpawnArmorOnPlayerSpawn(ply) then return end

	if MissionIntro.ShouldApplySpawnArmor and MissionIntro.ShouldApplySpawnArmor(ply) then
		MissionIntro.SchedulePlayerSpawnArmor(ply)
	end
end)

hook.Add("PlayerSpawn", "MissionIntro_FacilityScpSpawnArmorAfterZhev", function(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if not MissionIntro.GetFacilityScpConfiguredSpawnArmor then return end
	if not MissionIntro.GetFacilityScpConfiguredSpawnArmor(ply) then return end

	-- ZHEV_Init(0.1s) 会保留上一命 NW 万甲上限；SCP 护甲在 0.15s 后强制按职阶重发
	timer.Simple(0.15, function()
		if not IsValid(ply) then return end
		if MissionIntro.ScheduleFacilityScpSpawnArmorRefresh then
			MissionIntro.ScheduleFacilityScpSpawnArmorRefresh(ply)
		elseif MissionIntro.ApplyFacilityScpSpawnArmor then
			MissionIntro.ApplyFacilityScpSpawnArmor(ply, { force = true })
		end
	end)
end)

hook.Add("Fake Up", "MissionIntro_NoSpawnArmorOnFakeUp", function(ply)
	if not IsValid(ply) then return end

	ply._miFakeUpRespawning = true
	MissionIntro.CancelScheduledSpawnArmor(ply)

	-- 与 LastFakeUp 窗口对齐，覆盖 ZHEV_Init(0.1s) 与其它延迟 Spawn 逻辑
	timer.Simple(2.5, function()
		if IsValid(ply) then
			ply._miFakeUpRespawning = false
		end
	end)
end)

hook.Add("PlayerDeath", "MissionIntro_ClearSpawnArmorOnDeath", function(ply)
	if not IsValid(ply) then return end
	MissionIntro.ClearSpawnArmorLifeState(ply)
	MissionIntro.ResetStoredPlayerArmor(ply)
	-- 部分模式死亡当帧其它逻辑会再写 ZHEV，下一帧再清一次
	timer.Simple(0, function()
		if IsValid(ply) then
			MissionIntro.ResetStoredPlayerArmor(ply)
		end
	end)
end)

local MI_ROUND_ARMOR_HOOKS = {
	"ZB_EndRound",
	"ZB_PreRoundStart",
	"RoundStart",
	"Breach_NewRound",
	"OnNewRound",
	"HMCD_NewRound",
	"HomigradRoundStart",
}

for _, hookName in ipairs(MI_ROUND_ARMOR_HOOKS) do
	hook.Add(hookName, "MissionIntro_ResetSpawnArmorRound", function()
		local upcoming = MissionIntro.GetZCityUpcomingMode and MissionIntro.GetZCityUpcomingMode() or ""
		local light = not (MissionIntro.ShouldRunFacilityScpRoundMaintenance
			and MissionIntro.ShouldRunFacilityScpRoundMaintenance(upcoming))
		MissionIntro.BeginNewSpawnArmorRound({ light = light })
	end)
end

hook.Add("ZB_StartRound", "MissionIntro_SpawnArmorAfterRoundStart", function()
	if not MissionIntro.ShouldRunFacilityScpRoundMaintenance() then return end
	MissionIntro.ScheduleSpawnArmorRefreshForAll(0.75)
end)
