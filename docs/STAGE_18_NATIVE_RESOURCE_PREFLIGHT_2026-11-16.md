# Stage18 九月份／36 日原生 Perl 局部資源預檢（2026-11-16）

專案 `PC-BRANCH-PERL-GUOYU`；branch `Perl+國語`。**本文件是有界本機 feasibility／候選來源資源證據，並非 Stage18 production commit、Native CI PASS 或獨立全面 oracle。** Stage17 已正式接受，來源 SHA `457eb0a8c444c5d3416c79e03273d3144dcc3dec`。Stage18 DISCOVERY 契約見 `docs/STAGE_18_NINE_MONTH_WEAVING_DISCOVERY_CONTRACT_2026-11-16.md`。

## 精確來源復原與局部修改
- 以 Stage17 Git blob 完整重建 `lib/Pastafari/Monster/WeavingPrimitive.pm`；本地 `git hash-object` 得到 **`6100eac95fcc3263f8bc1457472df4ad589567b6`**，與 GitHub Stage17 已提交 source blob 一致，非重寫或只憑記憶重構。
- 在**本地臨時複本**唯一語義修改：`m > 8` → `m > 9` 及 `days > 32` → `days > 36`；唯一非語義修改是註解改為 Stage18 local resource preflight。臨時檔 `git hash-object` = **`f1e855a32d81599692bdda9aea39f81cc949a75b`**，SHA256 = `78ed7407556f0039f79af6a9f1d1757d8aca7b8cd4711bfe5399de4a19e7a738`。**此 blob 未提交至工作分支。**
- 測試工具：`qa/perl-guoyu/stage18_resource_probe.pl`，已於相同臨時模組使用 Perl 5.40.1 通過 `perl -Ilib -c`。腳本以 `PERL5LIB` 接受來源複本；三個 profile 均獨立執行 count 和首／中／末 rank-unrank-roundtrip，並檢查長度與 `[(2)x9]` 的獨立 Catalan(9)=4862 常數。腳本本地 SHA256=`c470cf7e93f64d1aadced550e86bade978c88711d56f2a8ff32082dcc1960560`。
- 環境：Linux x86_64，Perl v5.40.1。每個 profile `ulimit -v 393216` KiB + `timeout --signal=TERM --kill-after=5s 120s`；Peak RSS 由 `/usr/bin/time -f '%M'` 量測。這是虛擬記憶體限額，非 RSS 上限。
- 重現：從上述 Stage17 source SHA 取出原始模組到隔離 sandbox（不得修改 repo source），核實 Git blob；套用上述兩條數值改動及註解，將隔離 `lib` 設為 `PERL5LIB`，執行各 `k=2,3,4`：
`(ulimit -v 393216; PERL5LIB=<isolated-lib> /usr/bin/time -f 'maxrss_kib=%M exit=%x' timeout --signal=TERM --kill-after=5s 120s perl -CS qa/perl-guoyu/stage18_resource_probe.pl "$k")`。

## 正式量測（Perl 候選複本；exit=0，無 Perl stderr）
| Profile | 日數 | count（精確整數） | count 時間 | 三個 rank↔unrank | 總時間 | Peak RSS |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `[(2)x9]` | 18 | `4862` | 0.001472s | 0.005485s | 0.006957s | 10752 KiB |
| `[(3)x9]` | 27 | `65164480466` | 0.078300s | 0.415202s | 0.493502s | 12160 KiB |
| `[(4)x9]` | 36 | `4483012419041095514` | 2.911526s | 14.273508s | 17.185034s | 41376 KiB |

- 3 profiles × 3 ranks = **9 precise roundtrips PASS**，三個 count PASS；以每組獨立限制運行，皆 `exit=0`；無 timeout、無記憶體限制錯誤。另以已存檔的 `stage18_resource_probe.pl` 在同一複本重跑三組，均成功，數值不變（計時略有變化）。
- 對照實驗：兩個不同 Python 動態規劃記憶化模型（tuple 狀態與整數壓縮狀態）都於 `[(4)x9]`、393216KiB 虛擬位址空間下拋出 `MemoryError`；`[(2)x9]` 皆=4862、`[(3)x9]` 皆=65164480466。**這是 Python 模型的內存失敗，不是 Perl 產品 bug、expected-red 或拒收 Stage18 的證據**；Perl 來源最小邊界擴展已通過同樣資源上限。

## 結論與 NEXT
Stage18 的 **9 月／36 日範圍暫可保留**，因為經 Git blob 鎖定的 Perl 最小擴展在三個預檢 profile 內都低於 120 秒／393216KiB。下一步：以相同工作分支、重新核實 HEAD 後實作 Stage18 production 上界 9/36、獨立 `t/63` exhaustive + Catalan9 4862 oracle、過時負例精準更新、Stage18 canonical native job、完整本地 QA，最後同 SHA 的 19/19 CI 與新 ZIP SHA/CRC/來源驗收。**目前沒有 Stage18 Native acceptance，亦沒有全年生成器驗收。**
