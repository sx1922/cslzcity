if not CLIENT then return end

MissionIntro = MissionIntro or {}

local GALLERY_LABEL_FONT = { size = 20, weight = 700 }

local function MI_NormalizeImagePath(path)
	if not isstring(path) or path == "" then return nil end
	local base = path:gsub("%.png$", ""):gsub("%.vmt$", "")
	if not base:find("^materials/", 1, true) then
		base = "materials/" .. base
	end
	return base
end

function MissionIntro.ResolveMissionIntroImagePath(path, fallback)
	if not isstring(path) or path == "" then path = fallback end
	if not isstring(path) or path == "" then return nil end

	if file.Exists(path, "GAME") then return path end

	local base = MI_NormalizeImagePath(path)
	if not base then return nil end

	if file.Exists(base .. ".png", "GAME") then
		return base .. ".png"
	end
	if file.Exists(base .. ".vmt", "GAME") then
		return base
	end

	if isstring(fallback) and fallback ~= "" and fallback ~= path then
		return MissionIntro.ResolveMissionIntroImagePath(fallback, nil)
	end

	return nil
end

local function MI_GalleryLabel(galleryKey, entry)
	if istable(MissionIntro.FacilitySecurityGalleryLabels) then
		local fixed = MissionIntro.FacilitySecurityGalleryLabels[galleryKey]
		if isstring(fixed) and fixed ~= "" then return fixed end
	end
	if istable(MissionIntro.FacilitySciGalleryLabels) then
		local fixed = MissionIntro.FacilitySciGalleryLabels[galleryKey]
		if isstring(fixed) and fixed ~= "" then return fixed end
	end
	if istable(MissionIntro.FacilityMtfGalleryLabels) then
		local fixed = MissionIntro.FacilityMtfGalleryLabels[galleryKey]
		if isstring(fixed) and fixed ~= "" then return fixed end
	end
	if istable(MissionIntro.FacilityQrfGalleryLabels) then
		local fixed = MissionIntro.FacilityQrfGalleryLabels[galleryKey]
		if isstring(fixed) and fixed ~= "" then return fixed end
	end
	if istable(MissionIntro.NtfGalleryLabels) then
		local fixed = MissionIntro.NtfGalleryLabels[galleryKey]
		if isstring(fixed) and fixed ~= "" then return fixed end
	end
	if istable(entry) and isstring(entry.label_key) and entry.label_key ~= "" and MissionIntro.L then
		local s = MissionIntro.L(entry.label_key)
		if isstring(s) and s ~= "" and s ~= entry.label_key then return s end
	end
	return "角色"
end

function MissionIntro.GetFacilityGalleryRect()
	local cfg = MissionIntro.FacilitySecurityGalleryLayout or {}
	local panelH = MissionIntro.ScaleY(cfg.panel_h or 430)
	local topInset = MissionIntro.ScaleY(cfg.top_inset or 54)
	local bottomInset = MissionIntro.ScaleY(cfg.bottom_inset or 20)
	local labelGap = cfg.label_gap or 8
	local labelH = math.max(20, MissionIntro.ScaleFontSize and MissionIntro.ScaleFontSize(GALLERY_LABEL_FONT.size) or 20)

	local thumbW = math.floor(MissionIntro.ScaleX(cfg.thumb_w or 160))
	local thumbH = math.floor(MissionIntro.ScaleY(cfg.thumb_h or 272))
	local maxContentH = panelH - topInset - bottomInset
	local maxThumbH = maxContentH - labelGap - labelH

	if maxThumbH < 64 then maxThumbH = 64 end

	if thumbH > maxThumbH then
		local scale = maxThumbH / thumbH
		thumbH = math.floor(maxThumbH)
		thumbW = math.max(72, math.floor(thumbW * scale))
	end

	local contentH = thumbH + labelGap + labelH
	local x = MissionIntro.ScaleX(cfg.x or 112)
	local y = topInset + math.floor(math.max(0, maxContentH - contentH) * 0.5)

	return {
		x = x,
		y = y,
		thumbW = thumbW,
		thumbH = thumbH,
		labelY = y + thumbH + labelGap,
		labelH = labelH,
		labelGap = labelGap,
		boxH = thumbH + labelGap + labelH + 8,
	}
end

function MissionIntro.GetFacilitySecurityGalleryRect()
	return MissionIntro.GetFacilityGalleryRect()
end

function MissionIntro.BuildFacilityGalleryCache(galleryKey, entry)
	local layout = MissionIntro.GetFacilityGalleryRect()
	local label = MI_GalleryLabel(galleryKey, entry)
	local labelFont = (MissionIntro.EnsureFont and MissionIntro.EnsureFont(GALLERY_LABEL_FONT)) or "DermaDefaultBold"
	local imagePath = MissionIntro.ResolveMissionIntroImagePath(entry.image, entry.fallback_image)
	local mat
	if imagePath and MissionIntro.GetEmblemMaterial then
		mat = MissionIntro.GetEmblemMaterial(imagePath)
		if mat and mat:IsError() then mat = nil end
	end

	return {
		label = label,
		labelFont = labelFont,
		layout = layout,
		mat = mat,
	}
end

function MissionIntro.BuildFacilitySecurityGalleryCache(factionId, entry)
	return MissionIntro.BuildFacilityGalleryCache(factionId, entry)
end

function MissionIntro.StopFacilityGallery()
	timer.Remove("MissionIntro_FacilityGalleryEnd")
	if IsValid(MissionIntro._facilityGalleryPanel) then
		MissionIntro._facilityGalleryPanel:Remove()
	end
	MissionIntro._facilityGalleryPanel = nil
	MissionIntro._facilitySecurityGalleryPanel = nil
end

