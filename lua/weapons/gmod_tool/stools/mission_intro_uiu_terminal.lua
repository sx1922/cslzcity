TOOL.Category = "RX UIU"
TOOL.Name = "UIU 骇入终端"
TOOL.Command = nil
TOOL.Information = {
	{ name = "left", text = "放置 UIU 骇入终端" },
	{ name = "right", text = "删除瞄准的终端" },
	{ name = "reload", text = "清除全部终端" },
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

	if MissionIntro and MissionIntro.CreateUiuTerminal then
		MissionIntro.CreateUiuTerminal(pos, ang, false)
		return true
	end

	return false
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	local ent = trace and trace.Entity
	if IsValid(ent) and ent:GetClass() == "ent_mission_intro_uiu_terminal" then
		ent:Remove()
		if MissionIntro and MissionIntro.RequestSaveUiuTerminals then
			MissionIntro.RequestSaveUiuTerminals()
		end
		return true
	end

	return false
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	if MissionIntro and MissionIntro.RemoveAllUiuTerminals then
		MissionIntro.RemoveAllUiuTerminals(true)
	end

	return true
end

function TOOL.BuildCPanel(panel)
	panel:Help("左键：放置 UIU 骇入终端（骇入 5 台电脑后 UIU 间谍可用）")
	panel:Help("右键：删除瞄准的终端")
	panel:Help("重装：清除地图上全部终端")
	panel:Help("清图后会自动从 data/rx_mission_intro/uiu_terminals/ 恢复。")
	panel:NumSlider("朝向偏移 (Yaw)", "mission_intro_uiu_terminal_yaw", -180, 180, 0)
end

if CLIENT then
	language.Add("tool.mission_intro_uiu_terminal.name", "UIU 骇入终端")
	language.Add("tool.mission_intro_uiu_terminal.desc", "放置 UIU 间谍呼叫大部队用的设施终端")
	language.Add("tool.mission_intro_uiu_terminal.left", "放置终端")
	language.Add("tool.mission_intro_uiu_terminal.right", "删除终端")
	language.Add("tool.mission_intro_uiu_terminal.reload", "清除全部")
end
