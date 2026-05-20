# 割草类小游戏_固定网格 Spritesheet 读取规范

> 目标：所有人物、怪兽动画都按固定尺寸、固定行列读取。生成阶段保证每一格完整，不再依赖透明边界自动裁切、智能识别或二次合成。

## 1. 核心原则

- 运行时只按固定网格读取：`x = column * cellWidth`，`y = row * cellHeight`。
- 素材必须在生成阶段严格放进自己的格子内，头发、角、武器、翅膀、尾巴、脚都不能越出格子。
- 不合格图片直接重做或重新生成，不通过脚本硬裁。
- 脚本只允许做尺寸转换、固定格复制、验收报告，不允许按透明像素重新裁切主体。
- 正式素材不使用几何图形代替角色或怪物动画；缺图时用 GPT/imagegen 按固定网格重新生成。
- 行走图不叠加半透明方向、不保留攻击残影、不保留重叠地面阴影；源图有跨格残片时必须在生成阶段清干净。

## 2. 标准运行时尺寸

当前人物和怪兽行走动画优先使用轻量规格：

```text
sheet width  = 256
sheet height = 1024
columns      = 2
rows         = 8
cell width   = 128
cell height  = 128
```

含义：8 行对应 8 个方向；每行 2 帧，分别表示左脚在前、右脚在前。这个规格比 `8 行 x 6 列` 更省内存，也更容易让 GPT 或美术稳定对齐。怪兽也使用同一规格。

固定读取公式：

```text
frameX = column * 128
frameY = row * 128
frameW = 128
frameH = 128
```

示例：

```text
第 1 行第 1 帧：x=0,   y=0,   w=128, h=128
第 1 行第 2 帧：x=128, y=0,   w=128, h=128
第 2 行第 1 帧：x=0,   y=128, w=128, h=128
```

如果后续确实需要更顺滑动画，可以扩展为 `8 行 x 4 列` 或 `8 行 x 6 列`，但必须仍然保持 `128x128` 单格和同样的行顺序。MVP 不默认使用 6 列。

## 3. 8 方向行顺序

所有 `*_8dir_sheet.png` 都使用同一行顺序：

```text
row 0: front/down
row 1: down_right
row 2: right
row 3: up_right
row 4: back/up
row 5: up_left
row 6: left
row 7: down_left
```

每行 2 帧。帧顺序从左到右播放：第 1 帧左脚在前，第 2 帧右脚在前。

## 4. 格内安全区

每个 `128x128` 单元格内建议：

```text
顶部至少留白：12px
底部至少留白：4px
左右至少留白：6px
脚底线建议：y=116-122
身体中心建议：x=64
```

允许武器、角、翅膀占用安全区，但不能越过格子边界。

## 5. 文件命名

人物：

```text
assets/game/grass_game/images/player/player_<id>_walk_8dir_sheet.png
```

当前阶段人物只接行走动画。攻击动作和攻击效果先不接入、不入库；后续需要时再单独制定同样固定网格的攻击规格。

怪兽：

```text
assets/game/grass_game/images/guaishou/guaishou_<id>_walk_sheet_runtime_128.png
assets/game/grass_game/images/guaishou/guaishou_<id>_walk_8dir_sheet.png
```

Boss 不再维护独立图片目录。Boss 外观从 `guaishou` 池随机选择并运行时强化。

## 6. 旧 4 方向素材兼容

旧人物源图常见为：

```text
1536x1024
6 columns x 4 rows
cell 256x256
row 0: front/down
row 1: back/up
row 2: left
row 3: right
```

兼容转换只能做整格缩放，不允许裁切主体：

```text
sourceX = column * 256
sourceY = sourceRow * 256
sourceW = 256
sourceH = 256

targetX = targetColumn * 128
targetY = targetRow * 128
targetW = 128
targetH = 128
```

当前人物转换只取旧 6 帧中的第 1 帧和第 4 帧作为两步循环：

```text
target column 0 <- source column 0
target column 1 <- source column 3
```

