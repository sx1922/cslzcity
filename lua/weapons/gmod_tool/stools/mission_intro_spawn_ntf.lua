TOOL.Category = "RX 任务入场"
TOOL.Name = "九尾狐出生点"
TOOL.Command = nil
TOOL.Information = {
	{ name = "left", text = "放置九尾狐出生点" },
	{ name = "right", text = "删除瞄准的出生点" },
	{ name = "reload", text = "清除全部九尾狐出生点" },
}

TOOL.ClientConVar["yaw"] = "0"

local MI_FACTION = "ntf_squad"

local function MI_CanUseTool(ply)
	if not IsValid(ply) then return false end
	if MissionIntro and MissionIntro.CanManage then
		return MissionIntro.CanManage(ply)
	end
	return ply:IsAdmin()
end

local function MI_IsNtfSpawn(ent)
	if not IsValid(ent) or ent:GetClass() ~= "ent_mission_intro_spawn" then return false end
	if not ent.GetSpawnFaction then return false end
	local fac = MissionIntro.NormalizeSpawnFaction and MissionIntro.NormalizeSpawnFaction(ent:GetSpawnFaction()) or ent:GetSpawnFaction()
	return fac == MI_FACTION
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
	if MI_IsNtfSpawn(ent) then
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

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_spawn")) do
		if MI_IsNtfSpawn(ent) then ent:Remove() end
	end

	if MissionIntro and MissionIntro.RequestSaveSpawnPoints then
		MissionIntro.RequestSaveSpawnPoints()
	end

	return true
end

function TOOL.BuildCPanel(panel)
	panel:Help("左键：放置机动特遣队九尾狐（ntf_squad）任务入场出生点")
	panel:Help("与管理员面板「九尾狐 · 重生并入场」使用同一套出生点，不是设施 MTF 专用点。")
	panel:Help("右键：删除瞄准的出生点；重装：仅清除九尾狐出生点")
	panel:NumSlider("朝向偏移 (Yaw)", "mission_intro_spawn_ntf_yaw", -180, 180, 0)
	panel:Help("须选中本工具才能看到齿轮预览；mission_intro_show_spawns 可强制显示全部点")
end

if CLIENT then
	language.Add("tool.mission_intro_spawn_ntf.name", "九尾狐出生点")
	language.Add("tool.mission_intro_spawn_ntf.desc", "RX 任务入场 · 机动特遣队九尾狐出生点")
	language.Add("tool.mission_intro_spawn_ntf.left", "放置九尾狐出生点")
	language.Add("tool.mission_intro_spawn_ntf.right", "删除出生点")
	language.Add("tool.mission_intro_spawn_ntf.reload", "清除全部九尾狐出生点")
end
