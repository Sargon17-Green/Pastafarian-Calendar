# ደረጃ 28/55 — DISCOVERY 14 (COMPLETE / EXPECTED_RED)

## የwide አሃዞች ቅደም ተከተል ስህተት

M=2^127−1። ለn>M አነስተኛው p በM^p≥n ይመረጣል።
የጠቅላላ ቦታ space=M^p። እያንዳንዱ
digit_j=answerAt(j)−1 ነው። ትክክለኛው ሕግ፦

wide=1+Σ(j=0..p−1) digit_j*M^j

የታሪክ old_wide_pick_high_first ግን በተሳሳተ ቦታ ይደርድራል፦

legacy_wide=1+Σ(j=0..p−1) digit_j*M^(p−1−j)

ሁለቱም limit=floor(space/n)*n፣ እና
wide>limit ሲሆን wide=1+regularMod(wide−1+step,space)
ሕጉን ይጠቀማሉ። እንግዲህ የታሪክ ስህተቱ
የdigit ቅደም ተከተል ብቻ ነው።

## የሚጠበቁ RED ምስክሮች

1. first=1, step=+1, n=M+1 ⇒ M+1 (legacy: 2)
2. first=1, step=−1, n=M² ⇒ M²−M+1 (legacy: M)
3. first=17, step=+1, n=M² ⇒ 17M+17 (legacy: 16M+18)
4. first=1, step=+1, n=M²+1 ⇒ M−1 (legacy: M+3)

የPATCH 14 ምርጫ ጥገና እስከ ደረጃ 29 አይገባም።
old_wide_pick_high_first እና LegacyWideOrderAdapter ሁለቱም
እንደ ምስክር መቀመጥ አለባቸው።
n<=M የPATCH 13 መንገድ አልተለወጠም።
ሙሉ 46-visible-drops ወደ ቀጣይ ደረጃዎች ተላልፏል።

## ማረጋገጫ
v fmt -verify ./pastafari
v test ./pastafari/discovery14_witness_test.v
v -check ./pastafari/discovery14_expected_red_test.v
v test ./pastafari/discovery14_expected_red_test.v

41 የቀድሞና አዲስ GREEN test ፋይሎች፣
4 ሆን ተብለው RED assertions መረጋገጥ አለባቸው።


## የnative CI ማረጋገጫ

- የተፈተነ commit: c8b3e7f1ad86d19b38a9b86e6f3042c230bb6ce4
- GitHub Actions: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38286516480
- Artifact: 11763501585 (v-amharic-stage28-red-evidence)
- የnative V ኮምፓይለር V 0.5.2 7647ce1።
- 41 የቀድሞና አዲስ GREEN test ፋይሎች PASS።
- አራት የnormative EXPECTED_RED ማስረጃዎች በተናጠል ተረጋግጠዋል።
- የV fmt -w የመጀመሪያ ልዩነቶች በnative ማስረጃ ተመዝግበው በምንጭ ፋይሎች ላይ ተተግብረዋል፤ የመጨረሻ v fmt -verify በነጻ CI ይፈተሻል።
- Canonical Names Lock PASS።
- LAST_COMPLETED_STAGE=28። ደረጃ 29 PATCH 14 አልተጀመረም።

**ደረጃ 28 COMPLETE / EXPECTED_RED።**


## የመጨረሻ የማይለወጥ ምንጭ native ማረጋገጫ

በcommit c8b3e7f1ad86d19b38a9b86e6f3042c230bb6ce4
በGitHub Actions run 38286516480 የfmt -w የሥራ ጊዜ
ለውጦች ሙሉ በሙሉ ተወግደው v fmt -verify
ብቻ ተፈትሿል። 41 GREEN test ፋይሎች PASS፣
የታሰቡት አራቱ RED assertions በየስማቸው
ተረጋግጠዋል፣ Canonical Names Lock PASS።
