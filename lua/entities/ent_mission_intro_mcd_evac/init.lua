AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	local cfg = MissionIntro.Mcd or {}
	self:SetModel(cfg.evac_model or "models/props_combine/combine_interface001.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:Sleep()
	end

	self:SetEvacProgress(0)
	self:SetEvacuatingPlayer(NULL)
	self._evacStart = 0
	self:SetEvacZoneRadius(tonumber(cfg.evac_zone_radius) or 140)
end

function ENT:GetZoneRadius()
	return math.Clamp(tonumber(self:GetEvacZoneRadius()) or 140, 64, 400)
end

function ENT:GetPlayersInZone()
	local list = {}
	local center = self:GetPos()
	local half = self:GetZoneRadius()
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:Alive() and MissionIntro.IsPlayerInEvacSquare(ply, center, half) then
			list[#list + 1] = ply
		end
	end
	return list
end

function ENT:CancelEvac()
	self._evacStart = 0
	self:SetEvacProgress(0)
	self:SetEvacuatingPlayer(NULL)
end

function ENT:GetEvacDuration()
	local cfg = MissionIntro.Mcd or {}
	return tonumber(cfg.evac_zone_duration)
		or tonumber(cfg.evac_solo_duration)
		or tonumber(cfg.evac_employer_duration)
		or 5
end

function ENT:CompleteEvac(ply)
	self:CancelEvac()
	if not IsValid(ply) then return end

	if MissionIntro.IsEmployerPlayer(ply) and MissionIntro.BroadcastMcdEmployerEvacuated then
		MissionIntro.BroadcastMcdEmployerEvacuated()
	end

	if MissionIntro.ExecuteMcdEvacuation then
		MissionIntro.ExecuteMcdEvacuation(ply, self)
	end
end

function ENT:Think()
	self:NextThink(CurTime() + 0.1)

	local dur = self:GetEvacDuration()
	local evacPly = self:GetEvacuatingPlayer()

	if IsValid(evacPly) and evacPly:Alive() and self._evacStart > 0 then
		local stillIn = false
		for _, p in ipairs(self:GetPlayersInZone()) do
			if p == evacPly then stillIn = true break end
		end

		if not stillIn then
			self:CancelEvac()
			return true
		end

		if MissionIntro.CanMcdPlayerEvacuate and not MissionIntro.CanMcdPlayerEvacuate(evacPly) then
			self:CancelEvac()
			return true
		end

		local frac = math.Clamp((CurTime() - self._evacStart) / dur, 0, 1)
		self:SetEvacProgress(frac)
		if frac >= 1 then
			self:CompleteEvac(evacPly)
		end
		return true
	end

	if self._evacStart <= 0 then
		local inZone = self:GetPlayersInZone()
		local picked

		local menuEmployer = MissionIntro.GetMcdEmployer and MissionIntro.GetMcdEmployer() or NULL
		if IsValid(menuEmployer) then
			for _, candidate in ipairs(inZone) do
				if candidate == menuEmployer
					and MissionIntro.CanMcdPlayerEvacuate
					and MissionIntro.CanMcdPlayerEvacuate(candidate) then
					picked = candidate
					break
				end
			end
		end

		if not picked then
			for _, candidate in ipairs(inZone) do
				if MissionIntro.IsMcdPlayer and MissionIntro.IsMcdPlayer(candidate)
					and MissionIntro.CanMcdPlayerEvacuate
					and MissionIntro.CanMcdPlayerEvacuate(candidate) then
					picked = candidate
					break
				end
			end
		end

		if not picked then
			for _, candidate in ipairs(inZone) do
				if MissionIntro.CanMcdPlayerEvacuate and MissionIntro.CanMcdPlayerEvacuate(candidate) then
					picked = candidate
					break
				end
			end
		end

		if picked then
			self._evacStart = CurTime()
			self:SetEvacuatingPlayer(picked)
			self:SetEvacProgress(0)
		end
	end

	return true
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end
	local sec = math.floor(self:GetEvacDuration())
	local hint = MissionIntro.L and MissionIntro.L("mcd_evac_hint_free", sec) or ("[MC&D] 进入区域 " .. sec .. " 秒即可撤离。")

	if MissionIntro.IsMenuMcdEmployer and MissionIntro.IsMenuMcdEmployer(activator) then
		activator:ChatPrint(hint)
		return
	end

	if MissionIntro.IsMcdPlayer and MissionIntro.IsMcdPlayer(activator) then
		activator:ChatPrint(hint)
		return
	end

	if MissionIntro.CanMcdPlayerEvacuate and MissionIntro.CanMcdPlayerEvacuate(activator) then
		activator:ChatPrint(hint)
	else
		activator:ChatPrint(MissionIntro.L and MissionIntro.L("mcd_evac_need_employer_or_mcd") or "[MC&D] 仅对讲机雇主与 MC&D 队员可在此撤离。")
	end
end
