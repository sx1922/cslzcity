hg = hg or {}

local hg_font = ConVarExists("hg_font") and GetConVar("hg_font")
	or CreateClientConVar("hg_font", "Bahnschrift", true, false, "UI text font")

function hg.GetFont()
	local f = hg_font:GetString()
	return f ~= "" and f or "Bahnschrift"
end
