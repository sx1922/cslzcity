TOOL.Category = "RX 任务入场"
TOOL.Name = "VDV 空降连队出生点"
TOOL.Command = nil
TOOL.Information = {
	{ name = "left", text = "放置 VDV 空降连队出生点" },
	{ name = "right", text = "删除瞄准的出生点" },
	{ name = "reload", text = "清除全部出生点" },
}

TOOL.ClientConVar["yaw"] = "0"

local MI_FACTION = "vdv_squad"

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
	panel:Help("左键：放置 CI 空降连队（VDV）专用入场出生点")
	panel:Help("右键：删除瞄准的出生点")
	panel:Help("重装：清除地图上全部出生点")
	panel:NumSlider("朝向偏移 (Yaw)", "mission_intro_spawn_vdv_yaw", -180, 180, 0)
	panel:Help("VDV 玩家会优先在此类出生点（或通用点）复活。")
	panel:Help("须切换到工具枪并选中本工具，才能看到地面齿轮标记。")
	panel:Help("控制台 mission_intro_show_spawns 可强制显示标记。")
end

if CLIENT then
	language.Add("tool.mission_intro_spawn_vdv.name", "VDV 空降连队出生点")
	language.Add("tool.mission_intro_spawn_vdv.desc", "放置 VDV 空降连队任务入场出生点")
	language.Add("tool.mission_intro_spawn_vdv.left", "放置出生点")
	language.Add("tool.mission_intro_spawn_vdv.right", "删除出生点")
	language.Add("tool.mission_intro_spawn_vdv.reload", "清除全部")
end
