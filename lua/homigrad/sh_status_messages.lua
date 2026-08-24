
local allowedchars = {
	"ah",
	"AH",
	"ghh",
	"GH",
	"AHHH",
}

local audible_pain = {
	"啊啊啊啊啊...妈的...好痛。",
	"我再也受不了了！",
    "让它停下来，让它停下来，让它停下来！",
    "为什么它停不下来！",
    "让我昏过去吧。求你了！",
    "为什么我生来就要承受这种痛苦...",
    "只要能让它停下，我什么都愿意做...什么都愿意。",
    "这不是活着，这是被折磨！",
    "我什么都不在乎了，只要别让我再痛下去！",
    "什么都无所谓，除了让它停下来...",
    "每一秒都是永恒的煎熬。",
    "现在死亡对我来说都是仁慈...",
    "只要哪怕一刻没有痛苦..",
	"我真希望现在有止痛药。操。",
}

local sharp_pain = {
	"AAAHH",
	"AAAH",
	"AAaaAH",
	"AAaaAH",
	"AAaaAAAGH",
	"AAaaAH",
	"AAaAaaH",
	"AAAAAaaH",
	"AAaaAHHHH",
	"AAaAA",
	"AAAAAa",
	"AAAAaAAAaaaaghh",
	"AAAaaAa",
	"AaaAAaghf",
	"aaAaaAaff",
	"aaahhh",
	"AAAaaGHHH",
	"AAAaaAAHH",
	"AAAaaAAAAAaGHHHH",
	"AAAaaAAAAAaGHAAAHHH",
	"AAAaaAAAAAaGHHAAAAAAHH",
	"AAAaaAAAAAaGHHHH",
	"AAAaaAAAaaAAAaGHHHH",
	"AAAaaAAAaaAAAaAAAAAAAGHHHH",
	"AAAaaAAAAAaGHHHH",
	"AAAaaAAAAAAAAAHHH",
	"AAAaaAAAAAaGHAaaaHH",
	"AAAaaAAAAAaAaaaaaAAAAHH",
	"AAAaaAAAAAaAAAAAAAADGHHHH",
	"AAAaaAAAaaAAAaAAAAAAAAAAAAGGGGGGAGHHHH",
	"AAAaaAAAaaAAAaAAAAAAAAAAAAAAAAAAH",
}

hg.sharp_pain = sharp_pain

local random_phrase = {
	"这里有点冷...",
	"一切都太安静了...",
	"此刻呼吸的感觉意外地舒服。",
	"如果这安静永远持续下去怎么办？",
	"为什么什么都没发生？",
	"我能听到自己的心跳...",
	"这寂静几乎震耳欲聋。",
	"时间似乎...有些不一样了。",
	"外面到底有没有人？",
	"我在这里站了多久了？",
	"空气里有股陈腐的味道。",
	"我不记得自己是怎么到这里来的。",
	"什么都不会改变，对吧？",
	"我现在醒着吗？",
	"阴影似乎比平时更深了。",
	"在这片寂静中，我的思绪格外喧嚣。",
	"什么时候变得这么黑了？",
	"我感觉自己被监视着。",
	"一切都和以前一模一样。",
	"有人知道我在这里吗？",
	"墙壁似乎更近了。",
	"我刚才在想什么来着？",
	"这里的时间流动得很奇怪。",
	"我记不清上次发生改变是什么时候了。",
	"这寂静开始变得有生命了。",
}


local fear_hurt_ironic = {
	"我打赌这背后肯定有教训...如果我能活下来的话。",
	"我未来的传记作者不会相信这一段的。",
	"好吧，这可真是个愚蠢的死法。",
	"至少我的人生不算无聊。",
	"给未来的自己：再也不要这样做了。",
	"这还不是最糟糕的死法。",
	"没事的。一切都会没事的。",
	"至少我死的时候知道我是对的。",
	"看来我是罪有应得。",
	"好吧，是我自己想要的冒险。",
	"葬礼上他们大概会笑吧。",
	"至少这会是个好故事...如果有人活着讲出来的话。",
	"我经历过更糟的...大概吧。",
}

