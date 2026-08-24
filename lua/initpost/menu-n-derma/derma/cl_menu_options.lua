hg.settings = hg.settings or {}
hg.settings.tbl = hg.settings.tbl or {}

function hg.settings:AddOpt( strCategory, strConVar, strTitle, bDecimals, bString, category )
    self.tbl[strCategory] = self.tbl[strCategory] or {}
    self.tbl[strCategory][strConVar] = { strCategory, strConVar, strTitle, bDecimals or false, bString or false, category }
end
local hg_firstperson_death = CreateClientConVar("hg_firstperson_death", "0", true, false, "切换第一人称死亡视角", 0, 1)
local hg_font = CreateClientConVar("hg_font", "Bahnschrift", true, false, "将所有文字字体改为所选字体，因为 UI 自定义很酷")
local hg_attachment_draw_distance = CreateClientConVar("hg_attachment_draw_distance", 0, true, nil, "附件绘制距离", 0, 4096)

xbars = 17
ybars = 30

gradient_l = Material("vgui/gradient-l")

local blur = Material("pp/blurscreen")
local blur2 = Material("effects/shaders/zb_blur" )
local sw, sh = ScrW(), ScrH()

local font = function() -- hg_coolvetica:GetBool() and "Coolvetica" or "Bahnschrift"
    local usefont = "Bahnschrift"

    if hg_font:GetString() != "" then
        usefont = hg_font:GetString()
    end

    return usefont
end

surface.CreateFont("ZCity_setiings_tiny", {
	font = font(),
	size = ScreenScale(7),
	weight = 100
})

surface.CreateFont("ZCity_setiings_fine", {
	font = font(),
	size = ScreenScale(10),
	weight = 100
})

surface.CreateFont("ZCity_setiings_category", {
	font = font(),
	size = ScreenScale(15),
	weight = 100
})


hg.settings:AddOpt("游戏","hg_old_notificate", "旧版通知")
hg.settings:AddOpt("游戏","hg_cheats", "启用作弊")
hg.settings:AddOpt("游戏","hg_showthoughts", "显示想法")
hg.settings:AddOpt("游戏","hg_hints", "显示提示")
hg.settings:AddOpt("游戏","hg_gary", "假人模式居中武器")
hg.settings:AddOpt("游戏","hg_deathfadeout", "死亡淡出")
--hg_gary
--hg_deathfadeout
if not game.IsDedicated() then
	hg.settings:AddOpt("服务器设置","hg_toughnpcs", "耐打 NPC")
	hg.settings:AddOpt("服务器设置","hg_thirdperson", "第三人称 (开发中)")
	hg.settings:AddOpt("服务器设置","hg_legacycam", "旧版摄像机")
	hg.settings:AddOpt("服务器设置","hg_ragdollcombat", "布娃娃战斗模式")
	hg.settings:AddOpt("服务器设置","hg_movement_stamina_debuff", "移动耐力减益")
	hg.settings:AddOpt("服务器设置","hg_furcity", "Furcity")
	hg.settings:AddOpt("服务器设置","hg_appearance_access_for_all", "外观完整权限对所有人生效", nil, nil, "bool")
	hg.settings:AddOpt("服务器设置","hg_healanims", "治疗与进食动画")
	hg.settings:AddOpt("服务器设置","hg_aimtoshoot", "切换类 DarkRP 射击系统 (瞄准射击): 0 - 禁用; 1 - 仅腰射; 2 - 仅瞄准", nil, nil, "int")
	hg.settings:AddOpt("服务器设置","hg_slings", "吊索系统")
	hg.settings:AddOpt("服务器设置","hg_allow_gopro", "允许类 GoPro 的第一人称相机")
	hg.settings:AddOpt("服务器设置","hg_allow_gopro_pos", "允许编辑 GoPro 相机位置")
	hg.settings:AddOpt("服务器设置","hg_giveammomul", "乘以从生成菜单生成的武器所获得的弹药")
	hg.settings:AddOpt("服务器设置","hg_ixanims", "为玩家启用类似 Helix 的 NPC 模型动画。实验性")
	hg.settings:AddOpt("服务器设置","hg_coolhands", "生成时给予酷炫双手而非默认手部模型")
	hg.settings:AddOpt("服务器设置","hg_loadcontent", "使用 'resource.AddWorkshop' 向客户端加载内容 (需要重启服务器生效)")
    hg.settings:AddOpt("服务器设置","homicide_traitoramount", "Homicide: 叛徒数量", nil, nil, "int")
