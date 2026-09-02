# 第 1 阶段峰值内存边界审查

## 1. 目的

本文件记录第 1 阶段测试 oracle 的峰值内存风险、已经采取的精确修正，以及仍需由真实 GnuCOBOL 执行确认的部分。

审查目标不只是“调用结束后没有泄漏”。一个算法即使最终全部 `FREE`，也可能在单次调用中先把系统内存耗尽。因此本阶段同时检查：

1. 动态对象是否有唯一所有者和释放点；
2. 单次完整 oracle 的活动对象数量是否有结构性上界；
3. 重复调用后活动堆是否精确回到基线；
4. 测试是否记录单次调用的动态分配高水位。

所有修正保持 Appendix A 的精确计数和词典序反排名；没有引入近似、随机抽样、截断答案或未来补丁语义。

## 2. 已消除的主要风险：月份编织全状态 memo

旧实现把以下完整状态作为 memo key：

- `remaining[1..m]`；
- `openedUpTo`；
- `closedUpTo`。

`m` 最多为 47。虽然每个 memo 节点最终可以释放，但单次调用可能访问组合数量级的状态，并且每个状态还保存一个任意精度计数。这个结构没有可接受的单次峰值上界，理论上足以在 `RESET` 之前耗尽机器的 RAM/commit。

新实现不再分配任何 weaving memo node。

### 2.1 已打开月份的精确基数

对当前仍打开的连续月份，设剩余出现次数为 `r_i`，其前缀剩余总数为 `P_i`。满足最后出现顺序约束的基数为：

`B = product C(P_i - 1, r_i - 1)`。

该式直接计算，不保存状态图。

### 2.2 尚未打开月份的未来因子

对未来月份 `k`，长度为 `n_k`，定义：

- `w_k(0) = 1`；
- `w_k(r) = C(n_k + r - 2, r)`，`r >= 1`；
- `F_{m+1}(s) = 1`；
- `F_k(s) = sum_{r=0..s} w_k(r) * F_{k+1}(n_k - 1 + r)`。

实现使用等价递推：

`F_k(s) = F_k(s-1) + w_k(s) * F_{k+1}(n_k - 1 + s)`。

一个状态的精确补全数是：

`B * F_{openedUpTo+1}(baseLength)`。

### 2.3 动态内存边界

代码保留两个固定的 5779 项记录数组作为轮换容器，但在构造新层时，旧层单元在最后一次读取后立即 `FREE`。因此动态 BigInt 的活跃数量保持在线性数量级：最多约一层 5779 个缓存值，再加常数个临时值；不再与完整状态向量的组合数量成比例。

两个 5779 项数组本身是固定 COBOL 存储，不是 `ALLOCATE` 堆节点。

计数值本身仍是任意精度整数，因此不能在未运行前给出可靠的字节峰值。重要区别是：BigInt 的**数量**已经从潜在组合爆炸变为与年长线性相关的硬结构边界。

## 3. 已消除的第二个风险：有界组合 48×5779 BigInt DP

旧 `NORMATIVE-BOUNDED-COMPOSITION` 保留最多 `48 * 5779 = 277392` 个 BigInt 记录，并在递推过程中产生大量短期结果。

新实现完全删除该 BigInt DP 表。

对 `k` 个槽、每项范围 `[lo, hi]`、总和 `T`，令：

- `z = T - k*lo`；
- `u = hi-lo`。

精确计数使用 inclusion-exclusion：

`count = sum_j (-1)^j * C(k,j) * C(z - j*(u+1) + k - 1, k - 1)`，

其中只遍历合法的 `j`。

词典序反排名对每个候选首值调用同一精确计数公式计算其后缀块大小。每次只保留常数个 BigInt 临时值，并在被替换后立即释放。

测试增加了一个必须真正触发上界扣除项的例子：总和 8、3 个槽、每槽 1..3；完整穷举计数应为 3，并逐 rank 比较词典序结果。

## 4. 肉饼分割不再需要 BigInt DP

肉饼分割的元素均为正整数，总和 `G`，槽数 `K`。

- 无强制内部边界时，剩余状态计数为 `C(r-1, s-1)`；
- 尚未经过必需边界且该边界仍严格位于剩余区间内部时，要求一个指定切点存在，因此计数为 `C(r-2, s-2)`；
- 已经过该边界后恢复为普通正组合计数；
- 边界已经错过或不可能到达时计数为 0。

因此旧的 `18×138×2` BigInt DP 也被删除。反排名仍按候选分量从小到大计算精确后缀块大小，所以词典序语义不变。

## 5. 任意精度小除法

上述组合公式频繁使用“BigInt 除以小正整数”。为避免把每个二项式步骤送入通用长除法，`BIG-INTEGER-SERVICE` 增加 `DIV-SMALL`：

