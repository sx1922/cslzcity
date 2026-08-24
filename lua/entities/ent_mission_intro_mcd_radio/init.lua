AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	local cfg = MissionIntro.Mcd or {}
	self:SetModel(cfg.radio_model or "models/props_lab/reciever01d.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
		phys:Sleep()
	end
end

function ENT:GetUseDistance()
	return tonumber(MissionIntro.Mcd.use_distance) or 120
end

function ENT:CanUseDist(ply)
	if not IsValid(ply) then return false end
	return ply:GetPos():DistToSqr(self:GetPos()) <= self:GetUseDistance() ^ 2
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() or not activator:Alive() then return end
	if not self:CanUseDist(activator) then return end

	if MissionIntro.IsMcdPlayer and MissionIntro.IsMcdPlayer(activator) then
		activator:ChatPrint(MissionIntro.L and MissionIntro.L("mcd_radio_mcd_no_need") or "[MC&D] 我觉得我不需要这个。")
		return
	end

	if activator:HasWeapon("weapon_mcd_radio") then
		activator:ChatPrint(MissionIntro.L and MissionIntro.L("mcd_radio_already_have") or "[MC&D] 你已经有一个了。")
		return
	end

	activator:Give("weapon_mcd_radio", false)

	local msg = MissionIntro.L and MissionIntro.L("mcd_radio_pickup_popup") or "你已拾取 MC&D 呼叫对讲机。装备后按左键呼叫增援。"
	net.Start("MissionIntro_McdRadioPickupMsg")
		net.WriteString(msg)
	net.Send(activator)
end
