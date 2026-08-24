MODE.name = "gwars"

local MODE = MODE

local playstart
local ended
local ngDeployed = false

local MusicVolume = GetConVar("snd_musicvolume")

net.Receive("gwars_start", function()
	surface.PlaySound("zbattle/nigshit.mp3")
	zb.RemoveFade()
	playstart = true
	ended = nil
	ngDeployed = false

	sound.PlayFile("sound/music_themes/ghetto_loop.wav", "noblock noplay", function(station)
		if IsValid(station) then
			GWARS_LoopStation = station
			station:SetVolume(1 * MusicVolume:GetFloat())
			station:EnableLooping(true)
		end
	end)

	sound.PlayFile("sound/music_themes/ghetto_police.wav", "noblock noplay", function(station)
		if IsValid(station) then
			GWARS_LoopStation2 = station
			station:SetVolume(1 * MusicVolume:GetFloat())
			station:EnableLooping(true)
		end
	end)
end)

net.Receive("gwars_nationalguard", function()
	ngDeployed = true
	surface.PlaySound("ambient/alarms/combine_bank_alarm_loop1.wav")
end)

local teams = {
	[0] = {
		objective = "清除第聂伯帮，警惕国防军介入",
		name = "维德私人俱乐部成员",
		color1 = Color(180, 120, 0),
		color2 = Color(220, 160, 30)
	},
	[1] = {
		objective = "铲除维德俱乐部，警惕国防军介入",
		name = "第聂伯河帮成员",
		color1 = Color(0, 150, 200),
		color2 = Color(50, 200, 255)
	},
	[2] = {
		objective = "消灭所有敌对武装力量（维德+第聂伯）",
		name = "国防军特种部队",
		color1 = Color(40, 40, 120),
		color2 = Color(80, 80, 180)
	},
}

local lerpsnd = 0.3

function MODE:RenderScreenspaceEffects()
	if zb.ROUND_START + 7.5 < CurTime() then return end
	local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)
	surface.SetDrawColor(0, 0, 0, 255 * fade)
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

surface.CreateFont("timer_Font2", {
	font = "Bahnschrift",
	size = ScreenScale(12),
	extended = true,
	weight = 650,
	antialias = true,
	italic = false
})

