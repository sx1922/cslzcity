if not SERVER then return end

MissionIntro.ScarletRitualPhase = MissionIntro.ScarletRitualPhase or 0

util.AddNetworkString("MissionIntro_ScarletRitualHUD")
util.AddNetworkString("MissionIntro_ScarletRitualExplosion")

local function MI_BookDir()
	return "rx_mission_intro/books"
end

function MissionIntro.GetScarletBookSavePath()
	return MI_BookDir() .. "/" .. game.GetMap() .. ".json"
end

function MissionIntro.EnsureScarletBookSaveDir()
	if not file.IsDir("rx_mission_intro", "DATA") then
		file.CreateDir("rx_mission_intro")
	end
	if not file.IsDir(MI_BookDir(), "DATA") then
		file.CreateDir(MI_BookDir())
	end
end

function MissionIntro.GetScarletBookEntities()
	return ents.FindByClass("ent_mission_intro_scarlet_book")
end

function MissionIntro.ExportScarletBooks()
	local out = {}
	for _, ent in ipairs(MissionIntro.GetScarletBookEntities()) do
		if not IsValid(ent) then continue end
		local pos = ent:GetPos()
		local ang = ent:GetAngles()
		out[#out + 1] = {
			pos = { x = pos.x, y = pos.y, z = pos.z },
			ang = { p = ang.p, y = ang.y, r = ang.r },
		}
	end
	return out
end

function MissionIntro.CanSaveScarletBooks()
	if MissionIntro._loadingScarletBooks then return false end
	if MissionIntro._suppressScarletBookSave then return false end
	return true
end

