local MODE = MODE

zb = zb or {}
zb.Points = zb.Points or {}

zb.Points.HMCD_TDM_CT = zb.Points.HMCD_TDM_CT or {}
zb.Points.HMCD_TDM_CT.Color = Color(0,0,150)
zb.Points.HMCD_TDM_CT.Name = "HMCD_TDM_CT"

zb.Points.HMCD_TDM_T = zb.Points.HMCD_TDM_T or {}
zb.Points.HMCD_TDM_T.Color = Color(150,95,0)
zb.Points.HMCD_TDM_T.Name = "HMCD_TDM_T"

MODE.PrintName = "团队死斗"

--[[
    ["weapon_hk_usp"] = {
        Type = "Weapon",
        Price = "600",
        Category = "Pistols",
        Attachments = {
            "supressor3", "supressor4"
        }
    },
]]

MODE.BuyItems = {}

local priority = 1
local function AddItemToBUY(ItemName, Type, ItemClass, Price, Category, Attachments, Amount, TeamBased)
    if not MODE.BuyItems[Category] then
        MODE.BuyItems[Category] = {}
        MODE.BuyItems[Category].Priority = priority
        priority = priority + 1
    end

    MODE.BuyItems[Category][ItemName] = {
        Type = Type,
        ItemClass = ItemClass,
        Price = Price,
        Category = Category,
        Attachments = Attachments,
        Amount = Amount,
        TeamBased = TeamBased,
    }
end
-- Weapons
AddItemToBUY( "HK-USP", "Weapon", "weapon_hk_usp", 500, "手枪", {"supressor3", "supressor4"} )
AddItemToBUY( "Glock-17", "Weapon", "weapon_glock17", 550, "手枪", {"supressor4", "holo16", "laser3", "laser1"} )
AddItemToBUY( "Glock-18C", "Weapon", "weapon_glock18c", 1400, "手枪", {"supressor4", "holo16", "laser3", "laser1"} )
AddItemToBUY( "Walter-P22", "Weapon", "weapon_p22", 300, "手枪", {"supressor4"} )
AddItemToBUY( "Desert Eagle", "Weapon", "weapon_deagle", 900, "手枪" )
AddItemToBUY( "MR-96", "Weapon", "weapon_revolver2", 750, "手枪", {"supressor4"} )
AddItemToBUY( "FNX-45", "Weapon", "weapon_fn45", 700, "手枪", {"supressor4", "holo16", "laser3", "laser1"} )
AddItemToBUY( "Colt M45A1", "Weapon", "weapon_m45", 450, "手枪", {} )
AddItemToBUY( "Colt M1911", "Weapon", "weapon_m1911", 400, "手枪", {} )
AddItemToBUY( "Browning Hi-Power", "Weapon", "weapon_browninghp", 700, "手枪", {} )
AddItemToBUY( "Beretta PX4", "Weapon", "weapon_px4beretta", 400, "手枪", {"supressor4"} )
AddItemToBUY( "PL-15", "Weapon", "weapon_pl15", 500, "手枪", {"supressor4"} )
AddItemToBUY( "ČZ 75", "Weapon", "weapon_cz75", 500, "手枪", {"supressor4"} )
AddItemToBUY( "柯尔特王蛇", "Weapon", "weapon_revolver357", 800, "手枪", {} )

AddItemToBUY( "Ruger 10/22", "Weapon", "weapon_ruger", 1000, "卡宾枪", {} )
AddItemToBUY( "Mini-14", "Weapon", "weapon_mini14", 2200, "卡宾枪", {} )

AddItemToBUY( "AKM", "Weapon", "weapon_akm", 3200, "突击步枪", {"holo6","holo1","holo2","supressor1","optic7"}, nil, 0 )--0 = terrorist, 1 = swat
AddItemToBUY( "M4A1", "Weapon", "weapon_m4a1", 2700, "突击步枪", {"holo1","holo2","supressor2","holo15","optic8"}, nil, 1 )
AddItemToBUY( "HK416", "Weapon", "weapon_hk416", 3000, "突击步枪", {"holo1","holo2","supressor2","holo15","optic8"}, nil, 1 )
AddItemToBUY( "AK-74", "Weapon", "weapon_ak74", 2400, "突击步枪", {"holo6","holo1","holo2","supressor1","supressor8","optic7"}, nil, 0 )

