# 任意精度整数

`BIG-INTEGER-SERVICE` 使用动态分配的双向链表。每个节点保存一个十进制九位块，基数为 `1000000000`。符号与块链分开保存；零使用符号 0 和空链。内部整数位数不由固定规范 bit width 限制。

支持第 1 阶段 oracle 所需的初始化、复制、比较、加法、减法、乘法、长除法/余数、欧几里得正余数、文本序列化和显式释放。

## 小整数除法

组合计数频繁需要除以不超过几千的小正整数。`DIV-SMALL` 直接逐九位块执行：

`current = carry * 10^9 + digit`

然后生成一个商块和新的余数。调用者使用的除数必须为正且小于 `10^9`。该路径不使用浮点数，也不构造除数 BigInt。

## 所有权

普通成功结果由调用者拥有。测试 oracle 可用 `ARENA-BEGIN` 建立作用域：arena 内新导出的非零 BigInt 自动登记；显式 `FREE` 会注销并释放；`ARENA-END` 回收其余值；最终需要跨出 arena 的结果使用 `DETACH`。

`ORACLE-BIGINT` 自己创建的 scalar、模数、除法余数和 `SAVE` 中间值在本调用期释放；它们不再作为进程生命周期资源保留。

## 测试可观察计数

服务维护：

- 当前活动动态块计数 `HEAP-LIVE`；
- 历史高水位 `HEAP-PEAK`；
- 高水位重置 `HEAP-PEAK-RESET`。

这些操作只服务于 ownership/stress 测试，不参与任何规范分支。

文本接口使用固定 8192 字符缓冲区，因此序列化接口有明确的文本长度上限；当前 Appendix A 计数在真实执行中仍需验证没有触碰该上限。内部链表算术本身不以 8192 字符作为整数位数模型。

## 有界 arena 子作用域（Stage 1 test oracle）

除顶层 `ARENA-BEGIN` / `ARENA-END` 外，服务现在支持嵌套 checkpoint：`SCOPE-BEGIN` 与 `SCOPE-END`。子作用域只回收其进入点之后仍登记的 BigInt，不触碰父作用域已有值。需要跨出子作用域的值先用 `DETACH`，子作用域关闭后用 `ATTACH` 重新登记到仍活动的父 arena；若当前没有父 arena，`ATTACH` 成功但不登记，值继续由普通调用者拥有。

子作用域深度固定上限为 32；超限返回状态 50。若 checkpoint 链结构不一致返回状态 51。顶层 `ARENA-END` 在仍有子作用域时拒绝执行。

## Fix 27：数值小标量通道

历史 `ORACLE-BIGINT/MUL-SMALL` 会通过 `INIT-TEXT` 先创建一个 scalar BigInt，再调用通用 `MUL`。Fix 27 保留该路径为负数或 `>=10^9` 的 fallback，但为 Stage 1 高频范围增加内部 `MUL-SMALL-N`：`LK-TEXT-LEN` 直接承载 `0..999999999`，从最低有效 chunk 向高位执行 `digit * scalar + carry`，每步按 base `10^9` 分解。结果符号继承被乘 BigInt；scalar 0 产生规范零。

`DIV-SMALL-N` 同样用 `LK-TEXT-LEN` 直接承载 `1..999999999`，复用现有逐 chunk 精确除法。这样 oracle wrapper 不再把已有机器 divisor 格式化为十进制字符串再解析。

新增 `MUL-SMALL-HITS` / `DIV-SMALL-HITS` 只读计数，只用于 bootstrap/performance 观测，不参与任何规范分支。

