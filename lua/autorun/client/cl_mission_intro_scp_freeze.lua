MissionIntro = MissionIntro or {}

if not CLIENT then return end

local COL_TITLE = Color(255, 210, 80)
local COL_TEXT = Color(235, 240, 248)
local COL_DIM = Color(160, 170, 185)

local OVERVIEW_DIST_SQR = 250000
local OVERVIEW_HEIGHT = 400
local RECOVER_SEC = 12
local STABILIZE_SEC = 2.5
local VIEW_OFFSET = Vector(0, 0, 64)
local SCP_FOOT_BONES = {
	"ValveBiped.Bip01_R_Foot",
	"ValveBiped.Bip01_L_Foot",
}

local function MI_IsFacilityScp(ply)
	ply = ply or LocalPlayer()
	return IsValid(ply) and MissionIntro.IsFacilityScpPlayer and MissionIntro.IsFacilityScpPlayer(ply)
end

local function MI_ShouldFixScpFeet(ply)
	return MI_IsFacilityScp(ply) and ply:Alive()
		and (not MissionIntro.IsPlayerScpFrozen or not MissionIntro.IsPlayerScpFrozen(ply))
end

local function MI_MeasureScpFootLift(ply)
	if not IsValid(ply) or not ply:OnGround() then return 0 end
	local baseZ = ply:GetPos().z
	local lowest = nil
	for _, boneName in ipairs(SCP_FOOT_BONES) do
		local bone = ply:LookupBone(boneName)
		if bone then
			local matrix = ply:GetBoneMatrix(bone)
			if matrix then
				local z = matrix:GetTranslation().z - baseZ
				if not lowest or z < lowest then
					lowest = z
				end
			end
		end
	end
	if not lowest or lowest < 2 then return 0 end
	return lowest
end

local function MI_FixScpFeetRenderOffset(ply)
	if not MI_ShouldFixScpFeet(ply) then
		if ply._miScpFootRenderFix then
			ply:SetRenderOrigin()
			ply._miScpFootRenderFix = nil
		end
		return
	end

	if MissionIntro.MI_ClearScpDuckFlags then
		MissionIntro.MI_ClearScpDuckFlags(ply)
	end

	local nextAt = ply._miScpFootMeasureAt or 0
	if CurTime() >= nextAt then
		ply._miScpFootMeasureAt = CurTime() + 0.12
		ply._miScpFootLift = MI_MeasureScpFootLift(ply)
	end

	local lift = ply._miScpFootLift or 0
	if lift > 1.5 then
		ply:SetRenderOrigin(Vector(0, 0, -lift))
		ply._miScpFootRenderFix = true
	else
		ply:SetRenderOrigin()
		ply._miScpFootRenderFix = nil
	end
end
local angleZero = Angle(0, 0, 0)

MissionIntro._scpCamRecoverUntil = MissionIntro._scpCamRecoverUntil or 0
MissionIntro._scpCamLastFrozen = MissionIntro._scpCamLastFrozen or false

local function MI_ShouldStabilizeScpCamera(ply)
	ply = ply or LocalPlayer()
	if not MI_IsFacilityScp(ply) or not ply:Alive() then return false end
	if MissionIntro.ShouldApplyFacilityScpGameplayRules then
		return MissionIntro.ShouldApplyFacilityScpGameplayRules(ply) == true
	end
	return true
end

local function MI_HasStaleFakeRagdoll(ply)
	if not IsValid(ply) then return false end
	if IsValid(follow) and follow ~= ply then return true end
	if IsValid(ply.FakeRagdoll) and not IsValid(ply:GetNWEntity("FakeRagdoll")) then return true end
	return false
end

