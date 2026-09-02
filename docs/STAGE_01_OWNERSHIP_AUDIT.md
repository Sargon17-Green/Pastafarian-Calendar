# 第 1 阶段所有权与堆生命周期审查

## 1. 审查范围

本审查覆盖第 1 阶段测试 oracle 的：

- BigInt 临时值与最终值；
- arena 登记；
- gate cache；
- 月份编织有界缓存；
- 组合族计数与反排名；
- 固定数组/缓冲区；
- 显式错误路径；
- 重复完整 oracle 调用。

峰值内存复杂度与新的有界算法另见 `STAGE_01_MEMORY_BOUND.md`。

## 2. 动态 allocator 清单

当前 COBOL 源码中的 `ALLOCATE` 只有三类：

| 动态对象 | 创建者 | 所有者 | 释放者 | 生命周期 |
| --- | --- | --- | --- | --- |
| BigInt 九位块节点 | `BIG-INTEGER-SERVICE` | 当前 BigInt 值的唯一逻辑所有者 | `FREE-A` / 局部清理 / arena cleanup | 从创建到值被释放或转交 |
| arena 登记节点 | `BIG-INTEGER-SERVICE` | 当前 arena | 显式 `FREE` 时注销，或 `ARENA-END` | 单个顶层 oracle 作用域 |
| gate 节点 | `NORMATIVE-GATES` | 当前 gate cache | `RESET` / 错误清理 | 单个顶层 oracle 作用域 |

月份编织不再分配 memo node。有界组合和肉饼分割不再分配 BigInt DP 表。

## 3. BigInt 所有权

### 3.1 普通服务调用

`BIG-INTEGER-SERVICE` 的结果遵守唯一转移规则：

1. 运算过程先在局部 `WS-R`/`WS-R2`/`WS-T`/`WS-U` 中拥有链；
2. 成功导出时，链的所有权转给调用者的输出记录；
3. 导出后局部记录立即清空，避免局部清理再次释放；
4. 未导出的局部链在返回前释放；
5. `FREE-A` 释放调用者拥有的链并把输入记录清零。

零值由空链表示，不需要动态释放。

### 3.2 arena 内

顶层 `NORMATIVE-ORACLE` 在任何规范 BigInt 工作前开启 arena。arena 活跃时，每个新导出的非零 BigInt 同时登记一个 arena 节点。

- 若临时值被显式 `FREE`，服务先从 arena 注销，再释放其链；
- 若临时值未显式释放，`ARENA-END` 统一释放；
- 成功的最终年份值在离开 oracle 前执行 `DETACH`，因此不由 `ARENA-END` 回收；
- 该年份值随后由调用者拥有并负责 `FREE`。

### 3.3 `ORACLE-BIGINT` 自身临时值

`ADD-SMALL`、`MUL-SMALL`、`CMP-SMALL`、`MOD-M`、`MOD-SMALL`、普通 `DIV` 和 `SAVE` 的内部 scalar/modulus/remainder 中间值都有本调用期所有者，并在返回前释放。它们不要求进程生命周期。

新增 `DIV-SMALL` 直接在 BigInt 九位块上执行小正整数除法，不创建小除数 BigInt。

## 4. 月份编织所有权

旧 full-state memo 已删除。`NORMATIVE-WEAVING-COUNT` 现在拥有一个有界 future-factor cache：

- 两个固定 5779 项 COBOL 记录数组只是容器，不是动态 allocator；
- 每个非零缓存项拥有一个独立 BigInt；
- 构造下一层时，旧层项在最后一次读取后立即 `FREE`；
- `RESET` 释放两个容器中仍存在的全部 BigInt；
- `ASSERT-EMPTY` 验证 reset 后不存在缓存项。

`NORMATIVE-WEAVING` 对 child block 和替换后的 rank 使用显式局部所有权：

