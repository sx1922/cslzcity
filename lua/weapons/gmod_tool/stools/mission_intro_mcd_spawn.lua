TOOL.Category = "RX MC&D"
TOOL.Name = "MC&D 出生点"
TOOL.Command = nil
TOOL.Information = {
	{ name = "left", text = "放置 MC&D 出生点" },
	{ name = "right", text = "删除瞄准的出生点" },
	{ name = "reload", text = "清除全部 MC&D 出生点" },
}

TOOL.ClientConVar["yaw"] = "0"

local MI_FACTION = "mcd_squad"

local function MI_CanUseTool(ply)
	if not IsValid(ply) then return false end
	if MissionIntro and MissionIntro.CanManage then return MissionIntro.CanManage(ply) end
	return ply:IsAdmin()
end

local function MI_IsMcdSpawn(ent)
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
	if MI_IsMcdSpawn(ent) then
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
		if MI_IsMcdSpawn(ent) then ent:Remove() end
	end

	if MissionIntro and MissionIntro.RequestSaveSpawnPoints then
		MissionIntro.RequestSaveSpawnPoints()
	end

	return true
end

if CLIENT then
	language.Add("tool.mission_intro_mcd_spawn.name", "MC&D 出生点")
	language.Add("tool.mission_intro_mcd_spawn.desc", "与猩红/UIU 相同的齿轮预览出生点")
	language.Add("tool.mission_intro_mcd_spawn.left", "放置 MC&D 出生点")
	language.Add("tool.mission_intro_mcd_spawn.right", "删除出生点")
	language.Add("tool.mission_intro_mcd_spawn.reload", "清除全部 MC&D 出生点")
end
