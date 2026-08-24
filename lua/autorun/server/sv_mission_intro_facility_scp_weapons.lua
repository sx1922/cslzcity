-- SCP 武器：禁止拾取非主武器，捡起后立刻扔掉并补发 98k/武士刀
if not SERVER then return end

MissionIntro = MissionIntro or {}

local HOOK_PRIO_LAST = 1000

local function MI_IsScp(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	-- 仅 RX/设施 SCP 上下文生效；勿用残留 NW 在 cstrike/hmcd 等模式误拦全员捡枪
	if MissionIntro.ShouldEnforceFacilityScpWeaponRules then
		return MissionIntro.ShouldEnforceFacilityScpWeaponRules(ply) == true
	end
	if MissionIntro.PlayerIsFacilityScpForWeapons then
		return MissionIntro.PlayerIsFacilityScpForWeapons(ply) == true
	end
	local rk = ply.RXSendRoleKey or ply:GetNWString("RXSend_RoleKey", "") or ""
	if MissionIntro.IsFacilityScpRoleKey and MissionIntro.IsFacilityScpRoleKey(rk) then
		return true
	end
	return MissionIntro.PlayerHasFacilityScpCredentials and MissionIntro.PlayerHasFacilityScpCredentials(ply) == true
end

local function MI_AllowedClass(ply, className)
	if not isstring(className) or className == "" then return false end
	if MissionIntro.IsFacilityScpAllowedWeaponClass then
		return MissionIntro.IsFacilityScpAllowedWeaponClass(className, ply) == true
	end
	if className == "weapon_hands_sh" then return true end
	if MissionIntro.IsFacilityScpKeycardClass and MissionIntro.IsFacilityScpKeycardClass(className) then return true end
	if MissionIntro.IsScp912WeaponClass and MissionIntro.IsScp912WeaponClass(className) then return true end
	if MissionIntro.GetFacilityScpPrimaryWeaponClass and className == MissionIntro.GetFacilityScpPrimaryWeaponClass(ply) then
		return true
	end
	return false
end

local function MI_PlayerHoldingAllowedWeapon(ply)
	if not IsValid(ply) then return false end
	local active = ply:GetActiveWeapon()
	if not IsValid(active) then return false end
	return MI_AllowedClass(ply, active:GetClass())
end

local function MI_IsScp912Player(ply)
	return MissionIntro.IsFacilityScp912Player and MissionIntro.IsFacilityScp912Player(ply) == true
end

local function MI_ShouldBlockPickup(ply, weapon)
	if not MI_IsScp(ply) or not IsValid(weapon) then return false end
	if ply._missionIntroAllowWeaponGive then return false end
	if MissionIntro.IsFacilityScpAllowedGroundPickup and MissionIntro.IsFacilityScpAllowedGroundPickup(weapon) then
		return false
	end
	return not MI_AllowedClass(ply, weapon:GetClass())
end

function MissionIntro.ShouldFacilityScpBlockWeaponPickup(ply, weapon)
	return MI_ShouldBlockPickup(ply, weapon)
end

function MissionIntro.EnforceFacilityScpWeaponWhitelist(ply)
	if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
	if not MI_IsScp(ply) then return end
	if ply._missionIntroAllowWeaponGive then return end
	if ply:GetNWBool("MissionIntro_IntroPlaying", false) then return end
	if ply._miIntroSpawnPending or ply._miPendingSpawn then return end
	if MissionIntro.IsPlaying and MissionIntro.IsPlaying(ply) then return end

	local now = CurTime()
	if now < (ply._miScpWeaponEnforceGraceUntil or 0) then return end
	if now < (ply._miScpLastWeaponEnforce or 0) + 1.25 then return end

	local primary = MissionIntro.GetFacilityScpPrimaryWeaponClass and MissionIntro.GetFacilityScpPrimaryWeaponClass(ply)
		or "weapon_kar98_12755"

	for _, wep in ipairs(ply:GetWeapons()) do
		if not IsValid(wep) then continue end
		local class = wep:GetClass()
		if MissionIntro.IsScp912WeaponClass and MissionIntro.IsScp912WeaponClass(class) then
			wep.NoDrop = true
			wep.bigNoDrop = true
			continue
		end
		if not MI_AllowedClass(ply, class) then
			wep.NoDrop = nil
			wep.bigNoDrop = nil
			local class = wep:GetClass()
			ply:DropWeapon(wep)
			if ply:HasWeapon(class) then
				ply:StripWeapon(class)
			end
		end
	end

	if hg and hg.weaponInv and istable(ply.weaponInv) and not MI_IsScp912Player(ply) then
		for _, slot in pairs(ply.weaponInv) do
			if istable(slot) then
				for i = #slot, 1, -1 do
					local wep = slot[i]
					if not IsValid(wep) then continue end
					local class = wep:GetClass()
					if MissionIntro.IsScp912WeaponClass and MissionIntro.IsScp912WeaponClass(class) then
						continue
					end
					if not MI_AllowedClass(ply, class) then
						table.remove(slot, i)
						local class = wep:GetClass()
						if ply:HasWeapon(class) then
							ply:StripWeapon(class)
						end
					end
				end
			end
		end
		if isfunction(hg.weaponInv.Sync) then
			hg.weaponInv.Sync(ply)
		end
	end

	-- SCP-912：特供枪只由 sv_mission_intro_scp912_spawn 分批发放；此处勿 Give/SelectWeapon（会触发 M4 Deploy 卡死）
	if MI_IsScp912Player(ply) then
		if MissionIntro.ApplyFacilityScpWeaponNoDrop then
			MissionIntro.ApplyFacilityScpWeaponNoDrop(ply)
		end
		return
	end

	if not ply:HasWeapon(primary) then
		if MissionIntro.GivePlayerWeapon then
			MissionIntro.GivePlayerWeapon(ply, primary)
		else
			ply:Give(primary)
		end
	end

	local primaryWep = ply:GetWeapon(primary)
	if IsValid(primaryWep) and not MI_PlayerHoldingAllowedWeapon(ply) then
		ply:SelectWeapon(primary)
	end

	ply._miScpLastWeaponEnforce = now

	if MissionIntro.ApplyFacilityScpWeaponNoDrop then
		MissionIntro.ApplyFacilityScpWeaponNoDrop(ply)
	end
end

-- homigrad-weapons 会在满槽时 DropWeapon 再 return true；须包裹并在 PlayerCanPickupWeapon 末位 return false
local function MI_WrapHomigradWeaponsPickup()
	local hooks = hook.GetTable()
	local current = hooks.PlayerCanPickupWeapon and hooks.PlayerCanPickupWeapon["homigrad-weapons"]
	if not isfunction(current) then return false end
	if current == MissionIntro._miScpHgWeaponPickupWrap then return true end

	local orig = current
	if orig == MissionIntro._miScpHgWeaponPickupWrap then return true end

	hook.Remove("PlayerCanPickupWeapon", "homigrad-weapons")

	local function wrapped(ply, wep)
		if MI_ShouldBlockPickup(ply, wep) then
			return false
		end
		return orig(ply, wep)
	end
	MissionIntro._miScpHgWeaponPickupWrap = wrapped
	hook.Add("PlayerCanPickupWeapon", "homigrad-weapons", wrapped)
	return true
end

local function MI_WrapPlayerWeaponMeta()
	local meta = FindMetaTable("Player")
	if not meta then return end

	if meta.PickupWeapon ~= MissionIntro._miScpPickupWeaponWrap then
		if isfunction(meta.PickupWeapon) and meta.PickupWeapon ~= MissionIntro._miScpPickupWeaponWrap then
			MissionIntro._miScpOrigPickupWeapon = meta.PickupWeapon
		end
		if isfunction(MissionIntro._miScpOrigPickupWeapon) then
			function MissionIntro._miScpPickupWeaponWrap(self, wep)
				if MI_ShouldBlockPickup(self, wep) then
					return
				end
				return MissionIntro._miScpOrigPickupWeapon(self, wep)
			end
			meta.PickupWeapon = MissionIntro._miScpPickupWeaponWrap
		end
	end

	if meta.DropWeapon ~= MissionIntro._miScpDropWeaponWrap then
		if isfunction(meta.DropWeapon) and meta.DropWeapon ~= MissionIntro._miScpDropWeaponWrap then
			MissionIntro._miScpOrigDropWeapon = meta.DropWeapon
		end
		if isfunction(MissionIntro._miScpOrigDropWeapon) then
			function MissionIntro._miScpDropWeaponWrap(self, wep)
				if MI_IsScp(self) and IsValid(wep) then
					if wep.NoDrop or wep.bigNoDrop then return end
					if MissionIntro.IsFacilityScpAllowedWeaponClass and MissionIntro.IsFacilityScpAllowedWeaponClass(wep:GetClass(), self) then
						return
					end
				end
				return MissionIntro._miScpOrigDropWeapon(self, wep)
			end
			meta.DropWeapon = MissionIntro._miScpDropWeaponWrap
		end
	end

	if meta.Give ~= MissionIntro._miScpGiveWrap then
		if isfunction(meta.Give) and meta.Give ~= MissionIntro._miScpGiveWrap then
			MissionIntro._miScpOrigGive = meta.Give
		end
		if isfunction(MissionIntro._miScpOrigGive) then
			function MissionIntro._miScpGiveWrap(self, className, ...)
				if not self._missionIntroAllowWeaponGive and MI_IsScp(self) and isstring(className) and className ~= "" then
					local allowed = MI_AllowedClass(self, className)
					if MissionIntro.IsScp912WeaponClass and MissionIntro.IsScp912WeaponClass(className) then
						allowed = true
					end
					if not allowed then
						return NULL
					end
				end
				return MissionIntro._miScpOrigGive(self, className, ...)
			end
			meta.Give = MissionIntro._miScpGiveWrap
		end
	end
end

local function MI_WrapWeaponInvInsert()
	if not hg or not hg.weaponInv or not isfunction(hg.weaponInv.Insert) then return end
	if hg.weaponInv.Insert == MissionIntro._miScpWeaponInvInsertWrap then return end
	local origInsert = hg.weaponInv.Insert
	function MissionIntro.MI_ScpWrappedWeaponInvInsert(ply, wep)
		if IsValid(ply) and IsValid(wep) and MI_ShouldBlockPickup(ply, wep) then
			return false
		end
		return origInsert(ply, wep)
	end
	MissionIntro._miScpWeaponInvInsertWrap = MissionIntro.MI_ScpWrappedWeaponInvInsert
	hg.weaponInv.Insert = MissionIntro._miScpWeaponInvInsertWrap
end

local function MI_InstallAllScpWeaponGuards()
	MI_WrapPlayerWeaponMeta()
	MI_WrapHomigradWeaponsPickup()
	MI_WrapWeaponInvInsert()
end

function MissionIntro.MI_ReinstallScpWeaponGuards()
	MI_InstallAllScpWeaponGuards()
end

-- 高优先级：在 homigrad-weapons return true 之后仍 return false
hook.Add("PlayerCanPickupWeapon", "MissionIntro_FacilityScpBlockPickup", function(ply, weapon)
	if MI_ShouldBlockPickup(ply, weapon) then
		return false
	end
end, HOOK_PRIO_LAST)

hook.Add("PlayerUse", "MissionIntro_FacilityScpBlockWeaponUse", function(ply, ent)
	if not MI_IsScp(ply) or not IsValid(ent) then return end
	if ent:IsWeapon() and MI_ShouldBlockPickup(ply, ent) then
		return true
	end
end)

hook.Add("AllowPlayerPickup", "MissionIntro_FacilityScpBlockWeaponUse", function(ply, ent)
	if not MI_IsScp(ply) or not IsValid(ent) then return end
	if ent:IsWeapon() and MI_ShouldBlockPickup(ply, ent) then
		return false
	end
end)

hook.Add("OnPlayerPhysicsPickup", "MissionIntro_FacilityScpBlockPhysicsPickup", function(ply, ent)
	if not MI_IsScp(ply) or not IsValid(ent) then return end
	if ent:IsWeapon() and MI_ShouldBlockPickup(ply, ent) then
		return false
	end
end)

hook.Add("WeaponEquip", "MissionIntro_FacilityScpWeaponEnforce", function(wep, ply)
	if not MI_IsScp(ply) or MI_IsScp912Player(ply) then return end
	timer.Simple(0, function()
		if IsValid(ply) then
			MissionIntro.EnforceFacilityScpWeaponWhitelist(ply)
		end
	end)
end)

hook.Add("PlayerSwitchWeapon", "MissionIntro_FacilityScpWeaponEnforce", function(ply, oldWep, newWep)
	if not MI_IsScp(ply) or MI_IsScp912Player(ply) or not IsValid(newWep) then return end
	if MI_AllowedClass(ply, newWep:GetClass()) then return end
	MissionIntro.EnforceFacilityScpWeaponWhitelist(ply)
	return true
end)

hook.Add("MissionIntro_AfterFinishIntro", "MissionIntro_FacilityScpWeaponGuards", function(ply)
	MI_InstallAllScpWeaponGuards()
	if IsValid(ply) and MI_IsScp(ply) then
		MissionIntro.EnforceFacilityScpWeaponWhitelist(ply)
	end
end)

function MissionIntro.ClearScpGroundPickupBlocks()
	for _, ent in ipairs(ents.GetAll()) do
		if not IsValid(ent) or not ent:IsWeapon() then continue end
		if not IsValid(ent:GetOwner()) and ent._miScpBlockedPickup then
			ent.dontPickup = nil
			ent._miScpBlockedPickup = nil
		end
	end
end

local function MI_ClearStaleGroundDontPickupWorker()
	if MissionIntro.ShouldModeUseFacilityScpRoles
		and MissionIntro.ShouldModeUseFacilityScpRoles(zb and (zb.CROUND or zb.nextround)) then
		return
	end
	if MissionIntro.RXSendIsActive and MissionIntro.RXSendIsActive() then return end

	for _, ent in ipairs(ents.GetAll()) do
		if not IsValid(ent) or not ent:IsWeapon() then continue end
		if IsValid(ent:GetOwner()) then continue end
		if ent._miScpBlockedPickup or ent.dontPickup then
			ent.dontPickup = nil
			ent._miScpBlockedPickup = nil
		end
	end
end

local function MI_ClearStaleGroundDontPickup()
	timer.Simple(0, MI_ClearStaleGroundDontPickupWorker)
end

hook.Add("ZB_PreRoundStart", "MissionIntro_ClearScpWeaponDontPickup", MI_ClearStaleGroundDontPickup)
hook.Add("ZB_EndRound", "MissionIntro_ClearScpWeaponDontPickup", MI_ClearStaleGroundDontPickup)

timer.Create("MissionIntro_FacilityScpWeaponScan", 1.0, 0, function()
	if not MissionIntro.ShouldRunFacilityScpRoundMaintenance() then return end
	for _, ply in ipairs(player.GetAll()) do
		if not MI_IsScp(ply) or MI_IsScp912Player(ply) then continue end
		if ply:GetNWBool("MissionIntro_IntroPlaying", false) then continue end
		if MissionIntro.IsPlaying and MissionIntro.IsPlaying(ply) then continue end
		MissionIntro.EnforceFacilityScpWeaponWhitelist(ply)
	end
end)

hook.Add("InitPostEntity", "MissionIntro_FacilityScpWeaponGuards", MI_InstallAllScpWeaponGuards)
timer.Create("MissionIntro_FacilityScpWeaponGuards", 0.25, 0, function()
	if MissionIntro.RXSendIsActive and not MissionIntro.RXSendIsActive() then return end
	MI_InstallAllScpWeaponGuards()
end)
MI_InstallAllScpWeaponGuards()

concommand.Add("mission_intro_scp_weapon_check", function(ply)
	if IsValid(ply) and not ply:IsAdmin() then return end
	local target = IsValid(ply) and ply or player.GetAll()[1]
	if not IsValid(target) then return end
	local rk = target:GetNWString("RXSend_RoleKey", "")
	print("[MissionIntro] role=" .. rk
		.. " forWeapons=" .. tostring(MissionIntro.PlayerIsFacilityScpForWeapons and MissionIntro.PlayerIsFacilityScpForWeapons(target))
		.. " rules=" .. tostring(MissionIntro.ShouldEnforceFacilityScpWeaponRules and MissionIntro.ShouldEnforceFacilityScpWeaponRules(target))
		.. " cred=" .. tostring(MissionIntro.PlayerHasFacilityScpCredentials and MissionIntro.PlayerHasFacilityScpCredentials(target))
		.. " scpNW=" .. tostring(target:GetNWBool("MissionIntro_IsFacilityScp", false))
		.. " introPlaying=" .. tostring(target:GetNWBool("MissionIntro_IntroPlaying", false))
		.. " hgWrap=" .. tostring(MissionIntro._miScpHgWeaponPickupWrap ~= nil)
		.. " pickupWrap=" .. tostring(MissionIntro._miScpPickupWeaponWrap ~= nil)
		.. " dropWrap=" .. tostring(MissionIntro._miScpDropWeaponWrap ~= nil))
end)

MsgN("[MissionIntro] SCP weapon pickup block ACTIVE (sv_mission_intro_facility_scp_weapons.lua)")