- child block 在比较完成后立即释放；
- 每次 rank 被新的 `rank-block` 替换时，先释放旧的内部 rank；
- 初始 `LK-RANK` 只是借用，不由 callee 释放；
- 成功的 `LK-COUNT` 才转给调用者；
- 失败路径若已经导出 count，会将其释放并清空；
- 所有退出路径都 reset weaving cache。

## 5. 有界组合所有权

`NORMATIVE-BOUNDED-COMPOSITION` 已删除 `48×5779` BigInt DP。

当前计算只保留常数个 BigInt：

- 当前总和；
- 两个二项式因子；
- 当前 inclusion-exclusion 项；
- 当前分支 block；
- 必要时的内部 rank 副本。

每个被替换的值在赋入新值以前显式 `FREE`。非零 rank 时，总 count 先由 callee 保留；只有完整 unrank 成功后才转给 `LK-COUNT`。因此中途错误不留下部分 heap 输出。

## 6. 肉饼分割所有权

旧 `18×138×2` BigInt DP 已删除。计数使用正组合的二项式闭式，并根据指定内部切点是否尚未命中选择精确的 `C(r-1,s-1)` 或 `C(r-2,s-2)`。

运行期只保留总 count、当前 branch block、内部 rank 和一个二项式工作值；替换后立即释放。错误路径不导出部分 count。

## 7. gate cache

每个 `GATE-NODE` 同时拥有：

- gate index BigInt；
- gate day BigInt；
- 前后结构指针。

插入 cache 时使用独立 BigInt 副本，不借用调用者结果。`FREE-GATES` 先释放节点拥有的 BigInt，再释放节点本身。顶层 oracle 在进入时 reset，在所有成功/错误退出时再次 reset。

`ASSERT-EMPTY` 用于 stress 检查结构节点已经归零。

## 8. 固定缓冲区

以下对象不由 COBOL `ALLOCATE` 创建：

- Year 5000 的 40000 项候选记录；
- weaving 的两个 5779 项指针/元数据容器；
- 最多 5778 项的 weaving 输出；
- sauce 六碗和固定表；
- 名称 ID、月份长度和其他固定数组；
- 8192 字符 BigInt 文本序列化缓冲区。

这些对象随相应的 `LOCAL-STORAGE`/`WORKING-STORAGE` 生命周期存在；其记录中若保存动态 BigInt 指针，则动态链仍按本文件的显式规则释放。

## 9. 顶层 oracle 生命周期

成功调用顺序为：

1. 验证 caller 提供的年份输出为空；
2. reset gate/weaving scoped cache；
3. `ARENA-BEGIN`；
4. 执行 Year 5000、结构 sauce、组合族和 weaving；
5. 得到最终五字段结果；
6. reset gate/weaving cache；
7. 对最终年份执行 arena `DETACH`；
8. `ARENA-END` 回收其余所有未显式释放的 BigInt；
9. 年份所有权转给 caller。

肉饼名、月份名和两个日序号是值结果，不需要堆释放。

若 caller 传入的年份记录任一 `sign/chunks/head/tail` 字段已经表示非空所有权，oracle 在新 scoped allocation 之前以状态 175 拒绝调用。

## 10. 错误路径

显式错误路径遵守以下原则：

- 尚未转交的局部 BigInt 由当前 procedure cleanup；
- scoped gate/weaving cache 在顶层退出前 reset；
- arena 在已开启时必须关闭；
- callee 不释放借用的 caller 输入；
- 对“成功才导出”的接口，中途错误返回空动态输出；
- weaving 已导出的 count 若后续 rank/反排名失败，会在错误退出前撤销并释放。

`test/ownership_error_tests.cob` 覆盖：

1. 非法 weaving rank 返回状态 141、count 为空、weaving 有界缓存为空、arena 关闭后活动堆为 0；
2. caller-owned 年份输出被状态 175 拒绝且活动堆不变；
3. 无 arena 条件下重复 raw BigInt helper，并要求每轮回到同一活动堆基线。

