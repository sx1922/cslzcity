MissionIntro = MissionIntro or {}

MissionIntro._uiuReinforceCalled = MissionIntro._uiuReinforceCalled or false

local STATE = MissionIntro.UiuTerminalState or { locked = 0, ready = 1, hacking = 2, used = 3 }

local function MI_Font(size, weight)
	local name = "MissionIntro_UiuTerm_" .. size .. "_" .. (weight or 500)
	if not MI_FontCache then MI_FontCache = {} end
	if not MI_FontCache[name] then
		surface.CreateFont(name, {
			font = "Tahoma",
			size = size,
			weight = weight or 500,
			extended = true,
		})
		MI_FontCache[name] = true
	end
	return name
end

function MissionIntro.DrawUiuTerminalHackProgress(ent)
	if not IsValid(ent) or ent:GetTerminalState() ~= STATE.hacking then return end

	local endAt = ent:GetHackEndTime() or 0
	local dur = MissionIntro.GetUiuTerminalForceHackDuration and MissionIntro.GetUiuTerminalForceHackDuration() or 60
	local left = math.max(0, endAt - CurTime())
	local frac = 1 - (left / dur)

	local w, h = 280, 28
	local x, y = ScrW() * 0.5 - w * 0.5, ScrH() * 0.72

	draw.RoundedBox(6, x - 2, y - 2, w + 4, h + 4, Color(0, 0, 0, 160))
	draw.RoundedBox(4, x, y, w, h, Color(30, 34, 42, 220))
	draw.RoundedBox(4, x, y, w * math.Clamp(frac, 0, 1), h, Color(70, 200, 110, 230))

	local label = string.format("强行骇入终端… %.0f 秒", left)
	draw.SimpleText(label, MI_Font(18, 600), x + w * 0.5, y + h * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

hook.Add("HUDPaint", "MissionIntro_UiuTerminalHackBar", function()
	if not MissionIntro.IsUiuSpyPlayer or not MissionIntro.IsUiuSpyPlayer(LocalPlayer()) then return end

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_uiu_terminal")) do
		if IsValid(ent) and ent:GetTerminalState() == STATE.hacking and ent:GetHacker() == LocalPlayer() then
			MissionIntro.DrawUiuTerminalHackProgress(ent)
			return
		end
	end
end)

function MissionIntro.OpenUiuTerminalMenu(ent, canCallSilent)
	if not IsValid(ent) then return end

	canCallSilent = canCallSilent == true
	local dur = MissionIntro.GetUiuTerminalForceHackDuration and MissionIntro.GetUiuTerminalForceHackDuration() or 60

	local fr = vgui.Create("DFrame")
	fr:SetTitle("UIU 骇入终端")
	fr:SetSize(400, canCallSilent and 240 or 200)
	fr:Center()
	fr:MakePopup()
	fr._terminalEnt = ent

	local body = vgui.Create("DLabel", fr)
	body:SetPos(12, 32)
	body:SetSize(376, canCallSilent and 72 or 48)
	body:SetWrap(true)
	if canCallSilent then
		body:SetText("方式1：已黑完 5 台电脑，可呼叫 UIU 陆军（全服接管广播 + 封锁提示）。\n方式2：强行骇入本终端（全服 Z city 警报，需 " .. dur .. " 秒）。")
	else
		body:SetText("尚未黑完 5 台电脑，仅可强行骇入本终端（全服 Z city 警报，需 " .. dur .. " 秒）。")
	end
	body:SetTextColor(Color(210, 215, 225))

	local btnForce = vgui.Create("DButton", fr)
	btnForce:SetPos(12, canCallSilent and 118 or 92)
	btnForce:SetSize(376, 36)
	btnForce:SetText("强行骇入（Z city 警报 + " .. dur .. " 秒）")
	btnForce.DoClick = function()
		if not IsValid(ent) then fr:Close() return end
		net.Start("MissionIntro_UiuTerminalAction")
			net.WriteEntity(ent)
			net.WriteUInt(2, 2)
		net.SendToServer()
		fr:Close()
	end

	if canCallSilent then
		local btnCall = vgui.Create("DButton", fr)
		btnCall:SetPos(12, 162)
		btnCall:SetSize(376, 36)
		btnCall:SetText("呼叫 UIU 陆军")
		btnCall.DoClick = function()
			if not IsValid(ent) then fr:Close() return end
			net.Start("MissionIntro_UiuTerminalAction")
				net.WriteEntity(ent)
				net.WriteUInt(1, 2)
			net.SendToServer()
			fr:Close()
		end
	end

	local btnCancel = vgui.Create("DButton", fr)
	btnCancel:SetPos(12, canCallSilent and 206 or 138)
	btnCancel:SetSize(376, 24)
	btnCancel:SetText("取消")
	btnCancel.DoClick = function()
		fr:Close()
	end
end

net.Receive("MissionIntro_UiuTerminalOpen", function()
	local ent = net.ReadEntity()
	local canCallSilent = net.ReadBool()
	if MissionIntro.OpenUiuTerminalMenu then
		MissionIntro.OpenUiuTerminalMenu(ent, canCallSilent)
	end
end)