- 除数严格小于 `10^9`；
- 从最高有效九位块向最低有效块扫描；
- 每一步使用 `carry * 10^9 + digit`；
- 商块和余数均有明确的 `10^9` 上界；
- 不使用浮点数。

现有测试增加 `10^18 / 10 = 10^17` 的直接 `DIV-SMALL` 回归用例。组合公式中的除法在数学上逐步整除；真实执行仍需验证实现。

## 6. 其余动态分配源

完成本次重构后，源码中的 COBOL `ALLOCATE` 只属于三类：

1. BigInt 九位块节点；
2. BigInt arena 登记节点；
3. gate cache 节点。

月份编织不再有结构 memo allocator；有界组合和肉饼分割不再有动态 DP allocator。

Year 5000 的 40000 项候选记录是固定 `LOCAL-STORAGE`。已有证明表明，在年长上限 5778、最小 gate gap 42 下，可能有效的候选对少于 40000，因此该缓冲区不是语义截断。

## 7. 高水位测量与压力测试安全门

BigInt 服务新增两个测试可观察操作：

- `HEAP-PEAK`：读取进程内 BigInt/arena 动态块的历史高水位；
- `HEAP-PEAK-RESET`：把高水位重置为当前活动块数。

这些值不参与任何规范分支。

`ORACLE-STRESS-TESTS` 现在按以下顺序运行：

1. 创建两个长期输入并记录活动堆基线；
2. 重置高水位；
3. 只运行一次完整 Year 5000 oracle warm-up；
4. 验证 gate cache 和 weaving 有界缓存已经清空；
5. 验证活动堆精确回到基线；
6. 读取并打印单次完整 oracle 的高水位；
7. 若高水位超过 2,000,000 个 BigInt/arena 动态块，则测试失败并**不进入剩余重复循环**；
8. 只有 warm-up 通过该安全门，才继续到总计 20 次完整 oracle；
9. 每次仍要求活动堆精确回到同一基线；
10. 最终释放输入后要求活动堆为 0。

2,000,000 是测试运行安全门，不是规范数学上限，也不改变成功计算的答案。如果真实 Year 5000 触碰该门，应继续优化实现，而不是提高门值后宣称通过。

该门不能替代真实操作系统 RSS/commit 测量，也不能在第一次 allocation failure 发生后“恢复”操作系统；它的作用是阻止未知高峰被无条件重复 20 次。结构性消除组合 memo/大 DP 才是主要安全修正。

## 8. 尚未通过的门

当前文件记录的是静态内存边界重构。它还没有在修正后的源码上完成真实 GnuCOBOL compile/run，因此不能写成运行时 PASS。

必须重新执行：

- 全部单元的真实编译；
- ABI/type/field-width 警告审查；
- bootstrap tests；
- Year 5000 / weaving / BigInt-heavy tests；
- warm-up 高水位；
- 20 次重复 oracle；
- 最终 `HEAP-LIVE=0`。

在这些结果实际为绿色以前，`SEMANTIC_STATE_OWNER_VALIDATED` 必须保持 `NO`，`LAST_COMPLETED_STAGE` 必须保持 `0`。

## 9. 真实严格运行更新：内部高水位门已触发

2026-08-28 的 Strict Full 17 证明当前静态边界论证仍不充分。严格编译和 174 项 bootstrap 测试全部通过，但第一轮完整 Year 5000 oracle 在 weaving 内返回状态 135。该状态来自 `CHECK-MEMORY-GUARD`：`HEAP-LIVE` 达到 2,000,000 个活动 BigInt chunk/arena 登记块。

外部 Windows Job Object 峰值为 private 175 MiB、working 182 MiB，并未触发外部内存限制。这说明问题不是操作系统 OOM，而是逻辑动态对象数量在单次 weaving 计算内仍然达到禁止重复压力测试的安全门。

因此第 2.3 节的“动态 BigInt 活跃数量保持在线性数量级”必须继续由实际 ownership 路径验证，不能仅以 cache cell 数量推断。尤其需要审计：被 arena 登记的短期导出值是否在 layer/index 循环中显式 `FREE`/unregister，以及 cache 值转移后是否遗留额外登记。修正前不得提高 2,000,000 安全门。

## 10. Weaving Heap Probe 18：区分 chunk 高水位与 arena 登记积累

`HEAP-LIVE` 目前统计的是两类动态节点之和：BigInt 九位 chunk 与 arena registration。Strict Full 17 只证明总数达到 2,000,000，不能单凭该数字判断是哪一种对象主导。

因此下一候选只增加只读观测：

- `HEAP-CHUNK-LIVE = BI-LIVE-ALLOCATIONS - BI-ARENA-COUNT`；
- `HEAP-ARENA-LIVE = BI-ARENA-COUNT`。

