# 第 11 階段 Native／CI 驗收紀錄（2026-11-03）

專案 PC-BRANCH-PERL-GUOYU；工作分支 Perl+國語。此驗收僅涵蓋獨立串流排名選擇；完整五欄年曆及全部 55 階段尚未完成。

## 來源、整體 CI 與精確重試

驗收 source SHA：c2989899f1491d8591bd4f26072f8176f12bec80；驗收時分支 HEAD 完全相符。生產模組 blob 27674ea969c5e04e3f1a389755d201baccadd7e3，測試 blob 0028ca4fc7e719ebccfe8024ae06cedc15bb1248。

Canonical push run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41536821625 ，head_branch=Perl+國語，head_sha 與來源相同。Attempt 1 最終 cancelled：Stage04 job 125590672178 雖然其內部所有步驟成功、385/385 TAP 成功及 artifact 上傳完成，工作結論卻為 cancelled；其他 11 個必需 jobs 成功。因此 attempt 1 **不視為整體 PASS**。

只重試被取消的 Stage04 工作 125590672178，未重跑其餘已成功工作。Attempt 2 在 2026-11-03T20:19:35Z 為 completed/success，相同 source SHA。分頁查看 158 個 jobs：12/12 必需 jobs success，146 skipped，沒有失敗或取消。Stage04 新 job 126180381924，385/385 TAP PASS，syntax 2/2、stderr 檢查、artifact 上傳 success。已讀取初次所有 12 個必需 job 原始日誌及 Stage04 attempt 2 完整日誌。

Attempt 2 job 索引：verify 126180454306；perl-stage01 126180461929；Stage02 126180466279；Stage03 126180385448；Stage04 126180381924；Stage05 126180431735；Stage06 126180471863；Stage07 126180385829；Stage08 126180385261；Stage09 126180441874；Stage10 126180444692；Stage11 126180467918。全部 success。主 perl-stage01 為 107 files、170636 tests、Result: PASS；Stage11 為 6517/6517 TAP，6246 小模數枚舉、56 真實 M 大數獨立 oracle。

## 七件 Stage11 Native 原始證據

Artifact https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41536821625/artifacts/13183508581 下載 ZIP 37942 bytes，獨立 SHA256 = e22f4f55296e5d6d4d1149e1aecf3282f90ff8796db483fc405ef212b0683b75，與 GitHub metadata、Stage11 upload log 一致。ZIP CRC 全部 PASS，且恰好七件：
- source.txt 等於所述 source SHA；
- perl-version.txt 為 v5.40.5；
- syntax.stderr：模組及測試各 syntax OK，2/2；
- test.stdout：1..6517、Files=1 Tests=6517、Result: PASS、All tests successful、STAGE11_SMALL_MODULUS_CASES=6246、STAGE11_REAL_MODULUS_CASES=56、STAGE11_INDEPENDENT_BIGINT_ORACLE=1；
- test.stderr 0 bytes；
- test.exit 為 0；
- result.txt 為 STAGE11_NATIVE_PASS=1。

Native job 使用 120s timeout、ulimit -v 393216 KiB；是虛擬記憶體限制而非 RSS 測值。Stage11 牆鐘約 2 秒。Attempt 2 沿用成功工作，不代表再次執行 Stage11。

## 結論與 NEXT

**STAGE11 ACCEPTED**，僅涵蓋 StreamRankSelection::choose_rank_from_stream 的 M=2^127-1、1<=N<=47!、BigInt、雙方向及精確一基排名、拒絕區有界跳躍、輸入驗證、獨立 oracle。可在後續 commit 將 LAST_COMPLETED_STAGE 由 10 更新為 11；新 commit 不自動繼承相同 SHA 的 Native 完成證明。

NEXT：選擇有界 Stage12 串流排名和互異名稱索引整合；要有明確契約、獨立 oracle、Native job 和 13/13 jobs 的新來源驗收。不變更 main、不 merge、不發布；完整日曆尚未驗收。
