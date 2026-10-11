# OpenRPG

**Unity 2020.1.0f1c1 + [xLua](https://github.com/Tencent/xLua) + Spine** 的 RPG 玩法原型。与 OpenACT 同一套思路的进化版：**C# 只做胶水**（lua 加载、注入、生命周期/物理 API 转发），游戏逻辑全在 lua；在它之上做了 Spine 骨骼动画接入、基于 id 的 3D 物理封装和一套自定义碰撞系统。

内置运行时：xLua（`Assets/XLua`）、Spine runtime **3.6**（`Assets/spine-csharp` / `Assets/spine-unity`，历史上从 3.8 降级到 3.6）。

## 场景

| 场景 | 内容 |
| --- | --- |
| `Assets/Resources/Scenes/test0.unity` | LMap + LPlayer：地图加载、角色、自定义碰撞 |
| `Assets/Resources/Scenes/test1.unity` | Spine 角色 + castleDB 数据 + pngLua 图集 |
| `Assets/Resources/Scenes/test2.unity` | BulletUnity/BulletSharp 物理实验（**插件未内置**，需自备） |
| `Assets/Resources/Scenes/test3.unity` | ECS 试验（tiny-ecs，require 已注释归档） |
| `Assets/Resources/Scenes/test4.unity` | 其他玩法测试 |

## 架构

```
GameLoader（场景配置 scripts 列表 + folder，默认 StreamingAssets/Lua）
   │  UnityWebRequest 读入每个 lua 文件（text + 原始字节两份缓存）
   ▼
LuaManager（单例缓存）
   │  全部就绪后 SetActive(init)
   ▼
LuaBehaviour（挂物体上，物体名 = lua 文件名；Instantiate 的 "(Clone)" 自动剥掉）
   · 每物体独立 scriptEnv，injections 注入，self 指向自身
   · 转发 start/update/lateupdate/fixedupdate/ondestroy/ongui/onDrawGizmos
   · 每秒 luaEnv.Tick() 一次（OnGUI 左下角的 √ 是 GC 心跳）
LuaUtil.AddLuaComponent(go, "脚本名")   ← 运行时给物体动态挂 lua 组件（LuaComponent）
```

- **自定义碰撞**：Unity 物理回调的转发路线已停用（LuaBehaviour 里注释归档），改为 lua 侧用 `LuaUtil` 的物理 API 自行实现——`PhysicsBoxCastNonAlloc` / `OverlapBox` / `RigidbodyMovePosition` / `TestMove`（六向 AABB 推挤解算）等，配合按 id 注册的 GameObject/Collider 表（`AddGameObjectID` / `AddColliderID`）
- **坐标口径**：整体 y/z 轴互换——世界 z 为上/进深，渲染坐标 `(x, y - z, z + y)`，重力沿 z 方向（详见提交 5e113dd）
- **require 解析**：先查预载字节缓存，桌面端落盘兜底，子目录库走 `package.path`（test1 的 pngLua 就这么挂）
- **编辑器菜单** `OpenRPG/CopyDataAndRun`：把 StreamingAssets 拷到指定构建目录并启动 exe（路径硬编码 `D:\uppp\OpenRPG\`，仅作者机器可用，按需改 `Assets/Resources/Editor/CopyData.cs`）

## Lua 模块

| 模块 | 职责 |
| --- | --- |
| `LUtils.lua` | 公共工具：资源路径（PC/WebGL 双分支）、对象/动画/HP 条、帧号解析 |
| `LMap.lua` / `LTileRoom.lua` | 地图与 tile 房间 |
| `LPlayer.lua` / `LAI.lua` | 玩家与 AI |
| `LCollider.lua` | 自定义碰撞体（配合 LuaUtil 的物理 API） |
| `LComponent.lua` / `LUIObject.lua` / `LSystem.lua` | 组件、UI 对象、系统层 |
| `LCastleDB.lua` | 读 castleDB 导出的 json 数据 |
| `class.lua` / `ecs.lua` / `json.lua` | OOP 基类、ECS 试验、JSON |
| `test0~4_main.lua` | 各场景入口 |
| `utils/pngLua-master/` | png 读写库（test1 图集生成用） |

## 注意

- 用 **Unity 2020.1.0f1c1** 打开；换版本后 xLua 需重新 Generate Code，Spine 资源版本要对上 runtime（3.6）
- test2 场景依赖 BulletUnity/BulletSharp 插件，**仓库未内置**，没有插件时该场景跑不起来
- lua 源码全部 UTF-8；C# 带 BOM。脚本缓存按原始字节走，编码不会被加载链破坏

## 更新（2026-10）

**C# 胶水层**
- `LuaBehaviour`：FPS 统计把 `Time.realtimeSinceStartup` 赋给 `UpdateInterval`（间隔字段变成开机秒数，FPS 恒为垃圾值）；`AddLoader` 每个 Awake 重复添加改只加一次；非 Windows 分支 `WWW` 同步忙等必死循环（主线程堵住 `isDone` 永不完成），改「预载字节缓存 → 桌面读文件」；物体名剥 `"(Clone)"` 后再查脚本，找不到时报错而不是把 null 塞进 `DoString`；`OnDestroy` 补齐全部 lua 委托置空；清掉 250 余行注释死代码
- `GameLoader`：UnityWebRequest 失败静默注册空串改报错并继续；删掉 2.7 万字符注释 Base64 测试代码与空 `Update`；`LuaManager` 增加原始字节缓存（`Get/SetScriptBytes`），`DoString` 改走 `byte[]` 重载，编码由文件本身决定；`Tools.PhysicsBoxCastG` 去调试 Log；删掉未使用的 `using Spine.Unity.Modules`
- `LuaUtil.AddLuaComponent`：原来只查字符串缓存、拿不到就把 null 塞 `DoString`，改走字节加载（缓存 → 落盘兜底）并报错；补上被注释掉的 `start` 绑定（`LuaComponent.luaStart` 字段和 `Start()` 调用都是现成的，等于动态组件的 start 一直被静默跳过）
- `CopyData.CopyDirectory`：子目录复制失败先置 `ret = false`、结尾又被无条件 `ret = true` 覆盖（错误被吞），改早退
- `test2_main.lua`：`require "LTestComp"`（文件从未提交，场景启动即 module not found）注释归档，挂载改回作者注释里的可用写法 `AddLuaComponent(go, "test2_testfun")`
