# Seed — 游戏内界面（HUD）规划

> 状态：设计草案 v0.1 · 2026-11-21
>
> 定位：定义游戏内“能看什么、什么时候看、在哪里看”。覆盖常驻 HUD、时间、
> 资源、背包、科技档案、殖民地面板与通知系统，并给出可落地的 Godot 组件拆分。
>
> 关联文档：[`opening.md`](opening.md) · [`design.md`](design.md) ·
> [`art-direction.md`](art-direction.md) ·
> [`first-phase-food.md`](first-phase-food.md) · [`thermal-power.md`](thermal-power.md) ·
> [`factory-loop.md`](factory-loop.md) · [`tech-archive.md`](tech-archive.md) ·
> [`colonist-wake-chain.md`](colonist-wake-chain.md) · [`ROADMAP.md`](ROADMAP.md)

## 1. 目标与非目标

### 1.1 目标

1. **一眼看懂今天的生存状态**：现在几点、还剩多少时间、饿不饿、冷不冷、电池够不够。
2. **资源分层**：随身、基地、电力、科技输入分开看，不把 9 种材料糊在屏幕上。
3. **背包是工具，不是仓库**：快捷栏负责“马上要用”，背包负责“我有什么”，基地仓库负责“殖民地有多少”。
4. **科技是找回来的档案**：不做彩色科技瓶，不做抽象研究条；科技界面要能看出“进度从哪来、缺谁、缺什么”。
5. **符合设定**：动力服 HUD、低算力 AI、货仓玻璃薄片、先生存后工业。
6. **可渐进展示**：开场只给字幕和交互提示，穿动力服后一层层点亮，避免一上来满屏数字。

### 1.2 非目标（第一版不做）

- 不做完整 3D 全息投影/第一人称腕表动画。
- 不做拖拽式背包、物品旋转、3D 模型预览。
- 不做地图标记、路径规划、物流大屏（M6 / M2.5 后段）。
- 不做双时钟 UI（任务时间 / 船载时间）。按 `story-timeline.md`，只用任务时间叙事。
- 不做天气系统本身，只为天气预留图标和文字位。

## 2. 现状审计（读代码后）

当前游戏内 UI 全部由 `scripts/main.gd` 动态创建，没有独立 HUD 场景：

| 层 | 位置 | 内容 | 问题 |
|----|------|------|------|
| `GameplayHud`（layer 12） | 左上 | 体力、饥饿条 | 只有数值条，没有图标/趋势 |
| `GameplayHud` / `QuestHud` | 右上 | 任务列表常驻 | 任务一多会占满右侧 |
| `GameplayHud` / `InventoryPanel` | 屏幕中央 | `I` 打开的物品列表 | 只有文字行，挡住世界，无快捷栏 |
| `PromptLayer`（35） | 底部中央 | `[E] Interact` | 与 AI 字幕、吃饭提示挤在底部 |
| `SurvivalLayer`（36） | 中下 / 左下 | AI 字幕、`[H] Eat` | 和交互提示争空间 |
| `DialogueBox`（40） | 中下 | 对白 | 正常 |
| `UIRouter`（50 / 100） | 全屏 | 标题、暂停、设置、Toast | 可复用 |

已存在但未用于 UI 的基础设施：

- `GameClock` 自动加载：`world_seconds` 会随游戏进行累加，并且已经注册到存档。
- `InventoryContainer`：玩家当前 **16 格**，`max_slots` 可读，适合做 4×4 网格。
- `InputRouter`：支持 UI 上下文栈，打开面板时应压入上下文。
- `UIRouter`：支持屏幕栈、Toast、确认框，适合承载腕装终端和殖民地大面板。
- `StatSet` / `StatBar`：可复用，但常驻 HUD 需要更紧凑的 Seed 版本。

**结论：** 不继续往 `main.gd` 里堆控件；新建 Seed 自己的 HUD 场景与组件，
`addons/` 保持只读。

## 3. 设计约束（来自设定）

| 设定 | 对 UI 的约束 |
|------|--------------|
| 玩家穿动力服，HUD 是动力服的一部分 | 常驻 HUD 用“服内读数”语气：电量、体温、生命维持；不要游戏化血条堆叠 |
| 开场 AI 只有一小部分在线 | 开场不显示科技树、殖民地统计；AI 提示逐级解锁 |
| 第一幕先食物、后电力 | 时间、饥饿、温度优先于资源总览和科技 |
| 科技是货仓里的玻璃薄片 | 科技界面叫 `ARCHIVE`，节点来自找到的薄片/数据/样本，不叫“研究菜单” |
| 没有彩色科技瓶 | 不显示“科技点”货币；进度来源必须可解释 |
| 专家是科技树的人肉入口 | 节点要显示归属专家、是否醒来、共同科技缺谁 |
| 工厂是手段不是目的 | 殖民地/物流面板可以深，但常驻 HUD 只显示瓶颈 |
| 只用任务时间，不做双时钟 | 主时钟显示本地日/时；任务年份放在档案详情，不常驻 |

## 4. 信息架构

界面分三层，避免“所有东西都在 HUD 上”：

