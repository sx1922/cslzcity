MissionIntro = MissionIntro or {}

net.Receive("MissionIntro_EttDangerSync", function()
	MissionIntro._ettDangerLevel = net.ReadFloat()
	MissionIntro._ettReinforcementsCalled = net.ReadBool()
	MissionIntro._ettReinforcementsEta = net.ReadFloat()

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_ett_panel")) do
		if IsValid(ent) then
			ent:SetDangerLevel(MissionIntro._ettDangerLevel or 0)
			ent:SetReinforcementsCalled(MissionIntro._ettReinforcementsCalled == true)
			ent:SetReinforcementsEta(MissionIntro._ettReinforcementsEta or 0)
		end
	end

	if IsValid(MissionIntro._ettHudPanel) and IsValid(MissionIntro._ettHudPanel._ettEnt) then
		local hudEnt = MissionIntro._ettHudPanel._ettEnt
		timer.Simple(0, function()
			if IsValid(hudEnt) then
				MissionIntro.OpenEttPanelHud(hudEnt)
			end
		end)
	end
end)
