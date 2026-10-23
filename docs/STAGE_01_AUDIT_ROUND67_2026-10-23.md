# 第 67 輪 Stage 1：超 64-bit 四月份字序與完整合法前綴

日期：2026-10-23（以色列時間），僅 Perl+國語 Stage 1。
Stage 2 未授權，不修改 main、正式曆法或其它語言。

## 前輪關閉的分開證據

R66 原生十個互補片段（a=1..10，各 1000 向量）
在 https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39915881899
全部 SUCCESS，verify SUCCESS；唯 Perl 測試 fixture 失敗。
失敗證據亦存在於原提交及
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39918945917 。
修正後 HEAD d56455f21210bb98a5378879db4add49e8683741，
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39930803997
之 verify 與 perl-stage01 均 SUCCESS。故 R66 以互補證據封存，
沒有聲稱在修正後 HEAD 重跑十片原生壓力驗證。

## 本輪的新測試空間

保留 R66 的 185 秒／393216 KiB 資源政策；
本輪專用 GitHub 工作五分鐘、Perl 子測試 190 秒。
下列總數已由各自撰寫的 Python 逆向後綴遞迴與
逐日正向狀態 DP 兩條不同模型一致重算，
尚非原生 Perl CI 的 PASS 證據：

| 四月份長度 | 全部合法字序 |
|---|---:|
| 10,10,10,11 | 34837538497713607370 |
| 11,11,11,11 | 2134397833143177403516 |
| 12,12,12,12 | 474042534302340556453992 |
| 15,14,13,12 | 1331903513327335554982512328 |

各值都嚴格超出 signed int64 最大值
9223372036854775807。這四組與 R66 的
(1..10)^4 全空間不同，尤其新增長度 11..15。

新檔 t/87_r67_wide_bigint_prefix.t 會比較：
一、直接合法後繼 BigInt 記憶式 DFS；
二、基於首次／末次位置分布的獨立插入多項式；
三、舊 Memo DFS；四、有界 16 項 FIFO；
五、有界 16 項 CLOCK。
並於獨立生成的真實合法首尾完整詞取固定深度
前綴，逐一比對合法完工後綴數、BigInt 副本
隔離和閉式實際觸發；不藉錯誤前綴製造假 PASS。
t/88_r67_wide_contract.t 檢查證據配置和 opt-in 工作。

只有專用工作、verify、完整 Perl CI 均原生 SUCCESS
才可封存 Round 67。超大 BigInt 局部四月份測試
不推論 45 個月／4244 日全球名次全域同構，
也不推論多語言全部實作互相等價。


## Round 67 監督器補強

在提交的第一版 opt-in 工作中，只有 timeout，未由父程序
直接監測 VmRSS；故必須補上獨立 fork/exec 父程序。
tools/profile_r67_wide_bigint_prefix.pl 每 50ms 檢查子
Perl 的 /proc/PID/status VmRSS，185 秒或 393216 KiB
先達上限即將子程序 kill 並以 BLOCKED/exit 3 回傳。
測試非零結束則 FAIL/exit 2；正常完成才 PASS/exit 0。
195 秒的外部 timeout 僅為父程序失效的第二防護。
舊版 CI run 的結果仍保留；必須以監督器合併後的
完整 native 與全套 Perl 成功來驗收 R67。
