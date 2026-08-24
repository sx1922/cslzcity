-- 基于 SOG 刀，SCP-912 特供：右键冲刺拔刀（20s +50% 移速，120s CD），一刀必杀
SWEP.Base = "weapon_sogknife"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "SCP 912 利刃"
SWEP.Author = "RX Mission Intro"

SWEP.Category = "Weapons - SCP"
SWEP.NoLoot = true
SWEP.NoDrop = true
SWEP.bigNoDrop = true

SWEP.StaminaPrimary = 0
SWEP.StaminaSecondary = 0

local DASH_COOLDOWN = 120
local DASH_DURATION = 20
local DASH_MOVE_MUL = 1.5

function SWEP:IsDashActive()
	local owner = self:GetOwner()
	if IsValid(owner) and owner:IsPlayer() then
		return CurTime() < owner:GetNWFloat("MI_KnifeDashBuffEnd", 0)
	end
	return false
end

function SWEP:IsDashReady()
	return CurTime() >= (self._miNextDash or 0) and not self:IsDashActive()
end

function SWEP:IsKnifeDrawn()
	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then return false end
	return self:IsDashActive()
end

function SWEP:InUse()
	if not self:IsKnifeDrawn() then return false end
	return self.BaseClass.InUse(self)
end

function SWEP:UpdateKnifeCarryState()
	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	if self:IsKnifeDrawn() then
		self.setrh = true
		if not owner.suiciding then
			self:SetHold(self.HoldType)
		end
	else
		self.setrh = false
		self.lhandik = false
		self.rhandik = false
		if not owner.suiciding then
			self:SetHold("normal")
		end
		if SERVER then
			self:RemoveFake()
		end
	end
end

function SWEP:SyncDashCooldownNW()
	if not SERVER then return end
	self:SetNWFloat("MI_NextDash", self._miNextDash or 0)
end

function SWEP:SheathKnife()
	if SERVER then
		self:RemoveFake()
	end
	self:SetInAttack(false)
	self:UpdateKnifeCarryState()
end

function SWEP:DrawKnife()
	if SERVER then
		local owner = self:GetOwner()
		if IsValid(owner) and not owner.noSound then
			owner:EmitSound(self.DeploySnd, 65)
		end
	end
	self:UpdateKnifeCarryState()
	self:PlayAnim("deploy", 1, false, nil, false)
end

function SWEP:CanBlock()
	return false
end

function SWEP:CanSecondaryAttack()
	return self.allowsec and true or false
end

function SWEP:CanPrimaryAttack()
	if self:GetOwner():KeyDown(IN_RELOAD) then return end
	if not self:IsKnifeDrawn() then return false end
	if not self:GetNetVar("mode") then
		return true
	end

	self.allowsec = true
	self:SecondaryAttack(true)
	self.allowsec = nil
	return false
end

function SWEP:TryDash()
	if not SERVER then return end

	local owner = self:GetOwner()
	if not IsValid(owner) or not owner:IsPlayer() then return end
	if owner:GetActiveWeapon() ~= self then return end
	if owner:KeyDown(IN_USE) and not IsValid(owner.FakeRagdoll) then return end
	if (self:GetLastAttack() + self:GetAttackWait()) > CurTime() then return end
	if not self:IsDashReady() then return end

	local now = CurTime()
	self._miNextDash = now + DASH_COOLDOWN
	owner:SetNWFloat("MI_KnifeDashBuffEnd", now + DASH_DURATION)
	self:SyncDashCooldownNW()

	owner._miKnifePreWalk = nil
	owner._miKnifePreRun = nil
	owner._miKnifePreSlow = nil
	owner._miKnifePreCrouch = nil
	owner._miKnifeDashSpeedActive = nil

	if MI_SogKnifeApplyDashSpeed then
		MI_SogKnifeApplyDashSpeed(owner)
	end

	self:DrawKnife()
	self:SetNextSecondaryFire(now + 0.35)
end

function SWEP:InitAdd()
	if SERVER then
		self._miNextDash = 0
		self:SyncDashCooldownNW()
	end
end

function SWEP:Deploy()
	self.Initialzed = true
	self:UpdateKnifeCarryState()
	if self:IsKnifeDrawn() then
		self:PlayAnim("idle", 10, true)
	end
	return true
end

function SWEP:Holster()
	self:SetInAttack(false)
	return true
end

function SWEP:ThinkAdd()
	if SERVER and IsValid(self:GetOwner()) and self:GetOwner():KeyPressed(IN_ATTACK2) then
		self:TryDash()
	end
end

function SWEP:Think()
	local owner = self:GetOwner()
	if IsValid(owner) then
		local buffActive = self:IsDashActive()
		if self._miKnifeHadBuff and not buffActive then
			self:SheathKnife()
		end
		self._miKnifeHadBuff = buffActive
	end

	self.BaseClass.Think(self)
	self:UpdateKnifeCarryState()
end

