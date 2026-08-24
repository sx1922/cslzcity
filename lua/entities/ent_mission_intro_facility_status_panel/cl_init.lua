include("shared.lua")

local COL_TITLE = Color(245, 248, 252, 255)
local COL_HINT = Color(200, 210, 220, 220)
local COL_PA = Color(255, 100, 80, 255)
local FONT_FLOAT

local function MI_EnsureFloatFont()
	if FONT_FLOAT then return FONT_FLOAT end
	if MissionIntro.EnsureFont then
		FONT_FLOAT = MissionIntro.EnsureFont({ size = 52, weight = 700, antialias = true })
	else
		FONT_FLOAT = "DermaLarge"
	end
	return FONT_FLOAT
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local cfg = MissionIntro.FacilityStatusPanel or {}
	local useDist = tonumber(cfg.use_distance) or 140
	if ply:GetPos():DistToSqr(self:GetPos()) > useDist * useDist then return end

	MI_EnsureFloatFont()

	local mins, maxs = self:OBBMins(), self:OBBMaxs()
	local c = self:OBBCenter()
	local labelUp = tonumber(cfg.label_offset) or 10
	local labelScale = tonumber(cfg.label_scale) or 0.11
	local topPos = self:LocalToWorld(Vector(c.x, c.y, maxs.z + labelUp))
	local ang = Angle(0, ply:EyeAngles().y - 90, 90)

	cam.Start3D2D(topPos, ang, labelScale)
		draw.SimpleText("设施终端", FONT_FLOAT, 0, 0, COL_TITLE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		if self:GetPAActive() then
			draw.SimpleText("广播 ON", "DermaDefault", 0, 34, COL_PA, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		else
			draw.SimpleText("按 E 打开", "DermaDefault", 0, 34, COL_HINT, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
	cam.End3D2D()
end
