# 第 48 輪：拆分 236 日真正四月份第三日的 BigInt 正向前沿驗證

日期 2026-10-16。僅在 Perl+國語 Stage 1 工作。
禁止修改 main、正式曆法算法、Stage 2 或 HANDOFF 包。

第 47 輪 CI https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38897483824
的獨立第三日工作在 185.013 秒硬界線上
\`CANONICAL_WINDOW41 status=BLOCKED reason=TIME_LIMIT\`，
RSS 約 30 MiB。當時全球 236 日 125 位 BigInt 正向前沿
與常駐、磁碟串流兩種多項式均吻合，沒有發現算術反例。
必須保留原失敗歷史，不能報稱 Round 47 全 PASS。

本輪保持 185 秒和 393216 KiB RSS 單進程界線，
改為五個獨立 GitHub opt-in 工作。每個都錨定 Year 5000
的完整 45 月/4244 日 SHA-256、取真實零起始第 37..
40 四月份 [83,88,40,25]，先各自核對全局精確 BigInt
計數、三個總數引擎、首末字序和中間索引雙向排名。

四個指定前綴
  1. parent = [1,2]
  2. 1 = [1,2,1]
  3. 2 = [1,2,2]
  4. 3 = [1,2,3]
分別在專用子程序以 \`countWeavingsFrontier\` 計算，
並和同一不可變提交中另一 \`countWeavingSuffixFactored\`
後綴精確 BigInt 核對；不能用因子後綴代替獨立前沿。

第五個 assembly 工作從四個精確因子後綴求
N([1,2,1])+N([1,2,2])+N([1,2,3])=N([1,2])，
由中間一基全球 BigInt 減去先前已通過的較小第二日
區段，獨立選出第三日，再與索引反排名的第 2、3
字元比對。四個分片及整合工作只有在**全部**成功
時才形成可傳遞的獨立前沿分割證據；
任一 FAIL、BLOCKED、取消都表示第 48 輪未完成。

新增 \`--third-day-target parent|1|2|3|assembly\`，
只准明確使用 window-offset=37，不能跟昂貴的
\`--third-day-partition\` 或第 46 輪第二日分割同跑。
既有歷史工作和其 BLOCKED 記錄不改、不刪。
新增 \`t/64_quad_third_split_ci_contract.t\` 確保所有
五個 opt-in CI 工作恰好一次、沒有放寬資源界線。

提交標記 \`[weaving-window37-third-split]\`。
每個工作子程序 185 秒、RSS 393216 KiB、
外層 260 秒、磁碟索引單檔 16 MiB。
必須五份工作、verify 和一般 65 檔 Perl
全部由原生 CI 證實 PASS 才算完成第 48 輪。

即使全部成功，只獨立檢驗了 236 天中的第二、
第三天，並不是整個 45 個月 4244 天的全年
BigInt 字序核對或跨實作 Soak。