local fear_phrases = {
	"没那么糟...对吧？",
	"我不想这样死。",
	"真的就这样结束了吗？",
	"这可不好。",
	"真的就这样结束了吗？",
	"我不想这样死。",
	"真希望能有一条出路。",
	"我后悔太多事了。",
	"不能就这样结束。",
	"我不敢相信这发生在我身上。",
	"我本该更认真对待这件事的。",
	"万一我挺不过去呢..？",
	"这比我预想的还要糟。",
	"太不公平了。",
	"我还不能放弃。",
	"我从没想过会变成这样。",
	"我本该听从本能的。",
	"呼吸。只要呼吸。",
	"手要稳。保持镇定。",
}

local is_aimed_at_phrases = {
    "天啊。就是这一刻了。",
    "别。动。",
    "我真的就要这样死了吗？",
    "我本该逃跑的。为什么我没跑？",
    "求你别扣扳机。求你了。",
    "我能看到他手指放在扳机上。",
    "我不想死。不想这样死。",
    "如果我求饶，情况会不会更糟？",
    "这不可能是真的。这不可能是真的。",
    "谁来救救我。求你了。谁来。",
    "我不想死在这样一个地方。",
    "我不想我的最后一个念头是恐惧。",
    "我不想死。",
}

local near_death_poetic = {
	"想站起来...但我就是站不起来...",
	"呼吸只剩下浅得没有内容的吸气...",
	"我已经分不清自己的眼睛是睁着还是闭着了...",
	"最后尝到的味道会是我自己的血和铁锈味。",
	"视线总是从东西上滑开。",
	"想不起怎么站起来了。",
	"一切都在我的颅骨里回响。",
	"眨眼之后要很久才能回过神来。",
	"手指什么都握不住。",
	"肺不肯被灌满。",
	"现在后悔已经没用了。",
}

local near_death_positive = {
	"我不想死。",
	"我必须活下去。",
	"还有机会。",
	"我不能让恐惧战胜我。",
	"再试一次。",
	"我拒绝死在这里。",
	"好吧...想清楚再做。",
	"别动。动只会更糟。",
	"慢慢呼吸。惊慌解决不了问题。",
	"只要还没结束，就还没结束。",
	"疼痛只是信号。无视它。",
	"如果这就是结局...至少会很快。",
	"我经历过更糟的。大概吧。",
	"这不是我预想的结局。",
}

local broken_limb = {
	"操。操。肯定断了！",
	"我能感觉到骨头碎片在动！",
	"他妈的断了。我猜..",
	"光是想想就觉得疼。肯定断了。",
	"我觉得这里不该这样弯曲。",
	"哦操。断了。",
	"我没看到开放性骨折，但我感觉我伤到了什么",
}

local dislocated_limb = {
	"对，那里不该这样弯的。",
	"我得把这骨头接回去。",
	"不...我得把它复位。",
	"那里实在太痛了。我可能需要检查一下。",
	"我的肢体错位了。",
}

local hungry_a_bit = {
    "唔，我饿了...",
    "有点吃的就好了...",
    "我饿了...",
    "我该吃点东西。",
}

local very_hungry = {
    "我的胃...呃...",
    "如果不吃东西，我会更难受...",
    "胃...该死...我感觉不舒服",
}

local after_unconscious = {
    "发生了什么？好痛...",
	"我在哪？为什么这么痛...",
	"我...我以为我要死了...",
	"我的头...发生了什么？",
	"我刚才是不是差点死了？",
	"感觉就像死过一次。",
	"上天没收走我？",
	"哦操...我的头好疼...",
	"现在想站起来很难...但我必须起来...",
	"我完全不认识这个地方...还是说认识？",
	"我再也不想经历这种事了！",
}

local slight_braindamage_phraselist = {
	"我不明白...",
	"这说不通...",
	"我在哪？",
	"嗯？这是什么..？",
	"我不知道发生了什么...",
	"喂？",
	"呃呃呃哦哦哦...      嗯...",
	"什么...正在发生？",
}