```
L0 常驻 HUD（不打断游戏）
  时间 / 环境 · 生命维持 · 当前目标 · 快捷栏 · 固定资源 · 交互提示 · AI 字幕

L1 腕装终端（Tab / I / T，半暂停或实时）
  SUIT 状态 · PACK 背包 · ARCHIVE 科技档案 · COLONY 殖民地 · LOG 记录

L2 世界内界面（靠近才出现）
  建造点成本 · 机器面板 · 休眠舱需求 · 物流站 · 研究台 · 货仓薄片架
```

原则：

- **L0 只回答“现在要不要做决定”**。
- **L1 回答“我有什么、我能做什么”**。
- **L2 回答“这台机器/这个人/这条线现在缺什么”**。
- 同一个信息不在两层重复：例如电力只在 L0 显示一个总满足率，明细放 L1。

## 5. 常驻 HUD 布局

以 1280×720 为基准，安全边距 24 px；使用锚点/容器，不写死像素。

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ SEED-2338 III   DAY 003  07:42  DAWN  ·  CLEAR 12°C        AI ◉   POWER 18/20 │  top bar
│                                                                              │
│ ♥ 82        ▓▓▓▓▓▓▓░░░   stamina                                             │  left
│ HUNGER 54   ▓▓▓▓▓░░░░░                                                       │  vitals
│ BATTERY 62% ▓▓▓▓▓▓░░░░   TEMP 36.4°C OK                                      │
│                                                                              │
│                                                   ┌─ CURRENT OBJECTIVE ────┐ │  right
│                                                   │ First Night           │ │
│                                                   │ Build shelter     0/1 │ │
│                                                   └────────────────────────┘ │
│                                                                              │
│                          (world / crosshair)                                 │
│                                                                              │
│                                                                              │
│                          [ Ship AI subtitle ]                                │
│                          [E] Harvest Fallen Branch                           │
│                                                                              │
│  ┌ 1 ┐┌ 2 ┐┌ 3 ┐┌ 4 ┐┌ 5 ┐┌ 6 ┐        ┌ wood 8 ┐┌ fiber 3 ┐┌ stone 0 ┐     │  bottom
│  │axe││ber││   ││   ││   ││   │        │   +0   ││   +1    ││  LOW    │     │
│  └───┘└───┘└───┘└───┘└───┘└───┘        └────────┘└─────────┘└─────────┘     │
└──────────────────────────────────────────────────────────────────────────────┘
```

### 5.1 区域职责

| 区域 | 组件 | 内容 | 更新源 |
|------|------|------|--------|
| 顶部左 | `IdentityClock` | 星球代号、`DAY 003`、`07:42`、昼夜阶段、天气、温度 | `WorldTime` + 未来 `Weather` |
| 顶部右 | `SuitStatus` | AI 在线状态、基地电力（建好发电机后） | `ShipAI` / `PowerGrid` |
| 左上 | `VitalsPanel` | 生命、饥饿、体力、电池、体温状态 | `StatSet` + suit |
| 右上 | `ObjectivePanel` | 当前目标 1 条 + 进度；按 `J` 展开日志 | `QuestTracker` |
| 顶部中 | `AlertStack` | 夜间倒计时、风暴、断电、低电量等紧急提示 | `NotificationBus` |
| 底部中 | `Hotbar` | 6–8 个快捷物品/工具，选中高亮 | `InventoryContainer` + 快捷栏映射 |
| 底部右 | `PinnedResources` | 4–6 个固定资源 + 数量 + 变化 | `ResourceLedger` |
| 底部中上 | `PromptLabel` | `[E] Interact` | `Interactor` |
| 底部中上 | `AISubtitle` | `Ship AI: ...` | `ShipAI` |
| 左下 | `EatHint` | 保留 `[H]`，食物系统成熟后并入快捷栏 | `HungerController` |

### 5.2 布局规则

- 顶部条高 44 px，背景半透明，不遮世界中心。
- 左右面板宽度 ≤ 240 px；中间至少留 60% 无遮挡区域。
- 底部 HUD 总高 ≤ 130 px；对白/大面板打开时，快捷栏淡出到 30% 透明度。
- 1024×576 下允许资源条缩成 4 个、快捷栏缩成 6 个；信息不删除，只折叠。
- 任务列表默认只显示 1 条当前目标；完整列表在 `LOG` 页。
- 所有面板圆角 2–4 px、细边框，避免大块圆角卡片。

## 6. 时间系统

### 6.1 显示什么

主时钟（常驻）：

```
DAY 003  07:42  DAWN  ·  CLEAR 12°C
```

- `DAY 003`：迫降后第 3 个本地日，从 `DAY 001` 开始。
- `07:42`：本地 24 小时制；`HH:MM` 全局统一，不做 12 小时制。
- `DAWN / DAY / DUSK / NIGHT`：昼夜阶段。
- 天气与温度：第一版可以只显示 `CLEAR 12°C` 占位，天气系统上线后接真实值。
- 悬停/点击展开：`Landing +3d 07:42`、`Local day 40 min`、`Mission year 0`。
- 任务年份、离开母星多少年等放在 `ARCHIVE`/`LOG` 详情里，不做双时钟。

接近夜晚时，时钟右侧出现倒计时 chip：

```
NIGHT IN 00:42
```

### 6.2 时间模型（建议）

| 参数 | 已定值 | 说明 |
|------|--------|------|
| 1 本地日 | **30 真实分钟** | `1 游戏小时 = 75 真实秒` |
| 起始时间 | 第 1 日 06:00 | 13 小时后入夜，约 16 分钟；开场后仍有约 8–10 分钟准备第一夜 |
| 昼夜 | 05–07 黎明，07–17 白天，17–19 黄昏，19–05 夜晚 | 第一版可用光照 + 时钟颜色表现 |
| 时间倍率 | 0.5× / 1× / 2× / 4×（设置项） | 工厂挂机/夜间等待时使用 |
| 睡觉 | **可选**：1h / 2h / 4h / 睡到黎明 | 玩家自己选时长或醒来时间；没有强制睡眠，不睡也能一直玩 |

> 30 分钟一天意味着第一夜比 40 分钟方案更早到；这是作者确认的节奏。
> 睡觉只是时间跳过和恢复体力的便利，不是生存强制项。
> 打开 `PACK` / `ARCHIVE` / `COLONY` 时游戏暂停，时间不流逝（见 §15 / D036）。

### 6.3 时间的玩法职责

- **夜晚**：温度下降、太阳能归零、敌人/风险提高、部分 NPC 回庇护所。
- **倒计时**：夜间、风暴、作物成熟、打印完成、发电机燃料。
- **不强制睡觉**：时间自然流逝，玩家可以通宵；睡觉是可选的跳过方式。
- **可选睡觉**：在庇护所/休眠舱选择 `1h`、`2h`、`4h` 或“睡到黎明”；醒来时间可调。
- **时间跳过**：睡觉、等待、快速旅行；跳过要推进世界状态（作物、燃料、电力）。
- **存档**：`GameClock.world_seconds` 已有存档；日历从它派生，不新增第二份时间存档。

### 6.4 实现注意

- 当前 `HungerController` 用原始 `delta` 衰减；引入时间倍率/睡觉后，应改为
  `GameClock.gameplay_delta(delta)`，否则时间跳过不会影响饥饿。
- 时钟只在 `PLAYING` 状态前进；标题、暂停、读档时冻结。
- **打开腕装终端（PACK / ARCHIVE / COLONY）时暂停**：树暂停 + `GameClock` 停止，
  关闭后恢复到 `PLAYING`。这是 D036。
- UI 不要每帧刷新；按“游戏分钟变化”信号更新。

## 7. 资源系统

### 7.1 三层资源

| 层级 | 资源 | 显示位置 |
|------|------|----------|
| 身体 | 生命、饥饿、体力、体温、电池 | 左上 `VitalsPanel` |
| 随身 | 木材、纤维、石头、食物、零件等 | 快捷栏 + 底部固定资源条 + `PACK` |
| 殖民地 | 仓库库存、电力、水、燃料、食物储备 | `COLONY` 面板 + 顶部电力 |

不要把三层混成一个“总资源”数字。玩家需要知道“我身上有多少”和“基地有多少”是两件事。

### 7.2 常驻资源条

- 默认 4 个 chip，最多 6 个；每个 chip：图标 + 名称缩写 + 数量 + 趋势/状态。
- 优先级：
  1. 当前建造/交互需要的材料；
  2. 当前目标需要的材料；
  3. 最近变化的材料；
  4. 玩家手动 pin 的材料。
- 探索期默认：`wood`、`fiber`、`stone`、`food`。
- 工厂期默认：`iron_ore`、`coal`、`iron_plate`、`mechanical_part`，其余进 `COLONY`。
- 状态颜色：正常白、低量琥珀、归零红、增长绿；不能只靠颜色，配 `LOW` / `0` 文字。
- 数量变化时显示 1.5 秒的 `+3` / `-2` 浮字。

### 7.3 建造成本提示

靠近建造点/机器时，在交互提示上方显示成本 chip：

```
[Shelter]  wood 3/5   fiber 1/3
```

`3/5` 的 `3` 是拥有量，`5` 是需求；不足项红色。这样玩家不用打开背包算。

### 7.4 资源分组

| 组 | 内容 | 用途 |
|----|------|------|
| Survival | 食物、水、药、燃料 | 生存与烹饪 |
| Construction | 木材、原木、石头、纤维、废金属 | 建造与修理 |
| Industry | 铁矿、铜矿、煤、铁板、铜、机械件、电气件 | 工厂循环 |
| Research | 机械件、电气件、数据、样本、玻璃薄片 | 科技进度 |
| Colony | 电力、水、食物储备、人口 | 殖民地总览 |

`COLONY` 面板按组展示，`PACK` 按物品类型过滤。

## 8. 背包与快捷栏

### 8.1 快捷栏

- 6 格；当前玩家只有 16 格背包，自动显示前 6 个已占用格。
- 排序优先：工具/武器 → 食物 → 容器 → 其他材料；同类按背包顺序。
- 快捷栏是 **物品引用**，不复制库存；显示数量来自背包。
- `1–6` 选择，选中格琥珀色描边；`F` 使用选中物。
- 工具按 tag 驱动动作：knife → `gather`，axe → `chop`，pickaxe → `mine`，
  mallet → `build`，weapon → `strike`；食物 → 吃。
- `F` 对着聚焦的浆果丛/采集点/建造点时直接调用 `interact()`。
- 选中的工具/食物在快捷栏上方显示 `物品 · F 动作`。
- `H` 吃野果保留，作为食物的快捷方式。
- **已实现**：显示、选择、使用、工具动作映射、旧 `1–4` 动作键释放。
- **未实现**：按住 `F` 连续动作、拖拽排布、手动 pin 快捷栏。

### 8.2 腕装终端 `PACK`

```
┌ WRIST // PACK ─────────────────────────────────────────────── 12/16 ┐
│ SUIT │ PACK │ ARCHIVE │ COLONY │ LOG                                 │
├───────────────┬──────────────────────────────────┬───────────────────┤
│ EQUIPMENT     │  [1] [2] [3] [4]                 │ Wild Berry        │
│  Suit         │  [5] [6] [7] [8]                 │ Food · 12         │
│  Tool         │  [9] [10][11][12]                │ Restores hunger   │
│  Battery      │  [13][14][15][16]                │ [Use] [Hotbar]    │
│  Headlamp     │                                  │ [Drop]            │
├───────────────┴──────────────────────────────────┴───────────────────┤
│ FILTER: ALL  TOOLS  FOOD  MATERIALS  QUEST        [SORT] [CLOSE]      │
└──────────────────────────────────────────────────────────────────────┘
```

- 4×4 网格读取 `InventoryContainer.max_slots`；未来扩到 24/30 格时自动变 6×5。
- 左：装备槽（动力服、手持工具、电池、头灯），第一版可只显示状态不实现槽位。
- 中：背包格子；有图标用图标，没有图标用 64 px 类别 fallback 图标。
- 右：选中物详情、使用/装备、加入快捷栏、丢弃。
- 底部：分类过滤、排序、关闭。
- 操作：单击选中，双击使用/装备；右键菜单（使用/装备/加入快捷栏/丢弃）。
- 不强制拖拽；拖拽作为后续增强。
- `I` 直接打开 `PACK`；`Tab` 打开腕装终端并停在上次页面；`Esc` 先关终端，再暂停。

### 8.3 背包容量

- 当前 16 格。建议第一版保持 16，避免 UI 和数值同时扩。
- 基地仓库是独立容器，不占玩家格子；在 `COLONY / Resources` 里看。
- 任务物品加锁图标，不可丢弃，不占快捷栏。

### 8.4 道具图标（2026-11-22）

- 统一入口：`scripts/ui/item_icons.gd`（`ItemIcons`）。
- 已接入：腕装 `PACK` 格子（图标 + 名称 + 数量）、物品详情 52 px 图标、
  底部常驻资源条（18 px 图标 + 数量）。
- 未接入：快捷栏（另一位 agent 正在改 `hotbar.gd`，接入时调用
  `ItemIcons.icon_for(item_id, def.tags)` 即可）；建造点成本行。
- 5 个 authored 256 px 图标在 `assets/art/icons/`；其余物品由 fallback
  程序化生成，保证不会出现空图标。
- 详细规范、映射表和新增图标流程见 [`item-icons.md`](item-icons.md)。

## 9. 科技档案 `ARCHIVE`

完整阶段、分支、节点、权重与共同科技规则见 [`tech-tree.md`](tech-tree.md)；本节只定义 UI。

### 9.1 设计语气

- 不叫 `TECH TREE`，叫 `ARCHIVE // 科技档案`。
- 节点不是“研究项目”，是“找回来的玻璃薄片 + 数据 + 人”。
- 进度不是一条自动走的条，而是多来源贡献的百分比。
- HUD 只显示当前研究目标；完整树只在 `ARCHIVE` 里看。