local function MI_ResetHomigradCameraSway()
	if isvector(angle_difference_localvec) then angle_difference_localvec:Zero() end
	if isvector(angle_difference_localvec2) then angle_difference_localvec2:Zero() end
	if isangle(angle_difference) then angle_difference:Zero() end
	if isangle(angle_difference2) then angle_difference2:Zero() end
	if isvector(position_difference) then position_difference:Zero() end
	if isvector(position_difference2) then position_difference2:Zero() end
	if isvector(position_difference3) then position_difference3:Zero() end
	if isangle(offsetView) then offsetView:Zero() end
	if isangle(lerped_ang) then lerped_ang:Zero() end
	if lean_lerp ~= nil then lean_lerp = 0 end
	if rollang ~= nil then rollang = 0 end
	if isfunction(SetViewPunchAngles) then SetViewPunchAngles(angleZero) end
	if isfunction(SetViewPunchAngles2) then SetViewPunchAngles2(angleZero) end
	if isfunction(SetViewPunchAngles3) then SetViewPunchAngles3(angleZero) end
	if isfunction(SetViewPunchAngles4) then SetViewPunchAngles4(angleZero) end
end

local function MI_ClearClientOrganismDebuffs(ply)
	if not IsValid(ply) or not istable(ply.organism) then return end
	local org = ply.organism
	org.disorientation = 0
	org.pain = 0
	org.painadd = 0
	org.hurt = 0
	org.immobilization = 0
	org.brain = 0
	org.lightstun = 0
	org.stun = 0
	org.adrenaline = 0
	org.otrub = false
	org.canmove = true
	org.canmovehead = true
end

local function MI_ExtendScpCameraRecover(seconds)
	local untilAt = CurTime() + (seconds or STABILIZE_SEC)
	if untilAt > (MissionIntro._scpCamRecoverUntil or 0) then
		MissionIntro._scpCamRecoverUntil = untilAt
	end
end

local function MI_IsLocalScpFrozen()
	local ply = LocalPlayer()
	return IsValid(ply) and ply:Alive() and ply:GetNWBool("MissionIntro_ScpFrozen", false)
end

local function MI_GetSyncedFreezePos(ply)
	if not IsValid(ply) then return nil end
	local pos = ply:GetNWVector("MissionIntro_ScpFreezePos", vector_origin)
	if pos:LengthSqr() < 1 then return nil end
	return pos
end

local function MI_CameraLooksBroken(ply, origin)
	if not IsValid(ply) or not isvector(origin) then return true end
	local body = ply:GetPos()
	if MI_GetSyncedFreezePos(ply) then
		body = MI_GetSyncedFreezePos(ply)
	end
	if origin:DistToSqr(body) > OVERVIEW_DIST_SQR then return true end
	if (origin.z - body.z) > OVERVIEW_HEIGHT then return true end
	return false
end

local function MI_ClearClientFakeRagdoll(ply)
	if not IsValid(ply) then return end
	if IsValid(ply.FakeRagdoll) then
		ply.FakeRagdoll.ply = nil
	end
	ply.FakeRagdoll = nil
	ply.FakeRagdollOld = nil
	ply.OldRagdoll = nil
end

local function MI_ClearHomigradFollow()
	if follow ~= nil then
		follow = nil
	end
	if fakeTimer ~= nil then
		fakeTimer = nil
	end
end

local function MI_FixViewOffset(ply)
	if not IsValid(ply) then return end
	ply:SetViewOffset(VIEW_OFFSET)
	ply:SetViewOffsetDucked(VIEW_OFFSET)
end

function MissionIntro.GetScpFreezeEyePos(ply)
	ply = ply or LocalPlayer()
	if not IsValid(ply) then return vector_origin end

	local freezePos = MI_GetSyncedFreezePos(ply)
	local basePos = freezePos or ply:GetPos()
	local eye = basePos + ply:GetViewOffset()

	if MI_CameraLooksBroken(ply, eye) then
		eye = basePos + VIEW_OFFSET
	end

	return eye
end