local braindamage_phraselist = {
	"Bbbee.. wheea mgh?!",
	"Bmmeee... mehk...",
	"Mm--hhhh. Mmm?",
	"Ghmgh whhh...",
	"Ahgg...mg?",
	"Hgghh... D-Dmmh.",
	"Lmmmphf, mp-hf!",
	"Heeelllhhpphp...",
	"Nghh... Gmh?",
	"Ggg... Bgh..",
	"Bhrhraihin.",
}

local cold_phraselist = {
	"变得好冷..",
	"对我来说太冷了。",
	"我在发抖，妈的，伙计。",
	"这里冷得吓人..",
	"需要点东西暖和一下...",
	"我感觉很冷...",
	"冷得我都觉得难受了，操。"
}

local freezing_phraselist = {
	"我...我..感..感觉不到自己的身-身体了..",
	"我..感-感觉不到我的腿了...",
	"我他妈快-快冻-冻僵了..",
	"我-我觉得我的脸都麻-麻木了..",
	"好-好冷..",
	"我..什么都感-感觉不到了..",
}

local numb_phraselist = {
	"不..不冷了..",
	"为什么...感觉暖暖的..？",
	"我觉得我没事了...应该...",
	"终于有点温暖了...",
	"我又暖和了...不知怎么的...",
	"我刚才还在发抖...这股热气从哪来的..？",
}

local hot_phraselist = {
	"我全身是汗..",
	"这热浪快把我烤死了..",
	"我的衣服都被汗浸透了，操。",
	"我身上的汗味真他妈难闻。我真该凉快一下...",
	"有点太热了，操，伙计。",
	"我热得厉害...",
	"这里怎么这么热？",
}

local heatstroke_phraselist = {
	"我需要水！！",
	"求你了...水...",
	"我感到头晕...操-",
	"我的头！-好痛..",
	"我的头好疼..",
}

local heatvomit_phraselist = {
	"那热气..-我要吐了-",
	"呃呃呃...我要吐了-",
	"操..哦呃..我感觉不太好-"
}

local hg_showthoughts = ConVarExists("hg_showthoughts") and GetConVar("hg_showthoughts") or CreateClientConVar("hg_showthoughts", "1", true, true, "Toggle thoughts of your character", 0, 1)