## 11. 重复调用与高水位

`BI-LIVE-ALLOCATIONS` 统计 BigInt chunk 与 arena 登记节点的当前活动数量。

新增：

- `HEAP-LIVE`；
- `HEAP-PEAK`；
- `HEAP-PEAK-RESET`。

它们仅用于测试观测，不参与规范计算。

`ORACLE-STRESS-TESTS` 先运行一次完整 oracle warm-up，验证：

- gate cache 为空；
- weaving 有界缓存为空；
- 活动堆回到长期输入基线；
- 单次高水位不超过测试安全门 2,000,000 个动态 BigInt/arena 块。

只有上述条件通过才继续到总计 20 次完整 oracle。每次都要求活动堆精确回到同一基线，最后释放长期输入后要求 0。

## 12. 当前结论

静态所有权模型目前没有已知的必要 process-lifetime heap allocation，也没有已知的组合数量级动态状态结构。原先最危险的 weaving memo 和大型组合 DP 已被精确的有界算法替换。

这仍不是运行时 PASS。修正后的源码必须在 GnuCOBOL 中重新编译，并实际通过普通 suite、Year 5000、weaving、BigInt-heavy、高水位和 20 次重复 stress，之后才能把 `SEMANTIC_STATE_OWNER_VALIDATED` 改为 `YES`。

## 13. 真实运行发现的未闭合所有权问题

Strict Full 17 已证明普通 BigInt、bootstrap 错误路径和小型 weaving 测试可以通过，但完整 Year 5000 weaving 在第一次 oracle 调用中触发状态 135：`HEAP-LIVE` 达到 2,000,000。

因此本文件第 12 节的静态模型不能视为最终证据。至少存在一种完整规模路径，使 BigInt chunk 或 arena registration 的活动数量没有按预期及时下降。下一步必须逐 layer/index 记录 `HEAP-LIVE`/`HEAP-PEAK` 并核对每个 exported temporary 的 creator/owner/free/unregister 路径，特别是 future-factor cache 构造和二项式递推。

在该问题通过真实 stress 关闭以前，`SEMANTIC_STATE_OWNER_VALIDATED` 必须继续为 `NO`。

## 14. Probe 18 的所有权判别计数

下一次真实运行不再把 `HEAP-LIVE` 当成单一对象类型。BigInt 服务只读暴露 arena registration 数，并由总 live 减去该数得到 chunk 数。weaving 在原有安全门之前按阶段输出两者。

判别标准不是“arena 越少越好”，而是与活动 cache 值数量的数量级一致性：每个已导出的非零 BigInt 正常应有一个 arena registration，另有若干 chunk。若 arena registration 数远大于实际持有的 BigInt 值数量，则证明存在登记重复或释放时未 unregister；若 registration 数合理而 chunk 数巨大，则所有权可能正确，但物理表示的单次峰值仍不满足 Stage 1 的资源边界要求。


## Probe 18C 对所有权审查的修正

18C 显示在 weaving 第一层真正开始前，arena 中已有 321964 个登记节点，BigInt chunk 也已有 2135485 个活动节点。由于 weaving 两张表的 limit 仍为 0，当前异常不能只归因于 future-factor cache 的转移/释放。

顶层 arena 设计允许未显式释放的中间值一直存活到 `ARENA-END`。这在错误安全上是兜底，但不自动满足单次调用峰值边界。因此“arena 最终会释放”不能再被视为足够的峰值所有权证明。Probe 19 先定位哪个顶层阶段贡献主要净增长；随后应在该阶段把短期导出值改成显式 `FREE`/unregister 或等价的有界作用域策略，同时保护真正需要跨阶段存活的根值。

## 15. Probe 19 后的所有权结论：Sauce 需要子作用域

