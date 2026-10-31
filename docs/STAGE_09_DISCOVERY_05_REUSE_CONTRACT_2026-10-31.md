# Stage9 / DISCOVERY05 — 连续调用与输入重用的状态隔离调查

PROJECT_ID: `PC-BRANCH-COBOL-SIMPLIFIED-CHINESE`
日期：2026-10-31
状态：实现测试及 CI gate，Native 待查；不得预设任何 production bug。

## 前置门
Stage8/DISCOVERY04 在 GnuCOBOL 3.1.2 的 run 41187120199，原始源码 SHA `eaeb149dd63aa32750098e9d333dcd12f451f57a` 上通过：9/9 CI jobs、8/8 alias cases、0 unexpected、heap 0。发现结论 `NO_DEFECT_REPRODUCED` 仅适用于该矩阵，不要求 PATCH04。Stage7/PATCH03 既有 production 路由保持不变；不得声称五字段算法已完工。

## 新问题与边界
调查同一对 caller-owned BigInt 输入在**不释放、不重新解析输入**的条件下，连续经过三次 `MONSTER-DISTANCE/DISTANCE-PATCH` 调用是否保持无状态、精确结果、不修改输入，并且每次独立产生的输出可以被安全释放。此研究不同于 Stage8 的同地址输入/输出别名调查。输出必须初始为空；每次调用后只释放当前输出，三次之后再释放两个输入。禁止以生产函数计算 oracle、禁止浮点、禁止生成无界随机数据。

输入组（每组复用相同 BigInt 两端对象 3 次，一共 12 次独立验证）：
1. c=-2, t=2，oracle = 5；
2. c=0, t=0，oracle = 1；
3. c=-10^63, t=+10^63，oracle = `2` + 62 个 `0` + `1`（十进制 2*10^63+1）；
4. c=7, t=3，oracle = 5（反向顺序也必须规范化为正距离）。

每次需检查 status=0、路由 message=`PATCH03:DISTANCE-PATCH`、输出经独立 `TO-TEXT` 与 oracle 十进制字符串完全一致、两个输入的 sign/count/head/tail 未改变、输出释放成功及输出 slot 清空。全部结束后 `HEAP-LIVE=0`。Native 计数 `STAGE9_RUNS=12`、`STAGE9_PASS=12`、`STAGE9_UNEXPECTED_FAILURES=0`、`STAGE9_HEAP_LIVE_POST_RELEASE=0`，并输出固定 `RESULT=PASS_STAGE9_REUSE_DISCOVERY_NATIVE`。

## 安全与验收
- 单独的 `test/stage09_discovery_tests.cob`；不得改变或替换已有 Stage8 案例，也不得更改生产代码；fixture 由本合同独立定义。
- canonical workflow 新增独立 Stage9 job，Linux GnuCOBOL 3.x，严格 `-Werror`；编译上限 300 秒、执行上限 120 秒；保存 stdout/stderr 与 SHA，失败亦保存 artifact。
- 只有当 verify + Stage1–8 回归 jobs、Stage9 Native job `completed/success`、完整日志签名和所需内存不变量同时成立，才可关闭 Stage9。
- 若发生实际不一致，保存最小重现对、循环序号、实际值、预期值、状态码和 call/log；在真实结果前不得命名 EXPECTED_RED 或开始 PATCH04/05。若 12 次全部正确，结论只能是 `NO_DEFECT_REPRODUCED_IN_TWELVE_CALLS`，下一候选应继续独立调查。
