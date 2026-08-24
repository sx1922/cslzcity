if not CLIENT then return end

MissionIntro = MissionIntro or {}

function MissionIntro.IsAllyGlowDrawingAllowed()
	if MissionIntro.ShouldUseRxsendTeamPanel and MissionIntro.ShouldUseRxsendTeamPanel() then
		return false
	end
	if MissionIntro.ShouldDrawAllyGlows then
		return MissionIntro.ShouldDrawAllyGlows()
	end
	return true
end
