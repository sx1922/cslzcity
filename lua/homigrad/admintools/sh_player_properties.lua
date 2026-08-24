local function check(self, ent, ply)
    if not ply:ZCTools_GetAccess() then return false end 
	if ( !IsValid( ent ) ) then return false end
	if ( ent:IsPlayer() ) then return true end
    local pEnt = hg.RagdollOwner( ent )
    if ( ent:IsRagdoll() ) and pEnt and pEnt:IsPlayer() and pEnt:Alive() then return true end
end
properties.Add( "notify", {
	MenuLabel = "通知", -- Name to display on the context menu
	Order = 1, -- The order to display this property relative to other properties
	MenuIcon = "icon16/note_add.png", -- The icon to display next to the property

	Filter = check,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
        Derma_StringRequest(
            "通知 ".. ent:GetPlayerName(), 
            "输入一条消息",
            "",
            function(text) 
                self:MsgStart()
                    net.WriteEntity( ent )
                    net.WriteString( text )
                self:MsgEnd()
            end
        )

	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local ent = net.ReadEntity()
        local text = net.ReadString()

		--if ( !properties.CanBeTargeted( ent, ply ) ) then return end
		if ( !self:Filter( ent, ply ) ) then return end
        ent = hg.RagdollOwner( ent ) or ent

		ent:Notify( text, 0 )
		print(tostring(ply:Nick() or ply) .." has notfied ".. tostring(ent:Nick() or ent) .." with the following message; "..text)
	end 
} )

properties.Add( "givegun", {
	MenuLabel = "给予武器", -- Name to display on the context menu
	Order = 2, -- The order to display this property relative to other properties
	MenuIcon = "icon16/gun.png", -- The icon to display next to the property

	Filter = check,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
        Derma_StringRequest(
            "给予 ".. ent:GetPlayerName(), 
            "输入实体类名",
            "",
            function(text) 
                self:MsgStart()
                    net.WriteEntity( ent )
                    net.WriteString( text )
                self:MsgEnd()
            end
        )

	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local ent = net.ReadEntity()
        local text = net.ReadString()
		--if ( !properties.CanBeTargeted( ent, ply ) ) then return end
		if ( !self:Filter( ent, ply ) ) then return end
        ent = hg.RagdollOwner( ent ) or ent

		local spawned = ent:Give( text )
        if not IsValid(spawned) then return end
        spawned:Use(ent)
		print(tostring(ply:Nick() or ply) .." has given ".. tostring(ent:Nick() or ent) .." a SWEP; "..text)
	end 
} )

properties.Add( "strip", {
	MenuLabel = "缴械", -- Name to display on the context menu
	Order = 3, -- The order to display this property relative to other properties
	MenuIcon = "icon16/basket_delete.png", -- The icon to display next to the property

	Filter = check,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
        Derma_Query(
            "该玩家将被缴械，仅剩拳头。",
            "你确定吗？",
            "是",
            function()
                self:MsgStart()
                    net.WriteEntity( ent )
                self:MsgEnd()
            end,
        	"否"
        )

	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local ent = net.ReadEntity()

		--if ( !properties.CanBeTargeted( ent, ply ) ) then return end
		if ( !self:Filter( ent, ply ) ) then return end
        ent = hg.RagdollOwner( ent ) or ent
		ent:StripWeapons( )
        ent:Give("weapon_hands_sh")
		print(tostring(ply:Nick() or ply) .." has stripped ".. tostring(ent:Nick() or ent) .." of their weapons.")
	end 
} )

properties.Add( "fullstrip", {
	MenuLabel = "完全缴械", -- Name to display on the context menu
	Order = 4, -- The order to display this property relative to other properties
	MenuIcon = "icon16/lorry_delete.png", -- The icon to display next to the property

	Filter = check,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
        Derma_Query(
            "所有武器（包括拳头）都将被移除。",
            "你确定吗？",
            "是",
            function()
                self:MsgStart()
                    net.WriteEntity( ent )
                self:MsgEnd()
            end,
        	"否"
        )

	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local ent = net.ReadEntity()

		--if ( !properties.CanBeTargeted( ent, ply ) ) then return end
		if ( !self:Filter( ent, ply ) ) then return end
        ent = hg.RagdollOwner( ent ) or ent

		ent:StripWeapons( )
		print(tostring(ply:Nick() or ply) .." has full stripped ".. tostring(ent:Nick() or ent) .." of their weapons and fist.")
	end 
} )

