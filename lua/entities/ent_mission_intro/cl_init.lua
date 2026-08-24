include("shared.lua")

function ENT:Draw()
	self:DrawModel()
end

function ENT:DrawTranslucent()
	self:Draw()

	local pos = self:GetPos() + self:GetUp() * 18
	local ang = LocalPlayer():EyeAngles()
	ang:RotateAroundAxis(ang:Forward(), 90)
	ang:RotateAroundAxis(ang:Right(), 90)

	local V = MissionIntro and MissionIntro.Visual
	local fontDef = V and V.fonts and V.fonts.terminal or { size = 22, weight = 500 }
	local font = MissionIntro.EnsureFont and MissionIntro.EnsureFont(fontDef) or "DermaDefault"

	cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.08)
		draw.SimpleText(MissionIntro.L("terminal_title"), font, 0, -12, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(MissionIntro.L("terminal_hint"), font, 0, 8, Color(160, 255, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