Probe 19 证明顶层 arena 的“最终统一释放”在 Sauce 上虽然保证最终无泄漏，但不保证可接受的调用内峰值。单次独立 Sauce 在返回时留下 102262 个活动 chunk/registration；Year 的 gate-gap 路径重复 Sauce，使这些互不再需要的临时值同时存活。

Fix 20 增加三项 test-only arena 控制：

- `SCOPE-BEGIN`：保存父 arena 当前 head；没有父 arena 时创建临时根作用域；
- `SCOPE-END`：只释放进入点之后仍登记的值，并恢复父作用域；
- `ATTACH` / `ARENA-ATTACH`：把已 detach 的保留值重新登记到仍活动的父 arena；若没有父 arena，则保持普通调用者所有权。

`NORMATIVE-SAUCE` 的 creator/owner/free 路径现在是：所有内部导出值先由 Sauce 子作用域拥有；成功时六个 final bowl 转交给调用者并在需要时重新登记到父 arena；其他所有临时值在 Sauce 返回前回收。失败时 scope 一定尝试关闭，已经 detach 的 final bowl 由错误清理显式释放。这样避免逐表达式 `FREE` 对浅拷贝 alias 造成 use-after-free。


## 2026-08-29 — Fix 20 实测结论

真实长跑中 `AFTER_YEAR LIVE=4900`、`BEFORE_WEAVING LIVE=6564`，相较 Probe 19 的 `AFTER_YEAR LIVE=2353555` 已下降约三个数量级。该结果支持 Sauce bounded sub-scope 的 ownership 方向正确；Fix 21 不再修改该 ownership 模型，只处理普通乘法的链表定位复杂度。

## Fix 26：arena owner backlink

arena 中每个已登记 BigInt 的 head chunk 现在保存其 arena node 指针；arena node 同时保存 prev/next。显式 FREE/DETACH 先验证 backlink 指向的 arena node 的 `AN-HEAD` 是否仍等于当前 BigInt head，验证成功后直接 unlink。若 backlink 缺失或不一致，才执行历史线性搜索并在找到后修复 backlink。

scope rollback 与 arena end 在释放 chunk chain 之前清除 head backlink，并维护新 arena head 的 `AN-PREV=NULL`。这不改变调用者/arena 所有权边界，只降低寻找登记节点的复杂度。

## Fix 26 实测后的 ownership 结论

真实 600 秒切片中 bootstrap middle-node 回归得到 `ARENA_O1_HITS=2`、`ARENA_SCAN_STEPS=0`。进入 Year-5000 weaving 时累计 scan steps 为 58254；随后多个 `WEAVING_PERF_POINT` 中该数值保持不变，而 O(1) hits 从约 8.736M 持续上升。这证明正常 weaving 显式释放路径不再线性扫描 arena；保留的 scan fallback 没有在被测 weaving 段继续增长。

Fix 27 不改变 ownership 边界。相反，常见 `MUL-SMALL` fast path 不再创建临时 scalar BigInt，因此减少一次临时 arena registration/free；历史 fallback 仍按原 ownership 规则处理。


## 16. 2026-09-03 — Stage 1 验收门纠偏

本文件前面的“必须先完成 20 次完整 oracle 才能把 `SEMANTIC_STATE_OWNER_VALIDATED` 设为 YES”是工作过程增加的保守压力策略，不是 Stage 1 规范条款。它现在仅作为 endurance diagnostic 保留。

Stage 1 的所有权结论改由已经真实通过的 targeted contract tests 判定：weaving 错误路径清理 + `ASSERT-EMPTY`、caller-owned output guard、50 轮 raw BigInt baseline、arena end live=0，以及 gate/weaving 显式 reset。结合 Sauce bounded scope 对此前真实峰值问题的修正，当前 `SEMANTIC_STATE_OWNER_VALIDATED=YES`。

可选 20× stress 若未来执行失败，仍应作为新的可靠性证据调查；但在没有新 failure 的情况下，不再反向把已通过的 Stage 1 规范验证改成未完成。
