AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	local mdl = (MissionIntro and MissionIntro.SpawnPreviewModel) or "models/Mechanics/gears2/bevel_18t1.mdl"
	self:SetModel(mdl)

	local scale = (MissionIntro and MissionIntro.SpawnPreviewScale) or 2
	if self.SetModelScale then
		self:SetModelScale(scale, 0)
	end

	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:SetUseType(SIMPLE_USE)

	self:SetNoDraw(true)
	self:DrawShadow(false)

	if MissionIntro and MissionIntro.RenumberSpawnPoints then
		MissionIntro.RenumberSpawnPoints()
	end
end

function ENT:OnRemove()
	if MissionIntro and MissionIntro.RenumberSpawnPoints and not MissionIntro._loadingSpawns then
		timer.Simple(0, function()
			if MissionIntro._loadingSpawns or MissionIntro._suppressSpawnSave then return end
			MissionIntro.RenumberSpawnPoints()
		end)
	end
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end
	if MissionIntro and MissionIntro.CanManage and not MissionIntro.CanManage(activator) then return end
	self:Remove()
	if MissionIntro and MissionIntro.RequestSaveSpawnPoints then
		MissionIntro.RequestSaveSpawnPoints()
	end
end