properties.Add( "reset_org", {
	MenuLabel = "重置生物体", -- Name to display on the context menu
	Order = 5, -- The order to display this property relative to other properties
	MenuIcon = "icon16/heart_add.png", -- The icon to display next to the property

	Filter = check,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
        Derma_Query(
            "生物体将被重置，如同重新复活一样。",
            "你确定吗？",
            "是",
            function()
                self:MsgStart()
                    net.WriteEntity( ent )
                self:MsgEnd()
            end,
        	"否"
        )

	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local ent = net.ReadEntity()

		--if ( !properties.CanBeTargeted( ent, ply ) ) then return end
		if ( !self:Filter( ent, ply ) ) then return end
        ent = hg.RagdollOwner( ent ) or ent
        
		hg.organism.Clear( ent.organism )
		print(tostring(ply:Nick() or ply) .." reset the health of ".. tostring(ent:Nick() or ent))
	end 
} )

properties.Add( "freeze", {
	MenuLabel = "冻结", -- Name to display on the context menu
	Order = 6, -- The order to display this property relative to other properties
	MenuIcon = "icon16/control_pause_blue.png", -- The icon to display next to the property

	Filter = function( self, ent, ply )
        if not ply:ZCTools_GetAccess() then return false end 
	    if ( !IsValid( ent ) ) then return false end
        local pEnt = hg.RagdollOwner( ent ) or ent
        self.MenuLabel = pEnt:IsPlayer() and pEnt:IsFrozen() and "解除冻结" or "冻结"
        self.MenuIcon = pEnt:IsPlayer() and pEnt:IsFrozen() and "icon16/control_pause.png" or "icon16/control_pause_blue.png"
	    if ( ent:IsPlayer() ) then return true end
        if ( ent:IsRagdoll() ) and pEnt and pEnt:IsPlayer() and pEnt:Alive() then return true end
    end,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
        self:MsgStart()
            net.WriteEntity( ent )
        self:MsgEnd()
	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local ent = net.ReadEntity()

		--if ( !properties.CanBeTargeted( ent, ply ) ) then return end
		if ( !self:Filter( ent, ply ) ) then return end
        ent = hg.RagdollOwner( ent ) or ent
        
		ent:Freeze(not ent:IsFrozen())
		print(tostring(ply:Nick() or ply) .. (ent:IsFrozen() and " has frozen " or " has unfrozen ").. tostring(ent:Nick() or ent))
	end 
} )

properties.Add( "snatch", {
	MenuLabel = "掳走", -- Name to display on the context menu
	Order = 7, -- The order to display this property relative to other properties
	MenuIcon = "icon16/cross.png", -- The icon to display next to the property

	Filter = function(self, ent, ply)
        if !CurrentRound then return false end
        
        return check(self, ent, ply)
    end,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
        Derma_Query(
            "如果周围没有玩家，他将会直接消失。",
            "你确定吗？",
            "是",
            function()
                self:MsgStart()
                    net.WriteEntity( ent )
                self:MsgEnd()
            end,
        	"否"
        )

	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local ent = net.ReadEntity()

		--if ( !properties.CanBeTargeted( ent, ply ) ) then return end
		if ( !self:Filter( ent, ply ) ) then return end
        ent = hg.RagdollOwner( ent ) or ent

		local bot = ents.Create("bot_fear")
        bot.Victim = ent
        bot:Spawn()
		print(tostring(ply:Nick() or ply) .." has snatched ".. tostring(ent:Nick() or ent))
	end 
} )

properties.Add( "ragdollize", {
	MenuLabel = "击晕/起身", -- Name to display on the context menu
	Order = 8, -- The order to display this property relative to other properties
	MenuIcon = "icon16/anchor.png", -- The icon to display next to the property

	Filter = check,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
		self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()
	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local ent = net.ReadEntity()

		if not self:Filter(ent, ply) then return end
        ent = hg.RagdollOwner(ent) or ent

		if not IsValid(ent.FakeRagdoll) then
			print(tostring(ply:Nick() or ply) .." has stunned ".. tostring(ent:Nick() or ent))
			hg.LightStunPlayer(ent, 5)
		else
			print(tostring(ply:Nick() or ply) .." has unstunned ".. tostring(ent:Nick() or ent))
			hg.FakeUp(ent)
		end
	end 
} )

