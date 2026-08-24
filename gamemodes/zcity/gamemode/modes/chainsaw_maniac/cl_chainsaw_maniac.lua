MODE.name = "chainsaw_maniac"

local MODE = MODE

surface.CreateFont("Maniac_Big", {font = "Tahoma", size = 64, weight = 700})
surface.CreateFont("Maniac_Med", {font = "Tahoma", size = 36, weight = 600})
surface.CreateFont("Maniac_Small", {font = "Tahoma", size = 22, weight = 500})

local phase = 1
local phaseEnd = 0
local resultTime = 0
local resultWinner = 1
local resultManiac = nil
local rolePrompt = "none"
local roleWeapon = ""
local rolePromptEnd = 0

local red = Color(180, 0, 0)
local blue = Color(0, 150, 200)
local gold = Color(255, 215, 0)

net.Receive("chainsaw_phase", function()
	phase = net.ReadInt(4)
	phaseEnd = net.ReadFloat()
	surface.PlaySound(phase == 2 and "ambient/alarms/warningbell1.wav" or "buttons/button14.wav")
end)

net.Receive("chainsaw_roundend", function()
	resultWinner = net.ReadInt(8)
	resultManiac = net.ReadEntity()
	resultTime = CurTime()

	local str = (resultWinner == 0 and "电锯杀人魔获胜！") or "幸存者获胜！"
	chat.AddText(resultWinner == 0 and red or blue, "[电锯杀人魔] " .. str)
end)

net.Receive("chainsaw_roar", function()
	local maniac = net.ReadEntity()
	if IsValid(maniac) then
		maniac:EmitSound("npc/stalker/go_alert2a.wav", 100, 70)
	end
end)

net.Receive("chainsaw_charge", function()
	local maniac = net.ReadEntity()
	if IsValid(maniac) then
		maniac:EmitSound("npc/stalker/go_alert2a.wav", 100, 100)
	end
end)

net.Receive("chainsaw_role", function()
	local newRole = net.ReadString()
	local newWeapon = net.ReadString()
	local shouldAnnounce = newRole ~= rolePrompt or rolePromptEnd <= CurTime()
	rolePrompt = newRole ~= "" and newRole or "none"
	roleWeapon = newWeapon or ""
	rolePromptEnd = CurTime() + 12

	if shouldAnnounce then
		if rolePrompt == "maniac" then
			local weaponText = roleWeapon ~= "" and ("已装备 " .. roleWeapon) or "近战武器正在补发"
			chat.AddText(red, "[电锯杀人魔] 你是电锯杀人魔！", color_white, " " .. weaponText .. "。左键攻击，G键技能。")
		elseif rolePrompt == "survivor" then
			chat.AddText(blue, "[电锯杀人魔] 你是幸存者！存活到倒计时结束。")
		end
	end
end)

function MODE:RoundStart()
	phase = 1
	phaseEnd = 0
	resultTime = 0
	resultManiac = nil
end