if SERVER then
	local function Scp912ResolveVictim(ent)
		if not IsValid(ent) then return nil end
		if ent:IsPlayer() then return ent end
		if ent:IsRagdoll() and hg and hg.RagdollOwner then
			local owner = hg.RagdollOwner(ent)
			if IsValid(owner) and owner:IsPlayer() then return owner end
		end
		return ent.organism and ent or nil
	end

	local function Scp912VictimIsScp(ply)
		if not IsValid(ply) or not ply:IsPlayer() then return false end
		if MissionIntro.PlayerIsFacilityScpForWeapons then
			return MissionIntro.PlayerIsFacilityScpForWeapons(ply) == true
		end
		if MissionIntro.ShouldFacilityScpImmuneZcityDebuffs then
			return MissionIntro.ShouldFacilityScpImmuneZcityDebuffs(ply) == true
		end
		return false
	end

	local function Scp912TryInstantKill(self, ent)
		if not self:IsKnifeDrawn() then return end
		local victim = Scp912ResolveVictim(ent)
		if not IsValid(victim) or not victim:IsPlayer() then return end
		if not victim:Alive() or Scp912VictimIsScp(victim) then return end

		if MI_Scp912ExecuteKill then
			MI_Scp912ExecuteKill(victim, self:GetOwner(), self)
			return
		end

		local dmg = DamageInfo()
		dmg:SetDamage(99999)
		dmg:SetAttacker(IsValid(self:GetOwner()) and self:GetOwner() or victim)
		dmg:SetInflictor(self)
		dmg:SetDamageType(DMG_SLASH)
		victim:TakeDamageInfo(dmg)
		if victim:Alive() then
			victim:Kill()
		end
	end

	function SWEP:PrimaryAttackAdd(ent, trace)
		if not IsValid(ent) then return end
		if not self:IsEntSoft(ent) then return end
		Scp912TryInstantKill(self, ent)
	end

	function SWEP:SecondaryAttackAdd(ent, trace)
		if not IsValid(ent) then return end
		if not self:IsEntSoft(ent) then return end
		Scp912TryInstantKill(self, ent)
	end

	function SWEP:SecondaryAttack(override)
		if override then
			return self.BaseClass.SecondaryAttack(self, override)
		end
	end
end

if CLIENT then
	function SWEP:SetHandPos(noset)
		if not self:IsKnifeDrawn() then
			self.rhandik = false
			self.lhandik = false
			return
		end
		return self.BaseClass.SetHandPos(self, noset)
	end

	function SWEP:Camera(eyePos, eyeAng, view, vellen)
		if not self:IsKnifeDrawn() then return end
		return self.BaseClass.Camera(self, eyePos, eyeAng, view, vellen)
	end

	function SWEP:DrawWorldModel()
		if not self:IsKnifeDrawn() then return end
		self.BaseClass.DrawWorldModel(self)
	end

	function SWEP:DrawWorldModel2()
		if not self:IsKnifeDrawn() then return end
		self.BaseClass.DrawWorldModel2(self)
	end

	surface.CreateFont("MI_SogKnifeScp912_HUD", {
		font = "Tahoma",
		size = 22,
		weight = 700,
		antialias = true,
		extended = true,
	})

	local colBg = Color(0, 0, 0, 140)
	local colText = Color(235, 235, 235, 255)
	local colReady = Color(140, 255, 160, 255)
	local colActive = Color(120, 200, 255, 255)

	function SWEP:DrawScp912HUD()
		local scrW, scrH = ScrW(), ScrH()
		local cx = scrW * 0.5
		local y = scrH - 120
		local lineH = 24
		local lines = {}

		local owner = self:GetOwner()
		local buffEnd = IsValid(owner) and owner:GetNWFloat("MI_KnifeDashBuffEnd", 0) or 0
		local buffLeft = math.max(0, buffEnd - CurTime())
		local nextDash = self:GetNWFloat("MI_NextDash", 0)
		local cd = math.max(0, nextDash - CurTime())

		if buffLeft > 0.05 then
			lines[#lines + 1] = {text = string.format("冲刺中 %.0f 秒", math.ceil(buffLeft)), color = colActive}
		elseif cd <= 0.05 then
			lines[#lines + 1] = {text = "冲刺 就绪", color = colReady}
		else
			lines[#lines + 1] = {text = string.format("冲刺 %.0f 秒", math.ceil(cd)), color = colText}
		end

		local maxW = 0
		for _, line in ipairs(lines) do
			surface.SetFont("MI_SogKnifeScp912_HUD")
			local tw = surface.GetTextSize(line.text)
			if tw > maxW then maxW = tw end
		end

		local padX, padY = 14, 8
		local boxH = #lines * lineH + padY * 2
		local boxW = maxW + padX * 2
		local boxX = cx - boxW * 0.5

		draw.RoundedBox(6, boxX, y - padY, boxW, boxH, colBg)

		for i, line in ipairs(lines) do
			draw.SimpleText(line.text, "MI_SogKnifeScp912_HUD", cx, y + (i - 1) * lineH, line.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
	end

	hook.Add("HUDPaint", "WeaponSogknifeScp912_HUD", function()
		local ply = LocalPlayer()
		if not IsValid(ply) or not ply:Alive() then return end
		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) or wep.DrawScp912HUD == nil then return end
		wep:DrawScp912HUD()
	end)
end
