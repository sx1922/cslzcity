MissionIntro = MissionIntro or {}
MissionIntro.RXMapRefresh = MissionIntro.RXMapRefresh or {}

MissionIntro.RXMapRefresh.ClientRows = MissionIntro.RXMapRefresh.ClientRows or {}

net.Receive("MissionIntro_RXMapRefresh_Sync", function()
	MissionIntro.RXMapRefresh.ClientRows = net.ReadTable() or {}
end)

function MissionIntro.RXMapRefresh.RequestSync()
	net.Start("MissionIntro_RXMapRefresh_Sync")
	net.SendToServer()
end
