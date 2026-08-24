AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local STATE = MissionIntro.UiuTerminalState or { locked = 0, ready = 1, hacking = 2, used = 3 }

function ENT:Initialize()
	self:SetModel(MissionIntro.GetUiuTerminalModel and MissionIntro.GetUiuTerminalModel() or "models/props_combine/combine_interface003.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:Sleep()
	end

	self:SetTerminalState(STATE.locked)
	self:SetHackEndTime(0)
	self:SetHacker(NULL)
	self:ApplyTerminalColor()

	if MissionIntro.RefreshUiuTerminalStates then
		MissionIntro.RefreshUiuTerminalStates()
	end
end

function ENT:GetUseDistance()
	return tonumber(MissionIntro.UiuTerminal and MissionIntro.UiuTerminal.use_distance) or 140
end

function ENT:CanUseDist(ply)
	if not IsValid(ply) then return false end
	return ply:GetPos():DistToSqr(self:GetPos()) <= self:GetUseDistance() ^ 2
end

function ENT:ApplyTerminalColor()
	local st = self:GetTerminalState()
	local col = Color(48, 52, 58)

	if st == STATE.ready then
		col = Color(95, 175, 235)
	elseif st == STATE.hacking then
		col = Color(70, 230, 110)
	elseif st == STATE.used then
		col = Color(120, 125, 135)
	end

	self:SetColor(col)
end

function ENT:SetTerminalStateSafe(state)
	self:SetTerminalState(state)
	self:ApplyTerminalColor()
end

function ENT:CancelForceHack()
	if self:GetTerminalState() ~= STATE.hacking then return end

	self:StopHackUseSound()

	self:SetHacker(NULL)
	self:SetHackEndTime(0)

	if MissionIntro.IsUiuTerminalUnlocked and MissionIntro.IsUiuTerminalUnlocked() then
		self:SetTerminalStateSafe(STATE.ready)
	else
		self:SetTerminalStateSafe(STATE.locked)
	end

	if MissionIntro.OnUiuTerminalHackCancelled then
		MissionIntro.OnUiuTerminalHackCancelled(self)
	end
end

function ENT:CompleteForceHack()
	if self:GetTerminalState() ~= STATE.hacking then return end

	self:StopHackUseSound()
	local ply = self:GetHacker()
	self:SetHacker(NULL)
	self:SetHackEndTime(0)

	if MissionIntro.OnUiuTerminalForceHackComplete then
		MissionIntro.OnUiuTerminalForceHackComplete(self, ply)
	end

	if MissionIntro._uiuReinforceCalled then
		self:SetTerminalStateSafe(STATE.used)
	elseif MissionIntro.IsUiuTerminalUnlocked and MissionIntro.IsUiuTerminalUnlocked() then
		self:SetTerminalStateSafe(STATE.ready)
	else
		self:SetTerminalStateSafe(STATE.locked)
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

function ENT:PlayHackUseSound()
	local path = self:GetHackUseSoundPath()
	if not path then return end
	self:StopHackUseSound()
	local level = tonumber(MissionIntro.UiuComputer and MissionIntro.UiuComputer.sound_use_level) or 85
	self._hackUseSoundPath = path
	self:EmitSound(path, level, 100, 1, CHAN_AUTO)
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() or not activator:Alive() then return end
	if not self:CanUseDist(activator) then return end

	local st = self:GetTerminalState()
	local isSpy = MissionIntro.IsUiuSpyPlayer and MissionIntro.IsUiuSpyPlayer(activator)

	if st == STATE.hacking then
		if isSpy then
			activator:ChatPrint("[UIU] 正在强行骇入终端，请等待完成。")
		else
			self:CancelForceHack()
			activator:ChatPrint("[设施] 已中断对 UIU 终端的强行骇入。")
		end
		return
	end

	if not isSpy then
		if st == STATE.ready then
			activator:ChatPrint("[设施] 终端处于待命状态，仅 UIU 人员可操作。")
		end
		return
	end

	if st == STATE.locked then
		if not MissionIntro._uiuMissionActive then
			activator:ChatPrint("[UIU] 终端未激活。")
			return
		end
		if MissionIntro.OpenUiuTerminalMenuForPlayer then
			MissionIntro.OpenUiuTerminalMenuForPlayer(activator, self)
		end
		return
	end

	if st == STATE.used or MissionIntro._uiuReinforceCalled then
		activator:ChatPrint("[UIU] 大部队已呼叫，终端已锁定。")
		return
	end

	if MissionIntro.OpenUiuTerminalMenuForPlayer then
		MissionIntro.OpenUiuTerminalMenuForPlayer(activator, self)
	end
end

function ENT:Think()
	if self:GetTerminalState() == STATE.hacking then
		if CurTime() >= (self:GetHackEndTime() or 0) then
			self:CompleteForceHack()
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
	if SERVER and MissionIntro.RequestSaveUiuTerminals then
		MissionIntro.RequestSaveUiuTerminals()
	end
end
