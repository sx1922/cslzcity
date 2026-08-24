ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "MC&D 撤离点"
ENT.Author = "RX Mission Intro"
ENT.Category = "RX / MC&D"
ENT.Spawnable = false
ENT.AdminOnly = true

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "EvacProgress")
	self:NetworkVar("Float", 1, "EvacZoneRadius")
	self:NetworkVar("Entity", 0, "EvacuatingPlayer")
end
