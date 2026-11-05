# 第 15 階段：正式名稱與已具體化五欄投影之整合探索契約（2026-11-06）

專案：`PC-BRANCH-PERL-GUOYU`；工作分支 `Perl+國語`；Stage14 已在 source `79b159ab0a47ebfd2d95baf60bf5f41f2b60e17a` 的 canonical CI 15/15、285 TAP、ZIP SHA256/CRC 與精確 source 之證據下驗收。**本文件為 Stage15 DISCOVERY／可執行驗收契約，不是實作、測試通過或 Native PASS。**

## 為何選此最小獨立步驟

Stage07 的 `five_field_projection(year,structure,target_day)` 已可將外部提供的合法年度五陣列投影為五欄，但要求 `cutletNames`、`monthNames` 是凍結目錄的一基索引。Stage14 `select_canonical_names(kind,first,direction_step,count)` 輸出正式名稱**文字**。因此下一步限定為將兩個已驗收介面連接，產出具有正式來源名稱的五欄，不自行生成年份、閘門、區段長度、月份長度或交織順位；禁止用翻譯文字取代正式 index 的排序語意。

## 擬定生產 API 與界限

新增 `Pastafari::Monster::CanonicalFiveFieldProjection::project_with_canonical_names(year,base_structure,target_day,cutlet_first,cutlet_step,month_first,month_step)`。
- `year` 保持 Stage07 的 `{number,openGateDay,closeGateDay}` 精確規則（`open < target <= close`、跨度 252..5778、Math::BigInt 不可變）。
- `base_structure` 為 HASH，**只**包含 `cutletPartition`、`monthLengths`、`monthWeaving`；不得含任一名稱陣列，以避免兩套真相。區段數 6..17，月份數 3..47，其餘完整合法性由 Stage07 驗證；所有陣列不得變動。
- `cutlet_first/month_first` 是 Stage14 正規流 1..M（`M=2^127-1`），`cutlet_step/month_step` 各是 ±1。選取數量由合法區段數與月份數決定；不接受呼叫者指定另一數量。
- 以 Stage14 為兩種目錄取得選中**文字**。以 Stage01 當前正式凍結目錄 `canonicalIndex=1..n` 建立字串到一基索引的唯一映射，驗證來源語言／版本／17 與 47 個條目，拒絕重複、空白、錯誤版本或找不到的文字。映射只供 Stage07 使用，**不得**使用 Unicode 正規化、翻譯或字母排序。
- 把新建的 `cutletNames`、`monthNames` 索引陣列與**複本**基底欄位組成一次性結構，呼叫已驗收的 Stage07 `five_field_projection`，回傳與 Stage07 相同型態的五欄 ARRAYref `[Math::BigInt, Str, Math::BigInt, Str, Math::BigInt]`。不共享輸入或返回陣列的可變參照。
- 拒絕一切不合法年份、年跨度、區段、月份、交織、流指標、步幅、型態及邊界。不得載入 `t/lib` 作生產依賴。

## 自主 oracle、測試及失敗條件

建立 `t/60_stage15_canonical_five_field_projection.t`；由本分支 Stage01 凍結原始文字建固定的獨立預期快照，不從 production accessor 讀出預期值。用獨立 BigInt 基數展開及文字逆字典序排名算兩組名稱排列，再以**逐日展開**的部門分段與交織前綴頻數得出五欄預期結果，不呼叫生產端排名／反排名／投影作 oracle。

驗證至少三種**本分支合法**年度 fixture（252、963、5778 日）及全年開閉閘邊界；每一種涵蓋全部區段首末、各月首次末次、相鄰交織變化和確定性中段樣本。另涵蓋兩種流各自的 `first=1,2,M-1,M`、步幅 ±1、BigInt 複本、不重複文字、目錄不可變，並測試錯誤結構與錯誤流參數必然拒絕。必須在完成 fixture 和測試後**實測** TAP 數量及標記；不得預填 PASS、虛構失敗或宣稱 Stage15 Native 已執行。

## 資源與 CI 接受門檻

Perl>=5.40、原生兩個 syntax OK、限定 `timeout 120s`／`ulimit -v 393216` KiB，獨立 TAP 全綠、stderr 空、exit0、保留 source/version/syntax/stdout/stderr/exit/result 七件 ZIP。新增專屬 Stage15 job 並在**同一新 source SHA** 下驗 verify、perl-stage01、Stage02..Stage15 **16/16 必需 jobs** 全部 completed/success；讀取 16 份 raw logs，ZIP provider/upload/local SHA256、CRC 與 `source.txt` 精確對照。只有在全部完成後，`LAST_COMPLETED_STAGE=15`。Stage15 不構成完整生成器、sauce、askBowl 或 55 階段驗收。

**目前狀態：DISCOVERY CONTRACT ONLY；尚未產生 Stage15 生產模組／測試／CI job；本檔沒有 Stage15 PASS。** 不更新 main、不 merge、不發佈。
