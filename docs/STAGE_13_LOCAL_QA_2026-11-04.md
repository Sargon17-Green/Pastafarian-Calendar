# 第 13 階段本機實作與 QA（2026-11-04）

專案 PC-BRANCH-PERL-GUOYU；工作分支 `Perl+國語`。此紀錄描述本機完成的有界測試，**不代表 Stage13 已獲 Native/CI 驗收**。

採用新模組 `lib/Pastafari/Monster/StreamDistinctNameMaterialization.pm`，僅依賴 Stage12 已驗收的 `select_distinct_name_indices`，並安全映射呼叫端提供的目錄；沒有正規名稱的硬編碼。測試 `t/58_stage13_stream_name_materialization.t` 採用獨立 DFS 和 BigInt 逆向排名 oracle，不引用 Stage10–12 producer 來產生預期結果。

本機 Perl v5.40.1。三個既存依賴從 Stage12 接受來源逐字確認 Git blob SHA：`DistinctNameAssignment.pm=0e05a8a3678c1271a4dedaa3026af6b3b0334828`；`StreamRankSelection.pm=27674ea969c5e04e3f1a389755d201baccadd7e3`；`StreamDistinctNameSelection.pm=26aab00bf463c2f6435aa152dfbc2cb868c9b5fa`。新生產模組本機 blob `a9c1a8e87a5b3729ecae962d0ea60eb5f46c7459`、測試 blob `c99a7f2d42390833e6b6bb86929163b0802eaa7b`；均已與存入 GitHub blob API 的 SHA 完全一致。

2/2 Perl syntax OK。使用 `ulimit -v 393216` KiB、`timeout --signal=TERM --kill-after=5s 120s` 及 `prove -e 'perl -CS -Ilib' -v`：`Files=1, Tests=4973`，`All tests successful.`，`Result: PASS`，exit 0，stderr 0 bytes，牆鐘約 4 秒。獨立枚舉 4730、21 families、40 boundaries、17 invalid；輸入和回傳不共享檢驗均通過。這是**局部測試**，未執行新增來源完整 109 個檔的本機套件，也沒有 Native 新來源的 CI 結果。

下一步：在新 HEAD 上等待 canonical run 完成，再核對全部 14 必需工作及 Stage13 七件原始 artifact；若有真實失敗，僅修復證明的原因，禁止重跑已通過的舊 SHA。LAST_COMPLETED_STAGE=12，正規名稱目錄和完整年曆未驗收。