function MissionIntro.SaveScarletBooksToDisk()
	if not MissionIntro.CanSaveScarletBooks() then return false end

	MissionIntro.EnsureScarletBookSaveDir()
	local data = MissionIntro.ExportScarletBooks()
	file.Write(MissionIntro.GetScarletBookSavePath(), util.TableToJSON(data, true))
	if MissionIntro.ServerMsg then
		MissionIntro.ServerMsg("log_saved", #data, MissionIntro.L("log_entity_scarlet_book"), MissionIntro.GetScarletBookSavePath())
	else
		MsgN("[MissionIntro] 已保存 " .. #data .. " 本祷告书")
	end
	return true
end

function MissionIntro.ReadScarletBooksFromDisk()
	local path = MissionIntro.GetScarletBookSavePath()
	if not file.Exists(path, "DATA") then return {} end
	local raw = file.Read(path, "DATA")
	if not raw or raw == "" then return {} end
	local ok, data = pcall(util.JSONToTable, raw)
	if not ok or not istable(data) then return {} end
	return data
end

function MissionIntro.CreateScarletBook(pos, ang, silent)
	local ent = ents.Create("ent_mission_intro_scarlet_book")
	if not IsValid(ent) then return nil end

	ent:SetPos(pos)
	ent:SetAngles(ang or angle_zero)
	ent:Spawn()
	ent:Activate()

	if ent.ApplyState then
		ent:ApplyState()
	end

	if not silent then
		MissionIntro.SaveScarletBooksToDisk()
	end

	return ent
end

function MissionIntro.LoadScarletBooksFromDisk()
	if MissionIntro._loadingScarletBooks then return end
	MissionIntro._loadingScarletBooks = true

	for _, ent in ipairs(MissionIntro.GetScarletBookEntities()) do
		if IsValid(ent) then ent:Remove() end
	end

	local data = MissionIntro.ReadScarletBooksFromDisk()
	for _, row in ipairs(data) do
		if not istable(row) or not istable(row.pos) then continue end
		local pos = Vector(tonumber(row.pos.x) or 0, tonumber(row.pos.y) or 0, tonumber(row.pos.z) or 0)
		local ang = Angle(0, 0, 0)
		if istable(row.ang) then
			ang = Angle(tonumber(row.ang.p) or 0, tonumber(row.ang.y) or 0, tonumber(row.ang.r) or 0)
		end
		MissionIntro.CreateScarletBook(pos, ang, true)
	end

	MissionIntro._loadingScarletBooks = false
	if MissionIntro.ServerMsg then
		MissionIntro.ServerMsg("log_loaded_scarlet_books", #data, MissionIntro.GetScarletBookSavePath())
	else
		MsgN("[MissionIntro] 已加载 " .. #data .. " 本祷告书（始终可见）")
	end
end

function MissionIntro.RemoveScarletBook(ent)
	if not IsValid(ent) or ent:GetClass() ~= "ent_mission_intro_scarlet_book" then return false end

	ent:Remove()

	if MissionIntro.SaveScarletBooksToDisk then
		MissionIntro.SaveScarletBooksToDisk()
	end

	return true
end

function MissionIntro.RemoveAllScarletBooks(save)
	MissionIntro._suppressScarletBookSave = true

	for _, ent in ipairs(MissionIntro.GetScarletBookEntities()) do
		if IsValid(ent) then ent:Remove() end
	end

	MissionIntro._suppressScarletBookSave = false

	if save ~= false and MissionIntro.SaveScarletBooksToDisk then
		MissionIntro.SaveScarletBooksToDisk()
	end
end

function MissionIntro.BroadcastScarletRitualHUD(phase, endAt)
	MissionIntro.ScarletRitualPhase = phase or 0

	net.Start("MissionIntro_ScarletRitualHUD")
		net.WriteUInt(math.floor(phase or 0), 3)
		net.WriteFloat(endAt or 0)
	net.Broadcast()
end

function MissionIntro.RevealAllScarletBooks()
	for _, ent in ipairs(MissionIntro.GetScarletBookEntities()) do
		if IsValid(ent) and ent.SetRevealToAll then
			ent:SetRevealToAll(true)
		end
	end
end

function MissionIntro.ClearScarletBookReveal()
	for _, ent in ipairs(MissionIntro.GetScarletBookEntities()) do
		if IsValid(ent) and ent.SetRevealToAll then
			ent:SetRevealToAll(false)
		end
	end
end

function MissionIntro.UpdateScarletPrayerActiveFlag()
	local active = (MissionIntro.ScarletRitualPhase or 0) >= 1
	if not active then
		for _, ent in ipairs(MissionIntro.GetScarletBookEntities()) do
			if IsValid(ent) and IsValid(ent:GetPrayingPlayer()) then
				active = true
				break
			end
		end
	end
	MissionIntro._rxSendScarletPrayerActive = active
	if MissionIntro.RXSendSyncEndgameRoundPause then
		MissionIntro.RXSendSyncEndgameRoundPause()
	end
end

function MissionIntro.ResetScarletRitualState()
	MissionIntro.ScarletRitualPhase = 0
	MissionIntro._rxSendScarletPrayerActive = false

	if MissionIntro.ClearScarletRitualEligible then
		MissionIntro.ClearScarletRitualEligible()
	end

	MissionIntro.ClearScarletBookReveal()

	for _, ent in ipairs(MissionIntro.GetScarletBookEntities()) do
		if not IsValid(ent) then continue end
		ent:SetRitualDone(false)
		ent:SetBookDestroyed(false)
		if ent.CancelPrayer then ent:CancelPrayer() end
		if ent.CancelSabotage then ent:CancelSabotage() end
		if ent.ApplyState then ent:ApplyState() end
	end

	timer.Remove("MissionIntro_ScarletRitualKill")
	MissionIntro.BroadcastScarletRitualHUD(0, 0)
	if MissionIntro.RXSendSyncEndgameRoundPause then
		MissionIntro.RXSendSyncEndgameRoundPause()
	end
end

local function MI_PickRitualExplosionSound()
	local cfg = MissionIntro.ScarletRitual or {}
	local candidates = {}

	if isstring(cfg.explosion_sound) and cfg.explosion_sound ~= "" then
		candidates[#candidates + 1] = cfg.explosion_sound
	end

	candidates[#candidates + 1] = "ambient/explosions/explode_9.wav"
	candidates[#candidates + 1] = "ambient/explosions/explode_4.wav"

	for _, path in ipairs(candidates) do
		if file.Exists("sound/" .. path, "GAME") then
			return path
		end
	end

	return "ambient/explosions/explode_9.wav"
end

function MissionIntro.BroadcastScarletRitualExplosion()
	local soundPath = MI_PickRitualExplosionSound()
	local books = MissionIntro.GetScarletBookEntities()
	local shakePos = Vector(0, 0, 0)

	for _, ent in ipairs(books) do
		if not IsValid(ent) then continue end
		shakePos = ent:GetPos()
		ent:EmitSound(soundPath, 100, 100, 1, CHAN_AUTO)
	end

	util.ScreenShake(shakePos, 12, 8, 1.2, 6000)

	net.Start("MissionIntro_ScarletRitualExplosion")
		net.WriteString(soundPath)
	net.Broadcast()
end

function MissionIntro.KillAllPlayersForRitual()
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:IsPlayer() and ply:Alive() then
			ply:Kill()
		end
	end

	MsgN("[MissionIntro] 猩红仪式：已处决所有人员")
end

function MissionIntro.SabotageScarletRitual(ply, book)
	if (MissionIntro.ScarletRitualPhase or 0) ~= 1 then return end

	timer.Remove("MissionIntro_ScarletRitualKill")
	MissionIntro.ScarletRitualPhase = 0
	MissionIntro.ClearScarletBookReveal()
	MissionIntro.BroadcastScarletRitualHUD(0, 0)

	if IsValid(book) then
		if book.CancelPrayer then book:CancelPrayer() end
		if book.CancelSabotage then book:CancelSabotage() end
	end

	for _, ent in ipairs(MissionIntro.GetScarletBookEntities()) do
		if not IsValid(ent) then continue end
		if ent.CancelPrayer then ent:CancelPrayer() end
		if ent.CancelSabotage then ent:CancelSabotage() end
	end

	local msg = MissionIntro.L and MissionIntro.L("ritual_sabotage_success") or "时空裂缝召唤已被阻止！"
	for _, p in ipairs(player.GetAll()) do
		if IsValid(p) and p:IsPlayer() then
			p:ChatPrint("[MissionIntro] " .. msg)
		end
	end

	if IsValid(ply) then
		MsgN("[MissionIntro] 书本被破坏，仪式中止: " .. ply:Nick())
	end

	if MissionIntro.UpdateScarletPrayerActiveFlag then
		MissionIntro.UpdateScarletPrayerActiveFlag()
	end
end

function MissionIntro.CompleteScarletRitual(ply, book)
	if (MissionIntro.ScarletRitualPhase or 0) >= 1 then return end

	MissionIntro.ScarletRitualPhase = 1

	for _, ent in ipairs(MissionIntro.GetScarletBookEntities()) do
		if not IsValid(ent) then continue end
		if ent.CancelPrayer then ent:CancelPrayer() end
		if ent.CancelSabotage then ent:CancelSabotage() end
	end

	local broadcastData = MissionIntro.GetScarletRitualBroadcast and MissionIntro.GetScarletRitualBroadcast()
	if broadcastData and MissionIntro.BroadcastCustomAlert then
		MissionIntro.BroadcastCustomAlert(broadcastData, { playSound = true })
	end

	local cfg = MissionIntro.ScarletRitual or {}
	local summonDelay = tonumber(cfg.summon_delay) or 180
	local summonEnd = CurTime() + summonDelay

	MissionIntro.BroadcastScarletRitualHUD(1, summonEnd)

	timer.Create("MissionIntro_ScarletRitualKill", summonDelay, 1, function()
		if (MissionIntro.ScarletRitualPhase or 0) ~= 1 then return end

		MissionIntro.ScarletRitualPhase = 0

		for _, ent in ipairs(MissionIntro.GetScarletBookEntities()) do
			if not IsValid(ent) then continue end
			ent:SetRitualDone(true)
			if ent.ApplyState then ent:ApplyState() end
		end

		MissionIntro.BroadcastScarletRitualHUD(0, 0)
		MissionIntro.BroadcastScarletRitualExplosion()
		MissionIntro.KillAllPlayersForRitual()
	end)

	if IsValid(ply) then
		MsgN("[MissionIntro] 猩红仪式进入召唤阶段: " .. ply:Nick())
	end

	if MissionIntro.UpdateScarletPrayerActiveFlag then
		MissionIntro.UpdateScarletPrayerActiveFlag()
	end
end

function MissionIntro.OnScarletBatchSpawned(startList)
	if not istable(startList) or #startList == 0 then return end

	if MissionIntro.ClearScarletRitualEligible then
		MissionIntro.ClearScarletRitualEligible()
	end

	for _, ply in ipairs(startList) do
		if IsValid(ply) and ply:IsPlayer() and MissionIntro.MarkScarletRitualEligible then
			MissionIntro.MarkScarletRitualEligible(ply)
		end
	end
end

hook.Add("InitPostEntity", "MissionIntro_LoadScarletBooks", function()
	timer.Simple(0.5, function()
		if MissionIntro.LoadScarletBooksFromDisk then
			MissionIntro.LoadScarletBooksFromDisk()
		end
	end)
end)

hook.Add("PostCleanupMap", "MissionIntro_ReloadScarletBooks", function()
	timer.Simple(0.5, function()
		MissionIntro.ResetScarletRitualState()
		if MissionIntro.LoadScarletBooksFromDisk then
			MissionIntro.LoadScarletBooksFromDisk()
		end
	end)
end)

hook.Add("PhysgunPickup", "MissionIntro_FreezeScarletBook", function(ply, ent)
	if IsValid(ent) and ent:GetClass() == "ent_mission_intro_scarlet_book" then
		return false
	end
end)

hook.Add("GravGunOnPickedUp", "MissionIntro_FreezeScarletBook", function(ply, ent)
	if IsValid(ent) and ent:GetClass() == "ent_mission_intro_scarlet_book" then
		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion(false)
		end
	end
end)

local MI_RitualRoundHooks = {
	"RoundStart",
	"Breach_NewRound",
	"OnNewRound",
	"HMCD_NewRound",
	"HomigradRoundStart",
	"ZB_PreRoundStart",
	"ZB_StartRound",
}
for _, hookName in ipairs(MI_RitualRoundHooks) do
	hook.Add(hookName, "MissionIntro_ResetScarletRitual", function()
		if hookName == "ZB_PreRoundStart" or hookName == "ZB_StartRound" then
			if not zb or zb.CROUND ~= "rxsend" then
				local nextRound = zb and (zb.nextround or zb.CROUND)
				if nextRound ~= "rxsend" then return end
			end
		end
		MissionIntro.ResetScarletRitualState()
	end)
end

concommand.Add("mission_intro_reset_ritual", function(ply)
	if IsValid(ply) and not ply:IsAdmin() then return end
	MissionIntro.ResetScarletRitualState()
end)

concommand.Add("mission_intro_clear_scarlet_books", function(ply)
	if IsValid(ply) and MissionIntro.CanManage and not MissionIntro.CanManage(ply) and not ply:IsAdmin() then return end
	if MissionIntro.RemoveAllScarletBooks then
		MissionIntro.RemoveAllScarletBooks(true)
	end
	if IsValid(ply) then
		ply:ChatPrint("[MissionIntro] " .. (MissionIntro.L and MissionIntro.L("log_tool_cleared_scarlet_books") or "已清除全部祷告书"))
	end
end)
