# 第七十一輪：四月份小空間 81 個向量之全部合法詞與反轉雙射（Stage 1）

日期：2026-10-24（以色列時間）。僅 Perl+國語，
保留 main、原先失敗紀錄、Stage 1/55 及四月份驗證範圍。

## Round 70 最終原生驗收

commit cdc9b27d30ecdbf697818e68ec6cc0b38333bae3
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40000207480
verify、perl-stage01、R70 0/1/2/3 六項工作皆 SUCCESS，
故 Round 70 封存 PASS。過去 R66/R67 失敗的證據不移除。

## R71 目的

R70 對 24 種互異月長 10/11/12/13 的每一種只取
3 個實際合法詞並證明反轉加補標籤會得到合法詞。
R71 不再只依靠抽樣：對所有 `[a,b,c,d]`，
`a,b,c,d ∈ {1,2,3}` 的**81 種配置**，
直接用首次和末次月序約束**逐條枚舉全部合法完整詞**。
以標籤由小到大的 DFS 自然構造真正 1-based 詞典序，
不用受測 rank/unrank 來生成期望詞。

固定集合基線由另一份 Python 獨立 memo 遞迴確認：
a=1：27 組、215 條詞；
a=2：27 組、892 條詞；
a=3：27 組、2596 條詞；
合計 **81 組、3703 條合法詞**。
對每個詞，每一步都測 `rankWeavingPolynomial` 等於
由完整枚舉的下標+1，`unrankWeavingPolynomial`
還原完全相同的詞。再將整條詞倒序及標籤
`j→5−j`，從**另一份獨立枚舉**得到倒序月長
的全體合法詞。檢查每個鏡射詞確實存在、每個目標
恰命中一次（單射及滿射），以及反轉兩次恰回原詞。
鏡射詞的本身 1-based 詞典序名次也逐條由原生
rank 與 unrank 核對。

每個來源詞執行 4 次既有 Perl rank/unrank 交叉檢查，
合計 14812 次，且 3703 次詞級鏡射覆蓋
完整集合。不與之前 72 個大數樣本混算。
每配置的獨立枚舉詞數另與不同表示的
`countWeavingsPolynomial` 和 `WeavingMemoOracle`
完全相符。

分三片 a=1/2/3，每片恰 27 向量，
GitHub 5 分鐘、Perl 子程序 185 秒／RSS 393216 KiB
獨立父程序監控，外層 timeout 195 秒。
只有 verify、完整 Perl suite 和三片 Native
都 SUCCESS 才可封存 Round 71。
此有限四月份窮舉不代表跨語言比較或完整
45 月／4244 日全年度排名驗證。


## R71 Native 已確認 PASS（2026-10-25 核對）

GitHub Actions 40125160119 的 verify、perl-stage01、R71 shard 1/2/3 均 SUCCESS。獨立子程序守衛輸出：215+892+2596=3703 條完整合法詞，14812 次 rank/unrank，全部 passed=1 blocked=0 failed=0。封存 R71，進入 R72 的新前綴區間驗證；不更寫之前的失敗歷史。
