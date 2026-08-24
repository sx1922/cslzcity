TOOL.Category = "RX MC&D"
TOOL.Name = "MC&D 撤离点"
TOOL.Command = nil
TOOL.Information = {
	{ name = "left", text = "放置 MC&D 撤离点" },
	{ name = "right", text = "删除撤离点" },
	{ name = "reload", text = "清除全部撤离点" },
}

TOOL.ClientConVar["yaw"] = "0"
TOOL.ClientConVar["radius"] = "140"

local function MI_CanUseTool(ply)
	if not IsValid(ply) then return false end
	if MissionIntro and MissionIntro.CanManage then return MissionIntro.CanManage(ply) end
	return ply:IsAdmin()
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end
	if not trace or not trace.Hit then return false end

	local yaw = trace.HitNormal:Angle().y + self:GetClientNumber("yaw", 0)
	local pos = MissionIntro.ComputeUiuToolSpawnPos and MissionIntro.ComputeUiuToolSpawnPos(trace) or (trace.HitPos + trace.HitNormal * 2)
	local ang = Angle(0, yaw, 0)
	local radius = self:GetClientNumber("radius", 140)

	if MissionIntro.CreateMcdEvac then
		MissionIntro.CreateMcdEvac(pos, ang, radius, false)
		return true
	end
	return false
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end
	local ent = trace and trace.Entity
	if IsValid(ent) and ent:GetClass() == "ent_mission_intro_mcd_evac" then
		ent:Remove()
		MissionIntro.SaveMcdPlaced("evac")
		return true
	end
	return false
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end
	if MissionIntro.RemoveAllMcd then MissionIntro.RemoveAllMcd("evac", true) end
	return true
end

function TOOL.BuildCPanel(panel)
	panel:NumSlider("方形半边长", "mission_intro_mcd_evac_radius", 64, 400, 0)
	panel:Help("撤离区为水平正方形，滑条数值 = 中心到边的距离。")
	panel:NumSlider("朝向偏移", "mission_intro_mcd_evac_yaw", -180, 180, 0)
end

if CLIENT then
	language.Add("tool.mission_intro_mcd_evac.name", "MC&D 撤离点")
end