AddItemToBUY( "MP-5", "Weapon", "weapon_mp5", 1500, "冲锋枪", {"supressor4"} )
AddItemToBUY( "MP-7", "Weapon", "weapon_mp7", 2300, "冲锋枪", {"holo1","holo2","supressor2","holo15"} )
AddItemToBUY( "MAC-11", "Weapon", "weapon_mac11", 1600, "冲锋枪", {"supressor4"}, nil, 0 )
AddItemToBUY( "Uzi", "Weapon", "weapon_uzi", 1300, "冲锋枪", {}, nil, 0 )
AddItemToBUY( "KRISS Vector", "Weapon", "weapon_vector", 2300, "冲锋枪", {"holo1", "holo2", "supressor4", "holo15"}, nil, 1 )
AddItemToBUY( "P90", "Weapon", "weapon_p90", 2300, "冲锋枪", {"holo1", "holo2", "supressor4", "holo15"}, nil, 1 )
AddItemToBUY( "Steyr TMP", "Weapon", "weapon_tmp", 2100, "冲锋枪", {"holo1", "holo2", "supressor4", "holo15"}, nil, 1 )
AddItemToBUY( "Šcorpion vz. 61", "Weapon", "weapon_skorpion", 1200, "冲锋枪", {}, nil, 0 )

AddItemToBUY( "\"猎鹿人\"弓", "Weapon", "weapon_hg_bow", 2000, "特殊武器", {} )

AddItemToBUY( "Remington-870", "Weapon", "weapon_remington870", 1700, "霰弹枪", {"holo1","holo2","supressor5","holo15"} )
AddItemToBUY( "SPAS-12", "Weapon", "weapon_spas12", 2200, "霰弹枪", {"supressor5"} )
AddItemToBUY( "Sawed-off IZh-43", "Weapon", "weapon_doublebarrel_short", 800, "霰弹枪", {}, nil, 0 )
AddItemToBUY( "IZh-43", "Weapon", "weapon_doublebarrel", 1100, "霰弹枪", {}, nil, 0 )
AddItemToBUY( "XM-1014", "Weapon", "weapon_xm1014", 2300, "霰弹枪", {"holo14", "holo3"} )

AddItemToBUY( "M249", "Weapon", "weapon_m249", 5750, "重武器", {"holo1","holo2","supressor2","holo15"} )
AddItemToBUY( "M60", "Weapon", "weapon_m60", 7000, "重武器", {} )
AddItemToBUY( "PKM", "Weapon", "weapon_pkm", 7800, "重武器", {"optic4"} )
AddItemToBUY( "RPK-74", "Weapon", "weapon_rpk", 3700, "重武器", {"optic4", "holo6", "holo13", "holo14", "holo6fur"} )

AddItemToBUY( "SR-25", "Weapon", "weapon_sr25", 5500, "射手/狙击", {"supressor7","optic6", "optic2", "grip2"} , nil, 1)
AddItemToBUY( "Karabiner 98k", "Weapon", "weapon_kar98", 2100, "射手/狙击", {"optic12"} )
AddItemToBUY( "SKS", "Weapon", "weapon_sks", 2900, "射手/狙击", {"optic4"}, nil, 0 )
AddItemToBUY( "SVD", "Weapon", "weapon_svd", 5200, "射手/狙击", {"optic4"}, nil, 0 )
AddItemToBUY( "Barrett M98B", "Weapon", "weapon_m98b", 4200, "射手/狙击", {} )

-- Armor
AddItemToBUY( "IIIA 级防弹衣", "Armor", "ent_armor_vest3", 450, "装备", {} )
AddItemToBUY( "III 级防弹衣", "Armor", "ent_armor_vest4", 650, "装备", {} )
AddItemToBUY( "IV 级防弹衣", "Armor", "ent_armor_vest1", 1000, "装备", {} )
AddItemToBUY( "III 级 ACH 头盔", "Armor", "ent_armor_helmet1", 350, "装备", {} )
AddItemToBUY( "防弹面具", "Armor", "ent_armor_mask1", 650, "装备", {} )

-- Other Shit
AddItemToBUY( "NVG-GPNVG-18", "Armor", "ent_armor_nightvision1", 450, "装备", {} )
AddItemToBUY( "手电筒", "Armor", "hg_flashlight", 250, "装备", {} )

