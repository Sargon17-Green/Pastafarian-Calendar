# 第 1 阶段完成审查

## 1. 结论

第 1 阶段状态为 `GREEN`，`LAST_COMPLETED_STAGE=1`。

本次关闭不修改 COBOL 规范计算。关闭依据是已经取得的真实 GnuCOBOL 严格编译和 181/181 bootstrap PASS，以及第 1 阶段规范自身规定的验证范围。

## 2. 已取得的真实执行证据

真实 Windows 环境：

```text
GnuCOBOL 3.2+svn.5686
x86_64-pc-mingw64
64bit-mode=yes
STRICT COMPILE=PASS
BOOTSTRAP TESTS=181
FAILED=0
BOOTSTRAP_RESULT=PASS
```

完整 test-only oracle 的全部 COBOL 单元参与严格链接编译；因此第 1 阶段关闭不是“只编译 production skeleton”。

## 3. 规范要求与此前额外压力门的区别

第 1 阶段要求：

- 从规范重新建立同线的 test-only oracle；
- exact integer arithmetic；
- 本地 fixtures / expected values；
- exact ordered-family count 与 `unrank1`；
- 在小空间用同语言 force-brute 证明计数和顺序；
- production/oracle 分离；
- 中性的 invocation-local 基础状态；
- GREEN 测试状态。

规范明确允许 exact DP count、lexicographic unranking 和 memoization；禁止 approximation、sampling、floating-point rank 与 truncated counts。

工作过程中另外加入了“完整 Year-5000 oracle 连续 20 次”的压力程序。它对发现资源问题很有用，但不是上述 Stage 1 完成条款。因此不能继续把一个额外诊断压力门升级成规范完成条件。

## 4. 181 项测试提供的语义证据

当前 suite 覆盖：

- BigInt 多 chunk 解析、序列化、加减乘除、小整数操作、负数 Euclidean 行为；
- `SAVE`、day/work counts 与 Appendix A primitive；
- sauce 与 selection helper；
- gate / year helper；
- bounded composition 与 cutlet family；
- month weaving 的小域 exhaustive enumeration；
- exact count 与 enumerated family 大小一致；
- lexicographic `unrank1` 与 brute-force 顺序一致；
- SourceLanguageCatalog 数量、索引、冻结顺序；
- production/oracle separation。

这些测试全部在 COBOL 内完成，不需要另一实现提供 expected output。

## 5. semantic state ownership

`SEMANTIC_STATE_OWNER_VALIDATED=YES` 的依据不是“进程最终退出”，而是现有 targeted tests 与显式 reset/owner contract：

- 非法 weaving rank 必须返回状态 141、撤销部分 count，并在 `ASSERT-EMPTY` 后无 weaving cache；
- caller 已拥有年份输出时，oracle 在新 allocation 前以状态 175 拒绝，heap live 不变；
- raw BigInt helper 连续 50 轮后每轮回到同一 live baseline；
- arena 结束后要求 live=0；
- gate/weaving scoped caches 都有 reset / empty 检查；
- Sauce 子作用域把短期值限制在调用内，已通过后续 bootstrap 与长时间真实运行验证，没有恢复原状态 135 的入口前堆积。

20 次完整同一 witness 只是额外 endurance test；它不是证明上述 owner contract 的唯一方法。

## 6. 可选 stress 的保留方式

`test/oracle_stress_tests.cob` 继续保留，不删除历史诊断工具。它可以以后用于机器耐久性、性能或高水位调查，但其运行时间不再阻塞 Stage 2。

`RUN_THIS_STAGE1_VERIFY.cmd` 是现行 Stage 1 重新验证入口。旧的 `RUN_THIS_STAGE1_FULL.cmd` 和 `RUN_THIS_STAGE1_FINISH.cmd` 作为兼容别名指向同一规范 Stage 1 验证，不再隐式启动 20 次长跑。

## 7. 不变项

本次关闭未修改：

- `src/*.cob`；
- `test/*.cob` 与 `test/oracle/*.cob`；
- Appendix A 算法与常量；
- 2,000,000 内部诊断门；
- SourceLanguageCatalog；
- production/oracle separation。

第 2 阶段没有开始。