### 9.2 布局

```
┌ ARCHIVE // RECOVERED 17% ─────────────────────────── AI ANALYSIS LV 1 ┐
│ BRANCHES            │  NODE MAP                         │  DETAIL     │
│ Power        40%    │   [Power Basics]──[Thermal I]     │ Basic Auto  │
│ Industry     20%    │        │                 │        │ 40%         │
│ Bio           0%    │   [Solar] [Wind]   [Steam II]     │ Sources     │
│ Construction 10%    │                                   │ Milestone 20│
│ Robotics      0%    │   ○ unknown  ◐ fragment           │ Data 10     │
│ Security     --     │   ● available  ✔ complete         │ Parts 4/10  │
│ Fleet        --     │                                   │ [Set target]│
├─────────────────────┴───────────────────────────────────┴─────────────┤
│ SLIDES: [Engineering Core 82%] [Power Fragment 31%] [ ??? ]           │
└───────────────────────────────────────────────────────────────────────┘
```

### 9.3 三种访问状态

| 状态 | 打开方式 | 能做什么 |
|------|----------|----------|
| Remote view | 任意地点 `T` | 查看已恢复节点、进度来源、缺什么；不能投入零件、不能改目标 |
| Bench link | 研究台/飞船档案终端附近 | 选择研究目标、投入机械件/电气件、启动研究 |
| Archive room | 货仓薄片架（M4） | 读取/装填薄片、修复残片、解锁隐藏分支 |

