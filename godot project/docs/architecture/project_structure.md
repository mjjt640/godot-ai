# 项目结构规范

## 目标

这份文档用于约束当前 Godot 幸存者项目的目录组织方式，避免随着玩法和内容扩展，脚本、场景、资源和文档继续混杂。

目标不是一次性重构成理想结构，而是给后续迁移和新增内容提供统一落点。

## 组织原则

1. 主目录按职责分层，只保留 `scenes`、`scripts`、`resources`、`art`、`audio`、`docs` 这类顶层入口。
2. `scripts` 按玩法域分目录，不再使用语义过宽的兜底目录。
3. `scenes` 只放可实例化场景，不放系统级纯逻辑脚本。
4. `resources` 只放资源数据和资源脚本，保持数值与配置资源驱动。
5. `docs` 只放长期有效的项目文档，不混入一次性执行过程产物。
6. 同一层目录只保留一套分类规则，避免一半按对象、一半按系统。

## 顶层目录约定

- `art/`
  - 美术源素材、导出贴图、风格参考图。
- `audio/`
  - 音频源文件和导出音频。
- `docs/`
  - 架构、玩法、内容和美术规范文档。
- `resources/`
  - `.tres` 资源、资源脚本和资源池定义。
- `scenes/`
  - 可实例化运行场景。
- `scripts/`
  - 运行时逻辑脚本、配置和开发校验脚本。

## scripts 目录规范

### 固定目录

- `scripts/build/`
  - 武器构筑状态、模块组合和 `ShotProfile` 构建逻辑。
- `scripts/combat/`
  - 投射物、命中结算、武器控制。
- `scripts/config/`
  - 碰撞层、全局常量等共享配置。
- `scripts/dev/`
  - 轻量校验脚本和项目检查入口，不参与正式运行时流程。
- `scripts/enemies/`
  - 敌人控制器、敌人表现、敌人行为执行器、敌人技能执行器。
- `scripts/player/`
  - 玩家控制和玩家局内状态逻辑。
- `scripts/progression/`
  - 经验、升级、掉落拾取等成长流程逻辑。
- `scripts/run/`
  - 单局编排、刷怪、目标事件、局内状态流转。
- `scripts/ui/`
  - HUD、升级面板、卡片展示、集中游戏文案入口。
- `scripts/world/`
  - 边界、障碍、地图视觉和场地相关运行逻辑。

### 放置规则

1. 以后不再新增 `scripts/game/`。
2. 敌人本体和敌人行为不归 `run/`，统一归 `enemies/`。
3. 地图或场地视觉、边界、障碍和危险区逻辑统一归 `world/`。
4. 共享逻辑只有在明确跨域复用时才进入 `config/` 或未来的 `shared/`，不能把“临时找不到位置”的脚本塞进去。

## scenes 目录规范

- `scenes/main/`
  - 主入口场景，例如 `game_root.tscn`。
- `scenes/player/`
  - 玩家场景。
- `scenes/enemies/`
  - 敌人场景。
- `scenes/weapons/`
  - 投射物和武器相关场景。
- `scenes/pickups/`
  - 掉落物场景。
- `scenes/ui/`
  - HUD、升级面板、卡片等 UI 场景。
- `scenes/world/`
  - 地图边界和场地视觉场景。

新增场景时，优先按运行实体归类，不再额外扩展语义重复的目录。

## resources 目录规范

- `resources/characters/`
  - 角色数据、角色池。
- `resources/combat/`
  - 战斗反馈和表现参数。
- `resources/enemies/`
  - 敌人定义、技能、技能池、模板、视觉资源定义。
- `resources/maps/`
  - 地图数据和地图入口资源。
- `resources/modules/`
  - 武器模块定义。
- `resources/runs/`
  - 单局调参和目标事件定义。
- `resources/upgrades/`
  - 升级选项、升级池和升级品质权重。
- `resources/waves/`
  - 波次表和刷怪条目。
- `resources/weapons/`
  - 基础武器数据。
- `resources/world/`
  - 场地视觉、障碍、危险区等世界资源。

### 子目录要求

1. 文件数量持续增长的目录必须尽早分子目录，不允许长期扁平堆放。
2. `resources/upgrades/` 按 `pools/`、`stats/`、`general/`、`modules/`、`economy/` 拆分。
3. `resources/modules/` 按 `fire_modes/` 和 `payloads/` 拆分。
4. `resources/world/` 按 `visuals/`、`hazards/`、`obstacles/` 拆分。

## docs 目录规范

后续文档统一按长期用途归档：

