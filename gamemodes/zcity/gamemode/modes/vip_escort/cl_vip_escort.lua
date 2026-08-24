MODE.name = "vipescort"

local MODE = MODE

surface.CreateFont("VIPEscort_Big", {font = "Tahoma", size = 64, weight = 700})
surface.CreateFont("VIPEscort_Med", {font = "Tahoma", size = 36, weight = 600})
surface.CreateFont("VIPEscort_Small", {font = "Tahoma", size = 22, weight = 500})

local phase = 1
local phaseEnd = 0
local extractPos = Vector()
local resultTime = 0
local resultWinner = 1
local resultVip = nil
local resultExtracted = false
local rolePrompt = "none"
local rolePromptName = "观察者"
local rolePromptEnd = 0

local gold = Color(255, 215, 0)
local guardColor = Color(70, 150, 255)
local assassinColor = Color(255, 70, 70)

net.Receive("vip_phase", function()
	phase = net.ReadInt(4)
	phaseEnd = net.ReadFloat()
	extractPos = net.ReadVector()

	surface.PlaySound(phase == 2 and "ambient/alarms/warningbell1.wav" or "buttons/button14.wav")
end)

net.Receive("vip_roundend", function()
	resultWinner = net.ReadInt(8)
	resultVip = net.ReadEntity()
	resultExtracted = net.ReadBool()
	resultTime = CurTime()

	local str = (resultWinner == 1 and "德军护卫胜利！") or "苏军刺客胜利！"
	chat.AddText(resultWinner == 1 and guardColor or assassinColor, "[VIP Escort] " .. str)
end)

net.Receive("vip_role", function()
	local newRole = net.ReadString()
	local newName = net.ReadString()
	local shouldAnnounce = newRole ~= rolePrompt or rolePromptEnd <= CurTime()
	rolePrompt = newRole ~= "" and newRole or "none"
	rolePromptName = newName ~= "" and newName or MODE.GetRoleName(rolePrompt)
	rolePromptEnd = CurTime() + 12

	if shouldAnnounce and rolePrompt ~= "none" then
		local color = rolePrompt == "vip" and gold or (rolePrompt == "guard" or rolePrompt == "guard_officer") and guardColor or assassinColor
		chat.AddText(color, "[VIP Escort] 你的职业：" .. rolePromptName)
		if rolePrompt == "vip" then
			chat.AddText(gold, "保护自己存活，并在第二阶段前往撤离点。")
		elseif rolePrompt == "guard" or rolePrompt == "guard_officer" then
			chat.AddText(guardColor, "保护 VIP，护送其到达撤离点。")
		else
			chat.AddText(assassinColor, "寻找并消灭敌方 VIP。")
		end
	end
end)

function MODE:RoundStart()
	phase = 1
	phaseEnd = 0
	extractPos = Vector()
	resultTime = 0
	resultVip = nil
	resultExtracted = false
end

local function GetVIP()
	for _, ply in player.Iterator() do
		if not IsValid(ply) then continue end
		if ply == Entity(0) then continue end
		if not ply:IsPlayer() then continue end
		if not ply:Alive() then continue end
		local ok, val = pcall(function() return ply:GetNetVar("VIPRole", "none") end)
		if ok and val == "vip" then
			return ply
		end
	end
end

