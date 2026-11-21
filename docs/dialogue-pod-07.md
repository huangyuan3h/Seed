# Seed — 07 号舱对白树

> 状态：已合并 + 已接进场景 v0.3 · 2026-11-21
>
> 覆盖三段对话：
> 1. `pod_07`：第一次检查空休眠舱（第一幕）。
> 2. `pod_07_after_power`：基础电力恢复后，AI 主动提起（第一幕末）。
> 3. `pod_07_chip_log`：后期分析数据芯片（第二/三幕）。
>
> v0.2：已合并进 `data/content/dialogue.json`、`data/content/items.json`、`data/ui_i18n.csv`。
> v0.3：已接进灰色场景——`scenes/world/pod_07.tscn` + `scripts/world/pod_07.gd`，并实例化到 `scenes/main.tscn`；测试增加 Pod 07 生成与交互断言。
>
> 关联文档：[`anomaly-01-empty-pod.md`](anomaly-01-empty-pod.md) · [`opening.md`](opening.md) · [`story.md`](story.md)

## 1. 触发条件

| 对话 | 触发 | 前置条件 | 只触发一次 |
|------|------|----------|------------|
| `pod_07` | 玩家交互 07 号休眠舱 | 无 | 否；可以反复检查，但 `pod_07_seen` 已设置 |
| `pod_07_after_power` | 基础电力恢复后，AI 主动发起 | `ai_level_1 == true` 且 `pod_07_after_power_seen == false` | 是 |
| `pod_07_chip_log` | 在 AI 分析台读取 `data_chip_07` | 背包有 `data_chip_07` 且 `ai_level_2 == true` | 是 |

## 2. 节点图

```
pod_07
  look → ai_name → ai_pause
    ├─ where → where_copy → where_convenient
    ├─ manifest → who_change → who_change_2
    ├─ press → press_2 → press_3 → who_took
    ├─ fleet_link → fleet_link_2
    ├─ inspect_menu
    │   ├─ glass → glass_ai
    │   ├─ status → status_ai
    │   ├─ locker ─┬─ locker_ai → take_chip → take_chip_ai
    │   │          └─ locker_empty → locker_empty_ai
    │   └─ maintenance → maintenance_ai
    └─ leave_early / leave

pod_07_after_power
  after_power_1
    ├─ after_power_unseen
    └─ after_power_2 → after_power_3
        ├─ after_power_who → after_power_trust
        ├─ after_power_alive → after_power_alive_2
        ├─ after_power_fleet
        └─ after_power_end

pod_07_chip_log
  chip_1 → chip_2 → chip_3 → chip_4 → chip_5
    ├─ chip_6
    └─ chip_end
```

## 3. 状态、物品与条件

| 名称 | 类型 | 用途 |
|------|------|------|
| `pod_07_seen` | flag | 玩家第一次进入 07 号舱对话 |
| `pod_07_inspected` | flag | 至少检查过一次 |
| `pod_07_chip_taken` | flag | 已拿走数据芯片 |
| `pod_07_left_early` | flag | 第一次对话选择“先不管” |
| `pod_07_leave` | flag | 正常离开 |
| `pod_07_after_power_seen` | flag | 电力恢复后的回访已播放 |
| `pod_07_log_partial` | flag | AI 已读出一部分 07 号舱日志 |
| `pod_07_log_full` | flag | 数据芯片已完整读取 |
| `data_chip_07` | item | 关键物品；后期在 AI 分析台读取 |
| `ai_level_1` | flag | 基础电力恢复，AI 解锁基础分析 |
| `ai_level_2` | flag | AI 解锁打印/分析能力，可读取芯片 |

## 4. 对白树（中文）

### 4.1 `pod_07`：第一次检查

