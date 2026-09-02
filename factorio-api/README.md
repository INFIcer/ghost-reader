# Factorio EmmyLua API 库（通用，普适所有 mod 开发）

本目录是由 **官方 Factorio API 数据**（取自 `lua-api.factorio.com`，经
[svizzini/factorio-lua-api-autocomplete](https://github.com/simonvizzini/vscode-factorio-lua-api-autocomplete)
抓取）**自动生成**的 EmmyLua 类型注释库。它覆盖 Factorio **全部运行时 API**
（82 个 `Lua*` 类 + 完整 `defines.*` 枚举），不针对任何特定 mod，可直接复用到
任意 Factorio 2.x mod 的 VS Code / sumneko.lua (Lua) 工程中。

## 内容

| 文件 | 说明 |
|------|------|
| `globals.lua` | 全局对象 `game` / `script` / `storage` / `log` / `print`，及常用概念类型别名（`Position`、`Area`、`BoundingBox`、`LocalisedString`、`SignalID`…） |
| `classes.lua` | 全部 `Lua*` 运行时类：`---@class` 定义 + 字段 + 方法。成员已含继承展平；**每个类/字段/方法均带官方 API 使用说明**，悬停即可查看用法 |
| `defines.lua` | 全部 `defines.*` 嵌套枚举（`defines.events`、`defines.gui_type`、`defines.direction`、`defines.rail_direction`…） |

## 使用说明（悬停文档，全中文）

本库把官方 API 文档的说明文本**全部译为简体中文**后写入注释。在 VS Code 中把
鼠标悬停到任意 API 成员上即可看到它的用途、参数、返回值说明，例如：

```lua
local p = game.get_player(1)   -- 悬停 game.get_player 看中文说明
local e = surface.find_entities_filtered{ area = a, type = "entity-ghost" }
script.on_event(defines.events.on_tick, function() end)
script.register_on_object_destroyed(entity)  -- 已补齐此缺失方法
```

生成时做了三处规范化处理：
- **保留字参数改名**：官方数据里个别参数名是 Lua 保留字（如 `add_command` 的
  `function`），已被改成 `_function` 等合法标识符，避免 EmmyLua 报错。
- **中文文档**：所有类 / 字段 / 方法 / 参数的说明均译为简体中文（英文技术名词
  如 `entity`、`surface`、`recipe` 等按需保留）。
- **文档清理**：markdown 链接 `[uint](url)` 压缩为 `uint`，反引号/星号去除，
  便于悬停展示。

> **已补齐缺失方法**：官方抓取数据里 `script` 缺了
> `register_on_object_destroyed` 和 `on_shutdown`，本库已手动补全（含中文文档）。

## 使用方法

在任意 mod 工程的 `.vscode/settings.json` 中，把本目录加入 `Lua.workspace.library`：

```jsonc
{
    // Factorio 用 Lua 5.1
    "Lua.runtime.version": "Lua 5.1",
    "Lua.workspace.library": [
        "${workspaceFolder}/factorio-api"   // 指向本目录
    ]
}
```

若本目录被放在 mod 工程之外，用绝对路径或 `${workspaceFolder}/../factorio-api` 引用均可。

## 配置建议（可复用到所有 mod）

以下配置与具体 mod 无关，推荐写入 `.vscode/settings.json`：

```jsonc
{
    "Lua.runtime.version": "Lua 5.1",
    "Lua.runtime.fileEncoding": "utf8",
    "Lua.workspace.library": [
        "${workspaceFolder}/factorio-api"
    ],
    "Lua.diagnostics.globals": ["game", "script", "defines", "storage", "log"],
    "Lua.diagnostics.disable": [
        "need-check-nil",
        "undefined-field",
        "duplicate-set-field",
        "missing-return",
        "inject-field"
    ]
}
```

## 如何重新生成

数据源更新后，用 `tools/generate-factorio-api.mjs` 重新生成：

```bash
node tools/generate-factorio-api.mjs \
  <classes.json> <defines.json> \
  factorio-api
```

- `<classes.json>` / `<defines.json>` 即 `svizzini.factorio-lua-api-autocomplete`
  扩展 `data/` 目录下的文件（抓取自官方文档）。
- 脚本读取官方 API 数据，把类型映射为 EmmyLua 注解，输出 `globals.lua`、
  `classes.lua`、`defines.lua` 三个文件。
- 中文文档来自同目录的 `tools/zh-docs.json`（类/成员）与
  `tools/param-zh.json`（参数）。脚本若找到这两个文件会自动使用中文说明；
  缺失时回退到英文官方说明。

> 提示：这些 `.lua` 文件**仅类型注释**，不会在 Factorio 运行期被加载执行。
> 若担心被打进 mod zip，可在打包脚本中排除 `factorio-api/`（或把它放到工程外）。