Remote view 顶部显示：

```
REMOTE VIEW // return to a Research Bench to spend parts
```

这样既满足“随时能看科技”，又不破坏“科技是实体”的设定。

### 9.4 节点状态

| 状态 | 外观 | 含义 |
|------|------|------|
| Unknown | 虚线轮廓 + `???` | 还没找到相关薄片/数据 |
| Fragment | 半亮 + 百分比 | 找到残片，但缺数据/专家/设施 |
| Available | 琥珀色实线 | 可以设为研究目标（可操作） |
| In progress | 冰蓝色 + 进度 | 系统正在投入资源/由专家推进 |
| Complete | 青绿色 + ✔ | 已解锁 |
| Locked by person | 灰色 + 人头像 | 需要指定专家醒来 |
| Locked by facility | 灰色 + 建筑图标 | 需要研究所/工作台/船坞 |

### 9.5 进度来源

节点详情必须列出贡献，不能只有一个百分比：

| 来源 | 例子 | UI 文案 |
|------|------|---------|
| 工程里程碑 | 建好研究台 | `Milestone: Research Bench` |
| 数据恢复 | 飞船工程缓存 | `Data: Ship Engineering Cache` |
| 样本分析 | 3 批种子 | `Samples: 3/3 Seed Batches` |
| 原型验证 | 打印测试件 | `Prototype: Test Frame` |
| 殖民地里程碑 | 人口/电力达标 | `Colony: 20 Power` |
| 专家 | 基因专家研究植物 | `Expert: Geneticist (awake)` |
| 研究台投入 | 10 机械件 | `Parts: 4/10 Mechanical` |

