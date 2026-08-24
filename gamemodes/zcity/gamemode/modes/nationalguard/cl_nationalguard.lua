local MODE = MODE

local phaseNames = {
	[1] = "军事行动进行中",
	[2] = "行动结束",
	[3] = "戒严状态",
}

local roleNames = {
	commander = "指挥官",
	guardsman = "步枪兵",
	medic = "医疗兵",
	engineer = "工兵",
	marksman = "精确射手",
	rioter = "暴徒",
	agitator = "煽动者",
	saboteur = "破坏者",
	sniper = "狙击手",
}

local roleColors = {
	commander = Color(255, 200, 0),
	guardsman = Color(0, 100, 200),
	medic = Color(0, 200, 100),
	engineer = Color(200, 150, 0),
	rioter = Color(180, 50, 0),
	agitator = Color(180, 50, 180),
	saboteur = Color(100, 0, 0),
	sniper = Color(80, 80, 80),
}

local curPhase = 0
local phaseEnd = 0
local riotLevel = 0
local martialLaw = false
local curfew = false
local roleStateReceived = false
local myRole = "none"
local myRoleName = "观察者"
local myTeam = 2
local myIsCommander = false
local rolePromptEnd = 0

local function GetLocalRole()
	if roleStateReceived then return myRole end
	local lply = LocalPlayer()
	if not IsValid(lply) then return "none" end
	local ok, role = pcall(function() return lply:GetNWVar("NGRole", "none") end)
	return ok and (role or "none") or "none"
end

local function GetLocalRoleName()
	if roleStateReceived then return myRoleName end
	return roleNames[GetLocalRole()] or "观察者"
end

local function GetLocalTeam()
	if roleStateReceived then return myTeam end
	local lply = LocalPlayer()
	if not IsValid(lply) then return 2 end
	local ok, teamID = pcall(function() return lply:GetNWVar("NGTeam", 2) end)
	return ok and (isnumber(teamID) and teamID or 2) or 2
end

local function IsLocalCommander()
	if roleStateReceived then return myIsCommander end
	local lply = LocalPlayer()
	return IsValid(lply) and lply:GetNWBool("IsCommander", false) or false
end

local function SendCommanderOrder(orderType)
	local lply = LocalPlayer()
	if not IsValid(lply) or not IsLocalCommander() then return end
	net.Start("ng_commander_order")
		net.WriteInt(orderType, 4)
		net.WriteVector(lply:GetPos())
	net.SendToServer()
end

local function OpenCommanderPanel()
	local lply = LocalPlayer()
	if zb.CROUND ~= "nationalguard" or not IsValid(lply) or not IsLocalCommander() then return end
	if IsValid(NG_CommanderPanel) then NG_CommanderPanel:Remove() end

	local frame = vgui.Create("DFrame")
	NG_CommanderPanel = frame
	frame:SetSize(320, 290)
	frame:Center()
	frame:SetTitle("国民警卫队 · 指挥面板")
	frame:MakePopup()
	frame:SetDeleteOnClose(true)

	local help = frame:Add("DLabel")
	help:Dock(TOP)
	help:DockMargin(12, 8, 12, 6)
	help:SetTall(34)
	help:SetWrap(true)
	help:SetText("下达行动命令。戒严/宵禁受模式配置开关控制。")

	local orders = {
		{1, "请求空投补给"},
		{2, "请求炮火支援"},
		{3, "宣布戒严"},
		{4, "宣布宵禁"}
	}
	for _, order in ipairs(orders) do
		local button = frame:Add("DButton")
		button:Dock(TOP)
		button:DockMargin(12, 3, 12, 3)
		button:SetTall(38)
		button:SetText(order[2])
		button.DoClick = function() SendCommanderOrder(order[1]) end
	end
end

hook.Add("PlayerButtonDown", "NG_OpenCommanderPanel", function(ply, button)
	if ply == LocalPlayer() and button == KEY_F3 then OpenCommanderPanel() end
end)

net.Receive("ng_phase", function()
	curPhase = net.ReadInt(4)
	phaseEnd = net.ReadFloat()
	if curPhase == 1 then
		riotLevel = 0
		martialLaw = false
		curfew = false
	end
end)

