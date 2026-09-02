# 第 1 阶段 Windows 外部内存保护


## 当前策略：Finalization Entry Fix 36

最终收尾运行 35 已证明 Strict Full 的旧启动公式会产生假拒绝：系统有 2488 MiB 可用，但旧公式把 2048 MiB Job Object **上限**再次当作必须预留的未来占用，再加 1024 MiB 系统保留线，因而要求 3072 MiB 并在任何 COBOL 子进程创建前返回 84。

Fix 36 只修改 FULL 的启动条件：`START_HEADROOM_BASIS=RUNTIME_RESERVE_ONLY`，因此 `REQUIRED_START_AVAILABLE_MB=1024`。这不降低运行中的任何保护：

- process tree private 达到 1536 MiB：终止；
- Job Object 达到 2048 MiB：Windows 硬限制；
- 系统可用物理内存低于 1024 MiB：FULL guard 终止；
- 轮询仍为 250 ms；
- COBOL 内部 2,000,000 heap-live 门不变。

下文关于 Strict Full 3072 MiB 启动门的描述保留为历史记录，不再代表当前 Fix 36 策略。

Windows 本地验证通过 Job Object 运行。该保护只限制构建/测试进程资源，不参与任何日历计算，也不改变规范结果。

## 当前完整验证入口

项目根目录：

```bat
RUN_THIS_STAGE1_FULL.cmd
```

候选 17 使用：

- private memory 软线：1536 MiB；
- Job Object 硬上限：2048 MiB；
- 系统可用物理内存保留线：1024 MiB；
- 轮询：250 ms；
- 当前 Fix 36 启动前只要求至少 `1024 MiB` 可用物理内存；2048 MiB 是运行中 Job Object 硬上限，不再重复计入启动预留；
- Job Object 启用 `KILL_ON_JOB_CLOSE`。

BigInt Probe 16 的真实峰值只有 private 71 MiB / working set 106 MiB。当前更大的预算是为了允许完整 Year 5000、weaving、gates 和 20 次 stress 运行，同时仍保留 2 GiB 的操作系统硬边界。

## 日志

保护层：

```text
handoff\logs\STAGE_01_GUARD_LOG.txt
```

构建/测试：

```text
handoff\logs\STAGE_01_EXECUTION_LOG.txt
```

正常完整成功应同时具有：

```text
BOOTSTRAP_RESULT=PASS
STRESS_RESULT=PASS
RESULT=PASS_STRICT_FULL
```

并且 guard 应记录：

```text
GUARD_RESULT=PROCESS_EXITED
EXIT_CODE=0
```

## 诊断入口

`handoff\run_compile_guarded.cmd` 与 `handoff\run_light_guarded.cmd` 仍保留，只用于完整运行失败后的定位。当前推荐路径不再要求先执行它们。

不得直接运行 `handoff\build_and_test.cmd`；该脚本要求由外层 guard 设置 `STAGE1_GUARD_ACTIVE=1`。

## Weaving Heap Probe 18A 的低余量诊断入口

2026-08-28，Probe 18 第一次启动时系统可用物理内存为 2974 MiB；旧诊断入口仍采用完整运行的 1024 MiB 保留线，因此启动要求为 3072 MiB，guard 在创建 build/test 子进程以前正确拒绝运行。

为了取得状态 135 的只读诊断分解，18A 仅对 `RUN_THIS_WEAVING_HEAP_PROBE.cmd` 使用 768 MiB 系统可用物理内存保留线。于是：

- probe private 软线仍为 1536 MiB；
- probe Job 硬上限仍为 2048 MiB；
- probe 启动要求为 2816 MiB；
- probe 运行中若可用内存低于 768 MiB，仍由 guard 终止；
- `RUN_THIS_STAGE1_FULL.cmd` 完全不变，仍要求 1024 MiB 系统保留线和 3072 MiB 启动余量。

这不是 Stage 1 验收门的放宽，只是诊断入口的主机资源策略调整。


## Weaving Heap Probe 18B：启动 headroom 使用先触发的软线

18A 第二次真实启动时仅有 2545 MiB 可用物理内存，低于 2816 MiB 旧要求，因此仍未进入 COBOL。18B 不改变运行中任何阈值，而修正 probe 的启动预算：WEAVING_HEAP_PROBE 在 private memory 达到 1536 MiB 时已经被软杀，所以启动时要求 `MIN_AVAILABLE_MB + SOFT_PRIVATE_MB = 768 + 1536 = 2304 MiB`。

2048 MiB Job Object 上限仍设置并由 Windows 强制执行；运行中系统可用物理内存低于 768 MiB 仍杀死整个 Job。只有 `GUARD_PURPOSE=WEAVING_HEAP_PROBE` 使用 soft-private basis；Strict Full 以及其他入口继续使用 hard-Job basis。Strict Full 的 3072 MiB 启动门因此没有改变。

新日志字段：

```text
START_HEADROOM_BASIS=SOFT_PRIVATE
REQUIRED_START_AVAILABLE_MB=2304
```

Strict Full 应记录 `START_HEADROOM_BASIS=HARD_JOB` 与 `REQUIRED_START_AVAILABLE_MB=3072`。

