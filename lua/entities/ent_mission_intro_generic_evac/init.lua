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

	local evacCfg = MissionIntro.GenericEvac or {}
	self:SetEvacZoneRadius(tonumber(evacCfg.default_zone_radius) or 130)

	self:NextThink(CurTime() + 0.1)
end

function ENT:GetZoneRadius()
	local evacCfg = MissionIntro.GenericEvac or {}
	local minR = tonumber(evacCfg.min_zone_radius) or 64
	local maxR = tonumber(evacCfg.max_zone_radius) or 400
	return math.Clamp(tonumber(self:GetEvacZoneRadius()) or 130, minR, maxR)
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
	if not MissionIntro.CanGenericPlayerEvacuate or not MissionIntro.CanGenericPlayerEvacuate(ply) then
		return false
	end

	self._evacStart = CurTime()
	self:SetEvacuatingPlayer(ply)
	self:SetEvacProgress(0)
	return true
end

function ENT:CompleteEvac(ply)
	self:CancelEvac()
	if MissionIntro.ExecuteGenericEvacuation then
		MissionIntro.ExecuteGenericEvacuation(ply, self)
	end
end

function ENT:Think()
	self:NextThink(CurTime() + 0.1)

	local cfg = MissionIntro.GenericEvac or {}
	local dur = tonumber(cfg.evac_duration) or 2

	local ply = self:GetEvacuatingPlayer()
	if self._evacStart > 0 then
		if not IsValid(ply) or not ply:IsPlayer()
			or not MissionIntro.CanGenericPlayerEvacuate or not MissionIntro.CanGenericPlayerEvacuate(ply)
			or not self:IsPlayerInZone(ply) then
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

	for _, candidate in ipairs(player.GetAll()) do
		if not IsValid(candidate) then continue end
		if not self:IsPlayerInZone(candidate) then continue end
		if self:StartEvac(candidate) then
			break
		end
	end

	return true
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end

	local sec = math.floor(tonumber(MissionIntro.GenericEvac.evac_duration) or 2)
	if MissionIntro.CanGenericPlayerEvacuate and MissionIntro.CanGenericPlayerEvacuate(activator) then
		if self:IsPlayerInZone(activator) then
			self:StartEvac(activator)
		end
		local msg = MissionIntro.L and MissionIntro.L("generic_evac_use_hint", sec) or ("[RX] 站在撤离区域内 " .. sec .. " 秒即可自动撤离。")
		activator:ChatPrint(msg)
		return
	end

	if activator._missionIntroEvacuated then
		activator:ChatPrint(MissionIntro.L and MissionIntro.L("generic_evac_already") or "[RX] 你已撤离。")
		return
	end

	local reason = MissionIntro.GetGenericEvacDenyReason and MissionIntro.GetGenericEvacDenyReason(activator)
	if reason == "dead" then
		activator:ChatPrint("[RX] 当前状态无法撤离（需可行动）。")
	elseif reason == "spectator" then
		activator:ChatPrint("[RX] 观察者无法撤离。")
	else
		activator:ChatPrint("[RX] 当前无法使用通用撤离点。")
	end
end

function ENT:PhysgunPickup(ply)
	return false
end

function ENT:GravGunPunt(ply)
	return false
end

function ENT:OnRemove()
	self:CancelEvac()
	if SERVER and MissionIntro.RequestSaveGenericEvacs then
		MissionIntro.RequestSaveGenericEvacs()
	end
end
