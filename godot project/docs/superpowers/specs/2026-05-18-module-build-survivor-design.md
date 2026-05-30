# 模块构筑型幸存者设计说明

## 目标

做一个适合 Godot 新人的肉鸽幸存者原型，核心卖点不是大量独立武器，而是`通过模块拼装来改变同一把武器的行为`。

第一版可玩原型只需要证明一件事：

- 同一把基础武器，在不同模块组合下，行为会出现明显变化。

## 范围

V1 必须刻意控制体量：

- 1 个玩家角色
- 1 把基础武器
- 2 个模块槽位
- 每个槽位 3 个模块
- 3 种敌人
- 1 张地图
- 1 套完整局内升级循环

V1 不做这些内容：

- 局外制作或背包系统
- 稀有度树
- 商店
- 程序化地图
- 元进度
- 完整通用状态效果框架

## 核心设计

基础循环仍然是标准幸存者结构：

1. 移动
2. 自动攻击
3. 击杀敌人
4. 获取经验
5. 选择升级
6. 在局内拼出自己的 build

这个项目的区分点在于：升级不主要是平面数值加成，而是`往武器上安装或替换模块`。

推荐的 V1 模块布局：

- `fire_mode`：单发、三连发、散射
- `payload`：普通、穿透、爆炸

这样只用 1 把基础武器，就能做出 9 种肉眼可感知的组合，而不用真的做 9 把武器。

## 角色模型与基础武器

角色形态可以作为`基础武器母题`，但不要成为攻击规则的来源。

推荐关系：

- `角色模型`：定义视觉身份和基础武器幻想，例如长枪手、枪械手、法杖手。
- `CharacterData`：定义基础属性、初始模块和开局构筑倾向。
- `模块`：仍然负责局内攻击方式变化。
- `ShotProfile`：仍然是最终攻击行为的唯一执行边界。

例如初始角色拿长枪时，长枪不是一套独立攻击系统，而是统一的攻击解释框架：

- `单发` 表现为一次直刺或一道枪芒。
- `三连发` 表现为连续三段刺击或三道枪影。
- `散射` 表现为扇形枪影。
- `穿透` 表现为贯穿枪芒。
- `爆炸` 表现为枪尖命中后的震爆、符文爆裂或地面冲击波。

这意味着“长枪攻击次数 +1”可以作为模块强化之一，但不能把模块系统降级成只给长枪加数值。模块仍然要制造肉眼可感知的攻击结构变化，只是表现上包装成该角色基础武器能够做出的招式或附魔效果。

V1 不推荐为每个角色制作完全独立的模块池。更稳的做法是让不同角色共享模块逻辑，但通过初始模块、基础属性、模块文案、子弹/VFX 和攻击动画，形成不同开局风格。

## 架构

建议采用简单的分层结构，不要一开始就过度抽象。

### 1. 场景层

用途：承载 Godot 节点、碰撞、定时器、可视对象、生成物。

推荐场景：

- `scenes/main/game_root.tscn`
- `scenes/player/player.tscn`
- `scenes/enemies/enemy_basic.tscn`
- `scenes/enemies/enemy_fast.tscn`
- `scenes/enemies/enemy_tank.tscn`
- `scenes/weapons/projectile.tscn`
- `scenes/ui/hud.tscn`
- `scenes/ui/level_up_panel.tscn`

场景层尽量保持薄。节点脚本主要负责转发，不要在这里堆规则。

### 2. 玩法层

用途：承载游戏规则和运行时调度。

推荐脚本：

- `scripts/game/run_manager.gd`
- `scripts/game/spawn_manager.gd`
- `scripts/player/player_controller.gd`
- `scripts/combat/weapon_controller.gd`
- `scripts/combat/projectile_controller.gd`
- `scripts/combat/hit_resolver.gd`
- `scripts/progression/xp_manager.gd`
- `scripts/progression/upgrade_manager.gd`
- `scripts/build/build_state.gd`
- `scripts/build/module_applier.gd`

职责建议：

- `run_manager`：管理整局状态、暂停、开始、失败、升级流程
- `spawn_manager`：管理刷怪节奏
- `weapon_controller`：向当前 build 询问这次该怎么开火
- `build_state`：保存当前模块选择和推导后的最终属性
- `module_applier`：把已选模块转换成实际可执行的射击行为

### 3. 数据层

用途：承载可编辑配置，而不是场景逻辑。

