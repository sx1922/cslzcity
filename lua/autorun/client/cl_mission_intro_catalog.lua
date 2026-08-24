MissionIntro = MissionIntro or {}
MissionIntro._catalogPanel = MissionIntro._catalogPanel or nil
MissionIntro.CatalogData = MissionIntro.CatalogData or nil
MissionIntro._catalogPreviewKey = MissionIntro._catalogPreviewKey or nil

local COL = {
	bg = Color(6, 6, 8, 252),
	sidebar = Color(0, 0, 0, 255),
	border = Color(255, 255, 255, 18),
	header = Color(36, 38, 42, 255),
	panelLight = Color(178, 182, 188, 255),
	panelLightText = Color(24, 26, 30, 255),
	panelDim = Color(72, 76, 84, 255),
	title = Color(245, 247, 250),
	text = Color(220, 226, 236),
	dim = Color(130, 136, 148),
	accent = Color(72, 130, 210),
	iconBg = Color(18, 20, 24, 255),
	iconSel = Color(52, 96, 168, 255),
	iconHover = Color(34, 38, 46, 255),
	thumbSel = Color(255, 255, 255, 240),
	thumbIdle = Color(255, 255, 255, 40),
	btn = Color(42, 88, 160),
	btnHover = Color(58, 118, 200),
	row = Color(16, 22, 34, 255),
	rowHover = Color(24, 34, 52, 255),
	rowSel = Color(32, 52, 88, 255),
}

local CATALOG_UI_SCALE = 1.15
local TAB_ROLES = "roles"
local TAB_RELATIONS = "relations"
local _emblemMatCache = {}

local function MI_ClearEmblemCache()
	_emblemMatCache = {}
end

local BUNDLE_ICON_COL = {
	facility_sci = Color(72, 130, 210),
	facility_security = Color(196, 64, 64),
	mtf_taskforce = Color(30, 90, 168),
	qrf_taskforce = Color(130, 145, 210),
	scp_entity = Color(190, 190, 190),
	scarlet_cultist = Color(220, 48, 48),
	hammerfall_squad = Color(36, 144, 255),
	hammerfall_maintenance = Color(36, 144, 255),
	sid_squad = Color(48, 52, 60),
	uiu_taskforce = Color(28, 32, 40),
	pttrb_squad = Color(72, 130, 210),
	mcd_squad = Color(160, 80, 255),
	ntf_squad = Color(118, 128, 88),
	ci_squad = Color(72, 200, 96),
	vdv_squad = Color(72, 200, 96),
	goc_squad = Color(185, 190, 200),
	ci_spy = Color(72, 200, 96),
}

-- 侧栏小图标内徽章缩放（相对默认内边距）
local BUNDLE_ICON_EMBLEM_SCALE = {
	pttrb_squad = 1.5,
	ci_squad = 1.3,
	vdv_squad = 1.3,
	goc_squad = 1.2,
	ci_spy = 1.35,
	hammerfall_squad = 1.3,
}

local function MI_GetBundleIconEmblemScale(bundleId)
	return BUNDLE_ICON_EMBLEM_SCALE[bundleId] or 1
end

local function MI_DrawBundleSidebarEmblem(x, y, w, h, mat, bundleId)
	if not mat or mat:IsError() then return false end

	local size = math.min(w, h)
	local drawW, drawH = size, size

	if bundleId == "scarlet_cultist" then
		drawW, drawH = size, size
	else
		local tw = mat:Width() or size
		local th = mat:Height() or size
		if tw > 0 and th > 0 then
			local aspect = tw / th
			if aspect > 1.01 then
				drawH = size / aspect
			elseif aspect < 0.99 then
				drawW = size * aspect
			end
		end
	end

	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(mat)
	surface.DrawTexturedRect(x + (w - drawW) * 0.5, y + (h - drawH) * 0.5, drawW, drawH)
	return true
end

local function MI_NormalizeEmblemBase(path)
	if not isstring(path) or path == "" then return nil end
	local base = path:gsub("%.png$", ""):gsub("%.vmt$", "")
	if not base:find("^materials/", 1, true) then
		base = "materials/" .. base
	end
	return base
end

local function MI_ResolveCatalogEmblemPath(path)
	if not isstring(path) or path == "" then return nil end
	if file.Exists(path, "GAME") then return path end

	local base = MI_NormalizeEmblemBase(path)
	if not base then return nil end

	if file.Exists(base .. ".png", "GAME") then
		return base .. ".png"
	end
	if file.Exists(base .. ".vmt", "GAME") then
		return base
	end

	return nil
end

local function MI_GetCatalogEmblemMaterial(path)
	path = MI_ResolveCatalogEmblemPath(path)
	if not path then return nil end
	if _emblemMatCache[path] then return _emblemMatCache[path] end

	local mat = Material(path, "noclamp smooth")
	if mat and not mat:IsError() then
		_emblemMatCache[path] = mat
		return mat
	end

	return nil
end

