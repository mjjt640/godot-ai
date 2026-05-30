# 模块构筑型幸存者架构草图（Architecture Sketch）

## 目标

先把架构边界定清楚，再开始写实现。

这份草图只解决一件事：

- 让`模块构筑型幸存者`在后续加武器参数、改流程效果、换平衡数值时，仍然能保持清楚、好改、好让 AI 接手。

## 1. 总体分层

推荐把项目拆成 4 层：

```text
静态配置层 (Data)
    ↓
运行状态层 (Runtime State)
    ↓
战斗结算层 (Combat Resolution)
    ↓
表现展示层 (Presentation)
```

### 各层职责

- `静态配置层`：存默认数值、模块定义、升级定义、敌人定义
- `运行状态层`：存当前局内血量、经验、已选模块、当前 build
- `战斗结算层`：把 build 和战斗事件转换成实际结果
- `表现展示层`：显示 UI、特效、飘字、动画、音效

### 关键原则

- 配置不存运行中的变化
- 运行状态不写回配置
- UI 不参与规则计算
- 子弹不自己解释模块
- build 的真相来源只能有一个

## 2. 主调用链

建议把局内流程固定成一条清楚的链路：

```text
玩家选择升级
→ upgrade_manager
→ build_state
→ module_applier
→ shot_profile
→ weapon_controller
→ projectile_controller
→ hit_resolver
→ health / status / VFX
```

### 这条链路的意义

- `upgrade_manager` 只负责升级入口和候选
- `build_state` 只负责保存当前模块组合
- `module_applier` 只负责把模块结算成武器行为
- `weapon_controller` 只负责开火
- `projectile_controller` 只负责飞行和命中触发
- `hit_resolver` 只负责命中结果的规则结算

这样以后新增参数时，只要能塞回这条链路，就属于“好加”。

## 3. 战斗阶段草图

把所有会改变流程的参数，限制在固定阶段上。

```text
before_fire
    ↓
on_spawn_projectile
    ↓
on_hit
    ↓
on_critical_hit
    ↓
on_kill
    ↓
on_expire
```

### 这样做的好处

- 新效果不是自己发明流程，而是挂在既定阶段上
- 暴击、击杀、命中、生成、结束，都有明确插口
- 后续增加“暴击分裂”“命中爆炸”“击杀返还弹药”时，不需要重写主循环

### 例子

- `暴击时分裂子弹` → 挂到 `on_critical_hit`
- `命中后爆炸` → 挂到 `on_hit`
- `击杀后返还一发` → 挂到 `on_kill`

## 4. 数据草图

### 4.1 静态数据

建议全部用 `Resource` 作为正式游戏数据。

```text
BaseWeaponData
ModuleData
UpgradeOptionData
EnemyData
```

### 4.2 运行时数据

运行时对象负责保存本局变化。

```text
BuildState
ShotProfile
PlayerRunState
EnemyRuntimeState
```

### 4.3 数据边界

- `BaseWeaponData`：基础伤害、冷却、弹速等默认值
- `ModuleData`：模块类型、描述、能改什么
- `BuildState`：当前选了什么模块
- `ShotProfile`：结算后的实际武器行为

### 关键要求

- 静态数据只描述“默认”
- `BuildState` 只保存“当前选择”
- `ShotProfile` 只保存“这次开火会发生什么”

## 5. 模块系统草图

当前模块系统不要做成万能系统，而要做成`有限槽位 + 有限阶段 + 有限效果`。

### 角色形态边界

角色形态和手持武器只提供基础武器母题，不拥有攻击规则。

推荐边界：

- `CharacterData`：保存基础属性、初始模块和开局构筑倾向。
- `BuildState`：保存当前局内模块选择，是 build 的唯一真相来源。
- `ModuleApplier`：把角色修正、基础武器和模块结算成 `ShotProfile`。
- `表现层`：把结算后的攻击包装成符合角色武器母题的动画、子弹和特效。

例如长枪角色可以把 `三连发` 表现为连续枪影，把 `爆炸` 表现为枪尖震爆，但它们仍然走同一套 `fire_mode` 和 `payload` 语义。不要因为角色拿了长枪，就在角色脚本、动画脚本或子弹脚本里新建一套长枪攻击规则。

### 推荐结构

```text
武器
├─ fire_mode 槽位
└─ payload 槽位
```

### 职责解释

- `fire_mode`：只改发射形式
- `payload`：只改命中效果

### 为什么这样更好加

- 每个槽位只改一个维度
- 模块组合容易理解
- 后期平衡调整范围可控
- AI 不容易把规则写散

## 6. 改流程参数怎么接

如果以后要加“暴击会改变流程”这类参数，建议不要直接改主循环，而是把它们接到阶段效果里。

### 推荐方式

```text
参数
→ 影响某个阶段
→ 触发某个效果
→ 结算到统一结果对象
```

### 例子

- `暴击率`：影响 `on_critical_hit`
- `穿透`：影响 `on_hit`
- `爆炸半径`：影响 `on_hit`
- `击杀回弹`：影响 `on_kill`

### 不推荐方式

- 新增一个完全不同的攻击流程
- 让每个模块自己改主循环
- 让 UI、子弹、敌人各算各的结果

## 7. 文件草图

建议核心文件职责先固定。

```text
build_state.gd
module_applier.gd
weapon_controller.gd
projectile_controller.gd
hit_resolver.gd
xp_manager.gd
upgrade_manager.gd
hud_controller.gd
```

### 责任分配

- `build_state.gd`：当前 build 的唯一来源
- `module_applier.gd`：把模块结算成 `ShotProfile`
- `weapon_controller.gd`：开火节奏和发射
- `projectile_controller.gd`：飞行、生命周期、命中触发
- `hit_resolver.gd`：伤害、暴击、穿透、击杀等规则
- `xp_manager.gd`：经验和升级触发
- `upgrade_manager.gd`：升级选项生成和应用
- `hud_controller.gd`：只显示状态

## 8. AI 协作草图

AI 适合做：

- 生成单个脚本的样板代码
- 按明确字段创建 `Resource`
- 帮忙补重复 UI
- 在明确报错后修局部问题

AI 不适合做：

- 一次性设计整套通用框架
- 自己新增一堆 Manager
- 自由发明未来扩展层

### 给 AI 的正确任务粒度

- “写一个 `ModuleData` 资源类”
- “把 `build_state` 改成唯一真相来源”
- “让 `module_applier` 只输出 `ShotProfile`”

不要直接丢给 AI：

- “帮我设计一个无限扩展的模块化战斗系统”

## 9. 中文对照术语

下面是后面常用的中英对照，方便你看文档时快速对应：

- `Data`：静态配置层
- `Runtime State`：运行状态层
- `Combat Resolution`：战斗结算层
- `Presentation`：表现展示层
- `Build State`：当前构筑状态
- `Shot Profile`：射击结果配置
- `Weapon Controller`：武器控制器
- `Projectile Controller`：子弹控制器
- `Hit Resolver`：命中结算器
- `Upgrade Manager`：升级管理器
- `Module Applier`：模块结算器

## 10. 当前结论

这份架构草图的核心不是“把系统做大”，而是把`变化点`固定住。

只要下面三件事稳定，后面就好加：

- `build_state` 只有一个
- `shot_profile` 只有一个统一出口
- 改流程的参数只能挂在固定阶段上

如果这三条守住，后面加暴击率、暴击分裂、命中爆炸、击杀返还、连锁效果，都会明显更容易。
