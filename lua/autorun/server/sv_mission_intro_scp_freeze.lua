MissionIntro = MissionIntro or {}

if not SERVER then return end

util.AddNetworkString("MissionIntro_ScpFreezeCamReset")

local HUMAN_WALK, HUMAN_RUN, HUMAN_SLOW = 100, 350, 60
local RECOVER_SEC = 2.5

local function MI_FreezeTimerName(ply)
	return "MissionIntro_PlayerFreeze_" .. ply:EntIndex()
end

local function MI_ClearLegacyFreezeFields(ply)
	if not IsValid(ply) then return end
	ply.IsFrozen = nil
	ply.FrozenWalkSpeed = nil
	ply.FrozenRunSpeed = nil
	ply.FreezeTimer = nil
	ply._miScpFrozen = nil
	ply._miScpFreezeSave = nil
	ply._miFreezePos = nil
end

local function MI_IsScpFreezeTarget(ply)
	return MissionIntro.IsScpFreezeTarget and MissionIntro.IsScpFreezeTarget(ply)
end

local function MI_NotifyScpFreezeCameraReset(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if not MI_IsScpFreezeTarget(ply) then return end
	net.Start("MissionIntro_ScpFreezeCamReset")
	net.Send(ply)
end

local function MI_EnsureScpViewForFreeze(ply)
	if not MI_IsScpFreezeTarget(ply) then return end
	if MissionIntro.MI_EnsureScpNormalMovement then
		MissionIntro.MI_EnsureScpNormalMovement(ply)
	end
end

local function MI_PinFrozenPosition(ply)
	if not IsValid(ply) or not ply._miFreezePos then return end
	local pos = ply._miFreezePos
	if ply:GetPos():DistToSqr(pos) > 0.01 then
		ply:SetPos(pos)
	end
	if ply.SetNWVector then
		ply:SetNWVector("MissionIntro_ScpFreezePos", pos)
	end
end

local function MI_ClearKatanaSpeedState(ply)
	if not IsValid(ply) then return end
	ply._katanaMoveBuffActive = nil
	ply._katanaHadMoveBuff = nil
	ply._katanaPreSkillWalk = nil
	ply._katanaPreSkillRun = nil
	ply._katanaPreSkillSlow = nil
	ply._katanaPreSkillCrouch = nil
	for _, wep in ipairs(ply:GetWeapons()) do
		if IsValid(wep) and wep:GetClass() == "weapon_katana" and wep.SetKatanaBuffEnd then
			wep:SetKatanaBuffEnd(0)
		end
	end
end

local function MI_ZeroVelocity(ply)
	if not IsValid(ply) then return end
	ply:SetVelocity(vector_origin)
	if ply.GetPhysicsObjectCount and ply:GetPhysicsObjectCount() > 0 then
		for i = 0, ply:GetPhysicsObjectCount() - 1 do
			local phys = ply:GetPhysicsObjectNum(i)
			if IsValid(phys) then
				phys:SetVelocity(vector_origin)
				phys:SetAngleVelocity(vector_origin)
			end
		end
	end
end

local function MI_ApplyHumanMoveSpeeds(ply)
	ply:SetWalkSpeed(HUMAN_WALK)
	ply:SetRunSpeed(HUMAN_RUN)
	ply:SetSlowWalkSpeed(HUMAN_SLOW)
	ply:SetCrouchedWalkSpeed(HUMAN_SLOW)
	ply.CurrentSpeed = HUMAN_WALK
	ply.move = nil
end

local function MI_ApplyScpMoveSpeeds(ply)
	if MissionIntro.ApplyFacilityScpMoveSpeed then
		MissionIntro.ApplyFacilityScpMoveSpeed(ply)
	end
	local walk, run, slow = HUMAN_WALK, HUMAN_RUN, HUMAN_SLOW
	if MissionIntro.GetFacilityScpMoveSpeeds then
		walk, run, slow = MissionIntro.GetFacilityScpMoveSpeeds(ply)
	end
	ply:SetWalkSpeed(walk)
	ply:SetRunSpeed(run)
	ply:SetSlowWalkSpeed(slow)
	ply:SetCrouchedWalkSpeed(slow)
	ply.CurrentSpeed = walk
	ply.move = nil
	if MissionIntro.EnforceFacilityScpMoveSpeed then
		MissionIntro.EnforceFacilityScpMoveSpeed(ply)
	end
end

function MissionIntro.RestoreMovementAfterPlayerFreeze(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	MI_ClearKatanaSpeedState(ply)
	MI_ClearLegacyFreezeFields(ply)
	MI_ZeroVelocity(ply)

	ply:SetMoveType(MOVETYPE_WALK)
	ply:SetJumpPower(160)

	if MissionIntro.IsScpFreezeTarget and MissionIntro.IsScpFreezeTarget(ply) then
		MI_ApplyScpMoveSpeeds(ply)
	else
		MI_ApplyHumanMoveSpeeds(ply)
	end

	ply._miPlayerFrozen = nil
	ply._miScpFreezeRecoverUntil = CurTime() + RECOVER_SEC

	if MissionIntro.ScheduleFacilityScpMoveSpeedRefresh and MissionIntro.IsScpFreezeTarget and MissionIntro.IsScpFreezeTarget(ply) then
		MissionIntro.ScheduleFacilityScpMoveSpeedRefresh(ply)
	end

	for _, delay in ipairs({ 0.08, 0.2, 0.5, 1.0, 1.5 }) do
		timer.Simple(delay, function()
			if not IsValid(ply) or not ply:Alive() then return end
			if MissionIntro.IsPlayerFrozen(ply) then return end
			if ply._miScpFreezeRecoverUntil and CurTime() > ply._miScpFreezeRecoverUntil then return end
			if MissionIntro.IsScpFreezeTarget and MissionIntro.IsScpFreezeTarget(ply) then
				MI_ApplyScpMoveSpeeds(ply)
			else
				MI_ApplyHumanMoveSpeeds(ply)
			end
		end)
	end
end

MissionIntro.RestoreMovementAfterScpFreeze = MissionIntro.RestoreMovementAfterPlayerFreeze

function MissionIntro.EnforcePlayerFreezeMovement(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if not MissionIntro.IsPlayerFrozen(ply) then return end

	-- 勿用 MOVETYPE_NONE：Homigrad/SCP 客户端会把视角拉到地图初始点或假死镜头
	if ply:GetMoveType() ~= MOVETYPE_WALK then
		ply:SetMoveType(MOVETYPE_WALK)
	end
	MI_EnsureScpViewForFreeze(ply)
	MI_PinFrozenPosition(ply)

	ply:SetWalkSpeed(0)
	ply:SetRunSpeed(0)
	ply:SetSlowWalkSpeed(0)
	ply:SetCrouchedWalkSpeed(0)
	ply:SetJumpPower(0)
	ply.CurrentSpeed = 0
	ply.move = nil
	MI_ZeroVelocity(ply)
end

MissionIntro.EnforceScpFreezeMovement = MissionIntro.EnforcePlayerFreezeMovement

function MissionIntro.RemovePlayerFreeze(ply, silent)
	if not IsValid(ply) then return end

	local wasFrozen = MissionIntro.IsPlayerFrozen(ply)

	local timerName = ply._miPlayerFreezeTimer or MI_FreezeTimerName(ply)
	if timer.Exists(timerName) then
		timer.Remove(timerName)
	end
	ply._miPlayerFreezeTimer = nil

	if ply.SetNWBool then
		ply:SetNWBool("MissionIntro_ScpFrozen", false)
	end
	if ply.SetNWVector then
		ply:SetNWVector("MissionIntro_ScpFreezePos", vector_origin)
	end

	if wasFrozen then
		MissionIntro.RestoreMovementAfterPlayerFreeze(ply)
		MI_NotifyScpFreezeCameraReset(ply)
	end

	if ply:IsPlayer() and not silent and wasFrozen then
		ply:ChatPrint("定身效果已结束，你可以移动了")
	end
end

MissionIntro.RemoveScpFreeze = MissionIntro.RemovePlayerFreeze

function MissionIntro.ApplyPlayerFreeze(attacker, target, duration, opts)
	if not IsValid(target) or not target:IsPlayer() then return false end
	opts = opts or {}

	duration = math.max(0.5, tonumber(duration) or MissionIntro.ScpFreezeDuration or 10)

	if opts.requireRxsend and MissionIntro.RXSendIsActive and not MissionIntro.RXSendIsActive() then
		if IsValid(attacker) then attacker:ChatPrint("该技能仅在 RXsend 设施行动中可用") end
		return false
	end

	if opts.requireExpert and MissionIntro.IsCombatExpertPlayer and not MissionIntro.IsCombatExpertPlayer(attacker) then
		if IsValid(attacker) then attacker:ChatPrint("仅战斗专家可使用此技能") end
		return false
	end

	local isScp = MissionIntro.IsScpFreezeTarget(target)
	if opts.requireScp and not isScp then
		if IsValid(attacker) then attacker:ChatPrint("只能对设施 SCP 使用定身") end
		return false
	end
	if opts.humanOnly and isScp then
		if IsValid(attacker) then attacker:ChatPrint("该模式只能定身人类玩家") end
		return false
	end

	if MissionIntro.IsPlayerFrozen(target) then
		MissionIntro.RemovePlayerFreeze(target, true)
	end

	MI_ClearKatanaSpeedState(target)
	if isScp then
		MI_ApplyScpMoveSpeeds(target)
	else
		MI_ApplyHumanMoveSpeeds(target)
	end

	target._miPlayerFrozen = true
	target._miScpFrozen = true
	target.IsFrozen = true
	target._miFreezePos = target:GetPos()
	if target.SetNWBool then
		target:SetNWBool("MissionIntro_ScpFrozen", true)
	end
	if target.SetNWVector then
		target:SetNWVector("MissionIntro_ScpFreezePos", target._miFreezePos)
	end

	MI_EnsureScpViewForFreeze(target)
	MissionIntro.EnforcePlayerFreezeMovement(target)
	MI_NotifyScpFreezeCameraReset(target)

	if IsValid(attacker) and attacker:IsPlayer() then
		if isScp then
			target:ChatPrint("你被九尾狐战斗专家定住了！" .. math.floor(duration) .. " 秒内无法移动")
			attacker:ChatPrint("已定身 SCP：" .. target:Nick() .. "（" .. math.floor(duration) .. " 秒）")
		else
			target:ChatPrint("你被定住了！" .. math.floor(duration) .. " 秒内无法移动")
			attacker:ChatPrint("已定身：" .. target:Nick() .. "（" .. math.floor(duration) .. " 秒）")
		end
	end

	local timerName = MI_FreezeTimerName(target)
	target._miPlayerFreezeTimer = timerName
	timer.Create(timerName, duration, 1, function()
		if IsValid(target) then
			MissionIntro.RemovePlayerFreeze(target)
		end
	end)

	return true
end

function MissionIntro.ApplyScpFreeze(attacker, target, duration)
	return MissionIntro.ApplyPlayerFreeze(attacker, target, duration, {
		requireScp = true,
		requireRxsend = true,
		requireExpert = true,
	})
end

hook.Add("SetupMove", "MissionIntro_PlayerFreezeLock", function(ply, mv, cmd)
	if not MissionIntro.IsPlayerFrozen(ply) then return end
	MissionIntro.EnforcePlayerFreezeMovement(ply)
	if cmd then
		cmd:ClearMovement()
		cmd:ClearButtons()
	end
	if mv then
		mv:SetVelocity(vector_origin)
	end
end)

hook.Add("Player Think", "MissionIntro_PlayerFreezeEnforce", function(ply)
	if not MissionIntro.IsPlayerFrozen(ply) then return end
	MissionIntro.EnforcePlayerFreezeMovement(ply)
end)

hook.Add("FinishMove", "MissionIntro_PlayerFreezeRecover", function(ply, mv)
	if not IsValid(ply) or not ply:Alive() then return end
	if MissionIntro.IsPlayerFrozen(ply) then return end

	local untilT = ply._miScpFreezeRecoverUntil
	if not untilT or CurTime() > untilT then return end

	ply.move = nil

	if MissionIntro.IsScpFreezeTarget and MissionIntro.IsScpFreezeTarget(ply) then
		local walk, run = HUMAN_WALK, HUMAN_RUN
		if MissionIntro.GetFacilityScpMoveSpeeds then
			walk, run = MissionIntro.GetFacilityScpMoveSpeeds(ply)
		end
		if ply:GetRunSpeed() > run + 2 or ply:GetWalkSpeed() > walk + 2 or (ply.CurrentSpeed or 0) > run + 4 then
			MI_ApplyScpMoveSpeeds(ply)
		end
	else
		if ply:GetRunSpeed() > HUMAN_RUN + 2 or (ply.CurrentSpeed or 0) > HUMAN_RUN + 4 then
			MI_ApplyHumanMoveSpeeds(ply)
		end
	end
end)

hook.Add("PlayerSpawn", "MissionIntro_PlayerFreezeCleanup", function(ply)
	ply._miScpFreezeRecoverUntil = nil
	MissionIntro.RemovePlayerFreeze(ply, true)
end)

hook.Add("PlayerDeath", "MissionIntro_PlayerFreezeCleanup", function(ply)
	ply._miScpFreezeRecoverUntil = nil
	MissionIntro.RemovePlayerFreeze(ply, true)
end)

hook.Add("PlayerDisconnected", "MissionIntro_PlayerFreezeCleanup", function(ply)
	MissionIntro.RemovePlayerFreeze(ply, true)
end)

hook.Add("HG_MovementCalc", "MissionIntro_PlayerFreezeMovement", function(vel, velLen, weightmul, ply, cmd, mv)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if not MissionIntro.IsPlayerFrozen(ply) then return end
	ply.CurrentSpeed = 0
	ply.move = nil
end)

-- zhanzhuan 旧版解除定身后会留下 FrozenWalkSpeed 快照 + Homigrad 加速残留
hook.Add("Player Think", "MissionIntro_LegacyFreezeSpeedCleanup", function(ply)
	if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
	if MissionIntro.IsPlayerFrozen(ply) then return end
	if not ply.FrozenWalkSpeed and not ply.FrozenRunSpeed then return end

	ply.FrozenWalkSpeed = nil
	ply.FrozenRunSpeed = nil
	ply.FreezeTimer = nil

	if ply:GetRunSpeed() > HUMAN_RUN + 2 or (ply.CurrentSpeed or 0) > HUMAN_RUN + 4 then
		MI_ApplyHumanMoveSpeeds(ply)
		ply._miScpFreezeRecoverUntil = CurTime() + RECOVER_SEC
	end
end)