local function MI_GetBundleEmblemPaths(bundle)
	if MissionIntro.GetCatalogBundleEmblemPaths then
		return MissionIntro.GetCatalogBundleEmblemPaths(bundle)
	end

	local paths = {}
	if MissionIntro.ResolveCatalogBundleEmblem then
		local resolved = MissionIntro.ResolveCatalogBundleEmblem(bundle)
		if isstring(resolved) and resolved ~= "" then
			paths[1] = resolved
		end
	end
	if istable(bundle) and isstring(bundle.emblem) and bundle.emblem ~= "" then
		paths[#paths + 1] = bundle.emblem
	end
	return paths
end

local function MI_TryApplyEmblemToImage(img, path)
	local resolved = MI_ResolveCatalogEmblemPath(path)
	if not resolved then return false end

	if resolved:find("%.png$", 1, true) then
		img:SetImage(resolved:gsub("^materials/", ""))
		return true
	end

	local mat = MI_GetCatalogEmblemMaterial(resolved)
	if mat then
		img:SetMaterial(mat)
		return true
	end

	return false
end

local function MI_GetBundleName(bundle)
	if MissionIntro.ResolveCatalogBundleName then
		return MissionIntro.ResolveCatalogBundleName(bundle)
	end
	return bundle.name or bundle.id or "?"
end

local function MI_GetRoleName(row, bundle)
	if MissionIntro.GetCatalogRoleDisplayName then
		return MissionIntro.GetCatalogRoleDisplayName(row, bundle)
	end
	return row.title or row.role_label or "?"
end

local function MI_GetMissionText(row)
	if MissionIntro.FormatCatalogMissionText then
		return MissionIntro.FormatCatalogMissionText(row)
	end
	return (row.mission or row.objective or "-")
end

local function MI_DrawEmblem(x, y, size, path, alpha)
	local mat = MI_GetCatalogEmblemMaterial(path)
	if not mat then return false end

	alpha = alpha or 255
	local drawW, drawH = size, size
	local tw = mat:Width() or size
	local th = mat:Height() or size
	if tw > 0 and th > 0 then
		local aspect = tw / th
		if aspect > 1.01 then
			drawH = size / aspect
		elseif aspect < 0.99 then
			drawW = size * aspect
		end
	end

	surface.SetDrawColor(255, 255, 255, alpha)
	surface.SetMaterial(mat)
	surface.DrawTexturedRect(x + (size - drawW) * 0.5, y + (size - drawH) * 0.5, drawW, drawH)
	return true
end

local function MI_CreateFactionIcon(parent, bundle, pad)
	pad = pad or 7
	local emblemScale = MI_GetBundleIconEmblemScale(bundle.id)
	local inset = math.max(2, math.floor(pad / emblemScale + 0.5))

	parent._miIconHasTexture = false
	parent._miIconFallback = string.sub(MI_GetBundleName(bundle), 1, 3)
	parent._miIconColor = BUNDLE_ICON_COL[bundle.id] or COL.accent
	parent._miIconBundleId = bundle.id
	parent._miIconEmblemMat = nil

	for _, path in ipairs(MI_GetBundleEmblemPaths(bundle)) do
		local resolved = MI_ResolveCatalogEmblemPath(path)
		if not resolved then continue end

		local mat = MI_GetCatalogEmblemMaterial(resolved)
		if mat and not mat:IsError() then
			parent._miIconEmblemMat = mat
			parent._miIconHasTexture = true
			parent._miIconFallback = nil
			break
		end
	end

	local iconPanel = vgui.Create("DPanel", parent)
	iconPanel:Dock(FILL)
	iconPanel:DockMargin(inset, inset, inset, inset)
	iconPanel:SetMouseInputEnabled(false)
	iconPanel:SetPaintBackground(false)
	iconPanel.Paint = function(self, w, h)
		if not parent._miIconHasTexture then return end
		MI_DrawBundleSidebarEmblem(0, 0, w, h, parent._miIconEmblemMat, parent._miIconBundleId)
	end

	return iconPanel
end

local function MI_S(n)
	return math.floor((tonumber(n) or 0) * CATALOG_UI_SCALE + 0.5)
end

local function MI_Font(size, weight)
	size = MI_S(size or 16)
	if MissionIntro.EnsureFont then
		return MissionIntro.EnsureFont({ size = size or 16, weight = weight or 600 })
	end
	return "DermaDefault"
end

local function MI_L(key, ...)
	if MissionIntro.L then
		return MissionIntro.L(key, ...)
	end
	return key
end

local function MI_RequestCatalog()
	net.Start("MissionIntro_CatalogRequest")
	net.SendToServer()
end

function MissionIntro.FitCatalogPreviewCamera(mdl, ent, mode)
	if not IsValid(mdl) or not IsValid(ent) then return end

	mode = mode or "full"

	local mn, mx = ent:GetRenderBounds()
	local center = (mn + mx) * 0.5
	local height = mx.z - mn.z
	local width = math.max(mx.x - mn.x, mx.y - mn.y)
	local size = math.max(height, width, 10)

	if mode == "head" then
		local lookAt = Vector(center.x, center.y, mn.z + height * 0.9)
		local bone = ent:LookupBone("ValveBiped.Bip01_Head1")
			or ent:LookupBone("ValveBiped.Bip01_Neck1")
			or ent:LookupBone("bip_head")
		if bone then
			local matrix = ent:GetBoneMatrix(bone)
			if matrix then
				lookAt = matrix:GetTranslation()
			else
				local bonePos = ent:GetBonePosition(bone)
				if bonePos then
					lookAt = bonePos
				end
			end
		end

		local dist = math.max(size * 0.38, 14)
		mdl:SetLookAt(lookAt)
		mdl:SetCamPos(lookAt + Vector(dist, dist * 0.42, height * 0.02))
		mdl:SetFOV(math.Clamp(32, 26, 40))
		return
	end

	-- 全身构图（缩略图等备用）
	local lookAt = Vector(center.x, center.y, center.z)
	local dist = size * 1.55
	mdl:SetLookAt(lookAt)
	mdl:SetCamPos(lookAt + Vector(dist, dist * 0.32, height * 0.04))

	local fov = math.deg(2 * math.atan(size / (dist * 1.35)))
	mdl:SetFOV(math.Clamp(fov, 24, 52))
end

function MissionIntro.ResolveCatalogPreviewCameraMode(modelPath, entry)
	if istable(entry) and isstring(entry.catalog_preview_mode) and entry.catalog_preview_mode ~= "" then
		return entry.catalog_preview_mode
	end
	if not isstring(modelPath) or modelPath == "" then return "full" end
	local lower = string.lower(modelPath)
	-- head_site.mdl 是设施主管全身模型，文件名含 head 但不是头部特写
	if lower:find("head_site", 1, true) then return "full" end
	if lower:find("/head_", 1, true) then return "head" end
	return "full"
end

function MissionIntro.ApplyCatalogPreviewVisuals(mdl, entry, cameraMode)
	if not IsValid(mdl) or not istable(entry) then return false end

	local path = MissionIntro.ResolveCatalogModelPath and MissionIntro.ResolveCatalogModelPath(entry) or entry.model
	if not isstring(path) or path == "" then return false end

	if util.PrecacheModel then
		util.PrecacheModel(path)
	end

	mdl:SetModel(path)

	local ent = mdl.Entity
	if not IsValid(ent) then return false end

	ent:SetSkin(tonumber(entry.skin) or 0)
	if istable(entry.bodygroups) then
		for bgId, val in pairs(entry.bodygroups) do
			ent:SetBodygroup(tonumber(bgId) or 0, tonumber(val) or 0)
		end
	end

	if entry.profile_id == "facility_qrf_marksman" or entry.role_id == "qrf_marksman" then
		if MissionIntro.ApplyObrQrfMarksmanHelmetCap then
			MissionIntro.ApplyObrQrfMarksmanHelmetCap(ent)
		end
	elseif entry.profile_id == "facility_qrf_medic" or entry.role_id == "qrf_medic" then
		if istable(entry.bodygroups) then
			ent:SetBodygroup(4, tonumber(entry.bodygroups[4]) or 1)
		end
	elseif entry.profile_id == "facility_qrf_commander" or entry.role_id == "qrf_commander" then
		if istable(entry.bodygroups) then
			ent:SetBodygroup(1, tonumber(entry.bodygroups[1]) or 3)
		end
	end

	cameraMode = cameraMode or MissionIntro.ResolveCatalogPreviewCameraMode(path, entry)
	MissionIntro.FitCatalogPreviewCamera(mdl, ent, cameraMode)
	mdl._miPreviewCamMode = cameraMode
	return true
end

function MissionIntro.PrecacheCatalogModels()
	if not MissionIntro.GetCatalogBaseModelPaths then return end
	for _, path in ipairs(MissionIntro.GetCatalogBaseModelPaths()) do
		if util.PrecacheModel then
			util.PrecacheModel(path)
		end
	end
end

local function MI_ClearCatalogPortrait(mdl)
	if not IsValid(mdl) then return end
	if IsValid(mdl._miPortraitImg) then
		mdl._miPortraitImg:Remove()
		mdl._miPortraitImg = nil
	end
end

local function MI_ApplyCatalogPortrait(mdl, entry)
	MI_ClearCatalogPortrait(mdl)
	if not IsValid(mdl) or not istable(entry) then return false end

	local portraitPath = entry.catalog_portrait
	if not isstring(portraitPath) or portraitPath == "" then return false end

	local resolved = portraitPath
	if MissionIntro.ResolveMissionIntroImagePath then
		resolved = MissionIntro.ResolveMissionIntroImagePath(portraitPath) or portraitPath
	end

	local mat = MI_GetCatalogEmblemMaterial(resolved)
	if not mat then return false end

	local parent = mdl:GetParent()
	if not IsValid(parent) then return false end

	mdl:SetVisible(false)
	mdl._miSpin = false
	mdl.LayoutEntity = function() end

	local img = vgui.Create("DImage", parent)
	img:Dock(FILL)
	img:DockMargin(MI_S(8), MI_S(8), MI_S(8), MI_S(8))
	img:SetKeepAspect(true)
	img:SetMaterial(mat)
	mdl._miPortraitImg = img
	return true
end

function MissionIntro.SetCatalogPreview(entry)
	if not IsValid(MissionIntro._catalogPreview) then return end

	local mdl = MissionIntro._catalogPreview
	MI_ClearCatalogPortrait(mdl)

	if istable(entry) and entry.catalog_preview_mode == "portrait" and MI_ApplyCatalogPortrait(mdl, entry) then
		MissionIntro._catalogPreviewKey = (entry.catalog_portrait or "") .. "|portrait"
		return
	end

	local path = MissionIntro.ResolveCatalogModelPath and MissionIntro.ResolveCatalogModelPath(entry) or (istable(entry) and entry.model)

	if istable(entry) and isstring(path) and path ~= "" then
		mdl:SetVisible(true)
		mdl._miRefitCamera = false
		mdl._miPendingEntry = table.Copy(entry)
		mdl._miPendingEntry.model = path
		local camMode = MissionIntro.ResolveCatalogPreviewCameraMode and MissionIntro.ResolveCatalogPreviewCameraMode(path, mdl._miPendingEntry) or "full"

		local function applyNow()
			if not IsValid(mdl) or not istable(mdl._miPendingEntry) then return end
			if MissionIntro.ApplyCatalogPreviewVisuals(mdl, mdl._miPendingEntry, camMode) then
				mdl._miPendingEntry = nil
			end
		end

		applyNow()
		if not IsValid(mdl.Entity) then
			timer.Simple(0, applyNow)
			timer.Simple(0.1, applyNow)
		end

		mdl._miSpin = true
		mdl.LayoutEntity = function(self, e)
			if not IsValid(e) then return end
			e:SetAngles(Angle(0, (CurTime() * 32) % 360, 0))
			if self._miRefitCamera ~= true then
				self._miRefitCamera = true
				MissionIntro.FitCatalogPreviewCamera(self, e, self._miPreviewCamMode or camMode)
			end
		end

		MissionIntro._catalogPreviewKey = path .. "|" .. (entry.bodygroups_text or "") .. "|" .. tostring(entry.skin or 0)
		return
	end

	if istable(entry) and MI_ApplyCatalogPortrait(mdl, entry) then
		MissionIntro._catalogPreviewKey = (entry.catalog_portrait or "") .. "|portrait"
		return
	end

	mdl:SetVisible(false)
	MissionIntro._catalogPreviewKey = nil
end

local function MI_BuildPreviewEntryFromRole(row)
	if not istable(row) then return nil end
	local model = MissionIntro.ResolveCatalogModelPath and MissionIntro.ResolveCatalogModelPath(row) or row.model
	return {
		model = model,
		profile_id = row.profile_id,
		bodygroups = row.bodygroups,
		bodygroups_text = row.bodygroups_text,
		skin = row.skin,
		catalog_portrait = row.catalog_portrait,
		catalog_preview_mode = row.catalog_preview_mode,
	}
end

local function MI_GetCatalogFactions(data)
	if istable(data) and istable(data.factions) and #data.factions > 0 then
		return data.factions
	end

	local grouped = {}
	local order = {}
	for _, row in ipairs(data and data.roles or {}) do
		local key = row.bundle_id or row.faction_id or "misc"
		if not grouped[key] then
			grouped[key] = {
				id = key,
				name = row.faction_name or key,
				emblem = "",
				roles = {},
			}
			order[#order + 1] = key
		end
		grouped[key].roles[#grouped[key].roles + 1] = row
	end

	local out = {}
	for _, key in ipairs(order) do
		out[#out + 1] = grouped[key]
	end
	return out
end

local function MI_PrecacheCatalogEmblems(factions)
	for _, bundle in ipairs(factions or {}) do
		for _, path in ipairs(MI_GetBundleEmblemPaths(bundle)) do
			MI_GetCatalogEmblemMaterial(path)
		end
	end
	if MissionIntro.CatalogBundleEmblems then
		for _, path in pairs(MissionIntro.CatalogBundleEmblems) do
			MI_GetCatalogEmblemMaterial(path)
		end
	end
end

local function MI_SetRoleThumbModel(mdl, row)
	if not IsValid(mdl) or not istable(row) then return end
	local entry = MI_BuildPreviewEntryFromRole(row)
	if not entry then return end

	if entry.catalog_preview_mode == "portrait" and MI_ApplyCatalogPortrait(mdl, entry) then
		return
	end

	mdl._miRefitCamera = false
	mdl._miPreviewCamMode = "head"
	if MissionIntro.ApplyCatalogPreviewVisuals(mdl, entry, "head") then
		local ent = mdl.Entity
		if IsValid(ent) then
			ent:SetAngles(Angle(0, 24, 0))
		end
	end
end

local function MI_FillRelationsView(ctx)
	local main = ctx.main
	local header = ctx.header
	local preview = ctx.preview
	local roleStrip = ctx.roleStrip

	main:Clear()
	if IsValid(roleStrip) then
		roleStrip:Clear()
		roleStrip:SetVisible(false)
	end
	if IsValid(preview) then
		preview:SetVisible(false)
	end

	header._miTitle = MI_L("catalog_tab_relations")
	header._miEmblemOk = false
	if IsValid(header._miEmblemImg) then
		header._miEmblemImg:Remove()
		header._miEmblemImg = nil
	end
	header:InvalidateLayout(true)

	local scroll = vgui.Create("DScrollPanel", main)
	scroll:Dock(FILL)
	scroll:DockMargin(MI_S(14), MI_S(12), MI_S(14), MI_S(12))
	scroll:GetVBar():SetWide(6)

	local relations = MissionIntro.GetCatalogHostileRelations and MissionIntro.GetCatalogHostileRelations() or {}

	for _, rel in ipairs(relations) do
		local card = vgui.Create("DPanel", scroll)
		card:Dock(TOP)
		card:DockMargin(0, 0, 0, MI_S(10))
		card:SetTall(MI_S(108))
		card.Paint = function(self, w, h)
			draw.RoundedBox(6, 0, 0, w, h, COL.panelLight)
		end

		local emblemPanel = vgui.Create("DPanel", card)
		emblemPanel:SetPos(MI_S(12), MI_S(14))
		emblemPanel:SetSize(MI_S(80), MI_S(80))
		emblemPanel.Paint = function(self, w, h)
			local mat = MI_GetCatalogEmblemMaterial(rel.emblem)
			if mat and not mat:IsError() then
				MI_DrawBundleSidebarEmblem(0, 0, w, h, mat, rel.bundle_id)
			else
				local col = BUNDLE_ICON_COL[rel.bundle_id] or COL.accent
				draw.RoundedBox(h * 0.5, 0, 0, w, h, Color(col.r, col.g, col.b, 220))
				draw.SimpleText(string.sub(rel.title or "?", 1, 3), MI_Font(14, 800), w * 0.5, h * 0.5, COL.title, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end

		local titleLbl = vgui.Create("DLabel", card)
		titleLbl:SetPos(MI_S(104), MI_S(14))
		titleLbl:SetSize(MI_S(520), MI_S(28))
		titleLbl:SetFont(MI_Font(22, 800))
		titleLbl:SetTextColor(COL.panelLightText)
		titleLbl:SetText(rel.title or "?")

		local bodyLbl = vgui.Create("DLabel", card)
		bodyLbl:SetPos(MI_S(104), MI_S(44))
		bodyLbl:SetSize(MI_S(520), MI_S(56))
		bodyLbl:SetFont(MI_Font(17, 500))
		bodyLbl:SetTextColor(COL.panelDim)
		bodyLbl:SetWrap(true)
		bodyLbl:SetAutoStretchVertical(true)
		bodyLbl:SetText(rel.body or "")
	end

	if #relations == 0 then
		local lbl = vgui.Create("DLabel", scroll)
		lbl:Dock(TOP)
		lbl:SetTall(MI_S(40))
		lbl:SetContentAlignment(5)
		lbl:SetFont(MI_Font(18, 600))
		lbl:SetTextColor(COL.dim)
		lbl:SetText(MI_L("catalog_loading"))
	end
end

local function MI_FillRolesView(ctx)
	local main = ctx.main
	local header = ctx.header
	local preview = ctx.preview
	local roleStrip = ctx.roleStrip
	local factions = ctx.factions

	main:Clear()
	roleStrip:Clear()
	if IsValid(roleStrip) then
		roleStrip:SetVisible(true)
	end

	if not istable(factions) or #factions == 0 then
		local lbl = vgui.Create("DLabel", main)
		lbl:Dock(FILL)
		lbl:SetContentAlignment(5)
		lbl:SetFont(MI_Font(18, 600))
		lbl:SetTextColor(COL.dim)
		lbl:SetText(MI_L("catalog_loading"))
		if IsValid(preview) then preview:SetVisible(false) end
		return
	end

	ctx.bundleIndex = math.Clamp(ctx.bundleIndex or 1, 1, #factions)
	local bundle = factions[ctx.bundleIndex]
	ctx.roleIndex = math.Clamp(ctx.roleIndex or 1, 1, math.max(1, #(bundle.roles or {})))
	local row = bundle.roles and bundle.roles[ctx.roleIndex]

	header._miEmblem = bundle.emblem
	header._miTitle = MI_GetBundleName(bundle)
	header._miEmblemOk = false

	if IsValid(header._miEmblemImg) then
		header._miEmblemImg:Remove()
	end
	header._miEmblemImg = vgui.Create("DImage", header)
	header._miEmblemImg:SetMouseInputEnabled(false)
	header._miEmblemImg:SetKeepAspect(true)
	for _, path in ipairs(MI_GetBundleEmblemPaths(bundle)) do
		if MI_TryApplyEmblemToImage(header._miEmblemImg, path) then
			header._miEmblemOk = true
			break
		end
	end
	if not header._miEmblemOk then
		header._miEmblemImg:SetVisible(false)
	end
	header:InvalidateLayout(true)

	local mid = vgui.Create("DPanel", main)
	mid:Dock(FILL)
	mid:DockMargin(MI_S(12), MI_S(8), MI_S(12), MI_S(8))
	mid.Paint = function() end

	local previewHost = vgui.Create("DPanel", mid)
	previewHost:Dock(LEFT)
	previewHost:SetWide(MI_S(300))
	previewHost.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(24, 26, 30, 255))
	end

	if IsValid(preview) then
		preview:SetParent(previewHost)
		preview:Dock(FILL)
		preview:DockMargin(MI_S(8), MI_S(8), MI_S(8), MI_S(8))
		preview:SetVisible(true)
	end

	if istable(row) then
		MissionIntro.SetCatalogPreview(MI_BuildPreviewEntryFromRole(row))
	end

	local infoHost = vgui.Create("DPanel", mid)
	infoHost:Dock(FILL)
	infoHost:DockMargin(MI_S(10), 0, 0, 0)
	infoHost.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, COL.panelLight)
		if isstring(bundle.emblem) and bundle.emblem ~= "" then
			MI_DrawEmblem(w - MI_S(150), h - MI_S(150), MI_S(140), bundle.emblem, 28)
		end
	end

	if istable(row) then
		local infoScroll = vgui.Create("DScrollPanel", infoHost)
		infoScroll:Dock(FILL)
		infoScroll:DockMargin(MI_S(8), MI_S(8), MI_S(8), MI_S(8))
		infoScroll:GetVBar():SetWide(6)

		local infoBody = vgui.Create("DPanel", infoScroll)
		infoBody:Dock(TOP)
		infoBody:SetPaintBackground(false)
		infoBody:DockPadding(MI_S(8), MI_S(10), MI_S(8), MI_S(16))
		infoBody.PerformLayout = function(self, w, h)
			self:SizeToChildren(false, true)
			infoScroll:InvalidateLayout(true)
		end

		local nameLbl = vgui.Create("DLabel", infoBody)
		nameLbl:Dock(TOP)
		nameLbl:DockMargin(0, 0, 0, MI_S(8))
		nameLbl:SetFont(MI_Font(28, 800))
		nameLbl:SetTextColor(COL.panelLightText)
		nameLbl:SetWrap(true)
		nameLbl:SetAutoStretchVertical(true)
		nameLbl:SetText(MI_GetRoleName(row, bundle))

		local missionLbl = vgui.Create("DLabel", infoBody)
		missionLbl:Dock(TOP)
		missionLbl:DockMargin(0, 0, 0, MI_S(10))
		missionLbl:SetFont(MI_Font(19, 600))
		missionLbl:SetTextColor(COL.panelDim)
		missionLbl:SetWrap(true)
		missionLbl:SetAutoStretchVertical(true)
		missionLbl:SetText(MI_GetMissionText(row))

		local statsHdr = vgui.Create("DLabel", infoBody)
		statsHdr:Dock(TOP)
		statsHdr:DockMargin(0, MI_S(4), 0, MI_S(6))
		statsHdr:SetFont(MI_Font(21, 800))
		statsHdr:SetTextColor(COL.panelLightText)
		statsHdr:SetText(MI_L("catalog_ui_stats"))

		local hpLbl = vgui.Create("DLabel", infoBody)
		hpLbl:Dock(TOP)
		hpLbl:DockMargin(0, 0, 0, MI_S(4))
		hpLbl:SetFont(MI_Font(18, 600))
		hpLbl:SetTextColor(COL.panelLightText)
		hpLbl:SetText(MI_L("catalog_ui_hp") .. "  100")

		local stLbl = vgui.Create("DLabel", infoBody)
		stLbl:Dock(TOP)
		stLbl:DockMargin(0, 0, 0, MI_S(4))
		stLbl:SetFont(MI_Font(18, 600))
		stLbl:SetTextColor(COL.panelLightText)
		local staminaText = (isstring(row.catalog_stamina) and row.catalog_stamina ~= "") and row.catalog_stamina or "50"
		stLbl:SetText(MI_L("catalog_ui_stamina") .. "  " .. staminaText)

		local spawnArmor = tonumber(row.spawn_armor)
		if spawnArmor and spawnArmor > 0 then
			local armorLbl = vgui.Create("DLabel", infoBody)
			armorLbl:Dock(TOP)
			armorLbl:DockMargin(0, 0, 0, MI_S(10))
			armorLbl:SetFont(MI_Font(18, 600))
			armorLbl:SetTextColor(COL.panelLightText)
			armorLbl:SetText(MI_L("catalog_ui_armor") .. "：" .. tostring(math.floor(spawnArmor)))
		else
			stLbl:DockMargin(0, 0, 0, MI_S(10))
		end

		local weaponLbl = vgui.Create("DLabel", infoBody)
		weaponLbl:Dock(TOP)
		weaponLbl:DockMargin(0, 0, 0, MI_S(4))
		weaponLbl:SetFont(MI_Font(17, 500))
		weaponLbl:SetTextColor(COL.panelDim)
		weaponLbl:SetWrap(true)
		weaponLbl:SetAutoStretchVertical(true)
		local weaponText = MI_L("catalog_label_primary") .. ": " .. (row.primary or "-")
		if row.secondary and row.secondary ~= "" then
			weaponText = weaponText .. "\n" .. MI_L("catalog_label_secondary") .. ": " .. row.secondary
		end
		weaponLbl:SetText(weaponText)

		timer.Simple(0, function()
			if IsValid(infoBody) then
				infoBody:InvalidateLayout(true)
			end
		end)
	end

	local stripScroll = vgui.Create("DHorizontalScroller", roleStrip)
	stripScroll:Dock(FILL)
	stripScroll:DockMargin(MI_S(8), MI_S(6), MI_S(8), MI_S(6))
	stripScroll:SetOverlap(-4)

	for i, roleRow in ipairs(bundle.roles or {}) do
		local btn = vgui.Create("DButton")
		btn:SetSize(MI_S(92), MI_S(92))
		btn:SetText("")
		btn._miRoleIndex = i
		btn.Paint = function(self, w, h)
			local sel = (ctx.roleIndex == self._miRoleIndex)
			draw.RoundedBox(4, 0, 0, w, h, Color(20, 22, 26, 255))
			surface.SetDrawColor(sel and COL.thumbSel or COL.thumbIdle)
			surface.DrawOutlinedRect(0, 0, w, h, sel and 2 or 1)
		end
		btn.DoClick = function(self)
			ctx.roleIndex = self._miRoleIndex
			if ctx.refresh then ctx.refresh() end
		end

		local thumb = vgui.Create("DModelPanel", btn)
		thumb:Dock(FILL)
		thumb:DockMargin(4, 4, 4, 18)
		thumb:SetFOV(32)
		thumb._miRefitCamera = false
		thumb.LayoutEntity = function(self, ent)
			if not IsValid(ent) then return end
			if self._miRefitCamera ~= true then
				self._miRefitCamera = true
				MissionIntro.FitCatalogPreviewCamera(self, ent, "head")
			end
		end
		MI_SetRoleThumbModel(thumb, roleRow)

		local cap = vgui.Create("DLabel", btn)
		cap:Dock(BOTTOM)
		cap:SetTall(MI_S(18))
		cap:SetFont(MI_Font(14, 700))
		cap:SetTextColor(COL.title)
		cap:SetContentAlignment(5)
		cap:SetText(MI_GetRoleName(roleRow, bundle))

		stripScroll:AddPanel(btn)
	end
end

local function MI_BuildFactionSidebar(ctx)
	local sidebar = ctx.sidebar
	sidebar:Clear()

	local relBtn = vgui.Create("DButton", sidebar)
	relBtn:Dock(BOTTOM)
	relBtn:SetTall(MI_S(46))
	relBtn:DockMargin(MI_S(8), MI_S(6), MI_S(8), MI_S(8))
	relBtn:SetText("")
	relBtn.Paint = function(self, w, h)
		local active = (ctx.catalogTab == TAB_RELATIONS)
		local col = active and COL.btnHover or COL.btn
		if self:IsHovered() and not active then
			col = Color(col.r + 16, col.g + 16, col.b + 16)
		end
		draw.RoundedBox(6, 0, 0, w, h, col)
		draw.SimpleText(MI_L("catalog_tab_relations"), MI_Font(15, 700), w * 0.5, h * 0.5, COL.title, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	relBtn.DoClick = function()
		ctx.catalogTab = TAB_RELATIONS
		if ctx.refresh then ctx.refresh() end
	end
	ctx.relationsBtn = relBtn

	local iconHost = vgui.Create("DPanel", sidebar)
	iconHost:Dock(FILL)
	iconHost:SetPaintBackground(false)
	ctx.iconHost = iconHost

	local factions = ctx.factions or {}
	local cols = 2
	local iconSize = MI_S(52)
	local gap = MI_S(8)
	local x0, y0 = MI_S(10), MI_S(10)

	iconHost.PerformLayout = function(self, w, h)
		for _, child in ipairs(self:GetChildren()) do
			if not IsValid(child) or not child._miBundleIndex then continue end
			local i = child._miBundleIndex
			local col = (i - 1) % cols
			local row = math.floor((i - 1) / cols)
			child:SetSize(iconSize, iconSize)
			child:SetPos(x0 + col * (iconSize + gap), y0 + row * (iconSize + gap))
		end
	end

	for i, bundle in ipairs(factions) do
		local btn = vgui.Create("DButton", iconHost)
		btn:SetSize(iconSize, iconSize)
		btn:SetText("")
		btn._miBundleIndex = i
		btn.Paint = function(self, w, h)
			local sel = (ctx.catalogTab == TAB_ROLES and ctx.bundleIndex == self._miBundleIndex)
			draw.RoundedBox(h * 0.5, 0, 0, w, h, COL.iconBg)
			if sel then
				surface.SetDrawColor(COL.iconSel)
				surface.DrawOutlinedRect(0, 0, w, h, 3)
			elseif self:IsHovered() then
				surface.SetDrawColor(COL.iconHover)
				surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 2)
			else
				surface.SetDrawColor(255, 255, 255, 35)
				surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 1)
			end
		end
		btn.PaintOver = function(self, w, h)
			if self._miIconHasTexture then return end
			local padIcon = MI_S(10)
			local size = w - padIcon * 2
			local col = self._miIconColor or COL.accent
			draw.RoundedBox(size * 0.5, padIcon, padIcon, size, size, Color(col.r, col.g, col.b, 220))
			if self._miIconFallback then
				draw.SimpleText(self._miIconFallback, MI_Font(16, 800), w * 0.5, h * 0.5, COL.title, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
		MI_CreateFactionIcon(btn, bundle, 7)
		btn.DoClick = function(self)
			ctx.catalogTab = TAB_ROLES
			ctx.bundleIndex = self._miBundleIndex
			ctx.roleIndex = 1
			if ctx.refresh then ctx.refresh() end
		end
	end

	iconHost:InvalidateLayout(true)
end

local function MI_RefreshCatalogView(ctx)
	MI_BuildFactionSidebar(ctx)
	if ctx.catalogTab == TAB_RELATIONS then
		MI_FillRelationsView(ctx)
	else
		MI_FillRolesView(ctx)
	end
end

function MissionIntro.CloseCatalogHud()
	if IsValid(MissionIntro._catalogPanel) then
		MissionIntro._catalogPanel:Remove()
	end
	MissionIntro._catalogPanel = nil
end

function MissionIntro.OpenCatalogHud()
	if IsValid(MissionIntro._catalogPanel) then return end

	if MissionIntro.PrecacheCatalogModels then
		MissionIntro.PrecacheCatalogModels()
	end

	if not istable(MissionIntro.CatalogData) then
		MI_RequestCatalog()
	end

	local data = MissionIntro.CatalogData
	local fr = vgui.Create("DFrame")
	fr:SetSize(math.min(MI_S(980), ScrW() - MI_S(40)), math.min(MI_S(680), ScrH() - MI_S(60)))
	fr:Center()
	fr:MakePopup()
	fr:SetTitle("")
	fr:ShowCloseButton(true)
	MissionIntro._catalogPanel = fr

	fr.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, COL.bg)
		surface.SetDrawColor(COL.border)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	local ctx = {
		bundleIndex = 1,
		roleIndex = 1,
		catalogTab = TAB_ROLES,
		data = data,
		factions = MI_GetCatalogFactions(data),
	}

	local sidebar = vgui.Create("DPanel", fr)
	sidebar:Dock(LEFT)
	sidebar:SetWide(MI_S(132))
	sidebar.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, COL.sidebar)
	end
	ctx.sidebar = sidebar

	local body = vgui.Create("DPanel", fr)
	body:Dock(FILL)
	body.Paint = function() end
	ctx.body = body

	local header = vgui.Create("DPanel", body)
	header:Dock(TOP)
	header:SetTall(MI_S(118))
	header.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, COL.header)
		if not self._miEmblemOk and isstring(self._miTitle) and self._miTitle ~= "" and self._miTitle ~= "?" then
			draw.SimpleText(string.sub(self._miTitle, 1, 3), MI_Font(20, 800), w * 0.5, MI_S(34), COL.title, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		draw.SimpleText(self._miTitle or "", MI_Font(26, 800), w * 0.5, MI_S(86), COL.title, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end
	header.PerformLayout = function(self, w, h)
		if IsValid(self._miEmblemImg) then
			local size = MI_S(68)
			self._miEmblemImg:SetSize(size, size)
			self._miEmblemImg:SetPos(w * 0.5 - size * 0.5, MI_S(10))
		end
	end
	ctx.header = header

	local roleStrip = vgui.Create("DPanel", body)
	roleStrip:Dock(BOTTOM)
	roleStrip:SetTall(MI_S(108))
	roleStrip.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(18, 20, 24, 255))
		surface.SetDrawColor(COL.border)
		surface.DrawLine(0, 0, w, 0)
	end
	ctx.roleStrip = roleStrip

	local main = vgui.Create("DPanel", body)
	main:Dock(FILL)
	main.Paint = function() end
	ctx.main = main

	local preview = vgui.Create("DModelPanel", fr)
	preview:SetFOV(40)
	preview:SetVisible(false)
	preview._miRefitCamera = false
	MissionIntro._catalogPreview = preview
	ctx.preview = preview

	local function refresh()
		ctx.data = MissionIntro.CatalogData
		ctx.factions = MI_GetCatalogFactions(ctx.data)
		MI_PrecacheCatalogEmblems(ctx.factions)
		MI_RefreshCatalogView(ctx)
	end

	ctx.refresh = refresh
	fr._miRefreshCatalog = refresh
	refresh()

	fr.Think = function(self)
		if istable(MissionIntro.CatalogData) and MissionIntro.CatalogData ~= ctx.data then
			ctx.data = MissionIntro.CatalogData
			ctx.factions = MI_GetCatalogFactions(ctx.data)
			if self._miRefreshCatalog then
				self._miRefreshCatalog()
			end
		end
	end

	fr.OnClose = function()
		if MissionIntro._catalogPanel == fr then
			MissionIntro._catalogPanel = nil
		end
		MissionIntro._catalogPreview = nil
	end
end

function MissionIntro.ToggleCatalogHud()
	if IsValid(MissionIntro._catalogPanel) then
		MissionIntro.CloseCatalogHud()
		return
	end

	MissionIntro.OpenCatalogHud()
end

net.Receive("MissionIntro_CatalogSync", function()
	local len = net.ReadUInt(32) or 0
	local data = {}

	if len > 0 then
		local compressed = net.ReadData(len)
		if isstring(compressed) and compressed ~= "" then
			local json = util.Decompress(compressed)
			if isstring(json) and json ~= "" then
				data = util.JSONToTable(json) or {}
			end
		end
	end

	MissionIntro.CatalogData = data
	MI_ClearEmblemCache()

	if MissionIntro.PrecacheCatalogModels then
		MissionIntro.PrecacheCatalogModels()
	end

	if IsValid(MissionIntro._catalogPanel) and MissionIntro._catalogPanel._miRefreshCatalog then
		MissionIntro._catalogPanel._miRefreshCatalog()
	end
end)

hook.Add("InitPostEntity", "MissionIntro_PrecacheCatalogModels", function()
	if MissionIntro.PrecacheCatalogModels then
		MissionIntro.PrecacheCatalogModels()
	end
end)

hook.Add("PlayerButtonDown", "MissionIntro_CatalogF2", function(ply, button)
	if ply ~= LocalPlayer() then return end
	if button ~= KEY_F2 then return end
	if gui.IsGameUIVisible() or gui.IsConsoleVisible() then return end
	if MissionIntro.IsPlaying and MissionIntro.IsPlaying(ply) then return end

	MissionIntro.ToggleCatalogHud()
end)

concommand.Add("mission_intro_catalog", function()
	MissionIntro.ToggleCatalogHud()
end)
