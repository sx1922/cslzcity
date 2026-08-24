TOOL.Category = "RX 支援刷新"
TOOL.Name = "RX 地图刷新"
TOOL.Command = nil
TOOL.Information = {
	{ name = "left", text = "放置刷新点并生成物品" },
	{ name = "right", text = "删除最近的刷新点" },
	{ name = "reload", text = "删除全部刷新点 (R)" },
}

TOOL.ClientConVar["class"] = "weapon_bandage_sh"
TOOL.ClientConVar["yaw"] = "0"

local RX = MissionIntro and MissionIntro.RXMapRefresh

local function RX_CanUseTool(ply)
	if not IsValid(ply) then return false end
	if MissionIntro and MissionIntro.CanManage then
		return MissionIntro.CanManage(ply)
	end
	return ply:IsAdmin()
end

local function RX_GetClassFromTool(tool)
	local class = tool:GetClientInfo("class") or ""
	if class == "" and tool.GetOwner then
		local ply = tool:GetOwner()
		if IsValid(ply) then
			class = ply:GetInfo("rx_map_refresh_class") or ""
		end
	end
	return class
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end
	if not trace or not trace.Hit then return false end
	if not RX_CanUseTool(self:GetOwner()) then return false end

	local class = RX_GetClassFromTool(self)
	if not RX or not RX.AddPlacement then return false end

	local yaw = self:GetClientNumber("yaw", 0)
	local pos = trace.HitPos + trace.HitNormal * 2
	local ang = Angle(0, self:GetOwner():EyeAngles().y + yaw, 0)

	local ok, err = RX.AddPlacement(class, pos, ang)
	if not ok then
		self:GetOwner():ChatPrint("[RX地图刷新] 无效类名：" .. tostring(class))
		return false
	end

	self:GetOwner():ChatPrint("[RX地图刷新] 已放置：" .. class)
	return true
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	if not trace or not trace.Hit then return false end
	if not RX_CanUseTool(self:GetOwner()) then return false end
	if not RX or not RX.RemoveNearest then return false end

	if RX.RemoveNearest(trace.HitPos) then
		self:GetOwner():ChatPrint("[RX地图刷新] 已删除最近刷新点")
		return true
	end

	self:GetOwner():ChatPrint("[RX地图刷新] 附近没有刷新点")
	return false
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	if not RX_CanUseTool(self:GetOwner()) then return false end
	if not RX or not RX.ClearAll then return false end

	RX.ClearAll(self:GetOwner())
	return true
end

function TOOL:Deploy()
	if CLIENT then
		if RX and RX.RequestSync then
			RX.RequestSync()
		end
		return
	end

	if RX and RX.SyncToPlayers then
		RX.SyncToPlayers(self:GetOwner())
	end
end

function TOOL.BuildCPanel(panel)
	panel:Help("左键：在瞄准位置放置刷新点，并立即生成对应武器/实体。")
	panel:Help("物品不会被固定，可正常受物理影响；不会走近自动拾取，需按 E 拾取。")
	panel:Help("每次清图（回合间歇 / game.CleanUpMap）后会按保存数据重新生成。")
	panel:Help("数据按地图保存，换图后各图配置互不影响。")
	panel:Help("右键：删除最近的刷新点；R 键（重装）：删除本图全部刷新点。")

	panel:AddControl("TextBox", {
		Label = "武器 / 实体类名",
		Command = "rx_map_refresh_class",
	})

	panel:NumSlider("朝向偏移 (Yaw)", "rx_map_refresh_yaw", -180, 180, 0)

	panel:Help("示例：weapon_bandage_sh、weapon_medkit_sh、ent_ammo_9x19mmparabellum")
	panel:Help("保存路径：data/rx_mission_intro/map_refresh/当前地图.json")
	panel:Help("控制台：rx_map_refresh_reload / rx_map_refresh_clear")

	if panel.Button then
		panel:Button("删除全部刷新点 (R)", "rx_map_refresh_clear")
	else
		local btnClear = vgui.Create("DButton")
		btnClear:SetText("删除全部刷新点 (R)")
		btnClear.DoClick = function()
			RunConsoleCommand("rx_map_refresh_clear")
		end
		panel:AddItem(btnClear)
	end
end

if CLIENT then
	language.Add("tool.rx_map_refresh.name", "RX 地图刷新")
	language.Add("tool.rx_map_refresh.category", "RX 支援刷新")
	language.Add("tool.rx_map_refresh.desc", "放置清图后自动刷新的武器或实体")
	language.Add("tool.rx_map_refresh.left", "放置刷新点")
	language.Add("tool.rx_map_refresh.right", "删除最近刷新点")
	language.Add("tool.rx_map_refresh.reload", "删除全部刷新点 (R)")

	local previewColor = Color(120, 200, 255, 220)

	function TOOL:DrawHUD()
		if not RX_CanUseTool(LocalPlayer()) then return end

		local rows = RX and RX.ClientRows or {}
		if not istable(rows) or #rows == 0 then return end

		surface.SetFont("ChatFont")

		for i, row in ipairs(rows) do
			if not istable(row.pos) then continue end

			local pos = Vector(tonumber(row.pos.x) or 0, tonumber(row.pos.y) or 0, tonumber(row.pos.z) or 0)
			if EyePos():DistToSqr(pos) > 10000000 then continue end

			local angTbl = row.ang or {}
			local ang = Angle(tonumber(angTbl.p) or 0, tonumber(angTbl.y) or 0, tonumber(angTbl.r) or 0)
			local label = tostring(row.class or "?") .. " #" .. tostring(row.id or i)

			cam.Start3D()
				render.SetColorMaterial()
				render.DrawWireframeSphere(pos, 12, 12, 12, previewColor)
				render.DrawWireframeBox(pos, ang, Vector(8, 8, 8), Vector(-8, -8, -8), previewColor)
			cam.End3D()

			local data = pos:ToScreen()
			if data.visible then
				draw.SimpleTextOutlined(label, "ChatFont", data.x, data.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
			end
		end
	end
end
