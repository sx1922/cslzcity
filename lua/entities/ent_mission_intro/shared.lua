ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "任务入场终端"
ENT.Author = "RX Mission Intro"
ENT.Category = "RX / SCP"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.RenderGroup = RENDERGROUP_OPAQUE

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Busy")
end