end
--hg_appearance_access_for_all
--hg_furcity
--hg_legacycam
--hg_toughnpcs

hg.settings:AddOpt("调试","hg_show_hitposmuzzle", "显示武器命中位置")
hg.settings:AddOpt("调试","hg_setzoompos", "编辑武器瞄准位置，查看控制台结果")
hg.settings:AddOpt("调试","hg_show_hitbox", "显示命中盒")

hg.settings:AddOpt("优化","hg_potatopc", "土豆 PC 模式")
hg.settings:AddOpt("优化","hg_anims_draw_distance", "动画绘制距离", true, nil, "int")
hg.settings:AddOpt("优化","hg_anim_fps", "动画 FPS", nil, nil, "int")
hg.settings:AddOpt("优化","hg_attachment_draw_distance", "附件绘制距离", true, nil, "int")
hg.settings:AddOpt("优化","hg_maxsmoketrails", "最大烟雾拖尾", nil, nil, "int")
hg.settings:AddOpt("优化","hg_tpik_distance", "TPIK 渲染距离", true, nil, "int")

hg.settings:AddOpt("血液","hg_blood_draw_distance", "血液绘制距离")
hg.settings:AddOpt("血液","hg_blood_fps", "血液 FPS")
hg.settings:AddOpt("血液","hg_blood_sprites", "血液精灵 (已对所有人禁用)")
hg.settings:AddOpt("血液","hg_old_blood", "旧版血液")

hg.settings:AddOpt("界面","hg_font", "设置自定义字体", false, true)

hg.settings:AddOpt("武器","hg_weaponshotblur_enable", "射击模糊")
hg.settings:AddOpt("武器","hg_dynamic_mags", "动态弹药检视")
hg.settings:AddOpt("武器","hg_zoomsensitivity", "瞄准灵敏度")
hg.settings:AddOpt("武器","hg_highpitchgunfire", "切换建筑物内的高音枪声")

hg.settings:AddOpt("视角","hg_firstperson_death", "第一人称死亡")
hg.settings:AddOpt("视角","hg_fov", "视野范围")
hg.settings:AddOpt("视角","hg_newspectate", "平滑观战相机")
hg.settings:AddOpt("视角","hg_cshs_fake", "C'sHS 布娃娃相机")
hg.settings:AddOpt("视角","hg_gun_cam", "枪械相机 (仅限管理员)")
hg.settings:AddOpt("视角","hg_nofovzoom", "禁用/启用 FOV 缩放")
hg.settings:AddOpt("视角","hg_realismcam", "写实相机 (很烂)")
hg.settings:AddOpt("视角","hg_gopro", "GoPro 相机")
hg.settings:AddOpt("视角","hg_newfakecam", "新版假人相机")
hg.settings:AddOpt("视角","hg_leancam_mul", "倾斜相机倍率", true, nil, "int")
hg.settings:AddOpt("视角","hg_gun_cam", "枪械相机 (开发中，仅限管理员)")
--hg_hints
--hg_leancam_mul
  --hg_newfakecam
hg.settings:AddOpt("声音","hg_dmusic", "动态音乐")
hg.settings:AddOpt("声音","hg_quietshots", "启用/禁用消音枪声")


