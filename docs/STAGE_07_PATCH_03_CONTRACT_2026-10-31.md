# Stage7 / PATCH03 — 任意精度包含端点的日期距离

PROJECT_ID: `PC-BRANCH-COBOL-SIMPLIFIED-CHINESE`
前置门：Stage6 / DISCOVERY03 Native accepted，run 41179473272，
SHA 59552109347486d952d444a90b98d1c5274bf011，7/7 jobs success。

## 生产输入与输出
独立生产路由：
`MONSTER-DISTANCE("DISTANCE-PATCH", currentDay, targetDay, result, status, message)`。
输入均为调用者持有的有符号任意精度天数；输出是调用者持有的空 BigInt 结果槽。
无截断语义：
```
patchDistance(c,t) = abs(t-c) + 1
```
相同日返回 1；交换日期结果不变；极大正负输入有效。
`PATCHED-DISTANCE` 直接通过 BigInt SUB、取绝对值、INIT-TEXT("1")、ADD
完成计算，不能调用旧 day-tag、测试 oracle 或改写 `LEGACY-DISTANCE`。
成功 status=0，message=`PATCH03:DISTANCE-PATCH`；
拒绝覆盖非空输出 status=175；非法输入 sign=2 status=22；
未知 action status=20。调用者输入必须保持不变，错误路径清理临时链及不完整输出。

## Oracle 与固定见证
测试内部使用有符号偏移，独立计算 `abs(t-c)+1`，不依赖生产的标签或差值算法。
Stage6 的八个基础见证中，前五个历史缺陷转为 PATCH 成功，后三个 CONTROL 不变。
比较每个真实 production 输出的十进制值，而不是只比较成功返回码。
大数固定见证分别为 `10^63` 到 `10^63+1`、
`-10^63` 到 `-(10^63+1)`，并交换两个参数：
四次返回均须为 2。八次 occupied nonzero result=17 均须拒绝覆盖；
三个无效输入/操作（current sign=2、target sign=2、unknown action）
检查精确状态和空输出；全部值释放后 heap-live=0。

## 严格接受条件
1. 真实 GnuCOBOL 3.x 严格 -Werror 编译并执行 PATCH03 production dispatch。
2. STAGE7_PATCH_PASS=5；STAGE7_CONTROL_PASS=3；
   STAGE7_OUTPUT_GUARD=8；STAGE7_BOUNDARY_PASS=4；
   STAGE7_INVALID_REJECT=3；STAGE7_UNEXPECTED_FAILURES=0；
   RESULT=PASS_STAGE7_PATCH03_NATIVE，heap-live=0。
3. verify 和 Stage1–6 的原生回归全部 success，
   特别 Stage6 必须仍是 5 expected-red、3 control。
4. 不以 queued/in_progress 宣布 PASS；不修改 main，不完成五字段日历集成。