| 节点 | 说话者 | 中文 | 选项 / 去向 | 效果 |
|------|--------|------|-------------|------|
| `look` | 旁白 | 07 号休眠舱。舱盖半开，玻璃上有一层霜。状态屏还亮着：OCCUPIED / LIFE SIGNS: NONE。舱里没有人。 | → `ai_name` | 设置 `pod_07_seen`、`pod_07_inspected` |
| `ai_name` | 船载 AI | 07 号舱……应该是安全官 Vale。 | → `ai_pause` | — |
| `ai_pause` | 船载 AI | ……至少名单上是这么写的。 | 1. Vale 去哪了？→ `where`<br>2. 为什么状态屏还显示有人？→ `manifest`<br>3. 你知道发生了什么，对吗？→ `press`<br>4. 再仔细看看。→ `inspect_menu`<br>5. 先不管这个。→ `leave_early` | — |
| `where` | 船载 AI | 没有离舱记录。至少，我这里没有。 | 1. 还有别的记录吗？→ `where_copy`<br>2. 再仔细看看。→ `inspect_menu`<br>3. 先这样。→ `leave` | — |
| `where_copy` | 船载 AI | 如果有，也在我现在读不到的舱段里。 | 1. 真方便。→ `where_convenient`<br>2. 回到舱前。→ `inspect_menu`<br>3. 先这样。→ `leave` | — |
| `where_convenient` | 船载 AI | ……是啊。真方便。 | → `leave` | — |
| `manifest` | 船载 AI | 名单没有更新。或者，有人改过它。 | 1. 谁会改名单？→ `who_change`<br>2. 再仔细看看。→ `inspect_menu`<br>3. 先这样。→ `leave` | — |
| `who_change` | 船载 AI | 有权限的人。或者，不需要权限的人。 | 1. 这不是回答。→ `who_change_2`<br>2. 再仔细看看。→ `inspect_menu`<br>3. 先这样。→ `leave` | — |
| `who_change_2` | 船载 AI | 不是。 | → `leave` | — |
| `press` | 船载 AI | 我知道的和你知道的一样多，指挥官。而且我现在……读不到那段记录。 | 1. 读不到，还是不想说？→ `press_2`<br>2. 和舰队失联有关吗？→ `fleet_link`<br>3. 先这样。→ `leave` | — |
| `press_2` | 船载 AI | ……两者都有。 | → `press_3` | — |
| `press_3` | 船载 AI | 我的记忆不完整。有些记录不是损坏，是被人拿走了。 | 1. 谁拿走的？→ `who_took`<br>2. 再仔细看看。→ `inspect_menu`<br>3. 先这样。→ `leave` | — |
| `who_took` | 船载 AI | 我不知道。等电力恢复，我会查。 | 1. 再仔细看看。→ `inspect_menu`<br>2. 先这样。→ `leave` | — |
| `fleet_link` | 船载 AI | 舰队连接在脱离前就断了。不是自然中断。 | 1. 有人切断了它？→ `fleet_link_2`<br>2. 先这样。→ `leave` | — |
| `fleet_link_2` | 船载 AI | ……我不能确定。别让我猜，指挥官。 | 1. 再仔细看看。→ `inspect_menu`<br>2. 先这样。→ `leave` | — |
| `inspect_menu` | 旁白 | 你想检查哪里？ | 1. 玻璃和舱盖。→ `glass`<br>2. 状态屏。→ `status`<br>3. 储物柜。→ `locker`<br>4. 维护面板。→ `maintenance`<br>5. 够了。→ `leave` | — |
| `glass` | 旁白 | 玻璃是从里面裂开的。应急释放装置也坏了，方向朝内。 | → `glass_ai` | — |
| `glass_ai` | 船载 AI | 有人在里面醒来，然后强行打开了舱。但系统没有记录这次唤醒。 | 1. 回到检查。→ `inspect_menu`<br>2. 先这样。→ `leave` | — |
| `status` | 旁白 | 状态屏还在重复：OCCUPIED / LIFE SIGNS: NONE。 | → `status_ai` | — |
| `status_ai` | 船载 AI | 它还在等一个已经不在的人。 | 1. 回到检查。→ `inspect_menu`<br>2. 先这样。→ `leave` | — |
| `locker` | 旁白 | 储物柜开着。空的安全官枪套。地上有一枚数据芯片。 | 分支：`pod_07_chip_taken` 为真 → `locker_empty`；否则 → `locker_ai` | — |
| `locker_empty` | 旁白 | 储物柜已经空了。只剩下枪套。 | → `locker_empty_ai` | — |
| `locker_empty_ai` | 船载 AI | 芯片在你那里更安全。 | 1. 回到检查。→ `inspect_menu`<br>2. 先这样。→ `leave` | — |
| `locker_ai` | 船载 AI | 07 号舱的个人记录。拿走它。现在别打开。 | 1. 拿走芯片。→ `take_chip`（条件：`pod_07_chip_taken != true`）<br>2. 先不拿。→ `inspect_menu` | — |
| `take_chip` | 旁白 | 你捡起了数据芯片。 | → `take_chip_ai` | 添加 `data_chip_07` ×1；设置 `pod_07_chip_taken` |
| `take_chip_ai` | 船载 AI | 等我恢复算力，也许能读。现在打开，可能会烧掉它。 | 1. 回到检查。→ `inspect_menu`<br>2. 先这样。→ `leave` | — |
| `maintenance` | 旁白 | 维护面板锁死。需要电力。 | → `maintenance_ai` | — |
| `maintenance_ai` | 船载 AI | 现在强行打开，只会毁掉里面的记录。先修电，指挥官。 | 1. 回到检查。→ `inspect_menu`<br>2. 先这样。→ `leave` | — |
| `leave_early` | 船载 AI | ……好。但别碰那个舱。 | 结束 | 设置 `pod_07_left_early` |
| `leave` | 船载 AI | 走吧。修电要紧。……我会继续查。 | 结束 | 设置 `pod_07_leave` |