function hg.CreateCategory(ctgName, ParentPanel, yPos)
    local pppanel = vgui.Create('DPanel', ParentPanel)
    pppanel:SetSize(ParentPanel:GetWide() / 1.05, ParentPanel:GetTall() * 0.07)
    pppanel:SetPos(ParentPanel:GetWide() / 2 -pppanel:GetWide() / 2, yPos)
    --pppanel:SetText(ctgName)
    pppanel.Paint = function(self,w,h)
        surface.SetDrawColor(60,60,60,145)
        surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(42, 42, 42, 184)
		surface.DrawRect(0, h-5, w, 5)
    
        draw.SimpleText(ctgName, 'ZCity_setiings_category', w / 2, h / 2, color3, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    return pppanel
end

function hg.GetConVarType(convar)
    local stringv = convar:GetString()
    local floatVal = convar:GetFloat()
    local intVal = convar:GetInt()
    local boolVal = convar:GetBool()

    if (stringv == '0' and not boolVal) or (stringv == '1' and boolVal) then
        return 'bool'
    end

    if tonumber(stringv) and math.floor(stringv) == floatVal then
        if intVal == floatVal then
            return "int"
        end
    end

    return "string"
end

local function SetConVarValue(convar, value)
    if not convar then
        return
    end

    local name = convar.GetName and convar:GetName()
    if not name or name == "" then
        return
    end

    if isbool(value) then
        RunConsoleCommand(name, value and "1" or "0")
        return
    end

    RunConsoleCommand(name, tostring(value))
end

local clr_1 = Color(255,255,255,104)
local clr_2 = Color(122,122,122,104)
local clr_3 = Color(28,28,28)
local clr_4 = Color(0, 0, 0, 30)
local clr_5 = Color(30, 29, 29, 30)
local clr_6 = Color(255, 255, 255, 100)
local clr_7 = Color(255, 255, 255, 200)
local clr_8 = Color(70, 130, 180)
function hg.CreateButton(buttonData, convarName, ParentPanel, yPos)
    local convar = GetConVar(convarName)

    if not convar then 
        return 
    end
    local pppanel = vgui.Create('DPanel', ParentPanel)
    pppanel:SetSize(ParentPanel:GetWide()/1.05, ParentPanel:GetTall()/15)
    pppanel:SetPos(ParentPanel:GetWide()/2-pppanel:GetWide()/2, yPos)
    
    surface.SetFont('ZCity_setiings_fine')
    local width2, height2 = surface.GetTextSize(buttonData[3])
    
    convarType = buttonData[6] or hg.GetConVarType(convar)
    pppanel.Paint = function(self,w,h)
        surface.SetDrawColor(43, 43, 43,145)
        surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(47, 47, 47,145)
		surface.DrawRect(0, h-3, w, 3)
        
        draw.SimpleText(buttonData[3], 'ZCity_setiings_fine', 30, h / 2 -height2/2.5, clr_1, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(convar:GetHelpText(), 'ZCity_setiings_tiny', 30, h / 2+height2/2, clr_2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    if convarType == 'bool' then
        local toggle = vgui.Create('DButton', pppanel)
        toggle:SetSize(pppanel:GetWide() / 18, pppanel:GetTall() / 2)

        
        toggle:SetPos(pppanel:GetWide() - toggle:GetWide()*1.4 - pppanel:GetWide() / 20, pppanel:GetTall() / 2 - toggle:GetTall() / 2)
        toggle:SetText('')
        
        local animProgress = convar:GetBool() and 1 or 0
        local targetProgress = animProgress
        
        function toggle:Paint(w, h)
            if animProgress ~= targetProgress then
                animProgress = Lerp(FrameTime() * 8, animProgress, targetProgress)
            end
            
            local bgColor = Color(
                Lerp(animProgress, 180, 80),  
                Lerp(animProgress, 30, 120),  
                Lerp(animProgress, 30, 50)   
            )
            
            local shadowColor = Color(0, 0, 0, Lerp(animProgress, 150, 40))
            surface.SetDrawColor(clr_3)
            draw.RoundedBox(0, 0, 0, w, h, clr_3)
            
            surface.SetDrawColor(clr_5)
            draw.RoundedBox(0, 2, 2, w - 4, h - 4, clr_4)
            
            local slsize = h - 12
            local slPos = Lerp(animProgress, 6, w - slsize - 6)
            surface.SetDrawColor(bgColor)
            draw.RoundedBox(0, slPos, 6, slsize, slsize, bgColor)
            surface.SetDrawColor(shadowColor)
            surface.DrawRect(slPos, slsize+4, slsize, 3)
    
            surface.SetDrawColor(clr_6)
        end
        
        function toggle:DoClick()
            if convar then
                local newValue = not convar:GetBool()
                SetConVarValue(convar, newValue)

                surface.PlaySound('glide/headlights_on.wav')
                targetProgress = newValue and 1 or 0
            end
        end
        
    elseif convarType == 'int' then
        local slider = vgui.Create('DNumSlider', pppanel)
        slider:SetSize(280, 30)
        slider:SetPos(pppanel:GetWide() - 300, pppanel:GetTall() / 2 - 15)
        slider:SetText('')
        
        local min = convar:GetMin() or 0
        local max = convar:GetMax() or 100
        local decimals = buttonData[4] and 2 or 0
        
        slider:SetMin(min)
        slider:SetMax(max)
        slider:SetDecimals(decimals)
        slider:SetValue(decimals > 0 and convar:GetFloat() or convar:GetInt())
        
        function slider:OnValueChanged(val)
            if convar then
                SetConVarValue(convar, decimals > 0 and math.Round(val, decimals) or math.Round(val))
            end
        end
        
        local valueLabel = vgui.Create('DLabel', pppanel)
        valueLabel:SetPos(pppanel:GetWide() - 350, pppanel:GetTall() / 2 - 8)
        valueLabel:SetSize(50, 20)
        valueLabel:SetText(convar:GetInt())
        valueLabel:SetTextColor(clr_7)
        valueLabel:SetFont('ZCity_setiings_tiny')
        
        slider.Think = function()
            if convar then
                valueLabel:SetText(convar:GetInt())
            end
        end
        
    elseif convarType == 'string' then
        local textEntry = vgui.Create('DTextEntry', pppanel)
        textEntry:SetSize(pppanel:GetWide()/8, pppanel:GetTall()/2)
        textEntry:SetPos(pppanel:GetWide()-pppanel:GetWide()/8-20, pppanel:GetTall()/2-textEntry:GetTall()/2)
        textEntry:SetText(convar:GetString())
        textEntry:SetUpdateOnType(true) 
        textEntry:SetFont('ZCity_Tiny')
        
    
        textEntry.Paint = function(self, w, h)
            surface.SetDrawColor(30, 30, 30, 255)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(60, 60, 60, 255)
            surface.DrawOutlinedRect(0, 0, w, h)
            
            self:DrawTextEntryText(color_white, clr_8, color_white)
        end
        
        function textEntry:OnValueChange(val)
            if convar then
                SetConVarValue(convar, val)
            end
        end
    end
    
    return pppanel
end

function hg.DrawSettings(ParentPanel)
    ParentPanel:SetAlpha(0)
    ParentPanel.Paint = function(self,w,h)

        surface.SetDrawColor(28,28,28,255)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(107, 107, 107,20)

        for i = 1, (ybars + 1) do
            surface.DrawRect((sw / ybars) * i - (CurTime() * 30 % (sw / ybars)), 0, ScreenScale(1), sh)
        end

        for i = 1, (xbars + 1) do
            surface.DrawRect(0, (sh / xbars) * (i - 1) + (CurTime() * 30 % (sh / xbars)), sw, ScreenScale(1))
        end

        local border_size = ScreenScale(2)

        surface.SetDrawColor(0, 0, 0)
        surface.SetMaterial(gradient_l)
        surface.DrawTexturedRect(0, 0, border_size, sh)
		surface.SetMaterial(blur)
        surface.SetDrawColor(28,28,28,208)
        surface.DrawRect(0, 0, w, h)
    end
    hg.DrawBlur(ParentPanel, 5)
    ParentPanel:AlphaTo(255,0.15,0)
    local pppanel3 = vgui.Create('DScrollPanel', ParentPanel)
    pppanel3:SetSize(ParentPanel:GetWide(), ParentPanel:GetTall())
    pppanel3:SetPos(0,0)
    --pppanel3:SetAlpha(0)
    pppanel3.Paint = function()end
    -- 🥴 <- лучший смайлик

    local yOffset = pppanel3:GetTall()/100

    for categoryName, categoryTable in pairs(hg.settings.tbl) do
        local category = hg.CreateCategory(categoryName, pppanel3, yOffset)
        yOffset = yOffset + category:GetTall() + 12
        for convarName, settingData in pairs(categoryTable) do
            local vbv = hg.CreateButton(settingData,convarName,pppanel3,yOffset)
            if not vbv then continue end
            yOffset = yOffset + (vbv:GetTall()) + 12
        end
    end
    local pppanel23 = vgui.Create('DPanel', pppanel3)
    pppanel23:SetSize(0, 0)
    pppanel23:SetPos(0,yOffset+12)
end