-- Melee 
AddItemToBUY( "砍刀", "Weapon", "weapon_hg_machete", 300, "近战", {}, nil, 0 )
AddItemToBUY( "短柄斧", "Weapon", "weapon_hatchet", 300, "近战", {}, nil, 0 )
AddItemToBUY( "战斧", "Weapon", "weapon_tomahawk", 300, "近战", {}, nil, 1 )
AddItemToBUY( "警用警棍", "Weapon", "weapon_hg_tonfa", 100, "近战", {}, nil, 1 )
AddItemToBUY( "攻城锤", "Weapon", "weapon_ram", 100, "近战", {}, nil, 1 )

-- Medical
AddItemToBUY( "绷带", "Weapon", "weapon_bandage_sh", 200, "医疗", {} )
AddItemToBUY( "大绷带", "Weapon", "weapon_bigbandage_sh", 400, "医疗", {} )
AddItemToBUY( "医疗包", "Weapon", "weapon_medkit_sh", 650, "医疗", {} )
AddItemToBUY( "止血带", "Weapon", "weapon_tourniquet", 150, "医疗", {} )
AddItemToBUY( "止痛药", "Weapon", "weapon_painkillers", 200, "医疗", {} )
AddItemToBUY( "吗啡", "Weapon", "weapon_morphine", 1000, "医疗", {} )
AddItemToBUY( "芬太尼", "Weapon", "weapon_fentanyl", 2000, "医疗", {} )
AddItemToBUY( "肾上腺素注射器", "Weapon", "weapon_adrenaline", 800, "医疗", {} )
AddItemToBUY( "血袋", "Weapon", "weapon_bloodbag", 400, "医疗", {} )
AddItemToBUY( "甘露醇", "Weapon", "weapon_mannitol", 300, "医疗", {} )
AddItemToBUY( "纳洛酮", "Weapon", "weapon_naloxone", 100, "医疗", {} )
AddItemToBUY( "减压针", "Weapon", "weapon_needle", 50, "医疗", {} )
AddItemToBUY( "β-阻滞剂", "Weapon", "weapon_betablock", 250, "医疗", {} )

-- Explosive
AddItemToBUY( "M67 手雷", "Weapon", "weapon_hg_grenade_tpik", 500, "爆炸物", {} )
AddItemToBUY( "RGD-5 手雷", "Weapon", "weapon_hg_rgd_tpik", 450, "爆炸物", {} )
AddItemToBUY( "闪光弹", "Weapon", "weapon_hg_flashbang_tpik", 250, "爆炸物", {} )

--Ammo
AddItemToBUY( "7.62x39mm (30)", "Ammo", "ent_ammo_7.62x39mm", 100, "弹药", {}, 30)
AddItemToBUY( "7.62x39mm BP (30)", "Ammo", "ent_ammo_7.62x39mmbp", 300, "弹药", {}, 30)
AddItemToBUY( "7.62x39mm SP (30)", "Ammo", "ent_ammo_7.62x39mmsp", 150, "弹药", {}, 30)

AddItemToBUY( "7.62x54mm (20)", "Ammo", "ent_ammo_7.62x54mm", 100, "弹药", {}, 20)

AddItemToBUY( "7.62x51mm (20)", "Ammo", "ent_ammo_7.62x51mm", 150, "弹药", {}, 20)
AddItemToBUY( "7.62x51mm M993 (20)", "Ammo", "ent_ammo_7.62x51mmm993", 300, "弹药", {}, 20)

AddItemToBUY( ".338 Lapua Magnum (20)", "Ammo", "ent_ammo_.338lapuamagnum", 350, "弹药", {}, 20)

AddItemToBUY( "9x19mm (30)", "Ammo", "ent_ammo_9x19mmparabellum", 75, "弹药", {}, 30)
AddItemToBUY( "9x19mm Green Tracer (30)", "Ammo", "ent_ammo_9x19mmgreentracer", 100, "弹药", {}, 30)
AddItemToBUY( "9x19mm QuakeMaker (30)", "Ammo", "ent_ammo_9x19mmqm", 150, "弹药", {}, 30)
AddItemToBUY( "9x17mm (30)", "Ammo", "ent_ammo_9x17mm", 75, "弹药", {}, 30)
AddItemToBUY( "7.65x17mm (30)", "Ammo", "ent_ammo_7.65x17mm", 75, "弹药", {}, 30)

