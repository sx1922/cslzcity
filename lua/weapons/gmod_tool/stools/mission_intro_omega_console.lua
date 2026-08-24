TOOL.Category = "RX 任务入场"
TOOL.Name = "欧米茄弹头控制台"
TOOL.Command = nil
TOOL.Information = {
	{ name = "left", text = "放置欧米茄弹头控制台（GOC 启动）" },
	{ name = "right", text = "删除瞄准的控制台" },
	{ name = "reload", text = "清除全部控制台" },
}

TOOL.ClientConVar["warhead_time"] = "90"
TOOL.ClientConVar["yaw"] = "0"
TOOL.ClientConVar["pitch"] = "0"
TOOL.ClientConVar["roll"] = "0"

local CONSOLE_CLASS = "ent_mission_intro_omega_console"

local function MI_CanUseTool(ply)
	if not IsValid(ply) then return false end
	if MissionIntro and MissionIntro.CanManage then
		return MissionIntro.CanManage(ply)
	end
	return ply:IsAdmin()
end

local function MI_ValidWarheadTime(n)
	n = tonumber(n) or 90
	if table.HasValue({ 80, 90, 100, 110, 120 }, n) then return n end
	return 90
end

local function MI_ToolAngleOpts(self)
	return {
		yaw = self:GetClientNumber("yaw", 0),
		pitch = self:GetClientNumber("pitch", 0),
		roll = self:GetClientNumber("roll", 0),
		flipWall = true,
	}
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end
	if not trace or not trace.Hit then return false end

	local pos = MissionIntro.ComputeOmegaWarheadToolPos and MissionIntro.ComputeOmegaWarheadToolPos(trace)
		or (trace.HitPos + trace.HitNormal * 2)
	local ang = MissionIntro.ComputeOmegaWarheadToolAngles and MissionIntro.ComputeOmegaWarheadToolAngles(trace, MI_ToolAngleOpts(self))
		or trace.HitNormal:Angle()

	local wt = MI_ValidWarheadTime(self:GetClientNumber("warhead_time", 90))
	local ent = MissionIntro.CreateOmegaConsole and MissionIntro.CreateOmegaConsole(pos, ang, false, wt)
	if not IsValid(ent) then
		self:GetOwner():ChatPrint("[MissionIntro] 放置失败（需 SL 欧米茄弹头模组）")
		return false
	end

	self:GetOwner():ChatPrint("[MissionIntro] 已放置欧米茄控制台（" .. wt .. " 秒，已保存）")
	return true
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	local ent = trace and trace.Entity
	if IsValid(ent) and ent:GetClass() == CONSOLE_CLASS then
		if self:GetOwner():KeyDown(IN_SPEED) then
			local ang = MissionIntro.ComputeOmegaWarheadToolAngles and MissionIntro.ComputeOmegaWarheadToolAngles(trace, MI_ToolAngleOpts(self))
			if ang then
				ent:SetAngles(ang)
			end
			local wt = MI_ValidWarheadTime(self:GetClientNumber("warhead_time", 90))
			if ent.SetWarheadTime then
				ent:SetWarheadTime(wt)
			end
			if MissionIntro.RequestSaveOmegaWarheadEntities then
				MissionIntro.RequestSaveOmegaWarheadEntities()
			end
			self:GetOwner():ChatPrint("[MissionIntro] 已更新控制台朝向/引爆时间（" .. wt .. " 秒，已保存）")
			return true
		end

		ent:Remove()
		if MissionIntro.RequestSaveOmegaWarheadEntities then
			MissionIntro.RequestSaveOmegaWarheadEntities()
		end
		self:GetOwner():ChatPrint("[MissionIntro] 已删除控制台（已保存）")
		return true
	end

	return false
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	if MissionIntro.RemoveAllOmegaConsoles then
		MissionIntro.RemoveAllOmegaConsoles(true)
	end

	self:GetOwner():ChatPrint("[MissionIntro] 已清除全部欧米茄控制台")
	return true
end

function TOOL.BuildCPanel(panel)
	panel:Help("放置后由 GOC 在 RXsend 模式下按 E 启动欧米茄弹头。")
	panel:Help("回合最后 4 分钟无法启动。")
	panel:Help("Shift+右键：按当前滑条更新瞄准控制台的朝向与引爆时间。")
	panel:Help("位置按地图自动保存，清图 / 换图后自动恢复。")
	panel:NumSlider("引爆时间（秒）", "mission_intro_omega_console_warhead_time", 80, 120, 0)
	panel:NumSlider("Yaw 偏移", "mission_intro_omega_console_yaw", -180, 180, 0)
	panel:NumSlider("Pitch 偏移", "mission_intro_omega_console_pitch", -180, 180, 0)
	panel:NumSlider("Roll 偏移", "mission_intro_omega_console_roll", -180, 180, 0)
	panel:Help("保存路径：data/rx_mission_intro/omega_warhead/当前地图.json")
end

if CLIENT then
	language.Add("tool.mission_intro_omega_console.name", "欧米茄弹头控制台")
	language.Add("tool.mission_intro_omega_console.desc", "放置 GOC 专用的欧米茄弹头启动控制台")
	language.Add("tool.mission_intro_omega_console.left", "放置控制台")
	language.Add("tool.mission_intro_omega_console.right", "删除控制台")
	language.Add("tool.mission_intro_omega_console.reload", "清除全部控制台")
end
