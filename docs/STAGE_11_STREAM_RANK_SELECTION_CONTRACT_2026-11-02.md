# 第 11 階段：有界串流排名選擇契約（2026-11-02）

專案：`PC-BRANCH-PERL-GUOYU`，唯一分支：`Perl+國語`。第十階段已依 [Native／CI 驗收](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/26a061a9c247ac34ff6f11ce89fe3832f8e2d662/docs/STAGE_10_NATIVE_CI_ACCEPTANCE_2026-11-02.md) 完成；本文件僅**開立 Stage11 契約**，未聲稱 Stage11 生產實作、Local PASS 或 Native PASS。

## 規範來源、選擇理由與排除事項

唯一規範來源為同一 Perl 分支 `t/lib/Pastafari/NormativeScroll.pm` 的 `M`、`answerAt`、`chooseRankShort`、`chooseRankWide`、`chooseRank`（原檔約 366–407 行）。第十階段只會把*已給定*的一基排名解碼成互異名稱索引，尚未產生該排名；因此下一個最小獨立切片是把 `askBowl` 已產生的 `first`、`directionStep` 和選擇空間大小轉為**精確一基排名**。

不實作 `sauce`、`askBowl`、`workCounts`、gate、`calendarDate`、整年組裝、名稱索引解碼或其他階段的算法。不從其他語言分支複製程式、fixture、預期值或 oracle。

## 生產 API 與有效輸入

新模組 `Pastafari::Monster::StreamRankSelection`，匯出 `choose_rank_from_stream($first,$direction_step,$N)`。

- `M=2^127-1` 為定值；`first` 是 `1..M` 的正規十進位字串／整數純量或 `Math::BigInt`，不可有前導零。
- `direction_step` 僅可為精確整數 `+1` 或 `-1`（數值字串或 `Math::BigInt`）；其他值拒絕。
- `N` 為 `1..47!` 的正規正整數十進位純量或 `Math::BigInt`；必須完整支援 `N<=M` 及 `M<N<=47!` 的兩條路徑。
- 回傳**新** `Math::BigInt`，值在 `1..N`。不得修改輸入 BigInt，隱式錯誤不得回傳部分結果；拒絕 `undef`、零、負數、前導零、非整數、空值、陣列／hash、NaN、超界值。

## 精確語義與獨立演算法

令 `x(j)=1+((first-1+direction_step*j) mod M)`，其中 mod 結果非負。取最小整數 `k>=1` 使 `S=M^k>=N`。構造 `W=1+Σ(j=0..k-1) (x(j)-1) M^j`（**低位數先取樣**）。設 `L=floor(S/N)*N`，接受區間 `1..L`；對 `W>L` 依原始 `direction_step` 每次在 `1..S` 循環前進直到被接受，輸出 `1+((W_final-1) mod N)`。

**生產者不得進行可能需要天文次數的逐步 rejection 迴圈。** 因接受區間連續，若 `W>L`，`direction_step=+1` 的第一個合格值必為 `1`（環繞），`direction_step=-1` 的第一個合格值必為 `L`。據此以 BigInt 閉式跳躍，與規範反覆遞增／遞減的輸出數學等價；不得修改 `first`、`N`。

## 獨立 oracle 與測試

1. **Oracle A — 小模數完整模擬**：測試使用與生產者不同的純整數迴圈，於試驗模數 `m={2,3,5,7}`、每個 `first=1..m`、兩個方向、`N=1..m^3`，逐步形成低位先行寬字、每次調整 1 並直接追蹤直到被接受；與同一生產閉式核心在小模數測試入口逐案比較。數量為 `2*(2^4+3^4+5^4+7^4)=6246` 個三參數組合。該 oracle 不呼叫生產者任何取模／閉式輔助函數。
2. **Oracle B — 真正 M 的獨立邊界預期**：`N=1,2,3,M-1,M,M+1,47!`；`first=1,2,M-1,M`，兩個方向；直接測試 `W<=L`、`W=L`、`W=L+1`、跨 `S` 環繞，並用另一套標量算式計算排名。另測 `N=47!` 的大整數精度；不得由生產函數自身生成期望值。
3. **不變性及邊界**：輸入參數未變、輸出無共享可變別名，重複呼叫穩定；非法／超界拒絕；對 `N<=M` 和 `N>M` 分別有實際測試證據。驗證小模數 oracle 全部有限且具有 1..L 的接受區間；任何 witness／expected-red 必須可重現，不預設存在規範漏洞。

## Native／CI 驗收門檻

- `perl -Ilib -c` 生產模組及 `t/56_stage11_stream_rank_selection.t` 各 syntax OK；
- `prove -e 'perl -CS -Ilib' -v t/56_stage11_stream_rank_selection.t`：exit 0、stderr 空、`Result: PASS`、完整 TAP 計數、`STAGE11_SMALL_MODULUS_CASES=6246`、獨立大數檢核標記；
- Linux Native Perl 5.40+；120 秒 timeout；`ulimit -v 393216` KiB；同源 canonical workflow 加入 Stage11 專屬 job；
- 保存七件原始證據 `source.txt`、`perl-version.txt`、`syntax.stderr`、`test.stdout`、`test.stderr`、`test.exit`、`result.txt`；下載 ZIP 並實驗 SHA256／CRC、核對 branch/source、直接審核 `verify`、`perl-stage01` 及 Stage02..Stage11 全部必要 job logs。只有同一來源 SHA completed/success 及所有證據齊全才准 Stage11 accepted。

**當前狀態**：`CURRENT_STAGE=11`（contract/discovery only），`LAST_COMPLETED_STAGE=10`。Stage11 不可憑本契約視為實作或 PASS。未驗收全年組裝、完整五日期欄位及整體 55 階段。不得更改 main、merge 或對外發布。
