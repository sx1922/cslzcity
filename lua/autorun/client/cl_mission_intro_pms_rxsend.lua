if not CLIENT then return end

MissionIntro = MissionIntro or {}

local function MI_PMS_BlockSelector()
	if MissionIntro.IsRXSendRound and MissionIntro.IsRXSendRound() then
		chat.AddText(Color(220, 80, 80), "[RX Mission] ", color_white,
			"本回合模型由任务系统分配，无法自行更换。")
		return
	end

	chat.AddText(Color(180, 180, 180), "[RX Mission] ", color_white,
		"玩家模型选择器仅在 RXsend 回合启用；当前模式不可用。")
end

local function MI_PMS_OverrideSelectorCommand()
	concommand.Add("playermodel_selector", MI_PMS_BlockSelector)
	if Menu and Menu.Toggle then
		Menu.Toggle = MI_PMS_BlockSelector
	end
end

hook.Add("Initialize", "MissionIntro_PMS_RxSendClient", function()
	if MissionIntro.SetPlayerModelSelectorCvar then
		MissionIntro.SetPlayerModelSelectorCvar("cl_playermodel_selector_force", "0")
	end
	timer.Simple(0, MI_PMS_OverrideSelectorCommand)
end)

hook.Add("InitPostEntity", "MissionIntro_PMS_RxSendClient", function()
	timer.Simple(2, MI_PMS_OverrideSelectorCommand)
end)
