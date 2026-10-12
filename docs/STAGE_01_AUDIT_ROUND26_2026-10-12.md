# 第 26 輪：真實四月 240 日的記憶式獨立 BigInt 前綴排名

日期：2026-10-12，分支 \`Perl+國語\`，僅 Stage 1。禁止觸碰 \`main\`、正式 API、Stage 2 或 \`HANDOFF_*\`。

## 已確認基線

第 25 輪真正月份 \`[40,25,77,98]\` 的全域計數 126 位，前 4 日全部使用前沿獨立整數分割核對，受控 CI 工作 **PASS**：
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38284476870
第 4 日選 2，130.087 秒完成第四日分割，138.100 秒完成整體；VmHWM=24,072 KiB。這不代表第 5 日以上已獨立核對。

## 計算瓶頸

原前沿 Oracle \`countWeavingsFrontier\` 每次不同前綴都從頭展開整個狀態空間。2026-10-12 第 25 輪已用 138 秒，按同法繼續到 24 或 240 日不能滿足 CI 185 秒及 384 MiB RSS 上限。

## 不共用多項式演算法的獨立記憶式 Oracle

新增 \`t/lib/Pastafari/WeavingMemoOracle.pm\`，用剩餘月長、opened、closed 當作唯一的遞迴精確後綴計數狀態，將每個結果以私有 BigInt 副本快取。任意外部請求只取得另一份副本，不能改寫內部快取；狀態上限 200,000，組合數快取 8,192。當最後一月已開啟時，依末次出現次序的組合數恆等式直接計數，避免展開所有尾部狀態。未匯入 \`WeavingPolynomial\`、\`WeavingSuffixFactor\` 或兩個排名器的任何程式碼。

新增 \`t/54_memo_oracle_smallspace.t\`：0..4 月、月長 1..3 的 **121** 組向量對照獨立深度優先規範計數；驗證沿首名字序每個前綴與原先的前沿 Oracle 一致、合法非首名前綴、可變 BigInt 所有權、重複快取命中與錯誤契約。

## 真實年資料分支的 24 日實測

另設 opt-in \`tools/profile_canonical_memo_prefix.pl\`，提交標記為
\`[weaving-canonical-memo]\` 才執行 5 分鐘內的獨立 CI job：

1. 固定 SHA-256 對應真正 5000 年 45 月中末段 4 月、240 日。
2. 以記憶式獨立 Oracle 算全域精確總數，和位置多項式核對。
3. 以索引式反排名器一次求出 125 位中間 BigInt 排名的完整 240 日詞。
4. 前 **24** 日逐天，由獨立 Oracle 逐一取得所有合法下一標籤的完工數，確認區塊和等於母區塊，以原始精確一基排名獨立選出分支，並和索引式反排名輸出逐位比較。
5. 列印各階段計數、命中數、時間與 VmHWM。24 日成功只能標記 \`PREFIX_ONLY\`；未計算的其餘 216 日不可宣稱驗證完成。若日後 240 日全部通過，工具另驗證所有月長耗盡和尾端局部排名等於 1，才標記 \`FULL_240_DAY_LEXICOGRAPHIC_BRANCHES\`。

父程序維持 185 秒 / 393,216 KiB RSS 監測；超限 BLOCKED，而不是 PASS。還未觸及全年 45 月／4,244 日完整精確字序。
