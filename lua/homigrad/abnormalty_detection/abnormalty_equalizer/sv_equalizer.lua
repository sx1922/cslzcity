--\\Перевод плагиновых штук в ваши штуки
hg.Abnormalties = hg.Abnormalties or {}
local PLUGIN = hg.Abnormalties
--//

--\\
PLUGIN.ConjureEqualizer = PLUGIN.ConjureEqualizer or {}
PLUGIN.ConjureEqualizer.ToConjure = PLUGIN.ConjureEqualizer.ToConjure or {}
--//

--\\
function PLUGIN.ConjureEqualizer.Do(ent, time, zone)
	PLUGIN.ConjureEqualizer.ToConjure[#PLUGIN.ConjureEqualizer.ToConjure + 1] = {
		Time = CurTime() + time,
		Zone = zone,
	}
end

local function TryConjureEqualizer(zone, ply)
	local equalizers_consumption = 400
	
	if(PLUGIN.GetZoneOrPlyEqualizers(zone, ply) >= equalizers_consumption)then
		PLUGIN.ShowMessageInSphere("正在召唤均等物...", zone.Pos, zone.Radius)
		PLUGIN.ConjureEqualizer.Do(ent, 5, zone)
		PLUGIN.RemoveZoneOrPlyEqualizers(zone, ply, equalizers_consumption)
		PLUGIN.AddConsequencesToZoneChanters(zone, 3)
		PLUGIN.AddConsequences(ply, 50)
	else
		PLUGIN.ShowMessage(ply, "均等物不足，无法召唤均等物")
	end
end
--//

--\\SpecialEvents
hook.Add("Abnormalties_HotZoneAbnormaltyAdded", "Abnormalties_ConjureEqualizer", function(zone_id, abnormalty_name, amt, ply)
	local zone = PLUGIN.Zones[zone_id]
	
	if(PLUGIN.GetZoneAbnormalty(zone, "shield") >= 20 and PLUGIN.GetZoneAbnormalty(zone, "ritual") >= 10 and PLUGIN.GetZoneAbnormalty(zone, "help") >= 10 and amt > 0)then
		local clear_cd = 10
		
		if(!zone.Vars.RitualPhrasesAmtClearTime)then
			zone.Vars.RitualPhrasesAmtClearTime = CurTime() + clear_cd
		end
		
		if(zone.Vars.RitualPhrasesAmtClearTime <= CurTime())then
			PLUGIN.ResetPhrasesAbnormaltiesFromZone(zone)
			
			zone.Vars.RitualPhrasesAmtClearTime = nil
		end
		
		if(PLUGIN.CompareZonePhrasesToPattern(zone, {{"shield", 5}, {"help", 2}, {"sacrifice", 2}}, 5))then
			TryConjureEqualizer(zone, ply)
			PLUGIN.ResetPhrasesAbnormaltiesFromZone(zone)
			
			zone.Vars.RitualPhrasesAmtClearTime = nil
		end
	end
end)
--//

hook.Add("Think", "Abnormalties_ConjureEqualizer", function()
	for id, info in pairs(PLUGIN.ConjureEqualizer.ToConjure) do
		if(info.Time <= CurTime())then
			if(info.Zone)then
				local new_ent = ents.Create("ent_armor_ego_equalizer")
				
				new_ent:SetPos(info.Zone.Pos + Vector(0, 0, 30))
				new_ent:Spawn()
				new_ent:Activate()
			end
			
			PLUGIN.ConjureEqualizer.ToConjure[id] = nil
		end
	end
end)
-- ulx luarun hg.Abnormalties.FunMode = true for _, ply in player.Iterator() do hg.AddArmor(ply, 'ego_equalizer') end
-- ulx luarun hg.Abnormalties.FunMode = true for _, ply in player.Iterator() do ply:Give('weapon_bleeding_musket') ply.Abnormalties_Blood = 1000000 end
hook.Add("PostCleanupMap", "Abnormalties_ConjureEqualizer", function()
	PLUGIN.ConjureEqualizer.ToConjure = {}
end)

-- The Equalizer is no longer gated by the removed reputation system.  Keep the
-- item available to every player and avoid a per-tick punishment hook.
