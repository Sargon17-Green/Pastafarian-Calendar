# Stage02 DISCOVERY 01 — தனிமைப்படுத்தப்பட்ட மீள்கட்டமைப்பு
PROJECT_ID: PC-BRANCH-SQL-TAMIL
- BASELINE_TESTED_SHA=cac8fba51d2bb2a1a437187a1e58d73ec9fa512f
- BASELINE_EVIDENCE_COMMIT=1e1d0fe083fe7d273cbabde10204b4b23a815943
- FIRST_SLICE_SHA=8dbe132b175a5d464ee64612d550a11d23177404
- SOURCE_HEAD=357f25481a1b11b698f342b9d406f8b8c0794d9c
- SOURCE_TREE=41746ce12a984dfeea92fd6500e3e32d8daaa831
- RUN=NOT_RUN_VERIFIED
- CANONICAL_STAGE02=NOT_ACCEPTED

Stage01: 40742033401 / 123005883292 / 12839284885; 66/66 என வரலாற்றுப் பதிவில் உள்ளது. இந்த மீள்கட்டமைப்பில் அந்த பழைய ZIP மீண்டும் சரிபார்க்கப்படவில்லை. SHA256 9358d51104a564c2d364a00b13e4db2526bc0cdc4082264bd32b561ce931f5f5. சோதிக்கப்பட்ட commit-இலிருந்து evidence commit வரை ஒரே ஆவண மாற்றம்; evidence commit தற்போதைய மூலத்தின் முன்னோர் (164 ahead, 0 behind).

பழைய வழி: old_remainder → save_value. M,2M,3M → 0; M+1 → 1. தனித்த ஒப்புநிலை SAVE → M,M,M,1. இவை கணிக்கப்பட்ட மதிப்புகள்; Native முடிவுகள் அல்ல. தனித்த தரவுத்தளத்தில் உண்மையான அழைப்பு, மூன்று வேறுபாடுகள் மற்றும் ஒரு கட்டுப்பாட்டு ஒற்றுமை. தவறான வெளியீடு அல்லது செயலாக்கப் பிழை ஏற்றுக்கொள்ளப்படாது. PATCH01 இல்லை.

முந்தைய 52+7+3 சோதனைகள் மாற்றமில்லாமல் அடிப்படை reference DB-இல். Stage01-only no-legacy assertion அங்கு இயங்கும்; candidate DB-இல் old_remainder மட்டுமே அனுமதிக்கப்பட்ட legacy பெயர்; அங்கு நான்கு தனிமைப்படுத்தல் சோதனைகளும் bootstrap compatibility-யும் இயங்கும். இது candidate-இல் அனைத்து 66 சோதனைகளும் மாற்றமில்லாமல் இயங்கியது என்ற கூற்று அல்ல. Source locks: 8 baseline + 3 candidate; PostgreSQL 17.12; 2CPU/2GB, 900s reference watchdog, 90s candidate watchdog. முடிவு கிடைக்கும் வரை ஏற்றுக்கொள்ளப்படவில்லை.

தற்போதைய production sql/00–27, catalog, stage metadata மற்றும் ஏற்றுக்கொள்ளப்பட்ட slices மாற்றப்படவில்லை. இந்தக் கோப்புகள் தனியான source lane; பழைய branch history மீளெழுதப்படவில்லை. புதிய CI முடிவை அசல் log/ZIP/manifest மூலம் பரிசோதிக்க வேண்டும். Stage03/main/merge இல்லை.
