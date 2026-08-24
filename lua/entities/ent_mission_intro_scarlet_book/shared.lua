ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "猩红祷告书"
ENT.Author = "RX Mission Intro"
ENT.Category = "RX / SCP"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_OPAQUE

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "RitualDone")
	self:NetworkVar("Bool", 1, "BookDestroyed")
	self:NetworkVar("Float", 0, "PrayProgress")
	self:NetworkVar("Float", 1, "SabotageProgress")
	self:NetworkVar("Entity", 0, "PrayingPlayer")
	self:NetworkVar("Entity", 1, "SabotagingPlayer")
	self:NetworkVar("Bool", 2, "RevealToAll")
end
