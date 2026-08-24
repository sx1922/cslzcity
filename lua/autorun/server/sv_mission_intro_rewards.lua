MissionIntro = MissionIntro or {}

MissionIntro.ScarletCultistModel = "models/cultist/humans/cultists/cultist.mdl"
MissionIntro.ScarletCultistBodygroupBase = 0

MissionIntro.ScarletRoleBodygroups = {
	bishop = {
		[0] = 3,
		[1] = 4,
		[2] = 2,
		[3] = 1,
	},
	flock = {
		[0] = 0,
		[1] = 0,
		[2] = 0,
		[3] = 0,
	},
	heretic = {
		[0] = 3,
		[1] = 2,
		[2] = 2,
		[3] = 1,
	},
}

MissionIntro.HammerfallMogModel = "models/cultist/humans/mog/mog.mdl"

MissionIntro.FactionRewards = {

	scarlet_bishop = {

		weapon = "weapon_akm",

		extra_weapons = {

			"weapon_morphine",

			"weapon_bigbandage_sh",

			"weapon_medkit_sh",

			"weapon_fury16",

			"weapon_buck200knife",

			"weapon_hands_sh",

		},

		ammo_entity = "ent_ammo_7.62x39mm",

		ammo_count = 60,

		ammo_types = {

			"7.62x39mm",

			"7.62x39MM",

			"7.62x39",

			"762x39",

			"Rifle",

			"AR2",

		},

		equipment = {

			"ent_armor_helmet5",

			"ent_armor_vest1",

		},

		player_model = MissionIntro.ScarletCultistModel or "models/cultist/humans/cultists/cultist.mdl",

		player_bodygroups = MissionIntro.ScarletRoleBodygroups and MissionIntro.ScarletRoleBodygroups.bishop or {
			[0] = 3,
			[1] = 4,
			[2] = 2,
			[3] = 1,
		},

		force_player_model = true,

	},

	scarlet_flock = {

		weapon = "weapon_ak74u",

		extra_weapons = {

			"weapon_bigbandage_sh",

		},

		ammo_entity = "ent_ammo_5.45x39mm",

		ammo_count = 60,

		ammo_types = {

			"5.45x39mm",

			"5.45x39MM",

			"5.45x39",

			"545x39",

			"545x39mm",

			"SMG1",

			"AR2",

		},

		equipment = {},

		player_model = MissionIntro.ScarletCultistModel or "models/cultist/humans/cultists/cultist.mdl",

		player_bodygroups = MissionIntro.ScarletRoleBodygroups and MissionIntro.ScarletRoleBodygroups.flock or {
			[0] = 0,
			[1] = 0,
			[2] = 0,
			[3] = 0,
		},

		force_player_model = true,

	},

	scarlet_heretic = {

		weapon = "weapon_hg_rpg",

		ammo_entity = "ent_ammo_rpg-7projectile",

		ammo_count = 1,

		ammo_types = {

			"RPG_Round",

			"RPG",

			"Rocket",

			"rpg",

		},

		secondary_weapon = "weapon_glock17",

		secondary_ammo_entity = "ent_ammo_9x19mmparabellum",

		secondary_ammo_count = 30,

		secondary_ammo_types = {

			"9x19mm",

			"9x19MM",

			"9x19",

			"Pistol",

			"SMG1",

		},

		equipment = {

			"ent_armor_helmet7",

			"ent_armor_vest4",

		},

		extra_weapons = {

			"weapon_medkit_sh",

		},

		player_model = MissionIntro.ScarletCultistModel or "models/cultist/humans/cultists/cultist.mdl",

		player_bodygroups = MissionIntro.ScarletRoleBodygroups and MissionIntro.ScarletRoleBodygroups.heretic or {
			[0] = 3,
			[1] = 2,
			[2] = 2,
			[3] = 1,
		},

		force_player_model = true,

	},

	hammerfall_soldier = {

		weapon = "weapon_m4a1",

		extra_weapons = {

			"weapon_tourniquet",

			"weapon_bloodbag",

			"weapon_adrenaline",

			"weapon_painkillers",

			"weapon_medkit_sh",

			"weapon_handcuffs_key",

			"weapon_handcuffs",

		},

		ammo_entity = "ent_ammo_5.56x45mm",

		ammo_count = 60,

		ammo_types = {

			"5.56x45mm",

			"5.56x45MM",

			"556x45",

			"556x45mm",

			"SMG1",

			"AR2",

			"Rifle",

		},

		equipment = {

			"ent_armor_helmet5",

			"ent_armor_vest1",

		},

		player_model = MissionIntro.HammerfallMogModel or "models/cultist/humans/mog/mog.mdl",

		player_bodygroups = MissionIntro.HammerfallRoleBodygroups and MissionIntro.HammerfallRoleBodygroups.soldier,

		player_skin = 0,

		force_player_model = true,

	},

	hammerfall_commander = {

		weapon = "weapon_asval",

		extra_weapons = {

			"weapon_tourniquet",

			"weapon_bloodbag",

			"weapon_adrenaline",

			"weapon_painkillers",

			"weapon_medkit_sh",

			"weapon_handcuffs_key",

			"weapon_handcuffs",

			"weapon_survival_scanner",

		},

		ammo_entity = "ent_ammo_9x39mm",

		ammo_count = 40,

		ammo_types = {

			"9x39mm",

			"9x39MM",

			"9x39",

			"SMG1",

			"AR2",

		},

		equipment = {

			"ent_armor_helmet5",

			"ent_armor_nightvision1",

			"ent_armor_vest1",

		},

		player_model = MissionIntro.PttrbModel or "models/cultist/humans/security/security_mobilized.mdl",

		player_bodygroups = MissionIntro.PttrbRoleBodygroups and MissionIntro.PttrbRoleBodygroups.leader,

		player_skin = 0,

		force_player_model = true,

	},

	sid_agent = {

		weapon = "weapon_mp5",

		extra_weapons = {

			"weapon_morphine",

			"weapon_bigbandage_sh",

		},

		ammo_entity = "ent_ammo_9x19mmparabellum",

		ammo_count = 50,

		ammo_types = {

			"9x19mm",

			"9x19MM",

			"9x19",

			"Pistol",

			"SMG1",

		},

		equipment = {

			"ent_armor_helmet1",

			"ent_armor_vest4",

			"ent_att_supressor4",

		},

		player_model = MissionIntro.SidAgentModel or "models/cultist/humans/fbi/fbi.mdl",

		player_bodygroups = MissionIntro.SidCaptainBodygroups,

		player_skin = 0,

		force_player_model = true,

	},

	sid_captain = {

		weapon = "weapon_p90",

		extra_weapons = {

			"nox_gas_grenade",

			"weapon_hg_grenade_tpik",

			"weapon_bandage_sh",

			"weapon_bigbandage_sh",

			"weapon_needle",

			"weapon_medkit_sh",

		},

		ammo_entity = "ent_ammo_5.7x28mm",

		ammo_count = 50,

		ammo_types = {

			"5.7x28mm",

			"5.7x28MM",

			"5.7x28",

			"57x28",

			"SMG1",

			"Pistol",

		},

		equipment = {

			"ent_armor_helmet1",

			"ent_armor_vest4",

			"ent_att_supressor4",

		},

		player_model = MissionIntro.SidAgentModel or "models/cultist/humans/fbi/fbi.mdl",

		player_bodygroups = MissionIntro.SidExpertBodygroups,

		player_skin = 0,

		force_player_model = true,

	},

	sid_expert = {

		weapon = "weapon_saiga12",

		extra_weapons = {

			"weapon_mission_intro_scp_freeze",

			"weapon_hg_smokenade_tpik",

			"weapon_hg_grenade_tpik",

			"weapon_morphine",

			"weapon_bigbandage_sh",

			"weapon_medkit_sh",

		},

		ammo_entity = "ent_ammo_12/70gauge",

		ammo_count = 30,

		ammo_types = {

			"12/70",

			"12/70gauge",

			"12g",

			"12 gauge",

			"Buckshot",

			"Shotgun1",

		},

		equipment = {

			"ent_armor_helmet1",

			"ent_armor_vest5",

		},

		player_model = MissionIntro.SidAgentModel or "models/cultist/humans/fbi/fbi.mdl",

		player_bodygroups = MissionIntro.SidAgentBodygroups,

		player_skin = 0,

		force_player_model = true,

	},

	uiu_tf_agent = {

		weapon = "weapon_mp5",

		extra_weapons = {

			"weapon_morphine",

			"weapon_bigbandage_sh",

		},

		ammo_entity = "ent_ammo_9x19mmparabellum",

		ammo_count = 50,

		ammo_types = {

			"9x19mm",

			"9x19MM",

			"9x19",

			"Pistol",

			"SMG1",

		},

		equipment = {

			"ent_armor_helmet1",

			"ent_armor_vest4",

			"ent_att_supressor4",

		},

		player_model = MissionIntro.UiuTfModel or "models/cultist/humans/fbi/fbi.mdl",

		player_bodygroups = MissionIntro.UiuTfAgentBodygroups,

		player_skin = 0,

		force_player_model = true,

	},

	uiu_tf_captain = {

		weapon = "weapon_p90",

		extra_weapons = {

			"nox_gas_grenade",

			"weapon_hg_grenade_tpik",

			"weapon_bandage_sh",

			"weapon_bigbandage_sh",

			"weapon_needle",

			"weapon_medkit_sh",

		},

		ammo_entity = "ent_ammo_5.7x28mm",

		ammo_count = 50,

		ammo_types = {

			"5.7x28mm",

			"5.7x28MM",

			"5.7x28",

			"57x28",

			"SMG1",

			"Pistol",

		},

		equipment = {

			"ent_armor_helmet1",

			"ent_armor_vest4",

			"ent_att_supressor4",

		},

		player_model = MissionIntro.UiuTfModel or "models/cultist/humans/fbi/fbi.mdl",

		player_bodygroups = MissionIntro.UiuTfCaptainBodygroups,

		player_skin = 0,

		force_player_model = true,

	},

	uiu_tf_expert = {

		weapon = "weapon_saiga12",

		extra_weapons = {

			"weapon_hg_smokenade_tpik",

			"weapon_hg_grenade_tpik",

			"weapon_morphine",

			"weapon_bigbandage_sh",

			"weapon_medkit_sh",

		},

		ammo_entity = "ent_ammo_12/70gauge",

		ammo_count = 30,

		ammo_types = {

			"12/70",

			"12/70gauge",

			"12g",

			"12 gauge",

			"Buckshot",

			"Shotgun1",

		},

		equipment = {

			"ent_armor_helmet1",

			"ent_armor_vest5",

		},

		player_model = MissionIntro.UiuTfModel or "models/cultist/humans/fbi/fbi.mdl",

		player_bodygroups = MissionIntro.UiuTfExpertBodygroups,

		player_skin = 0,

		force_player_model = true,

	},

	uiu_tf_suppressor = {

		weapon = "weapon_m249",

		extra_weapons = {

			"weapon_fentanyl",

			"weapon_bigbandage_sh",

			"weapon_morphine",

			"weapon_medkit_sh",

			"weapon_fury16",

		},

		ammo_entity = "ent_ammo_5.56x45mm",

		ammo_count = 100,

		ammo_types = {

			"5.56x45mm",

			"5.56x45MM",

			"556x45",

			"556x45mm",

			"SMG1",

			"AR2",

			"Rifle",

		},

		equipment = {

			"ent_armor_helmet1",

			"ent_armor_vest1",

		},

		player_model = MissionIntro.UiuTfModel or "models/cultist/humans/fbi/fbi.mdl",

		player_bodygroups = MissionIntro.UiuTfSuppressorBodygroups,

		player_skin = 0,

		force_player_model = true,

	},

	uiu_tf_infiltrator = {

		weapon = "weapon_revolver2",

		extra_weapons = {

			"weapon_buck200knife",

			"weapon_morphine",

			"weapon_fentanyl",

			"weapon_fury13",

			"weapon_bigbandage_sh",

		},

		ammo_entity = "ent_ammo_.38special",

		ammo_count = 20,

		ammo_types = {

			".38special",

			".38 Special",

			"38special",

			"Pistol",

		},

		player_model = MissionIntro.UiuTfModel or "models/cultist/humans/fbi/fbi.mdl",

		player_bodygroups = MissionIntro.UiuTfInfiltratorBodygroups,

		player_skin = 0,

		force_player_model = true,

	},

	hammerfall_medic = {

		weapon = "weapon_tmp",

		extra_weapons = {

			"weapon_bloodbag",

			"weapon_adrenaline",

			"weapon_bandage_sh",

			"weapon_thiamine",

			"weapon_mannitol",

			"weapon_tourniquet",

			"weapon_painkillers",

			"weapon_bigbandage_sh",

			"weapon_morphine",

			"weapon_medkit_sh",

			"weapon_needle",

			"weapon_betablock",

			"weapon_opendefib",

		},

		ammo_entity = "ent_ammo_9x19mmparabellum",

		ammo_count = 60,

		ammo_types = {

			"9x19mm",

			"9x19MM",

			"9x19",

			"Pistol",

			"SMG1",

		},

		equipment = {

			"ent_armor_helmet5",

			"ent_armor_vest1",

		},

		player_model = MissionIntro.HammerfallMogModel or "models/cultist/humans/mog/mog.mdl",

		player_bodygroups = MissionIntro.HammerfallRoleBodygroups and MissionIntro.HammerfallRoleBodygroups.medic,

		player_skin = 1,

		force_player_model = true,

	},

	hammerfall_assault = {

		weapon = "weapon_ac556",

		extra_weapons = {

			"weapon_speedboost",

			"weapon_hg_flashbang_tpik",

			"weapon_needle",

			"weapon_medkit_sh",

			"weapon_adrenaline",

			"weapon_tourniquet",

		},

		ammo_entity = "ent_ammo_5.56x45mm",

		ammo_count = 60,

		ammo_types = {

			"5.56x45mm",

			"5.56x45MM",

			"556x45",

			"556x45mm",

			"SMG1",

			"AR2",

			"Rifle",

		},

		equipment = {

			"ent_armor_helmet5",

			"ent_armor_vest4",

			"ent_coral_launcher_crate",

		},

		player_model = MissionIntro.HammerfallMogModel or "models/cultist/humans/mog/mog.mdl",

		player_bodygroups = MissionIntro.HammerfallRoleBodygroups and MissionIntro.HammerfallRoleBodygroups.assault,

		player_skin = 0,

		force_player_model = true,

	},

	hammerfall_sniper = {

		weapon = "weapon_m98b",

		ammo_entity = "ent_ammo_.338lapuamagnum",

		ammo_entity_count = 1,

		ammo_count = 10,

		ammo_types = {

			".338 Lapua Magnum",

			".338",

			"338",

			"338lapua",

			"Lapua",

			"Sniper",

			"AR2",

		},

		secondary_weapon = "weapon_m9beretta",

		secondary_ammo_entity = "ent_ammo_9x19mmparabellum",

		secondary_ammo_count = 30,

		secondary_ammo_types = {

			"9x19mm",

			"9x19MM",

			"9x19",

			"Pistol",

			"SMG1",

		},

		equipment = {

			"ent_armor_vest4",

			"ent_armor_headphones1",

			"ent_armor_helmet1",

		},

		extra_weapons = {

			"weapon_medkit_sh",

		},

		player_model = MissionIntro.HammerfallMogModel or "models/cultist/humans/mog/mog.mdl",

		player_bodygroups = MissionIntro.HammerfallRoleBodygroups and MissionIntro.HammerfallRoleBodygroups.sniper,

		player_skin = 0,

		force_player_model = true,

	},

	pttrb_leader = {

		weapon = "weapon_hk416",

		extra_weapons = {

			"weapon_bloodbag",

			"weapon_bigbandage_sh",

			"weapon_morphine",

			"weapon_medkit_sh",

			"weapon_tourniquet",

			"weapon_handcuffs",

			"weapon_handcuffs_key",

		},

		ammo_entity = "ent_ammo_5.56x45mm",

		ammo_count = 50,

		ammo_types = {

			"5.56x45mm",

			"5.56x45MM",

			"556x45",

			"556x45mm",

			"SMG1",

			"AR2",

			"Rifle",

		},

		equipment = {

			"ent_armor_helmet1",

			"ent_armor_vest1",

		},

		player_model = MissionIntro.PttrbModel or "models/cultist/humans/security/security_mobilized.mdl",

		player_bodygroups = MissionIntro.PttrbRoleBodygroups and MissionIntro.PttrbRoleBodygroups.leader,

		player_skin = 0,

		force_player_model = true,

	},

	pttrb_medic = {

		weapon = "weapon_vector",

		extra_weapons = {

			"weapon_bloodbag",

			"weapon_painkillers",

			"weapon_bigbandage_sh",

			"weapon_morphine",

			"weapon_medkit_sh",

			"weapon_needle",

			"weapon_betablock",

			"weapon_thiamine",

			"weapon_bandage_sh",

			"weapon_adrenaline",

			"weapon_opendefib",

		},

		ammo_entity = "ent_ammo_.45acp",

		ammo_count = 50,

		ammo_types = {

			".45acp",

			".45 ACP",

			"45acp",

			"45 ACP",

			".45",

			"Pistol",

			"SMG1",

		},

		equipment = {

			"ent_armor_helmet1",

			"ent_armor_vest1",

		},

		player_model = MissionIntro.PttrbModel or "models/cultist/humans/security/security_mobilized.mdl",

		player_bodygroups = MissionIntro.PttrbRoleBodygroups and MissionIntro.PttrbRoleBodygroups.medic,

		player_skin = 0,

		force_player_model = true,

	},

	pttrb_operative = {

		weapon = "weapon_m16a2",

		extra_weapons = {

			"weapon_bandage_sh",

			"weapon_medkit_sh",

		},

		ammo_entity = "ent_ammo_5.56x45mm",

		ammo_count = 40,

		ammo_types = {

			"5.56x45mm",

			"5.56x45MM",

			"556x45",

			"556x45mm",

			"SMG1",

			"AR2",

			"Rifle",

		},

		equipment = {

			"ent_armor_helmet1",

			"ent_armor_vest1",

		},

		player_model = MissionIntro.PttrbModel or "models/cultist/humans/security/security_mobilized.mdl",

		player_bodygroups = MissionIntro.PttrbRoleBodygroups and MissionIntro.PttrbRoleBodygroups.operative,

		player_skin = 0,

		force_player_model = true,

	},

	mcd_captain = {

		weapon = "weapon_sg552",

		extra_weapons = {

			"weapon_bigbandage_sh",

			"weapon_medkit_sh",

			"weapon_tourniquet",

		},

		ammo_entity = "ent_ammo_5.56x45mm",

		ammo_count = 45,

		ammo_types = {

			"5.56x45mm",

			"5.56x45MM",

			"556x45",

			"556x45mm",

			"SMG1",

			"AR2",

			"Rifle",

		},

		equipment = {

			"ent_armor_helmet1",

			"ent_armor_vest4",

		},

		player_model = MissionIntro.McdModel or "models/cultist/humans/obr/obr.mdl",

		player_bodygroups = MissionIntro.McdRoleBodygroups and MissionIntro.McdRoleBodygroups.captain,

		player_skin = 0,

		force_player_model = true,

	},

	ci_soldier = {

		weapon = "weapon_ak74",

		extra_weapons = {

			"weapon_bandage_sh",

		},

		ammo_entity = "ent_ammo_5.45x39mm",

		ammo_count = 60,

		ammo_types = {

			"5.45x39mm",

			"5.45X39MM",

			"545x39",

			"545x39mm",

			"AR2",

			"SMG1",

			"Rifle",

		},

		equipment = {

			"ent_armor_vest3",

			"ent_armor_helmet7",

		},

		player_model = MissionIntro.CiModel or "models/cultist/humans/chaos/chaos.mdl",

		player_bodygroups = MissionIntro.CiRoleBodygroups and MissionIntro.CiRoleBodygroups.soldier,

		player_skin = 0,

		force_player_model = true,

	},

	ntf_soldier = {

		weapon = "weapon_p90_ntf",

		extra_weapons = {

			"guthscp_keycard_lvl_5",

			"weapon_walkie_talkie",

			"weapon_bigbandage_sh",

			"weapon_morphine",

			"weapon_medkit_sh",

		},

		ammo_entity = "ent_ammo_5.7x28mm",

		ammo_count = 50,

		ammo_types = {

			"5.7x28mm",

			"5.7x28MM",

			"5.7x28",

			"57x28",

			"SMG1",

			"Pistol",

		},

		player_model = MissionIntro.NtfModel or "models/cultist/humans/ntf/ntf.mdl",

		player_bodygroups = MissionIntro.NtfRoleBodygroups and MissionIntro.NtfRoleBodygroups.soldier,

		player_skin = 0,

		force_player_model = true,

	},

	ntf_combat_expert = {

		weapon = "weapon_p90_ntf",

		extra_weapons = {

			"guthscp_keycard_lvl_5",

			"weapon_walkie_talkie",

			"weapon_bigbandage_sh",

			"weapon_morphine",

			"weapon_medkit_sh",

		},

		ammo_entity = "ent_ammo_5.7x28mm",

		ammo_count = 50,

		ammo_types = {

			"5.7x28mm",

			"5.7x28MM",

			"5.7x28",

			"57x28",

			"SMG1",

			"Pistol",

		},

		player_model = MissionIntro.NtfModel or "models/cultist/humans/ntf/ntf.mdl",

		player_bodygroups = MissionIntro.NtfRoleBodygroups and MissionIntro.NtfRoleBodygroups.combat_expert,

		player_skin = 0,

		force_player_model = true,

		equipment = {

			"ent_coral_launcher_crate",

		},

	},

	ntf_sniper = {

		weapon = "weapon_m98b_ntf",

		extra_weapons = {

			"guthscp_keycard_lvl_5",

			"weapon_walkie_talkie",

			"weapon_bigbandage_sh",

			"weapon_morphine",

			"weapon_medkit_sh",

		},

		equipment = {

			"ent_att_supressor7",

		},

		ammo_entity = "ent_ammo_.338lapuamagnum",

		ammo_entity_count = 1,

		ammo_count = 10,

		ammo_types = {

			".338 Lapua Magnum",

			".338",

			"338",

			"338lapua",

			"Lapua",

			"Sniper",

			"AR2",

		},

		secondary_weapon = "weapon_m9beretta",

		secondary_ammo_entity = "ent_ammo_9x19mmparabellum",

		secondary_ammo_count = 30,

		secondary_ammo_types = {

			"9x19mm",

			"9x19MM",

			"9x19",

			"Pistol",

			"SMG1",

		},

		player_model = MissionIntro.NtfModel or "models/cultist/humans/ntf/ntf.mdl",

		player_bodygroups = MissionIntro.NtfRoleBodygroups and MissionIntro.NtfRoleBodygroups.sniper,

		player_skin = 0,

		force_player_model = true,

	},

	ntf_commander = {

		weapon = "weapon_p90_ntf",

		extra_weapons = {

			"guthscp_keycard_lvl_5",

			"weapon_walkie_talkie",

			"weapon_survival_scanner",

			"weapon_bigbandage_sh",

			"weapon_morphine",

			"weapon_medkit_sh",

		},

		ammo_entity = "ent_ammo_5.7x28mm",

		ammo_count = 50,

		ammo_types = {

			"5.7x28mm",

			"5.7x28MM",

			"5.7x28",

			"57x28",

			"SMG1",

			"Pistol",

		},

		player_model = MissionIntro.NtfModel or "models/cultist/humans/ntf/ntf.mdl",

		player_bodygroups = MissionIntro.NtfRoleBodygroups and MissionIntro.NtfRoleBodygroups.commander,

		player_skin = 0,

		force_player_model = true,

	},

	ci_commander = {

		weapon = "weapon_ak200",

		extra_weapons = {

			"weapon_bigbandage_sh",

		},

		ammo_entity = "ent_ammo_5.45x39mm",

		ammo_count = 60,

		ammo_types = {

			"5.45x39mm",

			"5.45X39MM",

			"545x39",

			"545x39mm",

			"AR2",

			"SMG1",

			"Rifle",

		},

		equipment = {

			"ent_armor_vest4",

		},

		player_model = MissionIntro.CiModel or "models/cultist/humans/chaos/chaos.mdl",

		player_bodygroups = MissionIntro.CiRoleBodygroups and MissionIntro.CiRoleBodygroups.commander,

		player_skin = 0,

		force_player_model = true,

	},

	ci_antitank = {

		weapon = "weapon_hg_rpg",

		ammo_entity = "ent_ammo_rpg-7projectile",

		ammo_count = 1,

		ammo_types = {

			"RPG_Round",

			"RPG",

			"Rocket",

			"rpg",

		},

		secondary_weapon = "weapon_makarov",

		secondary_ammo_entity = "ent_ammo_9x18mm",

		secondary_ammo_count = 20,

		secondary_ammo_types = {

			"9x18mm",

			"9x18MM",

			"9x18",

			"Pistol",

			"SMG1",

		},

		equipment = {

			"ent_armor_vest4",

		},

		extra_weapons = {

			"weapon_bandage_sh",

			"weapon_tourniquet",

		},

		player_model = MissionIntro.CiModel or "models/cultist/humans/chaos/chaos.mdl",

		player_bodygroups = MissionIntro.CiRoleBodygroups and MissionIntro.CiRoleBodygroups.antitank,

		player_skin = 0,

		force_player_model = true,

	},

	ci_trap_expert = {

		weapon = "weapon_mp7",

		ammo_entity = "ent_ammo_4.6x30mm",

		ammo_count = 65,

		ammo_types = {

			"4.6x30 mm",

			"4.6x30mm",

			"4.6X30MM",

			"46x30",

			"46x30mm",

			"SMG1",

			"Pistol",

		},

		equipment = {

			"ent_armor_vest4",

		},

		extra_weapons = {

			"weapon_tourniquet",

			"weapon_bigbandage_sh",

			"weapon_claymore",

			"weapon_traitor_ied",

		},

		player_model = MissionIntro.CiModel or "models/cultist/humans/chaos/chaos.mdl",

		player_bodygroups = MissionIntro.CiRoleBodygroups and MissionIntro.CiRoleBodygroups.trap_expert,

		player_skin = 0,

		force_player_model = true,

	},

	ci_sniper = {

		weapon = "weapon_mp7",

		ammo_entity = "ent_ammo_4.6x30mm",

		ammo_count = 65,

		ammo_types = {

			"4.6x30 mm",

			"4.6x30mm",

			"4.6X30MM",

			"46x30",

			"46x30mm",

			"SMG1",

			"Pistol",

		},

		equipment = {

			"ent_armor_vest4",

		},

		extra_weapons = {

			"weapon_tourniquet",

			"weapon_bigbandage_sh",

			"weapon_claymore",

			"weapon_traitor_ied",

		},

		player_model = MissionIntro.CiModel or "models/cultist/humans/chaos/chaos.mdl",

		player_bodygroups = MissionIntro.CiRoleBodygroups and MissionIntro.CiRoleBodygroups.trap_expert,

		player_skin = 0,

		force_player_model = true,

	},

	ci_heavy = {

		weapon = "weapon_m60",

		ammo_entity = "ent_ammo_7.62x51mm",

		ammo_count = 100,

		ammo_types = {

			"7.62x51mm",

			"7.62x51MM",

			"7.62x51",

			"762x51",

			"762x51mm",

			"Rifle",

			"AR2",

		},

		equipment = {

			"ent_armor_vest1",

			"ent_armor_helmet5",

		},

		extra_weapons = {

			"weapon_morphine",

			"weapon_bigbandage_sh",

		},

		player_model = MissionIntro.CiModel or "models/cultist/humans/chaos/chaos.mdl",

		player_bodygroups = MissionIntro.CiRoleBodygroups and MissionIntro.CiRoleBodygroups.heavy,

		player_skin = 0,

		force_player_model = true,

	},

	vdv_soldier = {

		weapon = "weapon_ak200",

		extra_weapons = {

			"weapon_medkit_sh",

			"weapon_morphine",

			"weapon_bigbandage_sh",

			"weapon_hg_f1_tpik",

		},

		ammo_entity = "ent_ammo_5.45x39mm",

		ammo_count = 50,

		ammo_types = {

			"5.45x39mm",

			"5.45X39MM",

			"545x39",

			"545x39mm",

			"AR2",

			"SMG1",

			"Rifle",

		},

		equipment = {

			"ent_armor_helmet1",

			"ent_armor_vest4",

		},

		player_model = MissionIntro.CiModel or "models/cultist/humans/chaos/chaos.mdl",

		player_bodygroups = MissionIntro.VdvRoleBodygroups and MissionIntro.VdvRoleBodygroups.soldier,

		player_skin = 0,

		force_player_model = true,

	},

	goc_soldier = {

		weapon = "weapon_osipr",

		extra_weapons = {

			"weapon_bigbandage_sh",

			"weapon_morphine",

		},

		ammo_entity = "ent_ammo_pulse",

		ammo_count = 100,

		ammo_types = {

			"Pulse",

			"pulse",

			"AR2",

			"SMG1",

		},

		player_model = MissionIntro.GocModel or "models/cultist/humans/goc/goc.mdl",

		player_bodygroups = MissionIntro.GocRoleBodygroups and MissionIntro.GocRoleBodygroups.soldier,

		player_skin = 0,

		force_player_model = true,

	},

	goc_commander = {

		weapon = "weapon_ash12",

		extra_weapons = {

			"weapon_bigbandage_sh",

			"weapon_naloxone",

			"weapon_fentanyl",

			"weapon_morphine",

		},

		ammo_entity = "ent_ammo_12.7x55mm",

		ammo_count = 70,

		ammo_types = {

			"12.7x55mm",

			"12.7X55MM",

			"127x55",

			"127x55mm",

			"AR2",

			"SMG1",

			"Rifle",

		},

		equipment = {

			"ent_armor_vest1",

		},

		player_model = MissionIntro.GocModel or "models/cultist/humans/goc/goc.mdl",

		player_bodygroups = MissionIntro.GocRoleBodygroups and MissionIntro.GocRoleBodygroups.commander,

		player_skin = 0,

		force_player_model = true,

	},

	goc_heavy = {

		weapon = "weapon_m249_pulse",

		extra_weapons = {

			"weapon_bigbandage_sh",

			"weapon_naloxone",

			"weapon_fentanyl",

			"weapon_morphine",

		},

		ammo_entity = "ent_ammo_pulse",

		ammo_count = 150,

		ammo_types = {

			"Pulse",

			"pulse",

			"AR2",

			"SMG1",

		},

		equipment = {

			"ent_armor_vest1",

		},

		player_model = MissionIntro.GocModel or "models/cultist/humans/goc/goc.mdl",

		player_bodygroups = MissionIntro.GocRoleBodygroups and MissionIntro.GocRoleBodygroups.heavy,

		player_skin = 0,

		force_player_model = true,

	},

	vdv_commander = {

		weapon = "weapon_ak203",

		extra_weapons = {

			"weapon_tourniquet",

			"weapon_morphine",

			"weapon_bandage_sh",

			"weapon_bigbandage_sh",

			"weapon_medkit_sh",

			"weapon_hg_smokenade_tpik",

			"weapon_hg_f1_tpik",

		},

		ammo_entity = "ent_ammo_7.62x39mm",

		ammo_count = 45,

		ammo_types = {

			"7.62x39mm",

			"7.62X39MM",

			"762x39",

			"762x39mm",

			"AR2",

			"SMG1",

			"Rifle",

		},

		equipment = {

			"ent_armor_vest1",

		},

		player_model = MissionIntro.CiModel or "models/cultist/humans/chaos/chaos.mdl",

		player_bodygroups = MissionIntro.VdvRoleBodygroups and MissionIntro.VdvRoleBodygroups.commander,

		player_skin = 0,

		force_player_model = true,

	},

	vdv_antitank = {

		weapon = "weapon_hg_rpg",

		ammo_entity = "ent_ammo_rpg-7projectile",

		ammo_count = 1,

		ammo_types = {

			"RPG_Round",

			"RPG",

			"Rocket",

			"rpg",

		},

		secondary_weapon = "weapon_makarov",

		secondary_ammo_entity = "ent_ammo_9x18mm",

		secondary_ammo_count = 20,

		secondary_ammo_types = {

			"9x18mm",

			"9x18MM",

			"9x18",

			"Pistol",

		},

		equipment = {

			"ent_armor_vest4",

		},

		extra_weapons = {

			"weapon_bandage_sh",

			"weapon_morphine",

			"weapon_medkit_sh",

		},

		player_model = MissionIntro.CiModel or "models/cultist/humans/chaos/chaos.mdl",

		player_bodygroups = MissionIntro.VdvRoleBodygroups and MissionIntro.VdvRoleBodygroups.antitank,

		player_skin = 0,

		force_player_model = true,

	},

	vdv_sniper = {

		weapon = "weapon_m98b",

		ammo_entity = "ent_ammo_.338lapuamagnum",

		ammo_entity_count = 1,

		ammo_count = 15,

		ammo_types = {

			".338 Lapua Magnum",

			".338",

			"338",

			"338lapua",

			"Lapua",

			"Sniper",

			"AR2",

		},

		secondary_weapon = "weapon_makarov",

		secondary_ammo_entity = "ent_ammo_9x18mm",

		secondary_ammo_count = 20,

		secondary_ammo_types = {

			"9x18mm",

			"9x18MM",

			"9x18",

			"Pistol",

			"SMG1",

		},

		equipment = {

			"ent_armor_helmet7",

			"ent_armor_vest4",

		},

		extra_weapons = {

			"weapon_medkit_sh",

			"weapon_tourniquet",

			"weapon_needle",

			"weapon_adrenaline",

		},

		player_model = MissionIntro.CiModel or "models/cultist/humans/chaos/chaos.mdl",

		player_bodygroups = MissionIntro.VdvRoleBodygroups and MissionIntro.VdvRoleBodygroups.sniper,

		player_skin = 0,

		force_player_model = true,

	},

	vdv_heavy = {

		weapon = "weapon_m60",

		ammo_entity = "ent_ammo_7.62x51mm",

		ammo_count = 100,

		ammo_types = {

			"7.62x51mm",

			"7.62x51MM",

			"7.62x51",

			"762x51",

			"762x51mm",

			"Rifle",

			"AR2",

		},

		equipment = {

			"ent_armor_vest1",

			"ent_armor_helmet5",

		},

		extra_weapons = {

			"weapon_tourniquet",

			"weapon_bigbandage_sh",

			"weapon_morphine",

			"weapon_medkit_sh",

			"weapon_fury16",

			"weapon_hg_rgd_tpik",

			"weapon_hg_grenade_tpik",

			"weapon_traitor_ied",

		},

		player_model = MissionIntro.CiModel or "models/cultist/humans/chaos/chaos.mdl",

		player_bodygroups = MissionIntro.VdvRoleBodygroups and MissionIntro.VdvRoleBodygroups.heavy,

		player_skin = 0,

		force_player_model = true,

	},

	hammerfall_heavy = {

		weapon = "weapon_m249",

		ammo_entity = "ent_ammo_5.56x45mm",

		ammo_count = 100,

		ammo_types = {

			"5.56x45mm",

			"5.56x45MM",

			"556x45",

			"556x45mm",

			"SMG1",

			"AR2",

			"Rifle",

		},

		equipment = {

			"ent_armor_vest1",

			"ent_armor_helmet5",

		},

		extra_weapons = {

			"weapon_tourniquet",

			"weapon_needle",

			"weapon_medkit_sh",

			"weapon_morphine",

			"weapon_bandage_sh",

			"weapon_adrenaline",

			"weapon_bigbandage_sh",

			"weapon_hg_flashbang_tpik",

			"weapon_hg_grenade_tpik",

		},

		player_model = MissionIntro.HammerfallJaggerModel or "models/cultist/humans/mog/mog_jagger.mdl",

		player_skin = 0,

		force_player_model = true,

	},

	hammerfall_maintenance_electrician = {
		weapon = "weapon_hk416",
		extra_weapons = {
			"guthscp_keycard_lvl_5",
			"weapon_bigbandage_sh",
			"weapon_medkit_sh",
		},
		ammo_entity = "ent_ammo_5.56x45mm",
		ammo_count = 60,
		ammo_types = {
			"5.56x45mm",
			"5.56x45MM",
			"556x45",
			"556x45mm",
			"SMG1",
			"AR2",
			"Rifle",
		},
		equipment = {
			"ent_armor_helmet1",
			"ent_armor_vest1",
		},
		player_model = MissionIntro.HammerfallMogModel or "models/cultist/humans/mog/mog.mdl",
		player_bodygroups = MissionIntro.HammerfallRoleBodygroups and MissionIntro.HammerfallRoleBodygroups.medic,
		player_skin = 1,
		force_player_model = true,
	},

	hammerfall_maintenance_soldier = {
		weapon = "weapon_m4a1",
		extra_weapons = {
			"guthscp_keycard_lvl_5",
			"weapon_tourniquet",
			"weapon_bloodbag",
			"weapon_adrenaline",
			"weapon_painkillers",
			"weapon_medkit_sh",
			"weapon_handcuffs_key",
			"weapon_handcuffs",
		},
		ammo_entity = "ent_ammo_5.56x45mm",
		ammo_count = 60,
		ammo_types = {
			"5.56x45mm",
			"5.56x45MM",
			"556x45",
			"556x45mm",
			"SMG1",
			"AR2",
			"Rifle",
		},
		equipment = {
			"ent_armor_helmet5",
			"ent_armor_vest1",
		},
		player_model = MissionIntro.HammerfallMogModel or "models/cultist/humans/mog/mog.mdl",
		player_bodygroups = MissionIntro.HammerfallRoleBodygroups and MissionIntro.HammerfallRoleBodygroups.soldier,
		player_skin = 0,
		force_player_model = true,
	},

	facility_researcher = {
		weapon = "weapon_bigconsumable",
		player_model = MissionIntro.FacilitySciModelMale or "models/cultist/humans/sci/scientist.mdl",
		player_bodygroups = { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0, [7] = 0, [8] = 0 },
		player_skin = 0,
		force_player_model = true,
	},

	facility_doctor = {
		weapon = "weapon_defibrilator_homigrad",
		extra_weapons = {
			"weapon_medkit_sh",
			"weapon_morphine",
			"weapon_tourniquet",
			"weapon_bigbandage_sh",
			"weapon_smallconsumable",
			"weapon_opendefib",
		},
		player_model = "models/cultist/humans/sci/scientist.mdl",
		player_bodygroups = { [0] = 3, [1] = 1, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0, [7] = 0, [8] = 1, [9] = 0 },
		player_bodygroup_base = 0,
		player_skin = 0,
		force_player_model = true,
	},

	facility_senior_scientist = {
		weapon = "weapon_hammer",
		extra_weapons = {
			"weapon_smallconsumable",
			"weapon_bigconsumable",
		},
		player_model = MissionIntro.FacilitySciModelMale or "models/cultist/humans/sci/scientist.mdl",
		player_bodygroups = { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0, [7] = 0, [8] = 0 },
		player_skin = 0,
		force_player_model = true,
	},

	facility_ethics = {
		weapon = "weapon_tourniquet",
		extra_weapons = {
			"weapon_painkillers",
			"weapon_morphine",
			"weapon_hammer",
			"weapon_bigbandage_sh",
			"weapon_handcuffs_key",
			"weapon_handcuffs",
		},
		player_model = MissionIntro.FacilitySciModelMale or "models/cultist/humans/sci/scientist.mdl",
		player_bodygroups = { [0] = 0, [1] = 2, [2] = 0, [3] = 1, [4] = 0, [5] = 0, [6] = 0, [7] = 0, [8] = 0, [9] = 1 },
		player_skin = 0,
		force_player_model = true,
	},

	classd_impostor = {
		weapon = "weapon_bigconsumable",
		auto_select_weapon = false,
		extra_weapons = {
			"weapon_pocketknife",
		},
		player_model = MissionIntro.FacilitySciModelMale or "models/cultist/humans/sci/scientist.mdl",
		player_bodygroups = { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0, [7] = 0, [8] = 0 },
		player_skin = 0,
		force_player_model = true,
	},

	class_d_regular = {
		weapon = "weapon_bigconsumable",
		auto_select_weapon = false,
		player_model = MissionIntro.ClassDModelRegular or "models/cultist/humans/class_d/class_d.mdl",
		player_bodygroups = MissionIntro.BuildClassDStandardBodygroups and MissionIntro.BuildClassDStandardBodygroups({ body = 0 }) or { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0 },
		player_skin = 0,
		force_player_model = true,
	},

	class_d_killer = {
		weapon = "weapon_sogknife",
		auto_select_weapon = false,
		player_model = MissionIntro.ClassDModelRegular or "models/cultist/humans/class_d/class_d.mdl",
		player_bodygroups = MissionIntro.BuildClassDStandardBodygroups and MissionIntro.BuildClassDStandardBodygroups({ body = 0 }) or { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0 },
		player_skin = 0,
		force_player_model = true,
	},

	class_d_thief = {
		weapon = "weapon_handcuffs_key",
		auto_select_weapon = false,
		extra_weapons = {
			"weapon_bigconsumable",
			"guthscp_keycard_lvl_2",
		},
		player_model = MissionIntro.ClassDModelRegular or "models/cultist/humans/class_d/class_d.mdl",
		player_bodygroups = MissionIntro.BuildClassDStandardBodygroups and MissionIntro.BuildClassDStandardBodygroups({ body = 0 }) or { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0 },
		player_skin = 0,
		force_player_model = true,
	},

	uiu_spy = {
		weapon = "weapon_hk_usp",
		auto_select_weapon = false,
		extra_weapons = {
			"weapon_smallconsumable",
			"weapon_bigconsumable",
		},
		equipment = {
			"ent_att_supressor3",
			"ent_att_laser5",
		},
		ammo_entity = "ent_ammo_9x19mmparabellum",
		ammo_count = 6,
		ammo_types = {
			"9x19mm",
			"9x19MM",
			"9x19",
			"Pistol",
		},
		player_model = MissionIntro.FacilitySciModelMale or "models/cultist/humans/sci/scientist.mdl",
		player_bodygroups = { [0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0, [6] = 0, [7] = 0, [8] = 0 },
		player_skin = 0,
		force_player_model = true,
	},

	dr_maynard = {
		weapon = "weapon_m9beretta",
		auto_select_weapon = false,
		extra_weapons = {
			"weapon_handcuffs_key",
			"weapon_handcuffs",
			"weapon_traitor_poison1",
			"weapon_tourniquet",
			"weapon_painkillers",
			"weapon_morphine",
			"weapon_bigbandage_sh",
		},
		equipment = {
			"ent_att_supressor4",
			"ent_att_laser5",
		},
		ammo_entity = "ent_ammo_9x19mmparabellum",
		ammo_count = 8,
		ammo_types = {
			"9x19mm",
			"9x19MM",
			"9x19",
			"Pistol",
		},
		player_model = MissionIntro.FacilitySciModelMale or "models/cultist/humans/sci/scientist.mdl",
		player_bodygroups = { [0] = 0, [1] = 2, [2] = 0, [3] = 1, [4] = 0, [5] = 0, [6] = 0, [7] = 0, [8] = 0, [9] = 1 },
		player_skin = 0,
		force_player_model = true,
	},

	facility_security_rookie = {
		weapon = "weapon_glock17",
		extra_weapons = {
			"weapon_hg_tonfa",
			"weapon_bandage_sh",
		},
		ammo_entity = "ent_ammo_9x19mmparabellum",
		ammo_count = 50,
		ammo_types = {
			"9x19mm",
			"9x19MM",
			"9x19",
			"Pistol",
		},
		player_model = MissionIntro.FacilitySecurityModel or "models/cultist/humans/security/security.mdl",
		player_bodygroups = { [0] = 1, [1] = 1, [2] = 0, [3] = 0, [4] = 0, [5] = 7, [6] = 1, [7] = 0, [8] = 0 },
		player_skin = 0,
		force_player_model = true,
	},

	facility_security_officer = {
		weapon = "weapon_pl15",
		extra_weapons = {
			"weapon_hg_tonfa",
			"weapon_bigbandage_sh",
		},
		equipment = {
			"ent_armor_vest3",
		},
		ammo_entity = "ent_ammo_9x19mmparabellum",
		ammo_count = 50,
		ammo_types = {
			"9x19mm",
			"9x19MM",
			"9x19",
			"Pistol",
		},
		player_model = MissionIntro.FacilitySecurityModel or "models/cultist/humans/security/security.mdl",
		player_bodygroups = { [0] = 1, [1] = 2, [2] = 0, [3] = 1, [4] = 0, [5] = 3, [6] = 1, [7] = 0, [8] = 0 },
		player_skin = 0,
		force_player_model = true,
	},

	facility_security_warden = {
		weapon = "weapon_revolver357",
		extra_weapons = {
			"weapon_taser",
			"weapon_hg_tonfa",
			"weapon_painkillers",
			"weapon_bigbandage_sh",
			"weapon_medkit_sh",
		},
		equipment = {
			"ent_armor_vest4",
			"ent_armor_helmet3",
			"ent_att_supressor4",
		},
		ammo_entity = "ent_ammo_.357magnum",
		ammo_count = 50,
		ammo_types = {
			".357 Magnum",
			".357",
			"357",
			"Pistol",
		},
		player_model = MissionIntro.FacilitySecurityModel or "models/cultist/humans/security/security.mdl",
		player_bodygroups = { [0] = 1, [1] = 0, [2] = 0, [3] = 1, [4] = 1, [5] = 1, [6] = 1, [7] = 1, [8] = 1 },
		player_skin = 0,
		force_player_model = true,
	},

	facility_security_sergeant = {
		weapon = "weapon_m1911",
		extra_weapons = {
			"weapon_thiamine",
			"weapon_medkit_sh",
		},
		equipment = {
			"ent_armor_helmet1",
			"ent_armor_vest4",
		},
		ammo_entity = "ent_ammo_.45acp",
		ammo_count = 50,
		ammo_types = {
			".45acp",
			".45 ACP",
			"Pistol",
		},
		player_model = MissionIntro.FacilitySecurityModel or "models/cultist/humans/security/security.mdl",
		player_bodygroups = { [0] = 1, [1] = 2, [2] = 1, [3] = 0, [4] = 0, [5] = 5, [6] = 1, [7] = 0, [8] = 1 },
		player_skin = 0,
		force_player_model = true,
	},

	facility_mtf_site_director = {
		weapon = "weapon_glock26",
		extra_weapons = {
			"weapon_walkie_talkie",
			"weapon_handcuffs",
			"weapon_handcuffs_key",
			"weapon_bigbandage_sh",
			"weapon_betablock",
			"weapon_thiamine",
		},
		equipment = {
			"ent_armor_vest4",
		},
		ammo_entity = "ent_ammo_9x19mmparabellum",
		ammo_count = 40,
		ammo_types = {
			"9x19mm",
			"9x19MM",
			"9x19",
			"Pistol",
		},
		player_model = MissionIntro.FacilityMtfModel or "models/cultist/humans/mog/head_site.mdl",
		player_skin = 0,
		force_player_model = true,
	},

	facility_scp_062de = {
		weapon = "weapon_kar98_12755",
		secondary_weapon = "guthscp_keycard_omni",
		player_model = MissionIntro.FacilityScpModel or "models/cultist/scp/scp_062de.mdl",
		player_skin = 0,
		force_player_model = true,
	},

	facility_scp_0762 = {
		weapon = "weapon_katana",
		secondary_weapon = "guthscp_keycard_omni",
		player_model = "models/cultist/scp/scp_076.mdl",
		player_skin = 0,
		force_player_model = true,
	},

	facility_scp_912 = {
		-- 主/副武器由 sv_mission_intro_scp912_spawn.lua 分批发放，避免入场帧卡死
		secondary_weapon = "guthscp_keycard_omni",
		player_model = (MissionIntro.ResolveFacilityScp912PlayerModel and MissionIntro.ResolveFacilityScp912PlayerModel())
			or "models/cultist/scp/scp_912.mdl",
		player_skin = 0,
		force_player_model = true,
		auto_select_weapon = false,
	},

	facility_qrf_soldier = {
		weapon = "weapon_mp5",
		extra_weapons = MissionIntro.FacilityQrfMedicalExtras or {
			"weapon_medkit_sh",
		},
		equipment = {
			"ent_armor_vest4",
			"ent_armor_helmet1",
		},
		ammo_entity = "ent_ammo_9x19mmparabellum",
		ammo_count = 90,
		ammo_types = {
			"9x19mm",
			"9x19MM",
			"9x19",
			"Pistol",
			"SMG1",
		},
		player_model = MissionIntro.FacilityQrfModel or "models/cultist/humans/obr/obr.mdl",
		player_bodygroups = MissionIntro.FacilityQrfSoldierBodygroups,
		player_bodygroup_base = 0,
		player_skin = 0,
		force_player_model = true,
	},

	facility_qrf_marksman = {
		weapon = "weapon_sks",
		extra_weapons = MissionIntro.FacilityQrfMedicalExtras or {
			"weapon_medkit_sh",
		},
		equipment = {
			"ent_armor_vest4",
		},
		ammo_entity = "ent_ammo_7.62x39mm",
		ammo_count = 50,
		ammo_types = {
			"7.62x39mm",
			"7.62x39MM",
			"7.62x39",
			"762x39",
			"Rifle",
			"AR2",
		},
		player_model = MissionIntro.FacilityQrfModel or "models/cultist/humans/obr/obr.mdl",
		player_bodygroups = MissionIntro.FacilityQrfMarksmanBodygroups,
		player_bodygroup_base = 0,
		player_skin = 0,
		force_player_model = true,
	},

	facility_qrf_medic = {
		weapon = "weapon_mp7",
		extra_weapons = MissionIntro.FacilityQrfMedicExtras or {
			"weapon_tourniquet",
			"weapon_bandage_sh",
			"weapon_adrenaline",
			"weapon_fentanyl",
			"weapon_bloodbag",
			"weapon_painkillers",
			"weapon_bigbandage_sh",
			"weapon_morphine",
			"weapon_medkit_sh",
		},
		equipment = MissionIntro.FacilityQrfSoldierEquipment or {
			"ent_armor_vest4",
			"ent_armor_helmet1",
		},
		ammo_entity = "ent_ammo_4.6x30mm",
		ammo_count = 90,
		ammo_types = {
			"4.6x30mm",
			"4.6x30 mm",
			"4.6x30",
			"SMG1",
			"Pistol",
		},
		player_model = MissionIntro.FacilityQrfModel or "models/cultist/humans/obr/obr.mdl",
		player_bodygroups = MissionIntro.FacilityQrfMedicBodygroups,
		player_bodygroup_base = 0,
		player_skin = 0,
		force_player_model = true,
	},

	facility_qrf_breacher = {
		weapon = "weapon_xm1014",
		extra_weapons = MissionIntro.FacilityQrfMedicalExtras or {
			"weapon_medkit_sh",
		},
		equipment = MissionIntro.FacilityQrfSoldierEquipment or {
			"ent_armor_vest4",
			"ent_armor_helmet1",
		},
		ammo_entity = "ent_ammo_12/70gauge",
		ammo_count = 30,
		ammo_types = {
			"12/70",
			"12/70gauge",
			"12 gauge",
			"Buckshot",
			"Shotgun",
		},
		player_model = MissionIntro.FacilityQrfModel or "models/cultist/humans/obr/obr.mdl",
		player_bodygroups = MissionIntro.FacilityQrfBreacherBodygroups,
		player_bodygroup_base = 0,
		player_skin = 0,
		force_player_model = true,
	},

	facility_qrf_commander = {
		weapon = "weapon_p90",
		extra_weapons = MissionIntro.FacilityQrfCommanderExtras or {
			"weapon_bigbandage_sh",
			"weapon_morphine",
			"weapon_medkit_sh",
		},
		equipment = {
			"ent_armor_vest1",
		},
		ammo_entity = "ent_ammo_5.7x28mm",
		ammo_count = 100,
		ammo_types = {
			"5.7x28mm",
			"5.7x28MM",
			"5.7x28",
			"SMG1",
			"Pistol",
		},
		player_model = MissionIntro.FacilityQrfModel or "models/cultist/humans/obr/obr.mdl",
		player_bodygroups = MissionIntro.FacilityQrfCommanderBodygroups,
		player_bodygroup_base = 0,
		player_skin = 0,
		force_player_model = true,
	},

	facility_security_captain = {
		weapon = "weapon_deagle",
		extra_weapons = {
			"weapon_taser",
			"weapon_hg_tonfa",
			"weapon_adrenaline",
			"weapon_painkillers",
			"weapon_medkit_sh",
			"weapon_morphine",
			"weapon_bigbandage_sh",
		},
		equipment = {
			"ent_armor_vest4",
		},
		ammo_entity = "ent_ammo_.50actionexpress",
		ammo_count = 50,
		ammo_types = {
			".50 Action Express",
			".50AE",
			"50AE",
			"Pistol",
		},
		player_model = MissionIntro.FacilitySecurityModel or "models/cultist/humans/security/security.mdl",
		player_bodygroups = { [0] = 1, [1] = 4, [2] = 2, [3] = 1, [4] = 1, [5] = 0, [6] = 1, [7] = 0, [8] = 1 },
		player_skin = 0,
		force_player_model = true,
	},

}



MissionIntro.FactionRewards.scarlet_cultist = MissionIntro.FactionRewards.scarlet_bishop
MissionIntro.FactionRewards.hammerfall_squad = MissionIntro.FactionRewards.hammerfall_soldier
MissionIntro.FactionRewards.hammerfall_maintenance = MissionIntro.FactionRewards.hammerfall_maintenance_electrician
MissionIntro.FactionRewards.sid_squad = MissionIntro.FactionRewards.sid_agent
MissionIntro.FactionRewards.uiu_taskforce = MissionIntro.FactionRewards.uiu_tf_agent
MissionIntro.FactionRewards.pttrb_squad = MissionIntro.FactionRewards.pttrb_leader
MissionIntro.FactionRewards.mcd_squad = MissionIntro.FactionRewards.mcd_captain
MissionIntro.FactionRewards.ntf_squad = MissionIntro.FactionRewards.ntf_soldier
MissionIntro.FactionRewards.ci_squad = MissionIntro.FactionRewards.ci_soldier
MissionIntro.FactionRewards.vdv_squad = MissionIntro.FactionRewards.vdv_soldier
MissionIntro.FactionRewards.goc_squad = MissionIntro.FactionRewards.goc_soldier

-- 所有阵营入场奖励统一附加
MissionIntro.UniversalExtraWeapons = {
	"weapon_hands_sh",
}

MissionIntro.WalkieTalkieWeapon = "weapon_walkie_talkie"
MissionIntro.HandcuffExtraWeapons = {
	"weapon_handcuffs_key",
	"weapon_handcuffs",
}

function MissionIntro.IsSecurityRewardProfileId(profileId)
	if not isstring(profileId) or profileId == "" then return false end
	return profileId:find("^facility_security_", 1, true) ~= nil
end

function MissionIntro.IsMtfFacilityRewardProfileId(profileId)
	if not isstring(profileId) or profileId == "" then return false end
	return profileId == "facility_mtf_site_director"
		or profileId:find("^facility_mtf_", 1, true) ~= nil
end

function MissionIntro.GetBonusExtraWeaponsForPlayer(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return {} end

	local bonus = {}
	local seen = {}

	local function add(class)
		if not isstring(class) or class == "" or seen[class] then return end
		seen[class] = true
		bonus[#bonus + 1] = class
	end

	local facId = MissionIntro.GetFactionId and MissionIntro.GetFactionId(ply) or ""
	local profileId = MissionIntro.GetRewardProfileId and MissionIntro.GetRewardProfileId(ply) or ""
	local isCiSpy = MissionIntro.IsCiSpyPlayer and MissionIntro.IsCiSpyPlayer(ply) == true

	local isSecurity = MissionIntro.IsSecurityRewardProfileId(profileId)
	if not isSecurity and MissionIntro.IsFacilitySecurityFactionId then
		isSecurity = MissionIntro.IsFacilitySecurityFactionId(facId) == true
	end
	if isCiSpy then
		isSecurity = true
	end

	local isMtfFacility = MissionIntro.IsMtfFacilityRewardProfileId and MissionIntro.IsMtfFacilityRewardProfileId(profileId)
	if not isMtfFacility and MissionIntro.IsFacilityMtfFactionId then
		isMtfFacility = MissionIntro.IsFacilityMtfFactionId(facId) == true
	end

	local isReinforce = isstring(facId) and facId ~= ""
		and istable(MissionIntro.SupportReinforceFactionIds)
		and MissionIntro.SupportReinforceFactionIds[facId] == true

	if isReinforce or isSecurity or (isMtfFacility and not MissionIntro.IsMtfFacilityRewardProfileId(profileId)) then
		add(MissionIntro.WalkieTalkieWeapon or "weapon_walkie_talkie")
	end

	if facId == "hammerfall_squad"
		or facId == "hammerfall_maintenance"
		or facId == "pttrb_squad"
		or isSecurity then
		for _, class in ipairs(MissionIntro.HandcuffExtraWeapons or {}) do
			add(class)
		end
	end

	return bonus
end

-- SCP 门禁卡（GuthSCP Keycard）
MissionIntro.FacilityKeycardByRewardProfile = {
	facility_researcher = "guthscp_keycard_lvl_2",
	facility_doctor = "guthscp_keycard_lvl_1",
	facility_senior_scientist = "guthscp_keycard_lvl_3",
	facility_ethics = "guthscp_keycard_lvl_3",
	classd_impostor = "guthscp_keycard_lvl_2",
	facility_security_rookie = "guthscp_keycard_lvl_3",
	facility_security_officer = "guthscp_keycard_lvl_3",
	facility_security_warden = "guthscp_keycard_lvl_3",
	facility_security_sergeant = "guthscp_keycard_lvl_3",
	facility_security_captain = "guthscp_keycard_lvl_4",
	facility_mtf_site_director = "guthscp_keycard_lvl_5",
	facility_qrf_soldier = "guthscp_keycard_lvl_3",
	facility_qrf_marksman = "guthscp_keycard_lvl_3",
	facility_qrf_medic = "guthscp_keycard_lvl_3",
	facility_qrf_breacher = "guthscp_keycard_lvl_3",
	facility_qrf_commander = "guthscp_keycard_lvl_3",
	facility_scp_062de = "guthscp_keycard_omni",
	facility_scp_0762 = "guthscp_keycard_omni",
	facility_scp_912 = "guthscp_keycard_omni",
	uiu_spy = "guthscp_keycard_lvl_3",
	dr_maynard = "guthscp_keycard_lvl_4",
	ntf_soldier = "guthscp_keycard_lvl_5",
}

MissionIntro.SupportReinforceKeycard = "guthscp_keycard_lvl_5"

MissionIntro.SupportReinforceFactionIds = {
	scarlet_cultist = true,
	hammerfall_squad = true,
	hammerfall_maintenance = true,
	sid_squad = true,
	uiu_taskforce = true,
	pttrb_squad = true,
	mcd_squad = true,
	ci_squad = true,
	vdv_squad = true,
	goc_squad = true,
	ntf_squad = true,
}

function MissionIntro.ResolveKeycardWeaponForPlayer(ply)
	if not IsValid(ply) then return nil end

	local storedFac = MissionIntro.GetStoredFacilityFactionId and MissionIntro.GetStoredFacilityFactionId(ply)
	if storedFac == "ci_spy" then
		local profileId = MissionIntro.GetCiSpyRewardProfileId and MissionIntro.GetCiSpyRewardProfileId(ply)
		if isstring(profileId) and profileId ~= "" and MissionIntro.FacilityKeycardByRewardProfile[profileId] then
			return MissionIntro.FacilityKeycardByRewardProfile[profileId]
		end
		return "guthscp_keycard_lvl_3"
	end

	if MissionIntro.IsFacilityFactionId and storedFac and MissionIntro.IsFacilityFactionId(storedFac) then
		local profileId = MissionIntro.GetRewardProfileId and MissionIntro.GetRewardProfileId(ply)
		return profileId and MissionIntro.FacilityKeycardByRewardProfile[profileId] or nil
	end

	local facId = MissionIntro.GetFactionId and MissionIntro.GetFactionId(ply)
	if isstring(facId) and MissionIntro.SupportReinforceFactionIds[facId] then
		return MissionIntro.SupportReinforceKeycard
	end

	return nil
end

MissionIntro.Rewards = MissionIntro.FactionRewards.scarlet_bishop



local function MI_Log(msg)

	MsgN("[MissionIntro] " .. msg)

end

function MissionIntro.GiveRoleKeycard(ply)
	if not SERVER or not IsValid(ply) or not ply:IsPlayer() then return false end

	local keycard = MissionIntro.ResolveKeycardWeaponForPlayer(ply)
	if not isstring(keycard) or keycard == "" then return false end

	if IsValid(ply:GetWeapon(keycard)) then return true end

	local given = (MissionIntro.GivePlayerWeapon or ply.Give)(ply, keycard)
	if IsValid(given) or IsValid(ply:GetWeapon(keycard)) then
		MI_Log("门禁卡: " .. keycard .. " -> " .. ply:Nick())
		return true
	end

	MI_Log("门禁卡失败(类名可能不存在?): " .. keycard)
	return false
end

function MissionIntro.HolsterFacilityPlayerWeapons(ply)
	if not SERVER or not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end

	local prefer = { "weapon_hands_sh", "weapon_hands", "weapon_fists", "gmod_hands" }
	for _, cls in ipairs(prefer) do
		if IsValid(ply:GetWeapon(cls)) then
			ply:SelectWeapon(cls)
			return true
		end
	end

	for _, wep in ipairs(ply:GetWeapons()) do
		if not IsValid(wep) then continue end
		local cls = wep:GetClass() or ""
		if cls:find("hands", 1, true) then
			ply:SelectWeapon(cls)
			return true
		end
	end

	return false
end

function MissionIntro.ScheduleFacilityWeaponHolster(ply, delays)
	if not MissionIntro.ShouldDeferFacilityWeaponDraw or not MissionIntro.ShouldDeferFacilityWeaponDraw(ply) then
		return
	end

	for _, delay in ipairs(delays or { 0, 0.15, 0.35 }) do
		timer.Simple(delay, function()
			if IsValid(ply) and MissionIntro.HolsterFacilityPlayerWeapons then
				MissionIntro.HolsterFacilityPlayerWeapons(ply)
			end
		end)
	end
end



local function MI_AmmoTypeFromWeapon(wepClass)

	local swep = weapons.Get(wepClass)

	if not swep or not swep.Primary then return nil end

	local a = swep.Primary.Ammo

	if isstring(a) and a ~= "" then return a end

	return nil

end



local function MI_GiveAmmoToWeapon(ply, wepClass, count)

	if not IsValid(ply) then return false end



	local w = ply:GetWeapon(wepClass)

	if not IsValid(w) then return false end



	local gave = false

	local ammoId = w:GetPrimaryAmmoType()

	if isnumber(ammoId) and ammoId >= 0 then

		ply:SetAmmo(count, ammoId)

		gave = true

	end



	local ammoName = MI_AmmoTypeFromWeapon(wepClass)

	if ammoName then

		ply:GiveAmmo(count, ammoName)

		gave = true

	end



	local clipMax = w:GetMaxClip1() or 0

	if clipMax > 0 then

		w:SetClip1(math.min(clipMax, count))

	end



	return gave

end



local function MI_GiveAmmoByName(ply, count, types)

	for _, typ in ipairs(types or {}) do

		local id = game.GetAmmoID(typ)

		if id and id >= 0 then

			ply:GiveAmmo(count, typ)

			return true, typ

		end

	end

	return false

end



local function MI_SetEntityAmmoCount(ent, count)

	if not IsValid(ent) then return end



	local setters = { "Setcount", "SetCount", "SetAmmo", "SetAmmoCount", "SetAmount", "SetRounds" }

	for _, name in ipairs(setters) do

		local fn = ent[name]

		if isfunction(fn) then

			fn(ent, count)

		end

	end



	ent:SetNWInt("Ammo", count)

	ent:SetNWInt("AmmoCount", count)

	ent:SetNWInt("count", count)

end



local function MI_TryPickupEntity(ply, ent)

	if not IsValid(ply) or not IsValid(ent) then return false end



	if isfunction(ent.StartTouch) then

		ent:StartTouch(ply)

	end

	if isfunction(ent.Touch) then

		ent:Touch(ply)

	end

	if isfunction(ent.Use) then

		ent:Use(ply, ply, USE_ON, 1)

	end

	if isfunction(ent.OnTake) then

		ent:OnTake(ply)

	end



	return not IsValid(ent)

end



local function MI_SpawnPickupEntity(ply, class, offset, onSpawned)

	if not scripted_ents.Get(class) then

		return false, "类名未注册: " .. class

	end



	local ent = ents.Create(class)

	if not IsValid(ent) then

		return false, "无法创建: " .. class

	end



	offset = offset or Vector(0, 0, 12)

	local pos = ply:GetPos() + offset

	ent:SetPos(pos)

	ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))



	if isfunction(onSpawned) then

		onSpawned(ent)

	end



	ent:Spawn()

	ent:Activate()



	local function MI_Finalize()

		if not IsValid(ent) or not IsValid(ply) then return end

		if isfunction(onSpawned) then

			onSpawned(ent)

		end

		MI_TryPickupEntity(ply, ent)

	end



	timer.Simple(0, MI_Finalize)

	timer.Simple(0.1, MI_Finalize)



	return true

end



local function MI_GiveAmmoEntity(ply, class, count)

	return MI_SpawnPickupEntity(ply, class, Vector(0, 0, 12), function(ent)

		MI_SetEntityAmmoCount(ent, count)

	end)

end



MissionIntro.NightVisionClass = "ent_armor_nightvision1"

function MissionIntro.ShouldKeepNightVision(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end

	local fromHook = hook.Run("MissionIntro_ShouldKeepNightVision", ply)
	if fromHook ~= nil then return fromHook == true end

	if MissionIntro.GetFactionId and MissionIntro.GetHammerfallRole then
		if MissionIntro.GetFactionId(ply) == "hammerfall_squad" and MissionIntro.GetHammerfallRole(ply) == "commander" then
			return true
		end
	end

	return false
end

local function MI_FilterEquipmentForPlayer(ply, classes)
	local out = {}
	local nvClass = MissionIntro.NightVisionClass or "ent_armor_nightvision1"
	local roleKey = MissionIntro.GetFacilityRole and MissionIntro.GetFacilityRole(ply)
	local facId = MissionIntro.GetFactionId and MissionIntro.GetFactionId(ply)
	local useModelHelmetCap = roleKey == "qrf_marksman" or facId == "facility_qrf_marksman"
		or roleKey == "qrf_commander" or facId == "facility_qrf_commander"

	for _, class in ipairs(classes or {}) do
		if class == nvClass and not MissionIntro.ShouldKeepNightVision(ply) then
			continue
		end
		if useModelHelmetCap and class == "ent_armor_helmet1" then
			continue
		end
		out[#out + 1] = class
	end

	return out
end

function MissionIntro.StripNightVisionFromPlayer(ply)
	if not SERVER or not IsValid(ply) or not ply:IsPlayer() then return end
	if MissionIntro.ShouldKeepNightVision(ply) then return end

	local nvClass = MissionIntro.NightVisionClass or "ent_armor_nightvision1"

	for _, ent in ipairs(ents.FindByClass(nvClass)) do
		if not IsValid(ent) then continue end
		if ent:GetParent() == ply or ent:GetOwner() == ply then
			ent:Remove()
		end
	end

	for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 96)) do
		if not IsValid(ent) or ent:GetClass() ~= nvClass then continue end
		if ent:GetParent() == ply or ent:GetOwner() == ply then
			ent:Remove()
		end
	end
end

local function MI_GiveEquipment(ply, classes)

	local ok = false

	local spread = { Vector(50, 0, 12), Vector(-50, 0, 12), Vector(0, 50, 12), Vector(0, -50, 12), Vector(40, 40, 12) }



	for i, class in ipairs(classes or {}) do

		if not isstring(class) or class == "" then continue end



		local off = spread[i] or Vector((i - 1) * 40, 0, 12)

		local entOk, err = MI_SpawnPickupEntity(ply, class, off)

		if entOk then

			ok = true

			MI_Log("装备: " .. class .. " -> " .. ply:Nick())

		else

			MI_Log(err or ("装备失败: " .. class))

		end

	end



	return ok

end



local function MI_GiveExtraWeapons(ply, classes)

	local ok = false
	local seen = {}

	local function giveClass(class)
		if not isstring(class) or class == "" or seen[class] then return end
		seen[class] = true

		local given = (MissionIntro.GivePlayerWeapon or ply.Give)(ply, class)
		if IsValid(given) or IsValid(ply:GetWeapon(class)) then
			ok = true
			MI_Log("物品: " .. class .. " -> " .. ply:Nick())
		else
			MI_Log("物品失败(类名可能不存在?): " .. class)
		end
	end

	for _, class in ipairs(MissionIntro.UniversalExtraWeapons or {}) do
		giveClass(class)
	end

	for _, class in ipairs(classes or {}) do
		giveClass(class)
	end

	return ok

end



MissionIntro.ModelResetBlank = MissionIntro.ModelResetBlank or "models/player/skeleton.mdl"

function MissionIntro.NormalizeBodygroupTable(bodygroups, baseIndex)
	if not istable(bodygroups) then return nil end

	baseIndex = tonumber(baseIndex) or 0
	local out = {}
	local hasArrayPart = bodygroups[0] ~= nil or bodygroups[1] ~= nil

	if hasArrayPart then
		for id, value in pairs(bodygroups) do
			local bgId = tonumber(id)
			if bgId and bgId >= 0 and math.floor(bgId) == bgId then
				out[bgId] = tonumber(value) or 0
			end
		end
	elseif bodygroups[1] ~= nil then
		for index, value in ipairs(bodygroups) do
			out[baseIndex + index - 1] = tonumber(value) or 0
		end
	else
		for id, value in pairs(bodygroups) do
			local bgId = tonumber(id)
			if bgId and bgId >= 0 then
				out[bgId] = tonumber(value) or 0
			end
		end
	end

	return out
end

function MissionIntro.ApplyPlayerModelBodygroups(ply, bodygroups, skin, baseIndex)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	local bgMap = MissionIntro.NormalizeBodygroupTable(bodygroups, baseIndex)
	if not bgMap then return end

	local groupCount = ply:GetNumBodyGroups() or 0
	for bgId, value in pairs(bgMap) do
		if bgId >= 0 and bgId < groupCount then
			local wanted = math.max(0, math.floor(tonumber(value) or 0))
			local maxVal = math.max(0, (ply:GetBodygroupCount(bgId) or 1) - 1)
			ply:SetBodygroup(bgId, math.min(wanted, maxVal))
		end
	end

	if isnumber(skin) then
		local maxSkin = math.max(0, (ply:SkinCount() or 1) - 1)
		ply:SetSkin(math.Clamp(math.floor(skin), 0, maxSkin))
	end

	if MissionIntro.ApplyHammerfallClothesColor then
		MissionIntro.ApplyHammerfallClothesColor(ply)
	end

	if MissionIntro.ApplyObrQrfBodygroupFixes then
		MissionIntro.ApplyObrQrfBodygroupFixes(ply)
	end
end

function MissionIntro.GetHammerfallClothesBodygroupId(ply)
	if not IsValid(ply) then return tonumber(MissionIntro.HammerfallClothesBodygroupIndex) or 0 end

	if ply._missionIntroClothesBgId ~= nil then
		return ply._missionIntroClothesBgId
	end

	local forced = tonumber(MissionIntro.HammerfallClothesBodygroupIndex)
	if forced ~= nil and forced >= 0 then
		ply._missionIntroClothesBgId = forced
		return forced
	end

	local bestId, bestChoices = 0, 0
	for i = 0, (ply:GetNumBodyGroups() or 1) - 1 do
		local name = string.lower(ply:GetBodygroupName(i) or "")
		if name:find("color", 1, true) or name:find("cloth", 1, true) or name:find("uniform", 1, true)
			or name:find("shirt", 1, true) or name:find("衣", 1, true) then
			ply._missionIntroClothesBgId = i
			return i
		end

		local choices = ply:GetBodygroupCount(i) or 0
		if choices > bestChoices then
			bestChoices = choices
			bestId = i
		end
	end

	ply._missionIntroClothesBgId = bestId
	return bestId
end

function MissionIntro.ApplyHammerfallClothesColor(ply)
	if not SERVER or not IsValid(ply) or not ply:IsPlayer() then return end
	local facId = MissionIntro.GetFactionId and MissionIntro.GetFactionId(ply)
	if facId ~= "hammerfall_squad" and facId ~= "hammerfall_maintenance" then return end

	local role
	if facId == "hammerfall_maintenance" then
		if MissionIntro.GetHammerfallMaintenanceRole then
			role = MissionIntro.GetHammerfallMaintenanceRole(ply)
		else
			role = "maintenance_expert"
		end
	elseif MissionIntro.GetHammerfallRole then
		role = MissionIntro.GetHammerfallRole(ply)
	else
		return
	end
	-- 指挥官使用 ETT 组长模型；重装使用 mog_jagger，不适用 mog 制服配色
	if role == "commander" or role == "heavy" then return end

	local colors = MissionIntro.HammerfallClothesColorValue or {}
	local wanted = tonumber(colors[role])
	if wanted == nil then
		wanted = (role == "medic" or role == "maintenance_expert") and 1 or 0
	end

	local bgId = MissionIntro.GetHammerfallClothesBodygroupId(ply)
	local maxVal = math.max(0, (ply:GetBodygroupCount(bgId) or 1) - 1)
	ply:SetBodygroup(bgId, math.Clamp(math.floor(wanted), 0, maxVal))

	if role == "medic" or role == "maintenance_expert" then
		if (ply:SkinCount() or 0) > 1 then
			ply:SetSkin(math.min(1, (ply:SkinCount() or 1) - 1))
		else
			ply:SetSkin(1)
		end
	elseif role == "soldier" then
		ply:SetSkin(0)
	end
end

function MissionIntro.ScheduleHammerfallClothesColorApply(ply)
	if not SERVER or not IsValid(ply) then return end

	local function run()
		if not IsValid(ply) then return end
		if MissionIntro.ApplyHammerfallClothesColor then
			MissionIntro.ApplyHammerfallClothesColor(ply)
		end
		if MissionIntro.ApplyCachedPlayerModelVisuals and ply._missionIntroForcedBodygroups then
			MissionIntro.ApplyCachedPlayerModelVisuals(ply)
		end
	end

	run()
	for _, delay in ipairs({ 0.05, 0.15, 0.35, 0.75, 1.5, 3.0 }) do
		timer.Simple(delay, run)
	end
end

function MissionIntro.GetBodygroupBaseForModel(mdl, R)
	if istable(R) and isnumber(R.player_bodygroup_base) then
		return R.player_bodygroup_base
	end

	if isstring(mdl) and mdl:find("/mog/", 1, true) then
		return 0
	end
	if isstring(mdl) and (mdl:find("/obr/", 1, true) or mdl:find("\\obr\\", 1, true)) then
		return 0
	end

	if isstring(mdl) and mdl:find("cultist", 1, true) then
		if mdl:find("/fbi/", 1, true) or mdl:find("\\fbi\\", 1, true) then
			return 0
		end
		if mdl:find("/sci/", 1, true) or mdl:find("\\sci\\", 1, true)
			or mdl:find("/security/", 1, true) or mdl:find("\\security\\", 1, true) then
			return 0
		end
		if mdl:find("/class_d/", 1, true) or mdl:find("\\class_d\\", 1, true) then
			return 0
		end
		return MissionIntro.ScarletCultistBodygroupBase or 0
	end

	return 0
end

function MissionIntro.ResolveRewardBodygroups(ply, R)
	if not istable(R) then return nil end

	if MissionIntro.IsClassDPersonnelPlayer and MissionIntro.IsClassDPersonnelPlayer(ply) then
		if istable(ply._missionIntroFacilityBodygroups) then
			return ply._missionIntroFacilityBodygroups
		end
	end

	if MissionIntro.GetStoredUiuTfBodygroups then
		local uiuBg = MissionIntro.GetStoredUiuTfBodygroups(ply)
		if uiuBg then return uiuBg end
	end

	if MissionIntro.IsUiuTaskforcePlayer and MissionIntro.IsUiuTaskforcePlayer(ply) and MissionIntro.GetUiuTfBodygroupsForPlayer then
		return MissionIntro.GetUiuTfBodygroupsForPlayer(ply)
	end

	if MissionIntro.IsFacilityFactionId and MissionIntro.GetStoredFacilityFactionId then
		local facId = MissionIntro.GetStoredFacilityFactionId(ply)
		if facId and MissionIntro.IsFacilityFactionId(facId) and MissionIntro.GetFacilityBodygroupsForPlayer then
			return MissionIntro.GetFacilityBodygroupsForPlayer(ply)
		end
	end

	if MissionIntro.GetFactionId and MissionIntro.GetFactionId(ply) == "hammerfall_maintenance" and MissionIntro.GetHammerfallMaintenanceBodygroupsForPlayer then
		return MissionIntro.GetHammerfallMaintenanceBodygroupsForPlayer(ply)
	end

	if MissionIntro.GetFactionId and MissionIntro.GetFactionId(ply) == "hammerfall_squad" and MissionIntro.GetHammerfallBodygroupsForPlayer then
		return MissionIntro.GetHammerfallBodygroupsForPlayer(ply)
	end

	if MissionIntro.GetFactionId and MissionIntro.GetFactionId(ply) == "uiu_taskforce" and MissionIntro.GetUiuTfBodygroupsForPlayer then
		return MissionIntro.GetUiuTfBodygroupsForPlayer(ply)
	end

	if MissionIntro.GetFactionId and MissionIntro.GetFactionId(ply) == "sid_squad" and MissionIntro.GetSidBodygroupsForPlayer then
		if not (MissionIntro.IsUiuTaskforcePlayer and MissionIntro.IsUiuTaskforcePlayer(ply)) then
			return MissionIntro.GetSidBodygroupsForPlayer(ply)
		end
	end

	if MissionIntro.GetFactionId and MissionIntro.GetFactionId(ply) == "pttrb_squad" and MissionIntro.GetPttrbBodygroupsForPlayer then
		return MissionIntro.GetPttrbBodygroupsForPlayer(ply)
	end

	if MissionIntro.GetFactionId and MissionIntro.GetFactionId(ply) == "mcd_squad" and MissionIntro.GetMcdBodygroupsForPlayer then
		return MissionIntro.GetMcdBodygroupsForPlayer(ply)
	end

	if MissionIntro.GetFactionId and MissionIntro.GetFactionId(ply) == "ntf_squad" and MissionIntro.GetNtfBodygroupsForPlayer then
		return MissionIntro.GetNtfBodygroupsForPlayer(ply)
	end

	if MissionIntro.GetFactionId and MissionIntro.GetFactionId(ply) == "ci_squad" and MissionIntro.GetCiBodygroupsForPlayer then
		return MissionIntro.GetCiBodygroupsForPlayer(ply)
	end

	if MissionIntro.GetFactionId and MissionIntro.GetFactionId(ply) == "vdv_squad" and MissionIntro.GetVdvBodygroupsForPlayer then
		return MissionIntro.GetVdvBodygroupsForPlayer(ply)
	end

	if MissionIntro.GetFactionId and MissionIntro.GetFactionId(ply) == "goc_squad" and MissionIntro.GetGocBodygroupsForPlayer then
		return MissionIntro.GetGocBodygroupsForPlayer(ply)
	end

	if MissionIntro.GetFactionId and MissionIntro.GetFactionId(ply) == "scarlet_cultist" and MissionIntro.GetScarletRole then
		local role = MissionIntro.GetScarletRole(ply)
		if MissionIntro.ScarletRoleBodygroups and MissionIntro.ScarletRoleBodygroups[role] then
			return MissionIntro.ScarletRoleBodygroups[role]
		end
	end

	return R.player_bodygroups
end

function MissionIntro.RefreshUiuTfForcedBodygroups(ply)
	if not SERVER or not IsValid(ply) or not ply:IsPlayer() then return false end
	if not MissionIntro.IsUiuTaskforcePlayer or not MissionIntro.IsUiuTaskforcePlayer(ply) then return false end

	local bg = MissionIntro.GetStoredUiuTfBodygroups and MissionIntro.GetStoredUiuTfBodygroups(ply)
	if not istable(bg) and MissionIntro.GetUiuTfBodygroupsForPlayer then
		bg = MissionIntro.GetUiuTfBodygroupsForPlayer(ply)
	end
	if not istable(bg) then return false end

	local R = MissionIntro.GetFactionRewards and MissionIntro.GetFactionRewards(ply) or nil
	local mdl = (R and R.player_model) or MissionIntro.UiuTfModel or ply._missionIntroForcedModel
	local base = MissionIntro.GetBodygroupBaseForModel(mdl, R)
	ply._missionIntroForcedBodygroups = MissionIntro.NormalizeBodygroupTable(bg, base)
	ply._missionIntroForcedBodygroupBase = base
	MissionIntro.ApplyCachedPlayerModelVisuals(ply)
	return true
end

function MissionIntro.ReapplyForcedPlayerBodygroups(ply, delays)
	if not SERVER or not IsValid(ply) or not ply:IsPlayer() then return end
	if not ply._missionIntroForcedBodygroups then return end

	MissionIntro.ApplyCachedPlayerModelVisuals(ply)

	for _, delay in ipairs(delays or { 0.05, 0.2, 0.5, 1.0, 2.0 }) do
		timer.Simple(delay, function()
			if not IsValid(ply) or not ply._missionIntroForcedBodygroups then return end
			MissionIntro.ApplyCachedPlayerModelVisuals(ply)
		end)
	end
end

function MissionIntro.CacheForcedPlayerModelVisuals(ply, R)
	if not IsValid(ply) or not istable(R) then return end

	local bodygroups = MissionIntro.ResolveRewardBodygroups(ply, R)
	if istable(bodygroups) then
		local mdl = ply._missionIntroForcedModel or ply._missionIntroFacilityModel or R.player_model
		local base = MissionIntro.GetBodygroupBaseForModel(mdl, R)
		ply._missionIntroForcedBodygroups = MissionIntro.NormalizeBodygroupTable(bodygroups, base)
		ply._missionIntroForcedBodygroupBase = base
	elseif bodygroups == nil then
		ply._missionIntroForcedBodygroups = nil
		ply._missionIntroForcedBodygroupBase = nil
	end

	if isnumber(R.player_skin) then
		ply._missionIntroForcedSkin = R.player_skin
	end
end

function MissionIntro.ApplyCachedPlayerModelVisuals(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	if MissionIntro.IsClassDPersonnelPlayer and MissionIntro.IsClassDPersonnelPlayer(ply)
		and MissionIntro.ApplyClassDBodygroupsToPlayer then
		MissionIntro.ApplyClassDBodygroupsToPlayer(ply)
		return
	end

	MissionIntro.ApplyPlayerModelBodygroups(
		ply,
		ply._missionIntroForcedBodygroups,
		ply._missionIntroForcedSkin,
		ply._missionIntroForcedBodygroupBase
	)
end

local function MI_ShouldStripAttachedEntity(ent)
	if not IsValid(ent) then return false end

	local class = ent:GetClass()
	if class == "gmod_hands" then return false end
	if ent:IsWeapon() then return false end
	if class:StartWith("weapon_") then return false end
	if class:StartWith("ent_armor_") or class:find("armor", 1, true) then return false end
	if class:StartWith("ent_ammo_") then return false end

	-- 只清 bonemerge / 旧外观道具，避免删掉挂在身上的枪
	if class == "prop_dynamic" or class == "prop_physics" then return true end

	return false
end

-- Realtime Player Updater (Workshop 3660635637) 同款：换模前清掉子材质/配饰，避免旧模型贴图残留
function MissionIntro.ClearPlayerMaterialOverrides(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	ply:SetSubMaterial()

	if ply.SetNetVar then
		ply:SetNetVar("Accessories", "")
	end

	for _, key in ipairs({ "main", "pants", "boots", "gloves", "vest", "shirt", "coat" }) do
		ply:SetNWString("Colthes" .. key, "")
	end
end

function MissionIntro.StripPlayerModelExtras(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	MissionIntro.ClearPlayerMaterialOverrides(ply)

	local hands = ply:GetHands()
	if IsValid(hands) then
		hands:Remove()
	end

	for _, child in ipairs(ply:GetChildren()) do
		if MI_ShouldStripAttachedEntity(child) then
			child:Remove()
		end
	end
end

function MissionIntro.SafeSetupHands(ply)
	if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
	if not isfunction(ply.SetupHands) then return end

	local function trySetup()
		if not IsValid(ply) or not ply:Alive() then return end
		local vm = ply:GetViewModel(0)
		if not IsValid(vm) then return false end

		local ok, err = pcall(function()
			ply:SetupHands()
		end)
		if not ok then
			MI_Log("SetupHands 失败: " .. tostring(err))
		end
		return ok
	end

	if trySetup() then return end

	timer.Simple(0.15, function()
		if not IsValid(ply) then return end
		trySetup()
	end)
end

function MissionIntro.ResetPlayerModelVisual(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	MissionIntro.StripPlayerModelExtras(ply)

	local groups = ply:GetNumBodyGroups() or 0
	for i = 0, groups - 1 do
		ply:SetBodygroup(i, 0)
	end

	ply:SetSkin(0)
end

function MissionIntro.ClearForcedPlayerModel(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	MissionIntro.StripPlayerModelExtras(ply)
	ply._missionIntroForcedModel = nil
	ply._missionIntroApplyForcedOnSpawn = nil
	ply._missionIntroForcedBodygroups = nil
	ply._missionIntroForcedBodygroupBase = nil
	ply._missionIntroForcedSkin = nil
	ply._missionIntroClothesBgId = nil
	ply._missionIntroBodygroupKeepAt = nil
end

local function MI_CommitForcedPlayerModel(ply, mdl)
	if not IsValid(ply) or not isstring(mdl) or mdl == "" or not util.IsValidModel(mdl) then return false end
	if ply._missionIntroForcedModel ~= mdl then return false end

	local R = MissionIntro.GetFactionRewards and MissionIntro.GetFactionRewards(ply) or nil

	MissionIntro.StripPlayerModelExtras(ply)

	if ply:GetModel() ~= mdl then
		ply:SetModel(mdl)
	end

	MissionIntro.ClearPlayerMaterialOverrides(ply)

	if istable(R) then
		MissionIntro.CacheForcedPlayerModelVisuals(ply, R)
	end

	MissionIntro.ApplyCachedPlayerModelVisuals(ply)

	local function reapplyVisuals()
		if not IsValid(ply) or ply._missionIntroForcedModel ~= mdl then return end
		MissionIntro.ApplyCachedPlayerModelVisuals(ply)
	end

	timer.Simple(0.05, reapplyVisuals)
	timer.Simple(0.2, reapplyVisuals)
	timer.Simple(0.5, reapplyVisuals)

	if MissionIntro.ScheduleHammerfallClothesColorApply then
		MissionIntro.ScheduleHammerfallClothesColorApply(ply)
	end

	MissionIntro.SafeSetupHands(ply)

	return true
end

function MissionIntro.PrimeFacilitySpawnModel(ply)
	if not SERVER or not IsValid(ply) or not ply:IsPlayer() then return false end
	if not MissionIntro.IsFacilitySpawnPlayer or not MissionIntro.IsFacilitySpawnPlayer(ply) then return false end

	local R = MissionIntro.GetFactionRewards and MissionIntro.GetFactionRewards(ply) or nil
	if MissionIntro.GetStoredFacilityFactionId and MissionIntro.GetStoredFacilityFactionId(ply) == "ci_spy" and MissionIntro.GetCiSpyDisguiseRewardTable then
		local disguiseR = MissionIntro.GetCiSpyDisguiseRewardTable(ply)
		if istable(disguiseR) then
			R = disguiseR
		end
	end
	if not istable(R) or R.force_player_model == false then return false end

	local mdl = ply._missionIntroFacilityModel
	if not isstring(mdl) or mdl == "" or not util.IsValidModel(mdl) then
		mdl = R.player_model
	end
	if not isstring(mdl) or mdl == "" or not util.IsValidModel(mdl) then
		if MissionIntro.PickFacilityScientistModel then
			mdl = MissionIntro.PickFacilityScientistModel(ply)
			ply._missionIntroFacilityModel = mdl
		end
	end
	if not isstring(mdl) or mdl == "" or not util.IsValidModel(mdl) then return false end

	ply._missionIntroForcedModel = mdl
	ply._missionIntroApplyForcedOnSpawn = true
	MissionIntro.CacheForcedPlayerModelVisuals(ply, R)

	if istable(ply._missionIntroFacilityBodygroups) then
		ply._missionIntroForcedBodygroups = table.Copy(ply._missionIntroFacilityBodygroups)
	end

	return true
end

function MissionIntro.PrimeUiuTfSpawnModel(ply)
	if not SERVER or not IsValid(ply) or not ply:IsPlayer() then return false end
	if not MissionIntro.IsUiuTaskforceSpawnPlayer or not MissionIntro.IsUiuTaskforceSpawnPlayer(ply) then return false end

	local R = MissionIntro.GetFactionRewards and MissionIntro.GetFactionRewards(ply) or nil
	if not istable(R) or R.force_player_model == false then return false end

	local mdl = R.player_model or MissionIntro.UiuTfModel or "models/cultist/humans/fbi/fbi.mdl"
	if not isstring(mdl) or mdl == "" or not util.IsValidModel(mdl) then return false end

	ply._missionIntroForcedModel = mdl
	ply._missionIntroApplyForcedOnSpawn = true
	MissionIntro.CacheForcedPlayerModelVisuals(ply, R)

	return true
end

function MissionIntro.PrimeHammerfallSpawnModel(ply)
	if not SERVER or not IsValid(ply) or not ply:IsPlayer() then return false end
	if not MissionIntro.IsHammerfallSpawnPlayer or not MissionIntro.IsHammerfallSpawnPlayer(ply) then return false end

	local R = MissionIntro.GetFactionRewards and MissionIntro.GetFactionRewards(ply) or nil
	if not istable(R) or R.force_player_model == false then return false end

	local mdl = R.player_model or MissionIntro.HammerfallMogModel or "models/cultist/humans/mog/mog.mdl"
	if not isstring(mdl) or mdl == "" or not util.IsValidModel(mdl) then return false end

	ply._missionIntroForcedModel = mdl
	ply._missionIntroApplyForcedOnSpawn = true
	MissionIntro.CacheForcedPlayerModelVisuals(ply, R)

	return true
end

function MissionIntro.PrimeSidSpawnModel(ply)
	if not SERVER or not IsValid(ply) or not ply:IsPlayer() then return false end
	if not MissionIntro.IsSidSpawnPlayer or not MissionIntro.IsSidSpawnPlayer(ply) then return false end

	local R = MissionIntro.GetFactionRewards and MissionIntro.GetFactionRewards(ply) or nil
	if not istable(R) or R.force_player_model == false then return false end

	local mdl = R.player_model or MissionIntro.SidAgentModel or "models/cultist/humans/fbi/fbi.mdl"
	if not isstring(mdl) or mdl == "" or not util.IsValidModel(mdl) then return false end

	ply._missionIntroForcedModel = mdl
	ply._missionIntroApplyForcedOnSpawn = true
	MissionIntro.CacheForcedPlayerModelVisuals(ply, R)

	return true
end

function MissionIntro.ShouldDirectApplyForcedModel(ply)
	if MissionIntro.IsFacilitySpawnPlayer and MissionIntro.IsFacilitySpawnPlayer(ply) then return true end
	if MissionIntro.IsHammerfallSpawnPlayer and MissionIntro.IsHammerfallSpawnPlayer(ply) then return true end
	if MissionIntro.IsUiuTaskforceSpawnPlayer and MissionIntro.IsUiuTaskforceSpawnPlayer(ply) then return true end
	if MissionIntro.IsSidSpawnPlayer and MissionIntro.IsSidSpawnPlayer(ply) then return true end
	return false
end

function MissionIntro.PrimeForcedSpawnModel(ply)
	if MissionIntro.IsFacilitySpawnPlayer and MissionIntro.IsFacilitySpawnPlayer(ply) and MissionIntro.PrimeFacilitySpawnModel then
		return MissionIntro.PrimeFacilitySpawnModel(ply)
	end
	if MissionIntro.IsHammerfallSpawnPlayer and MissionIntro.IsHammerfallSpawnPlayer(ply) and MissionIntro.PrimeHammerfallSpawnModel then
		return MissionIntro.PrimeHammerfallSpawnModel(ply)
	end
	if MissionIntro.IsUiuTaskforceSpawnPlayer and MissionIntro.IsUiuTaskforceSpawnPlayer(ply) and MissionIntro.PrimeUiuTfSpawnModel then
		return MissionIntro.PrimeUiuTfSpawnModel(ply)
	end
	if MissionIntro.IsSidSpawnPlayer and MissionIntro.IsSidSpawnPlayer(ply) and MissionIntro.PrimeSidSpawnModel then
		return MissionIntro.PrimeSidSpawnModel(ply)
	end
	return false
end

function MissionIntro.ApplyForcedPlayerModel(ply, opts)
	if not SERVER or not IsValid(ply) or not ply:IsPlayer() then return false end

	opts = opts or {}

	local R = MissionIntro.GetFactionRewards and MissionIntro.GetFactionRewards(ply) or MissionIntro.Rewards
	if MissionIntro.GetStoredFacilityFactionId and MissionIntro.GetStoredFacilityFactionId(ply) == "ci_spy" and MissionIntro.GetCiSpyDisguiseRewardTable then
		local disguiseR = MissionIntro.GetCiSpyDisguiseRewardTable(ply)
		if istable(disguiseR) then
			R = disguiseR
		end
	end
	if not istable(R) or R.force_player_model == false then return false end

	local isDirectSpawn = MissionIntro.ShouldDirectApplyForcedModel and MissionIntro.ShouldDirectApplyForcedModel(ply)
	if isDirectSpawn and MissionIntro.PrimeForcedSpawnModel then
		MissionIntro.PrimeForcedSpawnModel(ply)
	end

	local isFacility = MissionIntro.IsFacilitySpawnPlayer and MissionIntro.IsFacilitySpawnPlayer(ply)

	local mdl = R.player_model
	if isFacility then
		if not isstring(mdl) or mdl == "" or not util.IsValidModel(mdl) then
			local facMdl = ply._missionIntroFacilityModel
			if isstring(facMdl) and facMdl ~= "" and util.IsValidModel(facMdl) then
				mdl = facMdl
			end
		end
	elseif MissionIntro.GetStoredFacilityFactionId and MissionIntro.GetStoredFacilityFactionId(ply) then
		local facMdl = ply._missionIntroFacilityModel
		if isstring(facMdl) and facMdl ~= "" and util.IsValidModel(facMdl) then
			mdl = facMdl
		end
	end
	if not isstring(mdl) or mdl == "" then return false end

	if not util.IsValidModel(mdl) then
		MI_Log("玩家模型无效(未挂载?): " .. mdl)
		return false
	end

	ply._missionIntroForcedModel = mdl
	ply._missionIntroApplyForcedOnSpawn = true
	MissionIntro.CacheForcedPlayerModelVisuals(ply, R)

	if opts.sync or isDirectSpawn or opts.spawnDirect then
		MI_CommitForcedPlayerModel(ply, mdl)
		MI_Log("玩家模型: " .. mdl .. " -> " .. ply:Nick())
		return true
	end

	MissionIntro.StripPlayerModelExtras(ply)

	local blank = MissionIntro.ModelResetBlank
	if ply:GetModel() ~= mdl and isstring(blank) and blank ~= "" and blank ~= mdl and util.IsValidModel(blank) then
		ply:SetModel(blank)
	end

	local function finishApply()
		if not IsValid(ply) or ply._missionIntroForcedModel ~= mdl then return end
		MI_CommitForcedPlayerModel(ply, mdl)
	end

	timer.Simple(0, finishApply)
	timer.Simple(0.12, finishApply)

	MI_Log("玩家模型(已清旧模): " .. mdl .. " -> " .. ply:Nick())
	return true
end

hook.Add("PlayerSetModel", "MissionIntro_ForceModel", function(ply)
	if not MissionIntro.ShouldKeepForcedModel or not MissionIntro.ShouldKeepForcedModel(ply) then return end

	local mdl = ply._missionIntroForcedModel
	if isstring(mdl) and mdl ~= "" and util.IsValidModel(mdl) then
		MissionIntro.ClearPlayerMaterialOverrides(ply)
		timer.Simple(0, function()
			if not IsValid(ply) then return end
			if MissionIntro.ApplyCachedPlayerModelVisuals then
				MissionIntro.ApplyCachedPlayerModelVisuals(ply)
			end
			if MissionIntro.ScheduleHammerfallClothesColorApply then
				MissionIntro.ScheduleHammerfallClothesColorApply(ply)
			end
			if MissionIntro.SafeSetupHands then
				MissionIntro.SafeSetupHands(ply)
			end
		end)
		return mdl
	end
end)

hook.Add("Think", "MissionIntro_KeepHammerfallBodygroups", function()
	for _, ply in ipairs(player.GetAll()) do
		if not MissionIntro.ShouldKeepForcedModel or not MissionIntro.ShouldKeepForcedModel(ply) then continue end
		if not ply._missionIntroForcedBodygroups then continue end

		local nextAt = ply._missionIntroBodygroupKeepAt or 0
		if CurTime() < nextAt then continue end
		ply._missionIntroBodygroupKeepAt = CurTime() + 0.35

		if MissionIntro.ApplyCachedPlayerModelVisuals then
			MissionIntro.ApplyCachedPlayerModelVisuals(ply)
		end
	end
end)

function MissionIntro.ShouldKeepForcedModel(ply)
	if not IsValid(ply) then return false end
	if MissionIntro.ShouldMissionIntroForcePlayerModels
		and not MissionIntro.ShouldMissionIntroForcePlayerModels() then
		return false
	end
	if not isstring(ply._missionIntroForcedModel) or ply._missionIntroForcedModel == "" then return false end
	if MissionIntro.IsPlaying and MissionIntro.IsPlaying(ply) then return true end
	if MissionIntro.IsFacilitySpawnPlayer and MissionIntro.IsFacilitySpawnPlayer(ply)
		and istable(ply._missionIntroForcedBodygroups) then
		return true
	end
	return ply._missionIntroApplyForcedOnSpawn == true
end

hook.Add("PlayerSpawn", "MissionIntro_FacilityHolsterSpy", function(ply)
	if MissionIntro.ShouldRunHeavyPlayerSpawnHooks and not MissionIntro.ShouldRunHeavyPlayerSpawnHooks(ply) then
		return
	end
	if not MissionIntro.ShouldDeferFacilityWeaponDraw or not MissionIntro.ShouldDeferFacilityWeaponDraw(ply) then
		return
	end
	if MissionIntro.ScheduleFacilityWeaponHolster then
		MissionIntro.ScheduleFacilityWeaponHolster(ply, { 0, 0.12, 0.3 })
	end
end)

hook.Add("PlayerSpawn", "MissionIntro_ForceModel", function(ply)
	if MissionIntro.ShouldRunHeavyPlayerSpawnHooks and not MissionIntro.ShouldRunHeavyPlayerSpawnHooks(ply) then
		return
	end
	if not MissionIntro.ShouldKeepForcedModel(ply) then
		if ply._missionIntroForcedModel then
			MissionIntro.ClearForcedPlayerModel(ply)
		end
		return
	end

	local mdl = ply._missionIntroForcedModel
	ply._missionIntroApplyForcedOnSpawn = nil

	timer.Simple(0, function()
		if not IsValid(ply) or not MissionIntro.ShouldKeepForcedModel(ply) then return end
		if not isstring(mdl) or mdl == "" then return end

		if MissionIntro.ShouldDirectApplyForcedModel and MissionIntro.ShouldDirectApplyForcedModel(ply) then
			MI_CommitForcedPlayerModel(ply, mdl)
			return
		end

		if MissionIntro.ApplyForcedPlayerModel then
			MissionIntro.ApplyForcedPlayerModel(ply)
		end
	end)
end)

hook.Add("PlayerDeath", "MissionIntro_ClearForcedModel", function(ply)
	MissionIntro.ClearForcedPlayerModel(ply)
end)

local MI_RoundClearHooks = {
	"RoundStart",
	"Breach_NewRound",
	"OnNewRound",
	"HMCD_NewRound",
	"HomigradRoundStart",
	"ZB_PreRoundStart",
}

for _, hookName in ipairs(MI_RoundClearHooks) do
	hook.Add(hookName, "MissionIntro_ClearForcedModel", function()
		local upcoming = MissionIntro.GetZCityUpcomingMode and MissionIntro.GetZCityUpcomingMode() or ""
		-- hmcd→hmcd 等同模式：跳过全员 ClearPlayerMissionIntroState（重逻辑且易与 HMCD 开局冲突）
		if hookName == "ZB_PreRoundStart"
			and MissionIntro.ShouldRunFacilityScpRoundMaintenance
			and not MissionIntro.ShouldRunFacilityScpRoundMaintenance(upcoming) then
			local current = MissionIntro.GetZCityRoundMode and MissionIntro.GetZCityRoundMode() or ""
			if upcoming == current or upcoming == "" then
				return
			end
		end

		if MissionIntro.StopUiuComputerMission then
			MissionIntro.StopUiuComputerMission()
		end

		for _, ply in ipairs(player.GetAll()) do
			MissionIntro.ClearForcedPlayerModel(ply)
			if MissionIntro.ClearPlayerMissionIntroState then
				MissionIntro.ClearPlayerMissionIntroState(ply)
			end
		end
	end)
end



function MissionIntro.GiveRewards(ply)

	if not SERVER then return false end

	if not IsValid(ply) or not ply:IsPlayer() then return false end

	if MissionIntro.HasGivenIntroReward and MissionIntro.HasGivenIntroReward(ply) then
		return false
	end

	if hook.Run("MissionIntro_GiveRewards", ply) == true then
		if MissionIntro.MarkIntroRewardGiven then
			MissionIntro.MarkIntroRewardGiven(ply)
		end
		return true
	end



	local R = MissionIntro.GetFactionRewards and MissionIntro.GetFactionRewards(ply) or MissionIntro.Rewards
	if MissionIntro.GetStoredFacilityFactionId and MissionIntro.GetStoredFacilityFactionId(ply) == "ci_spy" and MissionIntro.GetCiSpyDisguiseRewardTable then
		local disguiseR = MissionIntro.GetCiSpyDisguiseRewardTable(ply)
		if istable(disguiseR) then
			R = disguiseR
		end
	end

	if not istable(R) then return false end

	local facId = MissionIntro.GetRewardProfileId and MissionIntro.GetRewardProfileId(ply)
		or (MissionIntro.GetFactionId and MissionIntro.GetFactionId(ply)) or "?"

	local liveFac = MissionIntro.GetFactionId and MissionIntro.GetFactionId(ply) or ""
	local isFacilityQrf = MissionIntro.IsFacilityQrfFactionId and MissionIntro.IsFacilityQrfFactionId(liveFac)
	if liveFac ~= ""
		and (not MissionIntro.PlayerIsFacilityScpForWeapons or not MissionIntro.PlayerIsFacilityScpForWeapons(ply))
		and (
			(isFacilityQrf == true)
			or (
				MissionIntro.Factions and MissionIntro.Factions[liveFac]
				and (not MissionIntro.IsFacilityFactionId or not MissionIntro.IsFacilityFactionId(liveFac))
			)
		) then
		ply:StripWeapons()
	end

	local count = tonumber(R.ammo_count) or 60

	local wepClass = R.weapon

	local okWep, okAmmo, okGear, okExtra, okModel = false, false, false, false, false

	if MissionIntro.ApplyForcedPlayerModel then
		okModel = MissionIntro.ApplyForcedPlayerModel(ply, { sync = true }) == true
	end

	if isstring(wepClass) and wepClass ~= "" then

		local given = (MissionIntro.GivePlayerWeapon or ply.Give)(ply, wepClass)

		if IsValid(given) or IsValid(ply:GetWeapon(wepClass)) then

			local autoSelect = R.auto_select_weapon ~= false
			if MissionIntro.ShouldDeferFacilityWeaponDraw and MissionIntro.ShouldDeferFacilityWeaponDraw(ply) then
				autoSelect = false
			end
			if autoSelect then
				ply:SelectWeapon(wepClass)
			end

			okWep = true

			MI_Log("[" .. facId .. "] 武器: " .. wepClass .. " -> " .. ply:Nick())

		else

			MI_Log("[" .. facId .. "] 武器失败(类名可能不存在?): " .. wepClass)

		end

	end



	if okWep and MI_GiveAmmoToWeapon(ply, wepClass, count) then

		okAmmo = true

		MI_Log("[" .. facId .. "] 武器备弹 x" .. count)

	end



	if not okAmmo and isstring(R.ammo_entity) and R.ammo_entity ~= "" then

		local ammoBoxes = math.max(1, math.floor(tonumber(R.ammo_entity_count) or 1))
		local perBox = math.max(1, math.floor(tonumber(R.ammo_count) or count or 1))
		local entOk, err = false, nil

		for _ = 1, ammoBoxes do
			local oneOk, oneErr = MI_GiveAmmoEntity(ply, R.ammo_entity, perBox)
			entOk = entOk or oneOk
			err = err or oneErr
		end

		if entOk then

			timer.Simple(0.15, function()

				if not IsValid(ply) then return end

				if MI_GiveAmmoToWeapon(ply, wepClass, count) then

					MI_Log("[" .. facId .. "] 弹药实体后备弹 x" .. count)

				elseif MI_GiveAmmoByName(ply, count, R.ammo_types) then

					MI_Log("[" .. facId .. "] 弹药实体后备 GiveAmmo x" .. count)

				end

			end)

			okAmmo = true

			MI_Log("[" .. facId .. "] 弹药盒: " .. R.ammo_entity)

		else

			MI_Log(err or ("[" .. facId .. "] 弹药失败: " .. R.ammo_entity))

		end

	end



	if not okAmmo then

		local fbOk, typ = MI_GiveAmmoByName(ply, count, R.ammo_types)

		if fbOk then

			okAmmo = true

			MI_Log("[" .. facId .. "] GiveAmmo(" .. typ .. ") x" .. count)

		end

	end



	okGear = MI_GiveEquipment(ply, MI_FilterEquipmentForPlayer(ply, R.equipment))

	local mergedExtra = {}
	if istable(R.extra_weapons) then
		for _, class in ipairs(R.extra_weapons) do
			mergedExtra[#mergedExtra + 1] = class
		end
	end
	if MissionIntro.GetBonusExtraWeaponsForPlayer then
		for _, class in ipairs(MissionIntro.GetBonusExtraWeaponsForPlayer(ply)) do
			mergedExtra[#mergedExtra + 1] = class
		end
	end
	okExtra = MI_GiveExtraWeapons(ply, mergedExtra)

	if MissionIntro.GiveRoleKeycard and MissionIntro.GiveRoleKeycard(ply) then
		okExtra = true
	end

	if istable(R) then
		MissionIntro.CacheForcedPlayerModelVisuals(ply, R)
		MissionIntro.ReapplyForcedPlayerBodygroups(ply)
	end

	local okSecondary = false
	local secClass = R.secondary_weapon
	if isstring(secClass) and secClass ~= "" then
		local secGiven = (MissionIntro.GivePlayerWeapon or ply.Give)(ply, secClass)
		if IsValid(secGiven) or IsValid(ply:GetWeapon(secClass)) then
			okSecondary = true
			MI_Log("[" .. facId .. "] 副武器: " .. secClass .. " -> " .. ply:Nick())
		else
			MI_Log("[" .. facId .. "] 副武器失败(类名可能不存在?): " .. secClass)
		end

		local secCount = tonumber(R.secondary_ammo_count) or 30
		if MI_GiveAmmoToWeapon(ply, secClass, secCount) then
			okSecondary = true
		elseif isstring(R.secondary_ammo_entity) and R.secondary_ammo_entity ~= "" then
			local secEntOk = MI_GiveAmmoEntity(ply, R.secondary_ammo_entity, secCount)
			if secEntOk then
				timer.Simple(0.2, function()
					if not IsValid(ply) then return end
					MI_GiveAmmoToWeapon(ply, secClass, secCount)
					MI_GiveAmmoByName(ply, secCount, R.secondary_ammo_types)
				end)
				okSecondary = true
			end
		elseif MI_GiveAmmoByName(ply, secCount, R.secondary_ammo_types) then
			okSecondary = true
		end
	end

	if MissionIntro.ScheduleFacilityWeaponHolster then
		MissionIntro.ScheduleFacilityWeaponHolster(ply)
	end

	if MissionIntro.GetStoredFacilityFactionId and MissionIntro.GetStoredFacilityFactionId(ply) == "ci_spy" and MissionIntro.RefreshCiSpyPlayerVisuals then
		MissionIntro.RefreshCiSpyPlayerVisuals(ply, { sync = true })
	end

	local ok = okWep or okAmmo or okGear or okExtra or okSecondary or okModel
	if ok and MissionIntro.MarkIntroRewardGiven then
		MissionIntro.MarkIntroRewardGiven(ply)
	end

	if MissionIntro.SyncHudRoleDisplay then
		timer.Simple(0, function()
			if IsValid(ply) then
				MissionIntro.SyncHudRoleDisplay(ply)
			end
		end)
	end

	if MissionIntro.ShouldApplySpawnArmor and MissionIntro.ShouldApplySpawnArmor(ply) then
		if MissionIntro.RefreshSpawnArmorForPlayer then
			MissionIntro.RefreshSpawnArmorForPlayer(ply, { resetFirst = true })
		else
			MissionIntro.TryApplySpawnArmorNow(ply)
			if MissionIntro.SchedulePlayerSpawnArmor then
				MissionIntro.SchedulePlayerSpawnArmor(ply)
			end
		end
	end

	if MissionIntro.SyncHammerfallScannerWeapon then
		MissionIntro.SyncHammerfallScannerWeapon(ply)
	end

	if MissionIntro.SyncNtfScannerWeapon then
		MissionIntro.SyncNtfScannerWeapon(ply)
	end

	return ok

end



concommand.Add("mission_intro_test_reward", function(ply)

	if IsValid(ply) and ply:IsPlayer() then
		if MissionIntro.ClearIntroRewardLock then
			MissionIntro.ClearIntroRewardLock(ply)
		end
		MissionIntro.GiveRewards(ply)

	elseif game.SinglePlayer() then

		local p = player.GetAll()[1]

		if IsValid(p) then

			MissionIntro.GiveRewards(p)

		end

	end

end)



if SERVER then
	local function MI_StripNightVisionAll()
		for _, ply in ipairs(player.GetAll()) do
			if MissionIntro.StripNightVisionFromPlayer then
				MissionIntro.StripNightVisionFromPlayer(ply)
			end
		end
	end

	hook.Add("PlayerSpawn", "MissionIntro_StripNightVision", function(ply)
		if MissionIntro.ShouldRunHeavyPlayerSpawnHooks and not MissionIntro.ShouldRunHeavyPlayerSpawnHooks(ply) then
			return
		end
		timer.Simple(0.5, function()
			if IsValid(ply) and MissionIntro.StripNightVisionFromPlayer then
				MissionIntro.StripNightVisionFromPlayer(ply)
			end
		end)
	end)

	hook.Add("PlayerSpawn", "MissionIntro_SyncHudRoleOnSpawn", function(ply)
		if not MissionIntro.SyncHudRoleDisplay then return end
		if MissionIntro.ShouldRunHeavyPlayerSpawnHooks and not MissionIntro.ShouldRunHeavyPlayerSpawnHooks(ply) then
			return
		end
		if MissionIntro.ShouldRunFacilityScpRoundMaintenance
			and not MissionIntro.ShouldRunFacilityScpRoundMaintenance()
			and not (MissionIntro.ShouldApplySpawnArmor and MissionIntro.ShouldApplySpawnArmor(ply)) then
			return
		end
		timer.Simple(0.25, function()
			if IsValid(ply) and ply:IsPlayer() and ply:Alive() then
				MissionIntro.SyncHudRoleDisplay(ply)
			end
		end)
	end)

	timer.Create("MissionIntro_StripNightVision", 4, 0, MI_StripNightVisionAll)

	concommand.Add("mission_intro_faction", function(ply, _, args)

		if not IsValid(ply) or not ply:IsPlayer() then return end

		if MissionIntro.CanManage and not MissionIntro.CanManage(ply) then return end



		local id = args[1] or ""
		local roleArg = args[2]

		if id == "sid_agent" then
			id = "sid_squad"
			roleArg = roleArg or "agent"
		elseif id == "sid_captain" then
			id = "sid_squad"
			roleArg = roleArg or "captain"
		elseif id == "sid_expert" then
			id = "sid_squad"
			roleArg = roleArg or "expert"
		elseif id == "uiu_tf_agent" then
			id = "uiu_taskforce"
			roleArg = roleArg or "agent"
		elseif id == "uiu_tf_captain" then
			id = "uiu_taskforce"
			roleArg = roleArg or "captain"
		elseif id == "uiu_tf_expert" then
			id = "uiu_taskforce"
			roleArg = roleArg or "expert"
		elseif id == "uiu_tf_suppressor" then
			id = "uiu_taskforce"
			roleArg = roleArg or "suppressor"
		elseif id == "uiu_tf_infiltrator" then
			id = "uiu_taskforce"
			roleArg = roleArg or "infiltrator"
		end

		if id == "" or id == "list" then

			ply:ChatPrint("[MissionIntro] 阵营: scarlet_cultist, hammerfall_squad, sid_squad, uiu_taskforce, pttrb_squad")
			ply:ChatPrint("[MissionIntro] 猩红职业: bishop(主教), flock(教众), heretic(恶教徒)")
			ply:ChatPrint("[MissionIntro] 例: mission_intro_faction scarlet_cultist heretic")
			ply:ChatPrint("[MissionIntro] 落锤职业: soldier, medic, sniper, assault, commander, heavy(重装)")
			ply:ChatPrint("[MissionIntro] 维修小队(最多3人/批): maintenance_expert(维修专家)")
			ply:ChatPrint("[MissionIntro] 例: mission_intro_faction hammerfall_maintenance maintenance_expert")
			ply:ChatPrint("[MissionIntro] 例: mission_intro_faction hammerfall_squad commander")
			ply:ChatPrint("[MissionIntro] 例: mission_intro_faction hammerfall_squad heavy")
			ply:ChatPrint("[MissionIntro] 特异事故处职业: agent(特工), captain(队长), expert(战斗专家)")
			ply:ChatPrint("[MissionIntro] 例: mission_intro_faction sid_squad expert")
			ply:ChatPrint("[MissionIntro] FBI编队 uiu_taskforce: agent, captain, expert, suppressor(压制者), infiltrator(渗透者)")
			ply:ChatPrint("[MissionIntro] 例: mission_intro_faction uiu_taskforce infiltrator")
			ply:ChatPrint("[MissionIntro] ETT 每批最多 3 人：leader(组长), medic(医疗), operative(组员)")
			ply:ChatPrint("[MissionIntro] 例: mission_intro_faction pttrb_squad medic")
			ply:ChatPrint("[MissionIntro] CI 职业: soldier, commander, antitank(恶魔), trap_expert(诡雷专家), heavy(重装)")
			ply:ChatPrint("[MissionIntro] VDV 职业: soldier, commander, antitank, sniper, heavy(重装)")
			ply:ChatPrint("[MissionIntro] 例: mission_intro_faction ci_squad heavy")
			ply:ChatPrint("[MissionIntro] 例: mission_intro_faction vdv_squad sniper")
			ply:ChatPrint("[MissionIntro] 例: mission_intro_faction goc_squad soldier")
			ply:ChatPrint("[MissionIntro] 例: mission_intro_faction goc_squad heavy")
			ply:ChatPrint("[MissionIntro] 例: mission_intro_faction goc_squad commander")
			ply:ChatPrint("[MissionIntro] 九尾狐 ntf_squad: soldier(士兵), combat_expert(战斗专家), sniper(狙击手), commander(指挥官)")
			ply:ChatPrint("[MissionIntro] 例: mission_intro_faction ntf_squad commander")

			return

		end



		if not MissionIntro.Factions[id] then

			ply:ChatPrint("[MissionIntro] 未知阵营: " .. id)

			return

		end



		ply._missionIntroFaction = id

		if id == "scarlet_cultist" and MissionIntro.NormalizeScarletRole then
			if MissionIntro.ClearHammerfallRole then
				MissionIntro.ClearHammerfallRole(ply)
			end
			if MissionIntro.ClearSidRole then
				MissionIntro.ClearSidRole(ply)
			end
			if MissionIntro.ClearPttrbRole then
				MissionIntro.ClearPttrbRole(ply)
			end
			local role = MissionIntro.NormalizeScarletRole(args[2] or "bishop")
			if role == "heretic" then
				local minN = tonumber(MissionIntro.ScarletHereticMinPlayers) or 4
				local alive = 0
				for _, p in ipairs(player.GetAll()) do
					if IsValid(p) and p:IsPlayer() and p:Alive() then
						alive = alive + 1
					end
				end
				if alive < minN then
					ply:ChatPrint("[MissionIntro] 恶教徒需要场上至少 " .. minN .. " 名存活玩家")
					return
				end
			end
			MissionIntro.AssignScarletRole(ply, role)
			ply:ChatPrint("[MissionIntro] 已设为阵营: " .. id .. " / 职业: " .. role)
		elseif id == "hammerfall_squad" and MissionIntro.AssignHammerfallRole then
			if MissionIntro.ClearScarletRole then
				MissionIntro.ClearScarletRole(ply)
			end
			if MissionIntro.ClearSidRole then
				MissionIntro.ClearSidRole(ply)
			end
			if MissionIntro.ClearPttrbRole then
				MissionIntro.ClearPttrbRole(ply)
			end
			if MissionIntro.ClearCiRole then
				MissionIntro.ClearCiRole(ply)
			end
			if MissionIntro.ClearMcdRole then
				MissionIntro.ClearMcdRole(ply)
			end
			local role = MissionIntro.NormalizeHammerfallRole(args[2] or "soldier")
			MissionIntro.AssignHammerfallRole(ply, role)
			ply._missionIntroFaction = "hammerfall_squad"
			if MissionIntro.ApplyForcedPlayerModel then
				MissionIntro.ApplyForcedPlayerModel(ply, { sync = true })
			end
			ply:ChatPrint("[MissionIntro] 已设为阵营: " .. id .. " / 职业: " .. role)
		elseif id == "hammerfall_maintenance" and MissionIntro.AssignHammerfallMaintenanceRole then
			if MissionIntro.ClearScarletRole then MissionIntro.ClearScarletRole(ply) end
			if MissionIntro.ClearHammerfallRole then MissionIntro.ClearHammerfallRole(ply) end
			if MissionIntro.ClearSidRole then MissionIntro.ClearSidRole(ply) end
			if MissionIntro.ClearPttrbRole then MissionIntro.ClearPttrbRole(ply) end
			if MissionIntro.ClearCiRole then MissionIntro.ClearCiRole(ply) end
			if MissionIntro.ClearMcdRole then MissionIntro.ClearMcdRole(ply) end
			local role = MissionIntro.NormalizeHammerfallMaintenanceRole(args[2] or "maintenance_expert")
			MissionIntro.AssignHammerfallMaintenanceRole(ply, role)
			ply._missionIntroFaction = "hammerfall_maintenance"
			if MissionIntro.ApplyForcedPlayerModel then
				MissionIntro.ApplyForcedPlayerModel(ply, { sync = true })
			end
			ply:ChatPrint("[MissionIntro] 已设为阵营: " .. id .. " / 职业: " .. role)
		elseif id == "sid_squad" and MissionIntro.AssignSidRole then
			if MissionIntro.ClearScarletRole then
				MissionIntro.ClearScarletRole(ply)
			end
			if MissionIntro.ClearHammerfallRole then
				MissionIntro.ClearHammerfallRole(ply)
			end
			if MissionIntro.ClearPttrbRole then
				MissionIntro.ClearPttrbRole(ply)
			end
			local role = MissionIntro.NormalizeSidRole(roleArg or "agent")
			MissionIntro.AssignSidRole(ply, role)
			if MissionIntro.ApplyForcedPlayerModel then
				MissionIntro.ApplyForcedPlayerModel(ply, { sync = true })
			end
			ply:ChatPrint("[MissionIntro] 已设为阵营: " .. id .. " / 职业: " .. role)
		elseif id == "uiu_taskforce" and MissionIntro.AssignUiuTfRole then
			if MissionIntro.ClearScarletRole then
				MissionIntro.ClearScarletRole(ply)
			end
			if MissionIntro.ClearHammerfallRole then
				MissionIntro.ClearHammerfallRole(ply)
			end
			if MissionIntro.ClearSidRole then
				MissionIntro.ClearSidRole(ply)
			end
			if MissionIntro.ClearPttrbRole then
				MissionIntro.ClearPttrbRole(ply)
			end
			local role = MissionIntro.NormalizeUiuTfRole(roleArg or "agent")
			MissionIntro.AssignUiuTfRole(ply, role)
			ply._missionIntroFaction = "uiu_taskforce"
			if MissionIntro.ApplyForcedPlayerModel then
				MissionIntro.ApplyForcedPlayerModel(ply, { sync = true })
			end
			ply:ChatPrint("[MissionIntro] 已设为阵营: " .. id .. " / 职业: " .. role)
		elseif id == "pttrb_squad" and MissionIntro.AssignPttrbRole then
			if MissionIntro.ClearScarletRole then
				MissionIntro.ClearScarletRole(ply)
			end
			if MissionIntro.ClearHammerfallRole then
				MissionIntro.ClearHammerfallRole(ply)
			end
			if MissionIntro.ClearSidRole then
				MissionIntro.ClearSidRole(ply)
			end
			local role = MissionIntro.NormalizePttrbRole(roleArg or "leader")
			MissionIntro.AssignPttrbRole(ply, role)
			if MissionIntro.ApplyForcedPlayerModel then
				MissionIntro.ApplyForcedPlayerModel(ply, { sync = true })
			end
			ply:ChatPrint("[MissionIntro] 已设为阵营: " .. id .. " / 职业: " .. role)
		elseif id == "ci_squad" and MissionIntro.AssignCiRole then
			if MissionIntro.ClearScarletRole then MissionIntro.ClearScarletRole(ply) end
			if MissionIntro.ClearHammerfallRole then MissionIntro.ClearHammerfallRole(ply) end
			if MissionIntro.ClearSidRole then MissionIntro.ClearSidRole(ply) end
			if MissionIntro.ClearPttrbRole then MissionIntro.ClearPttrbRole(ply) end
			if MissionIntro.ClearMcdRole then MissionIntro.ClearMcdRole(ply) end
			if MissionIntro.ClearVdvRole then MissionIntro.ClearVdvRole(ply) end
			if MissionIntro.ClearGocRole then MissionIntro.ClearGocRole(ply) end
			local role = MissionIntro.NormalizeCiRole(roleArg or "soldier")
			MissionIntro.AssignCiRole(ply, role)
			if MissionIntro.ApplyForcedPlayerModel then
				MissionIntro.ApplyForcedPlayerModel(ply, { sync = true })
			end
			ply:ChatPrint("[MissionIntro] 已设为阵营: " .. id .. " / 职业: " .. role)
		elseif id == "vdv_squad" and MissionIntro.AssignVdvRole then
			if MissionIntro.ClearScarletRole then MissionIntro.ClearScarletRole(ply) end
			if MissionIntro.ClearHammerfallRole then MissionIntro.ClearHammerfallRole(ply) end
			if MissionIntro.ClearSidRole then MissionIntro.ClearSidRole(ply) end
			if MissionIntro.ClearPttrbRole then MissionIntro.ClearPttrbRole(ply) end
			if MissionIntro.ClearMcdRole then MissionIntro.ClearMcdRole(ply) end
			if MissionIntro.ClearCiRole then MissionIntro.ClearCiRole(ply) end
			if MissionIntro.ClearGocRole then MissionIntro.ClearGocRole(ply) end
			local role = MissionIntro.NormalizeVdvRole(roleArg or "soldier")
			MissionIntro.AssignVdvRole(ply, role)
			if MissionIntro.ApplyForcedPlayerModel then
				MissionIntro.ApplyForcedPlayerModel(ply, { sync = true })
			end
			ply:ChatPrint("[MissionIntro] 已设为阵营: " .. id .. " / 职业: " .. role)
		elseif id == "goc_squad" and MissionIntro.AssignGocRole then
			if MissionIntro.ClearScarletRole then MissionIntro.ClearScarletRole(ply) end
			if MissionIntro.ClearHammerfallRole then MissionIntro.ClearHammerfallRole(ply) end
			if MissionIntro.ClearSidRole then MissionIntro.ClearSidRole(ply) end
			if MissionIntro.ClearPttrbRole then MissionIntro.ClearPttrbRole(ply) end
			if MissionIntro.ClearMcdRole then MissionIntro.ClearMcdRole(ply) end
			if MissionIntro.ClearCiRole then MissionIntro.ClearCiRole(ply) end
			if MissionIntro.ClearVdvRole then MissionIntro.ClearVdvRole(ply) end
			local role = MissionIntro.NormalizeGocRole(roleArg or "soldier")
			MissionIntro.AssignGocRole(ply, role)
			if MissionIntro.ApplyForcedPlayerModel then
				MissionIntro.ApplyForcedPlayerModel(ply, { sync = true })
			end
			ply:ChatPrint("[MissionIntro] 已设为阵营: " .. id .. " / 职业: " .. role)
		elseif id == "ntf_squad" and MissionIntro.AssignNtfRole then
			if MissionIntro.ClearScarletRole then MissionIntro.ClearScarletRole(ply) end
			if MissionIntro.ClearHammerfallRole then MissionIntro.ClearHammerfallRole(ply) end
			if MissionIntro.ClearSidRole then MissionIntro.ClearSidRole(ply) end
			if MissionIntro.ClearPttrbRole then MissionIntro.ClearPttrbRole(ply) end
			if MissionIntro.ClearMcdRole then MissionIntro.ClearMcdRole(ply) end
			if MissionIntro.ClearCiRole then MissionIntro.ClearCiRole(ply) end
			if MissionIntro.ClearVdvRole then MissionIntro.ClearVdvRole(ply) end
			if MissionIntro.ClearGocRole then MissionIntro.ClearGocRole(ply) end
			local role = MissionIntro.NormalizeNtfRole(roleArg or "soldier")
			MissionIntro.AssignNtfRole(ply, role)
			if MissionIntro.ApplyForcedPlayerModel then
				MissionIntro.ApplyForcedPlayerModel(ply, { sync = true })
			end
			ply:ChatPrint("[MissionIntro] 已设为阵营: " .. id .. " / 职业: " .. role)
		else
			if MissionIntro.ClearScarletRole then
				MissionIntro.ClearScarletRole(ply)
			end
			if MissionIntro.ClearHammerfallRole then
				MissionIntro.ClearHammerfallRole(ply)
			end
			if MissionIntro.ClearSidRole then
				MissionIntro.ClearSidRole(ply)
			end
			if MissionIntro.ClearPttrbRole then
				MissionIntro.ClearPttrbRole(ply)
			end
			ply:ChatPrint("[MissionIntro] 已设为阵营: " .. id)
		end

	end)

	local function MI_PrintDumpLines(recipient, lines)
		for _, line in ipairs(lines or {}) do
			if not isstring(line) or line == "" then continue end
			if IsValid(recipient) and recipient:IsPlayer() then
				recipient:ChatPrint(line)
			else
				MsgN(line)
			end
		end
	end

	local function MI_FormatBodygroupMap(bodygroups)
		if not istable(bodygroups) then return "nil" end
		local parts = {}
		for id = 0, 15 do
			local value = bodygroups[id]
			if value ~= nil then
				parts[#parts + 1] = tostring(id) .. "=" .. tostring(value)
			end
		end
		if #parts == 0 then
			for id, value in pairs(bodygroups) do
				parts[#parts + 1] = tostring(id) .. "=" .. tostring(value)
			end
			table.sort(parts)
		end
		return table.concat(parts, " ")
	end

	concommand.Add("mission_intro_dump_bodygroups", function(ply)
		if IsValid(ply) and ply:IsPlayer() and MissionIntro.CanManage and not MissionIntro.CanManage(ply) then return end

		local targets = {}
		if IsValid(ply) and ply:IsPlayer() then
			targets[1] = ply
		else
			targets = player.GetAll()
		end

		for _, p in ipairs(targets) do
			if not IsValid(p) then continue end

			local fac = MissionIntro.GetFactionId and MissionIntro.GetFactionId(p) or "?"
			local facRole = p:GetNWString("MissionIntro_FacilityRole", "")
			local hammerRole = MissionIntro.GetHammerfallRole and MissionIntro.GetHammerfallRole(p) or "?"
			local lines = {
				string.format("[MissionIntro] %s", p:Nick()),
				string.format("  model=%s", p:GetModel() or "?"),
				string.format("  fac=%s facility_role=%s hammerfall=%s", fac, facRole ~= "" and facRole or "?", hammerRole),
			}

			if MissionIntro.GetFacilityBodygroupsForPlayer then
				local expected = MissionIntro.GetFacilityBodygroupsForPlayer(p)
				lines[#lines + 1] = "  expected=" .. MI_FormatBodygroupMap(expected)
			end

			if istable(p._missionIntroForcedBodygroups) then
				lines[#lines + 1] = "  forced=" .. MI_FormatBodygroupMap(p._missionIntroForcedBodygroups)
			end

			if istable(p._missionIntroFacilityBodygroups) then
				lines[#lines + 1] = "  facility=" .. MI_FormatBodygroupMap(p._missionIntroFacilityBodygroups)
			end

			for _, bg in ipairs(p:GetBodyGroups() or {}) do
				local bgId = tonumber(bg.id) or 0
				local bgName = tostring(bg.name or p:GetBodygroupName(bgId) or "?")
				if #bgName > 24 then
					bgName = string.sub(bgName, 1, 24) .. "…"
				end
				lines[#lines + 1] = string.format(
					"  BG%d (%s)=%d/%d",
					bgId,
					bgName,
					p:GetBodygroup(bgId),
					math.max(0, (p:GetBodygroupCount(bgId) or 1) - 1)
				)
				if istable(bg.submodels) then
					for subIdx = 0, #bg.submodels do
						local subName = tostring(bg.submodels[subIdx] or "")
						if subName ~= "" then
							lines[#lines + 1] = string.format("    [%d] %s", subIdx, subName)
						end
					end
				end
			end

			lines[#lines + 1] = string.format("  skin=%d/%d", p:GetSkin(), math.max(0, (p:SkinCount() or 1) - 1))

			MI_PrintDumpLines(IsValid(ply) and ply:IsPlayer() and ply or nil, lines)
		end
	end)

end


