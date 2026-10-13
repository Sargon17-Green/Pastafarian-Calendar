# 第 31 輪：不保存可由公式計算的全開狀態，擴大 322 日獨立 BigInt 字序核查

日期：2026-10-13，\`Perl+國語\` Stage 1。不可修改 \`main\`、Stage 2、正式曆法入口或 \`HANDOFF_*\`。

## 第 30 輪獨立實證

原生 CI：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38375375323

零起始索引 40..43，實際月份 \`[25,77,98,122]\` 共 322 日。
\`CANONICAL_WINDOW40_CHECK_COMPLETE passed=1 blocked=0 failed=0\`：
前沿正向狀態計數 186,325、同日最大前沿 1,898、精確總數 172 位；
另一位置多項式及磁碟串流多項式總數都一致。
無排名器的首末字序直接構造、索引式中間一基 BigInt 雙向還原
也 PASS，38.652 秒、VmHWM=29,760 KiB。
中間排名的字典序 322 次選擇**尚未**得到獨立前沿驗證。

## 精準降低記憶式狀態快取占用

既有 \`WeavingMemoOracle\` 在 \`opened==months\` 的後綴已可用
末次出現順序的精確二項式乘積公式，卻仍把每個此類狀態
放進 200,000 項上限的 BigInt 長期快取；對第 322 日視窗
造成不必要的高額記憶體與容量占用。

本輪只對 \`months>=2\` 且 \`opened==months\` 的分支
直接回傳公式結果，不記憶化這些可快速重算的葉狀態。
其餘尚未全開的狀態完全沿用舊的精確 BigInt 快取，
仍維持 200,000 項上限、獨立資料所有權和明確非法輸入拒絕。
對零／單月保留原始快取診斷契約。

\`t/55_memo_closed_form_cache.t\` 核對四種已全開前綴和
\`WeavingSuffix\` 及 \`WeavingFrontierOracle\` 的結果；
查詢前後長期快取項數不增加、BigInt 改動不會污染重查，
零／單月重查仍命中快取。

## 全長 322 日中間排名

既有獨立精確分支工具 \`profile_canonical_memo_multi_ranks.pl\`
新增 \`--window-offset 40\` 和 \`--case-filter middle\`，
僅對真正第 5000 年 322 日視窗的中位一基 BigInt：
- 獨立記憶式 Oracle 得到 172 位全局數並與位置多項式比較；
- 索引式字典序解碼生成完整 322 字序；
- 逐日枚舉所有合法下一標籤並以不共享排名器後綴程式碼的
  另一個 Oracle 精確計數；各分支和等於母前綴計數；
- 獨立扣除較小的 BigInt 分支，逐位比對解碼；
- 322 日結束時剩餘月長全 0、局部一基排名為 1，
  並由索引式正向排名完全重建原名次。

只要 185 秒、393,216 KiB RSS 或長期 200,000 狀態限制
中任一超限，就保留 BLOCKED／FAIL 原分類，不能稱 PASS。
\`[weaving-canonical-window40-middle]\` 標記獨立 CI job，
正常 56 檔全量回歸不可捨棄。
PASS 也只驗證此四月真實樣本，非全年的 45 月／4,244 日。
