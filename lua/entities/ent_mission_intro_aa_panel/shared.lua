ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "设施防空面板"
ENT.Author = "RX Mission Intro"
ENT.Category = "RX 任务入场"
ENT.Spawnable = false
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "DangerLevel")
	self:NetworkVar("Bool", 0, "AaActive")
	self:NetworkVar("Float", 1, "CiSpawnEta")
end