示例节点卡：

```
BASIC AUTOMATION                     40%
Branch: Industry · Tier 1
Progress
  Milestone: Research Bench built     20%
  Data: Ship engineering cache        10%
  Parts: 4/10 Mechanical Parts        10%
Unlocks: Miner, Road, Logistics Station, Truck
Owners: Commander
[Set as research target]   (requires Research Bench)
```

### 9.6 专家与共同科技

- 节点右上显示归属专家徽章：醒着（青）、睡着（灰）、已分配（琥珀）。
- 共同科技显示两个 owner 槽位；缺人时显示 `Requires: Geneticist + Doctor`。
- 专家贡献显示为加速，不是硬门槛（硬门槛单独标 `LOCKED`）。
- 后期 `COLONY / Colonists` 与 `ARCHIVE` 互相跳转：点专家看分支，点分支看专家。

### 9.7 薄片

- 底部 `SLIDES` 条显示已找到的玻璃薄片、完整度、对应节点。
- 点击薄片高亮节点；未知薄片显示 `???`。
- 薄片是物品，放在货仓/档案室；`ARCHIVE` 只是读取界面。
- 缺失薄片在节点详情里显示 `Missing slide: Power Distribution`，给探索目标。

## 10. 殖民地面板 `COLONY`

`COLONY` 是 L1 管理面板，不常驻。第一版可在基地/飞船附近打开；AI 等级足够后支持远程快照。

### 10.1 页签

| 页签 | 内容 |
|------|------|
| Overview | 天数/天气、人口、食物天数、电力满足率、当前科技目标、告警 |
| Resources | 分组库存、容量、趋势、低量预警 |
| Power | 发电/需求/满足率、电池、燃料、优先级、停机原因 |
| Production | 机器列表、配方、状态、缺料/缺电/满仓 |
| Colonists | 姓名、专长、状态、所属分支、当前任务（M5） |
| Logistics | 路线、车辆、货物、等待原因（M2.5 / F2.4） |

### 10.2 Overview 卡片

```
DAY 003 07:42      POP 1/6       FOOD 2.3 days
POWER 18/20 90%    WATER 40%     TECH Basic Automation 40%
ALERTS: Generator fuel low · Night in 00:42
```

每个卡片可点击跳到对应页签。

### 10.3 电力

- 只显示三个数：`supply / demand / satisfaction`，加电池和燃料。
- `satisfaction < 100%` 时，所有机器按比例降速；面板列出降速对象。
- 优先级分组：生命维持 > 研究 > 生产 > 充电。
- 第一版电力还是 flag/数值时，先显示 `18/20`，不假装有电网图。

## 11. 世界内界面（L2）

靠近目标时才出现的轻量面板，不用打开腕装终端：

| 目标 | 显示 |
|------|------|
| 建造点 | 名称、成本 `have/need`、缺什么、`[E] Build` |
| 热能发电机 | 燃料、水、温度、压力、输出、状态 |
| 研究台 | 当前目标、投入零件、进度、缺料 |
| 机器 | 配方、输入/输出缓冲、电力满足率、停机原因 |
| 物流站 | 库存、装/卸、充电、等待原因 |
| 休眠舱 | 缺失条件列表、`[E] Wake`（满足时） |
| 薄片架 | 薄片列表、完整度、`[E] Read` |

这些面板共用一套 `ContextPanel` 样式，避免每个机器一个 UI。

## 12. 通知与 AI 提示

### 12.1 通道

| 通道 | 用途 | 位置 | 时长 |
|------|------|------|------|
| AI subtitle | 叙事、教学、角色语气 | 底部中上 | 4 s |
| System toast | 系统事件：保存、任务完成、解锁 | 顶部中下 | 2–3 s |
| Alert banner | 紧急：断电、低电量、夜晚、风暴 | 顶部中 | 持续到解决或 10 s |
| Log | 历史记录、错过的事件 | `LOG` 页 | 永久（本次会话） |
| World marker | 资源/目标高亮 | 世界内 | 按需 |

