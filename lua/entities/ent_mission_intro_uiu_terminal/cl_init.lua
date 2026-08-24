include("shared.lua")

local STATE = MissionIntro.UiuTerminalState or { locked = 0, ready = 1, hacking = 2, used = 3 }

function ENT:Draw()
	self:DrawModel()
end