## Weaving Heap Probe 18C：启动只要求运行保留线

18B 第三次真实启动时系统只有 1973 MiB 可用物理内存，低于 2304 MiB 的 `SOFT_PRIVATE + reserve` 启动门，因此仍未创建 COBOL/build 子进程。三次启动前可用内存分别为 2974、2545、1973 MiB，说明主机空闲内存本身波动显著。

18C 仅对 `WEAVING_HEAP_PROBE` 取消“未来进程预算”的启动预留，改为 `START_HEADROOM_BASIS=RUNTIME_RESERVE_ONLY`，启动要求仅为 `MIN_AVAILABLE_MB=768`。运行中安全边界完全不变：1536 MiB private 软杀、2048 MiB Job Object 硬上限、768 MiB 系统可用物理内存杀线、250 ms 轮询和 `KILL_ON_JOB_CLOSE`。因此 probe 可以在低空闲内存主机上开始，但不能侵占 768 MiB 系统保留线。

Strict Full 不使用此逻辑，继续采用 `START_HEADROOM_BASIS=HARD_JOB` 与 3072 MiB 启动门。


## Performance probe 的瞬时低内存 grace（Fix 22）

Fix 21 的 single-oracle 运行在进程自身约 28 MiB private 时，因为主机可用物理内存单次采样降至 643 MiB 而被立即终止。为避免长性能探针因瞬时外部压力丢失全部进度，Fix 22 只对 `GUARD_PURPOSE=PERFORMANCE_PROBE` 使用两级策略：

- `MIN_AVAILABLE_MB=768` 保持不变，仍是正常系统 reserve；
- 首次低于 768 MiB 时记录 grace 开始，不立即杀 Job；
- 在 120 秒内恢复到至少 768 MiB 时记录恢复并继续；
- 连续 120 秒低于 768 MiB 时以 `SYSTEM_AVAILABLE_LIMIT_SUSTAINED` 终止；
- 低于 384 MiB 时不等待，以 `SYSTEM_AVAILABLE_EMERGENCY` 立即终止；
- private soft limit 1536 MiB 和 Job hard limit 2048 MiB 不变。

非 performance 入口仍沿用原来的即时 `MIN_AVAILABLE_MB` 行为；尤其 Strict Full 没有放宽。


## Fix 23：execution log 单一写入者

Fix 22 的真实 performance probe 首次跌到 `AVAILABLE_MB=766` 时正确进入 120 秒 grace，但 guard 随后用 `Add-Content` 写 `STAGE_01_EXECUTION_LOG.txt`。该文件此时正由 `oracle-perf-probe.exe >> ...` 的子进程重定向持有，Windows 返回 sharing violation；顶层 guard catch 因而终止 Job。

Fix 23 不改变任何资源阈值。运行中 execution log 改为单一写入者模型：只有 build/test 子树写该文件；guard 只写独立 `STAGE_01_GUARD_LOG.txt`。因此低内存 grace / recovery / kill / error 事件全部以 guard log 为权威记录。`Current-Phase` 与 `Current-PerfPoint` 仍是只读 best-effort，读取 sharing violation 已由局部 `try/catch` 吞掉，不会终止 Job。

performance 参数仍为 768 MiB reserve、120 秒 grace、384 MiB emergency floor、1536 MiB private soft limit、2048 MiB Job hard limit。Strict Full 没有放宽。

## Fix 25：performance probe 防睡眠与 emergency debounce

Diagnostic 24 的真实运行在 02:04–02:47 期间每 30 秒记录 heartbeat，child `CPU_MS` 基本按墙钟一比一增长；02:47:59 后没有任何 heartbeat，直到约 05:03 guard/日志结束。guard 最终记录主机可用物理内存 375 MiB 并按旧 384 MiB emergency floor 立即终止 Job，而 Job 自身仅约 86 MiB private / 107 MiB working。该时间模式与 Windows 自动 sleep/standby 后唤醒高度一致，并没有形成 child 自身 raw exit。

Fix 25 仍只影响 `GUARD_PURPOSE=PERFORMANCE_PROBE`：

- guard 在 performance probe 开始时调用 `SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED)`，并在运行循环中刷新，退出时恢复 `ES_CONTINUOUS`；这阻止系统因空闲自动进入 sleep，但不阻止用户主动关机/睡眠；
- 正常 reserve 仍为 768 MiB，低于该值的 120 秒 grace 不变；
- 384 MiB emergency floor 不再由一个 250 ms 样本立即触发，必须连续低于该线 5 秒；
- 新增 256 MiB panic floor，低于它仍立即终止 Job；
- 1536 MiB private soft limit、2048 MiB Job hard limit、250 ms poll 和 `KILL_ON_JOB_CLOSE` 不变；
- Strict Full 完全不采用防睡眠之外的 diagnostic-only emergency debounce，最终验收策略未放宽。

新增 guard log 字段：

```text
EMERGENCY_CONFIRM_SECONDS=5
EMERGENCY_AVAILABLE_MB=384
PANIC_AVAILABLE_MB=256
SYSTEM_SLEEP_PREVENTION=SET_THREAD_EXECUTION_STATE
```
