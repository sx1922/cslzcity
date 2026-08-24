AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	local mdl = MissionIntro.GetAaPanelModel and MissionIntro.GetAaPanelModel()
		or (MissionIntro.AaPanel and MissionIntro.AaPanel.model)
		or "models/props_combine/masterinterface.mdl"
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

	self:SetDangerLevel(MissionIntro.GetAaDangerLevel and MissionIntro.GetAaDangerLevel() or 0)
	self:SetAaActive(MissionIntro.IsAaSystemActive and MissionIntro.IsAaSystemActive() or true)
	self:SetCiSpawnEta(tonumber(MissionIntro._aaCiSpawnEta) or 0)
end

function ENT:GetUseDistance()
	return tonumber(MissionIntro.AaPanel and MissionIntro.AaPanel.use_distance) or 140
end

function ENT:CanUseDist(ply)
	if not IsValid(ply) then return false end
	return ply:GetPos():DistToSqr(self:GetPos()) <= self:GetUseDistance() ^ 2
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() then return end

	if not MissionIntro._aaClosingInProgress then
		if MissionIntro.TryAbortAaShutdownFromUse and MissionIntro.TryAbortAaShutdownFromUse(activator, self) then
			return
		end
	end

	if not activator:Alive() or not self:CanUseDist(activator) then return end

	net.Start("MissionIntro_AaPanelOpen")
		net.WriteEntity(self)
	net.Send(activator)
end

function ENT:Think()
	self:NextThink(CurTime() + 0.5)

	if SERVER and MissionIntro.SyncAaPanels then
		local level = MissionIntro.GetAaDangerLevel and MissionIntro.GetAaDangerLevel() or 0
		local active = MissionIntro.IsAaSystemActive and MissionIntro.IsAaSystemActive() or true
		if math.abs((self:GetDangerLevel() or 0) - level) > 0.01
			or self:GetAaActive() ~= active
		then
			MissionIntro.SyncAaPanels()
		end
	end

	return true
end
