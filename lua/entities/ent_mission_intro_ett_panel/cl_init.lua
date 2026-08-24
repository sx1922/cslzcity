include("shared.lua")

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if ply:GetPos():DistToSqr(self:GetPos()) > (180 * 180) then return end

	local hint = MissionIntro.L and MissionIntro.L("ett_panel_use_hint") or "按 E 打开危机指挥终端"
	local pos = self:GetPos() + self:GetUp() * 42
	cam.Start3D2D(pos, Angle(0, ply:EyeAngles().y - 90, 90), 0.09)
		draw.SimpleText(hint, "DermaDefault", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