推荐直接用 Godot 的 `Resource` 做数据，这是对新手最友好的数据驱动方式。

推荐资源：

- `resources/weapons/base_weapon_data.gd`
- `resources/modules/module_data.gd`
- `resources/modules/fire_mode_module_data.gd`
- `resources/modules/payload_module_data.gd`
- `resources/upgrades/upgrade_option_data.gd`
- `resources/enemies/enemy_data.gd`

每个资源至少要能回答：

- 它是什么
- 它属于哪个类别
- 它改变哪些参数
- 它在 UI 里怎么显示

### 4. 表现层

用途：把状态清楚地展示给玩家。

推荐脚本：

- `scripts/ui/hud_controller.gd`
- `scripts/ui/level_up_panel_controller.gd`
- `scripts/ui/upgrade_card.gd`

表现层不要参与 build 规则计算。它只读取状态并负责展示。

## 数据模型

这个方向里，新手最容易踩的坑就是太早去做“完全通用的修饰器系统”。

不要从“模块可以做任何事”开始，而应该从`受限制的模块模式`开始。

### Base Weapon Data

基础武器定义默认值，例如：

- damage
- cooldown
- projectile_speed
- projectile_lifetime
- projectile_size

### Module Data

每个模块建议至少包含：

- `id`
- `display_name`
- `description`
- `slot_type`
- `stat_modifiers`
- `behavior_flags`

示例模块：

- `single_shot`
- `burst_fire`
- `spread_fire`
- `piercing_round`
- `explosive_round`

### Build State

`build_state` 应该按槽位保存当前已选模块。

结构示例：

```gdscript
{
    "fire_mode": "burst_fire",
    "payload": "explosive_round"
}
```

它还应该能对外暴露推导后的结果，例如：

- 最终冷却
- 子弹数量
- 散射角度
- 穿透次数
- 爆炸半径

这些结果不要分散到子弹脚本里临时重算。应该在 build 改变时，或在准备开火时，统一结算一次。

### Upgrade Options

升级选项应该主要指向模块资源，少量保留普通数值升级。

V1 推荐比例：

- 80% 是模块选择
- 20% 是普通但有用的数值选择

这样游戏的身份会更明确。

## 推荐执行模型

最干净的执行路径应该是：

1. `weapon_controller` 向 `build_state` 请求一份射击配置
2. `module_applier` 把基础武器数据和已选模块组合起来
3. 返回一个 `shot_profile` 字典或轻量对象
4. `weapon_controller` 根据它生成一个或多个子弹
5. `projectile_controller` 只处理移动和命中

一个 `shot_profile` 可以包含这些字段：

- `projectile_count`
- `angles`
- `damage`
- `speed`
- `pierce_count`
- `explosion_radius`
- `burst_count`
- `burst_interval`

这是整个架构里最关键的边界。只要这个边界清楚，后面加内容时就不需要反复重写战斗逻辑。

## 推荐目录结构

```text
res://
  scenes/
    main/
    player/
    enemies/
    weapons/
    ui/
  scripts/
    game/
    player/
    combat/
    progression/
    build/
    ui/
  resources/
    weapons/
    modules/
    upgrades/
    enemies/
  art/
  audio/
```

## 主要难点

真正麻烦的点，不是表面上那些“先写个子弹、写个敌人”。

### 1. 过早抽象系统

这是最大风险。

新手非常容易一上来就做一个“万能模块系统”：可组合、可叠加、事件驱动、什么效果都能插进去。听起来很优雅，但第一款游戏这么做，通常会把开发节奏拖死。

正确做法：

- V1 里硬性限制模块类别
- 针对这几个类别写一部分专用逻辑
- 接受它是“部分特化”的实现

你要的是“够扩展”，不是“未来所有游戏的底层引擎”。

### 2. 组合规则变得不清楚

这个项目成立的前提，是玩家能看懂组合后的结果。

如果玩家无法预测 `burst + explosive` 到底会变成什么，那系统就算代码没错，也算失败。

正确做法：

- 每个槽位只改变一个清晰维度
- UI 用自然语言预告结果
- V1 不做隐藏联动

反例：

- 一个模块同时改变发射数、伤害倍率、命中附带状态

更好的做法：

- 一个模块只改发射模式
- 另一个模块只改命中效果

### 3. Build 逻辑散落到太多文件

如果一部分 build 逻辑在 UI，一部分在子弹，一部分在玩家，一部分在敌人受击代码里，AI 辅助效果会明显变差，排错也会很痛苦。