properties.Add( "vomit", {
	MenuLabel = "使其呕吐", -- Name to display on the context menu
	Order = 9, -- The order to display this property relative to other properties
	MenuIcon = "pluv/pluv51.png", -- The icon to display next to the property

	Filter = check,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
		self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()
	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local ent = net.ReadEntity()

		if not self:Filter(ent, ply) then return end
        ent = hg.RagdollOwner(ent) or ent

		hg.organism.Vomit(ent)
		print(tostring(ply:Nick() or ply) .." forced ".. tostring(ent:Nick() or ent) .." to vomit.")
	end 
} )

properties.Add( "lobotomize", {
	MenuLabel = "切除脑叶", -- Name to display on the context menu
	Order = 10, -- The order to display this property relative to other properties
	MenuIcon = "pluv/pluv51.png", -- The icon to display next to the property

	Filter = check,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
		self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()
	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local ent = net.ReadEntity()
        
		if not self:Filter(ent, ply) then return end
        ent = hg.RagdollOwner(ent) or ent
        
        ent.organism.brain = ent.organism.brain + 0.05
        ply:ChatPrint("大脑已被切除至 "..math.Round(ent.organism.brain * 100).."%")
        print(tostring(ply:Nick() or ply) .." has lobotomized ".. tostring(ent:Nick() or ent))

        if ent.organism.brain >= 0.25 and ent.organism.brain < 0.3 then
            ply:ChatPrint("下次切除脑叶将导致意识丧失！")
        end
    end 
} )

properties.Add("killsilent", {
	MenuLabel = "击杀（无声）",
	Order = 11,
	MenuIcon = "icon16/cross.png",

	Filter = check,
	Action = function( self, ent )
		self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()
	end,
	Receive = function( self, length, ply )
		local ent = net.ReadEntity()

		if ( !self:Filter( ent, ply ) ) then return end
        ent = hg.RagdollOwner( ent ) or ent
		print(tostring(ply:Nick() or ply) .." has silently killed ".. tostring(ent:Nick() or ent))
		ent:Kill()
	end 
})

properties.Add("removeply", {
	MenuLabel = "移除",
	Order = 12,
	MenuIcon = "icon16/cross.png",

	Filter = check,
	Action = function( self, ent )
		self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()
	end,
	Receive = function( self, length, ply )
		local ent = net.ReadEntity()

		if ( !self:Filter( ent, ply ) ) then return end
        ent = hg.RagdollOwner( ent ) or ent
		print(tostring(ply:Nick() or ply) .." has removed ".. tostring(ent:Nick() or ent))
		ent:KillSilent()
		ent:Remove()
	end 
})

properties.Add( "setplayerclass", {
	MenuLabel = "设置玩家职业", -- Name to display on the context menu
	Order = 15, -- The order to display this property relative to other properties
	MenuIcon = "vgui/entities/npc_nukude_proto_h", -- The icon to display next to the property

	Filter = check,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )
		self:MsgStart()
			net.WriteEntity( ent )
		self:MsgEnd()
	end,
	PlayerClass = function( self, ent, name )
		self:MsgStart()
			net.WriteEntity( ent )
			net.WriteString( name )
		self:MsgEnd()
	end,
	Receive = function( self, length, ply )
		local ent = net.ReadEntity()
		if not self:Filter(ent, ply) then return end -- this line was not here before
		local class = net.ReadString( )

		ent = hg.RagdollOwner(ent) or hg.GetCurrentCharacter(ent) or ent
		if IsValid(ent) and ent:IsPlayer() and player.classList[class] then
			ent:SetPlayerClass(class)
		end
	end,
	MenuOpen = function( self, option, ent, tr )
		local submenu = option:AddSubMenu()

		for name, tbl in pairs(player.classList) do
			local opt = submenu:AddOption(name)
			opt:SetRadio(true)
			opt:SetChecked(ent.PlayerClassName == name)
			opt:SetIsCheckable(true)
			opt.OnChecked = function(s, checked)
				self:PlayerClass(ent, name)
			end	
		end
	end
} )

