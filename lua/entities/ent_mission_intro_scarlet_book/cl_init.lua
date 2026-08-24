include("shared.lua")

function ENT:Initialize()
	self:SetNoDraw(false)
end

function ENT:Draw()
	if self:GetBookDestroyed() then return end
	if self:GetRitualDone() then return end
	self:DrawModel()
end

function ENT:DrawTranslucent()
	self:Draw()
end