### 12.2 优先级与去重

- Critical > Warning > Info > Flavor。
- 同一事件 30 秒内不重复；AI 提示走统一 `ShipAI` 总线（见 ROADMAP T2.5）。
- 同一时刻最多 1 条 Alert + 1 条 AI 字幕 + 3 条 Toast。
- AI 字幕不播报纯系统信息（如“保存成功”）；系统 Toast 不模仿 AI 语气。

### 12.3 示例

```
[ALERT]  SUIT BATTERY 8% — return to the ship
[ALERT]  NIGHT IN 00:42 — build a shelter or fire
[TOAST]  UNLOCKED: Basic Automation
[AI]     "The generator is out of fuel. We have maybe ten minutes of heat."
[LOG]    07:42  Generator stopped: fuel empty
```

## 13. 渐进展示

| 触发 | 新出现的 UI |
|------|-------------|
| 开场苏醒 | 只有字幕、交互提示、身份确认面板 |
| 穿上动力服 | 电池 → 体温 → 生命维持 → 交互提示（按 `opening.md` 分层点亮） |
| 第一次走出飞船 | 时间/昼夜、天气占位、当前目标 |
| 第一次拾取物品 | 快捷栏 + `I` 背包提示 |
| 第一次建造 | 建造成本 chip、固定资源条 |
| 热发电机建成 | 顶部基地电力、`COLONY / Power` |
| 研究台建成 / 第一片薄片 | `ARCHIVE` 页签、当前研究目标 |
| 第一条道路/第一台车 | `COLONY / Logistics` |
| 第一个专家醒来 | `COLONY / Colonists`、科技节点专家徽章 |

开场 UI 剧本（与 `opening.md` 对齐）：

```
0:00  黑屏 + 字幕；无 HUD
0:50  医疗屏身份确认；仍无 HUD
2:45  穿动力服：BATTERY 亮 → TEMP 亮 → VITALS 亮 → 交互提示亮
3:30  舱内：只显示电池/体温/提示
4:30  出舱：DAY 001 06:00、目标“First Night”、快捷栏
5:00+ 第一次拾取：PACK 提示；第一次建造：资源条
```

## 14. 视觉规范

与 [`art-direction.md`](art-direction.md) 的用色规则保持一致：蓝色 = 有电/AI 在线，
琥珀 = 可用/需要玩家注意，锈红 = 损坏/危险，青绿 = 制造/完成。

| 项 | 规则 |
|----|------|
| 底色 | 深青黑 `#141A1A`，82% 不透明 |
| 主文字 | 暖白 `#EDE8DC` |
| 系统/在线/进行中 | 冰蓝 `#79C7D8` |
| 强调/可用/可操作 | 琥珀 `#E08A3C` |
| 危险/异常/断电 | 锈红 `#B5483F` |
| 成功/制造/完成 | 青绿 `#9AD6C4` |
| 食物信号 | 莓红 `#A83A56` |
| 边框 | 1 px，`#3A4747`，重要面板 2 px |
| 字体 | 默认主题；数字用等宽/表格数字，避免跳动 |
| 字号 | 标题 18–20，正文 14–15，辅助 12–13；最小不低于 12 |
| 圆角 | 4 px，1 px 描边；像飞船的物理面板，不用大圆角卡片 |
| 动效 | 150–200 ms 淡入；只给警报/低电量做脉冲；不做常驻扫描线动画 |
| 图标 | 单色线性 + 状态色；没有美术时用 2 字母色块 |
| 可读性 | 对比度 ≥ 4.5:1；颜色之外必须有文字/形状 |
| 风格 | 沿用 `gu_core` Protoss 的细线、深色半透明、等宽大写与字距，但压掉装饰；共享全息材质只用于档案/终端 |

## 15. 输入与冲突

### 15.1 现有按键

| 键 | 迁移后功能 | 说明 |
|----|------------|------|
| `1–6` | 选择快捷栏 | 旧 `1–4` 动作键已释放 |
| `F` | 使用选中物 / 工具动作 | 旧 `Repeat Action` 已释放 |
| `Space` | Strike | 保留为直接攻击 |
| `E` | Interact | 保留，无工具也能交互 |
| `H` | Eat berry | 保留为食物快捷方式 |
| `I` | Inventory → `PACK` | 腕装终端 |
| `T` | Archive | 腕装终端 |
| `Tab` | 腕装终端 | 打开 `PACK`，打开后切换页签 |
| `Shift` | Run | 保留 |
| 滚轮 / `+ -` | 缩放 | 不做快捷栏滚动 |
| `Esc` | 关闭面板 → 暂停 | 先关腕装终端 |
| `` ` `` | Dev console | 保留 |

### 15.2 已实现（D035）

- `1–6` 选择快捷栏；`F` 使用选中物。
- 工具驱动动作：knife → `gather`，axe → `chop`，pickaxe → `mine`，
  mallet → `build`，weapon → `strike`。
- 旧 `action_gather/mine/chop/build/repeat` 的键盘事件被清空；
  共享 `GuPlayer` 不再用 `1–4` 触发动作。
- 重新绑定/重置按键后，控制器会再次清空旧动作事件。
- 食物：`F` 使用选中食物；`wild_berry` 走现有 `HungerController.eat_berry()`。
- 聚焦采集点/建造点时，`F` 校验 `preferred_action` 与工具 tag，再调用 `interact()`。
- **未实现**：按住 `F` 循环动作、工具耐久、装备槽、自动切最佳工具。

## 16. 工程落点

### 16.1 文件结构（建议）

```
scenes/ui/hud.tscn                    # 常驻 HUD 根场景
scenes/ui/wrist_computer.tscn         # 腕装终端（PACK / ARCHIVE / COLONY / LOG）
scenes/ui/context_panel.tscn          # 建造点/机器/休眠舱共用样式

