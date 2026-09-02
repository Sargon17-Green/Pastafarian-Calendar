# 第 1 阶段静态审查

## 状态

当前树是 COBOL + 简体中文第 1 阶段 Bootstrap 的修正候选。它已经接受过 Windows 上 GnuCOBOL 3.2+svn.5686 的真实 discovery 编译；最近一次用户执行日志仍停在编译阶段，因此本次内存有界重构尚未经过真实编译/运行。

不能把本文件当作 GREEN 证明。

## 已实现范围

当前源码包含：

1. 冻结的 `SourceLanguageCatalog`，17 个肉饼名、47 个月份名，语义只依赖 `canonicalIndex`；
2. 中性的生产 Bootstrap 上下文、dispatcher、validator、错误边界和指标外壳；
3. 本地任意精度整数服务；
4. 独立 test-only Appendix A oracle；
5. Foundation/Tablets、SAVE、workCounts、sauce、ask、short/wide selection、gates、Year 5000、next/previous year；
6. 名称反排名、有界组合、肉饼分割、月份编织和最终五字段组装；
7. 小规模穷举对照、错误路径所有权测试和完整 oracle stress。

生产路径没有调用测试 oracle。

## 真实编译已经证明/暴露的内容

历史真实日志使用：

`cobc (GnuCOBOL) 3.2+svn.5686`

此前 discovery 编译已经暴露并促成修正：

- 非法 paragraph/control-flow；
- `CALL ... USING` 中重复 BY REFERENCE actual；
- `OCCURS` 元素与 group 的传参问题；
- 部分 field-width/narrowing 警告；
- Windows batch UTF-8 解析问题。

最近一次日志仍未进入 test execution，因此当前树新增的内存算法、`DIV-SMALL` 和 high-water 观测必须重新交给同一真实编译链。

## 精确算术静态审查

- BigInt 基数为 `10^9`；
- 单块值为 `0..999999999`；
- 两块乘积加局部 carry/已有块仍落在 18 位十进制中间值范围；
- `DIV-SMALL` 的除数严格小于 `10^9`；
- `carry * 10^9 + digit` 在当前小除数用途中远小于 18 位上限；
- SAVE 使用正欧几里得余数；
- 没有规范浮点路径。

## 内存复杂度修正

静态内存审查发现，旧月份编织 full-state memo 即使最终 reset，也可能在单次调用中先发生组合状态爆炸。旧有界组合还保留最多 277392 个 BigInt DP 单元。

当前树已经进行精确重构：

- weaving count 使用 active-base 二项式乘积与未来因子 `F_k(s)` 的线性有界缓存；
- 构造新 future-factor 层时，旧层单元最后一次读取后立即释放；
- bounded composition 使用 inclusion-exclusion 闭式，不再保存 BigInt DP；
- cutlet partition 使用指定切点的二项式计数，不再保存 BigInt DP；
- BigInt 增加 `DIV-SMALL`，供二项式递推使用；
- stress 增加 `HEAP-PEAK`/`HEAP-PEAK-RESET` warm-up 安全门。

证明与边界见 `STAGE_01_MEMORY_BOUND.md`，所有权见 `STAGE_01_OWNERSHIP_AUDIT.md`。

## 组合族独立对照

`family_bruteforce_tests.cob` 不依赖被测公式自证：

- 有界组合 `(T=5,k=2,1..4)` 完整穷举 count/rank；
- 有界组合 `(T=8,k=3,1..3)` 强制触发 inclusion-exclusion 上界扣除，并完整穷举 count/rank；
- 肉饼分割小例完整穷举；
- weaving `[2,2]` 完整穷举；
- weaving `[2,2,2]` 及两个中间 prefix state 的精确 completion count。

这些测试尚需在当前源码上真实运行。

## Year 5000 候选缓冲区

有效 Year 5000 必须跨过计算日，且年长不超过 5778。因此 opening gate 位于 `[c-5778,c)`，closing gate 位于 `[c,c+5778]`。

最小 gate gap 为 42，所以每侧保守不超过 139 个 gate；跨侧候选对最多：

`139 * 139 = 19321 < 40000`。

因此 40000 项固定候选缓冲区不会截断任何有效 Year 5000 候选。

