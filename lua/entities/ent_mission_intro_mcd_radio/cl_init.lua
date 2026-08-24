include("shared.lua")

function ENT:Draw()
	self:DrawModel()
end

function ENT:DrawTranslucent()
	local pos = self:GetPos() + Vector(0, 0, 18)
	local ang = LocalPlayer():EyeAngles()
	ang:RotateAroundAxis(ang:Forward(), 90)
	ang:RotateAroundAxis(ang:Right(), 90)

	cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.08)
		draw.SimpleText(MissionIntro.L and MissionIntro.L("mcd_radio_world_hint") or "MC&D 对讲机", "DermaDefault", 0, 0, Color(120, 180, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
