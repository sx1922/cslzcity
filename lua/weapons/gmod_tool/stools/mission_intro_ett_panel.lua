TOOL.Category = "RX ETT"
TOOL.Name = "ETT 战术面板"
TOOL.Command = nil
TOOL.Information = {
	{ name = "left", text = "放置 ETT 战术面板" },
	{ name = "right", text = "删除瞄准的面板" },
	{ name = "reload", text = "清除全部面板" },
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

	if MissionIntro.CreateEttPanel then
		MissionIntro.CreateEttPanel(pos, ang, false)
		return true
	end

	return false
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	local ent = trace and trace.Entity
	if IsValid(ent) and ent:GetClass() == "ent_mission_intro_ett_panel" then
		ent:Remove()
		if MissionIntro.RequestSaveEttPanels then
			MissionIntro.RequestSaveEttPanels()
		end
		return true
	end

	return false
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	if MissionIntro.RemoveAllEttPanels then
		MissionIntro.RemoveAllEttPanels(true)
	end

	return true
end

function TOOL.BuildCPanel(panel)
	panel:Help("左键：放置 ETT 区域危险等级战术面板")
	panel:Help("屏幕显示区域危险等级；每名玩家死亡 +12.5%")
	panel:Help("清图 / 新回合会重置为 0%")
	panel:Help("按 E 打开危机指挥 HUD；平民可查看危险等级，ETT 可呼叫增援")
	panel:Help("15 秒后从阵亡玩家里随机复活 3~8 人为落锤作战分队")
	panel:Help("重启服务器或清图后会自动恢复已放置的面板")
	panel:NumSlider("朝向偏移 (Yaw)", "mission_intro_ett_panel_yaw", -180, 180, 0)
end

if CLIENT then
	language.Add("tool.mission_intro_ett_panel.name", "ETT 战术面板")
	language.Add("tool.mission_intro_ett_panel.desc", "放置 ETT 危险等级与增援呼叫面板")
	language.Add("tool.mission_intro_ett_panel.left", "放置面板")
	language.Add("tool.mission_intro_ett_panel.right", "删除面板")
	language.Add("tool.mission_intro_ett_panel.reload", "清除全部")
end
