SWEP.Base = "weapon_m1911"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.PrintName = "Colt M45A1" -- 柯尔特M45A1
SWEP.Author = "Colt's Manufacturing Company"
SWEP.Instructions = "发射.45 ACP弹药的手枪"

SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.Category = "武器 - 手枪"
SWEP.WepSelectIcon2 = Material("entities/arc9_eft_m45.png")
SWEP.WepSelectIcon2box = true
SWEP.IconOverride = "entities/arc9_eft_m45.png"

SWEP.cameraShakeMul = 1

SWEP.FakeBodyGroups = "02000000"

SWEP.FakeBodyGroupsPresets = {
	"02000000",
	"02000000",
	"02000000",
	"02000000",
}

SWEP.LocalMuzzlePos = Vector(-3.5,0,6.5)
SWEP.LocalMuzzleAng = Angle(0.3,0,0)

function SWEP:AddModelCreated(model)

    model:SetSkin(2)

end

SWEP.ZoomPos = Vector(25, -0.05, 7.34)