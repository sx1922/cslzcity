# Z-City 模块化重构操作手册

> 本文档为逐步执行指南，每一步包含：改什么文件、改哪几行、怎么验证。
> 执行者无需了解全局架构，按顺序操作即可。
> 预计总工时：20-30小时（分多天完成）。

---

## 前置准备

### 开发环境
- Garry's Mod 专用服务器（本地测试用）
- 文本编辑器（VSCode + Lua 插件）
- Git

### 开始前必做
```
cd Z-City-main
git init
git add -A
git commit -m "chore: initial snapshot before refactor"
```

之后每完成一个 Step 立即提交一次。出问题时：
```
git diff HEAD~1                                # 查看上一步改了什么
git checkout HEAD~1 -- <file_path>            # 恢复单个文件
git revert HEAD                                # 回滚整个提交
```

---

## 阶段0：基础设施与Bug修复

风险等级说明：极低(新建文件) / 低(删重复/字符串替换) / 中(函数合并)

### Step 0: 代码规范配置 [极低风险]

新建3个文件，不动任何现有代码。

#### 0.1 创建 .editorconfig

路径: `Z-City-main/.editorconfig`

```ini
root = true

[*]
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
charset = utf-8

[*.lua]
indent_style = tab
indent_size = 4
tab_width = 4

[*.md]
indent_style = space
indent_size = 2
trim_trailing_whitespace = false

[*.{yml,yaml}]
indent_style = space
indent_size = 2

[*.json]
indent_style = space
indent_size = 2
```

验证: 用编辑器打开 .lua 确认 Tab 缩进。

#### 0.2 创建 .luacheckrc

路径: `Z-City-main/.luacheckrc`

```lua
globals = {
    "zb", "hg", "Glide", "COMMANDS", "COMMAND_GETACCES",
    "ZBATTLE_BIGMAP", "VFIRE_DISABLED", "GM",
    "lply", "Dynamic", "scoreBoardMenu",
    "spect", "prevspect", "viewmode", "BlurBackground",
}

read_globals = {
    "derma", "surface", "vgui", "render", "draw", "gui",
    "net", "hook", "timer", "file", "util", "player", "ents",
    "team", "game", "engine",
    "RunConsoleCommand", "CreateClientConVar", "ConVarExists",
    "GetConVar", "CreateConVar", "AddCSLuaFile", "IsValid",
    "FindMetaTable", "AddOriginToPVS", "SetGlobalVar", "GetGlobalVar",
    "print", "Msg", "MsgN", "ErrorNoHalt", "include",
    "string", "table", "math", "os", "utf8",
    "LocalPlayer", "Entity", "Color", "Vector", "Angle", "Matrix", "Material",
    "TEXT_ALIGN_LEFT", "TEXT_ALIGN_CENTER", "TEXT_ALIGN_RIGHT",
    "TEXT_ALIGN_TOP", "TEXT_ALIGN_BOTTOM",
    "MOVETYPE_NOCLIP", "MOVETYPE_WALK",
    "OBS_MODE_NONE", "OBS_MODE_ROAMING",
    "TEAM_SPECTATOR", "TEAM_UNASSIGNED",
    "HUD_PRINTTALK", "IN_ATTACK", "IN_ATTACK2", "IN_RELOAD",
    "FrameTime", "CurTime", "ScrW", "ScrH",
    "ScreenScale", "ScreenScaleH",
    "Lerp", "LerpVector", "LerpAngle",
    "ipairs", "pairs", "next", "select",
    "tostring", "tonumber", "type",
    "istable", "isfunction", "isnumber", "isstring",
    "isbool", "isvector", "isangle", "ispanel",
    "pcall", "rawget", "rawset",
    "setmetatable", "getmetatable",
    "setfenv", "getfenv", "loadstring",
    "ULib", "eightbit", "BlackterioExtraFunctions",
}

unused_globals = { "Dynamic", "scoreBoardMenu" }
```

验证: 安装 luacheck 后运行 `luacheck . --no-color --codes`，无 fatal error 即可。未安装则跳过。

#### 0.3 创建 CI Workflow

路径: `Z-City-main/.github/workflows/lint.yml`

