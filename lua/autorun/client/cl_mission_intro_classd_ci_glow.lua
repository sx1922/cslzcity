if not CLIENT then return end

MissionIntro = MissionIntro or {}

local GLOW_IMPOSTOR_CI = Color(255, 180, 70)
local GLOW_IMPOSTOR_DR = Color(120, 255, 160)

local function MI_SkipLegacyAllyGlow()
	return MissionIntro.ShouldUseRxsendTeamPanel and MissionIntro.ShouldUseRxsendTeamPanel()
end

hook.Add("PreDrawHalos", "MissionIntro_ClassdCiImpostorGlow", function()
	if MI_SkipLegacyAllyGlow() then return end
	if MissionIntro.IsAllyGlowDrawingAllowed and not MissionIntro.IsAllyGlowDrawingAllowed() then return end
	if not MissionIntro.ShouldClassdCiImpostorGlowPair then return end

	local viewer = LocalPlayer()
	if not IsValid(viewer) or not viewer:Alive() then return end

	local targets = {}
	for _, ply in ipairs(player.GetAll()) do
		if MissionIntro.ShouldClassdCiImpostorGlowPair(viewer, ply) then
			targets[#targets + 1] = ply
		end
	end

	if #targets == 0 then return end

	halo.Add(targets, GLOW_IMPOSTOR_CI, 2, 2, 1, true, true)
end)

hook.Add("PreDrawHalos", "MissionIntro_ClassdDrImpostorGlow", function()
	if MI_SkipLegacyAllyGlow() then return end
	if MissionIntro.IsAllyGlowDrawingAllowed and not MissionIntro.IsAllyGlowDrawingAllowed() then return end
	if not MissionIntro.ShouldClassdDrImpostorGlowPair then return end

	local viewer = LocalPlayer()
	if not IsValid(viewer) or not viewer:Alive() then return end

	local targets = {}
	for _, ply in ipairs(player.GetAll()) do
		if MissionIntro.ShouldClassdDrImpostorGlowPair(viewer, ply) then
			targets[#targets + 1] = ply
		end
	end

	if #targets == 0 then return end

	halo.Add(targets, GLOW_IMPOSTOR_DR, 2, 2, 1, true, true)
end)
