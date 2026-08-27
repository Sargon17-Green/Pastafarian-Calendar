# 第 1 阶段 handoff

## 交付性质

这是当前环境能够完成的最大第 1 阶段交付包。源树已经包含第 1 阶段要求的生产骨架、冻结的 `SourceLanguageCatalog`、COBOL 任意精度整数基础设施、独立测试 oracle、fixture、测试和文档，并且没有加入第 2 至第 53 阶段的未来补丁代码。

但这不是可以诚实标记为绿色完成的第 1 阶段：当前环境没有 `cobc/cobcrun`，测试无法实际编译运行；测试 oracle 还有已记录的堆所有权限制；而且本工作序列早先已经调用过非 COBOL 运行时，因此不满足严格的 `foreign_language_runtime_called=NO` 来源条件。

## 建议的 commit title

建立 COBOL 与简体中文第 1 阶段引导基线

## 建议的 commit body

从零建立 COBOL + 简体中文实现线的第 1 阶段基线。加入冻结且按 canonicalIndex 排序的 SourceLanguageCatalog、中性的生产上下文/调度/验证/错误/指标外壳、COBOL 本地任意精度整数服务、从内嵌 Appendix A 独立重写的完整测试 oracle，以及整数、基础计数、目录、选择和小型组合族的测试。

静态审查修正了任意精度九位块解析、乘法符号、碗更新完整 s 平方、排列秩边界、COBOL CONTINUE 误用、编织 DP 索引和按引用传递字段表示等问题。没有读取、移植、运行、散列或比较其他实现，也没有加入未来历史补丁专用代码。

当前环境没有 GnuCOBOL，因此本包尚未完成真实编译/运行验证。测试 oracle 仍有已记录的堆所有权限制。此外，本工作序列早先发生过非 COBOL 运行时调用，所以若严格执行来源条件，本序列不能被认证为正式完成的第 1 阶段。

## GitHub 说明

本包可以作为当前静态工作成果保存或上传，但不要把 `LAST_COMPLETED_STAGE` 改为 `1`，也不要声称测试已经通过。应先在具有 GnuCOBOL 的环境中运行 `./handoff/build_and_test.sh` 并处理任何编译或测试失败。

若要求完全满足任务中的语言来源约束，还必须在只允许 COBOL 执行任务代码的受控环境中从零重新执行第 1 阶段；当前序列中已经发生的非 COBOL 运行时调用不能通过后续修改消除。

## 文件清单

完整清单见 `handoff/FILES.txt`。

## 本地测试命令

```text
./handoff/build_and_test.sh
```

脚本等价于以下纯构建/运行流程：

```text
cobc -std=default -free -x -o bootstrap-tests \
  src/big_integer.cob \
  src/source_language_catalog.cob \
  src/monster_bootstrap.cob \
  test/oracle/oracle_constants.cob \
  test/oracle/oracle_bigint.cob \
  test/oracle/normative_basic.cob \
  test/oracle/normative_bigint_primitives.cob \
  test/oracle/normative_sauce.cob \
  test/oracle/normative_selection.cob \
  test/oracle/normative_families.cob \
  test/oracle/normative_weaving.cob \
  test/oracle/normative_gates.cob \
  test/oracle/normative_year.cob \
  test/oracle/normative_oracle.cob \
  test/big_integer_tests.cob \
  test/normative_primitive_tests.cob \
  test/source_catalog_tests.cob \
  test/family_bruteforce_tests.cob \
  test/selection_tests.cob \
  test/bootstrap_tests.cob
./bootstrap-tests
```

## 预期结果

若源码与目标 GnuCOBOL 兼容并且静态审查没有遗漏，预期所有第 1 阶段测试返回零退出码，目录映射、任意精度整数、基础计数、选择、穷举等价性和完整 oracle 烟雾测试全部通过。

## 实际结果

未运行。当前执行环境没有 `cobc` 或 `cobcrun`，且网络无法取得 GnuCOBOL。

## 用户应执行的动作

1. 将本包作为独立 COBOL + 简体中文实现线的第 1 阶段工作树放入目标仓库，不覆盖其他实现线。
2. 在安装 GnuCOBOL 的环境中运行 `./handoff/build_and_test.sh`。
3. 若出现编译或测试失败，把完整输出和当前工作树交回本实现线，只修正第 1 阶段，不进入第 2 阶段。
4. 若要求严格来源合规，不要把当前序列认证为正式完成；应在合规环境中从零重做第 1 阶段。
