include("shared.lua")

local sprite = Material("sprites/light_ignorez")

function ENT:Initialize()
	self.pixvis = util.GetPixelVisibleHandle()
end

function ENT:Draw()
	self:DrawModel()

	if not SCPWarhead then return end

	if util.PixelVisible(self:GetPos() + self:GetUp() * 2 + self:GetForward() * 3 + self:GetRight() * 0.6, 4, self.pixvis) < 0.5 then
		return
	end

	if SCPWarhead:GetInevitable() or SCPWarhead:GetWarheadState() == ENUM_SCPWARHEAD_DETONATED then
		render.SetMaterial(sprite)
		render.DrawSprite(
			self:GetPos() + self:GetUp() * 2 + self:GetForward() * 3 + self:GetRight() * 0.6,
			16,
			16,
			Color(255, 0, 0)
		)
	end
end