scripts/ui/hud/seed_hud.gd            # HUD 根：绑定服务、显隐、层级
scripts/ui/hud/clock_widget.gd
scripts/ui/hud/vitals_panel.gd
scripts/ui/hud/resource_strip.gd
scripts/ui/hud/hotbar.gd
scripts/ui/hud/hotbar_controller.gd
scripts/ui/hud/objective_panel.gd
scripts/ui/hud/alert_stack.gd

scripts/ui/wrist/wrist_computer.gd
scripts/ui/wrist/pack_screen.gd
scripts/ui/wrist/archive_screen.gd
scripts/ui/wrist/colony_screen.gd
scripts/ui/wrist/log_screen.gd

scripts/world/world_time.gd           # 日历/昼夜，从 GameClock 派生
scripts/colony/resource_ledger.gd     # 随身/基地资源聚合
scripts/tech/tech_service.gd          # 随 F1.4 实现；UI 只读
```

- 不修改 `addons/gu_core` / `addons/gu_gameplay`。
- 可以复用 `StatBar`、`QuestHud`、`UIRouter`、`TooltipFrame`；常驻 HUD 用 Seed 自己的紧凑组件。
- `main.gd` 目前负责创建 HUD；改为实例化 `hud.tscn`，把绑定逻辑移到 `seed_hud.gd`。
- L1 面板通过 `UIRouter.register_screen` 注册，享受屏幕栈、输入上下文、Toast。
- 层级建议：HUD 20，Prompt 35，AI 36，Dialogue 40，UIRouter 50，Overlay 100。
  对白打开时，腕装终端应关闭或让对白盖在最上层。

### 16.2 服务

`WorldTime`（建议自动加载）：

```gdscript
signal minute_changed(day: int, hour: int, minute: int)
signal phase_changed(phase: StringName)  # dawn/day/dusk/night
signal day_changed(day: int)