net.Receive("ng_role", function()
	local newRole = net.ReadString()
	local newRoleName = net.ReadString()
	local newTeam = net.ReadInt(3)
	local newIsCommander = net.ReadBool()
	local shouldAnnounce = not roleStateReceived or myRole ~= newRole or myTeam ~= newTeam

	roleStateReceived = true
	myRole = newRole ~= "" and newRole or "none"
	myRoleName = newRoleName ~= "" and newRoleName or roleNames[myRole] or "观察者"
	myTeam = isnumber(newTeam) and newTeam or 2
	myIsCommander = newIsCommander or myRole == "commander"
	rolePromptEnd = CurTime() + 10

	if myRole ~= "none" and shouldAnnounce then
		local color = roleColors[myRole] or color_white
		chat.AddText(color, "[国民警卫队] 你的职业：" .. myRoleName)
		if myRole == "commander" then
			chat.AddText(color, "按 F3 打开指挥面板，可下达行动命令。")
		end
	end
end)

net.Receive("ng_riot_level", function()
	riotLevel = net.ReadUInt(7)
	martialLaw = net.ReadBool()
end)

net.Receive("ng_roundend", function()
	local winner = net.ReadInt(8)
	local commander = net.ReadEntity()

	hook.Add("HUDPaint", "NG_EndRoundHUD", function()
		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawRect(0, 0, ScrW(), ScrH())

		local title = winner == 1 and "国民警卫队胜利" or "暴徒胜利"
		local titleColor = winner == 1 and Color(0, 100, 200) or Color(180, 50, 0)

		draw.SimpleText(title, "DermaLarge", ScrW() / 2, ScrH() / 2 - 80, titleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(winner == 1 and "秩序已恢复" or "暴乱席卷城市", "DermaDefault", ScrW() / 2, ScrH() / 2 - 40, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if IsValid(commander) then
			draw.SimpleText("指挥官: " .. commander:Nick(), "DermaDefault", ScrW() / 2, ScrH() / 2, Color(255, 200, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end)

	timer.Simple(10, function()
		hook.Remove("HUDPaint", "NG_EndRoundHUD")
	end)
end)

net.Receive("ng_supply_drop", function()
	local pos = net.ReadVector()

	hook.Add("HUDPaint", "NG_SupplyDropHUD", function()
		local screenPos = pos:ToScreen()
		if screenPos.visible then
			surface.SetDrawColor(255, 200, 0, 200)
			surface.DrawRect(screenPos.x - 2, screenPos.y - 2, 4, 4)

			draw.SimpleText("物资空投", "DermaDefault", screenPos.x, screenPos.y - 15, Color(255, 200, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end)

	timer.Simple(30, function()
		hook.Remove("HUDPaint", "NG_SupplyDropHUD")
	end)
end)

net.Receive("ng_martial_law", function()
	local enabled = net.ReadBool()
	martialLaw = enabled
end)

net.Receive("ng_curfew", function()
	curfew = net.ReadBool()
end)

hook.Add("HUDPaint", "NG_RiotLevelHUD", function()
	if zb.CROUND ~= "nationalguard" then return end
	local lply = LocalPlayer()
	if not IsValid(lply) then return end
	if lply:Team() == TEAM_SPECTATOR then return end

	local x, y = ScrW() - 290, 30

	draw.RoundedBox(6, x, y, 280, 108, Color(12, 16, 24, 220))

	draw.SimpleText("国民警卫队行动", "DermaDefaultBold", x + 144, y + 15, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local teamID = GetLocalTeam()
	local teamColor = teamID == 1 and Color(0, 100, 200) or Color(180, 50, 0)
	local teamName = teamID == 1 and "国民警卫队" or "叛乱分子"
	draw.RoundedBox(2, x + 8, y + 8, 4, 92, teamColor)
	draw.SimpleText("阵营: " .. teamName, "DermaDefault", x + 144, y + 37, teamColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local role = GetLocalRole()
	local roleColor = roleColors[role] or color_white
	local roleName = GetLocalRoleName()
	draw.SimpleText("职业: " .. roleName, "DermaDefault", x + 144, y + 59, roleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local timeLeft = math.max(0, phaseEnd - CurTime())
	local statusPrefix = martialLaw and "戒严 · " or curfew and "宵禁 · " or ""
	local status = statusPrefix .. string.FormattedTime(timeLeft, "%02i:%02i")
	draw.SimpleText(status, "DermaDefault", x + 144, y + 82, martialLaw and Color(255, 150, 50) or curfew and Color(180, 180, 255) or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

hook.Add("HUDPaint", "NG_RiotBarHUD", function()
	if zb.CROUND ~= "nationalguard" then return end
	local lply = LocalPlayer()
	if not IsValid(lply) then return end
	if lply:Team() == TEAM_SPECTATOR then return end

	local x, y = ScrW() - 290, 148
	local barW, barH = 240, 20

	draw.RoundedBox(6, x, y, barW, barH + 24, Color(12, 16, 24, 220))

	draw.SimpleText("暴乱度", "DermaDefault", x + barW / 2, y - 5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

	surface.SetDrawColor(60, 60, 60, 255)
	surface.DrawRect(x, y, barW, barH)

	local fillW = barW * math.Clamp(riotLevel / 100, 0, 1)
	local barColor = riotLevel > 75 and Color(200, 0, 0) or riotLevel > 50 and Color(200, 150, 0) or Color(0, 200, 0)
	surface.SetDrawColor(barColor.r, barColor.g, barColor.b, 255)
	surface.DrawRect(x, y, fillW, barH)

	draw.SimpleText(string.format("%d%%", riotLevel), "DermaDefault", x + barW / 2, y + barH / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

hook.Add("HUDPaint", "NG_CommanderHUD", function()
	if zb.CROUND ~= "nationalguard" then return end
	local lply = LocalPlayer()
	if not IsValid(lply) then return end
	if not IsLocalCommander() then return end

	local x, y = 20, ScrH() - 100

	surface.SetDrawColor(0, 0, 0, 150)
	surface.DrawRect(x, y, 300, 80)

	draw.SimpleText("[指挥官] 按F3打开指挥面板", "DermaDefault", x + 150, y + 40, Color(255, 200, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

hook.Add("ShouldDrawCrosshair", "NG_Crosshair", function()
	if zb.CROUND ~= "nationalguard" then return end
	local lply = LocalPlayer()
	if not IsValid(lply) then return end
	if GetLocalRole() == "sniper" then
		return true
	end
end)

hook.Add("HUDPaint", "NG_RolePromptHUD", function()
	if zb.CROUND ~= "nationalguard" or CurTime() >= rolePromptEnd then return end
	local lply = LocalPlayer()
	if not IsValid(lply) or lply:Team() == TEAM_SPECTATOR or GetLocalRole() == "none" then return end

	local alpha = math.Clamp((rolePromptEnd - CurTime()) * 32, 0, 255)
	local color = roleColors[GetLocalRole()] or color_white
	color = Color(color.r, color.g, color.b, alpha)
	draw.SimpleText("你的职业：" .. GetLocalRoleName(), "DermaLarge", ScrW() / 2, ScrH() * 0.2, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

hook.Add("PostDrawOpaqueRenderables", "NG_Checkpoints", function()
	if zb.CROUND ~= "nationalguard" then return end
	for _, ent in ipairs(ents.FindByClass("ent_checkpoint")) do
		if IsValid(ent) then
			local pos = ent:GetPos()

			cam.Start3D2D(pos + Vector(0, 0, 20), Angle(0, 0, 0), 0.5)
				draw.SimpleText("检查站", "DermaDefault", 0, 0, Color(0, 200, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			cam.End3D2D()
		end
	end
end)

concommand.Add("ng_debug_set_riot", function(ply, cmd, args)
	if not ply:IsAdmin() then return end
	riotLevel = tonumber(args[1]) or 0
	PrintMessage(HUD_PRINTTALK, "[DEBUG] 暴乱度设为: " .. riotLevel)
end)
