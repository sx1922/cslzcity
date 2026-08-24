ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "任务入场出生点"
ENT.Author = "RX Mission Intro"
ENT.Category = "RX / SCP"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "SpawnIndex")
	self:NetworkVar("String", 0, "SpawnFaction")
end
