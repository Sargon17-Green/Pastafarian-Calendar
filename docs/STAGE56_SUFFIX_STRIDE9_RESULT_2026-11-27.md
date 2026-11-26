# Stage56 stride9 result and rollback (2026-11-27)
PC-BRANCH-PHP-MALAY; exact experiment fa308b8cda469348f9804669ba833f931bf4f50d, push 45907416456. External job 140207385880 completed failure steps 16/18; 271 tuples PASS external only; raw Sauce 3/3 mismatch; source boundary adapter PASS only. B4 artifact 15158354263 SHA256 bb9dc5b68be50d7e8836caa3c727064541c2d667d89635dfdaddd653948e0ce0 CRC18/18, 10 exits zero, 3 empty stderr, exact project/SHA, stride9 marker and core/profiler PASS in retained output. B4 job ID not exposed in returned jobs listing; do not claim independently verified job log. External artifact 15160917779 SHA256 8a169d1ff1d21fedf7cafe3992bc61cb47828083566c4cad560921a5613ee6ac CRC81/81 manifest80/80 exact, canonical cc2cf0b422757a5e7c33218ce30cffa8f99c6786; exits 0/124/124, all stderr empty.

Timestamp-joined completed DP rebuilds within each emitted unrank interval (same method as parent):
|year/profile|positions|unrank s|DP s|rebuilds|rows|peak bytes|
|---|---:|---:|---:|---:|---:|---:|
|4999/1|4125|183.429|113.389|7|34|224395264|
|4999/2|4125|194.990|124.819|8|42|224395264|
|5000/1|4243|277.354|164.706|10|54|284164096|
|5001/1 partial|4352|539.653|365.069|10|56|417857536|

All joined rebuild totals match emitted bucket counters; completed row/cell sums match planned/end counts; max active+checkpoint rows 8. Overall 4999 763.216s vs 766.812s; 5000 still timeout roundtrip_unrank, peak across observed DP/buckets 297795584 vs first parent unrank peak 269484032 (not identical scope); first unrank matched scope 284164096 vs 269484032. 5001 still timeout month_weaving_unrank; peak 417857536 vs 388497408, positions 4352 vs 1792 (both partial). 45-month DP 180.705 ->164.706s and 15->10 rebuilds; 46-month partial DP 418.171->365.069s and 16->10. Timing not controlled benchmark. Explicit experiment contract says revert if peak regresses; restore exact parent source blob only, not branch HEAD. Keep 45/46 independent counts, endpoints/midpoints in B4, rename marker to LARGE_SHAPE to avoid falsely claiming stride9. No other source change. No new Native result. Next: isolate DP checkpoint retention across count/rank/unrank; compare per-stage overlapping identical DP cells and actual memory before any new optimization; do not repeat stride9 unchanged. Stage56 NOT ACCEPTED. No PATCH22/PATCH23/main/merge/publication.