function MissionIntro.ResetScpFreezeCamera(ply)
	ply = ply or LocalPlayer()
	if not IsValid(ply) then return end

	MI_ClearHomigradFollow()
	MI_ClearClientFakeRagdoll(ply)
	MI_ResetHomigradCameraSway()
	MI_ClearClientOrganismDebuffs(ply)
	MI_FixViewOffset(ply)
	ply.norender = nil

	if GetViewEntity() ~= ply then
		ply:SetViewEntity(ply)
	end

	local freezePos = MI_GetSyncedFreezePos(ply)
	if freezePos then
		ply:SetPos(freezePos)
	end
end

local function MI_BuildFallbackView(ply, angles, fov, znear, zfar)
	local ang = isangle(angles) and angles or ply:EyeAngles()
	local eye = MissionIntro.GetScpFreezeEyePos(ply)

	-- 定身期间用第一人称 eye，与 Homigrad TPIK / 手持武器共用同一 EyePos
	if MI_IsLocalScpFrozen() then
		return {
			origin = eye,
			angles = ang,
			fov = fov or 90,
			znear = znear or 1,
			zfar = zfar,
			drawviewer = false,
		}
	end

	local tr = util.TraceLine({
		start = eye,
		endpos = eye - ang:Forward() * 72 + ang:Right() * 12,
		filter = ply,
		mask = MASK_SOLID,
	})

	return {
		origin = tr.HitPos,
		angles = ang,
		fov = fov or 90,
		znear = znear or 5,
		zfar = zfar,
		drawviewer = true,
	}
end

local function MI_ShouldForceScpCamera(ply, origin)
	if not MI_IsFacilityScp(ply) or not ply:Alive() then return false end
	if MI_IsLocalScpFrozen() then return true end
	if MI_CameraLooksBroken(ply, origin) then return true end
	if CurTime() < (MissionIntro._scpCamRecoverUntil or 0) and IsValid(follow) and follow ~= ply then
		return true
	end
	return false
end

local function MI_ApplyScpCameraFix(ply, view)
	if not istable(view) then return end
	local fix = MI_BuildFallbackView(ply, view.angles, view.fov, view.znear, view.zfar)
	view.origin = fix.origin
	view.angles = fix.angles
	view.drawviewer = fix.drawviewer
	view.znear = fix.znear or view.znear
end

local function MI_Font(size, weight)
	if MissionIntro.EnsureFont then
		return MissionIntro.EnsureFont({ size = size, weight = weight or 700, antialias = true })
	end
	return "DermaLarge"
end

local function MI_InstallGetCurrentCharacterGuard()
	if not hg or not hg.GetCurrentCharacter then return end
	if MissionIntro._miScpGetCurrentCharacterWrap then return end

	MissionIntro._scpOrigGetCurrentCharacter = hg.GetCurrentCharacter
	function MissionIntro._miScpGetCurrentCharacterWrap(ply)
		if ply == LocalPlayer() and MI_ShouldStabilizeScpCamera(ply) then
			if MI_IsLocalScpFrozen() or not IsValid(ply:GetNWEntity("FakeRagdoll")) then
				return ply
			end
		end
		return MissionIntro._scpOrigGetCurrentCharacter(ply)
	end
	hg.GetCurrentCharacter = MissionIntro._miScpGetCurrentCharacterWrap
end

net.Receive("MissionIntro_ScpFreezeCamReset", function()
	local ply = LocalPlayer()
	if not MI_IsFacilityScp(ply) then return end
	MissionIntro.ResetScpFreezeCamera(ply)
	if ply:GetNWBool("MissionIntro_ScpFrozen", false) then
		MissionIntro._scpCamRecoverUntil = math.huge
	else
		MissionIntro._scpCamRecoverUntil = CurTime() + RECOVER_SEC
	end
end)

hook.Add("Think", "MissionIntro_ScpInstallGetCurrentCharacter", function()
	MI_InstallGetCurrentCharacterGuard()
	hook.Remove("Think", "MissionIntro_ScpInstallGetCurrentCharacter")
end)

