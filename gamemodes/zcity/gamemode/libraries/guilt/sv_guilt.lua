-- СДЕЛАЙТЕ СИНХРУ С СКУЭЛЬ УЖЕ // ЛАДНО Я САМ СДЕЛАЮ
zb = zb or {}

zb.GuiltTable = zb.GuiltTable or {}
zb.HarmDone = zb.HarmDone or {}
zb.HarmDoneKarma = zb.HarmDoneKarma or {}
zb.HarmDoneDetailed = zb.HarmDoneDetailed or {}
zb.HarmAttacked = zb.HarmAttacked or {}
zb.GuiltSQL = zb.GuiltSQL or {}
zb.GuiltSQL.PlayerInstances = zb.GuiltSQL.PlayerInstances or {}

local hg_developer = ConVarExists("hg_developer") and GetConVar("hg_developer") or CreateConVar("hg_developer",0,FCVAR_SERVER_CAN_EXECUTE,"Toggle developer mode (enables damage traces)",0,1)

local guiltCV = {
	enabled       = CreateConVar("zb_guilt_enabled", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "业力系统总开关"),
	dmg_mul       = CreateConVar("zb_guilt_damage_mul", "2", FCVAR_ARCHIVE, "罪恶伤害倍率"),
	ban_lowkarma  = CreateConVar("zb_guilt_ban_lowkarma", "1", FCVAR_ARCHIVE, "低业力自动封禁开关"),
	ban_lk_time   = CreateConVar("zb_guilt_ban_lowkarma_time", "60", FCVAR_ARCHIVE, "低业力封禁时长上限(分钟)"),
	ban_tk        = CreateConVar("zb_guilt_ban_teamkill", "1", FCVAR_ARCHIVE, "队伤恶意封禁开关"),
	ban_tk_time   = CreateConVar("zb_guilt_ban_teamkill_time", "30", FCVAR_ARCHIVE, "队伤封禁时长(分钟)"),
	seizure_karma = CreateConVar("zb_guilt_seizure_karma", "50", FCVAR_ARCHIVE, "癫痫触发业力阈值(0=禁用)"),
	vomit_karma   = CreateConVar("zb_guilt_vomit_karma", "35", FCVAR_ARCHIVE, "呕吐触发业力阈值(0=禁用)"),
	regen         = CreateConVar("zb_guilt_regen", "0.75", FCVAR_ARCHIVE, "业力回复基准值"),
}

hook.Add("DatabaseConnected", "GuiltCreateData", function()
	local query

	query = mysql:Create("zb_guilt")
		query:Create("steamid", "VARCHAR(20) NOT NULL")
		query:Create("steam_name", "VARCHAR(32) NOT NULL")
		query:Create("value", "FLOAT NOT NULL")
		query:PrimaryKey("steamid")
	query:Execute()

    zb.GuiltSQL.Active = true
end)