function MissionIntro.StopFacilitySecurityGallery()
	MissionIntro.StopFacilityGallery()
end

local PANEL = {}

function PANEL:Init()
	self:SetPaintBackground(false)
	self:SetMouseInputEnabled(false)
	self:SetKeyboardInputEnabled(false)
end

function PANEL:Setup(cache, endAt, startAt)
	self.Cache = cache
	self.EndAt = endAt
	self.StartAt = startAt
	local layout = cache.layout
	self:SetPos(layout.x - 4, layout.y - 4)
	self:SetSize(layout.thumbW + 8, layout.boxH)
end

function PANEL:Paint(w, h)
	local cache = self.Cache
	if not cache or not cache.layout then return end

	local now = CurTime()
	if now >= (self.EndAt or 0) then
		MissionIntro.StopFacilityGallery()
		return
	end

	local elapsed = now - (self.StartAt or now)
	local fadeIn = math.Clamp(elapsed / 0.35, 0, 1)
	local fadeOut = math.Clamp((self.EndAt - now) / 0.45, 0, 1)
	local alpha = math.floor(255 * math.min(fadeIn, fadeOut))
	if alpha <= 0 then return end

	local layout = cache.layout
	local thumbW, thumbH = layout.thumbW, layout.thumbH
	local imgX, imgY = 4, 4
	local labelY = layout.labelY - layout.y
	local label = cache.label or "角色"
	local labelFont = cache.labelFont or "DermaDefaultBold"

	surface.SetDrawColor(8, 14, 24, math.floor(alpha * 0.78))
	surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(95, 175, 220, alpha)
	surface.DrawOutlinedRect(0, 0, w, h, 1)

	local mat = cache.mat
	if mat and not mat:IsError() then
		surface.SetMaterial(mat)
		surface.SetDrawColor(255, 255, 255, alpha)
		surface.DrawTexturedRect(imgX, imgY, thumbW, thumbH)
	else
		surface.SetDrawColor(40, 50, 65, alpha)
		surface.DrawRect(imgX, imgY, thumbW, thumbH)
	end

	draw.SimpleText(label, labelFont, w * 0.5 + 1, labelY + 1, Color(0, 0, 0, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw.SimpleText(label, labelFont, w * 0.5, labelY, Color(235, 245, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

vgui.Register("MissionIntroSecurityGallery", PANEL, "DPanel")

function MissionIntro.ShowFacilityGallery(factionId, ply)
	if not MissionIntro.GetFacilityGalleryEntry then return end

	local entry, galleryKey = MissionIntro.GetFacilityGalleryEntry(factionId, ply)
	if not entry then return end
	galleryKey = galleryKey or factionId

	MissionIntro.StopFacilityGallery()

	local duration = tonumber(
		MissionIntro.FacilityScpGalleryDuration
			or MissionIntro.NtfGalleryDuration
			or MissionIntro.FacilityQrfGalleryDuration
			or MissionIntro.FacilityMtfGalleryDuration
			or MissionIntro.FacilitySciGalleryDuration
			or MissionIntro.FacilitySecurityGalleryDuration
	) or 13
	local cache = MissionIntro.BuildFacilityGalleryCache(galleryKey, entry)
	local startAt = CurTime()
	local endAt = startAt + duration

	local panel = vgui.Create("MissionIntroSecurityGallery")
	panel:Setup(cache, endAt, startAt)
	MissionIntro._facilityGalleryPanel = panel
	MissionIntro._facilitySecurityGalleryPanel = panel

	timer.Create("MissionIntro_FacilityGalleryEnd", duration, 1, function()
		MissionIntro.StopFacilityGallery()
	end)
end

function MissionIntro.ShowFacilitySecurityGallery(factionId)
	MissionIntro.ShowFacilityGallery(factionId, LocalPlayer())
end

function MissionIntro.ShowFacilitySciGallery(factionId, ply)
	MissionIntro.ShowFacilityGallery(factionId, ply or LocalPlayer())
end

hook.Add("OnScreenSizeChanged", "MissionIntro_RefreshFacilityGalleryLayout", function()
	local panel = MissionIntro._facilityGalleryPanel
	if not IsValid(panel) or not panel.Cache then return end
	local fid = MissionIntro.Active and MissionIntro.Active.factionId
	local ply = (MissionIntro.Active and MissionIntro.Active.ply) or LocalPlayer()
	local entry, galleryKey = fid and MissionIntro.GetFacilityGalleryEntry and MissionIntro.GetFacilityGalleryEntry(fid, ply)
	if not entry then return end
	local cache = MissionIntro.BuildFacilityGalleryCache(galleryKey or fid, entry)
	panel.Cache = cache
	panel:Setup(cache, panel.EndAt, panel.StartAt)
end)

-- 兼容旧调用（图鉴已改 VGUI，不再占用 HUDPaint）
function MissionIntro.DrawFacilitySecurityGalleryHud() end

concommand.Add("mission_intro_security_gallery_test", function(_, _, args)
	local fid = args[1] or "facility_security_rookie"
	MissionIntro.ShowFacilityGallery(fid, LocalPlayer())
end)

concommand.Add("mission_intro_sci_gallery_test", function(_, _, args)
	local fid = args[1] or "facility_researcher"
	MissionIntro.ShowFacilitySciGallery(fid, LocalPlayer())
end)

for _, hookName in ipairs({
	"RoundStart",
	"Breach_NewRound",
	"OnNewRound",
	"HMCD_NewRound",
	"HomigradRoundStart",
	"PostCleanupMap",
	"ZB_PreRoundStart",
	"ZB_EndRound",
}) do
	hook.Add(hookName, "MissionIntro_FacilityGalleryReset", function()
		MissionIntro.StopFacilityGallery()
	end)
end
