include("shared.lua")

-- 绘制逻辑在 cl_mission_intro_spawn_preview.lua（PostDrawTranslucentRenderables）

function ENT:Draw()
end

function ENT:DrawTranslucent()
end

function ENT:OnRemove()
	local key = self:EntIndex()
	if MissionIntro and MissionIntro._spawnPreviewModels and IsValid(MissionIntro._spawnPreviewModels[key]) then
		MissionIntro._spawnPreviewModels[key]:Remove()
		MissionIntro._spawnPreviewModels[key] = nil
	end
end
