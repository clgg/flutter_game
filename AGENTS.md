# AGENTS.md

> 根目录规则入口。详细方案以 `doc/ideas/` 下的设计文档为准，本文件只保留开发时必须先看的短索引和硬性约束。

## 1. 项目定位

- 目标形态：Flutter App 内的 `Flutter + Flame` 割草类小游戏。
- 核心玩法：虚拟摇杆移动、敌人追踪、自动射击、经验拾取、升级三选一、暂停与结算。
- 承载方式：Flutter 页面中嵌入 Flame `GameWidget`，不优先使用 WebView/H5/JSBridge。
- 第一版原则：先做可运行闭环，再逐步替换正式素材和远程配置。

## 2. 必读文档

- 技术设计：`doc/ideas/割草类小游戏_Flutter_Flame技术设计.md`
- 阶段计划：`doc/ideas/割草类小游戏_Flutter_Flame逐步开发计划.md`
- 素材规范：`doc/ideas/割草类小游戏_角色敌人武器素材设计规范.md`
- 大型架构：`doc/architecture/大型项目架构设计.md`
- 多语言架构：`doc/architecture/多语言架构设计.md`
- 海外登录设计：`doc/architecture/海外登录页面设计.md`
- ODT 闪屏动画：`doc/architecture/ODT闪屏动画设计.md`
- Google Play 发版检查：`doc/release/Google Play 发版政策检查清单.md`
- 开发环境记录：`doc/environment/开发环境记录.md`

修改玩法、架构、资源目录或远程配置前，先查对应设计文档；如果文档与代码冲突，以当前代码事实为准，并在变更中同步修正文档。

## 3. 技术栈索引

- Flutter：页面、路由、HUD、弹窗、暂停层、结算层。
- Flame：game loop、Component、碰撞、输入、动画、图片缓存、音效缓存。
- Dart：核心玩法逻辑、配置模型、运行时状态、系统调度。
- `shared_preferences`：适合本地设置、最高分、上次有效配置缓存。
- `flame_audio`：仅在需要音效时引入；第一版可以先不接。
- 多语言：使用 Flutter 官方 `gen_l10n`、`flutter_localizations`、`intl` 和 ARB；通用文案集中在 `app_i18n` package。
- 远程 JSON 配置：用于敌人、波次、技能数值、活动开关；不要让配置承载复杂代码逻辑。

新增依赖前先确认是否已有 Flutter/Flame 能力能满足；第一版不要引入复杂物理引擎、第三方 ECS、自研渲染层或骨骼动画运行时。

## 4. 推荐目录

当前工程采用 App 壳 + packages 拆分：

```text
lib/
  main.dart
  app/
packages/
  app_core/
  app_i18n/
  app_splash/
  app_auth/
  grass_game_domain/
  grass_game_data/
  grass_game_runtime/
  grass_game_ui/
```

根 App 只负责入口、路由、主题和依赖装配；游戏模型、数据、运行时和 UI 都放在对应 package 中。App 路由统一放在 `lib/app/router/app_router.dart`，使用 `go_router`，不要在页面内私自维护平行路由表。启动首屏走 `/splash`，闪屏动画完成后进入海外登录或首页。

资源建议：

```text
assets/game/grass_game/
  images/
  audio/
  atlas/
```

更完整的 package 职责、依赖方向和拆包策略见 `doc/architecture/大型项目架构设计.md`。

只给小游戏使用的资源放业务目录；跨模块复用的资源再抽公共资源层。不要把 PSD、Aseprite 源文件、临时大图或未确认授权的网络图片直接放进工程资源。

## 5. 架构边界

- Flame 只负责游戏世界：玩家、敌人、子弹、掉落物、技能效果、碰撞、刷怪、运行时数值。
- Flutter Widget 只负责 UI：HUD、升级三选一、暂停、结算、按钮、弹窗、路由。
- `GameController` 作为 Flutter 与 Flame 的通信边界，避免 Widget 直接操作大量 Component。
- 高频更新逻辑放在 Flame `update(dt)` 或 system 内，不放在 Flutter `setState` 循环里。
- 升级、暂停、结算等低频状态由 Game 通知 Flutter Overlay，再由用户选择回写 Game。
- 不新增平行路由层、网络层、缓存层或平台 Channel；确实需要时先说明复用失败的原因。

## 6. SOLID 约束