AddItemToBUY( "5.56x45mm (30)", "Ammo", "ent_ammo_5.56x45mm", 100, "弹药", {}, 30)
AddItemToBUY( "5.56x45mm AP (30)", "Ammo", "ent_ammo_5.56x45mmap", 200, "弹药", {}, 30)
AddItemToBUY( "5.56x45mm M856 (30)", "Ammo", "ent_ammo_5.56x45mmm856", 150, "弹药", {}, 30)

AddItemToBUY( "5.45x39mm (30)", "Ammo", "ent_ammo_5.45x39mm", 100, "弹药", {}, 30)

AddItemToBUY( "4.6x30mm (30)", "Ammo", "ent_ammo_4.6x30mm", 100, "弹药", {}, 30)

AddItemToBUY( "5.7x28mm (30)", "Ammo", "ent_ammo_5.7x28mm", 100, "弹药", {}, 30)

AddItemToBUY( "12/70 Gauge (12)", "Ammo", "ent_ammo_12/70gauge", 100, "弹药", {}, 12)
AddItemToBUY( "12/70 Beanbag (12)", "Ammo", "ent_ammo_12/70beanbag", 25, "弹药", {}, 12)
AddItemToBUY( "12/70 RIP (12)", "Ammo", "ent_ammo_12/70rip", 250, "弹药", {}, 12)
AddItemToBUY( "12/70 Slug (12)", "Ammo", "ent_ammo_12/70slug", 150, "弹药", {}, 12)

AddItemToBUY( ".22 Long Rifle (60)", "Ammo", "ent_ammo_.22longrifle", 50, "弹药", {}, 60)

AddItemToBUY( ".45 ACP (30)", "Ammo", "ent_ammo_.45acp", 75, "弹药", {}, 30)
AddItemToBUY( ".45 ACP Hydro-Shock (30)", "Ammo", "ent_ammo_.45acphydroshock", 125, "弹药", {}, 30)

AddItemToBUY( ".50 Action Express (20)", "Ammo", "ent_ammo_.50actionexpress", 75, "弹药", {}, 20)
AddItemToBUY( ".50 Action Express Copper (20)", "Ammo", "ent_ammo_.50actionexpresscopper", 100, "弹药", {}, 20)
AddItemToBUY( ".50 Action Express JHP (20)", "Ammo", "ent_ammo_.50actionexpressjhp", 100, "弹药", {}, 20)

AddItemToBUY( ".357 Magnum (20)", "Ammo", "ent_ammo_.357magnum", 75, "弹药", {}, 20)
AddItemToBUY( ".38 Special (20)", "Ammo", "ent_ammo_.38special", 75, "弹药", {}, 20)
AddItemToBUY( ".40 Smith & Wesson (30)", "Ammo", "ent_ammo_.40sw", 75, "弹药", {}, 30)
AddItemToBUY( ".44 Remington Magnum (20)", "Ammo", "ent_ammo_.44remingtonmagnum", 75, "弹药", {}, 20)

AddItemToBUY( "Arrow", "Ammo", "ent_ammo_arrow", 25, "弹药", {}, 5)

function MODE:HG_MovementCalc_2( mul, ply, cmd, mv )
    if (zb.ROUND_START or 0) + 20 > CurTime() and cmd then
        cmd:RemoveKey(IN_ATTACK)
        cmd:RemoveKey(IN_FORWARD)
        cmd:RemoveKey(IN_BACK)
        cmd:RemoveKey(IN_MOVELEFT)
        cmd:RemoveKey(IN_MOVERIGHT)

        if mv then
            mv:RemoveKey(IN_ATTACK)
            mv:RemoveKey(IN_FORWARD)
            mv:RemoveKey(IN_BACK)
            mv:RemoveKey(IN_MOVELEFT)
            mv:RemoveKey(IN_MOVERIGHT)
        end

        if IsValid(ply) and IsValid(ply:GetWeapon("weapon_hands_sh")) then
            cmd:SelectWeapon(ply:GetWeapon("weapon_hands_sh"))
            if SERVER then ply:SelectWeapon("weapon_hands_sh") end
        end
        
        mul[1] = 0
    end
end

function MODE:PlayerCanLegAttack( ply )
	if zb.CROUND == "dm" and (zb.ROUND_START or 0) + 20 > CurTime() then
		return false
	end
end