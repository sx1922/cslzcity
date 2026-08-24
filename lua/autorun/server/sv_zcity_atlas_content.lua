if not SERVER then return end

local atlasFiles = {
	"materials/zcity/neurotrauma/AfflictionIcons.png",
	"materials/zcity/neurotrauma/AfflictionIcons2.png",
	"materials/zcity/neurotrauma/MainIconsAtlas.png",
}

for _, f in ipairs(atlasFiles) do
	if file.Exists(f, "GAME") then
		resource.AddFile(f)
	else
		print("[Z-City] 警告: 客户端图集缺失, 无法下发 -> " .. f)
	end
end
