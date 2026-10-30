# Stage 6 / DISCOVERY 03 — 历史距离与包含端点的实际工作日数

PROJECT_ID: `PC-BRANCH-COBOL-SIMPLIFIED-CHINESE`
前置门：Stage5 / PATCH02，经 GnuCOBOL 六个工作成功验收；
源 SHA `8f6d608b7f0637ced0478df651afcc50471558a9`；
验收记录 `3873ee8f56034a00cc7335a6417779ed33cc4824`。
本次为 Stage6 实现与 CI 申请；不能在 CI 未完成时宣布 Native PASS。

## 选择与出处
现有生产 `PATCHED-DAY-TAG` 计算正确的日标签。
下一层历史假设：旧距离使用两个正确标签之差的绝对值，
而不是两个日期的包含端点的时间间隔。
参考历史（不移植算法/fixture）：
`C++&Latina/SPAGHETTI_DEVELOPMENT_HISTORY.md` Gradus6 Detectio03。
另一个分支的旧距离定义不同，因此此处明确选择“标签差”路线，
不能将其他分支的红灯数量移植为此分支的实测结果。

设 `F=-15055671`：
```
tag(d) = 2*(F-d)          if d < F
tag(d) = 2*(d-F)+1        if d >= F
legacyDistance(c,t) = abs(tag(t)-tag(c))
normativeDistance(c,t) = abs(t-c)+1
```
生产的 `LEGACY-DISTANCE` 独立调用现有 `PATCHED-DAY-TAG`
各计算两个日期的标签，再通过本地 `BIG-INTEGER-SERVICE` 取差和绝对值。
`MONSTER-DISTANCE` 提供独立 `DISTANCE-LEGACY` 分发与状态边界。
不得调用 test-only oracle，不得提前实现 Stage7/PATCH03。
两个输入和输出分别由调用者持有，禁止覆盖非空结果，错误路径释放临时链。

## 固定的最小可复现见证（独立手算）
表中 `c,t` 均为相对于 F 的偏移量。只要未真正执行 Native，
这仅是数学预测，不是已观察到的运行缺陷。

| c | t | legacy | normative | expected |
|---:|---:|---:|---:|---|
|0|0|0|1|RED|
|1|3|4|3|RED|
|-3|-1|4|3|RED|
|-1|1|1|3|RED|
|-2|2|1|5|RED|
|0|1|2|2|CONTROL|
|-2|-1|2|2|CONTROL|
|1|2|2|2|CONTROL|

独立测试参考不调用标签生产算法，而用偏移量和
`abs(t-c)+1` 计算数学规范；对旧生产结果使用固定表值。
这使错误公式的实际运行与期望签名分开，避免因“预期失败”而接受未知错误。

## Native 验收门
- 真实 GnuCOBOL `-Werror` 编译并执行分发后的历史生产路径；
- exactly 5 expected RED, 3 matching CONTROL, 8 output-ownership rejections,
  0 unexpected failures, 全部 caller-owned 值释放后 heap live=0；
- 原有 Stage1–5 与 canonical names lock 保留；新运行不得把它们静默跳过；
- 不以仅有的退出码或已排队的运行推断通过；
- 本阶段不引入“加一”修补、完整五字段日期或主分支合并。

## 剩余边界工作
这八个见证只构成最小可重现的 Stage6 基线；
补充大数/反向输入/损坏状态测试后，才可认为边界覆盖完整。
任何意外输出、编译失败、heap 非零都须修复并重新取证。
