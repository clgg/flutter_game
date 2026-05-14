# Google Play 发版政策检查清单

> 目标：面向海外 Google Play 发布前使用。本文是工程执行清单，不替代 Google Play 官方政策；提交前仍以 Play Console 当前提示和官方政策页为准。

## 1. P0 阻断项

这些问题会直接导致无法上传、无法送审、被拒审或后续更新受阻。

### 1.1 发布包格式

- 正式发布使用 Android App Bundle。
- 构建命令优先使用：

```bash
flutter build appbundle --release
```

- 不使用 debug APK 或临时 APK 作为正式发布产物。
- 如果包体过大，优先评估 Play Asset Delivery，不直接把所有大资源塞进首包。

官方参考：[Android App Bundle](https://support.google.com/googleplay/android-developer/answer/9844279?hl=en-EN)

### 1.2 targetSdkVersion

- 新应用和更新必须满足 Google Play 当前 target API 要求。
- 2026-05 当前官方页面要求：自 2025-08-31 起，新应用和更新必须 target Android 15 / API 35 或更高。
- 发版前必须检查最终 AAB 内的 `targetSdkVersion`，不要只看源码默认值。
- 当前工程使用 `targetSdk = flutter.targetSdkVersion`，发版前建议明确锁定到满足 Play 要求的版本。

官方参考：[Target API level requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)

### 1.3 16 KB page size

- 自 2025-11-01 起，提交到 Google Play 且面向 Android 15 / API 35+ 设备的新应用和更新必须支持 16 KB page size。
- 如果 App 或第三方 SDK 含 `.so`，需要检查 native libraries 的 ELF alignment。
- Flutter、登录、广告、分析、支付、游戏引擎等 SDK 更新后都要重新检查。
- 发版前用 Android Studio APK Analyzer 或官方检查方式确认。

官方参考：[Support 16 KB page sizes](https://developer.android.com/guide/practices/page-sizes)

### 1.4 Release 签名

- 正式包必须使用 release keystore。
- 必须接入 Play App Signing。
- 禁止用 debug keystore 发布正式版本。
- 当前工程 `release` 仍使用 `signingConfigs.debug`，正式上架前必须修改。

官方参考：[Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756?hl=en)

### 1.5 包名和应用身份

- `applicationId` 一旦上架就不要再当临时字段处理。
- App 名、包名、开发者名、隐私政策里的 App 或开发者名称必须一致。
- 不使用 `flutter_game`、`demo`、`test` 等临时展示名上架。
- 版本号必须递增，`versionCode` 每次上传都要大于线上版本。

官方参考：[Create and set up your app](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en)

## 2. P0 隐私与账号

### 2.1 隐私政策

- 必须提供公开可访问 URL。
- URL 不能要求登录，不能做地域封锁，不能是 PDF。
- 隐私政策必须覆盖 App 收集、使用、共享、保存和删除用户数据的方式。
- 隐私政策中必须出现 App 名或开发者名。
- App 内也应提供 Privacy Policy 入口。

官方参考：[Prepare your app for review](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en)

### 2.2 Data safety

- Play Console 的 Data safety 必须与真实代码、SDK 行为一致。
- 每次新增 SDK 都要重新确认它收集的数据、用途、共享方和权限。
- 登录 SDK、广告 SDK、分析 SDK、崩溃 SDK 都要纳入 Data safety。
- 如果声明不收集数据，代码和 SDK 也必须真的不收集。
- 所有个人和敏感数据传输必须使用 HTTPS 等现代加密方式。

官方参考：[Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en-EN)、[User Data](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en)

### 2.3 账号删除

- 如果 App 内允许创建账号或登录账号，必须提供账号删除能力。
- 删除入口需要在 App 内容易找到。
- 还必须提供一个网页入口，让已卸载 App 的用户也能请求删除账号和相关数据。
- 临时冻结、停用账号不等同于删除账号。
- 如果因安全、反欺诈、法规需要保留部分数据，必须在隐私政策里说明。

官方参考：[Account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en)

### 2.4 审核账号和访问说明

- 如果登录后才能体验核心功能，必须在 Play Console 的 App access 中提供审核账号或详细访问说明。
- Google、Facebook 等第三方登录也要给审核团队可用的测试方式。
- 如果有一次性验证码、多因素验证、地区限制、服务端白名单，需要在说明中写清楚。
- 不要让审核人员停在登录页或空页面。

官方参考：[App access requirements](https://support.google.com/googleplay/android-developer/answer/15748846?hl=en-EN)

## 3. P1 游戏内容与年龄

### 3.1 内容分级

- 必须完成 IARC 内容分级问卷。
- 问卷要准确反映游戏内暴力、恐怖、赌博暗示、抽奖、聊天、用户生成内容、广告等内容。
- 游戏内容或功能变化影响问卷答案时，需要重新提交分级问卷。
- 未分级 App 可能被移除。

官方参考：[Content Ratings](https://support.google.com/googleplay/android-developer/answer/9898843?hl=en)

### 3.2 目标年龄

- Play Console 需要声明目标年龄段。
- 如果目标用户包含儿童，会触发 Families Policy。
- 如果产品不是儿童向，不要随意选择儿童年龄段。
- 如果包含儿童，广告 SDK、数据收集、外链和隐私政策都要满足更严格要求。

官方参考：[Families Policies](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en)

### 3.3 用户生成内容和 AI 内容

- 如果后续加入排行榜昵称、聊天、头像、评论、UGC 地图等，需要提供举报、屏蔽、审核和内容规则。
- 如果加入生成式 AI，需要提供用户举报入口，并防止生成违规、欺诈、骚扰、儿童伤害等内容。
- 当前游戏第一版不建议引入 UGC 或生成式 AI，避免提前扩大审核面。

官方参考：[User Generated Content](https://support.google.com/googleplay/android-developer/answer/9876937?hl=en)、[AI-Generated Content](https://support.google.com/googleplay/android-developer/answer/13985936?hl=en)

## 4. P1 广告与变现

### 4.1 广告声明

- 如果 App 内展示广告，Play Console 必须声明 Contains ads。
- 广告内容成熟度不能高于游戏内容分级。
- 插屏广告不能连续弹出，不能在每个点击后重复阻断用户。
- 广告不能遮挡核心操作，不能伪装成系统按钮或游戏奖励。

官方参考：[Ads policy](https://support.google.com/googleplay/android-developer/answer/9857753?hl=en)

### 4.2 Advertising ID

- 广告用途必须使用 Android Advertising ID，不能用 IMEI、MAC、SSAID 等持久设备标识替代。
- 不得把 Advertising ID 和持久设备标识关联用于广告或分析。
- 用户重置或删除 Advertising ID 后，不能把新旧 ID 重新关联。
- Advertising ID 的使用必须在隐私政策中披露。

官方参考：[Advertising ID](https://support.google.com/googleplay/android-developer/answer/6048248?hl=en-EN)

### 4.3 Google Play Billing

- 游戏内数字商品必须走 Google Play Billing。
- 包括虚拟货币、角色、皮肤、额外生命、额外时间、去广告、订阅、功能解锁等。
- App 内不能引导用户去外部支付渠道购买数字商品，除非符合 Google Play 特定地区和计划的例外规则。
- 虚拟货币只能在当前 App 或游戏内使用。
- 抽卡、宝箱、随机虚拟物品必须在购买前清晰披露概率。

官方参考：[Payments policy](https://support.google.com/googleplay/android-developer/answer/9858738?hl=en)、[Payments overview](https://support.google.com/googleplay/android-developer/answer/10281818?hl=en)

## 5. P1 权限与 SDK

### 5.1 权限最小化

- 不申请当前核心功能不需要的权限。
- 避免高风险权限，例如 SMS、Call Log、后台定位、`MANAGE_EXTERNAL_STORAGE`、`QUERY_ALL_PACKAGES`。
- 每个权限都必须能对应到商店页描述中的核心功能。
- 运行时权限必须在用户触发相关功能时再请求。

官方参考：[Permissions and APIs that Access Sensitive Information](https://support.google.com/googleplay/android-developer/answer/9888170?hl=en)

### 5.2 第三方 SDK 责任

- App 对集成的第三方 SDK 行为负责。
- 接入前确认 SDK 收集哪些数据、请求哪些权限、是否共享数据、是否满足 16 KB page size。
- 广告、分析、登录、崩溃、支付 SDK 都要纳入审核清单。
- SDK 默认收集超出用户预期的数据时，需要显著披露和合法同意。

官方参考：[SDK Requirements](https://support.google.com/googleplay/android-developer/answer/13323374?hl=en)

## 6. P1 商店页与发布流程

### 6.1 商店页

- App 名、短描述、完整描述必须准确，不堆关键词。
- 截图和视频必须展示真实功能，不展示未实现玩法或误导性奖励。
- 描述中如提到付费功能、广告、内购、订阅，需要和真实体验一致。
- 联系邮箱必须可用。
- 隐私政策 URL 必须填写。

官方参考：[Set up your app dashboard](https://support.google.com/googleplay/android-developer/answer/9859454?hl=en-EN)

### 6.2 测试轨道

- 发生产前先走 internal testing 或 closed testing。
- 2023-11-13 后创建的个人开发者账号，上生产前通常需要 closed test：至少 12 个测试者连续参与 14 天，再申请生产权限。
- 测试期间收集崩溃、卡顿、登录失败、支付失败、广告异常和设备兼容问题。

官方参考：[Testing requirements for new personal accounts](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)、[Set up testing](https://support.google.com/googleplay/android-developer/answer/9845334?hl=en)

## 7. 当前工程专项检查

### 7.1 已知现状

- 当前主 `AndroidManifest.xml` 没有敏感权限。
- 当前还没有真实广告、支付、Google 登录、Facebook 登录 SDK。
- 当前登录仍是假数据阶段。
- 当前 `release` 使用 debug 签名，正式发布前必须修正。
- 当前包名和应用展示名仍像临时值，正式建 Play Console 应用前必须确认。

### 7.2 发版前必须补齐

- 固定正式 `applicationId`。
- 固定正式 App 名、图标、启动图和商店页品牌资产。
- 配置 release keystore 和 Play App Signing。
- 构建 release AAB。
- 检查最终 AAB 的 targetSdkVersion。
- 检查 16 KB page size。
- 准备隐私政策 URL。
- 填写 Data safety。
- 填写 App access 审核账号或说明。
- 完成内容分级和目标年龄声明。
- 如接广告，填写 Contains ads 并更新 Data safety。
- 如接内购，接入 Google Play Billing 并补充支付文案、概率披露和退款说明。

## 8. 发版前命令

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

如新增 native SDK 或 release 构建配置变更，再补充：

```bash
flutter build apk --release
```

并用 Android Studio / Play Console Pre-review checks 检查：

- targetSdkVersion。
- native libraries 16 KB alignment。
- 签名证书。
- 包体大小。
- 权限列表。
- 设备兼容性。