properties.Add( "break_limb", {
	MenuLabel = "骨折",
	Order = 13,
	MenuIcon = "pluv/pluv51.png",

	Filter = check,
	MenuOpen = function( self, option, ent, tr )
		ent = hg.RagdollOwner(ent) or hg.GetCurrentCharacter(ent) or ent

		local submenu = option:AddSubMenu()

		local neck = submenu:AddOption("脖子")
		neck:SetRadio(true)
		neck:SetChecked(ent.organism.larm > 0)
		neck:SetIsCheckable(true)
		neck.OnChecked = function(s, checked) self:BreakLimb(ent, 0) end

		local larm = submenu:AddOption("左臂")
		larm:SetRadio(true)
		larm:SetChecked(ent.organism.larm > 0)
		larm:SetIsCheckable(true)
		larm.OnChecked = function(s, checked) self:BreakLimb(ent, 1) end

		local rarm = submenu:AddOption("右臂")
		rarm:SetRadio(true)
		rarm:SetChecked(ent.organism.rarm > 0)
		rarm:SetIsCheckable(true)
		rarm.OnChecked = function(s, checked) self:BreakLimb(ent, 2) end

		local lleg = submenu:AddOption("左腿")
		lleg:SetRadio(true)
		lleg:SetChecked(ent.organism.lleg > 0)
		lleg:SetIsCheckable(true)
		lleg.OnChecked = function(s, checked) self:BreakLimb(ent, 3) end

		local rleg = submenu:AddOption("右腿")
		rleg:SetRadio(true)
		rleg:SetChecked(ent.organism.rleg > 0)
		rleg:SetIsCheckable(true)
		rleg.OnChecked = function(s, checked) self:BreakLimb(ent, 4) end

		local spine1 = submenu:AddOption("脊柱 1")
		spine1:SetRadio(true)
		spine1:SetChecked(ent.organism.rleg > 0)
		spine1:SetIsCheckable(true)
		spine1.OnChecked = function(s, checked) self:BreakLimb(ent, 5) end

		local spine2 = submenu:AddOption("脊柱 2")
		spine2:SetRadio(true)
		spine2:SetChecked(ent.organism.rleg > 0)
		spine2:SetIsCheckable(true)
		spine2.OnChecked = function(s, checked) self:BreakLimb(ent, 6) end

		local spine3 = submenu:AddOption("脊柱 3")
		spine3:SetRadio(true)
		spine3:SetChecked(ent.organism.rleg > 0)
		spine3:SetIsCheckable(true)
		spine3.OnChecked = function(s, checked) self:BreakLimb(ent, 7) end
	end,

	BreakLimb = function( self, ent, id )
		self:MsgStart()
			net.WriteEntity( ent )
			net.WriteUInt( id, 8 )
		self:MsgEnd()
	end,

	Receive = function( self, length, ply )
		local ent = net.ReadEntity()
		local limb = net.ReadUInt( 8 )
        
		if not self:Filter(ent, ply) then return end
       	ent = hg.RagdollOwner(ent) or hg.GetCurrentCharacter(ent) or ent
        
        local dmgInfo = DamageInfo()
		if limb == 0 then
            hg.BreakNeck(ent)
        elseif limb == 1 then
            hg.organism.input_list.larmup(ent.organism, 0, 1, dmgInfo)
		elseif limb == 2 then
			hg.organism.input_list.rarmup(ent.organism, 0, 1, dmgInfo)
		elseif limb == 3 then
			hg.organism.input_list.llegup(ent.organism, 0, 1, dmgInfo)
		elseif limb == 4 then
			hg.organism.input_list.rlegup(ent.organism, 0, 1, dmgInfo)
		elseif limb == 5 then
			hg.organism.input_list.spine1(ent.organism, 0, 1, dmgInfo)
		elseif limb == 6 then
			hg.organism.input_list.spine2(ent.organism, 0, 1, dmgInfo)
		elseif limb == 7 then
			hg.organism.input_list.spine3(ent.organism, 0, 1, dmgInfo)
		end
	end
} )

