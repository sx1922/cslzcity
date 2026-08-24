-- RXsend：玩家死亡后立即清除尸体（与 SCP-912 相同），避免保留模型导致复活/增援仍出现在死亡位置

if not SERVER then return end

MissionIntro = MissionIntro or {}

local function MI_RxsendActive()
	return MissionIntro.RXSendIsActive and MissionIntro.RXSendIsActive()
end

local function MI_GetPlayerDeathRag(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return NULL end
	local rag = ply.RagdollDeath
	if not IsValid(rag) then rag = ply:GetNWEntity("RagdollDeath") end
	return rag
end

local function MI_CollectCorpseEntities(ply, primaryRag)
	local targets = {}
	local seen = {}

	local function add(ent)
		if not IsValid(ent) or seen[ent] then return end
		seen[ent] = true
		targets[#targets + 1] = ent
	end

	add(primaryRag)

	if IsValid(ply) then
		add(ply:GetNWEntity("RagdollDeath"))
		add(ply.FakeRagdoll)
		add(ply.RagdollDeath)
		add(ply.FakeRagdollOld)
		add(ply:GetNWEntity("FakeRagdoll"))
		add(ply:GetNWEntity("FakeRagdollOld"))
	end

	return targets
end

function MissionIntro.RemoveRXSendCorpse(rag, ply)
	if not IsValid(rag) then return end

	if hg then
		if hg.fountains then
			hg.fountains[rag] = nil
			if isfunction(SetNetVar) then
				SetNetVar("fountains", hg.fountains)
			end
		end

		if _G.gib_ragdols then
			_G.gib_ragdols[rag] = nil
		end

		if hg.organism and isfunction(hg.organism.Remove) then
			pcall(hg.organism.Remove, rag)
		end
	end

	if IsValid(ply) and ply:IsPlayer() then
		if ply:GetNWEntity("RagdollDeath") == rag then
			ply:SetNWEntity("RagdollDeath", NULL)
		end
		if ply.FakeRagdoll == rag then
			ply.FakeRagdoll = nil
		end
		if ply.RagdollDeath == rag then
			ply.RagdollDeath = nil
		end
		if ply.FakeRagdollOld == rag then
			ply.FakeRagdollOld = nil
		end
		if ply:GetNWEntity("FakeRagdoll") == rag then
			ply:SetNWEntity("FakeRagdoll", NULL)
		end
		if ply:GetNWEntity("FakeRagdollOld") == rag then
			ply:SetNWEntity("FakeRagdollOld", NULL)
		end
		if hg and hg.ragdollFake then
			hg.ragdollFake[ply] = nil
		end
		ply._miRxCorpseRef = nil
	end

	rag._miRxDeathCorpse = nil
	rag._miRxsendCorpseScheduled = nil
	rag._miRxAllowRemove = true
	rag.override = true
	rag:Remove()
end

function MissionIntro.RemovePlayerCorpseImmediately(ply, primaryRag)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	for _, rag in ipairs(MI_CollectCorpseEntities(ply, primaryRag)) do
		MissionIntro.RemoveRXSendCorpse(rag, ply)
	end
end

local function MI_ShouldInstantRemoveRxsendCorpse(ply)
	if not MI_RxsendActive() then return false end
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if ply._miWasScp912Death then return true end
	if MissionIntro.IsFacilityScp912Player and MissionIntro.IsFacilityScp912Player(ply) == true then
		return true
	end
	if MissionIntro.IsFacilityScpPlayer and MissionIntro.IsFacilityScpPlayer(ply) then
		return false
	end
	return true
end

local function MI_InstantRemoveCorpseNow(ply, primaryRag)
	if not MI_ShouldInstantRemoveRxsendCorpse(ply) then return end
	MissionIntro.RemovePlayerCorpseImmediately(ply, primaryRag)
end

function MissionIntro.ScheduleRXSendCorpseRemoval(ply, primaryRag)
	if not MI_RxsendActive() then return end
	MI_InstantRemoveCorpseNow(ply, primaryRag)
end

hook.Add("RagdollDeath", "MissionIntro_RXSendInstantCorpseRemoval", function(ply, rag)
	MI_InstantRemoveCorpseNow(ply, rag)
end, 1000)

hook.Add("PostPlayerDeath", "MissionIntro_RXSendInstantCorpseRemoval", function(ply)
	if not MI_ShouldInstantRemoveRxsendCorpse(ply) then return end
	for _, delay in ipairs({ 0, 0.05, 0.15 }) do
		timer.Simple(delay, function()
			if IsValid(ply) then
				MI_InstantRemoveCorpseNow(ply, nil)
			end
		end)
	end
end, 1000)

hook.Add("DoPlayerDeath", "MissionIntro_RXSendInstantCorpseRemoval", function(ply)
	if not MI_ShouldInstantRemoveRxsendCorpse(ply) then return end
	timer.Simple(0, function()
		if IsValid(ply) then
			MI_InstantRemoveCorpseNow(ply, ply.FakeRagdoll or ply.RagdollDeath)
		end
	end)
end, -1000)

hook.Add("Ragdoll_Create", "MissionIntro_RXSendInstantCorpseRemoval", function(ply, ragdoll)
	if not MI_ShouldInstantRemoveRxsendCorpse(ply) then return end
	-- 存活玩家的手动 Fake 布娃娃须保留；仅清除死亡尸体
	if IsValid(ply) and ply:Alive() then return end
	if IsValid(ragdoll) then
		ragdoll.override = true
		timer.Simple(0, function()
			if IsValid(ply) then
				MissionIntro.RemoveRXSendCorpse(ragdoll, ply)
			elseif IsValid(ragdoll) then
				ragdoll:Remove()
			end
		end)
	end
end, 1000)

hook.Add("PlayerSpawn", "MissionIntro_RXSendInstantCorpseRemoval", function(ply)
	ply._miWasScp912Death = nil
	if istable(ply.organism) then
		ply.organism.godmode = false
	end
end)

hook.Add("PlayerDisconnected", "MissionIntro_RXSendCorpseCleanup", function(ply)
	if not MI_RxsendActive() then return end
	if not IsValid(ply) then return end

	for _, rag in ipairs(MI_CollectCorpseEntities(ply, nil)) do
		MissionIntro.RemoveRXSendCorpse(rag, ply)
	end
end)

hook.Add("ZB_EndRound", "MissionIntro_RXSendCorpseCleanup", function()
	if not zb or zb.CROUND ~= "rxsend" then return end

	for _, rag in ipairs(ents.FindByClass("prop_ragdoll")) do
		if IsValid(rag) then
			local owner = hg and hg.RagdollOwner and hg.RagdollOwner(rag)
			if IsValid(owner) and owner:IsPlayer() and not owner:Alive() then
				MissionIntro.RemoveRXSendCorpse(rag, owner)
			end
		end
	end
end)
