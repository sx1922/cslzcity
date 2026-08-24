TOOL.Category = "RX UIU"
TOOL.Name = "UIU 撤离点"
TOOL.Command = nil
TOOL.Information = {
	{ name = "left", text = "放置 UIU 撤离点" },
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

	if MissionIntro and MissionIntro.CreateUiuEvac then
		MissionIntro.CreateUiuEvac(pos, ang, false, radius)
		return true
	end

	return false
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	local ent = trace and trace.Entity
	if IsValid(ent) and ent:GetClass() == "ent_mission_intro_uiu_evac" then
		if self:GetOwner():KeyDown(IN_SPEED) and ent.SetEvacZoneRadius then
			local radius = self:GetClientNumber("radius", 130)
			ent:SetEvacZoneRadius(MissionIntro.ClampUiuEvacRadius and MissionIntro.ClampUiuEvacRadius(radius) or radius)
			if MissionIntro.RequestSaveUiuEvacs then
				MissionIntro.RequestSaveUiuEvacs()
			end
			self:GetOwner():ChatPrint("[UIU] 已更新撤离点半径为 " .. math.floor(ent:GetZoneRadius()) )
			return true
		end

		ent:Remove()
		if MissionIntro and MissionIntro.RequestSaveUiuEvacs then
			MissionIntro.RequestSaveUiuEvacs()
		end
		return true
	end

	return false
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	if MissionIntro and MissionIntro.RemoveAllUiuEvacs then
		MissionIntro.RemoveAllUiuEvacs(true)
	end

	return true
end

function TOOL.BuildCPanel(panel)
	panel:Help("左键：放置 UIU 撤离点")
	panel:Help("右键：删除撤离点；按住 Shift+右键：按当前半径更新瞄准的撤离点")
	panel:Help("重装：清除全部撤离点")
	panel:Help("仅 UIU 完成骇入后进入撤离区域 10 秒自动撤离；撤离后清除装备并处死。")
	panel:Help("重启服务器或清图后会自动恢复。")
	panel:NumSlider("方形半边长", "mission_intro_uiu_evac_radius", 64, 400, 0)
	panel:Help("撤离区为水平正方形，滑条数值 = 中心到边的距离。")
	panel:NumSlider("朝向偏移 (Yaw)", "mission_intro_uiu_evac_yaw", -180, 180, 0)
	panel:Help("持工具时黄色线框为放置预览，绿色线框为已放置范围。")
end

if CLIENT then
	language.Add("tool.mission_intro_uiu_evac.name", "UIU 撤离点")
	language.Add("tool.mission_intro_uiu_evac.desc", "放置特异事故处撤离点")
	language.Add("tool.mission_intro_uiu_evac.left", "放置撤离点")
	language.Add("tool.mission_intro_uiu_evac.right", "删除撤离点")
	language.Add("tool.mission_intro_uiu_evac.reload", "清除全部")
end