properties.Add( "amputate_limb", {
	MenuLabel = "截肢",
	Order = 14,
	MenuIcon = "effects/arc9_eft/evil.png",

	Filter = check,
	MenuOpen = function( self, option, ent, tr )
		ent = hg.RagdollOwner(ent) or hg.GetCurrentCharacter(ent) or ent

		local submenu = option:AddSubMenu()

		local head = submenu:AddOption("头部")
		head:SetRadio(true)
		head:SetChecked(ent.organism.larm > 0)
		head:SetIsCheckable(true)
		head.OnChecked = function(s, checked) self:AmputateLimb(ent, 0) end

		local larm = submenu:AddOption("左臂")
		larm:SetRadio(true)
		larm:SetChecked(ent.organism.larm > 0)
		larm:SetIsCheckable(true)
		larm.OnChecked = function(s, checked) self:AmputateLimb(ent, 1) end

		local rarm = submenu:AddOption("右臂")
		rarm:SetRadio(true)
		rarm:SetChecked(ent.organism.rarm > 0)
		rarm:SetIsCheckable(true)
		rarm.OnChecked = function(s, checked) self:AmputateLimb(ent, 2) end

		local lleg = submenu:AddOption("左腿")
		lleg:SetRadio(true)
		lleg:SetChecked(ent.organism.lleg > 0)
		lleg:SetIsCheckable(true)
		lleg.OnChecked = function(s, checked) self:AmputateLimb(ent, 3) end

		local rleg = submenu:AddOption("右腿")
		rleg:SetRadio(true)
		rleg:SetChecked(ent.organism.rleg > 0)
		rleg:SetIsCheckable(true)
		rleg.OnChecked = function(s, checked) self:AmputateLimb(ent, 4) end
	end,

	AmputateLimb = function( self, ent, id )
		self:MsgStart()
			net.WriteEntity( ent )
			net.WriteUInt( id, 8 )
		self:MsgEnd()
	end,

	Receive = function( self, length, ply )
		local ent = net.ReadEntity()
		local limb = net.ReadUInt( 8 )
        
		if not self:Filter(ent, ply) then return end
        ent = hg.RagdollOwner(ent) or ent
        
        local dmgInfo = DamageInfo()
		if limb == 0 then
			if SERVER and not ent.noHead then
				hg.ExplodeHead(ent)
			end
        elseif limb == 1 then
            hg.organism.AmputateLimb(ent.organism, "larm")
		elseif limb == 2 then
			hg.organism.AmputateLimb(ent.organism, "rarm")
		elseif limb == 3 then
			hg.organism.AmputateLimb(ent.organism, "lleg")
		elseif limb == 4 then
			hg.organism.AmputateLimb(ent.organism, "rleg")
		end
	end
} )

local function doorCheck(self, ent, ply)
    if not ply:IsAdmin() then return false end
    if not IsValid(ent) then return false end
    if not ent:GetClass():lower():find("door") then return false end
    return true
end

properties.Add( "door_toggle", {
    MenuLabel = "切换门",
    Order = 7,
    MenuIcon = "icon16/door.png",
    Filter = doorCheck,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        if not self:Filter(ent, ply) then return end
        ent:Fire("toggle")
    end
})

properties.Add( "door_lock", {
    MenuLabel = "锁门",
    Order = 8,
    MenuIcon = "icon16/lock.png",
    Filter = doorCheck,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        if not self:Filter(ent, ply) then return end
        ent:Fire("lock")
    end
})

properties.Add( "door_unlock", {
    MenuLabel = "解锁门",
    Order = 9,
    MenuIcon = "icon16/lock_open.png",
    Filter = doorCheck,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity(ent)
        self:MsgEnd()
    end,
    Receive = function(self, length, ply)
        local ent = net.ReadEntity()
        if not self:Filter(ent, ply) then return end
        ent:Fire("unlock")
    end
})

local defaultinv = {
    Weapons = {},
    Ammo = {},
    Armor = {},
    Attachments = {}
}
local function Respawn(ply,body)
    if ply:Alive() then
        ply:Kill()
    end
    ply.gottarespawn = true
    //OverrideSpawn = true
    timer.Simple(0.1, function()
        ply:Spawn()
        //OverrideSpawn = false
        timer.Simple(0.1, function()
            ply.inventory = table.Copy(body.inventory or defaultinv)
            --PrintTable(ply.inventory)
            
            ply:SetNetVar("Inventory", ply.inventory)
            ply:SetNetVar("Armor",body:GetNetVar( "Armor", {} ))
            ply:SetNetVar("HideArmorRender", body:GetNetVar("HideArmorRender", false))
            body:SetNetVar( "Armor", {} )
            body:SetNetVar("HideArmorRender", false)

            for k,v in pairs( ply.inventory["Weapons"] ) do
                --print(k,v)
                if v == true or not IsValid(v) then continue end
                v:SetParent( ply )
                v:SetOwner( ply )
                v:Use( ply )
            end
            for k,v in pairs( ply.inventory["Ammo"] ) do
                --print(k,v)
                ply:SetAmmo( v, k )
            end
            ply:Give( "weapon_hands_sh" )
            hg.Fake( ply, body )
            hg.LightStunPlayer( ply )

            timer.Simple(0.1, function()
                if body.CurAppearance then
                    local color = body:GetNWVector("PlayerColor", vector_origin)
                    body.CurAppearance.AColor = Color( color[1] * 255,color[2] * 255,color[3] * 255 )
                    ply:SetPlayerColor(color)
                    hg.Appearance.ForceApplyAppearance( ply, body.CurAppearance )
                    ply:SetModel(body:GetModel())
                else
                    -- prevent funny submaterial glitch
                    local Appearance = ply.CurAppearance or hg.Appearance.GetRandomAppearance()
                    Appearance.AColthes = ""
                    ply:SetNetVar("Accessories", "")
					local bgs = {}
					for k, v in ipairs(body:GetBodyGroups()) do
						table.insert(bgs, body:GetBodygroup( k - 1 ))
					end
					ply:SetBodyGroups(table.concat(bgs))
                    ply:SetModel(body:GetModel())
                    ply:SetSubMaterial()
                    ply:SetPlayerColor(ply:GetNWVector("PlayerColor", vector_origin))
                end
                ply:Give( "weapon_hands_sh" )
            end)
        end)
    end)
