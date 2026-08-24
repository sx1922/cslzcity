-- 全模式禁用 Homigrad 肢解 / 碎尸 / 爆头碎肉（RXsend、HMCD、TDM 等均生效）

if not SERVER then return end

MissionIntro = MissionIntro or {}

function MissionIntro.ShouldDisableHomigradGore()
	if hook.Run("MissionIntro_ShouldDisableHomigradGore") == false then return false end
	return true
end

local function MI_GoreBlocked()
	return MissionIntro.ShouldDisableHomigradGore()
end

local GORE_TARGETS = {
	{ key = "_miWrapAmputateLimb", path = { "hg", "organism", "AmputateLimb" } },
	{ key = "_miWrapExplodeHead", path = { "hg", "ExplodeHead" } },
	{ key = "_miWrapGibInput", global = "Gib_Input" },
	{ key = "_miWrapGibRemoveBone", global = "Gib_RemoveBone" },
	{ key = "_miWrapSpawnMeatGore", global = "SpawnMeatGore" },
}

local function MI_ResolveTarget(spec)
	if spec.global then
		return _G[spec.global]
	end

	local node = _G
	for _, part in ipairs(spec.path) do
		if not node then return nil end
		node = node[part]
	end

	return node
end

local function MI_AssignTarget(spec, fn)
	if spec.global then
		_G[spec.global] = fn
		return
	end

	local node = _G
	for i = 1, #spec.path - 1 do
		node = node[spec.path[i]]
		if not node then return end
	end

	node[spec.path[#spec.path]] = fn
end

local function MI_WrapTarget(spec)
	local current = MI_ResolveTarget(spec)
	if not isfunction(current) then return false end
	if current == MissionIntro[spec.key] then return true end

	local origKey = spec.key .. "Orig"
	MissionIntro[origKey] = current

	local function wrapper(...)
		if MI_GoreBlocked() then return end
		return MissionIntro[origKey](...)
	end

	MissionIntro[spec.key] = wrapper
	MI_AssignTarget(spec, wrapper)
	return true
end

function MissionIntro.InstallHomigradGoreBlocks()
	if not hg then return false end

	local ready = true
	for _, spec in ipairs(GORE_TARGETS) do
		if not MI_WrapTarget(spec) then
			ready = false
		end
	end

	return ready
end

local function MI_TryInstallGoreBlocks()
	MissionIntro.InstallHomigradGoreBlocks()
end

hook.Add("Initialize", "MissionIntro_DisableHomigradGore", function()
	timer.Simple(0, MI_TryInstallGoreBlocks)
end)

hook.Add("InitPostEntity", "MissionIntro_DisableHomigradGore", function()
	timer.Simple(0, MI_TryInstallGoreBlocks)
end)

-- Homigrad headgib 可能在 rx_mission_intro 之后加载，需周期性重新包裹
timer.Create("MissionIntro_DisableHomigradGore_Watchdog", 2, 0, MI_TryInstallGoreBlocks)