```yaml
name: Lua Lint

on:
  push:
    branches: [ main, develop, refactor/* ]
  pull_request:
    branches: [ main, develop ]

jobs:
  luacheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install luacheck
        run: |
          sudo apt-get update
          sudo apt-get install -y lua5.3 luarocks
          sudo luarocks install luacheck
      - name: Run luacheck
        run: luacheck . --no-color --codes --no-unused-args --no-max-line-length || true
      - name: Check Lua syntax
        run: |
          errors=0
          for f in $(find . -name "*.lua" -not -path "*/.git/*"); do
            if ! lua5.3 -p "$f" 2>/dev/null; then
              echo "Syntax error: $f"
              errors=$((errors + 1))
            fi
          done
          [ $errors -eq 0 ]
```

验证: push 到 GitHub 后能看到 workflow 运行。

提交: `git commit -am "refactor: Step 0 - add editorconfig, luacheckrc, CI"`

---

### Step 1: 删除 sv_roundsystem.lua 重复代码块 [低风险]

文件: `gamemodes/zcity/gamemode/libraries/sv_roundsystem.lua`

**背景**: 文件末尾 L797-895 整个 `if SERVER then ... end` 块是前面 L504-740 的完全副本。重复注册了 AdminSetGameMode、AdminSetGameQueue、SendGameModesToClient 等，后者覆盖前者。

操作:

1. 找到文件末尾的 `if SERVER then` 块（特征：内部有 `util.AddNetworkString("ZB_NotifyRoundListChange")`）
2. 删除整个块直到文件末尾的 `end`

合并差异（删除前先做）:

找到第一个 `net.Receive("AdminSetGameMode", function` (约 L643)，在读取完 modeKey 后、`if modeKey == "random"` 之前，插入：

```lua
    if !(ply:IsSuperAdmin() or ply:IsAdmin()) and zb.modes[modeKey] and !zb.modes[modeKey]:CanLaunch() then
        ply:ChatPrint("This mode can't launch (No points or Is blocked): " .. modeKey)
        return
    end
```

然后确认文件顶部 (L504-508) 已有 `util.AddNetworkString("ZB_NotifyRoundListChange")`。

验证:
- [ ] 文件行数从 ~895 减少到 ~795
- [ ] 启动服务器无 Lua 报错
- [ ] 管理员面板切模式正常
- [ ] 模式队列操作正常
- [ ] 新玩家加入模式信息正常同步

提交: `git commit -am "refactor: Step 1 - remove sv_roundsystem duplicate block"`

---

### Step 2: 合并 hg.DrawBlur 重复定义 [低风险]

**背景**: hg.DrawBlur 在3处定义。保留 cl_init.lua 中带 blursettings 缓存的版本（性能最优），删除另外2个。

操作:

1. **保留** `gamemodes/zcity/gamemode/cl_init.lua` 中的 hg.DrawBlur（带 blursettings 缓存版本，约 L54-97）。不动它。

2. **删除** `gamemodes/zcity/gamemode/shared.lua` 中的 hg.DrawBlur 定义（约 L12-37）。删除 `local blur = Material(...)` 和整个函数。保留文件其他内容。

3. **删除** `lua/homigrad/libraries/pointshop/derma/cl_pointshop.lua` 中的 hg.DrawBlur 定义（约 L14-39）。删除 `local blur`、`local hg_potatopc` 和整个函数。保留文件其他内容。

4. **修复 BlurBackground 赋值**:
   - 打开 `lua/initpost/` 目录下包含 `hg.BlurBackground = hg.DrawBlur` 的文件（搜索确认具体文件名）
   - 删除该行
   - 在 `gamemodes/zcity/gamemode/cl_init.lua` 的 hg.DrawBlur 函数定义之后添加：
     ```lua
     BlurBackground = hg.DrawBlur
     hg.BlurBackground = hg.DrawBlur
     ```

验证:
- [ ] `grep -rn "function hg.DrawBlur" --include="*.lua"` 只返回1个结果
- [ ] 有模糊背景的 UI 正常显示
- [ ] PointShop 背景模糊正常