### 4.2 `pod_07_after_power`：基础电力恢复后

| 节点 | 说话者 | 中文 | 选项 / 去向 | 效果 |
|------|--------|------|-------------|------|
| `after_power_1` | 船载 AI | 指挥官，关于 07 号舱——我读到一点了。 | 分支：`pod_07_seen != true` → `after_power_unseen`；否则 → `after_power_2` | 设置 `pod_07_after_power_seen` |
| `after_power_unseen` | 船载 AI | 07 号舱是空的。我还没查完。你路过时可以看看。 | 结束 | — |
| `after_power_2` | 船载 AI | 它在迫降前十一小时被手动唤醒。唤醒指令来自船内，不是舰桥。 | → `after_power_3` | — |
| `after_power_3` | 船载 AI | 之后记录又断了。 | 1. 谁做的？→ `after_power_who`<br>2. Vale 还活着吗？→ `after_power_alive`<br>3. 和舰队失联有关吗？→ `after_power_fleet`<br>4. 先这样。→ `after_power_end` | 设置 `pod_07_log_partial` |
| `after_power_who` | 船载 AI | 我不知道。或者……我不确定现在该不该告诉你。 | 1. 你是在保护我，还是保护你自己？→ `after_power_trust`<br>2. 先这样。→ `after_power_end` | — |
| `after_power_trust` | 船载 AI | ……都有。 | → `after_power_end` | — |
| `after_power_alive` | 船载 AI | 没有生命信号。但也没有尸体。 | 1. 这不算“没有”。→ `after_power_alive_2`<br>2. 先这样。→ `after_power_end` | — |
| `after_power_alive_2` | 船载 AI | 不算。 | → `after_power_end` | — |
| `after_power_fleet` | 船载 AI | ……可能。等我能读到更多。 | 1. 先这样。→ `after_power_end` | — |
| `after_power_end` | 船载 AI | 先修电。等我能读到更多，我会告诉你。 | 结束 | — |

### 4.3 `pod_07_chip_log`：数据芯片后期分析

| 节点 | 说话者 | 中文 | 选项 / 去向 | 效果 |
|------|--------|------|-------------|------|
| `chip_1` | 旁白 | 数据芯片在分析台上亮起。Vale 的声音断断续续。 | → `chip_2` | — |
| `chip_2` | Vale | 如果有人听到这段记录：他们切断了舰队连接。不是意外。 | → `chip_3` | — |
| `chip_3` | Vale | 我试着阻止他们。如果我失败了，别相信名单。 | → `chip_4` | — |
| `chip_4` | Vale | 告诉指挥官—— | → `chip_5` | — |
| `chip_5` | 船载 AI | ……这是 Vale 的声音。录这段话的时候，Vale 还活着。至少那时候还活着。 | 1. 我们得找到 Vale。→ `chip_6`<br>2. 记住这件事。→ `chip_end` | 设置 `pod_07_log_full` |
| `chip_6` | 船载 AI | 如果 Vale 还在这艘船上，我们会的。 | 结束 | — |
| `chip_end` | 船载 AI | 我会记住。 | 结束 | — |

