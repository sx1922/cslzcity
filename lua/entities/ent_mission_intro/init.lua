AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")

include("shared.lua")



util.AddNetworkString("MissionIntro_Start")

util.AddNetworkString("MissionIntro_Finished")

util.AddNetworkString("MissionIntro_Unlock")

util.AddNetworkString("MissionIntro_ForceStop")

util.AddNetworkString("MissionIntro_Abort")



function ENT:Initialize()

	self:SetModel("models/props_lab/monitor01a.mdl")

	self:PhysicsInit(SOLID_VPHYSICS)

	self:SetMoveType(MOVETYPE_VPHYSICS)

	self:SetSolid(SOLID_VPHYSICS)

	self:SetUseType(SIMPLE_USE)



	local phys = self:GetPhysicsObject()

	if IsValid(phys) then

		phys:Wake()

	end



	self:SetBusy(false)

	self._lastUse = {}

	self._rewardGiven = false

end



function ENT:ClearIntroTimers()

	timer.Remove("MissionIntro_Unlock_" .. self:EntIndex())

	timer.Remove("MissionIntro_End_" .. self:EntIndex())

	timer.Remove("MissionIntro_Reward_" .. self:EntIndex())

end



function ENT:GiveIntroReward(ply)
	if self._rewardGiven then return false end
	if MissionIntro and MissionIntro.HasGivenIntroReward and MissionIntro.HasGivenIntroReward(ply) then
		self._rewardGiven = true
		return false
	end

	if not IsValid(ply) or not ply:IsPlayer() then return false end

	if not MissionIntro or not MissionIntro.GiveRewards then
		MsgN("[MissionIntro] GiveRewards 未加载(缺少 sv_mission_intro_rewards.lua)")
		return false
	end

	local ok = MissionIntro.GiveRewards(ply) == true
	self._rewardGiven = ok
	return ok
end



function ENT:Use(activator)

	if not IsValid(activator) or not activator:IsPlayer() then return end

	if self:GetBusy() then return end



	local sid = activator:SteamID()

	local cd = MissionIntro and MissionIntro.Cooldown or 30

	if self._lastUse[sid] and CurTime() < self._lastUse[sid] then return end



	self._lastUse[sid] = CurTime() + cd
	self:SetBusy(true)
	self._playingPly = activator
	self._rewardGiven = false
	if MissionIntro.ClearIntroRewardLock then
		MissionIntro.ClearIntroRewardLock(activator)
	end
	self:ClearIntroTimers()

	if MissionIntro and MissionIntro.StartIntro and MissionIntro.StartIntro(activator, self) then
		return
	end

	MsgN("[MissionIntro] StartIntro 不可用，终端入场已跳过")
	self:SetBusy(false)
	self._playingPly = nil
end



function ENT:FinishIntro(giveReward)

	self:ClearIntroTimers()

	local ply = self._playingPly



	if IsValid(ply) then

		ply:Freeze(false)

		if giveReward == true and not (MissionIntro and MissionIntro.HasGivenIntroReward and MissionIntro.HasGivenIntroReward(ply)) then
			self:GiveIntroReward(ply)
		end

		net.Start("MissionIntro_ForceStop")

		net.Send(ply)

	end



	self._playingPly = nil

	self:SetBusy(false)

end



function ENT:OnRemove()

	self:ClearIntroTimers()

	self:FinishIntro(false)

end



net.Receive("MissionIntro_Unlock", function(_, ply)

	local ent = net.ReadEntity()

	if not IsValid(ent) or ent:GetClass() ~= "ent_mission_intro" then return end

	if ent._playingPly ~= ply then return end

	ply:Freeze(false)

end)



net.Receive("MissionIntro_Abort", function(_, ply)

	ply:Freeze(false)

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro")) do

		if ent._playingPly == ply then

			ent:FinishIntro(false)

		end

	end

	net.Start("MissionIntro_ForceStop")

	net.Send(ply)

end)



hook.Add("PlayerDisconnected", "MissionIntro_Unfreeze", function(ply)

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro")) do

		if ent._playingPly == ply then

			ent:FinishIntro(false)

		end

	end

end)


