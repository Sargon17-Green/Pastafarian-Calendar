# పాస్తాఫేరియన్ క్యాలెండర్ — Ada + తెలుగు

ఇది కొత్తగా, ఖాళీ ప్రాజెక్టు వృక్షం నుండి ప్రారంభించిన స్వతంత్ర అమలు వరుస. ఈ సంచిక Stage 1 Bootstrap కోసం మాత్రమే రూపొందించబడింది. మరే ఇతర అమలు, పరీక్ష ఫలితం, fixture, generated table, hash లేదా oracle దీనికి మూలంగా ఉపయోగించబడలేదు.

## ఈ దశలో ఉన్న భాగాలు

- Ada 2022 ప్రమాణ గ్రంథాలయంలోని arbitrary-precision `Big_Integer` ఆధారంగా ఖచ్చిత పూర్ణాంక గణితం.
- Appendix A నుండి నేరుగా తిరిగి నిర్మించిన test-only `Normative_Oracle`.
- 17 కట్లెట్ పేర్లు మరియు 47 నెల పేర్లకు స్థిరమైన `canonicalIndex` కలిగిన `Source_Language_Catalog`.
- భవిష్యత్తు ట్యాగ్‌లు లేదా legacy మార్గాలు లేని సాధారణ `Monster_Context`, ప్రాథమిక dispatcher, validator, error boundary భావన మరియు metrics shell.
- Ada లోనే Stage 1 పరీక్షలు మరియు స్థానిక fixtures.

## నిర్మాణం మరియు పరీక్ష

GNAT మరియు GPRbuild ఉన్న పరిసరంలో ప్రాజెక్టు మూలంలో ఈ ఆదేశాన్ని నడపాలి:

```text
./run_stage01.sh
```

ఇది `gprbuild -p -P pastafari_calendar.gpr` నడిపి, తరువాత `bin/stage01_tests` ను నడుపుతుంది. ఈ shell ఫైలు build/run మాత్రమే చేస్తుంది; ఎటువంటి క్యాలెండర్ గణితం దానిలో లేదు.

## ముఖ్యమైన పరిమితి

ఈ handoff సిద్ధమైన పరిసరంలో GNAT frontend మరియు binder అందుబాటులో లేవు. అందువల్ల ఈ దశను స్థానికంగా compile/run చేసి GREEN అని ధృవీకరించలేకపోయాం. `STAGE_01_EXECUTION_STATUS.txt` మరియు `DEVELOPMENT_STAGE.md` ఈ స్థితిని నిజాయితీగా నమోదు చేస్తాయి. విజయవంతమైన Ada run లేకుండా Stage 1 పూర్తయిందని ఈ ప్యాకేజీ ప్రకటించదు.
