-- 基于 M4A1，SCP-912 特供：50 伤、极低后坐力、预装四件套、备弹每 60 秒补给 1 匣
SWEP.Base = "weapon_m4a1"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "M4A1(SCP 912 特供版)"
SWEP.Author = "RX Mission Intro"

SWEP.Category = "Weapons - SCP"
SWEP.ScrappersSlot = "Primary"
SWEP.weaponInvCategory = 1
SWEP.NoLoot = true
SWEP.NoDrop = true
SWEP.bigNoDrop = true

-- 原版 AR15 Ergonomics=0.8，开镜/举枪过渡 +90%
SWEP.Ergonomics = 0.8 * 1.9

SWEP.Primary.Damage = 50
-- Homigrad 以弹药显示名索引 hg.ammotypeshuy；ent_ammo_5.56x45mmap 对应此类型
SWEP.Primary.Ammo = "5.56x45 mm AP"
SWEP.CustomShell = "556x45"

SWEP.Primary.Wait = 0.082

SWEP.StartAtt = {"holo14", "supressor2", "grip3", "laser5"}

-- 垂直后坐力 -75%
local VERT_RECOIL_MUL = 0.25
-- 水平后坐力 -80%
local HORIZ_RECOIL_MUL = 0.20
-- 开火抖动 -70%
local FIRE_SHAKE_MUL = 0.30

SWEP.punchmul = 2 * VERT_RECOIL_MUL
SWEP.ShootAnimMul = 3 * VERT_RECOIL_MUL * FIRE_SHAKE_MUL
SWEP.AnimShootMul = FIRE_SHAKE_MUL
SWEP.AnimShootHandMul = FIRE_SHAKE_MUL
SWEP.animposmul = FIRE_SHAKE_MUL
SWEP.addSprayMul = VERT_RECOIL_MUL
SWEP.RecoilMul = 0.8 * VERT_RECOIL_MUL
SWEP.cameraShakeMul = VERT_RECOIL_MUL * FIRE_SHAKE_MUL
SWEP.SprayRand = {
	Angle(-0.03 * VERT_RECOIL_MUL, -0.03 * HORIZ_RECOIL_MUL, 0),
	Angle(-0.05 * VERT_RECOIL_MUL, 0.03 * HORIZ_RECOIL_MUL, 0),
}

local RESERVE_REFILL_INTERVAL = 60
local FORCED_ATTS = {
	sight = "holo14",
	barrel = "supressor2",
	grip = "grip3",
	underbarrel = "laser5",
}

function SWEP:GetSpareMagAmmo()
	return self:GetMaxClip1()
end

function SWEP:EnsureForcedAttachments()
	if not self.attachments or self._miForcedAttachmentsDone then return end

	local changed = false
	for slot, attName in pairs(FORCED_ATTS) do
		local cur = self.attachments[slot]
		if not istable(cur) or cur[1] ~= attName then
			if hg and hg.SetAttachment then
				hg.SetAttachment(self.attachments, attName, self:GetClass())
			else
				self.attachments[slot] = {attName, {}}
			end
			changed = true
		end
	end

	if changed then
		if SERVER and self.SetNetVar then
			self:SetNetVar("attachments", self.attachments)
		end
	else
		self._miForcedAttachmentsDone = true
	end
end

function SWEP:SyncReserveRefillNW()
	if not SERVER then return end
	self:SetNWFloat("MI_NextReserveRefill", self._miNextReserveRefill or 0)
end

function SWEP:InitializePost()
	self.BaseClass.InitializePost(self)

	if SERVER then
		timer.Simple(0, function()
			if not IsValid(self) then return end
			self:EnsureForcedAttachments()
		end)
		self._miNextReserveRefill = CurTime() + RESERVE_REFILL_INTERVAL
		self:SyncReserveRefillNW()
		self:MaintainTimedSpareMag(true)
	else
		self:EnsureForcedAttachments()
	end
