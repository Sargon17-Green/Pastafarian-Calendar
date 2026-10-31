# Stage8 / DISCOVERY04 — 调用者持有 BigInt 的输入别名与输出所有权调查

PROJECT_ID: `PC-BRANCH-COBOL-SIMPLIFIED-CHINESE`
日期：2026-10-31
状态：CONTRACT_ONLY / 未运行 Stage8 Native；缺陷尚未复现，不得标记 expected-red。

## 前置证据
Stage7 / PATCH03 通过真实 GnuCOBOL Native，run 41180791202，SHA `357d76ce4defcef6ada1d6e4571c0117aacc56fe`，8/8 jobs success；job 124477619835 的计数为 5 PATCH、3 CONTROL、8 output guards、4 BigInt boundary、3 invalid rejects、0 unexpected。旧 LEGACY 路径没有修改。Stage8 严禁抄录其他语言分支算法或测试样例。

## 选择的工程问题
生产路由 `MONSTER-DISTANCE` 接受 caller-owned BigInt currentDay、targetDay、result。Stage7 验证了占用输出拒绝覆盖，却没有专门展示 currentDay 与 targetDay 指向**同一个非空 BigInt 链**时的行为。调查这一交叠是否安全；不预设有 bug，不制造虚假的 legacy 缺陷。

输入：`DISTANCE-PATCH` 或 `DISTANCE-LEGACY`、两个合法 BigInt（允许同一个输入链的指针别名）、一个空输出 BigInt、状态和消息。
独立 oracle（只存在测试中）：
`normative(c,t)=abs(t-c)+1`；同一值在同一地址时应为 1。
对于别名情形，两个输入均保持 sign、chunk count、head/tail 指针、数值不变；释放结果一次、输入链一次，随后 `HEAP-LIVE=0`。若 API 明确禁止别名，则应在生产修改前先文档化拒绝状态，不可静默修改规范。

## 有界发现矩阵（8 个案例，独立于生产算法）
1. 同一实例 c=t=0，patched distance=1。
2. 同一非零实例 c=t=+10^63，patched distance=1。
3. 同一非零实例 c=t=-10^63，patched distance=1。
4. 两个不同实例 c=-2、t=2，patched distance=5（对照）。
5. 非空 result=17、独立有效输入：拒绝覆盖 status=175，哨兵未变化。
6. result 与非空 currentDay 共用结构（使用明确的调用者别名），要求拒绝覆盖 175、输入不变。
7. result 与非空 targetDay 共用结构，要求拒绝覆盖 175、输入不变。
8. 同一实例但 sign=2（非法），要求 status=22、空输出，无分配泄漏。

仅合法输入的对照值可先预测；真正的 output aliasing 需要真实调用与内存安全性记录。不得宣称已有 expected-red 见证。大数 `10^63` 由十进制文本精确构建，不能用浮点或截断整数。

## 执行与接受门
- 在隔离的 `test/stage08_discovery_tests.cob` 进行有界 Native 诊断；不得将测试 oracle 引入生产。
- 用 GnuCOBOL 3.x 严格 -Werror 编译，执行 8 案例、核对独立数学结果、状态码、输入不变性和每个案例的所有权。
- 不对已由 Stage7 验证的 SHA 再次启动重复 CI；下一次代码变更应更新现有 canonical workflow 中专门 Stage8 job，保存 log/artifact。
- 逐个输出观察结果：`STAGE8_CASES_RUN`、`STAGE8_PASS`、`STAGE8_REPRODUCED_FAILURES`、`STAGE8_UNEXPECTED_FAILURES`、`STAGE8_HEAP_LIVE_POST_RELEASE`，不以 PASS 取代红灯证据。
- 如果实际出现可复现偏差：保存最小输入、旧输出、oracle 输出、程序返回及日志，再决定是否将其归类 expected-red、给出独立 PATCH04 计划；否则记录 `NO_DEFECT_REPRODUCED` 并继续探索其他独立候选。
- 仅当 verify、Stage1–7 回归及 Stage8 Native completed/log 全部证实，才能判定 Stage8 的验收；现在 `NOT_RUN`。不得修改 main、合并或宣称完整五字段集成。

## 2026-10-31 实施记录（非验收）
专用 COBOL 测试文件 `test/stage08_discovery_tests.cob` 增加八个别名/对照/非法状态见证；canonical workflow 增加有界、-Werror、输出持久化的 Stage8 native job。提交代码不等于完成原生测试。仅根据 completed/log 判定 Stage8 是否真的复现缺陷或通过；若失败须保留日志而非预置 expected-red。

## Stage8 Native 实际结果与范围限制（2026-10-31）
- Verified branch `COBOL+简体中文`, source SHA `eaeb149dd63aa32750098e9d333dcd12f451f57a`; GitHub Actions run [41187120199](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41187120199) `completed/success`, 9/9 jobs SUCCESS.
- Stage8 job `124496187049` 在 GnuCOBOL 3.1.2.0 的严格 `-Werror` 下成功编译并执行；`STAGE8_CASES_RUN=8`, `STAGE8_PASS=8`, `STAGE8_REPRODUCED_FAILURES=0`, `STAGE8_UNEXPECTED_FAILURES=0`, `STAGE8_HEAP_LIVE_POST_RELEASE=0`, `STAGE8_NATIVE_GATE=PASS`.
- 原始诊断 artifact: [13037037636](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41187120199/artifacts/13037037636).
- 结论：`ACCEPTED_NO_DEFECT_REPRODUCED_IN_EIGHT_WITNESSES`。这不是“所有可能别名组合均安全”的证明；没有 expected-red，也没有 PATCH04 的证据。保留历史失败 run 41184236629（仅测试 harness 编译报错）和 Stage8 证据区分。
- 未触及生产代码、main 或五字段日历集成。后续 Stage9 / DISCOVERY05 单独调查连续调用与输入复用，使用独立测试 oracle。
