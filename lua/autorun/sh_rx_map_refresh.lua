MissionIntro = MissionIntro or {}
MissionIntro.RXMapRefresh = MissionIntro.RXMapRefresh or {}

MissionIntro.RXMapRefresh.PersistEnabled = true
MissionIntro.RXMapRefresh.DataDir = "rx_mission_intro/map_refresh"
MissionIntro.RXMapRefresh.RemoveRadius = 96

function MissionIntro.RXMapRefresh.GetSavePath()
	local dir = MissionIntro.RXMapRefresh.DataDir or "rx_mission_intro/map_refresh"
	return dir .. "/" .. game.GetMap() .. ".json"
end
