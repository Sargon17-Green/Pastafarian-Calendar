# 第 2 階段合約缺口檢核（2026-10-30）

專案：`PC-BRANCH-PERL-GUOYU`，分支：`Perl+國語`。本文件是針對既定 NEXT 的範圍審查，不是第 2 階段實作、不構成階段驗收或授權限制。

## 已核實的起點

- 查驗時的分支 HEAD：`b47eb3e2f36b1e2f67a636912d4664d12772e9a0`。這是本文件建立前的 HEAD，不得在後續當成永久的最新 HEAD。
- `DEVELOPMENT_STAGE.md` 明列 `TOTAL_STAGES=55`、`CURRENT_STAGE=1`、`CURRENT_KIND=BOOTSTRAP`、`LAST_COMPLETED_STAGE=1`，但沒有第 2 階段的類型、輸入輸出、修改範圍或驗收測試。
- `README.md` 及 `docs/ARCHITECTURE.md` 將第 1 階段生產端限制為中立骨架；完整規範參考位於 `t/lib`，不可由生產模組載入，亦不可作為回退的曆法答案。
- `SPAGHETTI_DEVELOPMENT_HISTORY.md` 只記錄第 1 階段的 Bootstrap。已查閱的 `docs` 目錄沒有第 2 階段合約文件；`MANIFEST_STAGE_01.txt` 是第 1 階段清單，不是後續階段的規格。
- 第 1 階段既有 CI 證據：原生 R75 九組、兩個雜湊種子，共 18 次成功呼叫；243 個向量；完整 Perl 測試 97 個檔案／89,620 項測試成功。後續 TAP UTF-8 修正成功，指定的 runtime `Wide character in print at` 警告數為零。這些都是**既有 CI 結果**，此次沒有重跑。
- 接受文件也清楚排除：將九組短長度測試當作完整真實年份（45 個月份／4,244 日）的證明，或直接當作跨實作差分驗證。文件對「第 1 階段已完成」的形式認定與 `DEVELOPMENT_STAGE.md` 的記號不同；不能自行推定已滿足未定義的第 2 階段進入條件。

## 未解決且不能從現有合約唯一推導的決策

1. **第 2 階段的產出究竟是什麼？**
   - 方案 A：開始獨立的生產曆法語意實作，例如明確選定五個日期分量的一個最小生產能力，並對照測試專用規範驗證。
   - 方案 B：先將某個具名、有限範圍的交織／排名原語轉成生產能力，再逐階段擴充。
   - 兩者都與第 1 階段「中立生產骨架、規範僅供測試」相容，卻有不同的 API、架構、依賴及測試。既有文件沒有指定哪一條路線，亦無法證明其他路線被排除。**這些只是待決方案，不是獲准的第 2 階段計畫。**
2. **驗收門檻與資源邊界是什麼？** 須明定第 2 階段的功能契約、測試範圍、是否需要 Native／獨立 differential 證據、時間／記憶體限制，以及哪些 CI 必須在同一 SHA 成功。不能將第 1 階段的 R75 專屬門檻自動移植到未知的第 2 階段。

## 決議與恢復條件

- 判定：**技術規格／實質設計決策缺失**；不是缺少使用者的形式性「允許進入 Stage 2」授權。既有進階授權可用，但不能取代未定義的技術契約。
- 在有確切的第 2 階段工作內容及驗收條件前，不建立虛構的 Stage 2 檔案、計算演算法、測試 PASS 或合併至 main。
- NEXT（有條件）：取得或確定第 2 階段的既存有效合約，或完成上述實質範圍及驗收選擇；然後先驗證當時的 branch HEAD，依該合約建立可測試的最小變更，執行對應測試與 CI，保存結果和 SHA。
- 本次完成的是有界的「合約是否存在」檢核，不是新一輪 R75、Native、完整差分或 Stage 2 實作。

## 既有證據

- [第 1 階段 R75 與 TAP UTF-8 驗證報告](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/b47eb3e2f36b1e2f67a636912d4664d12772e9a0/docs/STAGE_01_R75_NATIVE_TWO_SEEDS_CI_ACCEPTANCE_2026-10-28.md)
- [原生 R75 CI](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40674037609)
- [TAP UTF-8 修正 CI](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40720095572)
