SWEP.PrintName = "MC&D 呼叫对讲机"
SWEP.Author = "RX Mission Intro"
SWEP.Instructions = "左键：呼叫 MC&D 增援（需先在世界对讲机处按 E 拾取）"
SWEP.Category = "RX MC&D"

SWEP.Spawnable = false
SWEP.AdminOnly = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 1
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 1
SWEP.SlotPos = 3
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = "models/props_lab/reciever01d.mdl"
SWEP.HoldType = "slam"

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

function SWEP:PrimaryAttack()
	if CLIENT then return end
	self:SetNextPrimaryFire(CurTime() + 2)
	if MissionIntro.TryUseMcdRadio then
		MissionIntro.TryUseMcdRadio(self:GetOwner(), nil)
	end
end

function SWEP:SecondaryAttack()
end

function SWEP:Deploy()
	if CLIENT then return true end
	self:SetNextPrimaryFire(CurTime() + 0.5)
	return true
end