提交: `git commit -am "refactor: Step 2 - consolidate hg.DrawBlur to single definition"`

---

### Step 3: 提取 font() 函数 [低风险]

**背景**: 完全相同的 font() 函数在6个文件中重复。

操作:

1. 创建 `lua/homigrad/core/` 目录（如果不存在）

2. 创建 `lua/homigrad/core/cl_font.lua`:
   ```lua
   local hg_font = ConVarExists("hg_font") and GetConVar("hg_font")
       or CreateClientConVar("hg_font", "Bahnschrift", true, false, "UI text font")

   function hg.GetFont()
       local f = hg_font:GetString()
       return f ~= "" and f or "Bahnschrift"
   end
   ```

3. 在以下6个文件中，将完整的 font() 函数定义替换为 `local font = hg.GetFont`:
   - `gamemodes/zcity/gamemode/cl_init.lua` (~L317)
   - `lua/homigrad/cl_hud.lua` (~L77)
   - `gamemodes/zcity/gamemode/modes/homicide/cl_homicide.lua` (~L101)
   - `lua/initpost/cl_derma_skin.lua` (~L23)
   - `lua/initpost/cl_derma_skin_hokmah.lua` (~L12)
   - `lua/initpost/menu-n-derma/derma/cl_menu_options.lua` (~L21)

   如果文件中有对应的 `local hg_font = CreateClientConVar(...)` 声明，也可以一并删除。

4. 确认 `lua/autorun/loader.lua` 会递归扫描 `homigrad/core/` 目录。由于 loader 递归扫描整个 `homigrad/` 目录，core/ 会自动被包含。

验证:
- [ ] `grep -rn "local font = function" --include="*.lua"` 返回0结果
- [ ] `grep -rn "hg.GetFont" --include="*.lua"` 返回6+结果
- [ ] 所有 UI 字体正常显示
- [ ] 修改 ConVar `hg_font` 后字体变化

提交: `git commit -am "refactor: Step 3 - extract font() to hg.GetFont()"`

---

### Step 4: 替换脏话 Hook 名 [低风险，每次1个]

每次替换1个，用 grep 确认旧名完全消失后，再替换下一个。

替换清单:

| # | 旧名 | 新名 | 文件 |
|---|------|------|------|
| 1 | `"FUCKINGSAMENAMEUSEDINHOOKFUCKME"` | `"ZC_SpectatorHUD"` | `cl_init.lua` |
| 2 | `"zzzzzzzUwU"` | `"ZC_SpectatorCamera"` | `cl_init.lua` |
| 3 | `"huyhuyUwU"` | `"ZC_ScreenFade"` | `cl_init.lua` |
| 4 | `"zcityhuy"` | `"ZC_PlayerConnect"` | `cl_init.lua` |
| 5 | `"furryhuy"` | `"ZC_LoadPlayerInfo"` | `cl_init.lua` |
| 6 | `"fuckmapchanges"` | `"ZC_MapChangeTimer"` | `init.lua` |
| 7 | `"dontfuckingdamagethem"` | `"Coop_DamageBlock"` | `modes/coop/sv_coop.lua` |
| 8 | `"fucking bullshit"` | `"ZC_PlayerThink"` | `lua/homigrad/cl_utility.lua` |
| 9 | `"fuckclientsidemodels"` | `"ZC_ClearClientsideModels"` | `lua/homigrad/cl_utility.lua` |
| 10 | `"fuckragdolls"` | `"ZC_RagdollPVS"` | `lua/homigrad/fake/sv_tier_0.lua` |
| 11 | `"fuckingremoveragdoll"` | `"ZC_RemoveRagdoll"` | `lua/homigrad/fake/sv_tier_0.lua` |
| 12 | `"fuckingremoveragdoll"` | `"ZC_RemoveRagdoll"` | `lua/homigrad/fake/cl_fake.lua` |
| 13 | `"fuckyou"` | `"ZC_FakeInit"` | `lua/homigrad/fake/cl_fake.lua` |
| 14 | `"ffuckk"` | `"ZC_InitPostEntity"` | `lua/homigrad/sv_util.lua` |
| 15 | `"fuckgmodok"` | `"ZC_FixNoclipGesture"` | `lua/weapons/homigrad_base/shared.lua` |
| 16 | `"fuckthoseladders"` | `"ZC_LadderCleanup"` | `lua/entities/func_useableladder2.lua` |
| 17 | `"huyUwU"` | `"ZC_InputMouseApply"` | `lua/weapons/homigrad_base/cl_camera.lua` |

