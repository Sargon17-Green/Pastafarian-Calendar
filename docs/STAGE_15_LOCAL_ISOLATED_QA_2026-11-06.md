# 第 15 階段：本地隔離預檢（2026-11-06）

專案：PC-BRANCH-PERL-GUOYU；分支：Perl+國語。基底來源 787ebc7945da24d04a75c7fc39786e965f17bd70；最後正式驗收階段：14。

本階段已新增正式五欄投影組合器、固定字面錨點的獨立日展開 oracle 測試，及獨立 canonical Native CI job。**這份記錄只描述本地隔離環境，不宣稱實際來源相依模組完整通過。**

- 本地 Perl 5.40.1；產生與測試模組 syntax OK 2/2（載入隔離替身相依模組）。
- 使用明示的 mock/stub 來源目錄、Stage14 選名與 Stage07 投影相依模組；不是完整分支 checkout、不是既有 Stage07/Stage14 產品模組之端到端驗證。
- 隔離 `prove -e 'perl -CS -Ilib' -v`：14320/14320 TAP，Files=1，stderr 0、exit 0，約 10 秒；資源上限 393216 KiB、timeout 100s。
- 獨立 oracle：6993 年日展開、1585 日五欄比較、24 個串流邊界組合、28 個非法輸入拒絕；年度 fixture 長度 252、963、5778。
- 生產原始檔 Git blob: `f7d6ce5fb54baeded0d8be01aa03453738ade2ae`；測試原始檔 Git blob: `d1c391c6d2cf9648b0a038af188773e510d87209`；均已與本地 git hash-object 比對。

待驗收：在同一新 source SHA 上等待 canonical push CI，確定 16/16 mandatory completed/success；讀取全部 16 個原始 logs、Stage15 原生測試數量與獨立標記、7 個 ZIP 內容、SHA256(供應者/上傳/下載)、CRC、source.txt、語法、stderr 與 exit。直到此時 **LAST_COMPLETED_STAGE=14**；不得聲稱 Stage15 PASS 或完整年度生成器 PASS。
