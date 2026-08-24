-- Open Defibs × Z-City/Homigrad：不生成插件自带尸体，除颤目标用 RagdollDeath；覆盖成功率/窗口/冷却
if not SERVER then return end

MissionIntro = MissionIntro or {}

local MI_BRIDGE_INSTALLED = false

local function MI_GetHomigradDeathRag(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return nil end
	local rag = ply.RagdollDeath
	if not IsValid(rag) then rag = ply:GetNWEntity("RagdollDeath") end
	if IsValid(rag) then return rag end
	if hg and hg.RagdollOwner then
		for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
			if IsValid(ent) and hg.RagdollOwner(ent) == ply then
				return ent
			end
		end
	end
	return nil
end

local function MI_ShouldRegisterDefibTarget(ply)
	if not IsValid(ply) or not ply:IsPlayer() or ply:Alive() then return false end
	if MissionIntro.RXSendIsActive and MissionIntro.RXSendIsActive() then return false end
	if MissionIntro.IsFacilityScpPlayer and MissionIntro.IsFacilityScpPlayer(ply) then return false end
	if MissionIntro.ShouldApplyFacilityScpGameplayRules
		and MissionIntro.ShouldApplyFacilityScpGameplayRules(ply) then
		return false
	end
	return true
end

local function MI_TagRagdollForDefib(rag, ply)
	if not IsValid(rag) or not IsValid(ply) then return end
	rag.GrimOD_Owner = ply
	rag:SetNWEntity("GrimOD_Owner", ply)
	ply.GrimOD_Ragdoll = rag
end

local function MI_RegisterDefibBody(ply, rag)
	local G = grimothys_opendefibs
	if not G or not MI_ShouldRegisterDefibTarget(ply) or not IsValid(rag) then return false end

	local CONFIG = G.CONFIG or {}
	MI_TagRagdollForDefib(rag, ply)

	G.ActiveBodies = G.ActiveBodies or {}
	G.ActiveBodies[ply] = {
		ragdoll = rag,
		expiryTime = CurTime() + (tonumber(CONFIG.defibWindow) or 120),
		startTime = CurTime(),
		zcityRag = true,
	}

	ply.GrimOD_RespawnTime = CurTime() + (tonumber(CONFIG.respawnDelay) or 5)
	return true
end

local function MI_TryRegisterDefibBody(ply, rag)
	if MI_RegisterDefibBody(ply, rag) then return true end
	rag = rag or MI_GetHomigradDeathRag(ply)
	return MI_RegisterDefibBody(ply, rag)
end

local function MI_ScheduleDefibRegistration(ply)
	if not MI_ShouldRegisterDefibTarget(ply) then return end
	for _, delay in ipairs({ 0, 0.05, 0.15, 0.5 }) do
		timer.Simple(delay, function()
			if not IsValid(ply) or ply:Alive() then return end
			MI_TryRegisterDefibBody(ply, nil)
		end)
	end
end

local function MI_RemoveGrimODRagdoll(rag, ply)
	if not IsValid(rag) then return end
	if rag._miRxDeathCorpse then
		rag._miRxAllowRemove = true
		if MissionIntro.RemoveRXSendCorpse then
			MissionIntro.RemoveRXSendCorpse(rag, ply)
			return
		end
	end
	rag:Remove()
end

function MissionIntro.MI_InstallOpenDefibsZcityBridge()
	if MI_BRIDGE_INSTALLED or not grimothys_opendefibs then return false end

	local G = grimothys_opendefibs
	G.CONFIG = G.CONFIG or {}

	G.CONFIG.successChance = 0.8
	G.CONFIG.defibWindow = 120
	G.CONFIG.defibCooldown = 15
	G.CONFIG.consumeDefibOnSuccess = true
	G.CONFIG.autoRespawnAfterExpiry = false

	hook.Remove("DoPlayerDeath", "grimothys_opendefibs_HandleDeath")
	hook.Remove("PlayerPostThink", "grimothys_opendefibs_RemoveDefaultRagdoll")
	hook.Remove("PlayerSpawn", "grimothys_opendefibs_CleanupOnSpawn")
	hook.Remove("PlayerDisconnected", "grimothys_opendefibs_CleanupOnDisconnect")

	local function MI_CleanupDefibBody(ply)
		local data = G.ActiveBodies and G.ActiveBodies[ply]
		if not data then return end
		if not data.zcityRag and IsValid(data.ragdoll) then
			data.ragdoll:Remove()
		end
		G.ActiveBodies[ply] = nil
	end

	hook.Add("PlayerSpawn", "MissionIntro_OpenDefibsZcityCleanupOnSpawn", function(ply)
		MI_CleanupDefibBody(ply)
		if IsValid(ply) then
			ply.GrimOD_Ragdoll = nil
			ply.GrimOD_RespawnTime = nil
		end
	end)

	local origExpireBody = G.ExpireBody
	function G.ExpireBody(ply, data)
		if istable(data) and data.zcityRag then
			G.ActiveBodies[ply] = nil
			if IsValid(ply) then
				net.Start("grimothys_opendefibs_ExpireBody")
				net.Send(ply)
				-- Z-City：除颤窗口结束后仅标记不可救，不 Spawn；玩家继续观战至回合结束
			end
			return
		end
		if isfunction(origExpireBody) then
			return origExpireBody(ply, data)
		end
	end

	local origSuccessfulDefib = G.SuccessfulDefib
	function G.SuccessfulDefib(medic, target, bodyData)
		if not istable(bodyData) or not bodyData.zcityRag then
			if isfunction(origSuccessfulDefib) then
				return origSuccessfulDefib(medic, target, bodyData)
			end
			return
		end

		G.ActiveBodies[target] = nil

		local pos = IsValid(bodyData.ragdoll) and bodyData.ragdoll:GetPos() or target:GetPos()
		local rag = bodyData.ragdoll

		if IsValid(rag) then
			MI_RemoveGrimODRagdoll(rag, target)
		end

		target:Spawn()
		target:SetPos(pos)

		if isfunction(G.RestorePlayerEquipment) then
			G.RestorePlayerEquipment(target)
		end

		local percent = tonumber(G.CONFIG.revivalHealthPercent) or 0.5
		local delay = G.ActiveProfile and G.ActiveProfile.healthSetDelay or 0.1
		timer.Simple(delay, function()
			if not IsValid(target) then return end
			local health = math.max(1, math.floor(target:GetMaxHealth() * percent))
			target:SetHealth(health)
		end)

		target:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
		timer.Simple(2, function()
			if IsValid(target) then
				target:SetCollisionGroup(COLLISION_GROUP_PLAYER)
			end
		end)

		if G.CONFIG.enableSounds and IsValid(medic) then
			medic:EmitSound(G.CONFIG.sounds.shock)
			timer.Simple(1, function()
			 if IsValid(medic) then
					medic:EmitSound(G.CONFIG.sounds.recharge)
				end
			end)
		end

		if istable(target.organism) then
			target.organism.alive = true
			target.organism.otrub = false
			target.organism.needotrub = false
			target.organism.fake = false
			target.organism.needfake = false
		end

		hook.Run("grimothys_opendefibs_PlayerRevived", target, medic)
		if isfunction(G.ConsumeMedicDefib) then
			G.ConsumeMedicDefib(medic)
		end
	end

	function G.CreatePlayerRagdoll(ply)
		return MI_GetHomigradDeathRag(ply)
	end

	hook.Add("DoPlayerDeath", "MissionIntro_OpenDefibsZcityStoreGear", function(ply)
		if not grimothys_opendefibs or not IsValid(ply) then return end
		if isfunction(G.StorePlayerEquipment) then
			G.StorePlayerEquipment(ply)
		end
	end, 100)

	hook.Add("PlayerDisconnected", "MissionIntro_OpenDefibsZcityCleanupOnDisconnect", function(ply)
		MI_CleanupDefibBody(ply)
		if G.Cooldowns then
			G.Cooldowns[ply] = nil
		end
	end)

	hook.Add("RagdollDeath", "MissionIntro_OpenDefibsZcityRegister", function(ply, rag)
		if not grimothys_opendefibs then return end
		MI_TryRegisterDefibBody(ply, rag)
	end, -500)

	hook.Add("PostPlayerDeath", "MissionIntro_OpenDefibsZcityRegister", function(ply)
		if not grimothys_opendefibs then return end
		MI_ScheduleDefibRegistration(ply)
	end, 2)

	MI_BRIDGE_INSTALLED = true
	print("[MissionIntro] 开放除颤器已对接 Z-City 尸体（80% / 120s / 15s 冷却 / 一次性）")
	return true
end

hook.Add("InitPostEntity", "MissionIntro_OpenDefibsZcityBridge", function()
	timer.Simple(0, function()
		MissionIntro.MI_InstallOpenDefibsZcityBridge()
	end)
end)

timer.Create("MissionIntro_OpenDefibsZcityBridge", 1, 0, function()
	if MI_BRIDGE_INSTALLED then
		timer.Remove("MissionIntro_OpenDefibsZcityBridge")
		return
	end
	MissionIntro.MI_InstallOpenDefibsZcityBridge()
end)
