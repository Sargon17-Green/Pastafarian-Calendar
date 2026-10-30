# 第 4 阶段 — DISCOVERY 02：错误的基准日编号（跨分支确认）

PROJECT_ID: `PC-BRANCH-COBOL-SIMPLIFIED-CHINESE`  
确认日期：2026-10-30  
状态：`STAGE4_CONTRACT_RESOLVED_IMPLEMENTATION_NOT_STARTED`  
前一阶段：Stage3/PATCH01 已通过真实 GnuCOBOL Native，`LAST_COMPLETED_STAGE=3`。

## 来源和技术选择

这是系列第 **2 个历史缺陷**，接在 Stage2 的 SAVE 零余数缺陷和 Stage3/PATCH01 修复之后。不是 COBOL 分支的任意新功能。

交叉核对的独立分支和记录：
- `TypeScript+मराठी/SPAGHETTI_DEVELOPMENT_HISTORY.md`：Stage4/DISCOVERY02，五个 Foundation witness，3 个红灯和 2 个对照，实际 production handler。
- `C++&Latina/SPAGHETTI_DEVELOPMENT_HISTORY.md`：Gradus4/Detectio02，旧的 `oldDayTag` 只保留绝对距离。
- `PHP+Bahasa-Melayu/SPAGHETTI_DEVELOPMENT_HISTORY.md`：Stage4，64+1+64 大范围的 65 个差异、64 个匹配。
- `Gleam+Esperanto/SPAGHETTI_DEVELOPMENT_HISTORY.md`：Stadio4，精确的 3 RED/2 控制。
- Rust 独立测试参考 `Rust+Azərbaycan-dili/tests/support/normative_oracle.rs` 函数 `day_count`，直接实现规范，不依赖 COBOL production。

## 明确定义和不允许的修补

设 `F = -15055671` 为 FOUNDATION_DAY，日数为任意精度有符号整数。规范（正整数编号）：
```text
dayCount(d) = 2*(F-d)       for d < F
dayCount(d) = 2*(d-F)+1     for d >= F
```
历史错误函数（必须保留至 Stage5）：
```text
oldDayTag(d) = 2*abs(d-F)
```
Stage4 真实生产运行路径要先检查两日 BigInt 操作数和 caller-owned 输出，再通过已有 `MONSTER-BOOTSTRAP` 分发器的独立 `DAY-TAG-LEGACY` action 计算两份 `oldDayTag`，不得在 production 调用 test-only Oracle。旧 SAVE 入口和 Stage3 `SAVE-PATCH` 均不可更改；产出错误原始值，记录受调用者拥有的 trace/metrics，拒绝不完整输入并避免泄漏。

`oldDayTag`、dispatch action、测试入口必须为新增功能，不能把它们回填进 Stage1–3 历史；也不可提前执行 Stage5/PATCH02 的 `+1`。这两个相邻阶段的职责必须分离。

## 严格红灯和对照（精确数值）

| 输入日 | 旧结果 | 规范 | 判定 |
| --- | ---: | ---: | --- |
| F−2 | 4 | 4 | CONTROL |
| F−1 | 2 | 2 | CONTROL |
| F | 0 | 1 | EXPECTED_RED |
| F+1 | 2 | 3 | EXPECTED_RED |
| F+2 | 4 | 5 | EXPECTED_RED |

**结果必须恰好 3 个 EXPECTED_RED + 2 个 CONTROL**。任何未声明失败，或者少于 3 个 RED，都不是 Stage4 的 PASS；仅靠预期失败的退出码 1 不能判定通过。测试包装器只接受这三个确切差异的签名，并要求 native stdout/stderr 和 exit 证据。

额外验证：两个输入分别计算（`calculationDay` 和 `targetDay`），覆盖 F±64 或更广；数值变化与 `2*abs` 精确一致，输入不被修改、调用隔离；采用 BigInt 避免 `int` 减法溢出；独立的 test-only Oracle 负责判定而不复用生产计算代码。

## 实施顺序 / 解除的阻碍

1. 本文即为缺失的**权威技术合同**，依据多个已验证的同一系列分支和 Rust 测试参考；不需用户再次选择缺陷。
2. 在 COBOL 分支添加独立 legacy day tag 及 dispatcher 路由、测试、Native workflow；Stage4 执行时设 `CURRENT_STAGE=4`、`LAST_COMPLETED_STAGE=3`。
3. 本轮只解决规范障碍：**合同已成立，不能声称 Stage4 implementation/Native PASS**。下一轮可直接继续实现，不必等待已经 queued 的 GitHub Actions。
4. 所有 Stage1 181、Stage2 3 RED + 1 CONTROL、Stage3 6 PATCH + 2 CONTROL 的现有回归必须保持；新的 Native GnuCOBOL 和 Names Lock 仅在真实跑过后才可标记 PASS。
5. Stage5/PATCH02 以后独立修正 Foundation 和后侧的 `+1`，同时保持旧函数原样；不提前创建完整五组件日期，不修改 `main`。

**接受本合同不是 Stage4 已完成的证明。**
