ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "通用撤离点"
ENT.Author = "RX Mission Intro"
ENT.Category = "RX 任务入场"
ENT.Spawnable = false
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "EvacProgress")
	self:NetworkVar("Entity", 0, "EvacuatingPlayer")
	self:NetworkVar("Float", 1, "EvacZoneRadius")
end
