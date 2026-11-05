# 第 13 階段 Native／CI 驗收紀錄（2026-11-05）

專案：PC-BRANCH-PERL-GUOYU，唯一工作分支為 \`Perl+國語\`。本文件驗收 Stage13 將 **呼叫端提供的有序唯一名稱目錄**映射成文字。這不表示 source-language 正規名稱資料或五欄日曆已由 Stage13 自身驗收。

## 可追溯的同源 CI
原始 source SHA：\`916024b0c5d3a426497da2775053503e0c8532c9\`；分支 HEAD 在驗收前由 GitHub branch 端點確認完全一致。canonical push run [41870316140](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41870316140)，attempt=1，2026-11-04T16:55:15Z completed/success，head_sha 與 source 相同。GitHub jobs 分頁兩次總共 160 項，**14/14 必需 jobs completed/success**，146 skipped；verify、perl-stage01 及 Stage02..Stage13 全部原始 job logs 已直接審閱，沒有失敗的必需 job。

必需 job IDs：verify 126715278359，perl-stage01 126715277376，Stage02 126715298019，Stage03 126715299084，Stage04 126715298629，Stage05 126715299175，Stage06 126715297906，Stage07 126715298133，Stage08 126715300657，Stage09 126715299428，Stage10 126715299871，Stage11 126715298144，Stage12 126715298355，Stage13 126715298923。

Stage01 \`Files=109, Tests=180621, Result: PASS\`；Stage13 \`Files=1, Tests=4973, Result: PASS\`。獨立 DFS 枚舉 4730、21 家族、40 邊界、17 非法案例。Stage02..Stage12 各自日誌均有專屬 TAP PASS。Stage13 job 使用 Native Perl 5.40+，\`timeout 120s\`、\`ulimit -v 393216\` KiB；VSZ 為限制，不是 RSS 峰值實測。

## 直接下載的七件原始 ZIP 證據
[Stage13 artifact 13343803596](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41870316140/artifacts/13343803596)：15,089 bytes，獨立 SHA256 \`0b359f953f428353963cedc9fa9967fb3ca21c7b90c53c25cd6b39dfa0f01eb6\` 與 GitHub provider digest、CI upload log 完全相同，ZIP CRC 7/7 PASS，恰七個成員：
- \`source.txt\`：\`916024b0c5d3a426497da2775053503e0c8532c9\`；
- \`perl-version.txt\`：\`v5.40.5\`；
- \`syntax.stderr\`：模組與測試各 \`syntax OK\`（2/2）；
- \`test.stdout\`：4,973 個 \`ok\` TAP 行，\`Tests=4973\`、\`Result: PASS\` 及全部契約所需標記；
- \`test.stderr\`：0 bytes；
- \`test.exit\`：\`0\`；
- \`result.txt\`：\`STAGE13_NATIVE_PASS=1\`。

**結論：STAGE13 ACCEPTED。** 合約範圍僅限呼叫端提供的原始文字目錄映射；Stage13 原生記錄仍寫著 \`STAGE13_CANONICAL_CATALOG_NOT_VERIFIED\`、\`STAGE13_FULL_GENERATOR_NOT_VERIFIED\`。因而允許 LAST_COMPLETED_STAGE 設為 13，進行 Stage14 的正式目錄綁定。新的 Stage14 source SHA 不能繼承 Stage13 原 source 的 Native PASS，必須重新走獨立 15/15 閘門。禁止 main/merge/發佈。
