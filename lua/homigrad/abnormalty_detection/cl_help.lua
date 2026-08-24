-- if(SERVER)then
	-- PrintMessage(HUD_PRINTTALK, "Use 'stats_help' concommand to understand the stats")
-- end

ABNORMALTIESHELP = ABNORMALTIESHELP or {}
ABNORMALTIESHELP.Stats={
	[1] = {
		Name = "介绍",
		Desc = [[
		不要使用这个，停下
		停下
看来你发现了一些奇怪的东西。
在你弄清楚自己在做什么之前，永远不要使用它，而你并不清楚。
不过，如果你喜欢一些刺激的感受，那么，就继续吧。
这本书讲述的是如何开启仪式以及其他邪恶之事。

1. 区域
通灵术式区域是在吟唱通灵术式语句之处出现的特殊区域。
区域可以重叠。
区域允许在其内部进行仪式。
区域拥有一些仅凭一瞥无法知晓的特殊属性，所以要留心记录一切。
在区域内吟唱通灵术式语句后，区域会扩大。
通灵术式区域的扩大直接受到所吟唱语句复杂程度的影响。

2. 语句
要吟唱出有用的内容，你需要赋予词句以意义。
字母表中的每个字母都对应通灵术式表中的某些变化。
你需要创造一条只包含单一通灵术式含义的语句，才能与通灵术式区域交互。这条语句会被添加到你所处的区域中。

3. 字母
通灵术式语句由一些符号和通灵术式字母组成。
它们会在地图清理后改变。每次用这些字母拼写出正确的通灵术式语句，都能将这种改变推迟 10 分钟。

4. 吟唱你的第一句咒语
试着吟唱类似“身体的资源”这样的句子 10 次。
当你吟唱 10 次后，一些想法会浮现在你脑海中，为你指明方向。

示例：
<...>
- ноте бено мемо ммммт
~ 我好像找到方向了...
~ 献祭 - 2
~ 仪式 - 5
~ 但还有些东西我需要排除掉...

那么，我们试着去掉献祭
<...>
- ноте бено мемо ммммтч
~ 我好像找到方向了...
~ 献祭 - 1
~ 仪式 - 6
~ 但还有些东西我需要排除掉...

看，我加入了字母“ч”，增加了 1 点仪式，失去了 1 点献祭，那我们再加一个
<...>
- ноте бено мемо ммммтчч
~ 我好像找到方向了...
~ 仪式 - 7
~ 就是这个……我找到了！
~ 现在，只需要在一个地方一遍又一遍地吟唱它了...

第一条通灵术式语句完成！

5. 资源
血液：
要收集血液，你需要有某个生物在区域内流血。
如果你绘制某种符号，会获得额外的血液。
请注意，区域的初始半径很小，扩张也很缓慢，所以应避免在区域外浪费血液。
还有一种异常版本的此资源，它储存在你体内而非区域中。

均衡器：
承受伤害。
请注意，此资源储存在你身上而非区域中。

6. 仪式
请翻到下一页继续。
]]
	},
	[2] = {
		Name = "仪式 1",
		Desc = [[生命力]]
	},
	[3] = {
		Name = "治愈",
		Desc = [[
你将需要：
	献祭 10，帮助 20
	血液 2500
如何激活：
	吟唱 <帮助 1，献祭 1 ...>，共 5 个词，快速连续进行（你有 10 秒时间）
作用是什么？：
	几乎完全治愈靠近通灵术式区域中心的一名玩家。
	吟唱者获得 2 倍于区域内其他玩家的优先权。
	开始前务必移走其他不需要的玩家。
	每次施放可显著降低异常效果 2 分钟（可叠加）。
	无法治愈任何精神类异常。]]
	},
	[4] = {
		Name = "复活",
		Desc = [[
你将需要：
	献祭 50，帮助 30，仪式 10
	血液 3500
如何激活：
	吟唱 <仪式 5> 5 次，快速连续进行（你有 10 秒时间）
作用是什么？：
	复活靠近通灵术式区域中心的一具尸体。
	开始前务必移走其他不需要的尸体。
	复活有时会招致无法预料的后果。
	除了这些后果外，被复活的人类起初心脏可能随机停止跳动。]]
	},
	[5] = {
		Name = "仪式 2",
		Desc = [[隐身、交互等]]
	},
	[6] = {
		Name = "思维逃避（隐身）",
		Desc = [[
即使他们能看到我，也无法察觉到我。
你将需要：
	护盾 10，帮助 20，
	均衡器 50
如何激活：
	吟唱 <护盾 10> 5 次，快速连续进行（你有 10 秒时间）
作用是什么？：
	获得完全的思维逃避（隐身），直到与任何其他思维操控者接触，或经过 45 秒后结束（不可叠加）。
	吟唱者获得 2 倍于区域内其他玩家的优先权。
]]
	},
	[7] = {
		Name = "思维广播",
		Desc = [[
即使我能看到他们，我也无法察觉他们，除非我使用与他们相同的技巧。
你将需要：
	帮助 20，仪式 10
	均衡器 15
如何激活：
	吟唱 <帮助 5> 5 次，快速连续进行（你有 10 秒时间）
作用是什么？：
	与每一位思维操控者建立联系。
	为所有人禁用隐身及其他效果。
	吟唱者获得 2 倍于区域内其他玩家的优先权。
	副作用：你所说的一切将在大约 10 秒内广播给所有人（不可叠加）。
]]
	},
	[8] = {
		Requirement = true,
		Name = "???",
		Desc = [[
		不要使用这个，停下
(其余文字无法辨认)
(我或许需要做点什么，才能读懂这段文字)
]]
	},
	[9] = {
		Requirement = true,
		Name = "???",
		Desc = [[
(文字无法辨认)
(我或许需要无视所有警告，才能读懂这段文字)
]]
	},
	[10] = {
		Requirement = true,
		Name = "???",
		Desc = [[
(这一页被撕破并沾满了鲜血，文字无法辨认)
(我或许需要陷入疯狂，才能读懂这段文字)
]]
	},
	[11] = {
		Name = "仪式 3",
		Desc = [[复合仪式与高阶仪式]]
	},
	[12] = {
		Name = "通灵术式手臂具现",
		Desc = [[
看来在仪式中，血液的纯净度才是最重要的，而非数量。
借助注入魔力的武器，我将能够提取最纯净的血液。
你将需要：
	仪式 20，伤害 10，献祭 10
	均衡器 5
	血液 250
	备用的近战武器
如何激活：
	将近战武器放入区域中，
	吟唱模式 <仪式 2，献祭 2 ...>，共 5 个词，快速连续进行（你有 10 秒时间）
作用是什么？：
	将放置的近战武器转化为通灵术式手臂。
	该武器将允许你从自身或任何其他人类身上抽取异常血液。
]]
	},
	[13] = {
		Requirement = true,
		Name = "???",
		Desc = [[
		尚未完成，无法使用
(文字无法辨认)
(我或许需要朝积极方向夸大，才能读懂这段文字)
]]
	},
	[14] = {
		Requirement = true,
		Name = "???",
		Desc = [[
		尚未完成，无法使用
(文字无法辨认)
(我或许需要朝消极方向夸大，才能读懂这段文字)
]]
	},
	[15] = {
		Requirement = true,
		Name = "???",
		Desc = [[
(文字无法辨认)
(我或许需要朝积极方向夸大，才能读懂这段文字)
]]
	},
	[16] = {
		Requirement = true,
		Name = "???",
		Desc = [[
(文字无法辨认)
(我或许需要朝消极方向夸大，才能读懂这段文字)
]]
	},
}

