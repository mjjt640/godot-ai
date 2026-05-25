# Godot 角色节点与动画结构方案

## 目标

在不改动现有玩法脚本主结构的前提下，为 `player.tscn` 与 `enemy_*.tscn` 建立可扩展的视觉层级。

现状：

- 玩家和敌人根节点都是 `CharacterBody2D`
- 已有 `CollisionShape2D`
- 已有控制器脚本
- 现有 `Visual` 仍是 `Polygon2D` 占位

首版原则：

- 保留根节点、碰撞、控制器脚本路径
- 仅替换视觉节点
- 玩家使用分件结构
- 怪物使用逐帧结构

## 玩家节点结构

建议把 `scenes/player/player.tscn` 调整为：

```text
Player (CharacterBody2D)
  CollisionShape2D
  VisualRoot (Node2D)
    Shadow (Sprite2D)
    BodyRoot (Node2D)
      LegL (Sprite2D)
      LegR (Sprite2D)
      Torso (Sprite2D)
      ArmUpperL (Sprite2D)
      ArmUpperR (Sprite2D)
      ArmLowerL (Sprite2D)
      ArmLowerR (Sprite2D)
      HandL (Sprite2D)
      HandR (Sprite2D)
      HeadRoot (Node2D)
        HairBack (Sprite2D)
        Head (Sprite2D)
        HairFront (Sprite2D)
      WeaponPivot (Node2D)
        Weapon (Sprite2D)
      OutlineFX (Sprite2D) 可选
  WeaponController (Node2D)
  Camera2D
```

说明：

- `VisualRoot` 只负责美术显示与受击缩放
- `BodyRoot` 负责整体角色本体
- `HeadRoot` 方便单独做朝向压缩、轻微抬头、受击点头
- `WeaponPivot` 负责枪口朝向和后坐
- `OutlineFX` 可以单独闪烁或受击增强

## 玩家动画职责

建议这样分工：

- `player_controller.gd`：移动、受击、死亡、通用状态
- 新增视觉脚本，例如 `scripts/player/player_visual_controller.gd`
- `WeaponController`：保留攻击逻辑，不承担角色身体动画

`player_visual_controller.gd` 建议负责：

- 待机摆动
- 跑步腿部摆动
- 武器瞄准角度
- 开火后坐
- 受击缩放与闪色
- 死亡淡出或压缩

## 玩家挂点规范

建议保留这些逻辑挂点：

- `WeaponPivot`：子弹出生方向参考
- `HeadRoot`：帽子、发饰、耳机等后续换装挂点
- `Torso`：胸口徽记或被动状态特效挂点
- `Shadow`：不参与颜色闪烁，只跟随缩放

## 敌人节点结构

普通怪建议：

```text
EnemySwarm (CharacterBody2D)
  CollisionShape2D
  VisualRoot (Node2D)
    Shadow (Sprite2D)
    Body (AnimatedSprite2D)
    OutlineFX (AnimatedSprite2D 或 Sprite2D) 可选
  HealthBar
```

精英怪建议：

```text
EnemyEliteBrute (CharacterBody2D)
  CollisionShape2D
  VisualRoot (Node2D)
    Shadow (Sprite2D)
    Body (AnimatedSprite2D)
    OutlineFX (AnimatedSprite2D 或 Sprite2D) 可选
    CoreFX (Sprite2D) 可选
  HealthBar
```

说明：

- 首版敌人不做复杂分件，先以 `AnimatedSprite2D` 快速落地
- `VisualRoot` 继续作为 `enemy_controller.gd` 中 `_visual` 的绑定目标
- 受击、死亡缩放统一作用在 `VisualRoot`

## 敌人动画映射

建议统一动画名：

- `idle`
- `move`
- `attack`
- `hit`
- `death`

如果首版没有完整攻击帧：

- `attack` 可先复用 `idle`
- `hit` 可先通过 `modulate + scale` 反馈补足

## 与现有脚本的兼容

当前脚本里：

- `player_controller.gd` 会查找 `Visual`
- `enemy_controller.gd` 也会查找 `_visual` 并做 `scale/modulate`

所以接入时建议：

- 把 `Visual` 节点名保留，或让 `VisualRoot` 命名为 `Visual`
- 这样无需先改控制器脚本，也能继承现有受击反馈

推荐实际命名：

```text
Player
  CollisionShape2D
  Visual
    Shadow
    BodyRoot
```

敌人同理：

```text
EnemySwarm
  CollisionShape2D
  Visual
    Shadow
    Body
```

## 排序与层级

建议：

- `Shadow.z_index = 0`
- `Body` 相关节点 `z_index = 1`
- `Weapon` 与 `OutlineFX` 根据需要在 `1-2`
- `HealthBar` 始终高于视觉主体

如果后续地图里加入遮挡层：

- 角色排序仍以根节点全局位置做 YSort 逻辑
- 视觉节点内部不要再做复杂 YSort

## 首版接入步骤

1. 在 `player.tscn` 中把 `Polygon2D Visual` 换成 `Node2D Visual`
2. 给 `Visual` 下挂主角分件节点
3. 保持 `WeaponController` 路径不变
4. 在一个敌人场景中先把 `Polygon2D Visual` 换成 `Node2D Visual`
5. 挂入 `Shadow + AnimatedSprite2D`
6. 复用现有 `enemy_controller.gd` 受击与死亡反馈

## 首版不做的事

- 不先做骨骼动画
- 不先做复杂换装系统
- 不先做八方向完整手绘动作
- 不把碰撞体跟贴图边缘强绑定

## 推荐后续脚本

当资源准备好后，可以新增：

- `scripts/player/player_visual_controller.gd`
- `scripts/enemies/enemy_visual_controller.gd`

职责只放视觉，不承接数值与战斗结算。
