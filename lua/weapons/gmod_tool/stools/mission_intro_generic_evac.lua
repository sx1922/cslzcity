TOOL.Category = "RX 任务入场"
TOOL.Name = "通用撤离点"
TOOL.Command = nil
TOOL.Information = {
	{ name = "left", text = "放置通用撤离点" },
	{ name = "right", text = "删除瞄准的撤离点" },
	{ name = "reload", text = "清除全部撤离点" },
}

TOOL.ClientConVar["yaw"] = "0"
TOOL.ClientConVar["radius"] = "130"

local function MI_CanUseTool(ply)
	if not IsValid(ply) then return false end
	if MissionIntro and MissionIntro.CanManage then
		return MissionIntro.CanManage(ply)
	end
	return ply:IsAdmin()
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end
	if not trace or not trace.Hit then return false end

	local yaw = trace.HitNormal:Angle().y + self:GetClientNumber("yaw", 0)
	local pos = MissionIntro.ComputeUiuToolSpawnPos and MissionIntro.ComputeUiuToolSpawnPos(trace) or (trace.HitPos + trace.HitNormal * 2)
	local ang = Angle(0, yaw, 0)
	local radius = self:GetClientNumber("radius", 130)

	if MissionIntro and MissionIntro.CreateGenericEvac then
		MissionIntro.CreateGenericEvac(pos, ang, false, radius)
		return true
	end

	return false
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	local ent = trace and trace.Entity
	if IsValid(ent) and ent:GetClass() == "ent_mission_intro_generic_evac" then
		if self:GetOwner():KeyDown(IN_SPEED) and ent.SetEvacZoneRadius then
			local radius = self:GetClientNumber("radius", 130)
			ent:SetEvacZoneRadius(MissionIntro.ClampGenericEvacRadius and MissionIntro.ClampGenericEvacRadius(radius) or radius)
			if MissionIntro.RequestSaveGenericEvacs then
				MissionIntro.RequestSaveGenericEvacs()
			end
			self:GetOwner():ChatPrint("[RX] 已更新撤离点半径为 " .. math.floor(ent:GetZoneRadius()))
			return true
		end

		ent:Remove()
		if MissionIntro and MissionIntro.RequestSaveGenericEvacs then
			MissionIntro.RequestSaveGenericEvacs()
		end
		return true
	end

	return false
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	if MissionIntro and MissionIntro.RemoveAllGenericEvacs then
		MissionIntro.RemoveAllGenericEvacs(true)
	end

	return true
end

function TOOL.BuildCPanel(panel)
	panel:Help("左键：放置通用撤离点（无模型，仅显示范围线框）")
	panel:Help("任意存活玩家进入区域 2 秒自动撤离；撤离后清除装备并处死。")
	panel:Help("右键：删除撤离点；Shift+右键：按当前半径更新瞄准的撤离点")
	panel:Help("重装：清除全部撤离点；清图 / 换图后自动恢复。")
	panel:NumSlider("方形半边长", "mission_intro_generic_evac_radius", 64, 400, 0)
	panel:Help("撤离区为水平正方形，滑条数值 = 中心到边的距离。")
	panel:NumSlider("朝向偏移 (Yaw)", "mission_intro_generic_evac_yaw", -180, 180, 0)
	panel:Help("保存路径：data/rx_mission_intro/generic_evacs/当前地图.json")
end

if CLIENT then
	language.Add("tool.mission_intro_generic_evac.name", "通用撤离点")
	language.Add("tool.mission_intro_generic_evac.desc", "放置全员可用的通用撤离区域")
	language.Add("tool.mission_intro_generic_evac.left", "放置撤离点")
	language.Add("tool.mission_intro_generic_evac.right", "删除撤离点")
	language.Add("tool.mission_intro_generic_evac.reload", "清除全部")
end
