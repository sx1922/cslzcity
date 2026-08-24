AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	local cfg = MissionIntro.FacilityStatusPanel or {}
	self:SetModel(cfg.model or "models/props_combine/breenconsole.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:Sleep()
	end

	self:SetScienceCount(0)
	self:SetClassDCount(0)
	self:SetUnknownCount(0)
	self:SetScpCount(0)
	self:SetPAActive(false)
	self:SetOperator(NULL)
	self._nextStatusUpdate = 0
end

function ENT:GetUseDistance()
	return tonumber(MissionIntro.FacilityStatusPanel and MissionIntro.FacilityStatusPanel.use_distance) or 140
end

function ENT:CanUseDist(ply)
	if not IsValid(ply) then return false end
	return ply:GetPos():DistToSqr(self:GetPos()) <= self:GetUseDistance() ^ 2
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end
	if not activator:Alive() or not self:CanUseDist(activator) then return end

	net.Start("MissionIntro_FSP_Open")
		net.WriteEntity(self)
	net.Send(activator)
end

function ENT:PhysgunPickup(ply)
	return ply:IsAdmin()
end

function ENT:Think()
	if CurTime() >= (self._nextStatusUpdate or 0) then
		local cfg = MissionIntro.FacilityStatusPanel or {}
		self._nextStatusUpdate = CurTime() + (tonumber(cfg.update_interval) or 0.5)

		if MissionIntro.ComputeFacilityStatusCounts then
			local s, d, scp, u = MissionIntro.ComputeFacilityStatusCounts()
			self:SetScienceCount(s)
			self:SetClassDCount(d)
			self:SetScpCount(scp)
			self:SetUnknownCount(u)
		end
	end

	if self.GetPAActive and self:GetPAActive() then
		local cfg = MissionIntro.FacilityStatusPanel or {}
		local op = self:GetOperator()
		local leave = tonumber(cfg.leave_radius) or 197

		if not IsValid(op) or not op:Alive() then
			if MissionIntro.FacilityPA_Deactivate then
				MissionIntro.FacilityPA_Deactivate(self)
			end
		elseif op:GetPos():DistToSqr(self:GetPos()) > leave * leave then
			if MissionIntro.FacilityPA_Deactivate then
				MissionIntro.FacilityPA_Deactivate(self)
			end
		end
	end

	self:NextThink(CurTime() + 0.25)
	return true
end

function ENT:OnRemove()
	if MissionIntro._activeFacilityPA == self then
		MissionIntro._activeFacilityPA = nil
	end

	if MissionIntro.RequestSaveFacilityStatusPanels then
		MissionIntro.RequestSaveFacilityStatusPanels()
	end
end