- `docs/architecture/`
  - 项目结构、运行链路、地图架构。
- `docs/gameplay/`
  - 构筑、升级、刷怪、局内流程等玩法规则。
- `docs/content/`
  - 角色、敌人、关卡内容规范。
- `docs/art/`
  - 美术风格、素材规范、提示词文档。

现有一次性方案稿可以暂留，但新增正式规范优先放到上述目录或顶层过渡文档中。

## 命名规范

1. 场景文件使用稳定实体名，例如 `enemy_basic.tscn`、`player.tscn`。
2. 控制器脚本用 `*_controller.gd`。
3. 资源脚本用 `*_data.gd`、`*_pool_data.gd`、`*_profile.gd` 这类明确后缀。
4. 运行编排脚本优先使用语义明确的名词，例如 `run_manager.gd`、`spawn_manager.gd`。
5. 不再新增 `manager.gd`、`system.gd`、`helper.gd` 这类脱离语境的泛名文件。

## 当前迁移顺序

为了降低风险，目录整理分阶段执行：

1. 先拆 `scripts/game/`，把单局编排迁到 `scripts/run/`，把敌人逻辑迁到 `scripts/enemies/`。
2. 再把 `scenes/world/`、`scripts/world/`、`resources/world/` 统一到同一命名口径并补齐子目录。
3. 再持续整理 `resources/upgrades/`、`resources/modules/` 的新增资源，保持分组不回退成扁平结构。
4. 最后整理 `docs/` 的长期归档结构。

## 已完成阶段

截至当前版本，下面这些整理已经落地：

1. `scripts/game/` 已拆分为 `scripts/run/` 与 `scripts/enemies/`。
2. `scenes/environment/`、`scripts/environment/`、`resources/environment/` 已统一迁到 `world/`。
3. `resources/modules/` 已拆为 `fire_modes/` 与 `payloads/`。
4. `resources/upgrades/` 已拆为 `pools/`、`modules/`、`general/`、`economy/`。
5. `docs/` 已整理为 `architecture/`、`content/`、`art/` 等长期目录。
6. `scripts/dev/project_sanity_check.gd` 已从单文件大检查拆为多文件调度结构：
   - `sanity_context.gd`
   - `world_map_checks.gd`
   - `progression_checks.gd`
   - `enemy_combat_checks.gd`
   - `ui_run_profile_checks.gd`
7. `scripts/run/run_manager.gd` 已完成第一轮收敛，目标事件、升级暂停流程、掉落与镜头反馈已下沉到独立控制器：
   - `run_objective_controller.gd`
   - `run_level_flow_controller.gd`
   - `run_combat_reward_controller.gd`

## 当前状态

当前目录层面的主重构已经基本闭环，后续重点不再是继续搬目录，而是控制运行时代码复杂度。

现阶段的工作重点应转为：

1. 保持新增资源继续遵守现有分组，不回退到扁平结构。
2. 保持新增检查优先进入对应的 `scripts/dev/*_checks.gd` 文件，而不是继续堆回入口。
3. 继续收敛仍然偏胖的运行时代码入口，优先关注：
   - `scripts/run/run_manager.gd`
   - `scripts/enemies/enemy_controller.gd`
   - `scripts/world/arena_visual.gd`

## 后续优先级

推荐后续按这个顺序继续：

1. 继续瘦 `enemy_controller.gd`
   - 优先把导航、状态切换、Boss 技能状态等进一步下沉。
2. 继续瘦 `arena_visual.gd`
   - 优先把障碍/危险区重建和绘制层逻辑继续拆小。
3. 如果需要扩玩法，再进入 `run_manager.gd` 第二轮整理
   - 例如把地图初始化和 HUD 绑定也进一步抽到更细的编排层。

## 当前目标结构草案

```text
godot project/
├─ docs/
│  ├─ architecture/
│  ├─ gameplay/
│  ├─ content/
│  └─ art/
├─ resources/
│  ├─ characters/
│  ├─ combat/
│  ├─ enemies/
│  ├─ maps/
│  ├─ modules/
│  ├─ runs/
│  ├─ upgrades/
│  ├─ waves/
│  ├─ weapons/
│  └─ world/
├─ scenes/
│  ├─ main/
│  ├─ player/
│  ├─ enemies/
│  ├─ weapons/
│  ├─ pickups/
│  ├─ ui/
│  └─ world/
└─ scripts/
   ├─ build/
   ├─ combat/
   ├─ config/
   ├─ dev/
   ├─ enemies/
   ├─ player/
   ├─ progression/
   ├─ run/
   ├─ ui/
   └─ world/
```
