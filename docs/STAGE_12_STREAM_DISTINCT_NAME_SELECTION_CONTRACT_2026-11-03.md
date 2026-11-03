# 第 12 階段：串流選擇互異名稱索引整合契約（2026-11-03）

專案 PC-BRANCH-PERL-GUOYU；唯一工作分支 Perl+國語。Stage11 source c2989899f1491d8591bd4f26072f8176f12bec80 已在 canonical run 41536821625 attempt=2 得到 12/12 Native/CI 必需 jobs SUCCESS。本契約只訂立 Stage12 的可測整合，並未驗證完整五欄年曆。

## 選擇及限制

Stage10 已實作互異名稱索引家族計數及一基詞典序 unrank；Stage11 已實作精確串流一基 rank。Stage12 的最小整合是輸入串流首值、方向、目錄大小及選取數，直接輸出互異名稱**索引**序列，防止兩個元件的計數、排名基準和索引次序不一致。不處理名稱字串、sauce、askBowl、閘門、年/月/日、完整日期或其他分支的程式碼和測試資料。

## API 與語義

新增 Pastafari::Monster::StreamDistinctNameSelection::select_distinct_name_indices(first,direction_step,catalog_size,selected_count)。輸入規則與 Stage10/11 一致：M=2^127-1，first 為無前導零 1..M 整數；direction_step 恰為 +1/-1；1 <= selected_count <= catalog_size <= 47；允許有效數字字串或 Math::BigInt，不得改變輸入。無效類型、undef、非整數、非法方向、前導零、越界均拒絕。

輸出為新的 arrayref，長度恰為 selected_count，元素是 1..catalog_size 中不重複的索引；不同呼叫之間不可共用可變輸出。獨立語義：令 N=乘積 (catalog_size-j)，j=0..selected_count-1；用 Stage11 串流選出 1..N 中的一基 rank，再按照 Stage10 詞典序完整可行序列選取該 rank 的序列。最大 N=47! 大於 M，必須使用完整 BigInt 精確計算。

## 獨立 oracle 與驗收

- Oracle A：完全獨立 DFS 枚舉 1<=k<=n<=6 的全部排列；對每一個枚舉 rank 使用 first=rank 且方向各 +1、-1，逐案核對所選索引；不以生產 unrank 算出預期值。
- Oracle B：六種家族 (2,1)、(4,2)、(7,3)、(17,17)、(47,3)、(47,47)，首值為 1、2、M-1、M，兩種方向；獨立 BigInt 組字與接受區計算預期 rank，並從實際輸出反向算詞典序 rank；涵蓋短/寬排名、rejection/wrap、唯一性、不變性。
- 驗證非法輸入、BigInt 不可修改、回傳陣列非共享；標記 STAGE12_INDEPENDENT_ENUMERATED、STAGE12_INDEPENDENT_FAMILIES、STAGE12_INDEPENDENT_BOUNDARIES、STAGE12_INVALID_CASES、STAGE12_FULL_GENERATOR_NOT_VERIFIED。
- Native Perl 5.40+、2/2 syntax OK、完整 TAP PASS、exit=0、stderr=0、限制 120s + ulimit -v 393216 KiB，並存七個原始 evidence：source.txt、perl-version.txt、syntax.stderr、test.stdout、test.stderr、test.exit、result.txt。
- 在**同分支既有 canonical push workflow** 加入單一 Stage12 native job，必須在新 source SHA 上 completed/success、verify+perl-stage01+Stage02..Stage12 共 13/13 required jobs SUCCESS，檢查原始日誌、artifact SHA256/CRC/source 及七個檔案後才可標記 Stage12 ACCEPTED。直到此前 LAST_COMPLETED_STAGE=11。

禁止 main／merge／發布。完整五欄日曆及總共 55 階段未經整體驗收。
