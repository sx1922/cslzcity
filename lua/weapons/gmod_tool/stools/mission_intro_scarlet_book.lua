TOOL.Category = "RX 任务入场"
TOOL.Name = "#tool.mission_intro_scarlet_book.name"
TOOL.Command = nil
TOOL.Information = {
	{ name = "left", text = "#tool.mission_intro_scarlet_book.left" },
	{ name = "right", text = "#tool.mission_intro_scarlet_book.right" },
	{ name = "reload", text = "#tool.mission_intro_scarlet_book.reload" },
}

TOOL.ClientConVar["yaw"] = "0"

local SCARLET_BOOK_CLASS = "ent_mission_intro_scarlet_book"

local function MI_CanUseTool(ply)
	if not IsValid(ply) then return false end
	if MissionIntro and MissionIntro.CanManage then
		return MissionIntro.CanManage(ply)
	end
	return ply:IsAdmin()
end

local function MI_FindScarletBook(trace)
	if MissionIntro and MissionIntro.ResolveToolTraceEntity then
		return MissionIntro.ResolveToolTraceEntity(trace, SCARLET_BOOK_CLASS, 72)
	end

	local ent = trace and trace.Entity
	if IsValid(ent) and ent:GetClass() == SCARLET_BOOK_CLASS then
		return ent
	end

	return nil
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end
	if not MI_CanUseTool(self:GetOwner()) then return false end
	if not trace or not trace.Hit then return false end

	local yaw = trace.HitNormal:Angle().y + self:GetClientNumber("yaw", 0)
	local pos = trace.HitPos + trace.HitNormal * 2
	local ang = Angle(0, yaw, 0)

	if MissionIntro and MissionIntro.CreateScarletBook then
		MissionIntro.CreateScarletBook(pos, ang, false)
		return true
	end

	return false
end

function TOOL:RightClick(trace)
	if CLIENT then return true end

	local ply = self:GetOwner()
	if not MI_CanUseTool(ply) then return false end

	local ent = MI_FindScarletBook(trace)
	if IsValid(ent) then
		if MissionIntro and MissionIntro.RemoveScarletBook then
			MissionIntro.RemoveScarletBook(ent)
		else
			ent:Remove()
			if MissionIntro and MissionIntro.SaveScarletBooksToDisk then
				MissionIntro.SaveScarletBooksToDisk()
			end
		end

		if IsValid(ply) then
			ply:ChatPrint("[MissionIntro] " .. (MissionIntro.L and MissionIntro.L("log_tool_removed_scarlet_book") or "已删除祷告书"))
		end
		return true
	end

	if IsValid(ply) then
		ply:ChatPrint("[MissionIntro] " .. (MissionIntro.L and MissionIntro.L("log_tool_scarlet_book_miss") or "未瞄准祷告书，请靠近书本后右键删除"))
	end

	return false
end

function TOOL:Reload(trace)
	if CLIENT then return true end

	local ply = self:GetOwner()
	if not MI_CanUseTool(ply) then return false end

	local count = 0
	if MissionIntro and MissionIntro.GetScarletBookEntities then
		count = #MissionIntro.GetScarletBookEntities()
	end

	if MissionIntro and MissionIntro.RemoveAllScarletBooks then
		MissionIntro.RemoveAllScarletBooks(true)
	end

	if IsValid(ply) then
		local msg = MissionIntro.L and MissionIntro.L("log_tool_cleared_scarlet_books") or "已清除全部祷告书"
		ply:ChatPrint("[MissionIntro] " .. msg .. " (" .. count .. ")")
	end

	return true
end

function TOOL.BuildCPanel(panel)
	panel:Help("左键：放置猩红祷告书（始终可见，固定不可移动）")
	panel:Help("右键：删除瞄准的祷告书")
	panel:Help("重装：清除全部祷告书")
	panel:NumSlider("朝向偏移 (Yaw)", "mission_intro_scarlet_book_yaw", -180, 180, 0)
	panel:Help("仅本批猩红重生者可祷告(10s)；召唤阶段(3分钟)内其他人可长按E破坏(5s)。回合最后4分钟不可开始祷告。")
end

if CLIENT then
	language.Add("tool.mission_intro_scarlet_book.name", "猩红祷告书")
	language.Add("tool.mission_intro_scarlet_book.desc", "放置猩红仪式祷告书")
	language.Add("tool.mission_intro_scarlet_book.left", "放置祷告书")
	language.Add("tool.mission_intro_scarlet_book.right", "删除祷告书")
	language.Add("tool.mission_intro_scarlet_book.reload", "清除全部")
end
