# 角色资产规格

## 目标

本规格用于把当前 `Q 版奇幻竞技场 + 粗黑描边 + 高饱和角色` 风格的角色与怪物图，整理成 Godot 项目内可接入、可动画、可批量扩展的资源。当前风格参考源为 `C:\Users\admin\Desktop\C1827`，不再沿用旧赛博、霓虹、金属实验区素材方向。

首版目标：

- 主角支持分件拼装与少量补帧
- 普通怪优先使用逐帧动画
- 精英怪可先逐帧，后续再决定是否拆分件
- 不改现有玩法与数值脚本，只替换 `Visual` 占位显示

## 目录规范

建议在 `art/` 下建立以下结构：

```text
art/
  characters/
    player/
      source/
      parts/
      exports/
      previews/
    enemies/
      cyclops_bug/
        source/
        frames/
        exports/
      elite_brute/
        source/
        frames/
        exports/
  weapons/
  vfx/
```

说明：

- `source/` 放原始高清图、可编辑源文件、白底定风格图
- `parts/` 放主角拆分件 PNG
- `frames/` 放怪物动作帧 PNG
- `exports/` 放供 Godot 直接引用的最终资源
- `previews/` 放人工检查图，不直接进游戏

## 画布与尺寸

源图尺寸建议：

- 主角单体源图：`1024x1024`
- 小怪单体源图：`1024x1024`
- 精英怪单体源图：`1536x1536`

游戏内推荐显示尺寸：

- 主角站立高度：`160-220 px`
- 小怪主体宽高：`110-180 px`
- 精英怪主体宽高：`220-360 px`

规则：

- 所有导出 PNG 都使用透明背景
- 图像四周保留 `48-96 px` 安全边距，避免粗黑轮廓、武器和夸张动作被裁掉
- 同类怪物的锚点高度尽量统一，避免进场后脚底漂浮

## 主角拆分规范

主角首版按以下部件拆分：

- `head`
- `hair_back`
- `hair_front`
- `torso`
- `arm_upper_l`
- `arm_upper_r`
- `arm_lower_l`
- `arm_lower_r`
- `hand_l`
- `hand_r`
- `leg_l`
- `leg_r`
- `weapon`
- `outline_fx` 可选，仅用于独立黑色轮廓或受击高亮
- `shadow_blob`

要求：

- 部件单独导出时保持原始对位
- 所有部件以同一中心点或统一脚底参考线对齐
- 不要把受击高亮或轮廓特效完全烤死在主体层里；需要特效时优先保留 `outline_fx` 独立层
- 武器必须独立，便于换枪与瞄准

## 与攻击模块关系

主角模型和手持武器只定义基础武器母题，不直接定义攻击规则。

接入规则：

- 武器外观用于解释角色的攻击身份，例如长枪、枪械、法杖或能量核心。
- 局内攻击变化仍然由模块系统提供，不为每个角色单独制作一套攻击规则。
- 不要求每个模块都导出一把新武器模型；优先通过子弹贴图、命中特效、枪口/武器尖端特效和短攻击动画表现差异。
- 长枪角色的 `三连发` 可以表现为连续枪影，`散射` 可以表现为扇形枪芒，`爆炸` 可以表现为枪尖震爆。
- 如果某个模块需要角色侧表现，优先新增轻量 VFX 或动画覆盖，不把模块规则写进角色视觉脚本。

## 怪物动画规范

普通怪首版逐帧资源：

- `idle`：`4-6` 帧
- `move`：`6-8` 帧
- `attack`：`4-6` 帧
- `hit`：`2-3` 帧
- `death`：`6-8` 帧

精英怪首版逐帧资源：

- `idle`：`4-6` 帧
- `move`：`6-8` 帧
- `attack`：`6-8` 帧
- `hit`：`2-3` 帧
- `death`：`8-10` 帧

规则：

- 首版只做单朝向即可，必要时用 `flip_h` 扩展
- 粗黑轮廓必须在全部帧中保持宽度与节奏一致
- 怪物体内高亮只能做辅助，不要盖过外轮廓和主体识别色

## 命名规范

主角拆分件：

```text
player_head.png
player_hair_front.png
player_torso.png
player_weapon_pistol.png
player_outline_fx.png
```

怪物逐帧：

```text
enemy_cyclops_bug_idle_00.png
enemy_cyclops_bug_idle_01.png
enemy_cyclops_bug_move_00.png
enemy_cyclops_bug_attack_00.png
enemy_cyclops_bug_death_00.png
```

精英怪：

```text
enemy_elite_brute_idle_00.png
enemy_elite_brute_attack_00.png
```

## 导出规范

- 文件格式统一 `PNG`
- 颜色空间统一 `sRGB`
- 禁止导出 JPG
- 导出前检查透明边缘，不允许白底残边
- 导出后检查粗黑轮廓、武器、盾牌和夸张动作没有被裁切
- 主角和怪物都保留 `shadow_blob` 独立资源

## 美术接入优先级

第一批就做这些：

1. 主角：`head/torso/arms/legs/weapon/shadow_blob`
2. 小怪一只：`idle/move/hit/death`
3. 精英怪一只：`idle/move/attack/death`
4. 枪口火花与命中特效独立资源

## 与当前项目的对应关系

- `scenes/player/player.tscn` 现有 `Visual` 是程序化占位，需要替换成 C1827 风格的 Spine 或逐帧视觉节点
- `scenes/enemies/enemy_*.tscn` 现有 `Visual` 是程序化占位，需要替换成 C1827 的 `m100xx/m200xx` Spine 或逐帧动画
- 碰撞体继续独立保留，不跟美术图尺寸直接绑定
- 数值仍然从 `resources/characters/*.tres` 与 `resources/enemies/*.tres` 读取
