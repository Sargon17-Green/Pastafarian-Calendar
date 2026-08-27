# முதல் கட்ட ஒப்படைப்பு

## ஒப்படைப்பு வகை

இது delta அல்ல. முன் repository எதுவும் இல்லாததால், இது வெற்றிடத்திலிருந்து உருவாக்கப்பட்ட முழு Stage 1 seed package.

## சேர்க்கப்பட்ட கோப்புகள்

- `README.md`
- `ARCHITECTURE_STAGE_01.md`
- `SOURCE_LANGUAGE_CATALOG.md`
- `SPAGHETTI_DEVELOPMENT_HISTORY.md`
- `DEVELOPMENT_STAGE.md`
- `MANIFEST`
- `sql/00_schema.sql`
- `sql/01_source_language_catalog.sql`
- `sql/02_monster_bootstrap.sql`
- `sql/test/10_normative_reference.sql`
- `sql/test/20_stage01_tests.sql`
- `artifacts/stage-01/TEST_RESULTS.md`

## இந்த கட்டம் நிறுவுவது

தமிழ் `SourceLanguageCatalog` 17 கறி-துண்டுப் பெயர்களும் 47 மாதப் பெயர்களும் கொண்ட, வரிசை நிலையான non-updatable view ஆக உறையவைக்கப்பட்டுள்ளது. சோதனை reference முழுவதும் SQL-இல் மட்டுமே உள்ளது. Production பகுதி test oracle-ஐ அழைக்காது; neutral context/dispatcher/validator/observability அடுக்குகளை மட்டும் கொண்டுள்ளது. Patch 01–26 சார்ந்த code எதுவும் இல்லை.

## உள்ளூர் சரிபார்ப்பு

Artifact சூழலில் PostgreSQL runtime இல்லை. ஆகவே SQL assertions இயக்கப்படவில்லை. நிலையான ஆய்வில் வேறு programming-language source file இல்லை; SQL function language declaration-களில் SQL தவிர வேறு runtime இல்லை; floating-point வகை, logarithm, `power`, அல்லது gate index-ஐ `bigint`-க்கு குறைக்கும் cast இல்லை.

Runtime கிடைக்கும் இடத்தில் ஐந்து SQL கோப்புகளையும் README-யில் கொடுக்கப்பட்ட வரிசையில் இயக்க வேண்டும். `sql/test/20_stage01_tests.sql` முழுவதும் வெற்றியடைந்த பிறகே Stage 1 முடிந்ததாகக் குறிக்க வேண்டும்.

## பரிந்துரைக்கப்படும் commit தலைப்பு

`SQL மற்றும் தமிழ் செயலாக்க வரிக்கான முதல் கட்ட விதையை உருவாக்கு`

## பரிந்துரைக்கப்படும் commit உட்பொருள்

`முன் repository அல்லது வேறு மொழி செயலாக்கத்தை அடிப்படையாகக் கொள்ளாமல் SQL + தமிழ் செயலாக்க வரியின் Stage 1 விதையை வெற்றிடத்திலிருந்து உருவாக்குகிறது. 17 கறி-துண்டுப் பெயர்களும் 47 மாதப் பெயர்களும் கொண்ட தமிழ் SourceLanguageCatalog மாற்றமற்ற canonicalIndex வரிசையுடன் உறையவைக்கப்படுகிறது. Appendix A-இன் சுத்தமான test-only reference PostgreSQL LANGUAGE SQL-இல் நிறுவப்படுகிறது. Production பகுதியில் ஒவ்வொரு invocation-க்கும் தனி context, அடிப்படை dispatcher, validator மற்றும் observability shell மட்டுமே உள்ளன; patch 01–26 எதுவும் முன்கூட்டியே இல்லை மற்றும் production oracle-ஐ அழைக்காது.`

`உள்ளூர் artifact சூழலில் PostgreSQL runtime இல்லாததால் execution test இன்னும் நடத்தப்படவில்லை. Runtime உள்ள சூழலில் Stage 1 SQL assertions அனைத்தும் பச்சையாகிய பிறகே அடுத்த கட்டத்துக்கு செல்ல வேண்டும்.`

## GitHub-க்கு தயாரான குறிப்பு

`Stage 1 / 55 மட்டும். இது ஒரு full seed; ஏற்கனவே உள்ள tree-க்கு delta அல்ல. SQL மட்டுமே executable மொழியாக பயன்படுத்தப்பட்டுள்ளது, தமிழ் மூலப்பெயர் catalog canonicalIndex மூலம் உறையவைக்கப்பட்டுள்ளது, clean reference test-only schema-வில் உள்ளது, production oracle-ஐ அழைக்காது. PostgreSQL runtime-இல் Stage 1 tests பச்சையாகும் வரை Stage 2 தொடங்கப்படக்கூடாது.`

## பயனர் செய்ய வேண்டியது

இந்த package-ஐ புதிய repository-யின் தொடக்க உள்ளடக்கமாக வைக்கலாம். முதலில் PostgreSQL-இல் Stage 1 tests-ஐ இயக்கி முடிவை உறுதிப்படுத்த வேண்டும். அந்த test output அல்லது CI log அடுத்த பதிலில் வழங்கப்பட்டால், Stage 1-ஐ மட்டும் revalidate அல்லது திருத்த வேண்டும்; Stage 2-ஐ அதே பதிலில் தொடங்கக்கூடாது.
