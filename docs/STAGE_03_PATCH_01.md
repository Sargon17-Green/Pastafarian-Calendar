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
代码与验证已经按本阶段规定验收；这仅证明低层生产分发器 SAVE-PATCH 路径，不能冒称完整五字段日期计算。
既存 FOREIGN_LANGUAGE_USAGE 违规没有消除。

## 2026-10-30 Stage 3 Native 验收证据
- 来源 HEAD：`37c08546036a81177d3860c8560e2def4d7441dc`；独立 GitHub Actions：<https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41040504858>，4/4 jobs completed/success（verify、Stage1 Native、Stage2 Discovery Native、Stage3 PATCH Native）。
- Stage3 GnuCOBOL 严格编译成功；8 个实际 production 路由均为 `PATCH01:SAVE-PATCH`，涵盖 M、2M、3M、M+1、0、-M、-1、M-1。
- `STAGE3_PATCH_PASS=00006`；`STAGE3_CONTROL_PASS=00002`；`STAGE3_UNEXPECTED_FAILURES=00000`；`RESULT=PASS_STAGE3_PATCH_NATIVE`。
- 测试代码在全部释放后调用 `BIG-INTEGER-SERVICE/HEAP-LIVE`，仅当返回状态为零且 live allocations 为零时允许通过；该防漏断言已包含在零意外失败结果中。
- Native log artifact：<https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41040504858/artifacts/12969864067>。
- Stage2 老路径的 EXPECTED_RED 仍保留；Stage1 Native 同次回归通过。既有 `FOREIGN_LANGUAGE_USAGE` 历史违规保持不变；GCC `_FORTIFY_SOURCE` 提示未被掩盖。
- Stage 3 本范围验收完成，`LAST_COMPLETED_STAGE=3`。Stage4/DISCOVERY02 的具体缺陷、预期红灯及对照场景未在此分支阶段契约中明确；不凭空开工或称 Stage4 GREEN。
