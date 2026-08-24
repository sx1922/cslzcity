-- 九尾狐特供 M98B：半自动连狙、10发弹匣、无拉栓、自带消音、无瞄准镜
SWEP.Base = "weapon_m98b"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "Barrett M98B（九尾狐特供）"
SWEP.Author = "RX Mission Intro"
SWEP.Instructions = "九尾狐半自动狙击步枪，.338 Lapua Magnum，自带消音器"
SWEP.Category = "Weapons - Sniper Rifles"

SWEP.NoDrop = true
SWEP.bigNoDrop = true
SWEP.NoLoot = true

SWEP.OpenBolt = true
SWEP.AutomaticDraw = false
SWEP.Chocking = false
SWEP.CockSound = nil
SWEP.DontOnReloadSnd = true

SWEP.Primary.Automatic = true
SWEP.Primary.ClipSize = 10
SWEP.Primary.DefaultClip = 10
-- 原 0.32 秒/发，累计射速 -40% 后再 -30%（0.32 × 1.4 × 1.3）
SWEP.Primary.Wait = 0.5824
SWEP.Primary.Damage = 500

-- 原版 Ergonomics 0.75，开镜过渡速度 +60%
SWEP.Ergonomics = 1.2

SWEP.StartAtt = {"supressor7"}

SWEP.availableAttachments = {
	sight = {
		["empty"] = {
			"empty",
			{
				[1] = "null",
				[2] = "null",
			},
		},
		["mountType"] = "picatinny",
		["mount"] = Vector(-37, 2.2, -0.09),
		["removehuy"] = {
			[1] = "null",
			[2] = "null",
		},
	},
	barrel = {
		[1] = {"supressor7", Vector(-5, 0, 0), {}},
		["mountAngle"] = Angle(0, 0, 0),
	},
}

-- 在原有 -85% 基础上再 -30% 总体后坐力（0.15 × 0.7）
local RECOIL_MUL = 0.105
-- 开火抖动 -70%（相对当前 AnimShoot 倍率）
local FIRE_SHAKE_MUL = 0.3

SWEP.SprayRand = {
	Angle(-0.6 * RECOIL_MUL, -0.1 * RECOIL_MUL, 0),
	Angle(-0.7 * RECOIL_MUL, 0.1 * RECOIL_MUL, 0),
}
SWEP.punchmul = 2 * RECOIL_MUL
SWEP.punchspeed = 0.5 * RECOIL_MUL
SWEP.addSprayMul = 1 * RECOIL_MUL
SWEP.ShootAnimMul = 2 * RECOIL_MUL * FIRE_SHAKE_MUL
SWEP.AnimShootMul = 1 * RECOIL_MUL * FIRE_SHAKE_MUL
SWEP.AnimShootHandMul = 3 * RECOIL_MUL * FIRE_SHAKE_MUL
SWEP.cameraShakeMul = RECOIL_MUL * FIRE_SHAKE_MUL

function SWEP:InitializePost()
	if self.BaseClass.InitializePost then
		self.BaseClass.InitializePost(self)
	end
	self.drawBullet = true
	self.OpenBolt = true
end

function SWEP:Initialize_Reload()
	self.LastReload = 0
	self.drawBullet = true
	self.OpenBolt = true
end

function SWEP:PrimaryShoot()
	self.BaseClass.PrimaryShoot(self)
	self.drawBullet = true
end

function SWEP:Draw(server, override)
	if self:Clip1() > 0 then
		self.drawBullet = true
	end
end

function SWEP:ReloadEnd()
	self:InsertAmmo(self:GetMaxClip1() - self:Clip1())
	self.ReloadNext = CurTime() + (self.ReloadCooldown or 0.1)
	self.drawBullet = true
end

function SWEP:AnimationPostPost()
end
