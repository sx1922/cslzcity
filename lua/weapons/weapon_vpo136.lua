SWEP.Base = "weapon_akm"
SWEP.Primary.Automatic = false

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.PrintName = "VPO-136"
SWEP.Author = "维亚茨基耶波利亚纳机械制造厂"
SWEP.Instructions = "为俄罗斯民用枪械市场改装的AKM版本，无自动射击功能。使用7.62x39毫米弹药。"
SWEP.Category = "武器 - 卡宾枪"

SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.FakeBodyGroups = "0A0000C0010002"

SWEP.WepSelectIcon2 = Material("pwb/sprites/akm.png")
SWEP.IconOverride = "entities/arc9_eft_vpo136.png"

SWEP.Primary.Sound = {"weapons/ak74/ak74_tp.wav", 85, 90, 100}
SWEP.Primary.SoundFP = {"weapons/ak74/ak74_fp.wav", 85, 90, 100}

--local mat = "models/weapons/tfa_ins2/ak_pack/ak74n/ak74n_stock"
--function SWEP:ModelCreated(model)
--	local wep = self:GetWeaponEntity()
--	--self:SetSubMaterial(1, mat)
--	--wep:SetSubMaterial(1, mat)
--end
