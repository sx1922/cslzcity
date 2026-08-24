AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel(self.Model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:Sleep()
	end
end

ENT.LastUse = 0
ENT.NextUse = 0.2

function ENT:Think()
	if self.LastUse + self.NextUse > CurTime() then
		self:SetSequence(3)
	else
		self:SetSequence(2)
	end

	self:NextThink(CurTime())
	return true
end

function ENT:Use(activator)
	if not SCPWarhead or not SCPWarhead.CancelDetonation then return end
	if self.LastUse + self.NextUse > CurTime() then return end
	self.LastUse = CurTime()

	if hook.Run("SCPWarhead_CanCancelDetonation", activator, self) == false then return end

	SCPWarhead:CancelDetonation(false, false, activator)
end

function ENT:PhysgunPickup(ply)
	return IsValid(ply) and ply:IsAdmin()
end

function ENT:OnRemove()
	if not MissionIntro or not MissionIntro.CanSaveOmegaWarheadEntities then return end
	if not MissionIntro.CanSaveOmegaWarheadEntities() then return end
	if MissionIntro.RequestSaveOmegaWarheadEntities then
		MissionIntro.RequestSaveOmegaWarheadEntities()
	end
end
