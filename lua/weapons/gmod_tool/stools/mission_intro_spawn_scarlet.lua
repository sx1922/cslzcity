TOOL.Category = "RX 任务入场"
TOOL.Name = "猩红出生点"
TOOL.Command = nil
TOOL.Information = {
	{ name = "left", text = "放置猩红主教方出生点" },
	{ name = "right", text = "删除瞄准的出生点" },
	{ name = "reload", text = "清除全部出生点" },
}

TOOL.ClientConVar["yaw"] = "0"

local MI_FACTION = "scarlet_cultist"

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
	panel:Help("左键：放置猩红主教方专用入场出生点")
	panel:Help("右键：删除瞄准的出生点")
	panel:Help("重装：清除地图上全部出生点")
	panel:NumSlider("朝向偏移 (Yaw)", "mission_intro_spawn_scarlet_yaw", -180, 180, 0)
	panel:Help("猩红入场玩家只会在此类出生点（或通用点）复活。")
end

if CLIENT then
	language.Add("tool.mission_intro_spawn_scarlet.name", "猩红出生点")
	language.Add("tool.mission_intro_spawn_scarlet.desc", "放置猩红主教方任务入场出生点")
	language.Add("tool.mission_intro_spawn_scarlet.left", "放置猩红出生点")
	language.Add("tool.mission_intro_spawn_scarlet.right", "删除出生点")
	language.Add("tool.mission_intro_spawn_scarlet.reload", "清除全部")
end