const DAY_LENGTH_REAL_SECONDS := 1800.0  # 30 real minutes
const SECONDS_PER_GAME_HOUR := 75.0
const DAY_START_HOUR := 6.0
```

- `GameClock.world_seconds` 是唯一时间源。
- `WorldTime` 只做派生、边界信号、格式化；不自己累加时间。
- 纯函数 `format_clock(world_seconds) -> "07:42"`、`phase_for_hour(hour)` 便于测试。
- 新游戏/读档时随 `GameClock` 自动重置/恢复。

`ResourceLedger`：

- 注册多个 `InventoryContainer`（玩家、基地仓库、物流站）并标注 scope。
- 缓存分组总量，`inventory_changed` 时重算，不做每帧扫描。
- 提供 `get_count(item_id)`、`get_group_totals(group)`、`get_trend(item_id)`。
- HUD 只订阅变化信号。

`TechService`（F1.4 实现）：

- 节点定义来自 `data/content/tech.json`。
- `add_progress(node_id, source, amount)`；UI 只读展示。
- 专家/薄片/里程碑作为 source 写入，不另建 UI 状态。

### 16.3 数据与本地化

- `items.json` 建议增加可选字段：`ui_group`、`icon`、`color`、`hotbar_priority`。
- `tech.json`（F1.4）需要：`branch`、`tier`、`parents`、`owners`、`shared`、`sources`、
  `cost`、`unlocks`、`description`、`slide_id`。
- 所有可见文本进 `data/ui_i18n.csv`，前缀建议：
  `HUD_`、`CLOCK_`、`RES_`、`PACK_`、`ARCHIVE_`、`COLONY_`、`ALERT_`。
- 不在代码里写英文 UI 文案；动态文本用 `tr()`。

### 16.4 存档

- `GameClock.world_seconds`：已有。
- 玩家背包：已有。
- 快捷栏映射、固定资源 pin、当前研究目标：后续各自注册 saveable。
- UI 打开状态不存档；读档后回到常驻 HUD。

## 17. 实施阶段

| 阶段 | 内容 | 依赖 | 验收 |
|------|------|------|------|
| UI-0 | 本文档 + HUD 线框 + 组件拆分 | 无 | 评审通过 |
| UI-1 | `WorldTime` + 常驻时钟 + 昼夜阶段信号 | `GameClock` | 时钟只在 PLAYING 前进；存读档正确 |
| UI-2 | HUD 根场景：生命/饥饿/体力/电池、目标、快捷栏、固定资源、提示重排 | UI-1 | 1280×720 / 1024×576 不重叠；替换 `GameplayHud` |
| UI-3 | 腕装终端 + `PACK` + 装备槽 + 快捷栏映射 | UI-2 | `I`/`Tab`/`Esc` 行为正确；无卡输入 |
| UI-4 | `ARCHIVE`：分支、节点、来源、薄片、远程只读 | F1.4 `tech.json` + 研究台 | 节点状态/进度来源正确 |
| UI-5 | `COLONY`：Overview / Resources / Power | T2.1 / F1.5 | 电力与库存数字与运行时一致 |
| UI-6 | `COLONY / Logistics` + 路线 UI | F2.4 | 取货→卸货路线可分配 |
| UI-7 | `LOG`、通知历史、地图入口 | UI-4/5 | 事件可追溯；不刷屏 |

优先级建议：

1. **时间 + 生命维持 + 快捷栏**（玩家每小时都在看）。
2. **PACK**（现在中央弹窗必须换掉）。
3. **ARCHIVE**（等 `tech.json`）。
4. **COLONY**（等电力/工厂）。
5. **物流/地图**（等 M2.5 / M6）。

## 18. 测试与验收

### 18.1 单元测试（headless）

- `WorldTime.format_clock(0)` / 跨日 / 23:59→00:00 / 非整点。
- `phase_for_hour()` 边界：04:59/05:00/07:00/17:00/19:00/05:00。
- `day_index()` 第 1 天从 1 开始；读档恢复。
- `ResourceLedger` 多容器聚合、低量阈值、趋势符号。
- `Hotbar` 映射：空槽、物品被丢弃、数量变化。
- `TechService` 节点状态：unknown/fragment/available/locked/complete。
- 所有 `tr()` key 存在（可加 data 校验脚本）。

### 18.2 场景测试

- 实例化 `hud.tscn`，绑定假服务，断言标签文本。
- 打开 `PACK` → 断言 `InputRouter` 上下文压入；关闭 → 弹出。
- `Esc` 先关面板，不触发暂停。
- 对白打开时腕装终端关闭/被遮挡。
- 1280×720 与 1024×576 下关键控件矩形不重叠（可用 `get_global_rect()` 断言）。

### 18.3 手动验收

1. 新游戏：开场只有字幕/提示；穿动力服后 HUD 分层出现。
2. 07:42 时钟正常走；暂停/读档冻结/恢复。
3. 采浆果：快捷栏和固定资源条更新；`+3` 浮字。
4. 按 `1–6` 选中小刀/野果：快捷栏描边和上方提示变化；`F` 采浆果或吃东西。
5. 旧 `1–4` 不再直接触发 Gather/Mine/Chop/Build。
6. `I` 打开背包，4×4 网格、物品详情、关闭不卡输入。
5. 建庇护所：成本 chip 显示 `wood 3/5`，不足变红。
6. 建研究台：`ARCHIVE` 解锁；远程只读，台前可设目标。
7. 建发电机：顶部出现 `POWER 18/20`；`COLONY / Power` 与之一致。
8. 夜晚前 1 小时出现 `NIGHT IN`；夜晚时钟变色。

## 19. 已拍板

| # | 决定 | 值 | 记录 |
|---|------|----|------|
| 1 | 本地日长度 | **30 真实分钟 / 24 小时** | D034 |
| 2 | 睡觉 | **不强制**；可选 1h / 2h / 4h / 睡到黎明 | D034 |
| 3 | 动作键 | **工具驱动**；`1–6` 选择，`F` 使用（已实现） | D035 |
| 4 | 腕装终端打开时 | **暂停游戏** | D036 |

## 20. 待拍板

| # | 问题 | 选项 | 建议 |
|---|------|------|------|
| 1 | 背包 16 格还是扩到 24/30？ | 16 / 24 / 30 | **第一版 16**，UI 读 `max_slots` |
| 2 | 科技能否随地看？ | A 只能终端；B 随处只读，台前操作 | **B**，兼顾可读性与设定 |
| 3 | 快捷栏 6 格还是 8 格？ | 6 / 8 | **6**，16 格背包下够用 |
| 4 | 任务 HUD 常驻还是只显示 1 条？ | 全列表 / 1 条 | **1 条**，`J` 展开 |
| 5 | 温度单位？ | °C / °F | **°C 默认**，后续加设置 |
| 6 | 第一版做天气吗？ | 做 / 只占位 | **只占位**，时钟先做扎实 |
| 7 | 本地日叫 `DAY` 还是 `CYCLE`？ | DAY / CYCLE | **DAY**，玩家更直觉 |

## 变更记录

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-11-21 | v0.1 | 首版 HUD 规划：现状审计、三层信息架构、时间/资源/背包/科技/殖民地布局、渐进展示、工程落点与 UI-0–UI-7 阶段 |
| 2026-11-21 | v0.2 | 锁定 30 分钟本地日、可选睡觉、工具驱动动作键、腕装终端暂停 |
| 2026-11-21 | v0.3 | UI-1/UI-2 落地：`WorldTime`、Seed HUD、腕装终端 PACK/ARCHIVE 只读；UI-3.5 待做 |
| 2026-11-22 | v0.4 | UI-3.5 落地：`1–6` 快捷栏、`F` 使用、工具 tag → 动作、旧动作键释放、选中提示 |
