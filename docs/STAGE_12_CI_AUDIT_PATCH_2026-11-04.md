# 第十二階段 CI 稽核回歸修復（2026-11-04）

專案：PC-BRANCH-PERL-GUOYU；唯一工作分支：Perl+國語。此文件記錄精確失敗與有界修復，不代表 Stage12 已獲整體驗收。

## 來源與已完成實驗

Canonical push run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41712689426 在 source 07ffbd87ea86e19b1fc61dd047dd5473fb1fe4b5 上 completed/failure，attempt 1。共 159 jobs，其中 13 必需：verify 及 Stage02–Stage12 共 12 個 success、perl-stage01 一個 failure；其餘 146 skipped。已查看 13 個必需 job 原始日誌。perl-stage01 job 126184557884 的完整 prove 輸出為 Files=108、Tests=175648；只有 t/05_language_and_isolation_audit.t 第 7 項失敗，其餘 107 個測試檔皆 ok。失敗是明確的資料／稽核契約不一致，不是計算階段的 oracle 反例。

失敗的舊斷言強制 GITHUB_ACTIONS_PERFORMED=NO；然而 DEVELOPMENT_STAGE.md 在此 source 寫有 YES，且第 11 階段確有經驗收的 canonical CI 執行和原始產物。因此把 YES 改回 NO 會失真；應修正過時的斷言。

Stage12 native job 126184574152 completed/success：Perl v5.40.5，兩個 syntax OK，5012/5012 TAP、4730 獨立枚舉、21 families、48 boundary cases、14 invalid cases；test.exit=0、test.stderr 為空。原始七件 ZIP https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41712689426/artifacts/13269031332 長 15445 bytes，SHA256=d6620c102e23d3b18a0e511313b65cf53751eb3dba9007798495956378256a68，與 GitHub metadata 和上傳日誌一致；CRC 全部正常，source.txt 與上述 source 相同，result.txt=STAGE12_NATIVE_PASS=1。這僅是 Stage12 單獨 Native PASS，非 13/13 整體 PASS。

## 最小修復及獨立回歸檢查

只修改 t/05_language_and_isolation_audit.t 的第七項：值 NO 仍是合法狀態；值 YES 則必須在 docs/STAGE_*_NATIVE_CI_ACCEPTANCE_*.md 中找到同一倉庫的具體 GitHub Actions run URL、artifact URL 和完整 40 位來源 SHA。未宣告、非法值或缺少接受證據時明確 FAIL。其餘七項（語言隔離、規範隔離、來源目錄、跨實作禁令、Git 歷史）不放寬，總項數仍為 8。

本地 Perl 5.40.1、隔離的最小原始檔案／階段狀態／CI 證據 fixture：舊斷言在真實 YES 狀態下 7/8；修復後同樣狀態 8/8；刪除 CI 接受記錄 7/8；將旗標改為 BAD 7/8；合法歷史 NO 為 8/8。此為有界稽核測試，**未執行 108 檔完整本地套件**，也不可取代整體 Native CI。此修復不更改生產算法、Stage12 oracle、canonical 工作流程或歷史驗收狀態。

## 後續接受閘門

對修復後**新 source SHA** 查看 canonical push run：13/13 必需 job 必須 completed/success；逐一檢查 13 份日誌、Perl 版本、Stage12 5012 TAP/獨立 oracle/輸出標記、exit0、stderr0 和 120s/384MiB，下載 Stage12 的原始 ZIP 並核驗 provider SHA256、CRC、七件內容及新 source.txt。未滿足前 LAST_COMPLETED_STAGE=11，Stage12 不得 ACCEPTED。不得 main、merge 或發佈。
