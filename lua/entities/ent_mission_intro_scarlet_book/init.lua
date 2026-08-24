AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	local cfg = MissionIntro.ScarletRitual or {}
	local mdl = cfg.book_model or "models/props_lab/binderredlabel.mdl"

	self:SetModel(mdl)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:Sleep()
	end

	self:SetRitualDone(false)
	self:SetBookDestroyed(false)
	self:SetPrayProgress(0)
	self:SetSabotageProgress(0)
	self:SetPrayingPlayer(NULL)
	self:SetSabotagingPlayer(NULL)

	self._prayStart = 0
	self._sabotageStart = 0
	self:ApplyState()
end

function ENT:ApplyState()
	if self:GetBookDestroyed() then
		self:SetNoDraw(true)
		self:SetNotSolid(true)
		self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
		return
	end

	self:SetNoDraw(false)
	self:SetNotSolid(false)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:DrawShadow(true)
end

function ENT:PhysgunPickup(ply)
	return false
end

function ENT:GravGunPunt(ply)
	return false
end

function ENT:IsPlayerUsingMe(ply)
	if not IsValid(ply) or not ply:KeyDown(IN_USE) then return false end
	local tr = ply:GetEyeTrace()
	return tr.Entity == self
end

function ENT:CanInteract(ply)
	if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end
	if self:GetBookDestroyed() or self:GetRitualDone() then return false end
	return true
end

function ENT:CancelPrayer()
	self._prayStart = 0
	self:SetPrayProgress(0)
	self:SetPrayingPlayer(NULL)
	if MissionIntro.UpdateScarletPrayerActiveFlag then
		MissionIntro.UpdateScarletPrayerActiveFlag()
	end
end

function ENT:CancelSabotage()
	self._sabotageStart = 0
	self:SetSabotageProgress(0)
	self:SetSabotagingPlayer(NULL)
end

function ENT:StartPrayer(ply)
	if not self:CanInteract(ply) then return false end
	if MissionIntro.ScarletRitualPhase and MissionIntro.ScarletRitualPhase >= 1 then return false end

	if MissionIntro.RXSendCanStartScarletPrayer then
		local ok, denyKey = MissionIntro.RXSendCanStartScarletPrayer(ply)
		if not ok then
			local text = denyKey
			if MissionIntro.L then
				text = MissionIntro.L(denyKey) or denyKey
			end
			ply:ChatPrint("[MissionIntro] " .. text)
			return false
		end
	end

	local praying = self:GetPrayingPlayer()
	if IsValid(praying) and praying ~= ply then return false end

	local sabotaging = self:GetSabotagingPlayer()
	if IsValid(sabotaging) then return false end

	self:CancelSabotage()
	self._prayStart = CurTime()
	self:SetPrayingPlayer(ply)
	self:SetPrayProgress(0)

	if MissionIntro.RevealAllScarletBooks then
		MissionIntro.RevealAllScarletBooks()
	end

	if MissionIntro.UpdateScarletPrayerActiveFlag then
		MissionIntro.UpdateScarletPrayerActiveFlag()
	end

	return true
end

function ENT:StartSabotage(ply)
	if not self:CanInteract(ply) then return false end
	if not MissionIntro.CanSabotageScarletBook or not MissionIntro.CanSabotageScarletBook(ply) then return false end

	local sabotaging = self:GetSabotagingPlayer()
	if IsValid(sabotaging) and sabotaging ~= ply then return false end

	local praying = self:GetPrayingPlayer()
	if IsValid(praying) then return false end

	self:CancelPrayer()
	self._sabotageStart = CurTime()
	self:SetSabotagingPlayer(ply)
	self:SetSabotageProgress(0)
	return true
end

