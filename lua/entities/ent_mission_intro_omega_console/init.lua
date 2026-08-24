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

	local wt = 90
	if self.GetWarheadTime then
		local cur = tonumber(self:GetWarheadTime()) or 0
		if table.HasValue({ 80, 90, 100, 110, 120 }, cur) then
			wt = cur
		end
	end
	if wt == 90 then
		local cv = GetConVar("scpwarhead_time")
		if cv then wt = tonumber(cv:GetInt()) or 90 end
	end
	self:SetWarheadTime(wt)

	if SCPWarhead and ENUM_SCPWARHEAD_ENABLED then
		self.Monitor = ents.Create("warhead-monitor")
		if IsValid(self.Monitor) then
			self.Monitor:SetPos(self:GetPos() + self:GetUp() * 76 + self:GetRight() * -11)
			self.Monitor:SetAngles(self:GetAngles() + Angle(-90, 90, 0))
			self.Monitor:SetParent(self)
			self.Monitor:Spawn()
			self.Monitor:SetSolid(SOLID_NONE)
			self.Monitor:SetMoveType(MOVETYPE_NOCLIP)
		end
	end
end

function ENT:Use(activator)
	if not SCPWarhead or not SCPWarhead.StartCountdown then return end
	if hook.Run("SCPWarhead_CanStartCountdown", activator, self) == false then return end

	SCPWarhead:StartCountdown(self:GetWarheadTime())
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
