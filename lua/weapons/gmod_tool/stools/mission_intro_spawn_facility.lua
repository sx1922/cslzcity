TOOL.Category = "RX 设施入场"
TOOL.Name = "设施基金会出生点"
TOOL.Command = nil
TOOL.Information = {
	{ name = "left", text = "放置设施基金会出生点" },
	{ name = "right", text = "删除瞄准的出生点" },
	{ name = "reload", text = "清除全部出生点" },
}

TOOL.ClientConVar["yaw"] = "0"

local MI_FACTION = "facility_staff"

local function MI_CanUseTool(ply)
	if not IsValid(ply) then return false end
	if MissionIntro and MissionIntro.CanManage then
		return MissionIntro.CanManage(ply)
	end
	return ply:IsAdmin()
end

local function MI_PlaceSpawn(trace, yawOffset)
	if not trace or not trace.Hit then return false end

	local yaw = trace.HitNormal:Angle().y + yawOffset
	local pos = trace.HitPos + trace.HitNormal * 2
	local ang = Angle(0, yaw, 0)

	if MissionIntro and MissionIntro.CreateSpawnPoint then
		MissionIntro.CreateSpawnPoint(pos, ang, false, MI_FACTION)
	else
		local ent = ents.Create("ent_mission_intro_spawn")
		if not IsValid(ent) then return false end
		ent:SetPos(pos)
		ent:SetAngles(ang)
		if ent.SetSpawnFaction then ent:SetSpawnFaction(MI_FACTION) end
		ent:Spawn()
		ent:Activate()
	end

	return true
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end
	return MI_PlaceSpawn(trace, self:GetClientNumber("yaw", 0))
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	local ent = trace and trace.Entity
	if IsValid(ent) and ent:GetClass() == "ent_mission_intro_spawn" then
		ent:Remove()
		if MissionIntro and MissionIntro.RequestSaveSpawnPoints then
			MissionIntro.RequestSaveSpawnPoints()
		end
		return true
	end

	return false
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end

	if MissionIntro and MissionIntro.RemoveAllSpawnPoints then
		MissionIntro.RemoveAllSpawnPoints(true)
	else
		for _, ent in ipairs(ents.FindByClass("ent_mission_intro_spawn")) do
			if IsValid(ent) then ent:Remove() end
		end
	end

	return true
end

function TOOL.BuildCPanel(panel)
	panel:Help("左键：放置设施科研侧出生点（科研人员/医生/高研/伦理/D 级伪装/UIU 间谍/梅纳德等）")
	panel:Help("安保与 CI 间谍请使用「设施安保出生点」工具，与科研出生点分开。")
	panel:Help("右键：删除瞄准的出生点")
	panel:Help("重装：清除地图上全部出生点")
	panel:NumSlider("朝向偏移 (Yaw)", "mission_intro_spawn_facility_yaw", -180, 180, 0)
	panel:Help("须切换到工具枪并选中本工具，才能看到已放置出生点的齿轮预览。")
	panel:Help("控制台 mission_intro_show_spawns 可强制显示全部出生点。")
	panel:Help("出生点自动保存到 data/rx_mission_intro/spawns/ 当前地图.json")
end

if CLIENT then
	language.Add("tool.mission_intro_spawn_facility.name", "设施基金会出生点")
	language.Add("tool.mission_intro_spawn_facility.desc", "放置设施基金会角色任务入场出生点")
	language.Add("tool.mission_intro_spawn_facility.left", "放置出生点")
	language.Add("tool.mission_intro_spawn_facility.right", "删除出生点")
	language.Add("tool.mission_intro_spawn_facility.reload", "清除全部")
end
