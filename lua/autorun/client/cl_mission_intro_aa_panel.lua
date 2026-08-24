MissionIntro = MissionIntro or {}

net.Receive("MissionIntro_AaHoldSync", function()
	local active = net.ReadBool()
	if active then
		MissionIntro._aaShutdownHold = {
			holder = net.ReadEntity(),
			ent = net.ReadEntity(),
			endAt = net.ReadFloat(),
			mode = (net.ReadUInt(2) == 2) and "abort" or "close",
		}
	else
		MissionIntro._aaShutdownHold = nil
		if MissionIntro.RefreshAaPanelHud then
			MissionIntro.RefreshAaPanelHud()
		end
	end
end)

net.Receive("MissionIntro_AaHoldAbort", function()
	if MissionIntro.ForceStopUiuHackSounds then
		MissionIntro.ForceStopUiuHackSounds()
	end

	if IsValid(MissionIntro._aaHudPanel) then
		local fr = MissionIntro._aaHudPanel
		local activeBtn = fr._activeHoldBtn
		if IsValid(activeBtn) then
			activeBtn._holding = false
			activeBtn._holdStart = 0
			activeBtn._sentBegin = false
		end
		fr._shutdownHolding = nil
		fr._activeHoldBtn = nil
		if IsValid(fr._holdBar) then
			fr._holdBar:SetVisible(false)
		end
	end
end)

net.Receive("MissionIntro_AaPanelSync", function()
	local wasClosing = MissionIntro._aaClosingInProgress == true

	MissionIntro._aaDangerLevel = net.ReadFloat()
	MissionIntro._aaSystemActive = net.ReadBool()
	MissionIntro._aaCiSpawnEta = net.ReadFloat()
	MissionIntro._aaCiSpawnTriggered = net.ReadBool()
	MissionIntro._aaClosingInProgress = net.ReadBool()
	MissionIntro._aaClosingStarter = net.ReadEntity()

	if wasClosing and MissionIntro._aaClosingInProgress ~= true and MissionIntro.ForceStopUiuHackSounds then
		MissionIntro.ForceStopUiuHackSounds()
	end

	for _, ent in ipairs(ents.FindByClass("ent_mission_intro_aa_panel")) do
		if IsValid(ent) then
			ent:SetDangerLevel(MissionIntro._aaDangerLevel or 0)
			ent:SetAaActive(MissionIntro._aaSystemActive ~= false)
			ent:SetCiSpawnEta(MissionIntro._aaCiSpawnEta or 0)
		end
	end

	if MissionIntro.RefreshAaPanelHud then
		MissionIntro.RefreshAaPanelHud()
	end
end)
