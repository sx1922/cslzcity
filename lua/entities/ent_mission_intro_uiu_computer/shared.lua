ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "UIU 骇入终端"
ENT.Author = "RX Mission Intro"
ENT.Category = "RX UIU"
ENT.Spawnable = false
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "ScreenState")
	self:NetworkVar("Float", 0, "HackEndTime")
	self:NetworkVar("Entity", 0, "Hacker")
	self:NetworkVar("Bool", 0, "Hackable")
end
