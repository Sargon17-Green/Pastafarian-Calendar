# 第 3 阶段 — PATCH 01：SAVE 的零余数修复

## 规范与前提
Stage 2 DISCOVERY 01 已验收 3 个 EXPECTED_RED 和 1 个控制 PASS。
令 M=2^127-1=170141183460469231731687303715884105727。
规范要求 SAVE(x)=M 当 regularMod(x,M)=0，否则返回非零 Euclidean 余数。

## 修改
* 旧 LEGACY-OLD-REMAINDER 保留原状；Stage 2 可以继续复现红灯。
* 新的 production SAVE-PATCH 调用旧的模运算，在零余数时构造 M。
* MONSTER-BOOTSTRAP 新增 SAVE-PATCH action；无 oracle 链接。
* 仍未实现完整的五字段日期 API；不能将这个底层路径冒充为完整计算。

## 验证计划
Linux GnuCOBOL 的 Stage3 Native job 用严格编译测试 8 例：
M、2M、3M、M+1、0、-M、-1、M-1。
六个补丁边界 + 两个控制必须与规范十进制结果完全相同；
八次调用须走 PATCH01:SAVE-PATCH，回收后 HEAP-LIVE=0。
Stage1 181/181 和 Stage2 EXPECTED_RED 回归同时保持通过。

## 当前状态
代码已准备；Native CI 结果尚待确认，不能提前宣称 Stage 3 GREEN。
既存 FOREIGN_LANGUAGE_USAGE 违规没有消除。
