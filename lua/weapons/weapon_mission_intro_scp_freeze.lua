-- 特异事故处 战斗专家：定身 SCP 10 秒，冷却 50 秒（九尾狐战斗专家已不再发放）

if SERVER then
	AddCSLuaFile()
end

SWEP.PrintName = "战斗专家 · SCP 定身"
SWEP.Author = "RX Mission Intro"
SWEP.Instructions = "左键瞄准 SCP 定身 10 秒（50 秒冷却）"
SWEP.Purpose = "短暂控制设施 SCP"

SWEP.Spawnable = false
SWEP.AdminOnly = false
SWEP.Category = "Mission Intro"

SWEP.ViewModel = ""
SWEP.WorldModel = ""
SWEP.UseHands = true
SWEP.HoldType = "normal"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.NoDrop = true
SWEP.Slot = 5
SWEP.SlotPos = 1

function SWEP:Initialize()
	self:SetHoldType("normal")
end

function SWEP:GetCooldown()
	return MissionIntro and MissionIntro.ScpFreezeCooldown or 50
end

function SWEP:GetFreezeTime()
	return MissionIntro and MissionIntro.ScpFreezeDuration or 10
end

function SWEP:GetRange()
	return MissionIntro and MissionIntro.ScpFreezeRange or 800
end

function SWEP:CanUseSkill(ply)
	if not IsValid(ply) then return false, "无效玩家" end

	if MissionIntro and MissionIntro.RXSendIsActive and not MissionIntro.RXSendIsActive() then
		return false, "该技能仅在 RXsend 设施行动中可用"
	end

	if MissionIntro and MissionIntro.IsCombatExpertPlayer and not MissionIntro.IsCombatExpertPlayer(ply) then
		return false, "仅战斗专家可使用此技能"
	end

	return true
end

function SWEP:ResolveTarget(ply)
	local tr = util.TraceLine({
		start = ply:GetShootPos(),
		endpos = ply:GetShootPos() + ply:GetAimVector() * self:GetRange(),
		filter = ply,
		mask = MASK_SHOT,
	})

	local ent = tr.Entity
	if IsValid(ent) and ent:IsPlayer() then
		return ent
	end

	-- 准星落在 SCP 武器/布娃娃上时，尽量解析到玩家
	if IsValid(ent) and hg and hg.RagdollOwner then
		local owner = hg.RagdollOwner(ent)
		if IsValid(owner) and owner:IsPlayer() then
			return owner
		end
	end

	return nil
end

function SWEP:PrimaryAttack()
	if not SERVER then return end

	local ply = self:GetOwner()
	if not IsValid(ply) then return end

	local ok, reason = self:CanUseSkill(ply)
	if not ok then
		ply:ChatPrint(reason)
		return
	end

	if self.NextUse and CurTime() < self.NextUse then
		local remaining = math.ceil(self.NextUse - CurTime())
		ply:ChatPrint("技能冷却中，剩余 " .. remaining .. " 秒")
		return
	end

	local target = self:ResolveTarget(ply)
	if not IsValid(target) then
		ply:ChatPrint("请瞄准一名 SCP")
		return
	end

	if not MissionIntro or not MissionIntro.IsScpFreezeTarget or not MissionIntro.IsScpFreezeTarget(target) then
		ply:ChatPrint("只能对设施 SCP 使用定身")
		return
	end

	if ply:GetPos():DistToSqr(target:GetPos()) > self:GetRange() * self:GetRange() then
		ply:ChatPrint("目标太远，请靠近一些（" .. self:GetRange() .. " 单位内）")
		return
	end

	self.NextUse = CurTime() + self:GetCooldown()
	self:SetNextPrimaryFire(self.NextUse)

	if MissionIntro and MissionIntro.PlayScpFreezeSound then
		MissionIntro.PlayScpFreezeSound(ply)
	end

	ply:ChatPrint(ply:Nick() .. "：发现目标！")

	if MissionIntro.ApplyScpFreeze then
		MissionIntro.ApplyScpFreeze(ply, target, self:GetFreezeTime())
	end

	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
end

function SWEP:SecondaryAttack() end
function SWEP:Reload() end

if CLIENT then
	function SWEP:DrawHUD()
		local ply = LocalPlayer()
		if not IsValid(ply) or ply ~= self:GetOwner() then return end

		local cd = 0
		if self.NextUse and CurTime() < self.NextUse then
			cd = math.ceil(self.NextUse - CurTime())
		end

		local text = cd > 0 and ("SCP 定身 冷却 " .. cd .. "s") or "SCP 定身 就绪（左键）"
		draw.SimpleTextOutlined(text, "DermaDefault", ScrW() * 0.5, ScrH() * 0.72, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
	end
end
