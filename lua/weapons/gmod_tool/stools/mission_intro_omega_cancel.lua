TOOL.Category = "RX 任务入场"
TOOL.Name = "欧米茄弹头终止装置"
TOOL.Command = nil
TOOL.Information = {
	{ name = "left", text = "放置终止装置（非 GOC 使用）" },
	{ name = "right", text = "删除瞄准的终止装置" },
	{ name = "reload", text = "清除全部终止装置" },
}

TOOL.ClientConVar["yaw"] = "0"
TOOL.ClientConVar["pitch"] = "0"
TOOL.ClientConVar["roll"] = "0"

local CANCEL_CLASS = "ent_mission_intro_omega_cancel"

local function MI_CanUseTool(ply)
	if not IsValid(ply) then return false end
	if MissionIntro and MissionIntro.CanManage then
		return MissionIntro.CanManage(ply)
	end
	return ply:IsAdmin()
end

local function MI_ToolAngleOpts(self)
	return {
		yaw = self:GetClientNumber("yaw", 0),
		pitch = self:GetClientNumber("pitch", 0),
		roll = self:GetClientNumber("roll", 0),
		flipWall = false,
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

	local ent = MissionIntro.CreateOmegaCancel and MissionIntro.CreateOmegaCancel(pos, ang, false)
	if not IsValid(ent) then
		self:GetOwner():ChatPrint("[MissionIntro] 放置失败（需 SL 欧米茄弹头模组）")
		return false
	end

	self:GetOwner():ChatPrint("[MissionIntro] 已放置欧米茄终止装置（已保存）")
	return true
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	local ent = trace and trace.Entity
	if IsValid(ent) and ent:GetClass() == CANCEL_CLASS then
		if self:GetOwner():KeyDown(IN_SPEED) then
			local ang = MissionIntro.ComputeOmegaWarheadToolAngles and MissionIntro.ComputeOmegaWarheadToolAngles(trace, MI_ToolAngleOpts(self))
			if ang then
				ent:SetAngles(ang)
			end
			if MissionIntro.RequestSaveOmegaWarheadEntities then
				MissionIntro.RequestSaveOmegaWarheadEntities()
			end
			self:GetOwner():ChatPrint("[MissionIntro] 已更新终止装置朝向（已保存）")
			return true
		end

		ent:Remove()
		if MissionIntro.RequestSaveOmegaWarheadEntities then
			MissionIntro.RequestSaveOmegaWarheadEntities()
		end
		self:GetOwner():ChatPrint("[MissionIntro] 已删除终止装置（已保存）")
		return true
	end

	return false
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	if MissionIntro.RemoveAllOmegaCancels then
		MissionIntro.RemoveAllOmegaCancels(true)
	end

	self:GetOwner():ChatPrint("[MissionIntro] 已清除全部欧米茄终止装置")
	return true
end

function TOOL.BuildCPanel(panel)
	panel:Help("基金会侧人员在 RXsend 模式下按 E 可终止欧米茄弹头倒计时。")
	panel:Help("GOC 无法使用。最后 10 秒为不可避免阶段，仍无法终止。")
	panel:Help("Shift+右键：按当前滑条更新瞄准终止装置的朝向。")
	panel:Help("位置按地图自动保存，清图 / 换图后自动恢复。")
	panel:NumSlider("Yaw 偏移", "mission_intro_omega_cancel_yaw", -180, 180, 0)
	panel:NumSlider("Pitch 偏移", "mission_intro_omega_cancel_pitch", -180, 180, 0)
	panel:NumSlider("Roll 偏移", "mission_intro_omega_cancel_roll", -180, 180, 0)
	panel:Help("保存路径：data/rx_mission_intro/omega_warhead/当前地图.json")
end

if CLIENT then
	language.Add("tool.mission_intro_omega_cancel.name", "欧米茄弹头终止装置")
	language.Add("tool.mission_intro_omega_cancel.desc", "放置非 GOC 专用的欧米茄弹头终止按钮")
	language.Add("tool.mission_intro_omega_cancel.left", "放置终止装置")
	language.Add("tool.mission_intro_omega_cancel.right", "删除终止装置")
	language.Add("tool.mission_intro_omega_cancel.reload", "清除全部终止装置")
end
