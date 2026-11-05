# 第 14 階段：凍結正規名稱目錄綁定契約（2026-11-05）

專案：\`PC-BRANCH-PERL-GUOYU\`；唯一分支 \`Perl+國語\`。先前 Stage13 已根據 run 41870316140、14/14 必需 jobs、4973 TAP 及七件 ZIP 的 provider/local SHA256 與 CRC **同源驗收**。Stage14 只在這個已驗收的 Stage13 API 外再接一層**既有 Stage01 凍結的繁體中文正式名稱資料**，不是實作 sauce、askBowl、時間線或完整五欄日曆。

## 獨立生產 API、界限、決策
新增 \`Pastafari::Monster::CanonicalNameSelection::select_canonical_names(kind,first,direction_step,selected_count)\`。
- kind 僅可為精確字串 \`cutlet\` 或 \`month\`（拒絕大小寫變體、空白、參照及 undef）。
- 正式名稱唯一來源是同分支 \`Pastafari::SourceLanguageCatalog\`：\`source_language = 繁體中文（國語）\`、\`catalog_version = 1.0.0-stage1-frozen\`，\`cutlet_entries\` 17 個與 \`month_entries\` 47 個，按照連續 \`canonicalIndex=1..n\` 的既有順序。必須驗證版本、來源語言、長度、索引、非空及互異文字。**禁止自動 Unicode 正規化、重排、去重、翻譯或新增名稱**。
- cutlet 選擇數量 6..17；month 3..47；selected_count 是無前導零的十進位純量或 Math::BigInt。first 與 direction_step 使用 Stage11–13 的既有精確契約（M=2^127-1，first=1..M，step=±1）。所有不合法輸入拋錯。
- 生產端只能複製正式目錄的 \`source\` 欄位形成獨立陣列，呼叫已驗收 Stage13 的 \`select_distinct_names\`；返回長度恰好 k 的新 ARRAYref，文字順序與官方索引不變、每個值互異，輸入與正式來源資料皆未被修改。不產生年份、月份或切段語義。

## 完全獨立的測試基準
\`t/59_stage14_canonical_name_selection.t\` 不從 production accessor 建立預期文字，而是以 Stage01 凍結的**本分支** 17 + 47 文字作獨立固定快照，兩種目錄各檢查首與次詞典序已知位置。獨立算術 oracle 使用基數 M 的零基位元展開和拒絕區間推導出一基串流排名，再由回傳**文字序列**的剩餘池乘積逆算詞典序排名，不呼叫 production rank/unrank/索引生成。
- 8 組種類與數量：cutlet k=6、7、11、17，month k=3、6、17、47。
- 每組 first=1、2、M-1、M，方向 ±1，共 **64 boundary scenarios**；每案驗長度、官方名稱域、互異性、獨立 BigInt 排名（256 斷言）。
- 17 個不合法輸入，輸出不共享、輸入 BigInt 不變及固定名稱陣列不變；\`STAGE14_FROZEN_CUTLET_NAMES=17\`、\`STAGE14_FROZEN_MONTH_NAMES=47\`、\`STAGE14_INDEPENDENT_BOUNDARIES=64\`、\`STAGE14_INVALID_CASES=17\`、\`STAGE14_FULL_GENERATOR_NOT_VERIFIED\`。預期 \`Tests=285\`。
- 本次本地僅以 stub 依賴做了生產與測試檔的 **syntax 2/2**；這不等於全依賴、本地整合或 Native PASS。新程式的實際整合須以 GitHub 原始依賴執行才可接受。

## 單一 SHA 的 Native／CI 驗收
Canonical push workflow 必須有 Stage14 專屬 job：Perl>=5.40，兩個 syntax OK、\`prove -e 'perl -CS -Ilib' -v t/59_stage14_canonical_name_selection.t\`、285/285 TAP、上述全部 markers、exit0、stderr0、120s 與 384MiB VSZ。保留七件原始證據：\`source.txt\`、\`perl-version.txt\`、\`syntax.stderr\`、\`test.stdout\`、\`test.stderr\`、\`test.exit\`、\`result.txt\`。

同一 **新** source SHA 的 run 必須 completed/success；verify、perl-stage01、Stage02..Stage14 **15/15 必需 jobs** 完成成功，所有 15 raw job logs 直接審核；下載新的 Stage14 ZIP，核對 GitHub provider/upload/local SHA256、CRC、七檔、source exact 與版本。只能在完全核對後更新 \`LAST_COMPLETED_STAGE=14\`。queued/in_progress 不阻塞但絕非 PASS。仍無完整五欄日曆、sauce、askBowl 與整個 55 階段的驗收；禁止 main、merge 與發佈。