function string.Random(length)
	local length = tonumber(length)

    if length < 1 then return end

    local result = {}

    for i = 1, length do
        result[i] = allowedchars[math.random(#allowedchars)]
    end

    return table.concat(result)
end

function hg.nothing_happening(ply)
	if not IsValid(ply) then return end

	return ply.organism and ply.organism.fear < -0.6
end

function hg.fearful(ply)
	if not IsValid(ply) then return end

	return ply.organism and ply.organism.fear > 0.5
end

function hg.likely_to_phrase(ply)
	local org = ply.organism

	local pain = org.pain
	local brain = org.brain
	local blood = org.blood
	local fear = org.fear
	local temperature = org.temperature
	local broken_dislocated = org.just_damaged_bone and ((org.just_damaged_bone - CurTime()) < -3)

	return (broken_dislocated) and 5
		or (pain > 65) and 5
		or (temperature < 31 and 0.5)
		or (temperature > 38 and 0.5)
		or (blood < 3000 and 0.3)
		or (fear > 0.5 and 0.7)
		or (brain > 0.1 and brain * 5)
		or (fear < -0.5 and 0.05)
		or -0.1
end

function IsAimedAt(ply)
    return ply.aimed_at or 0
end

local function get_status_message(ply)
	if not IsValid(ply) then
		if CLIENT then
			ply = lply
		else
			return
		end
	end

	local nomessage = hook.Run("HG_CanThoughts", ply) --ply.PlayerClassName == "Gordon" || ply.PlayerClassName == "Combine"
	if nomessage ~= nil and nomessage == false then return "" end

    if ply:GetInfoNum("hg_showthoughts", 1) == 0 then return "" end

	local org = ply.organism
	
	if not org or not org.brain then return "" end

	local pain = org.pain
	local brain = org.brain
	local temperature = org.temperature
	local blood = org.blood
	local hungry = org.hungry
	local broken_dislocated = org.just_damaged_bone and ((org.just_damaged_bone + 3 - CurTime()) < -3)
	local fear = org.fear
	local adrenaline = org.adrenaline

	if broken_dislocated and org.just_damaged_bone then
		org.just_damaged_bone = nil
	end
	
	local broken_notify = (org.rarm == 1) or (org.larm == 1) or (org.rleg == 1) or (org.lleg == 1)
	local dislocated_notify = (org.rarm == 0.5) or (org.larm == 0.5) or (org.rleg == 0.5) or (org.lleg == 0.5)
	local after_unconscious_notify = org.after_otrub

	if not isnumber(pain) then return "" end

	local str = ""

	local most_wanted_phraselist
	
	if temperature < 35 then
		most_wanted_phraselist = temperature > 31 and cold_phraselist or (temperature < 28 and numb_phraselist or freezing_phraselist)
	elseif temperature > 38 then
		most_wanted_phraselist = temperature < 40 and hot_phraselist or heatstroke_phraselist
	end

	if not most_wanted_phraselist and hungry and hungry > 25 and math.random(3) == 1 then
		most_wanted_phraselist = hungry > 45 and very_hungry or hungry_a_bit
	end

	if (blood < 3100) or (pain > 75) or (broken_dislocated) or (broken_notify) or (dislocated_notify) then
		if pain > 75 and (broken_dislocated) then
			most_wanted_phraselist = math.random(2) == 1 and audible_pain or (broken_notify and broken_limb or dislocated_limb)
		elseif pain > 75 then
			most_wanted_phraselist = audible_pain
		elseif broken_dislocated then
			most_wanted_phraselist = (broken_notify and broken_limb or dislocated_limb)
		end

		if pain > 100 then
			most_wanted_phraselist = sharp_pain
		end

		if not most_wanted_phraselist then
			if (broken_dislocated_notify) and (blood < 3100) then
				most_wanted_phraselist = blood < 2900 and (near_death_poetic) or (math.random(2) == 1 and (broken_notify and broken_limb or dislocated_limb) or near_death_poetic)
			--elseif(broken_dislocated_notify)then
				--most_wanted_phraselist = (broken_notify and broken_limb or dislocated_limb)
			elseif(blood < 3100)then
				if adrenaline > 1.3 and fear < 0.5 then
					most_wanted_phraselist = near_death_positive
				else
					most_wanted_phraselist = near_death_poetic
				end
			end
		end
	elseif after_unconscious_notify then
		most_wanted_phraselist = after_unconscious
	elseif hg.nothing_happening(ply) then
		most_wanted_phraselist = random_phrase

		if hungry and hungry > 25 and math.random(5) == 1 then
			most_wanted_phraselist = hungry > 45 and very_hungry or hungry_a_bit
		end
	elseif hg.fearful(ply) then
		most_wanted_phraselist = ((IsAimedAt(ply) > 0.9) and is_aimed_at_phrases or (math.random(10) == 1 and fear_hurt_ironic or fear_phrases))
	end

	if brain > 0.1 then
		most_wanted_phraselist = brain < 0.2 and slight_braindamage_phraselist or braindamage_phraselist
	end
	
	if most_wanted_phraselist then
		str = most_wanted_phraselist[math.random(#most_wanted_phraselist)]

		return str
	else
		return ""
	end
end

local allowedlist_types = {
	heatvomit = heatvomit_phraselist,
}

function hg.get_phraselist(ply, type)
	if not IsValid(ply) then
		if CLIENT then
			ply = lply
		else
			return
		end
	end
	
	local nomessage = ply.PlayerClassName == "Gordon" || ply.PlayerClassName == "Combine"

	if nomessage then return "" end
    if ply:GetInfoNum("hg_showthoughts", 1) == 0 then return "" end

	local org = ply.organism	
	if not org or not org.brain then return "" end

	if not isstring(type) or not allowedlist_types[type] then return "" end

	local needed_list = allowedlist_types[type]

	local str = needed_list[math.random(#needed_list)]
	return str
end

function hg.get_status_message(ply)
	local txt = get_status_message(ply)

	return txt
end
