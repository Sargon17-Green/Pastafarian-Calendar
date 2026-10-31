# 第 7 階段：已生成年度結構的五欄日期組裝契約（2026-10-31）

專案 PC-BRANCH-PERL-GUOYU；唯一工作分支 Perl+國語。
依據：本分支 `t/lib/Pastafari/NormativeScroll.pm` 的 `calendarDate` 及 `buildYearStructure`，以及已驗收的 Stage4/5/6 契約。前一個 LAST_COMPLETED_STAGE=6，Stage7 的 Native/CI 尚未驗收。

## 為何不能直接拼接先前原語

Stage4 `month_occurrence` 只接受最多六個月、總長最多 24 日的排名反織，而實際一年為 252..5778 日、3..47 個月。不能假稱 Stage4 適用全長，亦不能把預生成的月份順序冒充規範 sauce/askBowl/chooseRank 的結果。Stage7 採取不同且明確的已具體化年度切片：接收合法年界及外部已生成的五個結構陣列，僅組裝當日五欄。沒有生成 gate、年、月、肉排、排名、nextYear 或 previousYear。

## API 和精確前提

`Pastafari::Monster::FiveFieldProjection::five_field_projection($year,$structure,$target_day)`
返回長度**恰為五**的陣列：
`[Math::BigInt yearNumber, Str cutletName, Math::BigInt dayInCutlet, Str monthName, Math::BigInt dayInMonth]`。

`year` 為單一 HASH，含 `number,openGateDay,closeGateDay`；年界採 `openGateDay < target_day <= closeGateDay`，跨度 252..5778。整數為正規十進位純量或 Math::BigInt，不接受前導零、非法類型、空值和小數；可用負數年及負數絕對日。

`structure` 為 HASH，必有以下 ARRAY：
- `cutletPartition`：6..17 個正整數區段長，總和等於年跨度；
- `cutletNames`：相同個數、無重複的 1..17 凍結目錄索引；
- `monthLengths`：3..47 個 4..123 日的月份，總和等於跨度；
- `monthNames`：相同個數、無重複的 1..47 目錄索引；
- `monthWeaving`：長度恰為跨度的一基月份索引序列，各月出現次數匹配 `monthLengths`，首次及末次出現的位置都依月份編號嚴格遞增。

生產程式重用 Stage6 `year_occurrence` 的年界與年份編號語意、Stage5 `cutlet_occurrence` 的區段與肉排名稱語意。對已具體化的月份字串，獨立計算目標位置以前含自身的月份前綴次數，並以凍結目錄映射名稱。這不是擴大 Stage4 DP 的契約，也不是聲稱 Stage4 的完整年長排名已通過。

輸入陣列和 Math::BigInt 不得修改；輸出的 Math::BigInt 皆不得別名化輸入。非法年、年份結構、月份字串及越界日必須拒絕。所有核心驗證不讀 `t/lib`，不呼叫 `calendarDate`。

## 獨立 Oracle 和邊界

`t/52_stage07_five_field_projection.t` 只使用原始目錄條目及給定固定 fixture，依各區段和月份長度**逐日擴展**肉排及月份期待欄位，不呼叫生產投影的查找、前綴計數或 Stage4 反排名。
- 252、963、5778 日：獨立擴展合計**6993** 個日位置。
- 至少 **1300** 個位置逐一比較五欄：前兩種年長全日，長年取確定性樣本、所有區段與月份邊界。
- 包含真實交織（非僅連續塊）、年開閉邊界、跨段首末日、名稱固定錨點、BigInt 複本與不變性。
- 反例涵蓋缺少陣列、總長不符、重複或超界名稱、非法前導零、非數字索引、錯誤月份次數、首次或末次順序無效及日期越界。

## Native/CI 同一來源 SHA 閘門

執行 Perl >=5.40；`perl -c` 模組及測試；`prove -e 'perl -CS -Ilib -It/lib' -v t/52_stage07_five_field_projection.t`。
Stage7 job 使用 `timeout --signal=TERM --kill-after=5s 120s` 與 `ulimit -v 393216`（384 MiB **虛擬記憶體**，非量測 RSS）。
驗收需 exit=0、空 stderr、Result PASS、至少 8600 TAP assertions、expansion=6993、compared>=1300；保存 source.txt、perl-version.txt、syntax.stderr、test.stdout、test.stderr、test.exit、result.txt 為 artifact。
另需同一 SHA 的 canonical workflow 八個 job completed/success：verify、perl-stage01、Stage2..Stage7 各自 Native。核對 jobs/logs/artifact、原始碼 SHA、資源界限後，方可更新 LAST_COMPLETED_STAGE 為 7。queued/in_progress 不能等於 PASS，亦不等於阻塞。

## 尚未涵蓋的工作

沒有對 `year5000`、`nextYear`、`previousYear`、`sauce`、完整年長月交織的 rank/unrank 或 `buildYearStructure` 自行生成結果給予整體 PASS。此 stage 驗證**已提供之合法年度結構的五欄投影**，並非整套 Pastafarian 日期產生器驗收。不可 merge/main 或公開發布。