local function DrawPhaseHUD()
	if CurTime() < resultTime + 6 then return end
	if phaseEnd <= 0 then return end

	local lply = LocalPlayer()
	if not lply or not IsValid(lply) then return end
	local remaining = math.max(phaseEnd - CurTime(), 0)
	local tstr = string.FormattedTime(remaining, "%02i:%02i")

	local x, y = sw * 0.5, sh * 0.08
	local title = phase == 1 and "阶段 1 — 护送 VIP 存活" or "阶段 2 — 撤离点护送"
	local col = phase == 1 and guardColor or gold

	draw.SimpleText(title, "VIPEscort_Med", x, y, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(tstr, "VIPEscort_Big", x, y + 40, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if phase == 2 then
		local dist = lply:GetPos():Distance(extractPos)
		local distStr = string.format("%.0fm", dist)
		local distCol = dist <= MODE.Config.ExtractRadius and Color(80, 255, 80) or Color(255, 255, 255)

		draw.SimpleText("撤离点距离: " .. distStr, "VIPEscort_Small", x, y + 110, distCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if dist <= MODE.Config.ExtractRadius then
			draw.SimpleText("VIP 已在撤离圈内！保持停留 " .. MODE.Config.ExtractHold .. " 秒！", "VIPEscort_Small", x, y + 140, gold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
end

local function DrawVIPArrow()
	local lply = LocalPlayer()
	if not IsValid(lply) then return end
	local role = MODE.GetRole(lply)
	if role ~= "guard" and role ~= "guard_officer" then return end

	local vip = GetVIP()
	if not IsValid(vip) then return end

	local vipPos = vip:GetPos()
	local myPos = lply:GetPos()
	local dist = vipPos:Distance(myPos)
	if dist < 1000 then return end

	local screenPos = vipPos:ToScreen()
	if not screenPos.visible then
		local dir = (vipPos - myPos):GetNormalized()
		local ang = dir:Angle()

		local cx, cy = sw * 0.5, sh * 0.5
		local radius = math.min(sw, sh) * 0.35
		local ax = cx + math.cos(math.rad(ang.y)) * radius
		local ay = cy - math.sin(math.rad(ang.y)) * radius

		ax = math.Clamp(ax, 40, sw - 40)
		ay = math.Clamp(ay, 40, sh - 40)

		surface.SetDrawColor(gold)
		local tipx = ax + math.cos(math.rad(ang.y)) * 24
		local tipy = ay - math.sin(math.rad(ang.y)) * 24
		local perpx = -math.sin(math.rad(ang.y)) * 12
		local perpy = -math.cos(math.rad(ang.y)) * 12

		surface.DrawPoly({
			{x = tipx, y = tipy},
			{x = ax + perpx, y = ay + perpy},
			{x = ax - perpx, y = ay - perpy}
		})

		draw.SimpleText("VIP", "VIPEscort_Small", ax, ay + 20, gold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function MODE:HUDPaint()
	local lply = LocalPlayer()
	if not IsValid(lply) then return end

	if CurTime() < resultTime + 6 then
		local fade = math.Clamp(6 - (CurTime() - resultTime), 0, 1)
		local col = resultWinner == 1 and guardColor or assassinColor
		col.a = 255 * fade

		local txt = (resultWinner == 1 and "德军护卫胜利！") or "苏军刺客胜利！"
		draw.SimpleText(txt, "VIPEscort_Big", sw * 0.5, sh * 0.4, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if IsValid(resultVip) and resultExtracted then
			draw.SimpleText("VIP " .. resultVip:Nick() .. " 成功撤离", "VIPEscort_Med", sw * 0.5, sh * 0.4 + 80, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		return
	end

	if not lply:Alive() then return end

	if zb.ROUND_START + 8.5 > CurTime() then
		zb.RemoveFade()
		local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)

		local role = MODE.GetRole(lply)
		if role == "none" or role == "" then role = rolePrompt end
		local roleName = MODE.GetRoleName(role)

		local col = role == "vip" and gold or (role == "guard" or role == "guard_officer") and guardColor or assassinColor
		col.a = 255 * fade

		draw.SimpleText("Z-City | VIP Escort", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("你是 " .. roleName, "VIPEscort_Med", sw * 0.5, sh * 0.45, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local objective = "保护 VIP 存活 12 分钟并前往撤离点"
		if role == "vip" then
			objective = "存活 12 分钟，随后进入撤离圈停留 3 秒"
		elseif role == "assassin" or role == "assassin_officer" then
			objective = "刺杀敌方 VIP"
		end

		draw.SimpleText(objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	-- Persistent role HUD (always show role after spawn)
	if zb.ROUND_START + 8.5 <= CurTime() then
		local role = MODE.GetRole(lply)
		if role == "none" or role == "" then role = rolePrompt end
		local roleName = MODE.GetRoleName(role)

		local col = role == "vip" and gold or (role == "guard" or role == "guard_officer") and guardColor or assassinColor

		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(10, sh - 50, 200, 35)
		draw.SimpleText(roleName, "VIPEscort_Small", 110, sh - 33, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if rolePromptEnd > CurTime() and lply:Alive() then
		local role = MODE.GetRole(lply)
		if role == "none" or role == "" then role = rolePrompt end
		local roleName = rolePromptName ~= "" and rolePromptName or MODE.GetRoleName(role)
		local col = role == "vip" and gold or (role == "guard" or role == "guard_officer") and guardColor or assassinColor
		local promptFade = math.Clamp(math.min(rolePromptEnd - CurTime(), 1), 0, 1)
		col.a = 255 * promptFade
		draw.SimpleText("你的职业：" .. roleName, "VIPEscort_Med", sw * 0.5, sh * 0.55, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	DrawPhaseHUD()
	DrawVIPArrow()
end

function MODE:PostDrawTranslucentRenderables(bDepth, bSkybox, isDraw3DSkybox)
	if bSkybox or isDraw3DSkybox then return end

	local lply = LocalPlayer()
	if not IsValid(lply) then return end

	if phase == 2 and phaseEnd > 0 and not (CurTime() < resultTime + 6) then
		render.SetColorMaterial()
		render.DrawWireframeSphere(extractPos, MODE.Config.ExtractRadius, 16, 16, gold)
	end

	local vip = GetVIP()
	if not IsValid(vip) then return end

	local pos = vip:GetPos() + Vector(0, 0, 78)
	local ang = Angle(0, lply:EyeAngles().yaw, 90)

	cam.Start3D2D(pos, ang, 0.35)
		surface.SetDrawColor(20, 20, 20, 200)
		surface.DrawRect(-40, -14, 80, 28)
		surface.SetDrawColor(gold)
		surface.DrawOutlinedRect(-40, -14, 80, 28, 2)
		draw.SimpleText("VIP", "VIPEscort_Small", 0, 0, gold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end

function MODE:RenderScreenspaceEffects()
	if zb.ROUND_START + 7.5 < CurTime() then return end
	local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)

	surface.SetDrawColor(0, 0, 0, 255 * fade)
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end
