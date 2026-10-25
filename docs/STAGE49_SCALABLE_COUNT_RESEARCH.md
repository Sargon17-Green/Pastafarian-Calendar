# Stage49 — कायदेशीर weaving COUNT साठी एक-विमीय सिद्ध गणना (अपूर्ण टप्पा)

Stage48 closure [CI 40191782358](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/40191782358) 2/2 SUCCESS. Stage49 मधील `DPUnrankLegalWeaving` या पहिल्या bounded full-state prototype ला मोठ्या 44-महिन्यांच्या वर्षात `LegalWeavingCapacityError` येतो. हा failure दडवू नका.

## नेमकी संख्येची नवी recurrence

कायदेशीर month weaving मधील महिन्यांचे first appearance आणि last appearance दोन्ही क्रमाने 1..m आहेत. j−1 पर्यंत तयार झालेला शब्द S दिवसांचा असतो; त्यातील शेवटचे month j−1 हे अंतिम अक्षर असते आणि j−1 चे प्रथम स्थान p असते. नव्या j महिन्याची लांबी h (किमान 4) असेल, तर शेवटचे j अक्षर अंतिम ठेवून आधीच्या S शब्दात उर्वरित h−1 j अक्षरे जिथे हवी तिथे insert करणे. पहिल्या j चे नवीन स्थान q=t+1 असेल, आणि वैधता p<q असणे अनिवार्य. स्थिर q साठी insertion पर्यायांची नेमकी संख्या `C(S-q+h-1,h-2)` आहे. त्यामुळे `Fnew(q)=C(S-q+h-1,h-2)*Σ_{p<q}Fold(p)`, q=1..S+1. सुरुवातीला S=0,F(0)=1. एकूण count = अंतिम F चा योग. हा नियम duplicates, first order व last order जतन करतो; दोन दिशेने bijection नेहमी शक्य असल्यामुळे गणना अचूक आहे.

दर महिन्याच्या वेळी दोनच BigInt vectors साठवतात; maximum `totalDays+1` cells, आणि O(months × totalDays) transitions. `ScalableLegalWeavingCounter` उत्पादनातील स्वतंत्र वर्ग; normative oracle import नाही, पूर्वीचे `DPUnrankLegalWeaving` आणि त्याचा large-year blockage अजून बदललेला नाही.

## पडताळणी आणि मर्यादा

`test/patch24ScalableCount.ts` मध्ये लहान स्वतंत्र legal oracle comparison, year5000 actual 5349 दिवस/44 महिने, आणि time reversal + month-ID reversal bijection मुळे count invariance. या metamorphic check मधील दोन production counts सारखे असणे स्वतंत्र exact sequence unrank किंवा second oracle नाही — मोठ्या वर्षाच्या rank चे correctness अजून सिद्ध नाही.

**अजून बाकी:** `itemAt1(rank)` चे मोठ्या real-year साठी scalable exact lex suffix counter व Native corrected Bowl4 Seal32 निवड. हा दस्तऐवज Stage49 GREEN नाही; `LAST_COMPLETED_STAGE=48` आणि Stage50 बंदच.
