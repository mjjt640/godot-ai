# 地图架构说明

## 核心入口

- 新增地图时，优先新建一个 `MapData` 资源，不要复制 `GameRoot`、`ArenaVisual` 或 `ArenaBounds`。
- `MapData` 是地图选择入口，负责组合一张地图需要的 `RunTuningData` 和 `ArenaVisualData`。
- `RunManager.map_data` 是当前局使用哪张地图的唯一选择点；后续做地图选择 UI 时，只切换这个资源。

## 资源职责

- `MapData`：地图 ID、显示名、运行参数资源、视觉资源。
- `MapTileLibraryData`：地图地砖、贴花、霓虹细节和危险区视觉素材库；后续 `TileSet` 或 `TileMapLayer` 应从这里对应分类取素材，不要散写路径。
- `RunTuningData`：地图尺寸、世界边界厚度、刷怪半径、最小刷怪距离、刷怪边距等运行参数。
- `ArenaVisualData`：地面颜色、网格、霓虹线、边界视觉、障碍物、危险区等表现和地图布置数据。
- `ObstacleData`：单个硬碰撞障碍的位置、尺寸、颜色。
- `HazardData`：单个危险区的位置、尺寸、颜色、伤害和触发间隔。

## 场景职责

- `ArenaBounds` 只负责世界边界碰撞，必须继续读取 `RunTuningData`，不要在地图视觉层里重复创建边界墙。
- `ArenaVisual` 只负责地图分层入口和资源驱动的地图表现，不要把刷怪、升级、武器或 UI 逻辑放进去。
- `GroundBaseLayer`、`GroundDetailLayer`、`NeonDetailLayer` 用于地面、纹理细节和霓虹占位；以后接入瓦片时优先扩展这些层。
- `PropVisualLayer` 只放障碍物视觉；`WorldCollisionLayer` 只放障碍物 `StaticBody2D`。
- `HazardVisualLayer` 只放危险区视觉；`HazardAreaLayer` 只放危险区 `Area2D`。
- `BoundaryVisualLayer` 只画边界视觉，不承担碰撞。

## 新增地图流程

1. 在 `resources/runs/` 下新建该地图的 `RunTuningData`。
2. 在 `resources/world/visuals/` 或后续地图子目录下新建该地图的 `ArenaVisualData`。
3. 在 `resources/maps/` 下新建该地图的 `MapTileLibraryData`，把地砖、贴花、霓虹细节、危险区视觉按用途分类。
4. 在 `resources/maps/` 下新建该地图的 `MapData`，引用上面三个资源。
5. 如需临时测试，把 `RunManager.map_data` 指向新 `MapData`。
6. 跑 `project_sanity_check.gd` 和地图相关 headless 检查。

## 注意事项

- 不要为每张地图新增一套平行的 `ArenaVisual` 脚本或场景。
- 不要把地图尺寸、刷怪距离、边界厚度写死在脚本里。
- 不要把硬碰撞障碍放进视觉层，也不要把危险区做成阻挡移动的碰撞体。
- 割草玩法的地图优先保证大范围跑图空间，必要时复用地块组，不要把第一张地图做成复杂地形。
- 地图障碍要保留玩家拉扯空间，不要形成复杂迷宫或封闭死胡同。
- 霓虹视觉应服务可读性：地图整体比角色和敌人更暗，青色和电粉只做克制高亮。
- 地砖素材进入项目后，先进入 `MapTileLibraryData` 分类；正式铺图时再创建 `TileSet`/`TileMapLayer`，不要在 `ArenaVisual` 或运行脚本里直接硬编码素材路径。
- 第一张地图优先使用少量基础地砖循环铺大面积区域，再叠加低密度贴花和少量霓虹/危险区视觉，避免复杂地形影响割草跑图。
