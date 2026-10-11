# टप्पा 5 पूर्ण — टप्पा 6 साठी हस्तांतरण

शाखा: `TypeScript+मराठी`, फक्त या शाखेवर काम करा; `main` बदलू नका.

- एकूण टप्पे: 55. पूर्ण झाले: 1–5. पुढील टप्पा: **6 — DISCOVERY 03**.
- Stage 1: शून्यापासून TypeScript/मराठी स्वतंत्र पाया; 17 कटलेट व 47 महिने `canonicalIndex` स्थिर आणि गोठवलेले; Appendix A वरून स्वतंत्र test-only oracle.
- Stage 2: DISCOVERY 01 — नेहमीचा modulo `M`, `2M`, `3M` साठी 0 देतो, नियमाधारित `SAVE` ने `M` दिला पाहिजे.
- Stage 3: PATCH 01 — `legacyValue === 0n` ते `M` असा एकमेव बदल. 672 regression नमुने, 0 भिन्नता.
- Stage 4: DISCOVERY 02 — `oldDayTag(d)=2*abs(d-F)`, `F=-15055671`; पुढील दिवसांमधील `+1` हरवला. दोन जुळण्या, तीन अपेक्षित लाल फरक.
- Stage 5: PATCH 02 — जुन्या adapter ला न बदलता `if day>=F: n+=1`, त्यानंतर स्वतंत्र ऐतिहासिक `if day==F && n!=1: n=1` अट ठेवली. `patch02DayTags` उत्पादन API. 1099 जोड्या/2198 दिवस, 0 भिन्नता, 18 scar checks, 0 forced.
- Stage 54 अंतिम `calendarDateSpaghetti` अजून लागू नाही. त्याची सध्याची `MonsterStageError` स्थिती जतन करा.
- Source code कधीच `test/normativeOracle.ts` आयात करत नाही; test-only oracle स्वतंत्र असावा.
- `src/discovery01LegacyRemainder.ts`, `src/discovery02LegacyDayTag.ts` आणि दोन्ही expected-red चाचण्या ऐतिहासिक पुरावा म्हणून ठेवा.
- GitHub CI Stage 05: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38153654056, सर्व jobs PASS.

पुढील कृती: GitHub ची वर्तमान HEAD आणि `DEVELOPMENT_STAGE.md` तपासा. मूळ 55-टप्पे करारात असलेला **तिसरा** ऐतिहासिक दोष आणि त्याचा अचूक expected-red पुरावा शोधा. करार उपलब्ध नसेल तर दोष बनवू नका; टप्पा 6 सुरू झाला असे खोटे नोंदवू नका. फक्त DISCOVERY 03 करा; PATCH 03 हा Stage 07 साठी आहे. Stage 01–05 regression, lock आणि दोन्ही historical failures हिरवे/अपेक्षित लाल राहावेत. CI पुरावा मिळाल्याशिवाय stage complete लिहू नका.
