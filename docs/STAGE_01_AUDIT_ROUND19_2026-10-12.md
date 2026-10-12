# 第十九輪：全部四十四組真實相鄰月份的獨立雙月公式與串流驗證

日期：2026-10-12。只更新 \`Perl+國語\` Stage 1 稽核，禁止修改 \`main\`、正式曆法 API 或 Stage 2。

## 基線

前次第十八輪 \`0909742359686e1edebc61543a74d88c8864a644\` 原生
GitHub Actions：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38274843277
49 檔、29,694 斷言，\`perl-stage01\` 和 \`verify\` 均 PASS。

## 改善抽樣覆蓋

第十七輪僅比對真實 5000 年 45 個月中的首尾兩對月份。
新增 \`t/49_canonical_adjacent_pairs.t\` 以已核對來源 SHA-256 的
完整 45 個月長陣列，對其**所有 44 個相鄰雙月向量**比較：

1. 由固定首／末次順序直接推導之組合數 \`C(a+b-2,a-1)\`（精確 BigInt）。
2. \`NormativeScroll::countWeavings\` 獨立規範狀態計數。
3. \`WeavingPolynomial::countWeavingsPolynomial\` 記憶體二維 DP。
4. \`WeavingPolynomialStream::countWeavingsPolynomialStream\` 的逐列磁碟運算。
5. 每對檢查實際序列化的首月矩陣列數，並故意修改回傳的串流 BigInt，驗證其他值不受污染。

再於位置 0、7、14、21、28、35、39、43 抽取八對，
獨立驗證持久化直方圖索引的總和及三種後綴引擎的指定前綴計數；
確認回傳值具有獨立可變性所有權，最後解除所有物件引用後的臨時檔案全部回收。

同樣涵蓋真實年份中段月長 25 日等非均勻組合，並不將這些 44 組
**雙月份子問題**冒充為 45 個月的全年度排名證明。

## 限制及驗收

一般 \`perl-stage01\` CI 將執行本檔；必須在 Perl 5.40 下完整跑測試，
取得整套 50 檔 PASS 才能標註驗證完成。保持 10 分鐘 CI 最長時限，
不刪除舊回歸斷言、不更改算法參數定義。

全年度 4,244 日精確交織、最多 5,778 日的時間／磁碟／位元量、
以及跨語言統一性仍是未關閉項。 \`LAST_COMPLETED_STAGE=1\` 保持原狀。
