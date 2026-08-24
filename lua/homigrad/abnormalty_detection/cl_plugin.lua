hg.Abnormalties = hg.Abnormalties or {}
local PLUGIN = hg.Abnormalties

--\\
local convar_newbie = CreateClientConVar("abnormalties_newbie", "1", true, false, "Set to 1 if you want to see a hint again")

PLUGIN.MainColor = Color(150, 0, 0)
--//
-- abnormalties_help
--\\
net.Receive("Abnormalties(ShowTranslation)", function(len, ply)
	local abnormalty = {}
	local abnormalty_name = net.ReadString()
	local abnormalty_amt = net.ReadUInt(32)
	
	while abnormalty_name != "" and net.BytesLeft() > 0 do
		abnormalty[abnormalty_name] = abnormalty_amt
		abnormalty_name = net.ReadString()
		abnormalty_amt = net.ReadUInt(32)
	end
	
	if(convar_newbie:GetBool())then
		convar_newbie:SetBool(false)
		
		PLUGIN.ShowMessage("你遇到了一些异常的东西，在控制台输入 abnormalties_help 以获取帮助")
	end
	
	PLUGIN.ShowTranslation(abnormalty)
end)

net.Receive("Abnormalties(ShowMessage)", function(len, ply)
	local msg = net.ReadString()
	
	PLUGIN.ShowMessage(msg)
end)
--//

--\\
function PLUGIN.ShowTranslation(abnormalty)
	-- Abnormalties_VGUI_Abnormalty = abnormalty
	-- Abnormalties_VGUI_AbnormaltyTimeEnd = CurTime() + 10
	local count = 0
	
	chat.AddText(PLUGIN.MainColor, "我有点眉目了……")
	
	for abnormalty_name, abnormalty_amt in pairs(abnormalty) do
		chat.AddText(PLUGIN.MainColor, abnormalty_name, " - " .. abnormalty_amt)
		
		count = count + 1
	end
	
	if(count > 1)then
		chat.AddText(PLUGIN.MainColor, "但还有些东西需要排除……")
	elseif(count == 1)then
		chat.AddText(PLUGIN.MainColor, "就是它……我找到了！")
		chat.AddText(PLUGIN.MainColor, "现在，只需在同一处反复念诵它……")
	elseif(count == 0)then
		chat.AddText(PLUGIN.MainColor, "但是……没有用，我必须赋予言语以意义……")
	end
end

function PLUGIN.ShowMessage(msg)
	chat.AddText(PLUGIN.MainColor, msg)
end
--//