--; Добавить ритуалы:
--; Создание магической тыкалки

function ABNORMALTIESHELP:OpenStats(Recipe)
	Recipe=Recipe or 1
	if(!ABNORMALTIESHELP.Stats[Recipe])then
		if(Recipe <= 0)then
			Recipe = #ABNORMALTIESHELP.Stats
		else
			Recipe = 1
		end
	end
	if(IsValid(ABNORMALTIESHELP.Panel))then ABNORMALTIESHELP.Panel:Remove() end
	
	ABNORMALTIESHELP.Panel = vgui.Create("DFrame")
	local frame = ABNORMALTIESHELP.Panel
	local size={math.max(ScrW()/4,640),math.max(ScrH()/2.5,640)}
	
	frame:SetTitle("")
	frame:SetSize(size[1], 0)
	frame:SizeTo(size[1], size[2], 0.1)
	frame:SetPos((ScrW()-size[1])/2, (ScrH()-size[2]))
	frame:MoveTo((ScrW()-size[1])/2, (ScrH()-size[2])/2, 0.1)
	frame:MakePopup()
	frame:NoClipping(true)
	frame.Paint = function( sel, w, h )
		local fancyayy ={
			{ x = -10, y = -15 },
			{ x = w+50, y = -10 },
			{ x = w+4, y = h },
			{ x = -5, y = h+3 }
		}
		draw.NoTexture()
		surface.SetDrawColor( 150, 0, 0, 255 )
		surface.DrawPoly(fancyayy)
		local fancyayy1 ={
			{ x = 0, y = 1 },
			{ x = w+40, y = -4 },
			{ x = w, y = h-1 },		
			{ x = 0, y = h }
		}
		draw.NoTexture()
		surface.SetDrawColor( 50, 50, 50, 255 )
		surface.DrawPoly(fancyayy1)
	end
	

	
	frame.Label = Label(ABNORMALTIESHELP.Stats[Recipe].Name, frame)
	frame.Label:SetFont("CloseCaption_Bold")
	frame.Label:Dock( TOP )
	frame.Label:SetSize(size[1],32)

	frame.Desc = vgui.Create("RichText",frame)
	frame.Desc:AppendText(ABNORMALTIESHELP.Stats[Recipe].Desc)
	function frame.Desc:PerformLayout()
		self:SetVerticalScrollbarEnabled(true)
		self:SetFontInternal("CloseCaption_Normal")
	end
	frame.Desc:Dock( TOP )
	frame.Desc:SetSize(size[1]-90,size[2]-100)

	frame.Prev = vgui.Create("DButton",frame)
	frame.Prev:SetText("上一页")
	frame.Prev:SetPos(0, 0)
	frame.Prev:SetSize(50, 20)
	frame.Prev.DoClick = function()
		ABNORMALTIESHELP:OpenStats(Recipe - 1)
	end

	frame.PageNumberEntry = vgui.Create("DTextEntry",frame)
	frame.PageNumberEntry:SetNumeric(true)
	frame.PageNumberEntry:SetText(Recipe)
	frame.PageNumberEntry:SetPos(50, 0)
	frame.PageNumberEntry:SetSize(20, 20)
	frame.PageNumberEntry.OnEnter = function(sel)
		ABNORMALTIESHELP:OpenStats(tonumber(sel:GetValue()))
	end

	frame.Next = vgui.Create("DButton",frame)
	frame.Next:SetText("下一页")
	frame.Next:SetPos(70, 0)
	frame.Next:SetSize(50, 20)
	frame.Next.DoClick = function()
		ABNORMALTIESHELP:OpenStats(Recipe + 1)
	end
	
	if(ABNORMALTIESHELP.Stats[Recipe].Requirement)then
		net.Start("Abnormalties(SendOpenedPage)")
			net.WriteUInt(Recipe, 8)
		net.SendToServer()
	end
end

concommand.Add("abnormalties_help",function()
	ABNORMALTIESHELP:OpenStats()
end)

--\\Networking
net.Receive("Abnormalties(SendOpenedPage)", function(len, ply)
	local page = net.ReadUInt(8)
	local page_name = net.ReadString()
	local page_desc = net.ReadString()
	ABNORMALTIESHELP.Stats[page].Name = page_name
	ABNORMALTIESHELP.Stats[page].Desc = page_desc
	
	ABNORMALTIESHELP:OpenStats(page)
end)
--//