end

-- 备弹上限 1 匣，每 60 秒补满 1 匣（不堆无限备弹）
function SWEP:MaintainTimedSpareMag(grantNow)
	if not SERVER then return end

	local ply = self:GetOwner()
	if not IsValid(ply) or not ply:IsPlayer() then return end

	local ammoType = self:GetPrimaryAmmoType()
	if ammoType < 0 then return end

	local spareCap = self:GetSpareMagAmmo()
	local reserve = ply:GetAmmoCount(ammoType)

	if reserve > spareCap then
		ply:SetAmmo(spareCap, ammoType)
		reserve = spareCap
	end

	if grantNow and reserve < spareCap then
		ply:SetAmmo(spareCap, ammoType)
		return
	end

	self._miNextReserveRefill = self._miNextReserveRefill or (CurTime() + RESERVE_REFILL_INTERVAL)

	if CurTime() >= self._miNextReserveRefill then
		self._miNextReserveRefill = CurTime() + RESERVE_REFILL_INTERVAL
		if ply:GetAmmoCount(ammoType) < spareCap then
			ply:SetAmmo(spareCap, ammoType)
		end
		self:SyncReserveRefillNW()
	end
end

function SWEP:PrimarySpread()
	local savedDamage = self.Primary.Damage
	self.Primary.Damage = 44
	self.BaseClass.PrimarySpread(self)
	self.Primary.Damage = savedDamage
end

function SWEP:Think()
	self.BaseClass.Think(self)
	if SERVER then
		local nextAt = self._miSpareMagTick or 0
		if CurTime() < nextAt then return end
		self._miSpareMagTick = CurTime() + 0.25
		self:MaintainTimedSpareMag()
	end
end

function SWEP:Deploy()
	local ret = self.BaseClass.Deploy(self)
	self:MaintainTimedSpareMag(true)
	return ret
end

if CLIENT then
	surface.CreateFont("MI_M4Scp912_HUD", {
		font = "Tahoma",
		size = 22,
		weight = 700,
		antialias = true,
		extended = true,
	})

	local colBg = Color(0, 0, 0, 140)
	local colText = Color(235, 235, 235, 255)
	local colReady = Color(140, 255, 160, 255)

	function SWEP:DrawHUDAdd()
		local scrW, scrH = ScrW(), ScrH()
		local cx = scrW * 0.5
		local y = scrH - 120
		local lineH = 24

		local lines = {}

		local nextRefill = self:GetNWFloat("MI_NextReserveRefill", 0)
		local spareCap = self:GetMaxClip1()
		local owner = self:GetOwner()
		local reserve = IsValid(owner) and owner:GetAmmoCount(self:GetPrimaryAmmoType()) or 0

		if nextRefill > 0 then
			local cd = math.max(0, nextRefill - CurTime())
			if cd <= 0.05 and reserve >= spareCap then
				lines[#lines + 1] = {
					text = string.format("备弹补给 就绪 (%d / %d)", reserve, spareCap),
					color = colReady,
				}
			else
				lines[#lines + 1] = {
					text = string.format("备弹补给 %.0f 秒 (%d / %d)", math.ceil(cd), reserve, spareCap),
					color = colText,
				}
			end
		end

		if #lines == 0 then return end

		local maxW = 0
		for _, line in ipairs(lines) do
			surface.SetFont("MI_M4Scp912_HUD")
			local tw = surface.GetTextSize(line.text)
			if tw > maxW then maxW = tw end
		end

		local padX, padY = 14, 8
		local boxH = #lines * lineH + padY * 2
		local boxW = maxW + padX * 2
		local boxX = cx - boxW * 0.5

		draw.RoundedBox(6, boxX, y - padY, boxW, boxH, colBg)

		for i, line in ipairs(lines) do
			draw.SimpleText(line.text, "MI_M4Scp912_HUD", cx, y + (i - 1) * lineH, line.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
	end
end
