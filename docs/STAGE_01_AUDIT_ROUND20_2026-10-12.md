# 第 20 輪：避免直方圖輸入輸出同參照與真實四月份受控精確排名

日期：2026-10-12；工作分支：\`Perl+國語\`。禁止進入 Stage 2、觸碰 \`main\` 或提交 \`HANDOFF_*\`。

## 已確認的第 19 輪結果

commit \`024bb3a1ac665a08ef5372653ebac61b4494b109\`，
原生 CI：https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38278990521
50 檔、30,028 斷言、PASS。全部 44 組實際月份相鄰雙月，包含八個索引和後綴核查位置，均 PASS。

## 參照別名的語義漏洞及修正

在 \`countWeavingsPolynomial($lengths,$stats,$first_histories)\` 中，原程式在
拷貝和驗證 \`$lengths\` 前先清空 \`@$first_histories\`；若兩者引用**同一**
ARRAY，則清空輸入長度並得到錯誤結果 \`1\`。在
\`countWeavingsPolynomialStream\` 中，雖先複製有效長度，仍清空
呼叫者的同一個來源 ARRAY，違反輸入不變性。

修改兩個 Stage 1 模組：在執行任何輸出清空前，以
\`Scalar::Util::refaddr\` 偵測同一 ARRAY，明確拒絕並保持原始資料不變。
拒絕涵蓋 0、1、3 月和包含可變 \`Math::BigInt\` 的輸入。
\`t/50_histories_input_alias.t\` 逐一測試錯誤類別、原始 ARRAY 位址、
原始值和 BigInt 物件身分；不同 ARRAY 的正常路徑也驗證與串流模型一致。
此處不以靜默修正或共享同一個 ARRAY 作為兩份互斥資料的替代。

## 選定四個真實連續月份

從原生年度選擇出的 45 月向量，截取零起始索引 39..42：

\`[40,25,77,98]\`，共 **240 日**。

新增獨立 opt-in \`tools/profile_canonical_four_months.pl\`。依序執行：
獨立規範 \`NormativeScroll::countWeavings\`、不同遞推的
\`countWeavingsPolynomial\`、按列存檔的 \`countWeavingsPolynomialStream\`
三路精確總數；由獨立規範反排名決定大整數中位字典序，
索引式 \`unrankWeavingPolynomial\` 驗證整條序列，
最後索引式 \`rankWeavingPolynomial\` 完全還原初始一基排名。

子程序資源監督：185 秒／393,216 KiB 觀測式 RSS，
逐階段輸出實際進度；超限回傳 BLOCKED 且 code=3，
語義不一致回傳 FAIL 且 code=2。其結果不可冒稱
全年度 4,244 日／45 個月，或至多 5,778 日的精確排名。
\`[weaving-canonical-four]\` 提交標記才執行獨立 CI job，
以免每次完整 Stage 1 快速測試背負大型負載。

驗收狀態必須以相應原生 CI 結果為準。