每个替换后用 PowerShell 验证：
```powershell
Select-String -Path "*.lua" -Pattern "<旧名>" -Recurse
```
返回空结果 = 替换成功。

全部替换完后统一验证功能：
- [ ] 观战系统（死亡后 HUD + 摄像机切换）
- [ ] 屏幕淡出效果
- [ ] Coop 模式友军不受伤害
- [ ] 布娃娃系统
- [ ] 武器瞄准/摄像机
- [ ] 梯子使用
- [ ] 伪装系统

提交: `git commit -am "refactor: Step 4 - replace profanity hook names with ZC_*"`

---

## 阶段1：大文件模块化拆分

前提: 阶段0全部完成并验证通过。

### Step 5: cl_init.lua 拆分 [中风险]

文件: `gamemodes/zcity/gamemode/cl_init.lua` (1115行 -> ~80行 + 6个新文件)

所有新文件放在 `gamemodes/zcity/gamemode/libraries/` 下，由 loader.lua 自动加载。

创建6个新文件:

**A. cl_spectator.lua** - 从 cl_init.lua 提取:
- `net.Receive("ZB_SpectatePlayer", ...)`
- HUDPaint 中观战 HUD 部分 (hook名 "ZC_SpectatorHUD")
- CalcView 中观战摄像机部分 (hook名 "ZC_SpectatorCamera")

**B. cl_effects.lua** - 从 cl_init.lua 提取:
- 屏幕淡出渲染 (hook名 "ZC_ScreenFade")
- PunishLightningEffect 网络接收和渲染
- AnotherLightningEffect 网络接收和渲染

**C. cl_roundinfo.lua** - 从 cl_init.lua 提取:
- `net.Receive("RoundInfo", ...)`

**D. cl_scoreboard.lua** - 从 cl_init.lua 提取 (~500行):
- GM:ScoreboardShow / GM:ScoreboardHide
- 计分板全部逻辑

**E. cl_playermutes.lua** - 从 cl_init.lua 提取:
- 玩家声音设置
- net.Receive("hg_playerConnect"/"hg_LoadPlayerInfo")
- 静音系统

**F. cl_snake.lua** - 从 cl_init.lua 提取 (~175行):
- 贪吃蛇游戏全部代码

修改 cl_init.lua:
- 删除上述已提取代码
- 将局部变量 spect/prevspect/viewmode 改为 zb 表字段: `zb.spect`, `zb.prevspect`, `zb.viewmode`
- cl_spectator.lua 中对应使用 zb.spect 等

cl_init.lua 剩余 (~80行):
- zb 初始化 + include shared/loader
- ConVar 定义
- hg.DrawBlur 缓存版本
- BlurBackground 赋值
- CurrentRound() 函数
- GM:AddHint
- Player Spawn 窗口闪烁

验证:
- [ ] cl_init.lua 约80行
- [ ] libraries/ 新增6个 cl_ 文件
- [ ] 观战系统完整正常
- [ ] 计分板正常
- [ ] 闪电效果正常
- [ ] 贪吃蛇正常

提交: `git commit -am "refactor: Step 5 - split cl_init.lua into 6 modules"`

---

### Step 6: init.lua 拆分 [中风险]

文件: `gamemodes/zcity/gamemode/init.lua` (551行 -> ~180行 + 2个新文件)

**A. libraries/sv_spawning.lua** - 提取:
- 出生点系统全部代码 (zb:GetTeamSpawn, zb:GetRandomSpawn, zb:FurthestFromEveryone, PlayerSelectSpawn hook 等)

**B. libraries/sv_spectator.lua** - 提取:
- 观战系统服务端 (net.Receive("ZB_ChooseSpecPly"), PlayerDeathThink, IsSpawnpointSuitable 中观战逻辑等)

