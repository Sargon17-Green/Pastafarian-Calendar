# ደረጃ 29/55 — PATCH 14: wide little-first

## አዲሱ ምርጫ

ለ `n>M`፣ `p` ትንሹ `M^p >= n` ነው።
`raw = 1 + Σ(answerAt(j)-1)*M^j` ከ `j=0` እስከ `p-1`።
`limit = floor(M^p/n)*n`። `raw > limit` ከሆነ
`step=+1`: `rejected = M^p-raw+1`፣ `accepted=1`፤
`step=-1`: `rejected=raw-limit`፣ `accepted=limit`።
ሁለቱም ከድግግሞሽ ውጭ በBigInt ቀጥታ ይሰላሉ።
`rank = 1+regularMod(accepted-1,n)`።

`n<=M` የPATCH 13 መንገድ እንዳለ ይቆያል።
`old_wide_pick_high_first` እና `LegacyWideOrderAdapter` የታሪክ
ማስረጃ ሆነው አይቀየሩም።

## የማረጋገጫ ዕቅድ

- `v fmt -verify ./pastafari`፣ native V 0.5.2 7647ce1።
- 41 Stage 28 GREEN files እና `discovery14_expected_red_test.v` (4 prior RED now GREEN) እና `patch14_test.v`፤ ድምር 43 test files።
- `patch14_test.v`፦ 3,5,7 ቤዝ ላይ ሙሉ የድንበር/የስፔስ ሙከራ፣ እንዲሁም `M=2^127-1` ላይ የ`step=-1` ትልቅ የrejection ምስክር።
- ከnative CI በፊት `PASS` አይገለጽም። ከnative CI በኋላ በrun ID፣ SHA እና የስራ ውጤት ይረጋገጣል።
- ሙሉ 46-visible-drop chain አልተጠናቀቀም። `main` አይቀየርም።