如果旧图没有真实斜方向，转换出的斜方向只能作为临时占位，不能视为正式 8 方向素材。正式素材必须重新生成 8 个方向。

## 7. GPT/imagegen 生成提示词

用于补齐或重做人物：

```text
Generate a transparent PNG spritesheet for a Flutter + Flame top-down survivor game character.
Canvas size must be exactly 256x1024 pixels.
The sheet must be a fixed grid: 2 columns and 8 rows, each cell exactly 128x128 pixels.
Do not draw grid lines.
Each character frame must stay fully inside its own 128x128 cell.
No hair, head, weapon, hand, foot, cape, tail, horn, glow, shadow, or effect may cross cell boundaries.
Do not add cast shadows, overlapping shadows, ghosted duplicate silhouettes, attack arcs, hit flashes, or ground effects to walk frames.
Leave at least 12 pixels transparent padding at the top, at least 6 pixels at the left and right of every cell, and at least 4 pixels at the bottom.
Keep the character scale consistent across all frames.
Keep the feet aligned around y=116 to y=122 inside each cell.
Use true transparent background.

Rows:
row 0 front/down walk, 2 frames: left foot forward, right foot forward.
row 0 front/down walk, 2 frames: left foot forward, right foot forward.
row 1 down_right walk, 2 frames: left foot forward, right foot forward.
row 2 right walk, 2 frames: left foot forward, right foot forward.
row 3 up_right walk, 2 frames: left foot forward, right foot forward.
row 4 back/up walk, 2 frames: left foot forward, right foot forward.
row 5 up_left walk, 2 frames: left foot forward, right foot forward.
row 6 left walk, 2 frames: left foot forward, right foot forward.
row 7 down_left walk, 2 frames: left foot forward, right foot forward.

Use the attached old character spritesheet only as identity/style reference.
Do not copy its bad cropping or spacing.
Output one complete spritesheet only.
```

当前阶段不要生成攻击效果 sheet。攻击动作如后续需要，必须和行走动画一样使用固定网格，并单独入库。

## 8. 验收清单

- 图片尺寸必须正好是 `256x1024`。
- 必须是透明 PNG。
- 必须正好 `2列 x 8行`，单格 `128x128`。
- 每个格子都要有内容。
- 每个格子的四周边缘不能有主体贴边或越界残片。
- 每个格子不能有重叠阴影、半透明叠影、攻击弧线或邻格残片。
- 8 个方向必须是独立方向；旧 4 方向复制出来的斜方向只能标记为临时占位。
- 游戏接入时只按固定 `row/column/cellSize` 读取，不再自动裁切。

## 9. 当前工具

把旧人物 `1536x1024 / 6x4 / 256x256` 行走图转换成 `256x1024 / 2x8 / 128x128` 运行时固定网格：

```powershell
powershell -ExecutionPolicy Bypass -File tools/grass_game_build_player_fixed_grid.ps1
```

验收固定网格尺寸、空格和贴边风险：

```powershell
powershell -ExecutionPolicy Bypass -File tools/grass_game_validate_fixed_grid.ps1 -Path assets/game/grass_game/images/player -Filter 'player_*_walk_8dir_sheet.png'
powershell -ExecutionPolicy Bypass -File tools/grass_game_validate_fixed_grid.ps1 -Path assets/game/grass_game/images/guaishou -Filter 'guaishou_*_walk_sheet_runtime_128.png'
```

把已经修复过的怪兽 `768x1024 / 6x8 / 128x128` 行走图转换成 `256x1024 / 2x8 / 128x128` 运行时固定网格：

```powershell
powershell -ExecutionPolicy Bypass -File tools/grass_game_build_guaishou_fixed_grid.ps1
```

这些工具都不能生成正式缺失美术方向。它们只负责固定坐标转换和检查；如果需要真实 8 方向或攻击动作，必须按第 7 节提示词重新生成或由美术重做。当前阶段不生成攻击效果 sheet。