init.lua 保留 (~180行):
- 初始化 + include
- GM:PlayerSpawn
- GM:PlayerInitialSpawn
- GM:EntityKeyValue, CanProperty
- Coop changelevel 逻辑

验证:
- [ ] init.lua 约180行
- [ ] 出生点选择正常
- [ ] 观战系统正常
- [ ] 回合正常启动

提交: `git commit -am "refactor: Step 6 - split init.lua into 3 modules"`

---

### Step 7: sv_roundsystem.lua 拆分 [中风险]

文件: `gamemodes/zcity/gamemode/libraries/sv_roundsystem.lua` (~795行 -> ~220行 + 2个新文件)

**A. libraries/sv_mode_selection.lua** - 提取:
- COMMANDS.bigmap
- zb.GetAvailableModes, zb.WeightedChance, zb.GetWorldSize
- zb.GetRoundName, zb.RoundList, zb.RerollChances
- zb.ModesPlaytime

**B. libraries/sv_mode_admin.lua** - 提取:
- zb.SendModesInfo, zb.SendRoundList, zb.SyncQueueToAdmins
- 所有 net.Receive("Admin*") 处理器
- zb.GetAllAdmins, zb.Unfreeze, zb.Freeze
- 管理员相关 COMMANDS

sv_roundsystem.lua 保留 (~220行):
- 回合状态常量/变量
- RoundThink / EndRoundThink / RoundThinkTimer
- RoundStart / EndRound 核心函数
- KillPlayers

验证:
- [ ] sv_roundsystem.lua 约220行
- [ ] 回合自动开始/结束正常
- [ ] 管理员切模式/队列正常
- [ ] 模式概率选择正常

提交: `git commit -am "refactor: Step 7 - split sv_roundsystem into 3 modules"`

---

## 阶段2：配置外部化

前提: 阶段1全部完成并验证通过。

### Step 8: 配置加载框架 [极低风险]

新建文件 `lua/homigrad/core/sh_config.lua`:

```lua
hg.Config = hg.Config or {}
hg.Config.cache = hg.Config.cache or {}

function hg.Config.Load(module, name, defaults)
    defaults = defaults or {}
    local key = module .. "/" .. name
    if hg.Config.cache[key] then return hg.Config.cache[key] end

    local path = "zcity_config/" .. module .. "/" .. name .. ".json"
    local result = table.Copy(defaults)

    if file.Exists(path, "DATA") then
        local raw = file.Read(path, "DATA")
        local ok, data = pcall(util.JSONToTable, raw)
        if ok and data then
            for k, v in pairs(data) do result[k] = v end
        end
    else
        file.CreateDir("zcity_config/" .. module)
        file.Write(path, util.TableToJSON(defaults, true))
    end

    hg.Config.cache[key] = result
    return result
end

function hg.Config.Save(module, name, data)
    local path = "zcity_config/" .. module .. "/" .. name .. ".json"
    file.CreateDir("zcity_config/" .. module)
    file.Write(path, util.TableToJSON(data, true))
    local key = module .. "/" .. name
    hg.Config.cache[key] = data
end

function hg.Config.Get(module, name, key)
    local config = hg.Config.Load(module, name)
    return config[key]
end
```

验证:
- [ ] 服务器启动无报错
- [ ] hg.Config.Load/Save 可正常调用

提交: `git commit -am "refactor: Step 8 - add config loader framework"`

---

### Step 9: 武器配置外部化 [低风险]

选择5个代表武器做试点: akm, deagle, m249, mp5, svd

在武器基类 `lua/weapons/homigrad_base/shared.lua` 的 SWEP:Initialize 中添加:

```lua
function SWEP:LoadConfig()
    local class = self:GetClass():Replace("weapon_", "")
    local override = hg.Config.Load("weapons", class, {})
    for k, v in pairs(override) do
        if self[k] ~= nil then self[k] = v
        elseif self.Primary and self.Primary[k] ~= nil then self.Primary[k] = v
        end
    end
end
```

在 SWEP:Initialize 末尾调用 `self:LoadConfig()`。

为每个试点武器创建 JSON 配置:

