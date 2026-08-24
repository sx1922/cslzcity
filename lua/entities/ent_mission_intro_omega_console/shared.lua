ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "欧米茄弹头控制台"
ENT.Category = "RX 任务入场"
ENT.Spawnable = false
ENT.AdminOnly = false

ENT.Model = "models/props_combine/breenconsole.mdl"

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "WarheadTime", {
		KeyName = "warhead_time",
		Edit = { type = "Combo", order = 1, text = "引爆时间（秒）", values = {
			[80] = "80",
			[90] = "90",
			[100] = "100",
			[110] = "110",
			[120] = "120",
		} },
	})
end