end

hg.RespawnIntoBody = Respawn

properties.Add( "respawn_ply_in_rag", {
	MenuLabel = "复活玩家", -- Name to display on the context menu
	Order = 1, -- The order to display this property relative to other properties
	MenuIcon = "icon16/heart.png", -- The icon to display next to the property

	Filter = function( self, ent, ply )
        if not ply:ZCTools_GetAccess() then return false end 
	    if ( !IsValid( ent ) ) then return false end
        local pEnt = hg.RagdollOwner( ent ) or ent
        if ( pEnt:IsRagdoll() ) then return true end
    end,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )

        hg.DermaPlayerQuery(
            function( ply )
                self:MsgStart()
                    net.WriteEntity( ent )
                    net.WriteEntity( ply )
                self:MsgEnd()
        end)
        
	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local ent = net.ReadEntity()
        local sPly = net.ReadEntity()
		--if ( !properties.CanBeTargeted( ent, ply ) ) then return end
		if ( !self:Filter( ent, ply ) ) then return end
        --ent = hg.RagdollOwner( ent ) or ent
        
		Respawn(sPly,ent)
	end 
} )

properties.Add( "respawn_lply_in_rag", {
	MenuLabel = "自我复活", -- Name to display on the context menu
	Order = 2, -- The order to display this property relative to other properties
	MenuIcon = "icon16/heart.png", -- The icon to display next to the property

	Filter = function( self, ent, ply )
        if not ply:ZCTools_GetAccess() then return false end 
	    if ( !IsValid( ent ) ) then return false end
        local pEnt = hg.RagdollOwner( ent ) or ent
        if ( pEnt:IsRagdoll() ) then return true end
    end,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )

        Derma_Query(
            "你将接管这具身体，并以该角色复活。",
            "你确定吗？",
            "是",
            function()
                self:MsgStart()
                    net.WriteEntity( ent )
                    net.WriteEntity( LocalPlayer() )
                self:MsgEnd()
            end,
        	"否"
        )    
	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local ent = net.ReadEntity()
        local sPly = net.ReadEntity()
		--if ( !properties.CanBeTargeted( ent, ply ) ) then return end
		if ( !self:Filter( ent, ply ) ) then return end
        --ent = hg.RagdollOwner( ent ) or ent
        
		Respawn(sPly,ent)
	end 
} )

properties.Add( "respawn_ragply_in_rag", {
	MenuLabel = "复活布偶主人", -- Name to display on the context menu
	Order = 3, -- The order to display this property relative to other properties
	MenuIcon = "icon16/heart.png", -- The icon to display next to the property

	Filter = function( self, ent, ply )
        if not ply:ZCTools_GetAccess() then return false end 
	    if ( !IsValid( ent ) ) then return false end
        local pEnt = hg.RagdollOwner( ent ) or ent
        if ( pEnt:IsRagdoll() ) then return true end
    end,
	Action = function( self, ent ) -- The action to perform upon using the property ( Clientside )

        Derma_Query(
            "这具布偶所属的玩家将被复活到他的身体中。",
            "你确定吗？",
            "是",
            function()
                self:MsgStart()
                    net.WriteEntity( ent )
                self:MsgEnd()
            end,
        	"否"
        )    
	end,
	Receive = function( self, length, ply ) -- The action to perform upon using the property ( Serverside )
		local ent = net.ReadEntity()
        local sPly = ent.ply
		--if ( !properties.CanBeTargeted( ent, ply ) ) then return end
		if ( !self:Filter( ent, ply ) ) then return end
        if not sPly then return end
        --ent = hg.RagdollOwner( ent ) or ent
        
		Respawn(sPly,ent)
	end 
} )


--hg.Fake(owner, body)
