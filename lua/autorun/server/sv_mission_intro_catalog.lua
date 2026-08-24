MissionIntro = MissionIntro or {}



util.AddNetworkString("MissionIntro_CatalogRequest")

util.AddNetworkString("MissionIntro_CatalogSync")



local CATALOG_NET_MAX = 60000



local function MI_SortedRoleIdsFallback(roleTable)

	local ids = {}

	for roleId in pairs(roleTable or {}) do

		if istable(roleTable[roleId]) then ids[#ids + 1] = roleId end

	end

	table.sort(ids)

	return ids

end



function MissionIntro.BuildCatalogSnapshot()

	local rewards = MissionIntro.FactionRewards

	if not istable(rewards) then return nil end



	local factions = MissionIntro.BuildCatalogFactions and MissionIntro.BuildCatalogFactions(rewards) or {}

	local roles = {}



	for _, fac in ipairs(factions) do

		for _, row in ipairs(fac.roles or {}) do

			roles[#roles + 1] = row

		end

	end



	-- 兼容旧逻辑：若 bundle 为空则回退到旧阵营列表

	if #roles == 0 then

		for _, factionId in ipairs(MissionIntro.CatalogFactionOrder or {}) do

			local roleTable = MissionIntro.GetCatalogFactionRoles and MissionIntro.GetCatalogFactionRoles(factionId)

			if not istable(roleTable) then continue end



			local factionLabel = MissionIntro.GetCatalogFactionLabel(factionId)



			for _, roleId in ipairs(MI_SortedRoleIdsFallback(roleTable)) do

				local roleCfg = roleTable[roleId]

				if not istable(roleCfg) then continue end



				local entry = MissionIntro.BuildCatalogRoleEntry(rewards, {

					bundle_id = factionId,

					bundle_name = factionLabel,

					faction_id = factionId,

					faction_name = factionLabel,

					role_id = roleId,

				}, roleCfg, roleCfg.reward_profile or roleId)



				if entry then

					roles[#roles + 1] = entry

				end

			end

		end

	end



	return {

		factions = factions,

		roles = roles,

	}

end



function MissionIntro.SendCatalogToPlayer(ply)

	if not IsValid(ply) or not ply:IsPlayer() then return end



	local data = MissionIntro.BuildCatalogSnapshot()

	if not istable(data) then return end



	local packed = MissionIntro.PackCatalogForNet and MissionIntro.PackCatalogForNet(data) or data

	local json = util.TableToJSON(packed)

	if not isstring(json) or json == "" then return end



	local compressed = util.Compress(json)

	if not isstring(compressed) or #compressed == 0 then return end



	if #compressed > CATALOG_NET_MAX then

		ErrorNoHalt("[rx_mission_intro] Catalog sync payload too large (" .. #compressed .. " bytes)\n")

		return

	end



	net.Start("MissionIntro_CatalogSync")

		net.WriteUInt(#compressed, 32)

		net.WriteData(compressed, #compressed)

	net.Send(ply)

end



net.Receive("MissionIntro_CatalogRequest", function(_, ply)

	if not IsValid(ply) or not ply:IsPlayer() then return end

	MissionIntro.SendCatalogToPlayer(ply)

end)



hook.Add("PlayerInitialSpawn", "MissionIntro_CatalogInitialSync", function(ply)

	timer.Simple(3, function()

		if IsValid(ply) then

			MissionIntro.SendCatalogToPlayer(ply)

		end

	end)

end)

