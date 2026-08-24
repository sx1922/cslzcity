MissionIntro = MissionIntro or {}
MissionIntro.EmblemImage = nil
MissionIntro._emblemPathCache = nil
MissionIntro._emblemMatCache = MissionIntro._emblemMatCache or {}
MissionIntro._emblemAspectCache = MissionIntro._emblemAspectCache or {}

local MI_SCARLET_EMBLEM_TEX_W = 512
local MI_SCARLET_EMBLEM_TEX_H = 512
local MI_UIU_EMBLEM_TEX_W = 512
local MI_UIU_EMBLEM_TEX_H = 512

-- 设施/阵营图标：优先使用 materials/mission_intro/*.png 原图（1:1）

local function MI_NormalizeEmblemBase(path)
	if not isstring(path) or path == "" then return nil end
	local base = path:gsub("%.png$", ""):gsub("%.vmt$", "")
	if not base:find("^materials/", 1, true) then
		base = "materials/" .. base
	end
	return base
end

local function MI_ResolveEmblemMaterial(path)
	if not isstring(path) or path == "" then return nil end
	if file.Exists(path, "GAME") then return path end

	local base = MI_NormalizeEmblemBase(path)
	if not base then return nil end

	-- 必须先 PNG：仅有 vmt 时会落到缺纹理或错误回退
	if file.Exists(base .. ".png", "GAME") then
		return base .. ".png"
	end
	if file.Exists(base .. ".vmt", "GAME") then
		return base
	end

	return nil
end

function MissionIntro.GetEmblemImagePath(plyOrState)
	local fac
	if istable(plyOrState) and (plyOrState.factionId or plyOrState.ply) then
		local stateFacId = isstring(plyOrState.factionId) and plyOrState.factionId or ""
		-- 入场 state.factionId 优先：勿用玩家身上残留的科研派系覆盖 SCP 批次
		if stateFacId ~= "" and MissionIntro.IsFacilityFactionId and MissionIntro.IsFacilityFactionId(stateFacId) then
			if IsValid(plyOrState.ply) and MissionIntro.GetFacilityFactionData then
				local stored = MissionIntro.GetStoredFacilityFactionId and MissionIntro.GetStoredFacilityFactionId(plyOrState.ply)
				if stored == stateFacId then
					fac = MissionIntro.GetFacilityFactionData(plyOrState.ply)
				end
			end
			if not fac then
				fac = {
					emblem_image = MissionIntro.GetFacilityFactionEmblem and MissionIntro.GetFacilityFactionEmblem(stateFacId),
				}
			end
		elseif IsValid(plyOrState.ply) and MissionIntro.GetFacilityFactionData then
			fac = MissionIntro.GetFacilityFactionData(plyOrState.ply)
		end
		if not fac and stateFacId ~= "" and MissionIntro.Factions then
			fac = MissionIntro.Factions[stateFacId]
		end
	elseif IsValid(plyOrState) or plyOrState == nil then
		fac = MissionIntro.GetFactionData(plyOrState or LocalPlayer())
	else
		fac = MissionIntro.GetFactionData(LocalPlayer())
	end

	if fac and fac.emblem_image and fac.emblem_image ~= "" then
		local resolved = MI_ResolveEmblemMaterial(fac.emblem_image)
		if resolved then return resolved end
	end

	if file.Exists("data/rx_mission_intro_emblem.png", "GAME") then
		return "data/rx_mission_intro_emblem.png"
	end

	local facId = istable(plyOrState) and plyOrState.factionId
	if (not facId or facId == "") and istable(plyOrState) and IsValid(plyOrState.ply) then
		if MissionIntro.GetStoredFacilityFactionId then
			facId = MissionIntro.GetStoredFacilityFactionId(plyOrState.ply)
		end
		if (not facId or facId == "") then
			facId = plyOrState.ply:GetNWString("MissionIntro_FactionId", "") or plyOrState.ply._missionIntroFaction
		end
	end
	if facId and MissionIntro.IsFacilitySecurityFactionId and MissionIntro.IsFacilitySecurityFactionId(facId) then
		return MI_ResolveEmblemMaterial("materials/mission_intro/emblem_facility_security.png")
			or MI_ResolveEmblemMaterial("materials/mission_intro/emblem_facility_security")
			or MI_ResolveEmblemMaterial("materials/mission_intro/emblem_facility_sci.png")
	end

	if facId and MissionIntro.IsFacilityQrfFactionId and MissionIntro.IsFacilityQrfFactionId(facId) then
		return MI_ResolveEmblemMaterial("materials/mission_intro/emblem_qrf_taskforce.png")
			or MI_ResolveEmblemMaterial("materials/mission_intro/emblem_qrf_taskforce")
	end
	if facId and MissionIntro.IsFacilityScpFactionId and MissionIntro.IsFacilityScpFactionId(facId) then
		return MI_ResolveEmblemMaterial("materials/mission_intro/emblem_scp.png")
			or MI_ResolveEmblemMaterial("materials/mission_intro/emblem_scp")
	end
	if facId and MissionIntro.IsFacilityMtfFactionId and MissionIntro.IsFacilityMtfFactionId(facId) then
		return MI_ResolveEmblemMaterial("materials/mission_intro/emblem_mtf_taskforce.png")
	end
	if facId and MissionIntro.IsFacilityFactionId and MissionIntro.IsFacilityFactionId(facId) then
		if facId == "classd_impostor" then
			return MI_ResolveEmblemMaterial("materials/mission_intro/emblem_classd.png")
		end
		if facId == "class_d_personnel" then
			return MI_ResolveEmblemMaterial("materials/mission_intro/emblem_classd_personnel.png")
		end
		return MI_ResolveEmblemMaterial("materials/mission_intro/emblem_facility_sci.png")
	end

	if MI_ResolveEmblemMaterial("materials/mission_intro/emblem_facility_sci.png") then
		return MI_ResolveEmblemMaterial("materials/mission_intro/emblem_facility_sci.png")
	end
	if MI_ResolveEmblemMaterial("materials/mission_intro/emblem_classd.png") then
		return MI_ResolveEmblemMaterial("materials/mission_intro/emblem_classd.png")
	end
	if file.Exists("materials/mission_intro/emblem_scarlet.png", "GAME") then
		return "materials/mission_intro/emblem_scarlet.png"
	end
	if file.Exists("materials/mission_intro/emblem_hammerfall.png", "GAME") then
		return "materials/mission_intro/emblem_hammerfall.png"
	end
	if file.Exists("materials/mission_intro/emblem_mcd.png", "GAME") then
		return "materials/mission_intro/emblem_mcd.png"
	end
	if file.Exists("materials/mission_intro/emblem_ci.png", "GAME") then
		return "materials/mission_intro/emblem_ci.png"
	end
	if file.Exists("materials/mission_intro/emblem_sid.png", "GAME") then
		return "materials/mission_intro/emblem_sid.png"
	end
	if file.Exists("materials/mission_intro/emblem_pttrb.png", "GAME") then
		return "materials/mission_intro/emblem_pttrb.png"
	end

	return nil
end

function MissionIntro.IsFacilityEmblemState(state)
	if not istable(state) then return false end
	if state.factionId and MissionIntro.IsFacilityFactionId and MissionIntro.IsFacilityFactionId(state.factionId) then
		return true
	end
	if IsValid(state.ply) and MissionIntro.GetStoredFacilityFactionId then
		return MissionIntro.GetStoredFacilityFactionId(state.ply) ~= nil
	end
	return false
end

function MissionIntro.ClearEmblemMaterialCache()
	MissionIntro._emblemMatCache = {}
	MissionIntro._emblemAspectCache = {}
end

local function MI_Be32(data, off)
	local a, b, c, d = data:byte(off, off + 3)
	if not a then return 0 end
	return ((a * 256 + b) * 256 + c) * 256 + d
end

local function MI_ReadPNGDimensions(path)
	if not isstring(path) or path == "" then return nil end

	if MissionIntro._emblemAspectCache[path] then
		local c = MissionIntro._emblemAspectCache[path]
		return c.w, c.h
	end

	local tryPaths = {}
	if path:find("%.png$", 1, true) then
		tryPaths[#tryPaths + 1] = path
	end
	local base = MI_NormalizeEmblemBase(path)
	if base then
		tryPaths[#tryPaths + 1] = base .. ".png"
	end

	for _, pngPath in ipairs(tryPaths) do
		if not file.Exists(pngPath, "GAME") then continue end

		local data = file.Read(pngPath, "GAME")
		if not data or #data < 24 then continue end
		if data:byte(1) ~= 0x89 or data:sub(2, 4) ~= "PNG" then continue end
		if data:sub(13, 16) ~= "IHDR" then continue end

		local w = MI_Be32(data, 17)
		local h = MI_Be32(data, 21)
		if w > 0 and h > 0 then
			MissionIntro._emblemAspectCache[path] = { w = w, h = h }
			return w, h
		end
	end

	return nil
end

local function MI_IsUiuEmblemPath(path)
	return isstring(path) and path:find("emblem_uiu", 1, true) ~= nil
end

local function MI_IsUiuEmblemState(state)
	if not istable(state) then return false end
	if MissionIntro.IsUiuEmblemFactionId and MissionIntro.IsUiuEmblemFactionId(state.factionId) then
		return true
	end
	if IsValid(state.ply) and MissionIntro.GetFactionId and MissionIntro.IsUiuEmblemFactionId then
		return MissionIntro.IsUiuEmblemFactionId(MissionIntro.GetFactionId(state.ply))
	end
	return false
end

local function MI_IsScarletEmblemPath(path)
	return isstring(path) and path:find("emblem_scarlet", 1, true) ~= nil
end

local function MI_IsScarletEmblemState(state)
	if not istable(state) then return false end
	if state.factionId == "scarlet_cultist" then return true end
	if IsValid(state.ply) and MissionIntro.GetFactionId and MissionIntro.GetFactionId(state.ply) == "scarlet_cultist" then
		return true
	end
	return false
end

local function MI_GetFactionEmblemTable(state)
	if not istable(state) then return nil end
	if state.factionId and MissionIntro.Factions then
		return MissionIntro.Factions[state.factionId]
	end
	if IsValid(state.ply) and MissionIntro.GetFactionData then
		return MissionIntro.GetFactionData(state.ply)
	end
	return nil
end

local function MI_ParseEmblemTexSize(fac)
	if not istable(fac) then return nil, nil end
	local ts = fac.emblem_tex_size
	if istable(ts) then
		local w = tonumber(ts[1] or ts.w)
		local h = tonumber(ts[2] or ts.h)
		if w and w > 0 and h and h > 0 then return w, h end
	end
	if isnumber(fac.emblem_tex_w) and fac.emblem_tex_w > 0 and isnumber(fac.emblem_tex_h) and fac.emblem_tex_h > 0 then
		return fac.emblem_tex_w, fac.emblem_tex_h
	end
	return nil, nil
end

local function MI_ShouldForceSquareEmblemDraw(path, state)
	if MI_IsScarletEmblemPath(path) or MI_IsScarletEmblemState(state) then return true end
	if MI_IsUiuEmblemPath(path) or MI_IsUiuEmblemState(state) then return true end
	local fac = MI_GetFactionEmblemTable(state)
	return fac and fac.emblem_force_square == true
end

local function MI_GetEmblemTextureSize(path, mat, state)
	if MI_IsScarletEmblemPath(path) or MI_IsScarletEmblemState(state) then
		return MI_SCARLET_EMBLEM_TEX_W, MI_SCARLET_EMBLEM_TEX_H
	end

	if MI_IsUiuEmblemPath(path) or MI_IsUiuEmblemState(state) then
		return MI_UIU_EMBLEM_TEX_W, MI_UIU_EMBLEM_TEX_H
	end

	local fac = MI_GetFactionEmblemTable(state)
	if fac then
		local tw, th = MI_ParseEmblemTexSize(fac)
		if tw and th then return tw, th end
		if fac.emblem_force_square == true then
			return 1, 1
		end
		if isnumber(fac.emblem_aspect) and fac.emblem_aspect > 0 then
			return fac.emblem_aspect, 1
		end
	end

	local pw, ph = MI_ReadPNGDimensions(path)
	if pw and ph and pw > 0 and ph > 0 then
		return pw, ph
	end

	if mat and not mat:IsError() then
		local tw, th = mat:Width(), mat:Height()
		if tw > 0 and th > 0 then
			return tw, th
		end
	end

	return 1, 1
end

local function MI_GetEmblemSquareUV(path, state)
	local isSquareEmblem = MI_IsScarletEmblemPath(path) or MI_IsScarletEmblemState(state)
		or MI_IsUiuEmblemPath(path) or MI_IsUiuEmblemState(state)
	if not isSquareEmblem then
		return 0, 0, 1, 1
	end

	local tw, th = MI_ReadPNGDimensions(path)
	if not tw or not th or tw <= 0 or th <= 0 then
		if MI_IsUiuEmblemPath(path) or MI_IsUiuEmblemState(state) then
			tw, th = MI_UIU_EMBLEM_TEX_W, MI_UIU_EMBLEM_TEX_H
		else
			tw, th = MI_SCARLET_EMBLEM_TEX_W, MI_SCARLET_EMBLEM_TEX_H
		end
	end

	if math.abs(tw - th) < 1 then
		return 0, 0, 1, 1
	end

	if tw > th then
		local pad = (1 - th / tw) * 0.5
		return pad, 0, 1 - pad, 1
	end

	local pad = (1 - tw / th) * 0.5
	return 0, pad, 1, 1 - pad
end

local function MI_GetEmblemMaterial(path)
	if not isstring(path) or path == "" then return nil end

	if MissionIntro._emblemMatCache[path] then
		return MissionIntro._emblemMatCache[path]
	end

	local candidates = {}
	if MI_IsScarletEmblemPath(path) then
		local pngPath = path:find("%.png$", 1, true) and path or (MI_NormalizeEmblemBase(path) .. ".png")
		candidates[#candidates + 1] = pngPath
	elseif MI_IsUiuEmblemPath(path) then
		local pngPath = path:find("%.png$", 1, true) and path or (MI_NormalizeEmblemBase(path) .. ".png")
		candidates[#candidates + 1] = pngPath
	else
		if path:find("%.png$", 1, true) then
			candidates[#candidates + 1] = path:gsub("%.png$", "")
			candidates[#candidates + 1] = path
		else
			candidates[#candidates + 1] = path
			candidates[#candidates + 1] = path .. ".png"
		end
	end

	for _, matPath in ipairs(candidates) do
		local mat = Material(matPath, "noclamp smooth")
		if mat and not mat:IsError() then
			MissionIntro._emblemMatCache[path] = mat
			return mat
		end
	end

	return nil
end

local function MI_ComputeEmblemDrawRect(cx, cy, maxSize, mat, path, state)
	maxSize = math.max(1, tonumber(maxSize) or 1)

	if MI_ShouldForceSquareEmblemDraw(path, state) then
		local x = math.floor(cx - maxSize * 0.5 + 0.5)
		local y = math.floor(cy - maxSize * 0.5 + 0.5)
		return x, y, maxSize, maxSize
	end

	local drawW, drawH = maxSize, maxSize

	local tw, th = MI_GetEmblemTextureSize(path, mat, state)
	if tw > 0 and th > 0 then
		local aspect = tw / th
		if aspect > 1.001 then
			drawW = maxSize
			drawH = maxSize / aspect
		elseif aspect < 0.999 then
			drawH = maxSize
			drawW = maxSize * aspect
		end
	end

	local x = math.floor(cx - drawW * 0.5 + 0.5)
	local y = math.floor(cy - drawH * 0.5 + 0.5)
	return x, y, math.max(1, math.floor(drawW + 0.5)), math.max(1, math.floor(drawH + 0.5))
end

local function MI_DrawEmblemMaterial(cx, cy, radius, alpha, path, state)
	local mat = MI_GetEmblemMaterial(path)
	if not mat then return false end

	local maxSize = math.max(1, math.floor(radius * 2 + 0.5))
	local x, y, w, h = MI_ComputeEmblemDrawRect(cx, cy, maxSize, mat, path, state)
	surface.SetDrawColor(255, 255, 255, alpha or 255)
	local u0, v0, u1, v1 = MI_GetEmblemSquareUV(path, state)
	surface.SetMaterial(mat)
	if u0 == 0 and v0 == 0 and u1 == 1 and v1 == 1 then
		surface.DrawTexturedRect(x, y, w, h)
	else
		surface.DrawTexturedRectUV(x, y, w, h, u0, v0, u1, v1)
	end
	return true
end

function MissionIntro.DestroyEmblemImage()
	if IsValid(MissionIntro.EmblemImage) then
		MissionIntro.EmblemImage:Remove()
	end
	MissionIntro.EmblemImage = nil
	MissionIntro._emblemPathCache = nil
	MissionIntro.ClearEmblemMaterialCache()
end

local function MI_EnsureEmblemImage(state)
	local path = MissionIntro.GetEmblemImagePath(state)
	if not path then return nil end

	if MI_GetEmblemMaterial(path) then
		return path
	end

	if MissionIntro._emblemPathCache ~= path then
		MissionIntro.DestroyEmblemImage()
		MissionIntro._emblemPathCache = path
	end

	if IsValid(MissionIntro.EmblemImage) then
		return MissionIntro.EmblemImage
	end

	local img = vgui.Create("DImage")
	img:SetPaintedManually(true)
	img:SetImage(path)
	img:SetKeepAspect(true)
	MissionIntro.EmblemImage = img
	return img
end

function MissionIntro.HasEmblemTexture(state)
	return MissionIntro.GetEmblemImagePath(state) ~= nil
end

function MissionIntro.DrawFactionEmblem(cx, cy, radius, alpha, state)
	alpha = alpha or 255

	if istable(state) and state._drawCache and state._drawCache.emblemMat then
		local mat = state._drawCache.emblemMat
		if not mat:IsError() then
			local path = state._drawCache.emblemPath
			local maxSize = math.max(1, math.floor(radius * 2 + 0.5))
			local x, y, w, h = MI_ComputeEmblemDrawRect(cx, cy, maxSize, mat, path, state)
			surface.SetDrawColor(255, 255, 255, alpha)
			local u0, v0, u1, v1 = MI_GetEmblemSquareUV(path, state)
			surface.SetMaterial(mat)
			if u0 == 0 and v0 == 0 and u1 == 1 and v1 == 1 then
				surface.DrawTexturedRect(x, y, w, h)
			else
				surface.DrawTexturedRectUV(x, y, w, h, u0, v0, u1, v1)
			end
			return
		end
	end

	local path = MissionIntro.GetEmblemImagePath(state)
	if not path then return end

	if isstring(path) and path:find("scarlet", 1, true) and MissionIntro.IsFacilityEmblemState(state) then
		path = MI_ResolveEmblemMaterial("materials/mission_intro/emblem_facility_sci.png")
			or MI_ResolveEmblemMaterial("materials/mission_intro/emblem_classd.png")
		if not path then return end
	end

	if MI_DrawEmblemMaterial(cx, cy, radius, alpha, path, state) then
		return
	end

	local img = MI_EnsureEmblemImage(state)
	if not IsValid(img) then return end

	local maxSize = math.max(1, math.floor(radius * 2 + 0.5))
	local x, y, w, h = MI_ComputeEmblemDrawRect(cx, cy, maxSize, nil, path, state)
	img:SetSize(w, h)
	img:SetPos(x, y)
	img:SetAlpha(alpha)
	img:PaintManual()
end

function MissionIntro.ComputeEmblemDrawRect(cx, cy, maxSize, mat, path, state)
	return MI_ComputeEmblemDrawRect(cx, cy, maxSize, mat, path, state)
end

function MissionIntro.GetEmblemSquareUV(path, state)
	return MI_GetEmblemSquareUV(path, state)
end

function MissionIntro.GetEmblemMaterial(path)
	path = path or MissionIntro.GetEmblemImagePath()
	return MI_GetEmblemMaterial(path) or Material("error")
end

concommand.Add("mission_intro_check_emblem", function()
	local ply = LocalPlayer()
	local facPath = MissionIntro.GetEmblemImagePath(ply)
	local st = MissionIntro.Active
	local introPath = st and MissionIntro.GetEmblemImagePath(st) or nil

	print("[MissionIntro] 当前玩家图标: " .. tostring(facPath))
	print("[MissionIntro] 入场播放图标: " .. tostring(introPath))
	print("[MissionIntro] PNG 科研: " .. tostring(file.Exists("materials/mission_intro/emblem_facility_sci.png", "GAME")))
	print("[MissionIntro] PNG 安保: " .. tostring(file.Exists("materials/mission_intro/emblem_facility_security.png", "GAME")))
	print("[MissionIntro] PNG D级: " .. tostring(file.Exists("materials/mission_intro/emblem_classd.png", "GAME")))
	local scarletPath = "materials/mission_intro/emblem_scarlet.png"
	if file.Exists(scarletPath, "GAME") then
		local data = file.Read(scarletPath, "GAME")
		if data and #data >= 24 and data:sub(13, 16) == "IHDR" then
			local a, b, c, d = data:byte(17, 20)
			local w = ((a * 256 + b) * 256 + c) * 256 + d
			a, b, c, d = data:byte(21, 24)
			local h = ((a * 256 + b) * 256 + c) * 256 + d
			print("[MissionIntro] 猩红 PNG 尺寸: " .. tostring(w) .. "x" .. tostring(h))
			print("[MissionIntro] 猩红强制绘制: " .. tostring(MI_SCARLET_EMBLEM_TEX_W) .. "x" .. tostring(MI_SCARLET_EMBLEM_TEX_H) .. " 正方形")
		end
	end
	if MissionIntro.GetEmblemMaterial then
		local mat = MissionIntro.GetEmblemMaterial(scarletPath)
		if mat and not mat:IsError() then
			print("[MissionIntro] 猩红材质尺寸: " .. tostring(mat:Width()) .. "x" .. tostring(mat:Height()))
		end
	end
end)

concommand.Add("mission_intro_reload_emblem", function()
	MissionIntro.DestroyEmblemImage()
	print("[MissionIntro] 已重置图标缓存，下次入场会重新加载 PNG")
end)
