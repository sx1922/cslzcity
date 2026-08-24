SWEP.Base = "weapon_glock17"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "格洛克26"
SWEP.Author = "Glock GmbH"
SWEP.Instructions = "格洛克是由奥地利制造商Glock Ges.m.b.H设计和生产的聚合物框架、短后坐式、击针发射、闭锁半自动手枪。该型号为紧凑型，使用9x19毫米弹药，弹匣容量10发。"
SWEP.Category = "武器 - 手枪"
SWEP.Slot = 2
SWEP.SlotPos = 10

SWEP.FakeBodyGroups = "2108"
SWEP.FakeBodyGroupsPresets = {
	"2108",
	"2108",
	"2108",
	"2108",
	"2108",
	"2108",
	"2108",
	"2108",
	"2108",
}

SWEP.AnimList = {
	["idle"] = "idle",
	["reload"] = "reload_10",
	["reload_empty"] = "reload_empty_10",
}

function SWEP:InitializePost()
	local Skin = math.random(0,2)
	if math.random(0,100) > 99 then
		Skin = 3
	end
	self:SetGlockSkin(Skin)
	self:SetRandomBodygroups(self.FakeBodyGroupsPresets[math.random(#self.FakeBodyGroupsPresets)] or "2108")
end

SWEP.ReloadTime = 2.8

SWEP.AttachmentPos = Vector(-0.1,-1.2,-6.5)
SWEP.AttachmentAng = Angle(0,0,0)

SWEP.WepSelectIcon2 = Material("vgui/hud/tfa_ins2_glock_p80.png")
SWEP.IconOverride = "entities/weapon_pwb_glock17.png"

SWEP.Primary.ClipSize = 10
SWEP.Primary.DefaultClip = 10

SWEP.weight = 1
SWEP.lengthSub = 20

SWEP.Ergonomics = 2

function SWEP:PostSetupDataTables()
	self:NetworkVar("Int",0,"GlockSkin")
	if ( CLIENT ) then
		self:NetworkVarNotify( "GlockSkin", self.OnVarChanged )
	end
end

function SWEP:OnVarChanged( name, old, new )
	if !IsValid(self:GetWM()) then return end

	self:GetWM():SetSkin(new)
end

function SWEP:InitializePost()
	local Skin = math.random(0,2)
	if math.random(0,100) > 99 then
		Skin = 3
	end
	self:SetGlockSkin(Skin)
end

function SWEP:ModelCreated(model)
	model:ManipulateBoneScale(46, vector_origin)
	model:SetSkin(self:GetGlockSkin())
end
