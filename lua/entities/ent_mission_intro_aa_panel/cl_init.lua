include("shared.lua")

local COL_OK = Color(80, 200, 120)
local COL_OFF = Color(220, 90, 70)
local COL_TEXT = Color(235, 240, 248)

function ENT:Draw()
	self:DrawModel()
end

function ENT:DrawScreen3D2D()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if ply:GetPos():DistToSqr(self:GetPos()) > (220 * 220) then return end

	local closing = MissionIntro._aaClosingInProgress == true
	local shutdown = MissionIntro._aaSystemShutdown == true
	local active = self:GetAaActive()
	local status, statusCol
	if closing then
		status = MissionIntro.L and MissionIntro.L("aa_status_closing") or "正在关闭"
		statusCol = Color(220, 150, 60)
	elseif shutdown or not active then
		status = MissionIntro.L and MissionIntro.L("aa_status_off") or "关闭"
		statusCol = COL_OFF
	else
		status = MissionIntro.L and MissionIntro.L("aa_status_normal") or "正常"
		statusCol = COL_OK
	end
	local level = math.Clamp(self:GetDangerLevel() or 0, 0, 100)

	local pos = self:GetPos() + self:GetUp() * 38
	local ang = Angle(0, ply:EyeAngles().y - 90, 90)

	cam.Start3D2D(pos, ang, 0.08)
		draw.SimpleText(MissionIntro.L and MissionIntro.L("aa_screen_title") or "设施防空系统", "DermaDefault", 0, -28, COL_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(status, "DermaDefault", 0, -8, statusCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(string.format("%.0f%%", level), "DermaDefault", 0, 12, COL_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end

function ENT:Think()
	self:DrawScreen3D2D()

	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if ply:GetPos():DistToSqr(self:GetPos()) > (180 * 180) then return end

	local hold = MissionIntro._aaShutdownHold
	if hold and IsValid(hold.ent) and hold.ent:EntIndex() == self:EntIndex() and IsValid(hold.holder) and ply ~= hold.holder and not MissionIntro._aaClosingInProgress then
		local hint = MissionIntro.L and MissionIntro.L("aa_panel_abort_hint") or "按 E 打开面板并长按阻止"
		local pos = self:GetPos() + self:GetUp() * 52
		cam.Start3D2D(pos, Angle(0, ply:EyeAngles().y - 90, 90), 0.09)
			draw.SimpleText(hint, "DermaDefault", 0, 0, Color(255, 200, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()
		return
	end

	local hint
	if MissionIntro._aaClosingInProgress then
		hint = MissionIntro.L and MissionIntro.L("aa_panel_closing_hint") or "防空正在关闭中…"
	else
		hint = MissionIntro.L and MissionIntro.L("aa_panel_use_hint") or "按 E 打开设施防空面板"
	end
	local pos = self:GetPos() + self:GetUp() * 52
	cam.Start3D2D(pos, Angle(0, ply:EyeAngles().y - 90, 90), 0.09)
		draw.SimpleText(hint, "DermaDefault", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
