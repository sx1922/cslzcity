AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local SCREEN = MissionIntro.UiuComputerScreen or { off = 0, white = 1, green = 2, red = 3 }

function ENT:Initialize()
	local cfg = MissionIntro.UiuComputer or {}
	self:SetModel(cfg.model or "models/props_lab/monitor01a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:Sleep()
	end

	self:SetScreenState(SCREEN.off)
	self:SetHackEndTime(0)
	self:SetHacker(NULL)
	self:SetHackable(false)

	self._hackStartedAt = 0
	self:ApplyScreenColor()

	for _, key in ipairs({ "sound_hack_use", "sound_hack_deny" }) do
		local snd = cfg[key]
		if isstring(snd) and snd ~= "" then
			util.PrecacheSound(snd)
		end
	end
end

function ENT:GetHackUseSoundPath()
	local path = MissionIntro.UiuComputer and MissionIntro.UiuComputer.sound_hack_use
	if isstring(path) and path ~= "" then return path end
	return nil
end

function ENT:StopHackUseSound()
	local path = self._hackUseSoundPath or self:GetHackUseSoundPath()
	if not path then return end

	self:StopSound(path)
	self._hackUseSoundPath = nil
end

function ENT:PlayHackDenySound()
	local cfg = MissionIntro.UiuComputer or {}
	local path = cfg.sound_hack_deny
	if not isstring(path) or path == "" then return end

	local level = tonumber(cfg.sound_deny_level) or 100
	local pitch = tonumber(cfg.sound_deny_pitch) or 115
	self:EmitSound(path, level, pitch, 1, CHAN_AUTO)
end

function ENT:PlayHackUseSound()
	local path = self:GetHackUseSoundPath()
	if not path then return end

	self:StopHackUseSound()

	local level = tonumber(MissionIntro.UiuComputer and MissionIntro.UiuComputer.sound_use_level) or 85
	self._hackUseSoundPath = path
	self:EmitSound(path, level, 100, 1, CHAN_AUTO)
end

function ENT:GetUseDistance()
	return tonumber(MissionIntro.UiuComputer and MissionIntro.UiuComputer.use_distance) or 110
end

function ENT:ApplyScreenColor()
	local st = self:GetScreenState()
	local col = Color(28, 30, 36)

	if st == SCREEN.white then
		if MissionIntro._uiuMissionActive and not self:GetHackable() then
			col = Color(118, 122, 132)
		else
			col = Color(235, 238, 245)
		end
	elseif st == SCREEN.green then
		col = Color(70, 230, 110)
	elseif st == SCREEN.red then
		col = Color(235, 65, 65)
	end

	self:SetColor(col)
end

function ENT:SetScreenStateSafe(state)
	self:SetScreenState(state)
	self:ApplyScreenColor()
end

function ENT:CanUseDist(ply)
	if not IsValid(ply) then return false end
	return ply:GetPos():DistToSqr(self:GetPos()) <= self:GetUseDistance() ^ 2
end

function ENT:StartHack(ply)
	if not MissionIntro._uiuMissionActive then return false end
	if self:GetScreenState() ~= SCREEN.white then return false end
	if not MissionIntro.IsUiuPlayer or not MissionIntro.IsUiuPlayer(ply) then return false end
	if not self:GetHackable() then
		return false, "decoy"
	end

	if MissionIntro.IsUiuTeamHackingOtherComputer and MissionIntro.IsUiuTeamHackingOtherComputer(self) then
		return false, "busy"
	end

	local dur = tonumber(MissionIntro.UiuComputer and MissionIntro.UiuComputer.hack_duration) or 30
	self:SetScreenStateSafe(SCREEN.green)
	self:SetHacker(ply)
	self._hackStartedAt = CurTime()
	self:SetHackEndTime(CurTime() + dur)

	self:PlayHackUseSound()

	if SERVER then
		net.Start("MissionIntro_UiuHackUseSound")
			net.WriteEntity(self)
		net.Send(ply)
	end

	if MissionIntro.OnUiuComputerHackStarted then
		MissionIntro.OnUiuComputerHackStarted(self, ply)
	end

	return true
end

function ENT:CancelHack()
	if self:GetScreenState() ~= SCREEN.green then return end

	self:StopHackUseSound()

	self:SetScreenStateSafe(SCREEN.white)
	self:SetHacker(NULL)
	self._hackStartedAt = 0
	self:SetHackEndTime(0)

	if MissionIntro.OnUiuComputerHackCancelled then
		MissionIntro.OnUiuComputerHackCancelled(self)
	end
end

function ENT:CompleteHack()
	if self:GetScreenState() == SCREEN.red then return end

	self:StopHackUseSound()

	self:SetScreenStateSafe(SCREEN.red)
	self:SetHacker(NULL)
	self._hackStartedAt = 0
	self:SetHackEndTime(0)

	if MissionIntro.OnUiuComputerHackComplete then
		MissionIntro.OnUiuComputerHackComplete(self)
	end
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() or not activator:Alive() then return end
	if not self:CanUseDist(activator) then return end
	if not MissionIntro._uiuMissionActive then return end

	local st = self:GetScreenState()
	local isUiu = MissionIntro.IsUiuPlayer and MissionIntro.IsUiuPlayer(activator)

	if isUiu then
		if st == SCREEN.white then
			local ok, reason = self:StartHack(activator)
			if not ok and reason == "decoy" then
				self:PlayHackDenySound()
				local msg = MissionIntro.L and MissionIntro.L("uiu_decoy_terminal") or "[UIU] 此终端无法连接，换一台试试。"
				activator:ChatPrint(msg)
			elseif not ok and reason == "busy" then
				activator:ChatPrint("[UIU] 队伍正在骇入另一台终端，全队同时只能骇入一台电脑。")
			end
		elseif st == SCREEN.green then
			activator:ChatPrint("[UIU] 队伍正在骇入此终端，请等待完成。")
		elseif st == SCREEN.red then
			activator:ChatPrint("[UIU] 此终端已完成骇入。")
		else
			activator:ChatPrint("[UIU] 终端未激活。")
		end
		return
	end

	if st == SCREEN.green then
		self:CancelHack()
		self:PlayHackDenySound()
		activator:ChatPrint("[UIU] 已中断骇入，终端已关闭。")
	end
end

function ENT:Think()
	if self:GetScreenState() == SCREEN.green then
		if CurTime() >= (self:GetHackEndTime() or 0) then
			self:CompleteHack()
		end
		self:NextThink(CurTime() + 0.2)
		return true
	end

	self:NextThink(CurTime() + 0.5)
	return true
end

function ENT:PhysgunPickup(ply)
	return false
end

function ENT:GravGunPunt(ply)
	return false
end

function ENT:OnRemove()
	if SERVER and MissionIntro.RequestSaveUiuComputers then
		MissionIntro.RequestSaveUiuComputers()
	end

	if MissionIntro.OnUiuComputerRemoved then
		MissionIntro.OnUiuComputerRemoved(self)
	end
end
