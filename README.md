# Z-City (cslzcity)

Z-City 是一个 Garry's Mod 综合游戏模式插件，修改角色伤害与操控系统，自带武器基类（homigrad_base）和多玩法回合系统（DM / TDM / Homicide / Coop / Defense / GWars 等 15 种模式）。

> 本仓库为 Z-City 的模块化重构维护版，重构方案见仓库外文档 `zcity-refactor.md`。
> 当前进度：**阶段 0（基础设施与 Bug 修复，Step 0-4）已完成**。

## 环境要求

- Garry's Mod（客户端 + 专用服务器）
- 8bit 模块（编译版已包含在 `lua/bin/`，源码见 https://github.com/uzelezz123/8bit_zcity）

可选客户端模块（Discord RPC）：

1. https://github.com/YuRaNnNzZZ/gmcl_steamrichpresencer/releases/tag/2023.07.20
2. https://github.com/fluffy-servers/gmod-discord-rpc/releases/tag/1.2.1

## 安装

1. 将本仓库放入 `garrysmod/addons/`（或将 `gamemodes/zcity` 放入 `garrysmod/gamemodes/`，其余 `lua/`、`data_static/` 合并到对应目录）。
2. 启动服务器，切换游戏模式为 **ZCity**。
3. `lua/bin/` 内的 8bit 模块需与服务器平台匹配（win32/win64/linux32/linux64）。

## 代码结构

```
gamemodes/zcity/gamemode/   # 游戏模式核心（init / cl_init / shared / loader）
  ├── libraries/            # 回合系统、观战、出生点、RTV、guilt 等服务端/客户端库
  └── modes/                # 15 种玩法模式（每个模式含 cl_/sh_/sv_ 三段）
lua/
  ├── autorun/loader.lua    # 启动加载器，递归扫描 homigrad/ 与 initpost/
  ├── homigrad/             # 底层框架：器官系统、伤害、移动、外观、库存、假布娃娃等
  │   └── cl_font.lua       # 重构新增：公共 UI 字体函数 hg.GetFont()
  ├── weapons/              # homigrad_base 武器基类 + 近 200 把武器
  ├── entities/             # 手雷、道具、Glide 载具实体
  ├── effects/              # 特效
  └── glide/                # Glide 载具框架
data_static/glide/          # 载具引擎音效预设
```

## 开发

- 缩进：Tab（4 宽），见 `.editorconfig`
- 静态检查：`luacheck . --no-color --codes`（配置见 `.luacheckrc`）
- CI：GitHub Actions 自动运行 luacheck 与 Lua 语法检查（`.github/workflows/lint.yml`）

## 重构进度（阶段 0 已完成）

| Step | 内容 | 提交 |
|------|------|------|
| 0 | .editorconfig / .luacheckrc / CI workflow | `30e664d` |
| 1 | 删除 sv_roundsystem.lua 末尾 ~100 行重复代码块（重复注册 Admin 网络） | `53a52f7` |
| 2 | 合并 hg.DrawBlur 3 处重复定义为 1 处（cl_init.lua 带缓存版本） | `5afea2d` |
| 3 | 提取 6 处重复 font() 为 `hg.GetFont()`（lua/homigrad/cl_font.lua） | `4e3cef7` |
| 4 | 17 个脏话 hook 名替换为 ZC_* 规范名 | `d040482` |

后续阶段（未执行）：大文件模块化拆分（cl_init / init / sv_roundsystem）、配置外部化（JSON）、模式系统插件化、加载阶段监控。

## 版本

当前版本 1.4.1。版本号含义：`A.Bcc` →
- A：全局更新
- B：新机制、玩法变更
- c：修复与小改动

## 致谢

原作者：uzelezz, sadsalat, Mr. Point, Zac90, Deka, Mannytko

上游项目与捐赠信息见原版 README（Z-City 1.4.1）。
