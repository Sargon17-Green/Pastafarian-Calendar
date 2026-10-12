# ደረጃ 26/55 — DISCOVERY 13 (native CI በመጠባበቅ ላይ)

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

LAST_COMPLETED_STAGE=25 እስከ native CI PASS_EXPECTED_RED ድረስ ይቆያል።
