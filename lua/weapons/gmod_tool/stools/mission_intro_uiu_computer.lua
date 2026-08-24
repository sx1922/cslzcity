TOOL.Category = "RX UIU"
TOOL.Name = "UIU 骇入电脑"
TOOL.Command = nil
TOOL.Information = {
	{ name = "left", text = "放置 UIU 骇入电脑" },
	{ name = "right", text = "删除瞄准的电脑" },
	{ name = "reload", text = "清除全部电脑" },
}

TOOL.ClientConVar["yaw"] = "0"

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

	if MissionIntro and MissionIntro.CreateUiuComputer then
		MissionIntro.CreateUiuComputer(pos, ang, false)
		return true
	end

	return false
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	local ent = trace and trace.Entity
	if IsValid(ent) and ent:GetClass() == "ent_mission_intro_uiu_computer" then
		ent:Remove()
		if MissionIntro and MissionIntro.RequestSaveUiuComputers then
			MissionIntro.RequestSaveUiuComputers()
		end
		return true
	end

	return false
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	if MissionIntro and MissionIntro.RemoveAllUiuComputers then
		MissionIntro.RemoveAllUiuComputers(true)
	end

	return true
end

function TOOL.BuildCPanel(panel)
	panel:Help("左键：放置 UIU 骇入用电脑（建议每张图 5 台）")
	panel:Help("右键：删除瞄准的电脑")
	panel:Help("重装：清除地图上全部电脑")
	panel:Help("重启服务器或清图后会自动恢复已放置的电脑。")
	panel:NumSlider("朝向偏移 (Yaw)", "mission_intro_uiu_computer_yaw", -180, 180, 0)
	panel:Help("可放置多台电脑；每局任务随机指定 5 台可骇入，其余为诱饵。")
	panel:Help("UIU 入场后屏幕变白（可骇入较亮，诱饵偏暗）；按 E 骇入 32 秒变红；全队同时只能骇入一台。")
end

if CLIENT then
	language.Add("tool.mission_intro_uiu_computer.name", "UIU 骇入电脑")
	language.Add("tool.mission_intro_uiu_computer.desc", "放置特异事故处骇入任务电脑")
	language.Add("tool.mission_intro_uiu_computer.left", "放置电脑")
	language.Add("tool.mission_intro_uiu_computer.right", "删除电脑")
	language.Add("tool.mission_intro_uiu_computer.reload", "清除全部")
end
