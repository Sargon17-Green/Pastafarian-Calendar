# 第 10 階段：不重複名稱索引序列生成契約（2026-11-02）

專案：`PC-BRANCH-PERL-GUOYU`；唯一工作分支：`Perl+國語`。第 9 階段來源 `f721156edd1b949980e00312b68f627a0cbe98de` 已由 [Native／CI 驗收紀錄](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/c77fafcd1509837a6ded9f865cedb989f90b433a/docs/STAGE_09_NATIVE_CI_ACCEPTANCE_2026-11-02.md) 接受。第 10 階段僅為已開立、**尚未實作及尚未驗收**之契約。

## 規範依據與範圍

同一 Perl 分支 `t/lib/Pastafari/NormativeScroll.pm` 的 `fallingFactorial(n,k)`、`unrankDistinctIndices(n,k,rank1)`，以及 `buildYearStructure` 中：
- 肉排名稱：17 個正式名稱索引選 K 個互異項；K 由有效肉排段數決定，通常 6..17；
- 月份名稱：47 個正式名稱索引選 K 個互異項；K 由合法月份數決定，通常 3..47。

本階段只輸出 **無重複正整數名稱索引序列**；不執行 `sauce`、`askBowl`、`chooseRank`、正式文字名稱轉換、cutlet 分段、month length、weaving、全年構造或五日期欄位。輸入排名由呼叫端提供，避免將排序生成與隨機選取混合。

## 獨立生產 API

模組：`Pastafari::Monster::DistinctNameAssignment`；匯出 `distinct_name_family($catalog_size,$selected_count)`。兩參數為無前導零的正整數十進位純量或 `Math::BigInt`，`1 <= selected_count <= catalog_size <= 47`；支援 1..7 的小型 oracle 域及 17/47 的實際名稱目錄。拒絕零、負數、非整數、前導零、空字串、NaN、超界值及其他參照類型。不得改變任何輸入 BigInt。

返回新 `HASH`，恰含 `count => CODE`、`unrank1 => CODE`：
- `count->()` 每次返回全新 `Math::BigInt`，等於 (P(n,k)=n!/(n-k)!)；
- `unrank1->($rank)` 接受標準正整數十進位純量或 `Math::BigInt`，限制 `1 <= rank <= P(n,k)`，輸出全新 ARRAY，含 k 個不同的 1..n 索引，採**一基詞典序**；
- 所有回傳值與前次呼叫均無可變別名；檢查錯誤時不部分修改輸入。

生成演算法：對零基排名 `q=rank-1` 與位置 `i=0..k-1`，從尚未使用的升序索引集合中取 `floor(q/B_i)` 所指項；`B_i=(n-i-1)!/(n-k)!`，然後令 `q=q mod B_i`。所有階乘、除法與餘數以獨立 `Math::BigInt` 複本計算；不使用規範實作逐候選減法循環，也不複製其他分支的程式、測試或固定向量。

## 獨立 Oracle、界限及品質門

**Oracle A（遞迴完整枚舉）**：對 `n=1..7` 的每個 `k=1..n`，以獨立回溯方式從尚未使用的值逐層生成所有序列，直接與每一合法 `unrank1` 結果依序比對。全域應有恰好 **16,064** 個逐排名序列比對；不呼叫生產階乘或規範 `unrankDistinctIndices`。

**Oracle B（逆向排名）**：由已回傳序列獨立累加每位置小於當前索引的可用項數，乘以尾部可用位置數的直接逐項乘積，重建一基排名；對 `n=17,k=6/17` 及 `n=47,k=3/47` 的首、第二、中位、倒數第二、末名次交叉檢查。獨立計數 Oracle 直接相乘 `n(n-1)...(n-k+1)`，與生產者階乘商比較。測試 47! 大數、變更 `count` 複本後仍不影響下次呼叫、跨呼叫陣列獨立性、非法與超範圍排名、輸入 BigInt 不變性。

**Native／CI**：使用 Perl>=5.40；`perl -Ilib -c` 模組和測試皆 syntax OK；`prove -e 'perl -CS -Ilib' -v t/55_stage10_distinct_name_assignment.t` 必須 exit 0、stderr 空、`All tests successful.`、`Result: PASS`、測試記號 `STAGE10_INDEPENDENT_ENUMERATED=16064` 和大排名測試數。限制 120 秒 timeout、384 MiB 虛擬位址空間。工作須獨立接入 canonical CI，保存 `source.txt`、`perl-version.txt`、`syntax.stderr`、`test.stdout`、`test.stderr`、`test.exit`、`result.txt`；審查同一來源 SHA 全部必要 jobs、直接 job logs、ZIP SHA256／CRC。僅 completed/success 可作驗收；queued/in_progress 不算 PASS 亦非阻塞。

第 10 階段驗收前必須維持 `LAST_COMPLETED_STAGE=9`。完整年份、閘、sauce、名稱文字、日期五欄、全 55 階段均**未**因本契約而取得驗收。無 main、merge 或對外發佈。
