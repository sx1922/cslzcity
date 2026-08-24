TOOL.Category = "RX MC&D"
TOOL.Name = "MC&D 对讲机"
TOOL.Command = nil
TOOL.Information = {
	{ name = "left", text = "放置 MC&D 呼叫对讲机" },
	{ name = "right", text = "删除对讲机" },
	{ name = "reload", text = "清除全部对讲机" },
}

TOOL.ClientConVar["yaw"] = "0"

local function MI_CanUseTool(ply)
	if not IsValid(ply) then return false end
	if MissionIntro and MissionIntro.CanManage then return MissionIntro.CanManage(ply) end
	return ply:IsAdmin()
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end
	if not trace or not trace.Hit then return false end

	local yaw = trace.HitNormal:Angle().y + self:GetClientNumber("yaw", 0)
	local pos = MissionIntro.ComputeUiuToolSpawnPos and MissionIntro.ComputeUiuToolSpawnPos(trace) or (trace.HitPos + trace.HitNormal * 2)
	local ang = Angle(0, yaw, 0)

	if MissionIntro.CreateMcdRadio then
		MissionIntro.CreateMcdRadio(pos, ang, false)
		return true
	end
	return false
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end
	local ent = trace and trace.Entity
	if IsValid(ent) and ent:GetClass() == "ent_mission_intro_mcd_radio" then
		ent:Remove()
		MissionIntro.SaveMcdPlaced("radio")
		return true
	end
	return false
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end
	if MissionIntro.RemoveAllMcd then MissionIntro.RemoveAllMcd("radio", true) end
	return true
end

if CLIENT then
	language.Add("tool.mission_intro_mcd_radio.name", "MC&D 呼叫对讲机")
	language.Add("tool.mission_intro_mcd_radio.desc", "放置后可按 E 呼叫；清图后保留")
end
