ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "ETT 战术面板"
ENT.Author = "RX Mission Intro"
ENT.Category = "RX ETT"
ENT.Spawnable = false
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "DangerLevel")
	self:NetworkVar("Bool", 0, "ReinforcementsCalled")
	self:NetworkVar("Float", 1, "ReinforcementsEta")
end
