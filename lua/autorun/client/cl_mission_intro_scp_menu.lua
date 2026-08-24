-- Q 菜单：Utilities → RX SCP 入场（与 RX 设施入场 分开）

hook.Add("PopulateToolMenu", "MissionIntro_ScpToolMenu", function()
	spawnmenu.AddToolCategory("Utilities", "rx_mission_intro_scp", MissionIntro.L("tool_category_scp"))

	spawnmenu.AddToolMenuOption(
		"Utilities",
		"rx_mission_intro_scp",
		"mission_intro_scp_admin",
		MissionIntro.L("tool_scp_name"),
		"",
		"icon16/user_gray.png",
		function(panel)
			if IsValid(panel) then
				panel.Paint = function(self, w, h)
					draw.RoundedBox(0, 0, 0, w, h, Color(248, 249, 252))
				end
			end
			if MissionIntro.BuildScpAdminCPanel then
				MissionIntro.BuildScpAdminCPanel(panel)
			end
		end
	)
end)

concommand.Add("mission_intro_scp_admin", function()
	if not MissionIntro.CanManage() then
		chat.AddText(Color(255, 120, 120), "[MissionIntro] ", color_white, MissionIntro.L("panel_admin_only"))
		return
	end
	if MissionIntro.OpenScpAdminHUD then
		MissionIntro.OpenScpAdminHUD()
	end
end)