hook.Add( "PlayerInitialSpawn","ZB_GuiltSQL", function( ply )
    local name = ply:Name()
	local steamID64 = ply:SteamID64()

    --if not zb.GuiltSQL.Active then
    --    zb.GuiltSQL.PlayerInstances[steamID64] = {}
    --    return
    --end 

	local query = mysql:Select("zb_guilt")
		query:Select("value")
		query:Where("steamid", steamID64)
		query:Callback(function(result)
			if (IsValid(ply) and istable(result) and #result > 0 and result[1].value) then
				local updateQuery = mysql:Update("zb_guilt")
					updateQuery:Update("steam_name", name)
					updateQuery:Where("steamid", steamID64)
				updateQuery:Execute()

				zb.GuiltSQL.PlayerInstances[steamID64] = {}

                zb.GuiltSQL.PlayerInstances[steamID64].value = tonumber(result[1].value)

                ply.Karma = ply:guilt_GetValue()
                ply:SetNetVar("Karma", ply.Karma)

                if zb.GuiltSQL.PlayerInstances[steamID64].value < 0 and guiltCV.ban_lowkarma:GetBool() then
                    ply:guilt_SetValue( 10 )
                    local karma = ply.Karma

                    ply.Karma = 10
                    ply:SetNetVar("Karma", ply.Karma)

                    timer.Simple(0, function()
                        ply:Ban(5, false)
                        ply:Kick("Your karma is too low: " .. math.Round( karma, 0 ) .. ". Try again in 5 minutes." )
                    end)
                end
			else
				local insertQuery = mysql:Insert("zb_guilt")
					insertQuery:Insert("steamid", steamID64)
					insertQuery:Insert("steam_name", name)
					insertQuery:Insert("value", 100)
				insertQuery:Execute()

				zb.GuiltSQL.PlayerInstances[steamID64] = {}

				zb.GuiltSQL.PlayerInstances[steamID64].value = 100

                ply.Karma = ply:guilt_GetValue()
                ply:SetNetVar("Karma",ply.Karma)
			end
		end)
	query:Execute()

end)

local plyMeta = FindMetaTable("Player")

function plyMeta:guilt_GetValue()

    return zb.GuiltSQL.PlayerInstances[self:SteamID64()] and zb.GuiltSQL.PlayerInstances[self:SteamID64()].value or 100

end

function plyMeta:guilt_SetValue( zb_guilt )

    local steamID64 = self:SteamID64()
	
	zb.GuiltSQL.PlayerInstances[self:SteamID64()] = zb.GuiltSQL.PlayerInstances[self:SteamID64()] or {}
	zb.GuiltSQL.PlayerInstances[self:SteamID64()].value = zb.GuiltSQL.PlayerInstances[self:SteamID64()].value or 100
	
    zb.GuiltSQL.PlayerInstances[self:SteamID64()].value = zb_guilt

	local updateQuery = mysql:Update("zb_guilt")
		updateQuery:Update("value", zb_guilt)
		updateQuery:Where("steamid", steamID64)
	updateQuery:Execute()
end

local function IsLookingAt(ply, targetVec)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local diff = targetVec - ply:GetShootPos()
    return ply:GetAimVector():Dot(diff) / diff:Length() >= 0.8
end

hook.Add("HomigradDamage", "GuiltReg", function(ply, dmgInfo, hitgroup, ent, harm) 
    local Attacker, Victim = dmgInfo:GetAttacker(), ply
    
    --[[if !IsValid(Attacker) and dmgInfo:GetInflictor().steamid then
        local steamid = dmgInfo:GetInflictor().steamid
        
        ULib.addBan( steamid, 60, "Kicked and banned for trying to exploit karma system.", steamid, "System" )
    end--]]

    if not IsValid(Attacker) or not Attacker:IsPlayer() then return end
    if not IsValid(Victim) or not (Victim:IsPlayer() or (Victim.organism.fakePlayer and Victim.organism.alive)) then return end
	if Victim:IsNPC() or Victim:IsNextBot() then return end

    local id = Victim:IsPlayer() and Victim:SteamID() or Victim:EntIndex()
    local id2 = Attacker:IsPlayer() and Attacker:SteamID() or Attacker:EntIndex()
    local maxharm = zb.MaximumHarm
    zb.HarmDone[Victim] = zb.HarmDone[Victim] or {}
    zb.HarmDoneDetailed[id] = zb.HarmDoneDetailed[id] or {}
    zb.HarmDoneKarma[Victim] = zb.HarmDoneKarma[Victim] or {}
    zb.HarmDoneKarma[Victim][Attacker] = zb.HarmDoneKarma[Victim][Attacker] or 0
    
    local oldharmdone = zb.HarmDone[Victim][Attacker] or 0
    zb.HarmDone[Victim][Attacker] = math.Clamp((zb.HarmDone[Victim][Attacker] or 0) + harm, 0, maxharm)
    
    zb.HarmAttacked[Attacker] = zb.HarmAttacked[Attacker] or 0
    zb.HarmAttacked[Attacker] = zb.HarmAttacked[Attacker] + harm

    local newharm = math.min(harm + oldharmdone, maxharm)
    local harm = newharm - oldharmdone
    local amt = harm / maxharm
    
    if amt > 0.2 or newharm / maxharm > 0.8 then
        --print("Player "..Attacker:Name().." harmed player "..(Victim:IsPlayer() and Victim:Name() or (tostring(Victim))).." with "..harm.." points.")
        --print("They contributed a total of "..math.Round(newharm / maxharm * 100, 0).."% of "..(Victim:IsPlayer() and Victim:Name() or (tostring(Victim))).."'s death")
    end

    if zb and zb.hostage and Victim == zb.hostage then
        zb.hostageLastTouched = Attacker
    end

    local attackerTeam = dmgInfo:GetInflictor().team or (Attacker:IsPlayer() and Attacker:Team()) or Attacker.team
    zb.HarmDoneDetailed[id][id2] = {
        harm = newharm,
        amt = newharm / maxharm,
        teamVictim = Victim:IsPlayer() and Victim:Team() or Victim.team or -1,
        teamAttacker = attackerTeam or -1,
        lasthitgroup = hitgroup,
        lastdmgtype = dmgInfo:GetDamageType(),
        lastattacked = CurTime(),
    }

    if hg_developer:GetBool() then
        Attacker:ChatPrint("造成的伤害为: "..math.Round(harm,3))
        Attacker:ChatPrint("总体伤害量为: "..math.Round(amt,3))
        Attacker:ChatPrint("总体伤害为: "..math.Round(newharm,3))
        Attacker:ChatPrint("罪恶值为: "..math.Round(amt * 60,3))
        Attacker:ChatPrint(" ")
    end

    hook.Run("HarmDone", Attacker, Victim, amt)

    if newharm >= maxharm and oldharmdone < newharm then
        //Attacker:AddFrags(1) -- better make it a system that counts kills and gives frags at the end of the round
    end

    Victim = hg.GetCurrentCharacter(Victim) or Victim
    Victim = hg.RagdollOwner(Victim) or Victim

    local rnd, cround = CurrentRound()
    
    if rnd.GuiltDisabled or GetConVar("zb_dev"):GetBool() then return end

    if Attacker == Victim then return end
    if not guiltCV.enabled:GetBool() then return end

    zb.GuiltTable[Attacker] = zb.GuiltTable[Attacker] or {}
    zb.GuiltTable[Victim] = zb.GuiltTable[Victim] or {}
    
    Attacker.LastAttacked = CurTime()

    if Victim.isTraitor and !Attacker.isTraitor and rnd.name == "hmcd" and !zb.IsForce(Attacker) then return end
    if Attacker.isTraitor and !Victim.isTraitor and rnd.name == "hmcd" then return end
    
    if rnd.name != "hmcd" and (Attacker.Team and Victim.Team and attackerTeam ~= Victim:Team()) then return end
    if zb.ROUND_STATE != 1 and (rnd.name != "cstrike" or !zb.RoundsLeft) then return end
    if Victim.Guilt and Victim.Guilt > 1 and !zb.IsForce(Attacker) then return end
    if Attacker:IsBerserk() then return end

    local victimWep = Victim:IsPlayer() and IsValid(Victim:GetActiveWeapon()) and Victim:GetActiveWeapon()
    
    if newharm >= maxharm and oldharmdone < newharm then
        //Attacker:AddFrags(-1)
    end
    
    amt = amt * 1
        * (Victim:IsPlayer() and math.Clamp(((Victim.Karma or 100) / 100), 1, 1.2) or 1)
        * (Victim:IsPlayer() and ((IsLookingAt(Victim, Attacker:EyePos()) and (victimWep and (ishgweapon(victimWep) or ((victimWep:GetClass() == "weapon_hands_sh" and victimWep:GetFists() or victimWep.ismelee2) and Victim:EyePos():DistToSqr(Attacker:EyePos()) <= (90 * 90))))) and 0.5 or 1) or 1)

    local add = amt * maxharm

    add = add * (Victim:IsPlayer() and Attacker:PlayerClassEvent("Guilt", Victim) or 1)
    add = add * guiltCV.dmg_mul:GetFloat()

    local mul, shouldBanGuilt
    
    if rnd.GuiltCheck then
        mul, shouldBanGuilt = rnd.GuiltCheck(Attacker, Victim, add, harm, amt)

        add = add * (mul or 1)
    end
    
    local guiltadd = amt * 60
    Attacker.Guilt = (Attacker.Guilt or 0) + guiltadd
    Attacker.Karma = math.Clamp((Attacker.Karma or 100) - add * math.max(((1 - (zb.GuiltTable[Victim][Attacker] or 0)) / 1),0), -60, zb.MaxKarma)

    zb.HarmDoneKarma[Victim][Attacker] = zb.HarmDoneKarma[Victim][Attacker] + add

    if shouldBanGuilt and Attacker.Guilt >= 100 then
        if guiltCV.ban_tk:GetBool() then
            local tktime = guiltCV.ban_tk_time:GetInt()
            ULib.addBan( Attacker:SteamID(), tktime, "Kicked and banned for dealing too much team damage.", Attacker:Name(), "System" )

            PrintMessage(HUD_PRINTTALK, "玩家 "..Attacker:Name().." 因在团队游戏模式中恶意击杀队友已被封禁"..tktime.."分钟。")
        else
            Attacker.Guilt = 50
        end
    end

    Attacker:SetNetVar("Karma", Attacker.Karma)
    
    zb.GuiltTable[Attacker][Victim] = math.Clamp((zb.GuiltTable[Attacker][Victim] or 0) + guiltadd, 0, 200)

    if Attacker.Karma <= 0 and not guiltCV.ban_lowkarma:GetBool() then
        Attacker.Karma = math.max(Attacker.Karma, 10)
        Attacker:SetNetVar("Karma", Attacker.Karma)
    elseif Attacker.Karma <= 0 then
        local steamID = Attacker:SteamID()
        local name = Attacker:Name()
        local karma = Attacker.Karma

        Attacker:guilt_SetValue( 10 )

        -- we wait one tick to make them pay for all the murders they've done
        -- also makes sure the message is displayed only once
        timer.Create("simplewaitforkarmadrop"..Attacker:EntIndex(), 0, 1, function()
            if IsValid(Attacker) then -- if the player haven't left in that exact tick then we do him dirty
                karma = Attacker.Karma
            end

            local base = guiltCV.ban_lk_time:GetInt()
            local time = math.Clamp(math.Round(base - karma * 4, 0), 5, base)

			-- if ULib then
				ULib.addBan( steamID, time, "Kicked and banned for having too low karma.", name, "System" )
			-- else
			-- 	Attacker:Ban(60, true)
			-- end
            
            PrintMessage(HUD_PRINTTALK, "玩家 "..name.." 因业力值过低已被封禁 "..time.." 分钟。")
        end)
    end
end)

function zb.IsForce(Attacker)
    return Attacker.PlayerClassName == "police" or Attacker.PlayerClassName == "nationalguard" or Attacker.PlayerClassName == "swat"
end

local function IsLookingAt(ply, targetVec)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local diff = targetVec - ply:GetShootPos()
    return true--ply:GetAimVector():Dot(diff) / diff:Length() >= 0.6 
end -- i dont think it should matter if he looks at you or not. just drop your weapon

function zb.ForcesAttackedInnocent(self, Victim)
    local victimWep = Victim:IsPlayer() and IsValid(Victim:GetActiveWeapon()) and Victim:GetActiveWeapon()

    return 1 * ((!Victim.LastAttacked or (Victim.LastAttacked + 10 > CurTime())) and 0 or 1) + 1 * (Victim:IsPlayer() and ((IsLookingAt(Victim, self:EyePos()) and (victimWep and (ishgweapon(victimWep) or ((victimWep:GetClass() == "weapon_hands_sh" and victimWep:GetFists() or victimWep.ismelee2) and Victim:GetPos():DistanceSqr(self:GetPos()) <= (72 * 72))))) and 0 or 1) or 1)
end

hook.Add("PlayerDisconnected","GuiltSaveOnDisconect",function(ply)
    ply:guilt_SetValue( ply.Karma or 100 )
end)

hook.Add("Player Spawn","SlowlyRestoreKarma",function(ply)
    if OverrideSpawn then return end

    ply.lastwarning = nil
    //ply.firstwarning = nil
    ply.Karma = ply.Karma or 100
    ply:SetNetVar("Karma",ply.Karma)
    //ply:guilt_SetValue( ply.Karma or 100 )
    
    ply.Guilt = 0
end)

hook.Add("Player Think", "karmagain", function(ply)
    if (ply.KarmaGainThink or 0) > CurTime() then return end
    ply.KarmaGainThink = CurTime() + 120

    ply.Karma = math.Clamp(ply.Karma + (ply.Karma > 100 and 0.1 or (ply.KarmaGain or guiltCV.regen:GetFloat())), 0, zb.MaxKarma)// * (1 + ply:HasPurchase("zpremium")), 0, zb.MaxKarma)
    
    ply:SetNetVar("Karma", ply.Karma)
    //ply:guilt_SetValue( ply.Karma or 100 )
end)

hook.Add("Org Clear","removekarmashaking",function(org)
    org.start_shaking = nil
end)

hook.Add("Should Fake Up", "karma", function(ply)
    if ply.organism and ply.organism.start_shaking then return false end
end)

local seizuremsgs = {
    "bllllhlhmmmbmmmmbmbmb",
    "bbb b-bbbbbb bllmbmmbb",
    "ddgdgg-d bbbglgggg",
    "mmmmammmm aaghbgbblllb",
    "hhel-bbbphphpppph",
    "zzzzblzzzmzzzzz",
}
hook.Add("Org Think", "Its_Karma_Bro",function(owner, org, timeValue)
    if not owner or not owner:IsPlayer() or org.otrub or not org.isPly then return end
    if not owner:IsPlayer() or not owner:Alive() then return end
    
    local ply = owner
    
    if (ply.Karma or 100) < guiltCV.seizure_karma:GetInt() then
        if ((math.random(math.Clamp((ply.Karma or 100),20,zb.MaxKarma) * 300) == 1 or org.start_shaking)) then
            hg.StunPlayer(ply)
            local time = 15
            
            ply:Notify(seizuremsgs[math.random(#seizuremsgs)], 16, "seizure", 1, function()
                if !IsValid(ply) then return end
                
                ply:ChatPrint("您正在经历癫痫发作。")
            end)

            org.start_shaking = org.start_shaking or (CurTime() + time)
            local ent = hg.GetCurrentCharacter(owner)
            local mul = ((org.start_shaking) - CurTime()) / time
            
            if mul > 0 then
                ent:GetPhysicsObjectNum(math.random(ent:GetPhysicsObjectCount()) - 1):ApplyForceCenter(VectorRand(-750 * mul,750 * mul))
            else
                org.start_shaking = nil
            end
        else
            org.start_shaking = nil
        end
	end

    if (ply.Karma or 100) < guiltCV.vomit_karma:GetInt() then
        if math.random(2000) == 1 then
            hg.organism.Vomit(owner)
        end
    end
end)

hook.Add("ZB_EndRound","savevalues",function()
    for i,ply in player.Iterator() do
        ply:guilt_SetValue( ply.Karma or 100 )
    end
end)

hook.Add("ZB_StartRound","NO_HARM",function()
    for i,ply in player.Iterator() do
        if (ply.Guilt or 0) < 1 then
            local rg = guiltCV.regen:GetFloat()
            ply.KarmaGain = math.Clamp((ply.KarmaGain or rg) + 0.25, rg, rg * 2)
        else
            ply.KarmaGain = guiltCV.regen:GetFloat()
        end

        //ply:guilt_SetValue( ply.Karma or 100 )
    end
    
    zb.HarmDone = {}
    zb.HarmDoneKarma = {}
end)

util.AddNetworkString("get_karma")
net.Receive("get_karma",function(len, ply)
    if not ply:IsAdmin() then return end

    local tbl = {}

    for i,pl in player.Iterator() do
        tbl[pl:UserID()] = pl.Karma
    end

    net.Start("get_karma")
    net.WriteTable(tbl)
    net.Send(ply)
end)

concommand.Add("hg_setkarma",function(ply,cmd,args)
    if not ply:IsAdmin() then return end
    
    local lenargs = #args
    local newply = player.GetListByName(lenargs > 1 and args[1] or ply:Name())[1]

    newply.Karma = tonumber(lenargs > 1 and args[2] or args[1])
    newply:SetNetVar("Karma",ply.Karma)
    //newply:guilt_SetValue( ply.Karma or 100 )
end)

util.AddNetworkString("open_guilt_menu")
util.AddNetworkString("forgive_player")

net.Receive("open_guilt_menu",function(len, ply)
    if ply:Alive() then return end
    local tbl = zb.HarmDoneKarma[ply] or {}
    net.Start("open_guilt_menu")
    net.WriteTable(tbl)
    net.Send(ply)
    //current round guilt
end)

net.Receive("forgive_player", function(len, ply)
    local ent = net.ReadEntity()
    if not IsValid(ent) or not zb.HarmDoneKarma[ply] then return end
    local harm = zb.HarmDoneKarma[ply][ent]
    if not harm then return end

    ent.Karma = math.Clamp(ent.Karma + harm, 0, zb.MaxKarma)
    ent:SetNetVar("Karma",ent.Karma)
    //ent:guilt_SetValue((ent.Karma or 100))

    zb.HarmDone[ply][ent] = 0
    zb.HarmDoneKarma[ply][ent] = 0
    net.Start("open_guilt_menu")
    net.WriteTable(zb.HarmDoneKarma[ply])
    net.Send(ply)
end)

hook.Add("Player Spawn", "GuiltKnown",function(ply)
    if ply.Karma then
        ply:ChatPrint("您当前的业力值为 "..tostring(math.Round(ply.Karma)).."")
    end
end)

hook.Add("ZC_SomeoneGetFallBy","IdiotsMustBeKilled",function(Attacker,Victim)
    local rnd = CurrentRound()
    
    if rnd.GuiltDisabled or GetConVar("zb_dev"):GetBool() then return end
   
    if Attacker == Victim then return end

    if Victim.isTraitor and !Attacker.isTraitor and rnd.name == "hmcd" and !zb.IsForce(Attacker) then return end
    if Attacker.isTraitor and !Victim.isTraitor and rnd.name == "hmcd" then return end
    if rnd.name != "hmcd" and (Attacker.Team and Victim.Team and Attacker:Team() ~= Victim:Team()) then return end
    if zb.ROUND_STATE != 1 and (rnd.name != "cstrike" or !zb.RoundsLeft) then return end
    if Victim.Guilt and Victim.Guilt > 1 then return end

    Attacker.Guilt = Attacker.Guilt or 0
    Attacker.Guilt = Attacker.Guilt < 4 and 5 or Attacker.Guilt 
end)