if not CLIENT then return end

MissionIntro = MissionIntro or {}
MissionIntro._mcdEmployerEvacuated = MissionIntro._mcdEmployerEvacuated or false
MissionIntro._mcdEmployerDead = MissionIntro._mcdEmployerDead or false

local function MI_ResetMcdClientState()
	MissionIntro._mcdEmployerEvacuated = false
	MissionIntro._mcdEmployerDead = false
end

local MCD_PURPLE = Color(160, 80, 255, 255)
local MCD_PURPLE_SOFT = Color(160, 80, 255, 180)

local function MI_Font(size)
	if MissionIntro.EnsureFont then
		return MissionIntro.EnsureFont({ size = size or 18, weight = 600 })
	end
	return "DermaDefault"
end

local function MI_IsLocalMcdCaptain()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return false end
	if MissionIntro.IsMcdPlayer and MissionIntro.IsMcdPlayer(ply) then return true end
	if ply:GetNWString("MissionIntro_McdRole", "") ~= "" then return true end
	if ply:GetNWString("MissionIntro_FactionId", "") == "mcd_squad" then return true end
	return false
end

local function MI_GetSyncedEmployer()
	if MissionIntro._mcdEmployerEntity and IsValid(MissionIntro._mcdEmployerEntity) then
		return MissionIntro._mcdEmployerEntity
	end
	local ent = LocalPlayer():GetNWEntity("MissionIntro_McdEmployer", NULL)
	if IsValid(ent) then return ent end
	return NULL
end

local function MI_IsEmployerOnClient(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	local synced = MI_GetSyncedEmployer()
	if IsValid(synced) then return synced == ply end
	if ply:GetNWBool("MissionIntro_IsEmployer", false) then return true end
	if MissionIntro.IsMenuMcdEmployer then return MissionIntro.IsMenuMcdEmployer(ply) end
	if MissionIntro.IsEmployerPlayer then return MissionIntro.IsEmployerPlayer(ply) end
	return false
end

net.Receive("MissionIntro_McdEmployerSync", function()
	MissionIntro._mcdEmployerEntity = net.ReadEntity()
end)

net.Receive("MissionIntro_McdRadioPickupMsg", function()
	local msg = net.ReadString() or ""
	Derma_Message(msg, "MC&D 呼叫对讲机", "确定")
end)

net.Receive("MissionIntro_McdDispatchMsg", function()
	local msg = net.ReadString() or ""
	chat.AddText(MCD_PURPLE, "[MC&D] ", color_white, msg)
	notification.AddLegacy(msg, NOTIFY_GENERIC, 6)
	surface.PlaySound("buttons/button15.wav")
end)

net.Receive("MissionIntro_McdEmployerEvacuated", function()
	if not MI_IsLocalMcdCaptain() then return end
	local msg = MissionIntro.L and MissionIntro.L("mcd_employer_evacuated_hint") or "雇主已成功撤离！"
	notification.AddLegacy(msg, NOTIFY_HINT, 6)
end)

net.Receive("MissionIntro_McdEmployerDied", function()
	if not MI_IsLocalMcdCaptain() then return end
	local msg = MissionIntro.L and MissionIntro.L("mcd_employer_died_hint") or "雇主已死亡，立刻撤离！"
	notification.AddLegacy(msg, NOTIFY_ERROR, 8)
	surface.PlaySound("buttons/button10.wav")
end)

net.Receive("MissionIntro_McdClearHints", function()
	MI_ResetMcdClientState()
end)

for _, hookName in ipairs({ "RoundStart", "Breach_NewRound", "OnNewRound", "HMCD_NewRound", "HomigradRoundStart", "PostCleanupMap" }) do
	hook.Add(hookName, "MissionIntro_McdClientReset", MI_ResetMcdClientState)
end

-- 穿墙高亮雇主（Halo + IgnoreZ 标记双保险）
hook.Add("PreDrawHalos", "MissionIntro_McdEmployerESP", function()
	if not MI_IsLocalMcdCaptain() then return end

	local lp = LocalPlayer()
	local targets = {}
	for _, p in ipairs(player.GetAll()) do
		if IsValid(p) and p:Alive() and p ~= lp and MI_IsEmployerOnClient(p) then
			targets[#targets + 1] = p
		end
	end

	if #targets > 0 then
		halo.Add(targets, MCD_PURPLE, 3, 3, 3, true, true)
	end
end)

hook.Add("PostDrawTranslucentRenderables", "MissionIntro_McdEmployerESPWorld", function(depth, skybox)
	if depth or skybox then return end
	if not MI_IsLocalMcdCaptain() then return end

	local lp = LocalPlayer()
	cam.IgnoreZ(true)
	render.SetColorMaterial()

	for _, p in ipairs(player.GetAll()) do
		if not IsValid(p) or not p:Alive() or p == lp then continue end
		if not MI_IsEmployerOnClient(p) then continue end

		local base = p:GetPos() + Vector(0, 0, 40)
		render.DrawSphere(base + Vector(0, 0, 36), 14, 12, 12, MCD_PURPLE_SOFT)

		local ang = lp:EyeAngles()
		ang:RotateAroundAxis(ang:Forward(), 90)
		ang:RotateAroundAxis(ang:Right(), 90)
		cam.Start3D2D(base + Vector(0, 0, 78), Angle(0, ang.y, 90), 0.08)
			draw.SimpleText(MissionIntro.L and MissionIntro.L("mcd_employer_tag") or "雇主", MI_Font(18), 0, 0, MCD_PURPLE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()
	end

	cam.IgnoreZ(false)
end)

hook.Add("HUDPaint", "MissionIntro_McdEmployerESPMinimap", function()
	if not MI_IsLocalMcdCaptain() then return end

	local lp = LocalPlayer()
	for _, p in ipairs(player.GetAll()) do
		if not IsValid(p) or not p:Alive() or p == lp then continue end
		if not MI_IsEmployerOnClient(p) then continue end

		local scr = (p:GetPos() + Vector(0, 0, 72)):ToScreen()
		if not scr.visible then
			draw.SimpleText("◇ 雇主", MI_Font(16), ScrW() * 0.5, 48, MCD_PURPLE, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
	end
end)

hook.Add("PostDrawTranslucentRenderables", "MissionIntro_McdEvacZones", function()
	if not MissionIntro.DrawUiuEvacZoneWire then return end
	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_mcd_evac")) do
		if not IsValid(ent) then continue end
		local r = ent.GetEvacZoneRadius and ent:GetEvacZoneRadius() or 140
		MissionIntro.DrawUiuEvacZoneWire(ent:GetPos(), r, Color(160, 80, 255, 200))
	end
end)

hook.Add("HUDPaint", "MissionIntro_McdEvacBar", function()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_mcd_evac")) do
		if not IsValid(ent) or ent:GetEvacuatingPlayer() ~= ply then continue end
		local frac = ent:GetEvacProgress() or 0
		if frac <= 0 then continue end

		local scrW, scrH = ScrW(), ScrH()
		local barW, barH = math.min(360, scrW * 0.28), 16
		local x = (scrW - barW) * 0.5
		local y = scrH - 88

		draw.RoundedBox(6, x - 2, y - 2, barW + 4, barH + 4, Color(0, 0, 0, 190))
		draw.RoundedBox(4, x, y, barW * frac, barH, MCD_PURPLE)
		draw.SimpleText(MissionIntro.L and MissionIntro.L("mcd_evac_progress") or "撤离中…", MI_Font(16), x + barW * 0.5, y - 20, MCD_PURPLE, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
	end
end)

