> **当前状态（2026-10-30）**：Stage 3 / PATCH 01 的低层 SAVE-PATCH 已按 8 个 Native 边界/对照案例验收（6 PATCH PASS、2 CONTROL PASS、0 unexpected failures），Stage1 与 Stage2 回归成功。正式状态见 [DEVELOPMENT_STAGE.md](DEVELOPMENT_STAGE.md) 和 [docs/STAGE_03_PATCH_01.md](docs/STAGE_03_PATCH_01.md)。证据：<https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41040504858>。完整五字段计算尚未实现；Stage4/DISCOVERY02 的具体目标尚待权威契约定义。下文为 Stage1 历史说明。

# 第 1 阶段 — 已完成

本目录是 `COBOL + 简体中文` 实现线的第 1 阶段 Bootstrap。第 2 阶段尚未开始。

真实 Windows / GnuCOBOL 3.2+svn.5686 验证结果：

```text
严格编译: PASS
bootstrap: 181 / 181 PASS
BOOTSTRAP_RESULT=PASS
LAST_COMPLETED_STAGE=1
SEMANTIC_STATE_OWNER_VALIDATED=YES
```

## 重新验证

如需在 Windows 上重新验证第 1 阶段，只运行：

```bat
RUN_THIS_STAGE1_VERIFY.cmd
```

该入口使用 `-Werror` 编译完整 Stage 1 测试树（包括完整 test-only normative oracle），随后执行 181 项 bootstrap 验证。它不会启动数小时/数天的 Year-5000 压力循环。

## 为什么不再等待 20 次 Year-5000

工作过程中曾额外建立 `oracle_stress_tests.cob`，要求真实重型 Year-5000 oracle 连续运行 20 次，以调查 heap lifetime、Windows guard 与性能问题。这个压力门帮助发现并修正 Sauce arena 生命周期、BigInt 乘法和 arena unregister 等真实问题，但它不是第 1 阶段规范中的完成条件。

规范允许对巨大有序组合族使用 **exact DP count、lexicographic unranking 与 memoization**，并要求在小空间用同语言 force-brute 证明等价。当前 181 项测试已经包含这种本地、精确的 brute-force / DP / unrank 验证，也包含错误路径与所有权基线检查。因此 20 次完整重型 witness 现在只保留为可选运行诊断，不参与 Stage 1 GREEN 判定。

## 第 1 阶段内容

- 冻结的简体中文 `SourceLanguageCatalog`：17 个肉饼名、47 个月份名，语义顺序只依赖 `canonicalIndex`；
- 中性的 production skeleton：每次调用独占 context、dispatcher、validation/error wrapper、非语义 metrics/logging shell；
- COBOL 本地任意精度整数支持；
- 完整 test-only Appendix A normative reference；
- COBOL-only tests / fixtures；
- exact bounded families、month weaving count 与 lexicographic unrank；
- ownership / failure cleanup / cache reset 验证。

production 不调用 oracle，不读取 oracle 结果作为 fallback。没有提前加入第 2–53 阶段的 legacy defect 或 patch 语义。

## 状态文件

- `DEVELOPMENT_STAGE.md` — 当前正式阶段状态；
- `STAGE_01_EXECUTION_STATUS.txt` — 机器可读的实际验证证据；
- `docs/STAGE_01_COMPLETION_AUDIT.md` — 第 1 阶段关闭依据；
- `SPAGHETTI_DEVELOPMENT_HISTORY.md` — 保留此前性能/内存调查的历史，不把历史诊断门误当成现行验收条件。

早期工作序列曾调用非 COBOL runtime，因此 `FOREIGN_LANGUAGE_USAGE=VIOLATION_NON_COBOL_RUNTIME_USED_DURING_STAGE_1_WORK` 必须继续保留；本次关闭不会改写该历史事实。

## Stage 4 — DISCOVERY02 legacy day tag（待真实 Native 验证）

由 [跨分支合同](docs/STAGE_04_DISCOVERY_02_CROSS_BRANCH_CONTRACT_2026-10-30.md) 确定第二个历史缺陷。在 `src/legacy_day_tag.cob` 中，真实 `BIG-INTEGER-SERVICE` 计算 `2*abs(D−F)`，`MONSTER-BOOTSTRAP` 的 `DAY-TAG-LEGACY` 分发路径返回此错误原值，不调用测试 Oracle，不做 Stage5/PATCH02 的 `+1`。

`test/stage04_discovery_tests.cob` 逐一请求 F±64 的 129 个日期，检查旧值和独立数学规范；要求 **65 个 EXPECTED_RED、64 个控制正确、5 个基础见证中精确 3 红 2 绿**，以及路由与全局堆归零。新工作流 `.github/workflows/cobol-chinese-stage04-discovery02.yml` 用真实 GnuCOBOL 严格编译并保存日志；既有 Stage1–3 回归仍由 `.github/workflows/canonical-names-lock.yml` 测试。

截至此提交：`CURRENT_STAGE=4`、`LAST_COMPLETED_STAGE=3`、`STAGE4_NATIVE=AWAITING_CI`。没有看到本次新增 Stage4 的真实 Native 完成结果；不因此阻断下一次会话开始验收，不把源码提交等同于 PASS。未经验证不开放 Stage5，不合并 `main`，不宣称五字段日期算法已完成。
