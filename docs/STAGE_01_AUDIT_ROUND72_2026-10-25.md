# 第七十二輪：全部 256 個四月份 1..4 向量的前綴字序連續區間

日期：2026-10-25（以色列時間）。僅 Stage 1 的 `Perl+國語`，
不修改 main，不啟動 Stage 2，不修改既有 canonical lock 源。

## R71 關閉所憑的真正 Native 證據

https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40125160119
的 commit `5b2e1665aa7e63c71eb0d58648d20aa3a0398fe1`
的 verify、perl-stage01、R71 shard 1/2/3 均 SUCCESS。
原生子程序守衛確認：shard 1=215、2=892、3=2596
條完整合法詞；合計 3703 條詞、14812 次 rank/unrank
交叉檢驗，無時間或 RSS 阻擋。因此 R71 封存 PASS。

## R72 新風險：完工數相等不必然保證前綴區間位置正確

四月每個長度皆在 1..4，全部 256 向量。
獨立的狀態 DFS `(remaining,opened,closed)` 計算任意
真實前綴剩餘完工數。對每個完整詞 rank=1、middle、N
獨立推導各深度 (0,1,2,half,last-1,last) 真實合法前綴，
以 **各較小合法候選子樹大小** 推得精確 1-based
區間起點 start，終點 end=start+ways−1；
不使用被測 rank/unrank 來建立期望邊界。

再以最小、最大合法下一月份逐步填滿尾詞，
交叉檢驗既有 Perl `rankWeavingPolynomial`、
`unrankWeavingPolynomial` 的區間雙端，
`WeavingMemoOracle` 有界 16 項 CLOCK 與每個真實
前綴的完工數一致，並對區間外鄰接排名確認**不屬於**
指定前綴。每個向量另驗證獨立 DFS 總數
與位置多項式一致。

來自獨立 Python 狀態 DP 的精確總數基線：
- shard a=1：64 向量，累計 4056 條詞，SHA256 `23e29a89c0b0ae4d769d121bd1109e1d21752114227236c810390b7c6bd33da2`
- a=2：64 向量，累計 27697，SHA256 `9831bee46cbf9d49a203ac3b530064d41c6ad074fe325c25f039a4a3da170e93`
- a=3：64 向量，累計 116768，SHA256 `9c703bd25c34f7512945c2ffb80cb648b2722b1b7c0bdc33c3e862736594f224`
- a=4：64 向量，累計 380893，SHA256 `aee9969ee80e407efccb96ea36e1ff68c07a1fa3d568e0bd93a7f0e032f7078c`
- **全域 256 向量總 529414 條合法詞**；
  不聲稱逐條枚舉或每條都做完整 rank/unrank：
  R72 是每組多個合法前綴的獨立精確**區間**稽核。

四個互不重疊 opt-in Native shard，各 64 向量。
每片 Github 5 分鐘，父監督 185 秒、393216 KiB RSS，
外層 timeout 195 秒，BLOCKED 和 FAIL 不等於 PASS。
只有 verify、perl-stage01、R72 四片 Native
全部 SUCCESS 才能宣布 R72 閉環；Stage 1 仍開啟，
沒有 45 月、4244 日或多語言通用證明。