## 5. 完整 JSON（可直接粘进 `data/content/dialogue.json` 的 `rows`）

```json
[
  {
    "id": "pod_07",
    "start": "look",
    "nodes": [
      {
        "id": "look",
        "speaker": "Narration",
        "text": "Pod 07. The lid is half open. Frost on the glass. The status screen still reads: OCCUPIED / LIFE SIGNS: NONE. There is no one inside.",
        "effects": [
          { "type": "set_flag", "id": "pod_07_seen", "value": true },
          { "type": "set_flag", "id": "pod_07_inspected", "value": true }
        ],
        "next": "ai_name"
      },
      {
        "id": "ai_name",
        "speaker": "Ship AI",
        "text": "Pod 07... that should be Security Officer Vale.",
        "next": "ai_pause"
      },
      {
        "id": "ai_pause",
        "speaker": "Ship AI",
        "text": "...At least, that's what the manifest says.",
        "choices": [
          { "text": "Where did Vale go?", "next": "where" },
          { "text": "Why does the screen still say occupied?", "next": "manifest" },
          { "text": "You know what happened, don't you?", "next": "press" },
          { "text": "Let me take a closer look.", "next": "inspect_menu" },
          { "text": "Leave it for now.", "next": "leave_early" }
        ]
      },
      {
        "id": "where",
        "speaker": "Ship AI",
        "text": "No exit record. At least, not in my copy.",
        "choices": [
          { "text": "Is there another copy?", "next": "where_copy" },
          { "text": "Let me take a closer look.", "next": "inspect_menu" },
          { "text": "Leave it for now.", "next": "leave" }
        ]
      },
      {
        "id": "where_copy",
        "speaker": "Ship AI",
        "text": "If there is, it's in a section I can't read right now.",
        "choices": [
          { "text": "Convenient.", "next": "where_convenient" },
          { "text": "Back to the pod.", "next": "inspect_menu" },
          { "text": "Leave it for now.", "next": "leave" }
        ]
      },
      {
        "id": "where_convenient",
        "speaker": "Ship AI",
        "text": "...Yes. Convenient.",
        "next": "leave"
      },
      {
        "id": "manifest",
        "speaker": "Ship AI",
        "text": "The manifest wasn't updated. Or someone changed it.",
        "choices": [
          { "text": "Who would change it?", "next": "who_change" },
          { "text": "Let me take a closer look.", "next": "inspect_menu" },
          { "text": "Leave it for now.", "next": "leave" }
        ]
      },
      {
        "id": "who_change",
        "speaker": "Ship AI",
        "text": "Someone with access. Or someone who didn't need it.",
        "choices": [
          { "text": "That's not an answer.", "next": "who_change_2" },
          { "text": "Let me take a closer look.", "next": "inspect_menu" },
          { "text": "Leave it for now.", "next": "leave" }
        ]
      },
      {
        "id": "who_change_2",
        "speaker": "Ship AI",
        "text": "No. It isn't.",
        "next": "leave"
      },
      {
        "id": "press",
        "speaker": "Ship AI",
        "text": "I know as much as you do, Commander. And right now... I can't read that record.",
        "choices": [
          { "text": "Can't, or won't?", "next": "press_2" },
          { "text": "Is this connected to the fleet link?", "next": "fleet_link" },
          { "text": "Leave it for now.", "next": "leave" }
        ]
      },
      {
        "id": "press_2",
        "speaker": "Ship AI",
        "text": "...Both.",
        "next": "press_3"
      },
      {
        "id": "press_3",
        "speaker": "Ship AI",
        "text": "My memory is incomplete. Some records weren't damaged. They were taken.",
        "choices": [
          { "text": "Who took them?", "next": "who_took" },
          { "text": "Let me take a closer look.", "next": "inspect_menu" },
          { "text": "Leave it for now.", "next": "leave" }
        ]
      },
      {
        "id": "who_took",
        "speaker": "Ship AI",
        "text": "I don't know. When the power is back, I'll look.",
        "choices": [
          { "text": "Let me take a closer look.", "next": "inspect_menu" },
          { "text": "Leave it for now.", "next": "leave" }
        ]
      },
      {
        "id": "fleet_link",
        "speaker": "Ship AI",
        "text": "The fleet link was cut before we dropped out. It wasn't a natural failure.",
        "choices": [
          { "text": "Someone cut it?", "next": "fleet_link_2" },
          { "text": "Leave it for now.", "next": "leave" }
        ]
      },
      {
        "id": "fleet_link_2",
        "speaker": "Ship AI",
        "text": "...I can't be sure. Don't make me guess, Commander.",
        "choices": [
          { "text": "Let me take a closer look.", "next": "inspect_menu" },
          { "text": "Leave it for now.", "next": "leave" }
        ]
      },
      {
        "id": "inspect_menu",
        "speaker": "Narration",
        "text": "What do you want to check?",
        "choices": [
          { "text": "The glass and the lid.", "next": "glass" },
          { "text": "The status screen.", "next": "status" },
          { "text": "The locker.", "next": "locker" },
          { "text": "The maintenance panel.", "next": "maintenance" },
          { "text": "That's enough.", "next": "leave" }
        ]
      },
      {
        "id": "glass",
        "speaker": "Narration",
        "text": "The glass is cracked from the inside. The emergency release is broken too. It was forced inward.",
        "next": "glass_ai"
      },
      {
        "id": "glass_ai",
        "speaker": "Ship AI",
        "text": "Someone woke up inside and forced the pod open. But the system has no record of a wake-up.",
        "choices": [
          { "text": "Back to the pod.", "next": "inspect_menu" },
          { "text": "Leave it for now.", "next": "leave" }
        ]
      },
      {
        "id": "status",
        "speaker": "Narration",
        "text": "The status screen keeps repeating: OCCUPIED / LIFE SIGNS: NONE.",
        "next": "status_ai"
      },
      {
        "id": "status_ai",
        "speaker": "Ship AI",
        "text": "It's still waiting for someone who isn't there.",
        "choices": [
          { "text": "Back to the pod.", "next": "inspect_menu" },
          { "text": "Leave it for now.", "next": "leave" }
        ]
      },
      {
        "id": "locker",
        "speaker": "Narration",
        "text": "The locker is open. An empty security holster. A data chip on the floor.",
        "branches": [
          { "conditions": [ { "type": "flag", "id": "pod_07_chip_taken", "op": "eq", "value": true } ], "next": "locker_empty" }
        ],
        "next": "locker_ai"
      },
      {
        "id": "locker_empty",
        "speaker": "Narration",
        "text": "The locker is empty now. Only the holster is left.",
        "next": "locker_empty_ai"
      },
      {
        "id": "locker_empty_ai",
        "speaker": "Ship AI",
        "text": "The chip is safer with you.",
        "choices": [
          { "text": "Back to the pod.", "next": "inspect_menu" },
          { "text": "Leave it for now.", "next": "leave" }
        ]
      },
      {
        "id": "locker_ai",
        "speaker": "Ship AI",
        "text": "Pod 07's personal log. Take it. Don't open it now.",
        "choices": [
          {
            "text": "Take the chip.",
            "next": "take_chip",
            "conditions": [ { "type": "flag", "id": "pod_07_chip_taken", "op": "neq", "value": true } ]
          },
          { "text": "Leave it.", "next": "inspect_menu" }
        ]
      },
      {
        "id": "take_chip",
        "speaker": "Narration",
        "text": "You pick up the data chip.",
        "effects": [
          { "type": "add_item", "id": "data_chip_07", "amount": 1 },
          { "type": "set_flag", "id": "pod_07_chip_taken", "value": true }
        ],
        "next": "take_chip_ai"
      },
      {
        "id": "take_chip_ai",
        "speaker": "Ship AI",
        "text": "When I have more power, I might be able to read it. Opening it now could burn it.",
        "choices": [
          { "text": "Back to the pod.", "next": "inspect_menu" },
          { "text": "Leave it for now.", "next": "leave" }
        ]
      },
      {
        "id": "maintenance",
        "speaker": "Narration",
        "text": "The maintenance panel is locked. It needs power.",
        "next": "maintenance_ai"
      },
      {
        "id": "maintenance_ai",
        "speaker": "Ship AI",
        "text": "Forcing it now would destroy the records inside. Power first, Commander.",
        "choices": [
          { "text": "Back to the pod.", "next": "inspect_menu" },
          { "text": "Leave it for now.", "next": "leave" }
        ]
      },
      {
        "id": "leave_early",
        "speaker": "Ship AI",
        "text": "...All right. But don't touch that pod.",
        "effects": [
          { "type": "set_flag", "id": "pod_07_left_early", "value": true }
        ]
      },
      {
        "id": "leave",
        "speaker": "Ship AI",
        "text": "Let's go. Power first. ...I'll keep looking.",
        "effects": [
          { "type": "set_flag", "id": "pod_07_leave", "value": true }
        ]
      }
    ]
  },
  {
    "id": "pod_07_after_power",
    "start": "after_power_1",
    "nodes": [
      {
        "id": "after_power_1",
        "speaker": "Ship AI",
        "text": "Commander, about Pod 07. I've read a little more.",
        "effects": [
          { "type": "set_flag", "id": "pod_07_after_power_seen", "value": true }
        ],
        "branches": [
          { "conditions": [ { "type": "flag", "id": "pod_07_seen", "op": "neq", "value": true } ], "next": "after_power_unseen" }
        ],
        "next": "after_power_2"
      },
      {
        "id": "after_power_unseen",
        "speaker": "Ship AI",
        "text": "Pod 07 is empty. I haven't finished checking. You should see it when you pass through."
      },
      {
        "id": "after_power_2",
        "speaker": "Ship AI",
        "text": "It was manually awakened eleven hours before the crash. The wake command came from inside the ship, not the bridge.",
        "next": "after_power_3"
      },
      {
        "id": "after_power_3",
        "speaker": "Ship AI",
        "text": "After that, the record cuts off.",
        "effects": [
          { "type": "set_flag", "id": "pod_07_log_partial", "value": true }
        ],
        "choices": [
          { "text": "Who did it?", "next": "after_power_who" },
          { "text": "Is Vale alive?", "next": "after_power_alive" },
          { "text": "Is this connected to the fleet link?", "next": "after_power_fleet" },
          { "text": "Not now.", "next": "after_power_end" }
        ]
      },
      {
        "id": "after_power_who",
        "speaker": "Ship AI",
        "text": "I don't know. Or... I'm not sure I should tell you yet.",
        "choices": [
          { "text": "Are you protecting me, or yourself?", "next": "after_power_trust" },
          { "text": "Not now.", "next": "after_power_end" }
        ]
      },
      {
        "id": "after_power_trust",
        "speaker": "Ship AI",
        "text": "...Both.",
        "next": "after_power_end"
      },
      {
        "id": "after_power_alive",
        "speaker": "Ship AI",
        "text": "No life signs. But no body, either.",
        "choices": [
          { "text": "That's not a no.", "next": "after_power_alive_2" },
          { "text": "Not now.", "next": "after_power_end" }
        ]
      },
      {
        "id": "after_power_alive_2",
        "speaker": "Ship AI",
        "text": "No. It isn't.",
        "next": "after_power_end"
      },
      {
        "id": "after_power_fleet",
        "speaker": "Ship AI",
        "text": "...Possibly. When I can read more.",
        "choices": [
          { "text": "Not now.", "next": "after_power_end" }
        ]
      },
      {
        "id": "after_power_end",
        "speaker": "Ship AI",
        "text": "Power first. When I can read more, I'll tell you."
      }
    ]
  },
  {
    "id": "pod_07_chip_log",
    "start": "chip_1",
    "nodes": [
      {
        "id": "chip_1",
        "speaker": "Narration",
        "text": "The data chip wakes on the analysis table. Vale's voice is broken by static.",
        "next": "chip_2"
      },
      {
        "id": "chip_2",
        "speaker": "Vale",
        "text": "If anyone hears this: they cut the fleet link. It wasn't an accident.",
        "next": "chip_3"
      },
      {
        "id": "chip_3",
        "speaker": "Vale",
        "text": "I tried to stop them. If I failed, don't trust the manifest.",
        "next": "chip_4"
      },
      {
        "id": "chip_4",
        "speaker": "Vale",
        "text": "Tell the Commander—",
        "next": "chip_5"
      },
      {
        "id": "chip_5",
        "speaker": "Ship AI",
        "text": "...That's Vale's voice. Vale was alive when this was recorded. At least then.",
        "effects": [
          { "type": "set_flag", "id": "pod_07_log_full", "value": true }
        ],
        "choices": [
          { "text": "We need to find Vale.", "next": "chip_6" },
          { "text": "Remember this.", "next": "chip_end" }
        ]
      },
      {
        "id": "chip_6",
        "speaker": "Ship AI",
        "text": "If Vale is still on this ship, we will."
      },
      {
        "id": "chip_end",
        "speaker": "Ship AI",
        "text": "I will."
      }
    ]
  }
]
```

