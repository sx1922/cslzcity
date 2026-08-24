TOOL.Category = "RX 任务入场"
TOOL.Name = "基金会撤离点"
TOOL.Command = nil
TOOL.Information = {
	{ name = "left", text = "放置基金会撤离点（阵营1）" },
	{ name = "right", text = "删除瞄准的撤离点" },
	{ name = "reload", text = "清除全部基金会撤离点" },
}

TOOL.ClientConVar["yaw"] = "0"
TOOL.ClientConVar["radius"] = "130"

local MI_BATTLE_TEAM = 1

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

	if MissionIntro.CreateRXSendEvac then
		MissionIntro.CreateRXSendEvac(pos, ang, MI_BATTLE_TEAM, false, radius)
		return true
	end

	return false
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	local ent = trace and trace.Entity
	if IsValid(ent) and ent:GetClass() == "ent_mission_intro_rxsend_evac" and ent:GetBattleTeam() == MI_BATTLE_TEAM then
		if self:GetOwner():KeyDown(IN_SPEED) and ent.SetEvacZoneRadius then
			local radius = self:GetClientNumber("radius", 130)
			ent:SetEvacZoneRadius(MissionIntro.ClampRXSendEvacRadius and MissionIntro.ClampRXSendEvacRadius(radius) or radius)
			if MissionIntro.RequestSaveRXSendEvacs then
				MissionIntro.RequestSaveRXSendEvacs()
			end
			self:GetOwner():ChatPrint("[RX] 已更新基金会撤离点半径")
			return true
		end

		ent:Remove()
		if MissionIntro.RequestSaveRXSendEvacs then
			MissionIntro.RequestSaveRXSendEvacs()
		end
		return true
	end

	return false
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	if MissionIntro.RemoveAllRXSendEvacs then
		MissionIntro.RemoveAllRXSendEvacs(MI_BATTLE_TEAM, true)
	end

	return true
end

function TOOL.BuildCPanel(panel)
	panel:Help("左键：放置基金会（阵营1）撤离点")
	panel:Help("RXsend 回合最后 30 秒开放；区域内停留 0.1 秒自动撤离。")
	panel:Help("右键：删除；Shift+右键：更新半径；重装：清除全部基金会撤离点")
	panel:NumSlider("方形半边长", "mission_intro_rxsend_evac_radius", 64, 400, 0)
	panel:NumSlider("朝向偏移 (Yaw)", "mission_intro_rxsend_evac_facility_yaw", -180, 180, 0)
end

if CLIENT then
	language.Add("tool.mission_intro_rxsend_evac_facility.name", "基金会撤离点")
	language.Add("tool.mission_intro_rxsend_evac_facility.desc", "放置 RXsend 基金会阵营撤离区域")
	language.Add("tool.mission_intro_rxsend_evac_facility.left", "放置撤离点")
	language.Add("tool.mission_intro_rxsend_evac_facility.right", "删除撤离点")
	language.Add("tool.mission_intro_rxsend_evac_facility.reload", "清除全部")
end
