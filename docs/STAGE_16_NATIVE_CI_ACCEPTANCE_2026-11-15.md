# Stage16 原生 CI 正式驗收（2026-11-15 記錄；2026-11-07 運行）
專案：PC-BRANCH-PERL-GUOYU；工作分支：`Perl+國語`。

## 精確來源與可重現憑據
- **已驗收原始碼 SHA**：`303bc820e2c9250ff21ea0f9bedf7f8ce2119695`。在接受文件提交前，透過 GitHub branch API 核實 HEAD 與此值相同；不是以先前登記的 SHA 當作當前 HEAD。
- Canonical push run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42390320913 ；run_id=42390320913，attempt=1，event=push，head_branch=`Perl+國語`，head_sha 等於上述 SHA；2026-11-07T16:23:01Z 時已 completed/success。
- GitHub jobs API `per_page=100`、page 1+2 完整檢查 **163 個 jobs**；17/17 必需 jobs completed/success，其餘 146 skipped；直接讀取全部 **17 份原始 job logs**（非僅狀態）。
- 必需 jobs IDs：verify 128456341840；perl-stage01 128456342070；Stage02 128456346104；Stage03 128456346084；Stage04 128456346124；Stage05 128456346033；Stage06 128456346145；Stage07 128456346225；Stage08 128456346151；Stage09 128456346184；Stage10 128456346054；Stage11 128456346073；Stage12 128456346213；Stage13 128456346215；Stage14 128456346230；Stage15 128456346214；Stage16 128456346165。
- Stage01 完整 Native suite：`Files=112, Tests=196279, Result: PASS`，包括已修訂的 `t/47_stage02_weaving_primitive.t`、`t/49_stage04_month_occurrence.t` 與 Stage16 測試。Stage02 專用 `Tests=261` PASS，Stage04 專用 `Tests=385` PASS。
- Stage16 專用 Native：`Files=1, Tests=1053, Result: PASS`；`STAGE16_EXHAUSTIVE_PROFILES=8`、`STAGE16_EXHAUSTIVE_POSITIONS=39`、`STAGE16_CATALAN7_RANKS=429`、`STAGE16_LARGE_PROFILES=5`、`STAGE16_INVALID_PROFILES=14`、`STAGE16_INVALID_RANKS=10`、`STAGE16_INVALID_WORDS=8`。日志明確記錄 `STAGE16_FULL_YEAR_GENERATOR_NOT_VERIFIED`。
- CI Perl `v5.40.5`；模組及測試 syntax OK 2/2；檢查限額 `timeout 120s` 和 `ulimit -v 393216` KiB（是虛擬記憶體上限，非 RSS）；`test.exit=0`，`test.stderr` 空。

## 新 ZIP 來源位元組三方核對
- 本次成功運行的 **新** Stage16 artifact： https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42390320913/artifacts/13580729456 ，ID=13580729456，實際 4763 bytes，未過期（讀取時）。
- SHA256（GitHub provider digest = Stage16 upload raw log = 獨立下載後的本地位元組）：`785839ebe8918b690a252eb85fafd2b2e7426effe5cb84baa818398f0d7cfe58`。
- ZIP CRC test 無任何損壞；**恰七個**成員：`source.txt`、`perl-version.txt`、`result.txt`、`syntax.stderr`、`test.exit`、`test.stderr`、`test.stdout`。
- `source.txt` 為精確 SHA `303bc820e2c9250ff21ea0f9bedf7f8ce2119695`；`result.txt` 為 `STAGE16_NATIVE_PASS=1`；`perl-version.txt` 為 `v5.40.5`；完整 test.stdout 實際存在 1053 TAP 與上述標記；syntax.stderr 正好二行 syntax OK；stderr 空、exit=0。

## 決議與後續限制
**Stage16 ACCEPTED; LAST_COMPLETED_STAGE=16 僅對來源 SHA 303bc820e2c9250ff21ea0f9bedf7f8ce2119695 成立。** 之前 42250795125 completed/failure 是先前來源 `5b4b15941e8c67fd753dee891644e3048fbea869`；不能將其 Stage16 個別 job success 轉為那次整體 PASS。驗收文件與 Stage17 DISCOVERY 提交之後續 CI 如有執行，只證明新 SHA 的自身結果，不能取代上述來源驗收。完整年度 (252..5778 日)、sauce、askBowl、其他 55 階段總驗收都**未**通過；沒有 main、merge 或發佈。