local function GetManiac()
	for _, ply in player.Iterator() do
		if not IsValid(ply) then continue end
		if ply == Entity(0) then continue end
		if not ply:IsPlayer() then continue end
		if not ply:Alive() then continue end
		local ok, val = pcall(function() return ply:GetNetVar("ManiacRole", "none") end)
		if ok and val == "maniac" then
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
	local title = "生存倒计时"
	local col = red

	draw.SimpleText(title, "Maniac_Med", x, y, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(tstr, "Maniac_Big", x, y + 40, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local maniac = GetManiac()
	if IsValid(maniac) and lply:Team() == 1 then
		local dist = lply:GetPos():Distance(maniac:GetPos())
		local distStr = string.format("%.0fm", dist)
		local distCol = dist <= 500 and Color(255, 80, 80) or Color(255, 255, 255)
		draw.SimpleText("杀人魔距离: " .. distStr, "Maniac_Small", x, y + 90, distCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local fearEnd = lply:GetNWFloat("Maniac_FearEnd", 0)
	if CurTime() < fearEnd then
		draw.SimpleText("恐惧中！移速降低", "Maniac_Small", x, y + 120, Color(255, 80, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

local function DrawManiacHUD()
	local lply = LocalPlayer()
	if not IsValid(lply) then return end
	local ok, role = pcall(function() return lply:GetNetVar("ManiacRole", "none") end)
	if not ok or role ~= "maniac" then return end

	local x, y = sw * 0.5, sh * 0.85

	local roarCD = math.max(lply:GetNWFloat("Maniac_RoarCooldown", 0) - CurTime(), 0)
	local chargeCD = math.max(lply:GetNWFloat("Maniac_ChargeCooldown", 0) - CurTime(), 0)
	local rageEnd = lply:GetNWFloat("Maniac_RageEnd", 0)

	draw.SimpleText("咆哮: " .. (roarCD > 0 and math.ceil(roarCD) .. "s" or "就绪"), "Maniac_Small", x - 200, y, roarCD > 0 and Color(255, 80, 80) or Color(80, 255, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("冲锋: " .. (chargeCD > 0 and math.ceil(chargeCD) .. "s" or "就绪"), "Maniac_Small", x, y, chargeCD > 0 and Color(255, 80, 80) or Color(80, 255, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if CurTime() < rageEnd then
		draw.SimpleText("狂暴中！", "Maniac_Med", x + 200, y, Color(255, 215, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function MODE:HUDPaint()
	local lply = LocalPlayer()
	if not lply or not IsValid(lply) then return end

	if CurTime() < resultTime + 6 then
		local fade = math.Clamp(6 - (CurTime() - resultTime), 0, 1)
		local col = resultWinner == 0 and red or blue
		col.a = 255 * fade

		local txt = (resultWinner == 0 and "电锯杀人魔获胜！") or "幸存者获胜！"
		draw.SimpleText(txt, "Maniac_Big", sw * 0.5, sh * 0.4, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		return
	end

	if not lply:Alive() then return end

	if zb.ROUND_START + 8.5 > CurTime() then
		zb.RemoveFade()
		local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)

		local role = MODE.GetRole(lply)
		if role == "none" or role == "" then role = rolePrompt end
		local roleName = MODE.GetRoleName(role)

		local col = role == "maniac" and red or blue
		col.a = 255 * fade

		draw.SimpleText("Z-City | 电锯杀人魔", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("你是 " .. roleName, "Maniac_Med", sw * 0.5, sh * 0.45, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local objective = role == "maniac" and "猎杀所有幸存者 · 左键使用近战武器 · G键使用技能" or "存活 10 分钟"
		draw.SimpleText(objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	-- Network role state is authoritative and also covers servers where the
	-- normal round-start fade is shorter than the equipment assignment.
	if rolePromptEnd > CurTime() and lply:Alive() then
		local roleName = MODE.GetRoleName(rolePrompt)
		local roleColor = rolePrompt == "maniac" and red or blue
		local promptFade = math.Clamp(math.min(rolePromptEnd - CurTime(), 1), 0, 1)
		roleColor.a = 255 * promptFade
		draw.SimpleText("你的身份：" .. roleName, "Maniac_Med", sw * 0.5, sh * 0.55, roleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		if rolePrompt == "maniac" then
			draw.SimpleText("近战武器：" .. (roleWeapon ~= "" and roleWeapon or "补发中"), "Maniac_Small", sw * 0.5, sh * 0.60, Color(255, 255, 255, 255 * promptFade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	DrawPhaseHUD()

	local lply2 = LocalPlayer()
	if IsValid(lply2) then
		local ok2, role2 = pcall(function() return lply2:GetNetVar("ManiacRole", "none") end)
		if ok2 and role2 == "maniac" then
			DrawManiacHUD()
		end
	end
end

function MODE:PostDrawTranslucentRenderables(bDepth, bSkybox, isDraw3DSkybox)
	if bSkybox or isDraw3DSkybox then return end

	local lply = LocalPlayer()
	if not IsValid(lply) then return end

	local maniac = GetManiac()
	if not IsValid(maniac) then return end

	local pos = maniac:GetPos() + Vector(0, 0, 78)
	local ang = Angle(0, lply:EyeAngles().yaw, 90)

	cam.Start3D2D(pos, ang, 0.35)
		surface.SetDrawColor(20, 20, 20, 200)
		surface.DrawRect(-60, -14, 120, 28)
		surface.SetDrawColor(red)
		surface.DrawOutlinedRect(-60, -14, 120, 28, 2)
		draw.SimpleText("电锯杀人魔", "Maniac_Small", 0, 0, red, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end

function MODE:RenderScreenspaceEffects()
	if zb.ROUND_START + 7.5 < CurTime() then return end
	local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)

	surface.SetDrawColor(0, 0, 0, 255 * fade)
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end
