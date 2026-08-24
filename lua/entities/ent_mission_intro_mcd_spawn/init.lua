AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel(MissionIntro.McdModel or "models/cultist/humans/obr/obr.mdl")
	self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 72))
	self:SetUseType(SIMPLE_USE)

	if MissionIntro.McdRoleBodygroups and MissionIntro.McdRoleBodygroups.captain then
		for bgId, val in pairs(MissionIntro.McdRoleBodygroups.captain) do
			self:SetBodygroup(tonumber(bgId) or 0, tonumber(val) or 0)
		end
	end
end

function ENT:Use(activator)
	if IsValid(activator) and activator:IsPlayer() then
		activator:ChatPrint(MissionIntro.L and MissionIntro.L("mcd_spawn_hint") or "[MC&D] 战术响应出生点")
	end
end
