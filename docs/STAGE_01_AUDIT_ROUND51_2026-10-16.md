# 第 51 輪：236 日中位排名第六日的四分支精確 BigInt 檢驗

日期：2026-10-16。只在 Perl+國語 Stage 1，嚴禁改 main、
正式算法、Stage 2 或 HANDOFF。

第 50 輪 opt-in 原生 CI：
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38902854152
五個第五日 BigInt 分片及其獨立正向前沿／另一個
因子式後綴的精確對照均 PASS：父前綴 [1,2,1,2]，
三個候選 [1,2,1,2,1]、[1,2,1,2,2]、[1,2,1,2,3]
完整精確總數相加等於母前綴。
中間名次第五天為 3，因此已獨立查驗的五日開頭
是 [1,2,1,2,3]。一般 Perl 全量 CI 尚需獨立檢查。

新增 --sixth-day-target=parent|1|2|3|4|assembly，
限定零起始月份窗口 37（真實 [83,88,40,25]，236 日）
且與所有此前昂貴的 opt-in 同時使用互斥。
第六天的月份 1、2、3 已開，第 4 月尚未開，
所以 **四個下一符號都合法**。

五份獨立工作計算：
parent => [1,2,1,2,3]；
1..4 => [1,2,1,2,3,j]，j=1,2,3,4。
對每份前綴，以不依賴排名多項式的正向合法狀態
countWeavingsFrontier 獨立算出精確 BigInt，並和
另一種 countWeavingSuffixFactored 的數值相等性比對。
任一獨立前沿不相等或為 0 必須 FAIL。

第六個 assembly 工作：從精確全年局部中間 BigInt
扣除先前第二日選 1 的所有完工詞、第四日較小的
[1,2,1,1] 完工詞、第五日較小的
[1,2,1,2,1]、[1,2,1,2,2] 完工詞。
中間局部排名必須在 [1,2,1,2,3] 範圍內。
再對四個完整第五日前綴衍生的第六日候選依字序
扣減 BigInt，驗證四數之和等於母前綴並與
unrankWeavingPolynomial 第六字元逐字相等。
不能用相同索引引擎的正反排名往返代替前沿核對。

六個新 GitHub jobs 只在提交含
[weaving-window37-sixth-split] 標記時觸發；
每程序時間 185 秒、RSS 393216 KiB，
每 job 五分鐘，索引單檔 16 MiB。
新增 t/67_quad_sixth_split_ci_contract.t，
驗證六份子工作、一基減法與標記、所有資源預算。
六份工作及一般 Perl 和 verify 全部原生 PASS
才可稱完成；任一 FAIL / BLOCKED / cancelled 必須保留證據。

這只延伸真實四月中位全長 236 天中的第六日，
沒有聲稱驗證剩下 230 日、全年 45 月 4244 日，
也不是跨實作 Soak。
