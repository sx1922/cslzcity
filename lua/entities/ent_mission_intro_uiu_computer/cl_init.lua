include("shared.lua")

local SCREEN = MissionIntro.UiuComputerScreen or { off = 0, white = 1, green = 2, red = 3 }

function ENT:Draw()
	self:DrawModel()
end

function ENT:GetHackUseSoundPath()
	local path = MissionIntro.UiuComputer and MissionIntro.UiuComputer.sound_hack_use
	if isstring(path) and path ~= "" then return path end
	return nil
end

function ENT:StopHackUseSoundLocal()
	local path = self:GetHackUseSoundPath()
	if not path then return end
	self:StopSound(path)
end

function ENT:PlayHackUseSoundLocal()
	local path = self:GetHackUseSoundPath()
	if not path then return end

	self:StopHackUseSoundLocal()
	local level = tonumber(MissionIntro.UiuComputer and MissionIntro.UiuComputer.sound_use_level) or 85
	self:EmitSound(path, level, 100, 1, CHAN_AUTO)
end

net.Receive("MissionIntro_UiuHackUseSound", function()
	local ent = net.ReadEntity()
	if IsValid(ent) and ent.PlayHackUseSoundLocal then
		ent:PlayHackUseSoundLocal()
	end
end)

function ENT:Think()
	local st = self:GetScreenState()
	local prev = self._miLastScreenState

	if prev == SCREEN.green and st ~= SCREEN.green then
		self:StopHackUseSoundLocal()
	end

	self._miLastScreenState = st

	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if not MissionIntro._uiuMissionActive then return end
	if ply:GetPos():DistToSqr(self:GetPos()) > (140 * 140) then return end

	local hint
	if MissionIntro.IsUiuPlayer and MissionIntro.IsUiuPlayer(ply) then
		if st == SCREEN.white then
			if MissionIntro.IsUiuTeamHackingOtherComputer and MissionIntro.IsUiuTeamHackingOtherComputer(self) then
				hint = "队伍正在骇入其他终端"
			elseif self.GetHackable and not self:GetHackable() then
				hint = "按 E 尝试连接"
			else
				hint = "按 E 开始骇入"
			end
		elseif st == SCREEN.green then
			local left = math.max(0, (self:GetHackEndTime() or 0) - CurTime())
			hint = string.format("骇入中 %.0fs", left)
		end
	else
		if st == SCREEN.green then
			hint = "按 E 关闭终端"
		end
	end

	if hint then
		local pos = self:GetPos() + self:GetUp() * 18
		cam.Start3D2D(pos, Angle(0, ply:EyeAngles().y - 90, 90), 0.08)
			draw.SimpleText(hint, "DermaDefault", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()
	end
end
