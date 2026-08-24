MissionIntro = MissionIntro or {}
MissionIntro._spawnPreviewModels = MissionIntro._spawnPreviewModels or {}

local function MI_GetPreviewModel()
	return (MissionIntro and MissionIntro.SpawnPreviewModel) or "models/Mechanics/gears2/bevel_18t1.mdl"
end

local function MI_GetPreviewScale()
	return (MissionIntro and MissionIntro.SpawnPreviewScale) or 2
end

MissionIntro.SpawnToolModes = MissionIntro.SpawnToolModes or {
	"mission_intro_spawn_scarlet",
	"mission_intro_spawn_hammerfall",
	"mission_intro_spawn_hammerfall_maintenance",
	"mission_intro_spawn_sid",
	"mission_intro_spawn_uiu_taskforce",
	"mission_intro_spawn_pttrb",
	"mission_intro_mcd_spawn",
	"mission_intro_spawn_ci",
	"mission_intro_spawn_ntf",
	"mission_intro_spawn_vdv",
	"mission_intro_spawn_goc",
	"mission_intro_spawn_facility",
	"mission_intro_spawn_facility_security",
	"mission_intro_spawn_mtf",
	"mission_intro_spawn_qrf",
	"mission_intro_spawn_scp",
}

MissionIntro.SpawnToolFactionByMode = MissionIntro.SpawnToolFactionByMode or {
	mission_intro_spawn_scarlet = "scarlet_cultist",
	mission_intro_spawn_hammerfall = "hammerfall_squad",
	mission_intro_spawn_hammerfall_maintenance = "hammerfall_maintenance",
	mission_intro_spawn_sid = "sid_squad",
	mission_intro_spawn_uiu_taskforce = "uiu_taskforce",
	mission_intro_spawn_pttrb = "pttrb_squad",
	mission_intro_mcd_spawn = "mcd_squad",
	mission_intro_spawn_ntf = "ntf_squad",
	mission_intro_spawn_ci = "ci_squad",
	mission_intro_spawn_vdv = "vdv_squad",
	mission_intro_spawn_goc = "goc_squad",
	mission_intro_spawn_facility = "facility_staff",
	mission_intro_spawn_facility_security = "facility_security",
	mission_intro_spawn_mtf = "mtf_taskforce",
	mission_intro_spawn_qrf = "qrf_taskforce",
	mission_intro_spawn_scp = "scp_entity",
}

function MissionIntro.IsSpawnToolMode(mode)
	if not isstring(mode) or mode == "" then return false end
	for _, name in ipairs(MissionIntro.SpawnToolModes) do
		if mode == name then return true end
	end
	return false
end

function MissionIntro.GetActiveSpawnToolMode(ply)
	ply = ply or LocalPlayer()
	if not IsValid(ply) then return "" end

	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) then return "" end

	local class = wep:GetClass()
	if class ~= "gmod_tool" and class ~= "weapon_physgun" then
		return ""
	end

	return (wep.GetMode and wep:GetMode()) or wep.Mode or ply:GetInfo("gmod_toolmode") or ""
end

function MissionIntro.GetActiveSpawnToolFaction(ply)
	local mode = MissionIntro.GetActiveSpawnToolMode(ply)
	if mode == "" then return nil end
	if not MissionIntro.IsSpawnToolMode(mode) then return nil end
	return (MissionIntro.SpawnToolFactionByMode and MissionIntro.SpawnToolFactionByMode[mode]) or ""
end

function MissionIntro.GetSpawnFactionVisual(factionId)
	if MissionIntro.NormalizeSpawnFaction then
		factionId = MissionIntro.NormalizeSpawnFaction(factionId)
	else
		factionId = factionId or ""
	end

	local vis = MissionIntro.SpawnFactionVisual and MissionIntro.SpawnFactionVisual[factionId]
	if vis then return vis end

	return {
		color = Color(100, 230, 140, 255),
		label_key = "spawn_entity_name",
	}
end

function MissionIntro.IsSpawnToolActive(ply)
	local mode = MissionIntro.GetActiveSpawnToolMode(ply)
	return mode ~= "" and MissionIntro.IsSpawnToolMode(mode)
end

function MissionIntro.ShouldDrawSpawnForEntity(ent, ply)
	if not IsValid(ent) then return false end
	if MissionIntro._forceShowSpawns then return true end

	local toolFac = MissionIntro.GetActiveSpawnToolFaction(ply)
	if toolFac == nil then return false end

	local entFac = ent.GetSpawnFaction and ent:GetSpawnFaction() or ""
	if MissionIntro.NormalizeSpawnFaction then
		entFac = MissionIntro.NormalizeSpawnFaction(entFac)
	elseif entFac == "facility_staff" then
		entFac = "facility_staff"
	end

	if toolFac == "" then
		return entFac == ""
	end

	return entFac == toolFac