`zcity_config/weapons/akm.json` (DATA目录自动创建):
```json
{
    "Damage": 50,
    "ClipSize": 30,
    "Wait": 0.095,
    "ReloadTime": 5,
    "Ergonomics": 0.8,
    "Penetration": 15,
    "weight": 4
}
```

其他4个武器同理，从各自 SWEP 文件中提取数值到 JSON。

验证:
- [ ] 删除 JSON 文件后武器使用 SWEP 默认值（不崩溃）
- [ ] 修改 JSON 中 Damage 后游戏中伤害变化
- [ ] 5把武器功能完全正常

提交: `git commit -am "refactor: Step 9 - externalize 5 weapon configs"`

---

### Step 10: 模式参数外部化 [低风险]

每个模式创建对应的 JSON 配置文件:

以 DM 模式为例 - 创建 JSON:
```json
{
    "ROUND_TIME": 400,
    "MapSize": 7500,
    "ZoneTimeToShrink": 120,
    "FreezeTime": 20
}
```

在模式的 sh_dm.lua 中，用 hg.Config.Load 覆盖默认值:
```lua
local config = hg.Config.Load("modes", "dm", {
    ROUND_TIME = 400,
    MapSize = 7500,
    ZoneTimeToShrink = 120,
    FreezeTime = 20
})
for k, v in pairs(config) do MODE[k] = v end
```

需要外部化的模式参数:

| 模式 | 文件 | 关键参数 |
|------|------|----------|
| homicide | sh_homicide.lua | ROUND_TIME, PoliceTime, FadeScreenTime |
| dm | sh_dm.lua | MapSize, ZoneTimeToShrink, FreezeTime |
| tdm | sh_tdm.lua | MapSize, BuyMenuPrices |
| defense | sv_defense_config.lua | 全部参数 |
| coop | sv_coop.lua | 回合时间 |

验证:
- [ ] 删除 JSON 后使用代码默认值
- [ ] 修改 JSON 后行为变化
- [ ] 各模式功能正常

提交: `git commit -am "refactor: Step 10 - externalize mode configs"`

---

### Step 11: Loot表外部化 [低风险]

将内联的 Loot 表提取到 JSON 文件:

**Homicide Loot:**
提取 `sh_homicide.lua` 中约160条 LootTable 条目到:
```
zcity_config/modes/homicide_loot.json
```

**Defense Wave Definitions:**
提取 `sv_defense_config.lua` 中24个波次定义到:
```
zcity_config/modes/defense_waves.json
```

**Defense Shop Items:**
提取商店物品到:
```
zcity_config/modes/defense_shop.json
```

在对应的 Lua 文件中改为从 hg.Config.Load 读取。

验证:
- [ ] Homicide 战利品掉落正常
- [ ] Defense 波次正常推进
- [ ] Defense 商店物品价格/内容正常

提交: `git commit -am "refactor: Step 11 - externalize loot tables"`

---

### Step 12: VGUI主题外部化 [极低风险]

创建 `zcity_config/theme/default.json`:
```json
{
    "main": [150, 0, 0],
    "secondary": [155, 0, 0, 240],
    "background": [25, 25, 35, 220],
    "info": [0, 100, 255],
    "success": [0, 200, 0],
    "error": [255, 0, 0],
    "warning": [255, 200, 0]
}
```

在 `lua/initpost/cl_derma_skin.lua` 中，用 hg.Config.Load 加载并覆盖默认颜色值。

验证:
- [ ] 删除 JSON 后使用代码默认颜色
- [ ] 修改 JSON 颜色后 UI 变化
- [ ] 所有 UI 元素颜色正常

提交: `git commit -am "refactor: Step 12 - externalize theme colors"`

---

## 阶段3：模式系统插件化

前提: 阶段2全部完成并验证通过。

### Step 13: 模式注册API [中风险]

新建 `gamemodes/zcity/gamemode/libraries/modes/api.lua`:

