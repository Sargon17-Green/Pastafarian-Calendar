# 第 6 階段：有界年份編號投影契約（2026-10-31）

專案：PC-BRANCH-PERL-GUOYU；唯一工作分支：Perl+國語。

## 規範根據與選擇

直接檢查本分支 t/lib/Pastafari/NormativeScroll.pm 的 calendarDate：
第一欄是 findTargetYear 所得年份記錄的 number；其餘欄位依序為肉排名稱、
肉排內日數、月份名稱、月份內日數。

Stage2／3 已覆蓋有界月份交織計數、排名及反排名；Stage4 已覆蓋月份索引
與月內日數；Stage5 已覆蓋肉排名稱與肉排內日數。尚未被獨立投影測試的
局部語意是：在已建立的連續年份區間中，依目標日選出第一欄的年份編號。
因此 Stage6 選擇年份編號投影，而不複製 year5000、nextYear、
previousYear 或 sauce 的年份生成程序。

## API 與輸入／輸出

生產模組：lib/Pastafari/Monster/YearOccurrence.pm
匯出：year_occurrence($years, $target_day) -> Math::BigInt。

years 是一至一百零一個已建立年份記錄的陣列；每筆記錄須含：
- number：有號整數年份編號；
- openGateDay：有號整數開閘日；
- closeGateDay：有號整數閉閘日。

整數可用十進位整數純量或 Math::BigInt；不接受小數、非數字、前導零
或其他物件。年份編號須依序每次增加一；前一筆 closeGateDay 必須等於
下一筆 openGateDay。每個區間必須滿足 252 <= closeGateDay-openGateDay
<= 5778。target_day 為有號整數或 Math::BigInt。

回傳值是所屬年份的 number 複本，型別為 Math::BigInt。唯一所屬條件為
openGateDay < target_day <= closeGateDay。故共用閘日屬於前一年；
下一日才屬於後一年。若目標日不在所提供區間內，必須拒絕。

生產程序先驗證整個區間序列，再依 closeGateDay 二分搜尋；驗證為 O(n)，
查找為 O(log n)。不得修改輸入陣列、記錄或 Math::BigInt，也不得讓輸出
與輸入共享可變數值。生產模組不得載入 t/lib 的規範參考。

## 獨立 Oracle 與測試

t/51_stage06_year_occurrence.t 不使用生產二分搜尋。測試端把各年份區間
逐日展開成日期至年份編號的對照表，再對每個日期比較生產結果。
三個區間長度為 252、963、5778 日，合計 6993 個獨立日位置；
年份編號跨越 -1、0、1。另測試一百零一筆區間上限、首末邊界、
共用閘日歸屬、BigInt、不變性，以及缺欄、型別錯誤、非連續年份編號、
間隙、重疊、反向、超短、超長和區間外日期。

## Native／CI 驗收

在同一來源 SHA 上，canonical-names-lock workflow 必須通過：
- verify；
- perl-stage01 全量測試及語言／隔離稽核；
- Stage2、Stage3、Stage4、Stage5 Native 回歸；
- stage06-year-occurrence-native。

Stage6 Native 使用 Perl >=5.40，檢查模組及測試語法，執行
prove -e 'perl -CS -Ilib -It/lib' -v t/51_stage06_year_occurrence.t。
要求至少 7000 TAP assertions、獨立位置標記恰為 6993、退出碼 0、
stderr 為 0 bytes，並使用 timeout 120s 與 ulimit -v 393216
（384 MiB 虛擬記憶體上限，不是峰值 RSS 測量）。保存來源 SHA、
Perl 版本、syntax.stderr、test.stdout、test.stderr、test.exit 及 result.txt
為 GitHub Actions artifact。

只有全部必要工作 completed/success，且 Stage6 artifact 的來源 SHA、
TAP、stderr、退出碼與資源限制均核對完成，才可將 LAST_COMPLETED_STAGE
更新為 6。在此之前 CURRENT_STAGE=6、LAST_COMPLETED_STAGE=5。

## 範圍排除

本原語只投影已提供年份記錄中的第一欄；不生成 gate、不執行
year5000／nextYear／previousYear、不調用 calendarDate，也不計算其他四欄。
因此不構成完整五欄日期或全年曆法 PASS。不得 merge main 或發布。
