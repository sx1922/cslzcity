AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	local cfg = MissionIntro.UiuEvac or {}
	self:SetModel(cfg.model or "models/props_combine/combine_interface001.mdl")
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

	local evacCfg = MissionIntro.UiuEvac or {}
	self:SetEvacZoneRadius(tonumber(evacCfg.default_zone_radius) or tonumber(evacCfg.use_distance) or 130)
end

function ENT:GetZoneRadius()
	local evacCfg = MissionIntro.UiuEvac or {}
	local minR = tonumber(evacCfg.min_zone_radius) or 64
	local maxR = tonumber(evacCfg.max_zone_radius) or 400
	return math.Clamp(tonumber(self:GetEvacZoneRadius()) or 130, minR, maxR)
end

function ENT:IsPlayerInZone(ply)
	return MissionIntro.IsPlayerInEvacSquare(ply, self:GetPos(), self:GetZoneRadius())
end

function ENT:CancelEvac()
	self._evacStart = 0
	self:SetEvacProgress(0)
	self:SetEvacuatingPlayer(NULL)
end

function ENT:StartEvac(ply)
	if not MissionIntro.CanUiuPlayerEvacuate or not MissionIntro.CanUiuPlayerEvacuate(ply) then
		return false
	end

	self._evacStart = CurTime()
	self:SetEvacuatingPlayer(ply)
	self:SetEvacProgress(0)
	return true
end

function ENT:CompleteEvac(ply)
	self:CancelEvac()
	if MissionIntro.ExecuteUiuEvacuation then
		MissionIntro.ExecuteUiuEvacuation(ply, self)
	end
end

function ENT:Think()
	self:NextThink(CurTime() + 0.1)

	local cfg = MissionIntro.UiuEvac or {}
	local dur = tonumber(cfg.evac_duration) or 10

	local ply = self:GetEvacuatingPlayer()
	if IsValid(ply) and ply:IsPlayer() and ply:Alive() and self._evacStart > 0 then
		if not self:IsPlayerInZone(ply) then
			self:CancelEvac()
		elseif not MissionIntro.CanUiuPlayerEvacuate or not MissionIntro.CanUiuPlayerEvacuate(ply) then
			self:CancelEvac()
		else
			local frac = math.Clamp((CurTime() - self._evacStart) / dur, 0, 1)
			self:SetEvacProgress(frac)
			if frac >= 1 then
				self:CompleteEvac(ply)
			end
		end
		return true
	end

	if self._evacStart <= 0 then
		for _, candidate in ipairs(player.GetAll()) do
			if not IsValid(candidate) or not candidate:Alive() then continue end
			if not self:IsPlayerInZone(candidate) then continue end
			if self:StartEvac(candidate) then
				break
			end
		end
	end

	return true
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end

	if MissionIntro.CanUiuPlayerEvacuate and MissionIntro.CanUiuPlayerEvacuate(activator) then
		local sec = math.floor(tonumber(MissionIntro.UiuEvac.evac_duration) or 10)
		activator:ChatPrint("[UIU] 站在撤离区域内 " .. sec .. " 秒即可自动撤离。")
	elseif MissionIntro.IsUiuPlayer and MissionIntro.IsUiuPlayer(activator) then
		if MissionIntro.UiuEvac.require_mission_complete and not MissionIntro._uiuMissionComplete then
			activator:ChatPrint("[UIU] 完成骇入任务后才能撤离。")
		else
			activator:ChatPrint("[UIU] 进入撤离区域等待倒计时即可撤离。")
		end
	else
		activator:ChatPrint("[UIU] 仅特异事故处成员可从此撤离。")
	end
end

function ENT:PhysgunPickup(ply)
	return false
end

function ENT:GravGunPunt(ply)
	return false
end

function ENT:OnRemove()
	self:CancelEvac()
	if SERVER and MissionIntro.RequestSaveUiuEvacs then
		MissionIntro.RequestSaveUiuEvacs()
	end
end
