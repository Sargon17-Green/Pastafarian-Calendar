# 第 35 輪：修正 402 日工具中被誤改的原生年份月長快照

日期：2026-10-13。僅更新 \`Perl+國語\` Stage 1 opt-in 測試腳本及稽核日誌；
不改 \`main\`、正式曆法 API、Stage 2 或 \`HANDOFF_*\`。

## 確認的測試腳本故障

第 34 輪 GitHub Actions：
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38429544202

新 opt-in 測試工具 \`tools/profile_canonical_window41_count.pl\`
在任何數學演算前就輸出
\`CANONICAL_WINDOW41 status=FAIL reason=5000 年原生月長 SHA-256 不符\`。
根因是由已通過的 window40 腳本搬移新窗口時，
將字串 \`25,77,98,122\` 作為全檔取代目標，
不慎把原生 45 個月份向量尾端
\`88,40,25,77,98,122,105\`
誤改成 \`88,40,77,98,122,105,105\`。
此非規範算法問題、不是數值不吻合，
而是測試工具的固定資料遭無意改寫。

## 修正

僅將 \`@year\` 恢復為已測過的 45 個實際月份（合計 4,244 日），
SHA-256 繼續鎖定
\`6d64022344c04935e6423aa6f96b285098d35b9b5ecb4b8c57a4c7149773a134\`。

欲測的視窗仍是零起始 \`41..44\`，
\`[77,98,122,105]\`，合計 402 日。
\`countWeavingsFrontier\`、常駐與串流三算法、
首末名的獨立直接構造及中位 BigInt 正反排名
和所有資源限制均不變。

待新 GitHub Actions 原生工作通過才能稱第 34–35 輪 402 日驗證 PASS。
若遇 185 秒時間／393,216 KiB RSS 限額則標記 BLOCKED，
不將其稱為數學反例。仍不宣稱全 45 月／4,244 日已獨立驗證。