end

function MissionIntro.ShouldDrawSpawnPreview()
	if MissionIntro._forceShowSpawns then return true end
	return MissionIntro.IsSpawnToolActive()
end

function MissionIntro.ClearAllSpawnPreviews()
	for key, mdl in pairs(MissionIntro._spawnPreviewModels) do
		if IsValid(mdl) then
			mdl:Remove()
		end
		MissionIntro._spawnPreviewModels[key] = nil
	end
end

function MissionIntro.GetSpawnPreviewCS(ent)
	if not IsValid(ent) then return nil end

	local key = ent:EntIndex()
	local cs = MissionIntro._spawnPreviewModels[key]
	local path = MI_GetPreviewModel()

	if IsValid(cs) then
		if cs:GetModel() ~= path then
			cs:SetModel(path)
		end
		return cs
	end

	if not util.IsValidModel(path) then
		return nil
	end

	cs = ClientsideModel(path, RENDERGROUP_TRANSLUCENT)
	if not IsValid(cs) then return nil end

	MissionIntro._spawnPreviewModels[key] = cs
	return cs
end

function MissionIntro.DrawSpawnPreview(ent)
	if not IsValid(ent) then return end

	local pos = ent:GetPos()
	local yaw = ent:GetAngles().y
	local idx = ent.GetSpawnIndex and ent:GetSpawnIndex() or 0
	local scale = MI_GetPreviewScale()
	local factionId = ent.GetSpawnFaction and ent:GetSpawnFaction() or ""
	local vis = MissionIntro.GetSpawnFactionVisual(factionId)
	local col = vis.color or Color(100, 230, 140, 255)

	local cs = MissionIntro.GetSpawnPreviewCS(ent)
	if IsValid(cs) then
		cs:SetPos(pos)
		cs:SetAngles(Angle(90, yaw, 0))
		if cs.SetModelScale then
			cs:SetModelScale(scale, 0)
		end
		cs:SetRenderMode(RENDERMODE_NORMAL)
		cs:SetColor(col)
		cs:DrawModel()
	end

	local labelPos = pos + Vector(0, 0, 22 + 8 * scale)
	local eyeAng = LocalPlayer():EyeAngles()
	eyeAng:RotateAroundAxis(eyeAng:Forward(), 90)
	eyeAng:RotateAroundAxis(eyeAng:Right(), 90)

	local font = (MissionIntro.EnsureFont and MissionIntro.EnsureFont({ size = 16, weight = 600 })) or "DermaDefault"

	local labelKey = vis.label_key or "spawn_entity_name"
	local label = (MissionIntro.L and MissionIntro.L(labelKey)) or labelKey

	cam.Start3D2D(labelPos, Angle(0, eyeAng.y, 90), 0.08)
		draw.SimpleText(label .. " #" .. idx, font, 0, 0, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end

hook.Add("PostDrawTranslucentRenderables", "MissionIntro_DrawSpawnPreviews", function(bDepth, bSkybox)
	if bDepth or bSkybox then return end
	if not MissionIntro.ShouldDrawSpawnPreview() then
		MissionIntro.ClearAllSpawnPreviews()
		return
	end

	local ply = LocalPlayer()
	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_spawn")) do
		if IsValid(ent) and MissionIntro.ShouldDrawSpawnForEntity(ent, ply) then
			MissionIntro.DrawSpawnPreview(ent)
		end
	end
end)

hook.Add("Think", "MissionIntro_SpawnPreviewCleanup", function()
	if MissionIntro.ShouldDrawSpawnPreview() then return end
	MissionIntro.ClearAllSpawnPreviews()
end)

concommand.Add("mission_intro_show_spawns", function()
	local force = not MissionIntro._forceShowSpawns
	MissionIntro._forceShowSpawns = force
	if force then
		chat.AddText(Color(120, 255, 160), "[MissionIntro] 强制显示全部出生点 (再输入一次关闭)")
		hook.Add("PostDrawTranslucentRenderables", "MissionIntro_ForceShowSpawns", function(bDepth, bSkybox)
			if bDepth or bSkybox then return end
			for _, ent in ipairs(ents.FindByClass("ent_mission_intro_spawn")) do
				if IsValid(ent) then MissionIntro.DrawSpawnPreview(ent) end
			end
		end)
	else
		hook.Remove("PostDrawTranslucentRenderables", "MissionIntro_ForceShowSpawns")
		chat.AddText(Color(200, 200, 200), "[MissionIntro] 已关闭强制显示")
	end
end)
