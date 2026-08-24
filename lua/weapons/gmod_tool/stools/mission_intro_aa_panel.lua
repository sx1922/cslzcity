TOOL.Category = "RX 任务入场"
TOOL.Name = "设施防空面板"
TOOL.Command = nil
TOOL.Information = {
	{ name = "left", text = "放置设施防空面板" },
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

	if not MissionIntro.CreateAaPanel then
		self:GetOwner():ChatPrint("[MissionIntro] 防空面板未加载，请 lua_refresh 或重启地图")
		return false
	end

	local ent = MissionIntro.CreateAaPanel(pos, ang, false)
	if IsValid(ent) then
		self:GetOwner():ChatPrint("[MissionIntro] 已放置设施防空面板")
		return true
	end

	self:GetOwner():ChatPrint("[MissionIntro] 放置失败，请查看服务器控制台")
	return false
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	local ent = trace and trace.Entity
	if IsValid(ent) and ent:GetClass() == "ent_mission_intro_aa_panel" then
		ent:Remove()
		if MissionIntro.RequestSaveAaPanels then
			MissionIntro.RequestSaveAaPanels()
		end
		return true
	end

	return false
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	if MissionIntro.RemoveAllAaPanels then
		MissionIntro.RemoveAllAaPanels(true)
	end

	return true
end

function TOOL.BuildCPanel(panel)
	panel:Help("左键：放置设施防空面板（按 E 打开）")
	panel:Help("上方：防空系统状态（正常/关闭）")
	panel:Help("中间：设施危险等级（7 名玩家死亡 = 100%）")
	panel:Help("按 E 打开 HUD；危险 100% 时在 HUD 内长按 5 秒关闭防空")
	panel:Help("关闭成功 → 警告弹窗 + 60 秒黑入音（use 播两遍）→ CI 空降；关闭中可阻止")
	panel:Help("模型需 EP2 的 silo_workspace1；缺失时自动改用 combine 面板")
	panel:Help("警报音：运行 tools/install_aa_assets.bat 复制 mp3")
	panel:Help("清图 / 新回合会重置危险等级；关闭状态新回合恢复")
	panel:NumSlider("朝向偏移 (Yaw)", "mission_intro_aa_panel_yaw", -180, 180, 0)
end

if CLIENT then
	language.Add("tool.mission_intro_aa_panel.name", "设施防空面板")
	language.Add("tool.mission_intro_aa_panel.desc", "放置设施防空系统控制面板")
	language.Add("tool.mission_intro_aa_panel.left", "放置面板")
	language.Add("tool.mission_intro_aa_panel.right", "删除面板")
	language.Add("tool.mission_intro_aa_panel.reload", "清除全部")
end