- S 单一职责：Component 表达实体，System 处理规则，Widget 呈现 UI，Repository 获取数据。
- O 开闭原则：新增武器、敌人、技能优先扩展配置和独立类，不修改既有大分支。
- L 里氏替换：抽象接口的实现必须保持相同行为契约，例如技能效果、武器发射器、配置源。
- I 接口隔离：不要做巨型 `GameService`；按配置、存档、埋点、奖励、音效拆小接口。
- D 依赖倒置：玩法核心依赖抽象配置源/事件上报接口，不直接依赖具体 HTTP、缓存或平台实现。

落地要求：类和文件保持短小；公共抽象必须解决真实重复或扩展点，不为了“看起来架构完整”提前抽象。

## 7. 网络请求与远程配置

当前项目没有既有网络层。后续接远程配置时遵守：

- 统一封装 `GameConfigRepository`，页面或 Game 不直接发 HTTP。
- 网络实现可用项目既有网络能力；如果没有，再选择 `dio` 或 `package:http`，并集中在 data/repository 层。
- 请求返回 DTO 先转换为领域配置模型，再进入游戏运行时。
- 必须有默认本地配置；远程失败、JSON 缺字段或版本不兼容时不能阻塞进入游戏。
- 缓存上一次有效配置，记录配置版本号，启动时优先保证可玩。
- 远程配置只控制数值、波次、技能池、权重和开关；新增机制、复杂 AI、奖励发放规则不要只靠 JSON 动态解释。
- 不要在 Flame 高频 `update(dt)` 中触发网络请求、磁盘 IO 或埋点上报。

建议数据流：

```text
GameConfigRepository
  -> RemoteDataSource / LocalCacheDataSource
  -> DTO
  -> GameBalance / EnemyConfig / WaveConfig / SkillConfig
  -> GrassSurvivorGame
```

## 8. 开发规范

- 按阶段交付：每次只完成一个可验收闭环，避免玩法、资源、路由、结算、网络同时混改。
- MVP 先用圆形、方块、纯色线条等临时素材；手感和性能稳定后再接正式图片。
- 所有移动、冷却、生成、碰撞计算必须基于 `dt`，避免帧率影响玩法。
- 同屏实体变多后优先使用对象池、空间分区、批量查询，避免 O(n²) 碰撞扫描失控。
- 伤害、拾取等高频事件本地聚合；埋点在开始、升级选择、暂停、结算等关键节点上报。
- Widget 中避免堆叠复杂业务逻辑；复杂 UI 状态抽到独立 controller/state。
- 面向用户的 UI 文案必须走多语言资源；`domain`、`runtime`、`data` 不持有 `BuildContext` 或本地化生成类。
- 当前只做海外版本；登录入口以 Google Play、Apple、Facebook、Email 允许列表为准。
- ODT 闪屏只允许本地动画和本地状态读取；动画期间不得请求权限、发网络请求或上报埋点。
- 新增 public API、配置字段、资源命名时保持向后兼容，避免破坏已有存档或远程配置。
- 代码提交前处理 analyzer 警告，不用 `ignore` 掩盖可修复问题。

## 9. 命名与资源

- Dart 文件使用 `snake_case.dart`，类名使用 `UpperCamelCase`。
- Component 以 `XxxComponent` 命名，System 以 `XxxSystem` 命名，配置以 `XxxConfig` 命名。
- 图片和音效资源使用小写、下划线、带语义前缀，例如 `hero_idle_01.png`、`enemy_fast_walk_01.png`。
- spritesheet、atlas、单帧图分目录管理，正式接入后同步更新 `pubspec.yaml` assets。
- 使用 AI 或素材库资源前必须确认授权、风格一致、透明背景和尺寸规范。

## 10. 验收命令

常规检查：

```bash
flutter pub get
flutter analyze
flutter test
```

涉及真机手感、性能、音效、资源加载、生命周期暂停恢复时，必须在模拟器或真机运行验证，并在结论中说明验证环境。

Google Play 上架前还必须按 `doc/release/Google Play 发版政策检查清单.md` 完成发布、隐私、账号、内容分级、广告、支付和 SDK 检查。

## 11. 变更前检查

- 是否读过相关 `doc/ideas/` 文档。
- 是否保持 Flutter UI 与 Flame 世界边界清晰。
- 是否遵守 SOLID，尤其是单一职责和依赖倒置。
- 是否有默认配置、失败兜底和本地缓存策略。
- 是否避免在高频 update 中做网络、磁盘或重型对象创建。
- 是否保留每阶段可运行、可回退、可验收。
