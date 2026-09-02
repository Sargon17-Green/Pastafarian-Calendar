# Stage 1 నిర్మాణ గమనిక

ఈ దశలో production monster ఇంకా నిర్మించబడలేదు. ఉద్దేశపూర్వకంగా భవిష్యత్తు legacy లోపాలు లేదా patches ముందుగానే చేర్చలేదు.

`Monster_Bootstrap` లో invocation కు మాత్రమే చెందిన `Monster_Context` ఉంది. అందులో immutable input, lifecycle స్థితి, dispatcher స్థితి, పరిమిత retry/recovery స్థలాలు, commit token, metrics shell మరియు deterministic error code ఉన్నాయి. ఈ దశలో వీటిలో ఏదీ నార్మేటివ్ క్యాలెండర్ ఫలితాన్ని లెక్కించదు.

`Base_Dispatch` ఒక చిన్న state machine. `Base_Validate` సాధారణ validation పొర. `Execute_Bootstrap` error boundary గా పనిచేస్తుంది. ఇవి భవిష్యత్తులో నిర్మాణం పెరగడానికి సాధారణ ఆధారం మాత్రమే; ఏ నిర్దిష్ట patch యొక్క ప్రవర్తనను ముందుగానే కలిగి ఉండవు.

`Normative_Oracle` పూర్తిగా test-only భావనలో స్వతంత్రంగా ఉంది. production skeleton దానిని పిలవదు. Oracle లో day counts, రాళ్లు, దాచిన మరియు కనిపించే చుక్కలు, కుండల క్రమం, pours, simultaneous bowl updates, A1 post-stir అర్థం, answer streams, short/wide selection, gates, year 5000, sequential year walk, కట్లెట్ partition DP, distinct-name unranking, bounded month-length DP, whole-weave DP మరియు ఐదు-field ఫలితం ఉన్నాయి.

Semantic state మరియు observability state ఈ దశ నుంచే వేరు చేయబడ్డాయి. Metrics విలువలు dispatch/validation సంఖ్యలను మాత్రమే నమోదు చేస్తాయి; అవి semantic decision కు input కావు.