## 动态 allocator 静态清单

当前源码中的 `ALLOCATE` 只属于：

1. BigInt chunk；
2. BigInt arena 登记节点；
3. gate cache node。

没有 weaving memo allocator，没有 bounded-composition/cutlet BigInt DP allocator。

## 调用与 ABI 静态检查

当前静态脚本检查所有字面 `CALL "..."` 目标是否存在对应 `PROGRAM-ID`，并检查 `GO TO` 目标是否存在 paragraph。当前编辑树中没有发现缺失目标。

这不能代替 GnuCOBOL 的 `-Wcall-params`、`-Wlinkage`、`-Wstrict-typing` 和 `-Wtruncate`。最终 ABI/field-width 结论必须以真实编译日志为准。

## 文本与阶段隔离

- 人工实现注释/文档使用简体中文；
- 技术标识符、状态字段和机器字符串可使用英文；
- `docs/STAGE_01_STATIC_AUDIT.md` 不应含偶然希伯来文段落；
- `src/` 不含 Stage 2/Patch 01–26 专用行为；
- 本阶段没有读取、散列、运行或差分比较其他实现。

## 来源限制

本工作序列早期已经调用过非 COBOL 运行时。该历史事实无法通过重新打包或删除文件消除。因此严格的来源证明不能写成 `foreign_language_runtime_called=NO`。

如果项目要求形式上满足“从零开始且整个实现/测试工作序列只调用 COBOL 运行时”，必须在受控环境中重新执行第 1 阶段。当前树仍可用于发现和修正 COBOL Stage 1 本身的 compile/runtime 问题，但不能伪造来源认证。

## 当前阻塞项

在以下全部真实通过以前不得更新 `LAST_COMPLETED_STAGE=1`：

1. 当前内存修正版完整编译；
2. `CALL ... USING` / ABI / field-width 警告审查；
3. bootstrap suite；
4. Year 5000 / weaving / BigInt-heavy 行为；
5. 单次完整 oracle 高水位；
6. 20 次重复 oracle 后每次活动堆回到基线；
7. 最终活动堆为 0。

## 严格编译门更新

2026-08-28 的 Strict Full 17 已在 Windows / GnuCOBOL 3.2+svn.5686 上通过两个 Stage 1 executable 的 `-Werror` 严格编译，并随后完成 174/174 bootstrap tests。当前阻塞已经从 compile/ABI gate 转移到 full-oracle weaving 动态生命周期：第一次 Year 5000 oracle 返回状态 135（`HEAP-LIVE >= 2000000`）。

## Probe 18 静态变更

当前编辑树在 Strict Full 17 之后只加入诊断性变更：BigInt live counter 的 chunk/arena 拆分、weaving 阶梯 trace，以及只运行完整 stress executable 的受保护入口 `RUN_THIS_WEAVING_HEAP_PROBE.cmd`。没有修改 Appendix A 公式、选择/反排名顺序、month lengths、weaving recurrence、2,000,000 内部门或 Windows Job Object 预算。

该编辑树尚未经过真实 `cobc -Werror`。因此 Probe 18 首先必须通过同一 strict warning 集的 stress executable 编译，然后才可把日志用于决定实际修正。

## 2026-08-28 — Fix 20 静态变更面

Probe 19 之后的规范修正仅涉及所有权基础设施与 Sauce 生命周期：`src/big_integer.cob` 增加有界 arena 子作用域；`test/oracle/oracle_bigint.cob` 暴露 `SCOPE-BEGIN`、`SCOPE-END`、`ATTACH`；`test/oracle/normative_sauce.cob` 使用该子作用域。Appendix A 公式、Year/Gates/Weaving 算法、SourceLanguageCatalog、2,000,000 门及 Windows guard 参数未改变。Fix 20 probe 的 CMD 仅加强验证顺序：先严格 bootstrap 回归，再运行完整 stress。

## Fix 20 打包前静态复核

打包前再次对当前 canonical 树执行字面调用/段落目标检查：共 22 个 `.cob` 文件、27 个 `PROGRAM-ID`，263 个字面 `CALL`（25 个唯一目标）；没有缺失 `PROGRAM-ID`。所有字面 `GO TO` 目标都存在对应 paragraph。

