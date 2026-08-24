if not SERVER then return end

util.AddNetworkString("MissionIntro_Broadcast")
util.AddNetworkString("MissionIntro_BroadcastCustom")
util.AddNetworkString("MissionIntro_BroadcastSound")
util.AddNetworkString("MissionIntro_BroadcastMusic")
util.AddNetworkString("MissionIntro_StopBroadcastSound")

function MissionIntro.StopBroadcastSoundForAll()
	for _, p in ipairs(player.GetAll()) do
		if not IsValid(p) or not p:IsPlayer() then continue end
		net.Start("MissionIntro_StopBroadcastSound")
		net.Send(p)
	end
end

function MissionIntro.BroadcastSoundToAll(soundPath, opts)
	if not isstring(soundPath) or soundPath == "" then return end
	opts = opts or {}

	local forceDuringIntro = opts.forceSoundDuringIntro == true
	for _, p in ipairs(player.GetAll()) do
		if not IsValid(p) or not p:IsPlayer() then continue end
		net.Start("MissionIntro_BroadcastSound")
			net.WriteString(soundPath)
			net.WriteBool(forceDuringIntro)
		net.Send(p)
	end
end

function MissionIntro.BroadcastMusicToAll(soundPath, opts)
	if not isstring(soundPath) or soundPath == "" then return end
	opts = opts or {}

	local forceDuringIntro = opts.forceSoundDuringIntro == true
	local volume = tonumber(opts.volume)
	for _, p in ipairs(player.GetAll()) do
		if not IsValid(p) or not p:IsPlayer() then continue end
		net.Start("MissionIntro_BroadcastMusic")
			net.WriteString(soundPath)
			net.WriteBool(forceDuringIntro)
			net.WriteFloat(volume or -1)
		net.Send(p)
	end
end

-- 全服显示弹窗；入场玩家默认静音（仅弹窗），broadcast_sound_for_intro 的阵营除外
function MissionIntro.BroadcastFactionAlert(factionId, introPlayers)
	if not isstring(factionId) or factionId == "" then
		factionId = MissionIntro.DefaultFaction
	end

	if hook.Run("MissionIntro_BroadcastFaction", factionId, introPlayers) == true then
		return
	end

	if MissionIntro.ShouldBroadcastFaction and not MissionIntro.ShouldBroadcastFaction(factionId) then
		return
	end

	if MissionIntro.IsFacilityFactionId and MissionIntro.IsFacilityFactionId(factionId) then
		return
	end

	local data = MissionIntro.GetFactionBroadcast and MissionIntro.GetFactionBroadcast(factionId)
	if not istable(data) then return end

	local soundForIntro = MissionIntro.FactionBroadcastSoundForIntro
		and MissionIntro.FactionBroadcastSoundForIntro(factionId)

	local silent = {}
	if not soundForIntro and istable(introPlayers) then
		for _, p in ipairs(introPlayers) do
			if IsValid(p) and p:IsPlayer() then
				silent[p] = true
			end
		end
	end

	if not soundForIntro and MissionIntro.ActiveSessions then
		for p, _ in pairs(MissionIntro.ActiveSessions) do
			if IsValid(p) and p:IsPlayer() then
				silent[p] = true
			end
		end
	end

	local noSound = data.no_sound == true
	local sent = 0
	local silentCount = 0
	for _, p in ipairs(player.GetAll()) do
		if not IsValid(p) or not p:IsPlayer() then continue end

		local playSound = (not noSound) and (not silent[p])
		net.Start("MissionIntro_Broadcast")
			net.WriteString(factionId or "")
			net.WriteBool(playSound)
		net.Send(p)

		sent = sent + 1
		if not playSound then
			silentCount = silentCount + 1
		end
	end

	MsgN("[MissionIntro] 广播: " .. tostring(data.title) .. " (" .. factionId .. ") -> 全服 " .. sent .. " 人 (" .. silentCount .. " 人仅弹窗静音)")
end

function MissionIntro.BroadcastCustomAlert(data, opts)
	if not istable(data) then return end
	opts = opts or {}

	if hook.Run("MissionIntro_BroadcastCustom", data, opts) == true then
		return
	end

	local silent = {}
	if istable(opts.silentFor) then
		for _, p in ipairs(opts.silentFor) do
			if IsValid(p) and p:IsPlayer() then
				silent[p] = true
			end
		end
	end

	local playSoundDefault = opts.playSound ~= false
	local forceDuringIntro = opts.forceSoundDuringIntro == true
	local sent = 0

	for _, p in ipairs(player.GetAll()) do
		if not IsValid(p) or not p:IsPlayer() then continue end

		local playSound = playSoundDefault and not silent[p]
		net.Start("MissionIntro_BroadcastCustom")
			net.WriteString(data.title or "Z city")
			net.WriteString(data.line1 or "")
			net.WriteString(data.line2 or "")
			net.WriteUInt(math.Clamp(data.accent and data.accent.r or 255, 0, 255), 8)
			net.WriteUInt(math.Clamp(data.accent and data.accent.g or 64, 0, 255), 8)
			net.WriteUInt(math.Clamp(data.accent and data.accent.b or 64, 0, 255), 8)
			net.WriteString(data.sound or "")
			net.WriteBool(playSound)
			net.WriteBool(forceDuringIntro)
		net.Send(p)

		sent = sent + 1
	end

	MsgN("[MissionIntro] 自定义广播: " .. tostring(data.title) .. " -> 全服 " .. sent .. " 人")
end

concommand.Add("mission_intro_test_broadcast", function(ply, _, args)
	if IsValid(ply) and not ply:IsAdmin() then return end

	local factionId = args[1] or MissionIntro.DefaultFaction
	if MissionIntro.Factions and not MissionIntro.Factions[factionId] then
		factionId = MissionIntro.DefaultFaction
	end

	MissionIntro.BroadcastFactionAlert(factionId, {})
end)