hook.Add("InitPostEntity", "MissionIntro_ScpCameraFixInit", function()
	MI_InstallGetCurrentCharacterGuard()

	hook.Add("CalcView", "MissionIntro_ScpCameraFix", function(ply, origin, angles, fov, znear, zfar)
		if ply ~= LocalPlayer() or not MI_ShouldForceScpCamera(ply, origin) then return end
		MI_ClearHomigradFollow()
		MI_ClearClientFakeRagdoll(ply)
		return MI_BuildFallbackView(ply, angles, fov, znear, zfar)
	end)
end)

hook.Add("CreateMove", "MissionIntro_ScpNoCrouch", function(cmd)
	local ply = LocalPlayer()
	if not MI_ShouldStabilizeScpCamera(ply) then return end
	if ply:GetNWBool("MissionIntro_ScpFrozen", false) then return end
	cmd:RemoveKey(IN_DUCK)
	if MissionIntro.MI_ClearScpDuckFlags then
		MissionIntro.MI_ClearScpDuckFlags(ply)
	end
end)

hook.Add("CalcMainActivity", "MissionIntro_ScpNoCrouchAnim", function(ply)
	if not MI_ShouldFixScpFeet(ply) then return end
	if MissionIntro.MI_ClearScpDuckFlags then
		MissionIntro.MI_ClearScpDuckFlags(ply)
	end
end)

hook.Add("Think", "MissionIntro_ScpFootGroundFix", function()
	for _, ply in ipairs(player.GetAll()) do
		if MI_ShouldFixScpFeet(ply) then
			MI_FixScpFeetRenderOffset(ply)
		elseif ply._miScpFootRenderFix then
			ply:SetRenderOrigin()
			ply._miScpFootRenderFix = nil
			ply._miScpFootLift = nil
		end
	end
end)

hook.Add("CreateMove", "MissionIntro_ScpFreezeClientPos", function()
	local ply = LocalPlayer()
	if not MI_IsFacilityScp(ply) or not MI_IsLocalScpFrozen() then return end

	local freezePos = MI_GetSyncedFreezePos(ply)
	if freezePos then
		ply:SetPos(freezePos)
	end
	MI_FixViewOffset(ply)
	MI_ClearClientFakeRagdoll(ply)
end)

hook.Add("Think", "MissionIntro_ScpFreezeCamWatch", function()
	local ply = LocalPlayer()
	if not MI_IsFacilityScp(ply) or not ply:Alive() then return end

	local frozen = MI_IsLocalScpFrozen()
	if frozen ~= MissionIntro._scpCamLastFrozen then
		MissionIntro._scpCamLastFrozen = frozen
		MissionIntro.ResetScpFreezeCamera(ply)
		if frozen then
			MissionIntro._scpCamRecoverUntil = math.huge
		else
			MissionIntro._scpCamRecoverUntil = CurTime() + RECOVER_SEC
		end
	end

	if frozen or CurTime() < (MissionIntro._scpCamRecoverUntil or 0) then
		if IsValid(follow) and follow ~= ply then
			MI_ClearHomigradFollow()
		end
		if frozen then
			MI_ClearClientFakeRagdoll(ply)
			MI_FixViewOffset(ply)
			local freezePos = MI_GetSyncedFreezePos(ply)
			if freezePos then
				ply:SetPos(freezePos)
			end
		end
		if GetViewEntity() ~= ply then
			ply:SetViewEntity(ply)
		end
		ply.norender = nil
	end

	if not MI_ShouldStabilizeScpCamera(ply) then return end

	local onGround = ply:OnGround()
	local vel = ply:GetVelocity():Length()
	local wasOnGround = ply._miScpCamWasOnGround

	if wasOnGround == false and onGround and vel > 180 then
		MI_ExtendScpCameraRecover(STABILIZE_SEC)
		MI_ResetHomigradCameraSway()
		MI_ClearClientOrganismDebuffs(ply)
	end

	ply._miScpCamWasOnGround = onGround

	if MI_HasStaleFakeRagdoll(ply) then
		MI_ClearHomigradFollow()
		MI_ClearClientFakeRagdoll(ply)
		MI_FixViewOffset(ply)
		MI_ExtendScpCameraRecover(STABILIZE_SEC)
	end

	if CurTime() < (MissionIntro._scpCamRecoverUntil or 0) then
		MI_ClearHomigradFollow()
		MI_ResetHomigradCameraSway()
		MI_ClearClientOrganismDebuffs(ply)
		MI_FixViewOffset(ply)
	end
end)

