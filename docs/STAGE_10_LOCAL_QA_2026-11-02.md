# 第 10 階段本機獨立驗證（2026-11-02）

唯一分支：`Perl+國語`。前一階段已驗收；本紀錄只證明第 10 階段**本機**測試，並非 GitHub Actions Native／CI 驗收。

- 生產模組：`lib/Pastafari/Monster/DistinctNameAssignment.pm`；Git blob：`0e05a8a3678c1271a4dedaa3026af6b3b0334828`。
- 獨立 Oracle：`t/55_stage10_distinct_name_assignment.t`；Git blob：`76c4fb2e41459a2355b54902641cd17adfad1c64`。
- 本機版本：Perl v5.40.1；兩份檔案 `perl -Ilib -c` 均 `syntax OK`。
- 有界執行：`ulimit -v 393216` KiB；`timeout 120s`；`prove -e 'perl -CS -Ilib' -v t/55_stage10_distinct_name_assignment.t`；退出碼 0，stderr 0 bytes，`Files=1, Tests=16256`、`Result: PASS`。
- Oracle A：`STAGE10_INDEPENDENT_ENUMERATED=16064`、`STAGE10_INDEPENDENT_FAMILIES=28`，完整對比 1..7 的各種排列。
- Oracle B：`STAGE10_LARGE_RANK_CASES=20`，17/47 種目錄大小的直接乘積計數及逆向排名。
- 無效輸入、越界、大數及呼叫間可變別名的測試包括在 16256 筆 TAP 中。
- Canonical workflow 已增設獨立 Stage10 job；結果須在同源 commit 的 completed/log/artifact 證據審核後另行驗收。

`LAST_COMPLETED_STAGE=9` 維持不變。完整曆法、五日期欄位、55 階段整體均尚未獲得本紀錄的驗收。不得合併 main 或對外發佈。
