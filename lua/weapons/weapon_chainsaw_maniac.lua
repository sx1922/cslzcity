if SERVER then AddCSLuaFile() end

-- Dedicated mode weapon.  It inherits the project's tested two-handed melee
-- implementation so it is available even when the optional chainsaw asset is
-- not mounted; the mode supplies the chainsaw damage/range values at runtime.
SWEP.Base = "weapon_hg_axe"
SWEP.PrintName = "电锯杀人魔近战武器"
SWEP.Instructions = "左键攻击；右键格挡。电锯模式专用近战武器。"
SWEP.Category = "Z-City - 电锯模式"
SWEP.Spawnable = false
SWEP.AdminOnly = false

SWEP.DamagePrimary = 120
SWEP.DamageSecondary = 35
SWEP.AttackLen1 = 100
SWEP.AttackLen2 = 65
SWEP.AttackTime = 0.24
SWEP.WaitTime1 = 0.55
SWEP.AttackTime2 = 0.18
SWEP.WaitTime2 = 0.4

-- Reuse the mounted axe model as a safe visual fallback. Servers can override
-- these two paths in a derived weapon when a dedicated chainsaw model is added.
SWEP.WorldModel = "models/props/cs_militia/axe.mdl"
SWEP.WorldModelExchange = "models/props/cs_militia/axe.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_bat_metal.mdl"