正确做法：

- 把 build 结算集中在 `build_state` 和 `module_applier`
- 子弹只执行已经结算好的结果
- UI 只显示状态

这一点对 AI 特别重要，因为 AI 在文件职责清晰、接口收口明确的情况下，生成质量会高很多。

### 4. 乘法型平衡爆炸

哪怕模块数量很少，数值也很容易炸。

例如：

- 三连发增加子弹数
- 爆炸弹增加范围伤害
- 冷却缩减减少发射间隔

三个东西一乘起来，整局难度曲线可能直接被打穿。

正确做法：

- 数值先保守
- 测试组合，不只测单个模块
- 提前限制 pierce、burst、AoE 的上限

必要时可以做组合级别的平衡表，不要假设局部合理就一定整体合理。

### 5. 当前 Build 的信息表达

这种游戏如果玩家读不懂自己现在的 build，体验会掉得很快。

正确做法：

- HUD 按槽位显示当前模块
- 升级卡明确写出会发生什么变化
- 用“发射三连发”这种句子，而不是抽象标签

### 6. 内容压力

系统驱动游戏很容易让人误以为“内容很省”。它确实比手工做十几把武器省，但绝不是免费。

每加一个模块，你都多了这些工作：

- 实现
- 平衡
- UI 描述
- 测试用例
- 交互联动检查

所以 V1 的内容量一定要小。

## AI 辅助开发策略

AI 应该作为`有边界的实现搭档`，而不是替你决定系统设计的人。

### AI 适合做的事

- 搭目录、场景、样板脚本
- 起草 `Resource` 类
- 生成重复性的升级卡 UI 代码
- 写第一版验证脚本
- 检查单个文件是否职责漂移
- 在已有稳定基线上提出局部重构建议

### AI 不适合做的事

- 一次性设计整套模块系统
- 在项目中途自由发明新抽象
- 只靠理论帮你做平衡
- 在没有明确合同的情况下同时改 10 个耦合文件

AI 很喜欢过度抽象和预留未来扩展。对这个项目来说，这通常是负收益。

### 最稳的 AI 工作流

1. 你先定义一个文件或一个子系统的明确职责
2. 让 AI 生成第一版
3. 你在 Godot 里运行，拿到具体错误或具体行为偏差
4. 再让 AI 按这些问题修
5. 行为稳定后，才考虑泛化

例如：

- 好提示词：`帮我为 Godot 4 写一个 ModuleData Resource，包含 id、display_name、slot_type、description 和少量 stat_modifiers，不要先做未来所有模块类型的继承体系。`
- 坏提示词：`帮我设计一个可无限扩展的模块化肉鸽武器系统。`

## 对 AI 友好的边界

如果你想让 AI 一直保持高质量，文件之间的合同必须稳定。

推荐的几个核心合同：

- `module_data.gd`：定义模块数据结构
- `build_state.gd`：保存已选模块并输出最终 build 状态
- `module_applier.gd`：把基础武器和模块转换成 `shot_profile`
- `weapon_controller.gd`：根据 `shot_profile` 开火
- `projectile_controller.gd`：只处理移动和命中效果

这样你每次都可以把一个小而清楚的单元交给 AI，而不是每次都把全项目上下文重新塞一遍。

## 推荐实现顺序

1. 先做移动、敌人、经验、普通单发武器
2. 加入 `BaseWeaponData`
3. 加入 `ModuleData` 和两个模块槽位
4. 实现 `build_state`
5. 实现 `module_applier`
6. 让升级选项能够安装模块
7. 加入展示当前 build 的 UI
8. 调整联动和平衡

这个顺序的原因很简单：不要在基础战斗循环还没跑顺之前，就提前造模块系统。

## 验证标准

满足以下条件，就可以进入下一步实现计划：

- 同一把武器在至少 4 种组合下表现差异明显
- 新增一个模块时，不需要去多个地方改子弹逻辑
- 升级选择能明显更新 build 状态和武器行为
- HUD 能让玩家读懂当前 build

## 结论建议

对于一个会使用 AI 辅助开发的新手来说，最稳的策略是：

- 小型模块矩阵
- 半数据驱动
- 集中式 build 结算
- V1 允许一定程度的特化逻辑，而不是追求万能抽象

这样项目对你自己是可理解的，对 AI 也是可理解的。现阶段这件事比“架构看起来多优雅”更重要。
