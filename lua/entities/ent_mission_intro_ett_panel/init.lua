AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	local cfg = MissionIntro.EttPanel or {}
	self:SetModel(cfg.model or "models/props_combine/masterinterface.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:Sleep()
	end

	self:SetDangerLevel(MissionIntro.GetEttDangerLevel and MissionIntro.GetEttDangerLevel() or 0)
	self:SetReinforcementsCalled(MissionIntro._ettReinforcementsCalled == true)
	self:SetReinforcementsEta(tonumber(MissionIntro._ettReinforcementsEta) or 0)
	self:SetColor(Color(255, 255, 255, 255))
end

function ENT:GetUseDistance()
	return tonumber(MissionIntro.EttPanel and MissionIntro.EttPanel.use_distance) or 110
end

function ENT:CanUseDist(ply)
	if not IsValid(ply) then return false end
	return ply:GetPos():DistToSqr(self:GetPos()) <= self:GetUseDistance() ^ 2
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() or not activator:Alive() then return end
	if not self:CanUseDist(activator) then return end

	net.Start("MissionIntro_EttPanelOpen")
		net.WriteEntity(self)
	net.Send(activator)
end

function ENT:Think()
	self:NextThink(CurTime() + 0.5)

	if SERVER and MissionIntro.SyncEttPanels then
		local level = MissionIntro.GetEttDangerLevel and MissionIntro.GetEttDangerLevel() or 0
		if math.abs((self:GetDangerLevel() or 0) - level) > 0.01 then
			self:SetDangerLevel(level)
			self:SetReinforcementsCalled(MissionIntro._ettReinforcementsCalled == true)
			self:SetReinforcementsEta(tonumber(MissionIntro._ettReinforcementsEta) or 0)
		end
	end

	return true
end