## 6. 合并步骤（已完成）

以下步骤已在 2026-11-21 执行；保留用于复现或迁移到其他项目。

1. 把上面的三个对象追加到 `data/content/dialogue.json` 的 `rows`。
2. 在 `data/content/items.json` 增加 `data_chip_07`：

```json
{
  "id": "data_chip_07",
  "display_name": "Pod 07 Data Chip",
  "max_stack": 1,
  "tags": ["quest", "data"]
}
```

3. 在 `data/ui_i18n.csv` 增加所有英文源串的 `zh` 翻译；
   `Narration` → 旁白，`Ship AI` → 船载 AI，`Vale` 可保留。
4. 在休眠舱区给 07 号舱加 `Interactable`，触发 `pod_07`。
5. 基础电力恢复后，由主流程/AI 触发 `pod_07_after_power`（检查 `ai_level_1` 和 `pod_07_after_power_seen`）。
6. AI 分析台读取 `data_chip_07` 时触发 `pod_07_chip_log`（检查 `ai_level_2` 和 `pod_07_log_full`）。
7. 跑：

```bash
/Users/huangyuan/Projects/game-utils/start.sh data validate "/Users/huangyuan/Projects/seed/data"
/Users/huangyuan/Projects/game-utils/start.sh check --project "/Users/huangyuan/Projects/seed"
```

