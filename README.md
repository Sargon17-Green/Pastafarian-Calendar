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
