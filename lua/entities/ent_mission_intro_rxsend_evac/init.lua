AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_NONE)
	self:SetUseType(SIMPLE_USE)
	self:SetNoDraw(true)
	self:DrawShadow(false)

	self:SetEvacProgress(0)
	self:SetEvacuatingPlayer(NULL)
	self._evacStart = 0

	local cfg = MissionIntro.RXSendEvac or {}
	self:SetEvacZoneRadius(tonumber(cfg.default_zone_radius) or 130)
end

function ENT:GetZoneRadius()
	return MissionIntro.ClampRXSendEvacRadius and MissionIntro.ClampRXSendEvacRadius(self:GetEvacZoneRadius())
		or tonumber(self:GetEvacZoneRadius()) or 130
end

function ENT:IsPlayerInZone(ply)
	return MissionIntro.IsPlayerInEvacSquare(ply, self:GetPos(), self:GetZoneRadius())
end

function ENT:CancelEvac()
	self._evacStart = 0
	self:SetEvacProgress(0)
	self:SetEvacuatingPlayer(NULL)
end

function ENT:StartEvac(ply)
	if not MissionIntro.CanRXSendPlayerEvacuate or not MissionIntro.CanRXSendPlayerEvacuate(ply, self:GetBattleTeam()) then
		return false
	end

	self._evacStart = CurTime()
	self:SetEvacuatingPlayer(ply)
	self:SetEvacProgress(0)
	return true
end

function ENT:CompleteEvac(ply)
	self:CancelEvac()
	if MissionIntro.ExecuteRXSendEvacuation then
		MissionIntro.ExecuteRXSendEvacuation(ply, self)
	end
end

function ENT:Think()
	self:NextThink(CurTime() + 0.05)

	local cfg = MissionIntro.RXSendEvac or {}
	local dur = math.max(0.05, tonumber(cfg.evac_duration) or 0.1)
	local battleTeam = self:GetBattleTeam()

	local ply = self:GetEvacuatingPlayer()
	if IsValid(ply) and ply:IsPlayer() and ply:Alive() and self._evacStart > 0 then
		if not self:IsPlayerInZone(ply) then
			self:CancelEvac()
		elseif not MissionIntro.CanRXSendPlayerEvacuate or not MissionIntro.CanRXSendPlayerEvacuate(ply, battleTeam) then
			self:CancelEvac()
		else
			local frac = math.Clamp((CurTime() - self._evacStart) / dur, 0, 1)
			self:SetEvacProgress(frac)
			if frac >= 1 then
				self:CompleteEvac(ply)
			end
		end
		return true
	end

	if self._evacStart <= 0 then
		for _, candidate in ipairs(player.GetAll()) do
			if not IsValid(candidate) or not candidate:Alive() then continue end
			if not self:IsPlayerInZone(candidate) then continue end
			if self:StartEvac(candidate) then
				break
			end
		end
	end

	return true
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end

	local battleTeam = self:GetBattleTeam()
	if activator._missionIntroEvacuated then
		activator:ChatPrint(MissionIntro.L and MissionIntro.L("generic_evac_already") or "[RX] 你已撤离。")
		return
	end

	if MissionIntro.RXSendGetBattleTeam and MissionIntro.RXSendGetBattleTeam(activator) ~= battleTeam then
		activator:ChatPrint(MissionIntro.L and MissionIntro.L("rxsend_evac_wrong_team") or "[RX] 你无法使用此撤离点。")
		return
	end

	if not MissionIntro.RXSendIsEvacZoneOpen or not MissionIntro.RXSendIsEvacZoneOpen(battleTeam) then
		local key = battleTeam == 0 and "rxsend_evac_ci_closed" or "rxsend_evac_facility_closed"
		activator:ChatPrint(MissionIntro.L and MissionIntro.L(key) or "[RX] 撤离点未开放")
		return
	end

	local sec = tonumber(MissionIntro.RXSendEvac and MissionIntro.RXSendEvac.evac_duration) or 0.1
	local msg = MissionIntro.L and MissionIntro.L("generic_evac_use_hint", sec)
		or ("[RX] 站在撤离区域内 " .. sec .. " 秒即可自动撤离。")
	activator:ChatPrint(msg)
end

function ENT:PhysgunPickup(ply)
	return false
end

function ENT:GravGunPunt(ply)
	return false
end

function ENT:OnRemove()
	self:CancelEvac()
	if SERVER and MissionIntro.RequestSaveRXSendEvacs then
		MissionIntro.RequestSaveRXSendEvacs()
	end
end