```lua
zb.ModeAPI = zb.ModeAPI or {}
zb.ModeAPI.registry = {}

function zb.ModeAPI.Register(id, def)
    zb.ModeAPI.registry[id] = {
        id = id,
        name = def.name or id,
        description = def.description or "",
        base = def.base,
        version = def.version or "1.0.0",
        author = def.author or "unknown",
        dependencies = def.dependencies or {},
        config = def.config or {},
        hooks = def.hooks or {},
    }
end

function zb.ModeAPI.Unregister(id)
    zb.ModeAPI.registry[id] = nil
end

function zb.ModeAPI.Get(id)
    return zb.ModeAPI.registry[id]
end

function zb.ModeAPI.GetAll()
    return zb.ModeAPI.registry
end

function zb.ModeAPI.IsAvailable(id)
    local mode = zb.ModeAPI.registry[id]
    if not mode then return false end
    for _, dep in ipairs(mode.dependencies) do
        if not zb.ModeAPI.registry[dep] then return false end
    end
    return true
end

function zb.ModeAPI.GetAvailable()
    local result = {}
    for id, _ in pairs(zb.ModeAPI.registry) do
        if zb.ModeAPI.IsAvailable(id) then
            table.insert(result, id)
        end
    end
    return result
end

function zb.ModeAPI.RunHook(hookName, ...)
    for id, mode in pairs(zb.ModeAPI.registry) do
        if mode.hooks[hookName] then
            mode.hooks[hookName](...)
        end
    end
end

function zb.ModeAPI.ResolveInheritance(id)
    local mode = zb.ModeAPI.registry[id]
    if not mode or not mode.base then return mode end
    local parent = zb.ModeAPI.ResolveInheritance(mode.base)
    if not parent then return mode end
    return table.Inherit(table.Copy(parent), mode)
end

function zb.ModeAPI.ValidateEnvironment()
    local results = {}
    for id, mode in pairs(zb.ModeAPI.registry) do
        local issues = {}
        if mode.dependencies then
            for _, dep in ipairs(mode.dependencies) do
                if not zb.ModeAPI.registry[dep] then
                    table.insert(issues, "Missing dependency: " .. dep)
                end
            end
        end
        results[id] = { ok = #issues == 0, issues = issues }
    end
    return results
end
```

验证:
- [ ] 启动服务器无报错
- [ ] zb.ModeAPI 表可用

提交: `git commit -am "refactor: Step 13 - add mode plugin API"`

---

### Step 14: 改造现有模式注册到 API [中风险]

修改 `gamemodes/zcity/gamemode/loader.lua`，在加载每个模式后调用 `zb.ModeAPI.Register()`:

在加载循环中，每个模式的 MODE 表收集完成后:
```lua
zb.ModeAPI.Register(modeId, {
    name = MODE.name or modeId,
    description = MODE.description or "",
    base = MODE.base,
    version = MODE.version or "1.0.0",
    author = MODE.author or "Z-City",
    dependencies = MODE.dependencies or {},
    config = MODE.config or {},
    hooks = MODE.hooks or {},
})
```

从 JSON 加载模式配置覆盖默认值:
```lua
local config = hg.Config.Load("modes", modeId, {})
for k, v in pairs(config) do MODE[k] = v end
```

验证:
- [ ] 15个内置模式全部注册成功
- [ ] 模式继承正常（tdm_cstrike 继承 tdm）
- [ ] JSON 配置覆盖默认参数正常
- [ ] 所有模式可正常加载和切换

提交: `git commit -am "refactor: Step 14 - migrate existing modes to plugin API"`

---

### Step 15: 模式模板 [极低风险]

新建 `gamemodes/zcity/gamemode/libraries/modes/template/` 目录:

**sh_template.lua:**
```lua
MODE = MODE or {}
MODE.name = "Template Mode"
MODE.description = "A template for custom modes"
MODE.author = "YourName"
MODE.version = "1.0.0"
MODE.ROUND_TIME = 300

MODE.config = {
    MapSize = 5000,
    MaxPlayers = 16,
}
```

**sv_template.lua:**
```lua
-- 服务端逻辑
-- function MODE.hooks.OnStart(state) end
-- function MODE.hooks.OnRoundStart(state) end
-- function MODE.hooks.OnRoundEnd(state, winners) end
```

**cl_template.lua:**
```lua
-- 客户端 HUD/UI
-- hook.Add("HUDPaint", "TemplateMode_HUD", function() end)
```

