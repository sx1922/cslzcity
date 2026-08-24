-- Q 菜单：Utilities → RX 设施入场（与 RX 任务入场 并列）

hook.Add("PopulateToolMenu", "MissionIntro_FacilityToolMenu", function()
	spawnmenu.AddToolCategory("Utilities", "rx_mission_intro_facility", MissionIntro.L("tool_category_facility"))

	spawnmenu.AddToolMenuOption(
		"Utilities",
		"rx_mission_intro_facility",
		"mission_intro_facility_admin",
		MissionIntro.L("tool_facility_name"),
		"",
		"icon16/group.png",
		function(panel)
			if IsValid(panel) then
				panel.Paint = function(self, w, h)
					draw.RoundedBox(0, 0, 0, w, h, Color(248, 249, 252))
				end
			end
			if MissionIntro.BuildFacilityAdminCPanel then
				MissionIntro.BuildFacilityAdminCPanel(panel)
			end
		end
	)
end)

concommand.Add("mission_intro_facility_admin", function()
	if not MissionIntro.CanManage() then
		chat.AddText(Color(255, 120, 120), "[MissionIntro] ", color_white, MissionIntro.L("panel_admin_only"))
		return
	end
	if MissionIntro.OpenFacilityAdminHUD then
		MissionIntro.OpenFacilityAdminHUD()
	end
end)
