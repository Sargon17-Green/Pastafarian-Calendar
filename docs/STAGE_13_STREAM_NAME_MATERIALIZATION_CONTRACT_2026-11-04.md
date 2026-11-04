# 第 13 階段：串流互異名稱文字映射契約（2026-11-04）

專案 PC-BRANCH-PERL-GUOYU；唯一工作分支 `Perl+國語`。前一階段的同源 canonical run 41775860313 在 SHA `6cc8a6f85c32663e664e644544abd2ef91ce4a94` 通過 13/13 必需工作，Stage12 ZIP SHA256/CRC、七件原始證據及 5012 TAP 已核對。本階段不得把索引映射測試冒充正規名稱目錄或整個曆法的驗證。

## 範圍及決策

Stage12 已可靠輸出 `1..n` 的互異索引；Stage13 僅在最小邊界上接受**呼叫端提供**的有序、互異文字目錄，將這些一基索引映射成名稱。此選擇不引入任何新正規名稱內容、不需要解釋 frozen catalog，也不處理 sauce、askBowl、年/月/日、時區或完整五欄日曆。若未來整合需正規目錄，其來源仍須另外稽核。

## 輸入、輸出、界限

新增 `Pastafari::Monster::StreamDistinctNameMaterialization::select_distinct_names(first,direction_step,catalog,selected_count)`。第一、二、四個參數沿用 Stage12：M=2^127-1，first 為 1..M 的正規十進位數字或 Math::BigInt，direction_step 恰為 +1/-1，1<=selected_count<=47。catalog 必須是一般 arrayref，長度 1..47，每個元素是定義的非參照、至少含一個非空白字元的文字值；按 Perl 字串精確相等定義不得重複。此階段不做 Unicode 正規化，也不變更文字內容或順序。selected_count 不得超過目錄長度。

輸出是**新** arrayref，長度恰為 selected_count，各元素為輸入目錄中由 Stage12 索引指向的文字，無重複、順序精確且不改動任何輸入；修改輸出不得修改目錄或其他呼叫結果。目錄不合法時明確拒絕，而非默默去重、裁切或重排。

## 獨立 oracle 與可測驗收

- Oracle A：對 1<=k<=n<=6 全部有序互異排列作獨立 DFS 枚舉，每個 rank、兩個方向各核對名稱序列；不得以 production rank/unrank 產生 expected。
- Oracle B：五組 (n,k) = (1,1)、(2,2)、(5,3)、(17,17)、(47,47)，每組 first=1、2、M-1、M 與方向 ±1；獨立 BigInt 串流取樣計算應得一基 rank，並由實際名稱列表獨立逆算詞典序 rank；預期 40 boundary cases。
- 覆蓋非法目錄、重複及空白值、非純量、非法方向/排名、BigInt 保持、回傳非共享；標記 `STAGE13_INDEPENDENT_ENUMERATED=4730`、`STAGE13_INDEPENDENT_FAMILIES=21`、`STAGE13_INDEPENDENT_BOUNDARIES=40`、`STAGE13_INVALID_CASES=17`、`STAGE13_CANONICAL_CATALOG_NOT_VERIFIED`、`STAGE13_FULL_GENERATOR_NOT_VERIFIED`。
- Native Perl >=5.40，production/test 2/2 syntax OK、TAP 4973/4973、exit0、stderr0、120s、384 MiB VSZ；保留 `source.txt`、`perl-version.txt`、`syntax.stderr`、`test.stdout`、`test.stderr`、`test.exit`、`result.txt` 七件原始證據。
- 同分支既有 canonical push workflow 加入 Stage13 專屬 job；新 source SHA 的 `verify`、`perl-stage01`、Stage02..Stage13 **14/14 必需 jobs completed/success**，逐項檢查日誌，核對 Stage13 ZIP 的 provider SHA256、本地 SHA256、CRC、全部七件及 source SHA 後方能 `STAGE13 ACCEPTED`。在此之前 `LAST_COMPLETED_STAGE=12`。

禁止修改 main、merge 或發佈，不能把此局部通過標為總共 55 階段驗收。