hook.Add("Fake", "MissionIntro_ScpCameraStabilize", function(ply)
	if ply ~= LocalPlayer() or not MI_ShouldStabilizeScpCamera(ply) then return end
	MI_ClearHomigradFollow()
	MI_ClearClientFakeRagdoll(ply)
	MI_ExtendScpCameraRecover(STABILIZE_SEC)
end)

hook.Add("FakeUp", "MissionIntro_ScpCameraStabilize", function(ply)
	if ply ~= LocalPlayer() or not MI_ShouldStabilizeScpCamera(ply) then return end
	MI_ResetHomigradCameraSway()
	MI_ClearClientOrganismDebuffs(ply)
	MI_ExtendScpCameraRecover(STABILIZE_SEC)
end)

hook.Add("hg_AdjustMouseSensitivity", "MissionIntro_ScpStableAim", function(ply)
	if ply ~= LocalPlayer() or not MI_ShouldStabilizeScpCamera(ply) then return end

	local wep = ply:GetActiveWeapon()
	local wepMul = 1
	if IsValid(wep) and wep.IsZoom and wep:IsZoom() then
		local hasSight = wep.HasAttachment and wep:HasAttachment("sight", "optic")
		local zoomBase = (hasSight and not wep.viewmode1) and math.min((wep.ZoomFOV or 60) / 60, 0.5) or 0.4
		local zoomSens = ConVarExists("hg_zoomsensitivity") and GetConVar("hg_zoomsensitivity")
		if zoomSens then
			wepMul = zoomBase * zoomSens:GetFloat()
		else
			wepMul = zoomBase
		end
	end

	local weaponAdjust = 1
	if IsValid(wep) and wep.AdjustMouseSensitivity then
		weaponAdjust = wep:AdjustMouseSensitivity() or 1
	end

	local vel = ply:GetVelocity()
	local isrunning = ply:KeyDown(IN_SPEED) and vel:Length() >= 10 and not ply:Crouching()
		and not IsValid(ply:GetNWEntity("FakeRagdoll"))
	if isrunning and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
		return 0.5 * wepMul * weaponAdjust
	end

	return wepMul * weaponAdjust
end)

hook.Add("PostHGCalcView", "MissionIntro_ScpFreezeCamera", function(ply, view)
	if ply ~= LocalPlayer() or not MI_ShouldForceScpCamera(ply, view and view.origin) then return end
	MI_ClearHomigradFollow()
	MI_ClearClientFakeRagdoll(ply)
	MI_ApplyScpCameraFix(ply, view)
end)

hook.Add("HUDPaint", "MissionIntro_ScpFreezeHud", function()
	if not MI_IsLocalScpFrozen() then return end

	local w, h = ScrW(), ScrH()
	draw.SimpleText("你被定住了", MI_Font(28, 800), w * 0.5, h * 0.18, COL_TITLE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("九尾狐战斗专家 · 无法移动", MI_Font(18, 600), w * 0.5, h * 0.18 + 34, COL_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("仍可转动视角", MI_Font(18, 600), w * 0.5, h * 0.18 + 58, COL_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

concommand.Add("mi_scp_cam_reset", function()
	MissionIntro.ResetScpFreezeCamera()
	MissionIntro._scpCamRecoverUntil = CurTime() + RECOVER_SEC
	chat.AddText(Color(120, 200, 255), "[MissionIntro] ", color_white, "SCP 镜头已重置")
end)