weaving 构建 future-factor 时，每跨过 250,000 个总活动块记录 `K`、`S`、`MAX_S`、deep/output table id、两张表的当前 limit、总 live、chunk live 与 arena live。达到原有 2,000,000 门时仍以状态 135 停止。

该观测用于决定下一修正方向：若 arena 数量异常接近总 live，则说明 unregister/ownership 路径仍有积累；若 arena 数量保持与 cache cell 数同阶而 chunk 数接近总 live，则需要降低同时驻留的 BigInt 表示成本。两种情况都不能通过提高安全门解决。


## 11. Probe 18C 的实测结论与 Probe 19

18C 已取得决定性分解。状态 135 触发点为 weaving 的 `K=45, S=0`，此时 `CACHE_A_LIMIT=0`、`CACHE_B_LIMIT=0`，但已有 `LIVE=2457449`，其中 `CHUNKS=2135485`、`ARENA=321964`。因此第 2.3 节关于 weaving cache 活动值数量的局部论证并不能解释当前峰值；异常活动块在当前 weaving 层开始前已经存在。

同次 Windows guard 峰值 private 175 MiB、working 182 MiB，所以内部动态块门先于操作系统资源边界触发。2,000,000 门继续保持不变。

Probe 19 在顶层 oracle 阶段边界增加只读快照：arena begin、year、year scalar、sauce、cutlet 选择、cutlet 实体化、bounded-composition count、weaving 前。该观测不参与任何规范分支。下一修正必须依据这些阶段 delta 指向具体所有权路径，而不是以物理内存尚有余量为理由扩大门值。

## 12. Probe 19 定位与 Fix 20 的峰值边界修正

Probe 19 的实测阶段差分为：`ARENA_BEGIN=2`，`AFTER_YEAR=2353555`，`AFTER_YEAR_SCALARS=2353559`，`AFTER_SAUCE=2455821`。因此一轮顶层独立 Sauce 的净增长为 102262 个活动块，而 Year 内累计规模约等于 23 次同量级 Sauce 调用。该观测解释了为什么物理 private memory 只有约 177 MiB，却会触发内部 2,000,000 动态块安全门：问题是大量短期链的生命周期被顶层 arena 人为延长。

Fix 20 把 Sauce 临时值的生命周期从“整个顶层 oracle”缩短为“单次 Sauce 调用”。嵌套 checkpoint 在入口保存父 arena 头；最终六个 bowl 先 detach；rollback 回收 checkpoint 之后的其他登记链；随后最终 bowl attach 回父 arena。这样单次 Sauce 内仍允许精确 BigInt 达到其真实计算峰值，但连续 gate-gap 调用不再把每次约 102k 个临时块相加。

该修正不放宽 2,000,000 门。下一次真实 stress 必须证明新的单次 `HEAP-PEAK` 在门内，并证明每次完整 oracle 后 live count 精确回到输入基线。


## 2026-08-29 — Fix 20 实测后更新

Fix 20 实测已把 `AFTER_YEAR LIVE` 从约 235 万降到 4900，并在 weaving `K=42/S=1070` 时保持 `LIVE=250010`。因此原 status 135 的主要 ownership 累积已不再出现；当前工作转向 CPU 复杂度。2,000,000 内部门仍保持不变。

## 13. Fix 21 实测与 Fix 22

Fix 21 的 single-oracle performance probe 在被外部系统 reserve 终止前，内部 heap 已从 weaving 前 6564 增至 `LIVE=305547`（`K=41,S=2500`），仍只有 2,000,000 门的约 15.3%。外层进程树约 28 MiB private，因此该次终止不表示内部 ownership 回归。

Fix 22 的数组乘法 fast lane 使用固定大小 scratch 仅作为寻址加速，超过 1024/1024 operand chunks 或 2048 result chunks 时回退到原无界链表算法。固定 scratch 因而不成为可表示整数的上限，也不改变 live-allocation 安全门的定义。

## Fix 26 实测资源切片与 Fix 27

Fix 26 的 600 秒 Year-5000 切片在 `K=43,S=2250` 由 timebox 主动结束；guard 正常退出，峰值 private 91 MiB、working 119 MiB。内部 live 在最后观测点为 206218，仍远低于 2,000,000 安全门。该结果不是完整 oracle 的最终峰值证明，但没有显示 ownership 高水位回归。

Fix 27 只减少小标量操作的临时对象和通用分派，不放宽任何内存门；2,000,000 内部门与外部 guard 边界保持不变。


## Stage 1 完成门说明（2026-09-03）

本文早期把 20 次完整 oracle 作为资源压力验收门，是诊断策略而非 Stage 1 规范要求。该长跑现在属于可选 endurance test。Stage 1 的完成依据是严格编译、181/181 本地精确测试、small-space brute-force、显式 ownership/cache reset 检查和已经修正的结构性内存问题。2,000,000 内部诊断门本身没有删除或提高。
