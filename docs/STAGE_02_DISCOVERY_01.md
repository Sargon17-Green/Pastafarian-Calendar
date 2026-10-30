# 第 2 阶段 — DISCOVERY 01：旧余数的预期红灯

## 授权与基线

2026-10-30 用户批准继续 Stage 2。起点是 COBOL+简体中文 分支
`f06bc22c0f27259158c5c7dc1f3bedfd4fbef173`；
Stage 1 的原有 181/181 bootstrap 验收不被改写。

## 故意保留的历史缺陷

设 `M=2^127-1=170141183460469231731687303715884105727`。

- 规范要求：`SAVE(x)=M` 当 `regularMod(x,M)=0`，否则等于该非零余数。
- Stage 2 的 `oldRemainder(x)` 故意只返回 `regularMod(x,M)`。
- 由 `MONSTER-BOOTSTRAP` 的 `OLD-REMAINDER` 分发，经
  `LEGACY-OLD-REMAINDER` 调用 production `BIG-INTEGER-SERVICE/MOD-EUCLID`。
- 输出放入 `LK-TARGET-DAY` 的调用者拥有 BigInt 记录；在此 action 中它是 *输出槽*，而不是日期参数。
  此 action 只是当前生产分发器的低层入口，**不是**完整五字段日历 API。
- oracle 模块不在执行链接中；没有调用测试 oracle，也没有 `savePatch`。
- 此阶段 *不修复* 缺陷；等到 Stage 3 PATCH 01 才考虑包装原函数。

## 必须通过的分支证据

| 输入 x | 旧值 (raw) | 规范 SAVE(x) | 预期 |
| --- | --- | --- | --- |
| M | 0 | M | EXPECTED_RED |
| 2M | 0 | M | EXPECTED_RED |
| 3M | 0 | M | EXPECTED_RED |
| M+1 | 1 | 1 | CONTROL_PASS |

测试须核实 production 入口返回
`DISCOVERY01:OLD-REMAINDER` 路由标记，
`EXPECTED_RED=3`、`CONTROL_PASS=1`、零意外失败和零活动 BigInt 块。
CI 必须使用 GnuCOBOL 严格编译，且 Stage 1 回归独立保持绿色。

## 仍有的边界

当前 `MONSTER-BOOTSTRAP` 仍未输出完整五字段日期，
所以这个测试只能证明 *实际 production 分发器通道* 的低层
`oldRemainder` 缺陷，不能声称已经在完整最终日历计算路径触发该缺陷。
将此记录保留为显式集成欠项，而不能通过只运行 oracle 来冒充完成五字段计算。

## 核验

GitHub Actions: `.github/workflows/canonical-names-lock.yml` (stage2-discovery-native job)
- JOB: `stage2-discovery-native`
- 标记: `RESULT=PASS_STAGE2_DISCOVERY_NATIVE`
- 初始状态: PENDING（禁止把静态设计或 commit 误称为原生 PASS）。

Stage 3 PATCH 01 在 Stage 2 证据检查完成前不得开始。