function ENT:DestroyBook(sabotager)
	self:SetBookDestroyed(true)
	self:CancelPrayer()
	self:CancelSabotage()
	self:ApplyState()
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end

	if self:GetBookDestroyed() then return end

	if self:GetRitualDone() then
		activator:ChatPrint("[MissionIntro] " .. (MissionIntro.L and MissionIntro.L("ritual_book_done") or "仪式已结束"))
		return
	end

	if MissionIntro.ScarletRitualPhase and MissionIntro.ScarletRitualPhase == 1 then
		if MissionIntro.CanSabotageScarletBook and MissionIntro.CanSabotageScarletBook(activator) then
			self:StartSabotage(activator)
		else
			activator:ChatPrint("[MissionIntro] " .. (MissionIntro.L and MissionIntro.L("ritual_book_sabotage_only") or "召唤阶段仅非猩红入场玩家可破坏书本"))
		end
		return
	end

	if MissionIntro.ScarletRitualPhase and MissionIntro.ScarletRitualPhase >= 1 then
		return
	end

	if MissionIntro.CanPrayAtScarletBook and MissionIntro.CanPrayAtScarletBook(activator) then
		self:StartPrayer(activator)
	else
		if MissionIntro.RXSendCanStartScarletPrayer then
			local ok, denyKey = MissionIntro.RXSendCanStartScarletPrayer(activator)
			if not ok and isstring(denyKey) and denyKey ~= "" then
				local text = MissionIntro.L and MissionIntro.L(denyKey) or denyKey
				activator:ChatPrint("[MissionIntro] " .. text)
				return
			end
		end
		activator:ChatPrint("[MissionIntro] " .. (MissionIntro.L and MissionIntro.L("ritual_book_scarlet_only") or "只有本批猩红重生入场的玩家可以祷告"))
	end
end

function ENT:Think()
	self:NextThink(CurTime())

	if self:GetBookDestroyed() then
		self:CancelPrayer()
		self:CancelSabotage()
		return true
	end

	if self:GetRitualDone() then
		self:CancelPrayer()
		self:CancelSabotage()
		return true
	end

	local cfg = MissionIntro.ScarletRitual or {}
	local maxDist = tonumber(cfg.use_distance) or 110
	local phase = MissionIntro.ScarletRitualPhase or 0

	-- 召唤阶段：非猩红破坏
	if phase == 1 then
		local sab = self:GetSabotagingPlayer()
		if IsValid(sab) and sab:IsPlayer() and sab:Alive() then
			if self._sabotageStart > 0 then
				if sab:GetPos():Distance(self:GetPos()) > maxDist or not sab:KeyDown(IN_USE) then
					self:CancelSabotage()
				elseif not MissionIntro.CanSabotageScarletBook(sab) then
					self:CancelSabotage()
				else
					local sabotageDur = tonumber(cfg.sabotage_duration) or 5
					local frac = math.Clamp((CurTime() - self._sabotageStart) / sabotageDur, 0, 1)
					self:SetSabotageProgress(frac)
					if frac >= 1 then
						self:CancelSabotage()
						if MissionIntro.SabotageScarletRitual then
							MissionIntro.SabotageScarletRitual(sab, self)
						end
					end
				end
			end
		end

		if self._sabotageStart <= 0 then
			for _, candidate in ipairs(player.GetAll()) do
				if not IsValid(candidate) or not candidate:Alive() then continue end
				if not self:IsPlayerUsingMe(candidate) then continue end
				if candidate:GetPos():Distance(self:GetPos()) > maxDist then continue end
				if MissionIntro.CanSabotageScarletBook and MissionIntro.CanSabotageScarletBook(candidate) then
					self:StartSabotage(candidate)
					break
				end
			end
		end

		self:CancelPrayer()
		return true
	end

	-- 平常：猩红祷告
	local ply = self:GetPrayingPlayer()
	if IsValid(ply) and ply:IsPlayer() and ply:Alive() and self._prayStart > 0 then
		if ply:GetPos():Distance(self:GetPos()) > maxDist or not ply:KeyDown(IN_USE) then
			self:CancelPrayer()
		elseif not MissionIntro.CanPrayAtScarletBook or not MissionIntro.CanPrayAtScarletBook(ply) then
			self:CancelPrayer()
		else
			local duration = tonumber(cfg.pray_duration) or 10
			local frac = math.Clamp((CurTime() - self._prayStart) / duration, 0, 1)
			self:SetPrayProgress(frac)
			if frac >= 1 then
				self:CancelPrayer()
				if MissionIntro.CompleteScarletRitual then
					MissionIntro.CompleteScarletRitual(ply, self)
				end
			end
		end
		return true
	end

	if self._prayStart <= 0 then
		for _, candidate in ipairs(player.GetAll()) do
			if not IsValid(candidate) or not candidate:Alive() then continue end
			if not self:IsPlayerUsingMe(candidate) then continue end
			if candidate:GetPos():Distance(self:GetPos()) > maxDist then continue end
			if MissionIntro.CanPrayAtScarletBook and MissionIntro.CanPrayAtScarletBook(candidate) then
				self:StartPrayer(candidate)
				break
			end
		end
	end

	return true
end

function ENT:OnRemove()
	self:CancelPrayer()
	self:CancelSabotage()
end
