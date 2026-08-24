TOOL.Category = "RX 任务入场"
TOOL.Name = "设施终端"
TOOL.Command = nil
TOOL.Information = {
	{ name = "left", text = "放置设施终端" },
	{ name = "right", text = "删除瞄准的终端" },
	{ name = "reload", text = "清除全部终端" },
}

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

	local pos = trace.HitPos + trace.HitNormal * 2
	local ang = trace.HitNormal:Angle()
	ang:RotateAroundAxis(ang:Right(), -90)

	if MissionIntro.CreateFacilityStatusPanel then
		MissionIntro.CreateFacilityStatusPanel(pos, ang, false, trace.HitNormal)
		return true
	end

	return false
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	local ent = trace and trace.Entity
	if IsValid(ent) and ent:GetClass() == "ent_mission_intro_facility_status_panel" then
		ent:Remove()
		if MissionIntro.RequestSaveFacilityStatusPanels then
			MissionIntro.RequestSaveFacilityStatusPanels()
		end
		self:GetOwner():ChatPrint("[MissionIntro] 已删除设施终端（已保存）")
		return true
	end

	return false
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	if MissionIntro.RemoveAllFacilityStatusPanels then
		MissionIntro.RemoveAllFacilityStatusPanels(true)
	end

	self:GetOwner():ChatPrint("[MissionIntro] 已清除全部设施终端")
	return true
end

function TOOL.BuildCPanel(panel)
	if not panel then return end
	panel:Help("设施终端：按 E 打开面板与广播。")
	panel:Help("统计：科研 / D级 / SCP异常 / 未知单位")
	panel:Help("广播：最长 20 秒，冷却 30 秒；拾音范围内语音+文字全图传递")
	panel:Help("位置按地图自动保存。")
end

if CLIENT then
	language.Add("tool.mission_intro_facility_status_panel.name", "设施终端")
	language.Add("tool.mission_intro_facility_status_panel.desc", "放置设施面板 + 广播终端")
	language.Add("tool.mission_intro_facility_status_panel.left", "放置终端")
	language.Add("tool.mission_intro_facility_status_panel.right", "删除终端")
	language.Add("tool.mission_intro_facility_status_panel.reload", "清除全部")
end
