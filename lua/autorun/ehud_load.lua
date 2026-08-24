-- ---------------------------------------------------------------------------
-- //// Don't change anything here if you don't know what you are doing ////
-- ---------------------------------------------------------------------------

if ( SERVER ) then
	--esclib (uncomment if you are using workshop version)
	--resource.AddWorkshop( "2888113484" ) -- https://steamcommunity.com/sharedfiles/filedetails/?id=2888113484

	--content (materials, sounds)
	resource.AddWorkshop( "2888079747" ) -- https://steamcommunity.com/sharedfiles/filedetails/?id=2888079747
end

ehud = ehud or {}
ehud.config = ehud.config or {}
ehud.vars = ehud.vars or {}

local function loader()
	--Using esclib loader system
	esclib.loader:New("ehud","ehud/",function(load)
		--fonts used in addon
		load:Resource("resource/fonts/unisans.ttf")

		--In workshop content
		load:Resource("sound/ehud_hitmark.wav")
		load:Resource("sound/ehud_heart.wav")
		load:MaterialFolder("materials/ehud",true,false) --load.Materials params: path, isrecurse, download
		
		ehud.Materials = ehud.Materials or {}
		table.Merge(ehud.Materials, load.Materials)
		ehud.Materials["gradient"] = Material("gui/gradient","smooth")

		--CONFIGS
		load:Shared("config/ehud_meta.lua")
		load:Shared("config/ehud_config.lua")
		load:Client("config/ehud_advanced_config.lua")
		load:Client("config/ehud_theme.lua")
		load:Client("config/ehud_languages.lua")

		load:ClientFolder("vgui")

		--MAIN FILES
		load:Server("core/__servercore__.lua")
		load:Client("core/__core__.lua")
		load:Client("core/module_main_hud.lua")
		load:Client("core/module_impact.lua")
		load:Client("core/module_ammo.lua")
		load:Client("core/module_notify.lua")
		load:Client("core/module_pickups.lua")
		load:Client("core/module_player.lua")
		load:Client("core/module_voice.lua")
		load:Client("core/module_death_screen.lua")
		load:Client("core/module_door_display.lua")
		load:Client("core/module_votes.lua")
		load:Client("core/module_agenda.lua")
		load:Client("core/module_fpp.lua")
		load:Client("core/module_crashscreen.lua")
		load:Client("core/module_vehicle.lua")
		load:Client("core/module_selector.lua")
		load:Client("core/module_xp.lua")
	end)
end

--lua refresh compat
if esclib then
	if esclib.loader.addons["ehud"] then
		if esclib.loader.addons["ehud"].finished then
			loader()
		end
	end
end

hook.Add("esclib_loaded", "ehud_load", function()
	loader()
end)