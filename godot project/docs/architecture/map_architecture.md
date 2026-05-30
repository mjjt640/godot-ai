# 地图架构说明

## 核心入口

- 新增地图时，优先新建一个 `MapData` 资源，不要复制 `GameRoot`、`ArenaVisual` 或 `ArenaBounds`。
- `MapData` 是地图选择入口，负责组合一张地图需要的 `RunTuningData`、`ArenaVisualData`、`MapTileLibraryData` 和 `MapTileLayoutData`。
- `RunManager.map_data` 是当前局使用哪张地图的唯一选择点；后续做地图选择 UI 时，只切换这个资源。

## 资源职责

- `MapData`：地图 ID、显示名、运行参数资源、视觉资源。
- `MapTileLibraryData`：地砖、贴花、低饱和装饰、障碍物和危险区视觉素材库；后续 `TileSet` 或 `TileMapLayer` 应从这里对应分类取素材，不要散写路径。
- `MapTileLayoutData`：地图铺设规则，包括是否绘制重复地砖、tile 世界尺寸、分区 tile 索引、细节/贴花复用间隔、装饰色调和障碍物碰撞脚印比例。
- `RunTuningData`：地图尺寸、世界边界厚度、刷怪半径、最小刷怪距离、刷怪边距等运行参数。
- `ArenaVisualData`：地面颜色、低对比纹理、竞技场边界视觉、障碍物、危险区等表现和地图布置数据。
- `ObstacleData`：单个硬碰撞障碍的位置、尺寸、颜色。
- `HazardData`：单个危险区的位置、尺寸、颜色、伤害和触发间隔。

## 场景职责

- `ArenaBounds` 只负责世界边界碰撞，必须继续读取 `RunTuningData`，不要在地图视觉层里重复创建边界墙。
- `ArenaVisual` 只负责地图分层入口和资源驱动的地图表现，不要把刷怪、升级、武器或 UI 逻辑放进去。
- `GroundBaseLayer`、`GroundDetailLayer`、`NeonDetailLayer` 用于地面、纹理细节和历史高亮 tile；第一张地图在没有合适地砖素材时只保留低饱和基础底色。
- `PropVisualLayer` 只放无碰撞装饰；`ObstacleVisualLayer` 只放障碍物视觉；`WorldCollisionLayer` 只放障碍物 `StaticBody2D`。
- `HazardVisualLayer` 只放危险区视觉；`HazardAreaLayer` 只放危险区 `Area2D`。
- `BoundaryVisualLayer` 只画边界视觉，不承担碰撞。

## 新增地图流程

1. 在 `resources/runs/` 下新建该地图的 `RunTuningData`。
2. 在 `resources/world/visuals/` 或后续地图子目录下新建该地图的 `ArenaVisualData`。
3. 在 `resources/maps/` 下新建该地图的 `MapTileLibraryData`，把地砖、贴花、低饱和装饰、危险区视觉按用途分类。
4. 在 `resources/maps/` 下新建该地图的 `MapTileLayoutData`，配置地砖世界尺寸和复用密度。
5. 在 `resources/maps/` 下新建该地图的 `MapData`，引用上面四个资源。
6. 如需临时测试，把 `RunManager.map_data` 指向新 `MapData`。
7. 跑 `project_sanity_check.gd` 和地图相关 headless 检查。

## 注意事项

- 不要为每张地图新增一套平行的 `ArenaVisual` 脚本或场景。
- 不要把地图尺寸、刷怪距离、边界厚度写死在脚本里。
- 不要把硬碰撞障碍放进视觉层，也不要把危险区做成阻挡移动的碰撞体。
- 生成障碍物的硬碰撞只覆盖底部脚印，不能直接用整张障碍物贴图尺寸做碰撞体。
- 割草玩法的地图优先保证大范围跑图空间，必要时复用地块组，不要把第一张地图做成复杂地形。
- 地图障碍要保留玩家拉扯空间，不要形成复杂迷宫或封闭死胡同。
- 当前第一张地图风格为 Q 版破损古代竞技场；地图整体必须比角色和敌人更暗、更低饱和，避免赛博、霓虹、金属实验区语汇。
- 地图素材进入项目后，先进入 `MapTileLibraryData` 分类，再由 `MapTileLayoutData` 控制地砖分区和复用密度；不要在 `ArenaVisual` 或运行脚本里直接硬编码素材路径。
- 第一张地图不要接入风格不合适的 tile 素材；后续找到合适素材后，再按中心、通道、外环、四角破损区分区铺设。
- 第一张地图不要随机散放生成装饰或障碍；后续接入合适障碍物素材后，再按外环和四角人工分区布置。
