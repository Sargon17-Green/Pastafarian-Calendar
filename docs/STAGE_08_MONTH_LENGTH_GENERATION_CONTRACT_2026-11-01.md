# 第 8 階段：全年月份日長生成的可驗證切片（2026-11-01）

專案 PC-BRANCH-PERL-GUOYU；唯一工作分支 Perl+國語。Stage7 已在來源 SHA 4619e3a325d78551cef398b9db2981122e69d295 驗收；Stage8 未有 Native／CI 驗收。

## 範圍、輸入和輸出

規範 t/lib/Pastafari/NormativeScroll.pm 之 buildYearStructure 以 _choose_month_lengths 呼叫 makeBoundedCompositionFamily(L,K,4,123) 從一基排名生成 monthLengths。本切片確實生成合法月長序列，不是 Stage7 的預生成結構投影；不讀規範模組、不生成 sauce、askBowl、chooseRank、月份交織、肉排或閘門。

API Pastafari::Monster::MonthLengthGeneration::month_length_family($year_span,$month_count) 接受正規十進位整數純量或 Math::BigInt：年長 252..5778；月數 3..47；4K <= L <= 123K。拒絕前導零、小數、負數、空值、非法類型及不可能長度。返回包含 count 和 unrank1 的 HASH，兩者為 CODE：count->() 返回獨立 Math::BigInt 的配置總數；unrank1->($rank) 以一基字典序輸出長度為 K 的整數 ARRAY，各元素 4..123，總和 L。排名必須是正規十進位或 Math::BigInt，1 <= rank <= count。輸入和結果的 BigInt 不可相互別名。

## 生產方法和獨立 Oracle

生產使用自底向上的 BigInt 滑動窗口 DP：D[k,s] = Σ(x=4..123) D[k-1,s-x]，其中 D[0,0]=1，超出可行範圍為零。逐個月試探升序月長，按其合法後綴計數扣除排名而選定月長；不全量枚舉巨大空間。

Oracle A：不引用生產 DP，獨立雙重 for 枚舉所有三個 4..123 月長總和 252 的組合；一共 7021 組，逐一核查所有一基字典序排名。Oracle B：獨立容斥公式，對 y_i = length_i - 4、0 <= y_i <= 119：
count = Σ(j=0..K) (-1)^j * C(K,j) * C(L-4K-120j+K-1,K-1)；
若 n<0 或 k>n，C(n,k)=0。用 (252,3)、(963,8)、(5778,47)、(492,4)、(252,47) 比對完整 BigInt 計數並驗證首／中／末生成序列、長度、上下限、和、輸入不變性；另涵蓋非法形參、排名、BigInt 複本。測試至少 7100 TAP；必有 STAGE08_INDEPENDENT_ENUMERATED=7021 及 STAGE08_INDEPENDENT_BIGINT_CASES=15。

## Native／CI 同版閘門

在 Perl >=5.40 檢查模組及測試語法（兩次 syntax OK）；執行 prove -e 'perl -CS -Ilib' -v t/53_stage08_month_length_generation.t，在 120s timeout、ulimit -v 393216 KiB（限制虛擬記憶體，不是 RSS 測量）下必須 exit=0、stderr 空、Result: PASS、至少 7100 TAP，核對兩個獨立 Oracle 標記。保存 source.txt、perl-version.txt、syntax.stderr、test.stdout、test.stderr、test.exit、result.txt 工件，檢查來源 SHA、工件 ZIP／CRC 和日誌。同一來源 SHA 的 verify、perl-stage01、Stage2 至 Stage8 九個必需工作必須全部 completed/success 後方能標記 LAST_COMPLETED_STAGE=8。queued/in_progress 不是 PASS 也不是阻塞。

尚未驗收完整 buildYearStructure、月份交織、肉排分割、真實 sauce/rank 種子、year5000、跨年日期生成或全五欄曆法。不得合併 main 或發佈。
