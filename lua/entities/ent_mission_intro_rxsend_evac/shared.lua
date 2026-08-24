ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "RXsend 撤离点"
ENT.Author = "RX Mission Intro"
ENT.Category = "RX 任务入场"
ENT.Spawnable = false
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "EvacProgress")
	self:NetworkVar("Entity", 0, "EvacuatingPlayer")
	self:NetworkVar("Float", 1, "EvacZoneRadius")
	self:NetworkVar("Int", 0, "BattleTeam")
end
