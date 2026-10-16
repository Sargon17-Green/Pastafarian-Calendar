# 第 45 輪：真實第 5000 年另外三組分散四月份的精確總數

日期：2026-10-16。限定 \`Perl+國語\` Stage 1，不修改 \`main\`、日曆算法、Stage 2 或 \`HANDOFF_*\`。

## 前置證據與未完成工作

第 41 輪的全部 43 個真實三月窗口三種全長 BigInt 排名 PASS：
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38586882997
第 42 輪一般 Perl 60 個測試檔、88,179 斷言 PASS：
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38589988538
第 44 輪 opt-in 的 11 組三月補充排名工作均 PASS：
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38892336324
但該次整個 workflow 結果為 \`cancelled\`，因為普通 \`perl-stage01\` 工作遭到取消；同一 HEAD 的該單獨工作已提出重跑，必須等待完成，不得把取消記作 Stage 1 全套 PASS。

## 新增三組分散的四月窗口

以已經固定 SHA-256 的 Year 5000 四十五個月、4244 日為來源；
挑選不同地區和形狀的四個相鄰月份：

| 零起始月索引 | 長度（日） | 合計（日） |
| --- | --- | ---: |
| 10 | 98,52,81,97 | 328 |
| 28 | 55,119,97,50 | 321 |
| 36 | 101,83,88,40 | 312 |

保留原 \`tools/profile_canonical_window41_count.pl\` 對
\`[77,98,122,105]\`（索引 41，402 日）之預設語義與完整工作歷史。
新增可明確要求的 \`--window-offset\`，只允許 10、20、28、36、41，
每組均將原始年份指定窗口的四個月長再和另一組明文數值比對。
20 僅列為往後待試，這次未安排執行，不能宣稱已通過。

三個 opt-in 工作由提交標記 \`[weaving-quad-distributed]\`
觸發，對每組分別驗證：
1. \`countWeavingsFrontier\` 的正向合法狀態 BigInt 精確總數；
2. 常駐位置多項式及逐行磁碟串流位置多項式總數，三者必須完全一致；
3. 以不依賴 DP 的直接連續月塊與倒序最大合法候選分別
   構造首名和末名字序，並與索引反排名相等；
4. 中間一基 BigInt 的索引式反排名與正向排名完全往返，
   所得全部日位次的月長、首次、末次次序均合法，且輸入 BigInt 未污染。

**重要限制**：對中間名的「全字序」依然是多項式同族排名器
之正反往返，前沿 Oracle 此處只對精確 **總數** 獨立。
不能稱為「中間名每一日都有獨立前綴 Oracle 對照」。
前幾輪三月核查的更強宣告不能誤轉移至這三個四月窗口。

每工作子程序上限 185 秒、393216 KiB Linux RSS，
外層 260 秒，單一索引檔最大 16 MiB。
超額時嚴格 \`BLOCKED\`，不允許記作 PASS。
新 \`t/61_quad_distributed_coverage.t\` 在全量一般 Perl CI
直接驗證三份 opt-in job、月份下標、Year 5000 的 SHA、
全部原有資源界線及預設窗口 41 的不變性。

必須在三個受控工作和 61 個一般 Perl 測試檔及 verify
全部原生 PASS 才算完成第 45 輪。
依然不是 45 月／4244 日整年全域 BigInt 字序驗證或跨實作 soak。
