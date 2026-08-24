if not CLIENT then return end

MissionIntro._uiuMissionActive = MissionIntro._uiuMissionActive or false
MissionIntro._uiuMissionComplete = MissionIntro._uiuMissionComplete or false
MissionIntro._uiuTerminalUnlocked = MissionIntro._uiuTerminalUnlocked or false
MissionIntro._uiuReinforceCalled = MissionIntro._uiuReinforceCalled or false
MissionIntro._uiuShowHud = MissionIntro._uiuShowHud or false
MissionIntro._uiuShowEvacMarkers = MissionIntro._uiuShowEvacMarkers or false
MissionIntro._uiuHackedCount = MissionIntro._uiuHackedCount or 0
MissionIntro._uiuGoalCount = MissionIntro._uiuGoalCount or 5

local function MI_Font(size, weight)
	if MissionIntro.EnsureFont then
		return MissionIntro.EnsureFont({ size = size or 20, weight = weight or 700 })
	end
	return "DermaDefault"
end

function MissionIntro.DestroyUiuTakeoverHUD()
	if timer.Exists("MissionIntro_UiuTakeoverHide") then
		timer.Remove("MissionIntro_UiuTakeoverHide")
	end

	if IsValid(MissionIntro._uiuTakeoverPanel) then
		MissionIntro._uiuTakeoverPanel:Remove()
	end
	MissionIntro._uiuTakeoverPanel = nil
end

function MissionIntro.ShowUiuTakeoverHUD(text, duration)
	if MissionIntro.DestroyUiuTakeoverHUD then
		MissionIntro.DestroyUiuTakeoverHUD()
	end

	duration = tonumber(duration) or 10
	text = text or ""

	local scrW, scrH = ScrW(), ScrH()
	local pnl = vgui.Create("DPanel")
	pnl:SetSize(scrW, scrH)
	pnl:SetPos(0, 0)
	pnl:SetAlpha(0)
	pnl:SetKeyboardInputEnabled(false)
	pnl:SetMouseInputEnabled(false)
	MissionIntro._uiuTakeoverPanel = pnl

	pnl.Paint = function(self, w, h)
		surface.SetDrawColor(0, 0, 0, 160)
		surface.DrawRect(0, 0, w, h)

		local font = MI_Font(42, 800)
		local wrapW = w * 0.78
		local lines = {}
		local line = ""

		for uchar in string.gmatch(text, "[%z\1-\127\194-\244][\128-\191]*") do
			local test = line .. uchar
			surface.SetFont(font)
			if surface.GetTextSize(test) > wrapW and line ~= "" then
				lines[#lines + 1] = line
				line = uchar
			else
				line = test
			end
		end
		if line ~= "" then lines[#lines + 1] = line end
		if #lines == 0 then lines[1] = text end

		local lineH = 52
		local totalH = #lines * lineH
		local startY = h * 0.5 - totalH * 0.5

		for i, ln in ipairs(lines) do
			local ty = startY + (i - 1) * lineH
			draw.SimpleText(ln, font, w * 0.5 + 2, ty + 2, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.SimpleText(ln, font, w * 0.5, ty, Color(220, 228, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
	end

	pnl:AlphaTo(255, 0.35, 0, function()
		timer.Create("MissionIntro_UiuTakeoverHide", duration, 1, function()
			if not IsValid(pnl) then
				if MissionIntro._uiuTakeoverPanel == pnl then
					MissionIntro._uiuTakeoverPanel = nil
				end
				return
			end

			pnl:AlphaTo(0, 0.45, 0, function()
				if IsValid(pnl) then pnl:Remove() end
				if MissionIntro._uiuTakeoverPanel == pnl then
					MissionIntro._uiuTakeoverPanel = nil
				end
			end)
		end)
	end)
end

local function MI_ClearLocalMissionIntroState()
	local ply = LocalPlayer()
	if IsValid(ply) then
		ply._missionIntroFaction = nil
	end
	MissionIntro._uiuMissionActive = false
	MissionIntro._uiuMissionComplete = false
	MissionIntro._uiuTerminalUnlocked = false
	MissionIntro._uiuReinforceCalled = false
	MissionIntro._uiuShowHud = false
	MissionIntro._uiuShowEvacMarkers = false
	if MissionIntro.StopAllUiuHackSounds then
		MissionIntro.StopAllUiuHackSounds()
	end
end

hook.Add("PlayerDeath", "MissionIntro_UiuClientClear", function(victim)
	if victim ~= LocalPlayer() then return end
	MissionIntro._uiuShowEvacMarkers = false
	MissionIntro._uiuShowHud = false
	local ply = LocalPlayer()
	if IsValid(ply) then
		ply._missionIntroFaction = nil
	end
end)

local MI_ClientRoundHooks = {
	"RoundStart",
	"Breach_NewRound",
	"OnNewRound",
	"HMCD_NewRound",
	"HomigradRoundStart",
}

for _, hookName in ipairs(MI_ClientRoundHooks) do
	hook.Add(hookName, "MissionIntro_UiuClientClear", function()
		MI_ClearLocalMissionIntroState()
		if MissionIntro.DestroyUiuTakeoverHUD then
			MissionIntro.DestroyUiuTakeoverHUD()
		end
		if MissionIntro.StopAllUiuHackSounds then
			MissionIntro.StopAllUiuHackSounds()
		end
	end)
end

hook.Add("HUDPaint", "MissionIntro_UiuComputerProgress", function()
	if not MissionIntro._uiuShowHud then return end

	local hacked = MissionIntro._uiuHackedCount or 0
	local goal = MissionIntro._uiuGoalCount or MissionIntro.GetUiuComputerGoal and MissionIntro.GetUiuComputerGoal() or 5
	local text = string.format("%d/%d", hacked, goal)

	local font = MI_Font(28, 700)
	local x, y = 24, ScrH() - 56
	draw.SimpleText(text, font, x + 1, y + 1, Color(0, 0, 0, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText(text, font, x, y, Color(200, 215, 240), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

	if MissionIntro._uiuMissionComplete then
		local sub = "任务完成"
		if MissionIntro._uiuTerminalUnlocked and not MissionIntro._uiuReinforceCalled
			and MissionIntro.IsUiuSpyPlayer and MissionIntro.IsUiuSpyPlayer(LocalPlayer()) then
			sub = "前往 UIU 骇入终端"
		elseif MissionIntro._uiuReinforceCalled then
			sub = "大部队已抵达"
		end
		draw.SimpleText(sub, MI_Font(18, 600), x, y + 22, Color(120, 220, 140), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
end)

net.Receive("MissionIntro_UiuComputerSync", function()
	MissionIntro._uiuMissionActive = net.ReadBool()
	MissionIntro._uiuMissionComplete = net.ReadBool()
	MissionIntro._uiuShowHud = net.ReadBool()
	MissionIntro._uiuHackedCount = net.ReadUInt(8)
	MissionIntro._uiuGoalCount = net.ReadUInt(8)
	MissionIntro._uiuShowEvacMarkers = net.ReadBool()
	MissionIntro._uiuTerminalUnlocked = net.ReadBool()
	MissionIntro._uiuReinforceCalled = net.ReadBool()
end)

net.Receive("MissionIntro_UiuTakeover", function()
	local text = net.ReadString()
	local dur = net.ReadFloat()
	if MissionIntro.ShowUiuTakeoverHUD then
		MissionIntro.ShowUiuTakeoverHUD(text, dur)
	end
end)