**template.json:**
```json
{
    "ROUND_TIME": 300,
    "MapSize": 5000,
    "MaxPlayers": 16
}
```

验证:
- [ ] 复制 template 目录并重命名后能正常作为新模式加载

提交: `git commit -am "refactor: Step 15 - add mode template for community"`

---

## 阶段4：加载机制优化

前提: 阶段3全部完成并验证通过。

### Step 16: 加载阶段定义与时间监控 [低风险]

修改 `lua/autorun/loader.lua`:

在递归加载前定义阶段:
```lua
local LOAD_PHASES = {
    { name = "core",       path = "homigrad/core/" },
    { name = "config",     path = "homigrad/config/" },
    { name = "libraries",  path = "homigrad/libraries/" },
    { name = "player",     path = "homigrad/playerclass/" },
    { name = "combat",     path = "homigrad/combat/" },
    { name = "ui",         path = "homigrad/ui/" },
    { name = "systems",    path = "homigrad/systems/" },
    { name = "world",      path = "homigrad/world/" },
    { name = "initpost",   path = "initpost/" },
}
```

在每个阶段加载完成后输出耗时:
```lua
print("[Z-City] Phase '" .. phase.name .. "' loaded in " .. (CurTime() - startTime) * 1000 .. "ms")
```

验证:
- [ ] 加载时控制台输出各阶段耗时
- [ ] 所有文件按正确优先级加载
- [ ] 总加载时间与重构前持平

提交: `git commit -am "refactor: Step 16 - add load phases and timing"`

---

## 阶段5：实体与武器规范化

### Step 17: 武器模板 [极低风险]

新建 `lua/weapons/template/weapon_template.lua`，包含完整 SWEP 骨架和注释说明。

验证: 模板可正常编译。
提交: `git commit -am "refactor: Step 17 - add weapon template"`

---

## 完成检查清单

阶段0 (Step 0-4):
- [ ] .editorconfig 已创建
- [ ] .luacheckrc 已创建
- [ ] CI workflow 已创建
- [ ] sv_roundsystem 重复块已删除
- [ ] hg.DrawBlur 合并为1处
- [ ] font() 合并为 hg.GetFont
- [ ] 17个脏话hook名已全部替换
- [ ] 所有游戏功能正常

阶段1 (Step 5-7):
- [ ] cl_init.lua 约80行
- [ ] init.lua 约180行
- [ ] sv_roundsystem.lua 约220行
- [ ] 新增8个拆分文件
- [ ] 所有游戏功能正常

阶段2 (Step 8-12):
- [ ] hg.Config 框架已创建
- [ ] 5个武器JSON配置已创建
- [ ] 模式参数JSON已创建
- [ ] Loot表JSON已创建
- [ ] 主题颜色JSON已创建
- [ ] 配置热修改生效

阶段3 (Step 13-15):
- [ ] zb.ModeAPI 已创建
- [ ] 15个模式已注册到API
- [ ] 模式模板已创建
- [ ] 依赖检查正常

阶段4-5 (Step 16-17):
- [ ] 加载阶段监控正常
- [ ] 武器模板已创建

---

## 回滚指南

如果某步出问题：

```powershell
# 查看上一步改了哪些文件
git diff HEAD~1 --stat

# 查看具体改了什么
git diff HEAD~1

# 恢复单个文件
git checkout HEAD~1 -- "具体文件路径"

# 回滚整个上一步
git revert HEAD
```

如果需要回滚到特定步骤：
```powershell
# 查看所有提交
git log --oneline

# 回到某个提交
git checkout <commit_hash> -- .
```

## 风险提示

| 操作 | 风险 | 回滚难度 |
|------|------|----------|
| 新建文件 | 极低 | 删除文件即可 |
| 删除重复代码 | 低 | git checkout 恢复 |
| 精确字符串替换 | 低 | git checkout 恢复 |
| 从大文件提取代码 | 中 | git checkout 恢复原文件 |
| 改变加载顺序 | 中-高 | 需仔细测试依赖 |
| 函数合并 | 中 | 恢复旧版本即可 |
