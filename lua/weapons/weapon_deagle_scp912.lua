-- 基于 Desert Eagle，SCP-912 特供：300 伤、常备 1 个备用弹匣、低后坐力
SWEP.Base = "weapon_deagle"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "沙漠之鹰 (SCP 912特供版)"
SWEP.Author = "RX Mission Intro"

SWEP.Category = "Weapons - SCP"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ScrappersSlot = "Secondary"
SWEP.weaponInvCategory = 2

SWEP.NoLoot = true
SWEP.NoDrop = true
SWEP.bigNoDrop = true

-- 原版 0.9，开镜/举枪过渡 +90%
SWEP.Ergonomics = 0.9 * 1.9

SWEP.StartAtt = {"laser5"}

SWEP.availableAttachments = {
	sight = {
		["mountType"] = "picatinny",
		["mount"] = Vector(-3, 0.5, 0),
		["mountAngle"] = Angle(0, 0, 0),
	},
	underbarrel = {
		["mount"] = Vector(10.5, 0, -1.2),
		["mountAngle"] = Angle(0, 0, 90),
		["mountType"] = "picatinny_small",
	},
}

SWEP.Primary.Damage = 300
SWEP.Primary.DefaultClip = 7

-- 垂直后坐力 -85%（相对原版 Desert Eagle）
local VERT_RECOIL_MUL = 0.15
-- 水平后坐力 -75%
local HORIZ_RECOIL_MUL = 0.25

SWEP.punchmul = 5 * VERT_RECOIL_MUL
SWEP.podkid = 2 * HORIZ_RECOIL_MUL
SWEP.AnimShootMul = 4 * VERT_RECOIL_MUL
SWEP.AnimShootHandMul = 2 * VERT_RECOIL_MUL
SWEP.ShootAnimMul = 7 * VERT_RECOIL_MUL
SWEP.RecoilMul = 0.8 * VERT_RECOIL_MUL
SWEP.addSprayMul = VERT_RECOIL_MUL
SWEP.cameraShakeMul = VERT_RECOIL_MUL
SWEP.SprayRand = {
	Angle(-0.4 * VERT_RECOIL_MUL, -0.2 * HORIZ_RECOIL_MUL, 0),
	Angle(-0.5 * VERT_RECOIL_MUL, 0.2 * HORIZ_RECOIL_MUL, 0),
}

function SWEP:GetSpareMagAmmo()
	return self:GetMaxClip1()
end

function SWEP:InitializePost()
	self.BaseClass.InitializePost(self)
	self:EnsureLaserAttachment()
end

function SWEP:EnsureLaserAttachment()
	if not self.attachments then return end
	local ub = self.attachments.underbarrel
	if istable(ub) and ub[1] == "laser5" then return end
	if hg and hg.SetAttachment then
		hg.SetAttachment(self.attachments, "laser5", self:GetClass())
		if SERVER and self.SetNetVar then
			self:SetNetVar("attachments", self.attachments)
		end
	else
		self.attachments.underbarrel = {"laser5", {}}
	end
end

-- 备弹恒为 1 个满弹匣：可换弹射击，但不堆无限备弹（Z City 按备弹数计负重）
function SWEP:MaintainSingleSpareMag()
	if not SERVER then return end

	local ply = self:GetOwner()
	if not IsValid(ply) or not ply:IsPlayer() then return end

	local ammoType = self:GetPrimaryAmmoType()
	if ammoType < 0 then return end

	local spareCap = self:GetSpareMagAmmo()
	local reserve = ply:GetAmmoCount(ammoType)

	if reserve == spareCap then return end
	if reserve > spareCap then
		ply:SetAmmo(spareCap, ammoType)
	elseif reserve < spareCap then
		ply:SetAmmo(spareCap, ammoType)
	end
end

-- 高伤害不参与后坐力叠乘（否则 300 伤会把镜头抖爆）
function SWEP:PrimarySpread()
	local savedDamage = self.Primary.Damage
	self.Primary.Damage = 40
	self.BaseClass.PrimarySpread(self)
	self.Primary.Damage = savedDamage
end

function SWEP:Think()
	self.BaseClass.Think(self)
	if SERVER then
		local nextAt = self._miSpareMagTick or 0
		if CurTime() >= nextAt then
			self._miSpareMagTick = CurTime() + 0.5
			self:MaintainSingleSpareMag()
		end
	end
end

function SWEP:Deploy()
	local ret = self.BaseClass.Deploy(self)
	self:MaintainSingleSpareMag()
	self:EnsureLaserAttachment()
	return ret
end

if SERVER then
	function SWEP:PostFireBullet(bullet)
		if self.BaseClass.PostFireBullet then
			self.BaseClass.PostFireBullet(self, bullet)
		end
	end
end