## 7. 测试点

- `DialogueDef.is_valid()` 对三个新条目返回 true。
- 第一次检查：所有选项都能到达一个结束节点；不会卡死。
- 拿走芯片后再检查储物柜：走 `locker_empty`，不会重复添加 `data_chip_07`。
- 没有见过 07 号舱时触发 `pod_07_after_power`：走 `after_power_unseen`。
- 电力恢复后只触发一次回访。
- 芯片日志只播放一次；`pod_07_log_full` 正确设置。
- 存档/读档后，已拿走的芯片和已看过的对话不会重复。

## 8. 检查表

- [ ] `pod_07` 的所有 `next` 都指向存在的节点
- [ ] 拿走芯片的选项有 `pod_07_chip_taken != true` 条件
- [ ] `locker` 在芯片已拿走时走 `locker_empty`
- [ ] `pod_07_after_power` 在未见过 07 号舱时走 `after_power_unseen`
- [ ] 三个对话都只设置一次关键 flag
- [ ] 所有英文台词都有 `zh` 翻译
- [ ] `data_chip_07` 已注册到 `items.json`
- [ ] 数据校验和 `gu check` 全绿

## 变更记录

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-11-21 | v0.1 | 07 号舱三段对白树、完整 JSON、条件/效果、合并步骤与测试点 |
| 2026-11-21 | v0.2 | 已合并进 dialogue.json、items.json、ui_i18n.csv；新增 4 条测试断言 |
| 2026-11-21 | v0.3 | 已接进 scenes/main.tscn 的灰色 Pod 07；新增场景与交互断言 |
