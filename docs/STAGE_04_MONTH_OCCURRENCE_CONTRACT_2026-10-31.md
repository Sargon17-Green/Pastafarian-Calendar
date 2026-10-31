# 第 4 階段：有界月份索引／月內日投影契約（2026-10-31）

專案：`PC-BRANCH-PERL-GUOYU`；分支：`Perl+國語`。第 3 階段已驗收，最後完成階段保持 `3`。

## 規範根據與技術選擇

直接檢查本分支 `t/lib/Pastafari/NormativeScroll.pm` 的 `calendarDate`：
規範日期精確五欄為 [年數、肉排名稱、肉排內日數、月份名稱、月份內日數]。
規範從年份完整交織序列位置 `offset` 取得月份索引 `monthId`；
月份內日數是包含目前位置的該索引前綴出現次數。
第 3 階段 `WeavingPrimitive.pm` 僅能還原至多 6 月、24 日的完整交織。

第 4 階段選擇**不自行產生年份與月份**，只以已驗收的有界排名原語建立
第四欄名稱映射前的月份索引和第五欄月份內日數投影。
這是規範來源的**局部語意**，不是五欄的正式完整計算。

## 精確 API

生產：`lib/Pastafari/Monster/MonthOccurrence.pm`，
`month_occurrence($lengths,$rank,$position) -> { monthIndex => Int, dayInMonth => Math::BigInt }`。
`position` 為**一基**年內序列位置，`rank` 為 Stage3 的一基交織排名。
輸入長度須符合 Stage3：1..6 個月份，每個月正整數，總日數 <=24。
令 `w=unrank_weaving(lengths,rank)`，`j=w[position-1]`；
則 `monthIndex=j`，`dayInMonth = |{ k:1<=k<=position, w[k-1]=j }|`。
輸入不可變，回傳 BigInt 不共享可變狀態。
非法配置、排名、位置零／負數／超界／型別錯誤必須拒絕。
不映射自然語言月份名稱；不啟動或繞過 Calendar 的五欄入口；不依賴 `t/lib` 在生產。

## Oracle、資源及驗收

獨立 `t/49_stage04_month_occurrence.t` 由固定長度 m 的基數枚舉生成所有 `m^D`
完整字串，**只在**生成整串才驗證月份個數、首次及最後出現的升序。
預期索引／第幾日由獨立前綴計數產生；比對生產投影對每個合法字串的
每個位置，至少 100 組；含大邊界 24 日、錯誤輸入、不變性。
這個 oracle 沒有調用生產 DP 或直接借用 Stage3 反排名來產生期望值。
大案例僅往返／不變量，不做年規範 oracle。

Native/CI 同一個 source SHA：Perl >=5.40，UTF-8，語法、測試單獨
`prove -e 'perl -CS -Ilib -It/lib' t/49_stage04_month_occurrence.t`，
stderr 空、exit 0；外部 `timeout 120s` 和 `ulimit -v 393216` (384 MiB VSZ)。
並結合 `perl-stage01`, `verify`, Stage2/Stage3 regression 的適用閘門。
原始 stdout/stderr/exit/source/runtime/artifact 留證據。未有 completed/log 全部通過前，
保持 `CURRENT_STAGE=4`、`LAST_COMPLETED_STAGE=3`，禁止 Stage4 PASS。
排除全年 47 月、完整 canonical five-component oracle、Soak；不可 merge/main。
