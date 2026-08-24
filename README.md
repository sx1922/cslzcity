# Z-City（中文整合版）

Z-City 是一个 Garry's Mod 游戏模式插件：修改角色伤害与操作控制，自带武器基座（homigrad_base）与完整回合制游戏模式。

**本仓库为中文整合维护版**，在原版基础上包含：

- 全量简体中文界面（聊天提示、菜单、危机应对 / TDM / 外观编辑器等）
- 原生业力系统（guilt），并支持 ConVar 宽松化配置
- 多处稳定性修复（组织系统判空、计分板判空、出生自愈等）
- 图集占位资源与自动下发脚本

上游项目：https://github.com/uzelezz123/8bit_zcity
（8bit 语音模块编译版已附带在 `lua/bin`，无需额外下载）

客户端可选 Discord RPC 模块：

1. https://github.com/YuRaNnNzZZ/gmcl_steamrichpresencer/releases/tag/2023.07.20
2. https://github.com/fluffy-servers/gmod-discord-rpc/releases/tag/1.2.1

## 版本说明

当前仓库版本为 1.4.0。

版本号 A.Bcc 含义：

- A → 大型更新
- B → 新机制、玩法改动
- c → 修复与小调整

## 部署方式

### 一、重要前提（必做）

workshop 创意工坊插件 **3778552899** 是旧版完整包，订阅后会遮蔽本地代码导致补丁失效。
**必须从你的创意工坊合集中取消订阅该插件**，否则以下所有部署步骤无效。

同时删除服务器上手动放置的旧副本（如果存在）：

```
garrysmod/lua/homigrad/        ← 整个目录删除
```

### 二、覆盖文件

将仓库中的以下目录覆盖到服务器的 `garrysmod/` 下：

| 仓库路径 | 目标路径 |
|---|---|
| `gamemodes/zcity/` | `garrysmod/gamemodes/zcity/` |
| `lua/` | `garrysmod/lua/` |
| `materials/zcity/` | `garrysmod/materials/zcity/` |
| `resource/fonts/` | `garrysmod/resource/fonts/` |

> 注意：`lua/` 目录采用合并覆盖（保留服务器上其他插件的 lua 文件，只覆盖同名文件）。

### 三、重载生效

```bash
changelevel <地图名>
```

### 四、本地单机测试

把同样的目录覆盖到客户端 `garrysmod/` 下，主菜单选择 Z-City 游戏模式开本地局即可。

## 业力系统配置（ConVar）

业力系统默认开启，行为与原版一致。管理员可通过以下 ConVar 调整宽松度（写入 server.cfg 持久化）：

| ConVar | 默认值 | 说明 |
|---|---|---|
| `zb_guilt_enabled` | 1 | 业力系统总开关 |
| `zb_guilt_damage_mul` | 2 | 罪恶伤害倍率（调低可减轻扣业力度） |
| `zb_guilt_ban_lowkarma` | 1 | 低业力自动封禁开关 |
| `zb_guilt_ban_lowkarma_time` | 60 | 低业力封禁时长上限（分钟） |
| `zb_guilt_ban_teamkill` | 1 | 恶意队伤封禁开关 |
| `zb_guilt_ban_teamkill_time` | 30 | 队伤封禁时长（分钟） |
| `zb_guilt_seizure_karma` | 50 | 癫痫触发业力阈值（0 = 禁用癫痫惩罚） |
| `zb_guilt_vomit_karma` | 35 | 呕吐触发业力阈值（0 = 禁用呕吐惩罚） |
| `zb_guilt_regen` | 0.75 | 业力回复基准值 |

示例（最宽松配置）：

```cfg
zb_guilt_enabled 1
zb_guilt_damage_mul 0.5
zb_guilt_seizure_karma 0
zb_guilt_vomit_karma 0
zb_guilt_regen 1.5
```

## 验证安装

服务器控制台依次执行：

```
lua_run print(zb.ForcesAttackedInnocent ~= nil)      -- 应输出 true
lua_run print(file.Exists("materials/zcity/neurotrauma/AfflictionIcons.png", "GAME"))  -- 应输出 true
lua_run PrintTable(zb.RoundList)                     -- 应列出全部游戏模式
```

游戏内检查：聊天提示、菜单、危机应对界面均应显示中文。

## 未包含的内容

以下自制/外部内容不随仓库分发（需自行同步到服务器）：

- `SCP/`（任务简报素材与脚本）
- `card/`（门禁卡材质）
- `.zcode/`
- `lua/autorun/*mission_intro*`
- `gamemodes/zcity/gamemode/modes/rxsend/`
- `resource/fonts/unisans.ttf`（HUD 字体，缺失仅影响字体美观）

## 支持原作者

**捐赠链接：**
- [Yoomoney](https://yoomoney.ru/fundraise/17GFEQH326Q.250101)
- [Boosty](https://boosty.to/sadsalat/donate)

**加密货币：**
- USDT(TRC20): TYgpaZgHQr6qEgemhHzVvV7AQESiyhHpZD
- BTC(BTC): bc1qa8pk9ag6xa5yav2mvlxkra8xk25lg3htgfqh5w
- ETH(ERC20)*: 0x72AdCCcCEB4E323C64bCF0955A779DD9298E9483