function MODE:HUDPaint()
	if not lply:Alive() and lply:Team() ~= 2 then
		if ngDeployed and lply:Team() == 2 then
		else
			return
		end
	end

	local timeBeforeNG = (zb.ROUND_START + 180 - CurTime())
	if timeBeforeNG > 0 and zb.ROUND_START + 10.5 < CurTime() then
		local time = string.FormattedTime(timeBeforeNG, "%02i:%02i:%02i")
		surface.SetFont("timer_Font2")
		surface.SetDrawColor(255, 255, 255, 255)
		local w2, h2 = surface.GetTextSize("time before National Guard deployment!")
		surface.SetTextPos(sw * 0.5 - w2 / 2, sh * 0.05)
		surface.DrawText(time)
		surface.SetTextPos(sw * 0.5 - w2 / 2 + surface.GetTextSize(time), sh * 0.05)
		surface.DrawText(" time before National Guard deployment!")
	end

	if zb.ROUND_START + 8 < CurTime() then
		if playstart then
			sound.PlayFile("sound/music_themes/ghetto_start.wav", "noblock noplay", function(station)
				if IsValid(station) then
					station:SetVolume(0.3 * MusicVolume:GetFloat())
					station:Play()
				end
			end)
			playstart = nil
		end

		lerpsnd = LerpFT(0.01, lerpsnd, (not ended) and (lply:Alive() and lply.organism and (not lply.organism.otrub) and lply.organism.fear and math.Clamp(lply.organism.fear + 0.3 + (timeBeforeNG <= 0 and 2 or 0), 0, 1) or 0.3) or 0)

		if zb.ROUND_START + 12 < CurTime() then
			if IsValid(GWARS_LoopStation) then
				GWARS_LoopStation:SetVolume(lerpsnd * MusicVolume:GetFloat())
				GWARS_LoopStation:Play()

				if IsValid(GWARS_LoopStation2) then
					GWARS_LoopStation2:SetVolume(0)
					GWARS_LoopStation2:Play()
				end
			end
		end

		if IsValid(GWARS_LoopStation) and GWARS_LoopStation:GetState() == GMOD_CHANNEL_PLAYING then
			GWARS_LoopStation:SetVolume(lerpsnd * MusicVolume:GetFloat())
		end

		if timeBeforeNG <= 0 then
			if IsValid(GWARS_LoopStation2) then
				GWARS_LoopStation2:SetVolume(lerpsnd * MusicVolume:GetFloat())
			end

			if IsValid(GWARS_LoopStation) then
				GWARS_LoopStation:SetVolume(0)
			end
		end
	end

	if zb.ROUND_START + 8.5 < CurTime() then return end

	if not lply:Alive() and lply:Team() ~= 2 then return end
	zb.RemoveFade()
	local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)
	local team_ = lply:Team()
	local teamData = teams[team_] or teams[0]

	draw.SimpleText("ZBattle | 维德俱乐部 VS 第聂伯帮", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local Rolename = teamData.name
	local ColorRole = teamData.color1
	ColorRole.a = 255 * fade
	draw.SimpleText("你是 " .. Rolename, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local Objective = teamData.objective
	local ColorObj = teamData.color2
	ColorObj.a = 255 * fade
	draw.SimpleText(Objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if ngDeployed then
		draw.SimpleText("国防军已介入！", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.3, Color(40, 40, 120, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if hg.PluvTown.Active then
		surface.SetMaterial(hg.PluvTown.PluvMadness)
		surface.SetDrawColor(255, 255, 255, math.random(175, 255) * fade / 2)
		surface.DrawTexturedRect(sw * 0.25, sh * 0.44 - ScreenScale(15), sw / 2, ScreenScale(30))

		draw.SimpleText("SOMEWHERE IN PLUVTOWN", "ZB_ScrappersLarge", sw / 2, sh * 0.44 - ScreenScale(2), Color(0, 0, 0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

local CreateEndMenu

net.Receive("gwars_roundend", function()
	ended = true
	CreateEndMenu()
end)

local colGray = Color(85, 85, 85, 255)
local colRed = Color(180, 120, 0)
local colRedUp = Color(220, 160, 30)
local colBlue = Color(0, 100, 180)
local colBlueUp = Color(50, 150, 220)
local colNG = Color(40, 40, 120)
local colNGUp = Color(80, 80, 180)
local col = Color(255, 255, 255, 255)
local colSpect1 = Color(75, 75, 75, 255)
local colSpect2 = Color(255, 255, 255)
local colorBG = Color(55, 55, 55, 255)
local colorBGBlacky = Color(40, 40, 40, 255)
local blurMat = Material("pp/blurscreen")
local Dynamic = 0

BlurBackground = BlurBackground or hg.DrawBlur

if IsValid(hmcdEndMenu) then
	hmcdEndMenu:Remove()
	hmcdEndMenu = nil
end

CreateEndMenu = function()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end
	Dynamic = 0
	hmcdEndMenu = vgui.Create("ZFrame")

	surface.PlaySound("ambient/alarms/warningbell1.wav")

	local sizeX, sizeY = ScrW() / 2.5, ScrH() / 1.2
	local posX, posY = ScrW() / 1.3 - sizeX / 2, ScrH() / 2 - sizeY / 2
	hmcdEndMenu:SetPos(posX, posY)
	hmcdEndMenu:SetSize(sizeX, sizeY)
	hmcdEndMenu:MakePopup()
	hmcdEndMenu:SetKeyboardInputEnabled(false)
	hmcdEndMenu:ShowCloseButton(false)

	local closebutton = vgui.Create("DButton", hmcdEndMenu)
	closebutton:SetPos(5, 5)
	closebutton:SetSize(ScrW() / 20, ScrH() / 30)
	closebutton:SetText("")
	closebutton.DoClick = function()
		if IsValid(hmcdEndMenu) then
			hmcdEndMenu:Close()
			hmcdEndMenu = nil
		end
	end

	closebutton.Paint = function(self, w, h)
		surface.SetDrawColor(122, 122, 122, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
		surface.SetFont("ZB_InterfaceMedium")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local lengthX, lengthY = surface.GetTextSize("Close")
		surface.SetTextPos(lengthX - lengthX / 1.1, 4)
		surface.DrawText("Close")
	end

	hmcdEndMenu.Paint = function(self, w, h)
		BlurBackground(self)
		surface.SetFont("ZB_InterfaceMediumLarge")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local lengthX, lengthY = surface.GetTextSize("Players:")
		surface.SetTextPos(w / 2 - lengthX / 2, 20)
		surface.DrawText("Players:")
		surface.SetDrawColor(255, 0, 0, 128)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	end

	local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
	DScrollPanel:SetPos(10, 80)
	DScrollPanel:SetSize(sizeX - 20, sizeY - 90)
	function DScrollPanel:Paint(w, h)
		BlurBackground(self)
		surface.SetDrawColor(255, 0, 0, 128)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	end

	for i, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		local but = vgui.Create("DButton", DScrollPanel)
		but:SetSize(100, 50)
		but:Dock(TOP)
		but:DockMargin(8, 6, 8, -1)
		but:SetText("")
		but.Paint = function(self, w, h)
			local team_ = ply:Team()
			local isNG = team_ == 2
			local isVide = team_ == 0
			local isDnieper = team_ == 1

			local alive = ply:Alive()

			local col1, col2
			if isNG then
				col1 = alive and colNG or colGray
				col2 = alive and colNGUp or colSpect1
			elseif isVide then
				col1 = alive and colRed or colGray
				col2 = alive and colRedUp or colSpect1
			else
				col1 = alive and colBlue or colGray
				col2 = alive and colBlueUp or colSpect1
			end

			surface.SetDrawColor(col1.r, col1.g, col1.b, col1.a)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(col2.r, col2.g, col2.b, col2.a)
			surface.DrawRect(0, h / 2, w, h / 2)

			local colPly = ply:GetPlayerColor():ToColor()
			surface.SetFont("ZB_InterfaceMediumLarge")
			local lengthX, lengthY = surface.GetTextSize(ply:GetPlayerName() or "He quited...")
			surface.SetTextColor(0, 0, 0, 255)
			surface.SetTextPos(w / 2 + 1, h / 2 - lengthY / 2 + 1)
			surface.DrawText(ply:GetPlayerName() or "He quited...")

			surface.SetTextColor(colPly.r, colPly.g, colPly.b, colPly.a)
			surface.SetTextPos(w / 2, h / 2 - lengthY / 2)
			surface.DrawText(ply:GetPlayerName() or "He quited...")

			local colSpec = colSpect2
			surface.SetFont("ZB_InterfaceMediumLarge")
			local lengthX2, lengthY2 = surface.GetTextSize(ply:GetPlayerName() or "He quited...")
			surface.SetTextPos(15, h / 2 - lengthY2 / 2)
			surface.DrawText((ply:Name() .. (not alive and " - died" or "")) or "He quited...")

			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(colSpec.r, colSpec.g, colSpec.b, colSpec.a)
			local lengthX3, lengthY3 = surface.GetTextSize(ply:Frags() or "He quited...")
			surface.SetTextPos(w - lengthX3 - 15, h / 2 - lengthY3 / 2)
			surface.DrawText(ply:Frags() or "He quited...")
		end

		but.DoClick = function()
			if ply:IsBot() then
				chat.AddText(Color(255, 0, 0), "no, you can't")
				return
			end
			gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
		end

		DScrollPanel:AddItem(but)
	end

	return true
end

function MODE:RoundStart()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end
end