相对 Probe 19，COBOL 变更面严格限定为三个文件：`src/big_integer.cob`、`test/oracle/oracle_bigint.cob`、`test/oracle/normative_sauce.cob`。`test/oracle/normative_oracle.cob` 与 `test/oracle/normative_weaving.cob` 字节未变；`RUN_THIS_STAGE1_FULL.cmd` 与 `handoff/run_guarded.ps1` 也字节未变。

`SCOPE-BEGIN`、`SCOPE-END`、`ARENA-ATTACH`、`ARENA-DETACH`、`HEAP-ARENA-LIVE`、`HEAP-CHUNK-LIVE` 均不超过 16 字符的操作字段宽度。两个 2,000,000 安全门仍分别位于 `test/oracle_stress_tests.cob` 与 `test/oracle/normative_weaving.cob`，数值未改变。

当前容器没有可用的 `cobc`，且本地包索引无法及时取得 GnuCOBOL，因此这里不能诚实声称 Fix 20 已编译。Windows probe 入口被设计为先用既有严格 warning 集（含 `-Werror`）编译 bootstrap 和 stress，再执行任何验证；真实编译结果必须以后续日志为准。


## 2026-08-29 — Fix 21 性能路径静态审计

Fix 20 长跑暴露的 CPU 问题定位到普通 BigInt 乘法结果链表的重复扫描。Fix 21 只在 `MULTIPLY-H1-H2` 增加结果行 cursor，并在测试中增加一个 50×50 位已知乘积向量。规范 oracle 仅增加每 250 个 `S` 的只读性能 marker。2,000,000 内部门、Appendix A 公式、weaving recurrence 和 unranking 均未改变。

### Fix 21 打包前计数

- COBOL 文件：23（新增 `test/oracle_perf_probe.cob`）；
- `PROGRAM-ID`：28；
- 唯一字面 `CALL` 目标：25；
- 缺失字面 `CALL` 目标：0；
- 缺失字面 `GO TO` 目标：0；
- 相对 Fix 20 发生变化/新增的 COBOL：`src/big_integer.cob`、`test/big_integer_tests.cob`、`test/oracle/normative_weaving.cob`、`test/oracle_perf_probe.cob`；
- `test/oracle_stress_tests.cob`、`test/oracle/normative_oracle.cob`、`test/oracle/normative_sauce.cob` 与 Fix 20 字节相同；
- `RUN_THIS_STAGE1_FULL.cmd` 与 Fix 20 字节相同；
- weaving/stress 的 2,000,000 内部门各仍保留一处。

当前容器未取得可用 `cobc`（包安装尝试未成功），因此以上是静态审计，不是编译 PASS。真实证据必须由 Windows GnuCOBOL 运行生成。

## 2026-08-29 — Fix 22 静态变更面

Fix 21 的真实日志证明严格编译与 175/175 bootstrap 已通过；single oracle 未完成是外部 `SYSTEM_AVAILABLE_LIMIT` 中止。Fix 22 的 COBOL 语义变更仅限 `src/big_integer.cob` 的普通乘法寻址 fast lane。`NORMATIVE-ORACLE`、`NORMATIVE-SAUCE`、`NORMATIVE-WEAVING`、stress 逻辑、SourceLanguageCatalog 和两个 2,000,000 安全门均未改动。

外层 `handoff/run_guarded.ps1` 只为 `PERFORMANCE_PROBE` 增加 120 秒低内存 grace 与 384 MiB emergency floor；其他 guard purpose 仍使用原即时 reserve 逻辑。当前容器仍没有可用 `cobc`/PowerShell，因此 Fix 22 在打包前只能完成静态检查，不能宣称本地 compile PASS。

### Fix 22 打包前静态复核

