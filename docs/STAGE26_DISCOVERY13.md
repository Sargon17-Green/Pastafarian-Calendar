# ደረጃ 26/55 — DISCOVERY 13 (COMPLETE / EXPECTED_RED)

## የታሪክ modulo bias ስህተት

M=2^127−1። ከ12 post-stirs የመጡ ቦውሎች እና ከPATCH 12 የተረጋገጠ
circular successor የመልስ ዙሩን ይመሠርታሉ።

- first=SAVE((B[queried]+seal+181)^2+179*B[next]+seal)
- d=SAVE((first+seal+194)^2+193*first+197*B[6])
- step=+1 ከd ጎዶሎ ከሆነ፣ ካልሆነ −1
- answerAt(k)=1+regularMod(first−1+step*k,M)

ታሪካዊው old_biased_pick(x,n) ያለ ቅድመ ምርመራ
1+regularMod(x−1,n) ይመልሳል።
ትክክለኛው ሂደት limit=floor(M/n)*n ብሎ x>limit
ከሆነ በተመሳሳይ ዙር የሚቀጥለውን x መጠበቅ አለበት።
ይህን የPATCH 13 rejection ጥገና በዚህ ደረጃ አናስገባም።

## የሚጠበቁ አራት RED assertions

1. first=M, step=+1, n=floor(M/2)+1 ⇒ 1
2. first=M−1, step=+1, ተመሳሳይ n ⇒ 1
3. first=M, step=−1, n=M−3 ⇒ M−3
4. first=M, step=+1, n=M−3 ⇒ 1

ከደረጃ 25 የነበሩት 37 GREEN የtest ፋይሎች አይለወጡም።
አዲሱ discovery13_witness_test.v ሌላ GREEN ፋይል ነው፤
discovery13_expected_red_test.v ደግሞ አራት ሆን ተብለው RED ነው።
ሙሉ 46-visible-drops ሰንሰለትና wide n>M አልተጨመሩም።

## ማረጋገጫ

v fmt -verify ./pastafari
v test ./pastafari/discovery13_witness_test.v
v -check ./pastafari/discovery13_expected_red_test.v
v test ./pastafari/discovery13_expected_red_test.v

## የመጨረሻ native V ማረጋገጫ

- የተፈተነ commit: 242a8d6604a5118d975eaa2a2961599c104a89c4
- CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38282248109
- V 0.5.2 7647ce1፦ v fmt -verify ./pastafari PASS።
- 38/38 የቀድሞና አዲስ GREEN የtest ፋይሎች PASS።
- አራቱ የታሰቡ normative RED assertions በተናጠል ተረጋግጠዋል።
- Canonical Names Lock PASS።
- old_biased_pick ሆን ተብሎ አልተጠገነም።
- LAST_COMPLETED_STAGE=26፤ ደረጃ 27 PATCH 13 አልተጀመረም።

**ደረጃ 26 COMPLETE / EXPECTED_RED።**
