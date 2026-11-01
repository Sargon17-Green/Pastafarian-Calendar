# 第 9 階段：肉排區間分割生成之獨立契約（2026-11-01）

專案 PC-BRANCH-PERL-GUOYU；唯一工作分支 Perl+國語。第 8 階段在來源 69a74d0fdfb52c3b3b2575cbb4288ac95b5a195e 已有完整 Native／CI 驗收；第 9 階段尚未取得 Native／CI 驗收。

## 來源語意、切片與 API

同分支規範 t/lib/Pastafari/NormativeScroll.pm 的 makeCutletPartitionFamily(G,K,required) 生成 K 個正整數肉排日長，總和 G，並依一基字典序排名。若 required 已提供，必須是某個非最後前綴和，亦即內部切點。規範的 _choose_cutlet_partition 依 G = closeGateIndex-openGateIndex 及位於年度內的計算日閘導出 required，另以 askBowl/chooseRank 決定排名。**本切片只生成合法分割，不重新構造 sauce、門日、名稱索引、日期或完整五欄結果。**

API：Pastafari::Monster::CutletPartitionGeneration::cutlet_partition_family($gate_count,$cutlet_count,$required=undef)。G=6..137，K=6..17 且 K<=G；required 為 undef 或 1..G-1。有效輸入為無前導零的十進位正整數純量或 Math::BigInt；所有輸入皆不得被修改。拒絕負數、零、非整數、非正規文字、陣列／雜湊和超限參數。

返回包含 count => CODE 及 unrank1 => CODE 的 HASH；count->() 每次返回獨立的 Math::BigInt 精確計數。unrank1->($rank) 接受正規十進位正整數或 Math::BigInt，滿足 1 <= rank <= count，返回全新整數 ARRAY，長度 K，每值 >=1，總和 G；指定分界須與某個前綴和一致。不接受無效或超出範圍排名，不能更改輸入 BigInt 或與其他結果別名共享可變狀態。

## 生產演算法：切點集合的二項係數 unranking

正整數有序分割對應 1..G-1 內的 K-1 個升序切點。若沒有必選切點，精確總數為 C(G-1,K-1)；有指定切點 r 時，總數為 C(G-2,K-2)。計算二項係數使用逐項整數乘除及局部複本快取，不用規範遞迴 DP。

對字典序選定下一切點 c，假設仍要選 a 個後續切點：已選必選分界（或無要求）時，後綴大小為 C(G-1-c,a)；若必選 r 尚未選、且 c<r，則為 C(G-2-c,a-1)；若 c>r 而 r 尚未選，候選非法。依序扣除後綴計數找到第 rank 個切點，最後以相鄰切點差還原日長。全程精確 BigInt，不物化整個巨大分割族。

## 完全獨立的測試 Oracle

- Oracle A：只用正整數有序組成的遞迴枚舉，對 G=6..12、K=6..min(8,G)，及 required 缺省／每個內部界線，依字典序逐一比對所有 unrank1 結果（預期 15048 次完整比對）。不讀取生產者的二項計數、也不匯入規範算法。
- Oracle B：純加法 Pascal 三角形（n=0..136）獨立求 C(n,k)；比對每組精確總數，另查 G=137/K=17 等較大輸入，含無必選及首／中／末必選分界，與首／中／末排名、輸入不變性和 BigInt 計數複本。
- 邊界：G=K、大計數、高位排名、必選界線 1 與 G-1、非法參數和排名、跨呼叫結果別名。預期 15573 TAP、STAGE09_INDEPENDENT_ENUMERATED=15048、STAGE09_INDEPENDENT_FAMILIES=170、STAGE09_LARGE_RANK_CASES=24。傳統中國語文字為唯一文件與訊息語言。

## Native／CI 及升階門檻

Perl>=5.40；兩個 syntax OK；prove -e 'perl -CS -Ilib' -v t/54_stage09_cutlet_partition_generation.t 於 timeout 120s、ulimit -v 393216 KiB 下 exit=0，stderr 空，Result: PASS，TAP=15573，兩 Oracle 標記及無完整生成器宣稱。證據檔：source.txt、perl-version.txt、syntax.stderr、test.stdout、test.stderr、test.exit、result.txt。須直接核實 CI run completed/success、head_sha、同 SHA 必需工作、工作日誌、下載之 ZIP SHA256/CRC 與證據內容。驗收之前 **不得** 更改 LAST_COMPLETED_STAGE=8，不得將 Stage 9 標為 PASS；queued/in_progress 不代表失敗或阻塞。

仍未驗收完整 buildYearStructure、真實生成器及 55 階段整體。沒有 main／merge／發佈授權。