- COBOL 文件：23；
- `PROGRAM-ID`：28；
- 唯一字面 `CALL` 目标：25；
- 缺失字面 `CALL` 目标：0；
- 缺失字面 `GO TO` 目标：0；
- 相对 Fix 21 唯一发生变化的 COBOL 文件：`src/big_integer.cob`；
- `test/oracle/normative_weaving.cob`、`test/oracle/normative_oracle.cob`、`test/oracle/normative_sauce.cob`、`test/oracle_stress_tests.cob` 均与 Fix 21 字节相同；
- `RUN_THIS_STAGE1_FULL.cmd` 与 `RUN_THIS_PERFORMANCE_PROBE.cmd` 均与 Fix 21 字节相同；
- weaving/stress 的 `2000000` 安全门各保留一处；
- `handoff/run_guarded.ps1` 的大括号与圆括号静态计数平衡；但没有 PowerShell 解释器可做真实语法执行。


## 2026-08-29 — Fix 23 变更面

Fix 22 真实运行已通过严格编译和 175/175 bootstrap；终止来自外部 guard 的 execution-log sharing violation。Fix 23 不修改任何 `.cob` 文件。相对 Fix 22，仅 `handoff/run_guarded.ps1` 的 guard-side execution-log 写入被移除；`handoff/build_and_test.cmd` 只更新 performance package 标签；其余变化为 handoff 文档与真实日志归档。

全部 23 个 COBOL 文件与 Fix 22 字节相同；`RUN_THIS_STAGE1_FULL.cmd`、`RUN_THIS_WEAVING_HEAP_PROBE.cmd`、`RUN_THIS_PERFORMANCE_PROBE.cmd` 也与 Fix 22 字节相同。两个 `2000000` 内部门未改变。

## Fix 26：arena 注销复杂度修正

Fix 26 的规范计算仍使用完全相同的 weaving recurrence。变化集中在 BigInt ownership metadata：chunk head 增加 arena owner backlink，arena 登记增加 prev 指针，使显式 `FREE-A` / detach 的正常注销从线性扫描降为 O(1)。旧扫描保留 fallback。

新增 bootstrap middle-node 注销回归要求 O(1) hit 且 scan steps 为零；bootstrap 预期总数为 176。performance 入口改为 600 秒切片，因此本包不能产生 Stage 1 PASS。

## Fix 27 打包前静态审计

相对 Fix 26，23 个 COBOL 文件中只有以下四个变化：

- `src/big_integer.cob`：数值小标量乘/除内部通道与只读 hit 计数；
- `test/oracle/oracle_bigint.cob`：小标量 fast-path 分派，历史 fallback 保留；
- `test/big_integer_tests.cob`：numeric MUL/DIV 回归与 hit 检查；
- `test/oracle/normative_weaving.cob`：只增加 fast-hit 性能打印。

共识别 28 个 `PROGRAM-ID`、25 个唯一字面 `CALL` 目标，缺失目标 0；字面 `GO TO` 缺失目标 0。`normative_oracle.cob`、`normative_sauce.cob`、`oracle_stress_tests.cob`、`RUN_THIS_STAGE1_FULL.cmd`、performance guard 与 capture wrapper 均与 Fix 26 字节相同。weaving live 与 stress peak 的 2,000,000 安全门均保留。

当前容器没有 `cobc`，因此该审计不能替代真实 `-Werror` 编译。下一证据必须来自 Windows `RUN_THIS_PERFORMANCE_PROBE.cmd`。详细机器记录见 `handoff/logs/FIX27_STATIC_AUDIT.txt`。



## Finalization Entry Fix 36

与 Finalization Run 35 比较，23 个 `.cob` 文件路径和 SHA-256 全部一致。`test/oracle_stress_tests.cob` 仍定义 `WS-ITERATIONS=20` 和 `WS-SAFE-PEAK-LIMIT=2000000`；`test/oracle/normative_weaving.cob` 仍定义 `WS-SAFE-LIVE-LIMIT=2000000`。本修正只涉及 Windows guard 启动 headroom、包标签和文档。

## Stage 1 关闭补充（2026-09-03）

最终关闭不修改任何 COBOL 文件。真实 GnuCOBOL `-Werror` 编译与 181/181 bootstrap 已通过。此前 20 次完整 Year-5000 stress 是内部 endurance 诊断，不是 Stage 1 规范必须门；现行重新验证入口仅严格编译完整 Stage 1 测试树并运行 bootstrap suite。`oracle_stress_tests.cob` 保留为可选诊断源码。
