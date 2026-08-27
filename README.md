# SQL + தமிழ் — முதல் கட்ட தொடக்க விதை

இந்த அடைவு எந்த முன் repository அல்லது வேறு செயலாக்கத்தையும் அடிப்படையாகக் கொள்ளாமல், வெற்றிடத்திலிருந்து உருவாக்கப்பட்ட தனித்துவமான SQL செயலாக்க வரியின் Stage 1 மட்டும் கொண்டுள்ளது.

செயலாக்க மொழி PostgreSQL SQL. இயக்கப்படும் function-கள் அனைத்தும் `LANGUAGE SQL` மட்டுமே. மனித மூல மொழி தமிழ். பெயர் உரை semantic கணக்கில் பயன்படுத்தப்படாது; மாற்றமற்ற `canonicalIndex` மட்டுமே rank, unrank, தேர்வு மற்றும் cache அடையாளத்திற்கு அதிகாரப்பூர்வமானது.

இந்த கட்டத்தில் production இன்னும் முழு நாள்காட்டி முடிவைத் தராது. அது பொதுவான invocation context, dispatcher, validator, error/observability shell ஆகிய நடுநிலையான அடுக்குகளை மட்டும் நிறுவுகிறது. வரலாற்றுப் பிழைகள் 01–26 மற்றும் அவற்றின் patch-கள் எதுவும் முன்கூட்டியே சேர்க்கப்படவில்லை. சோதனைக்கான சுத்தமான Appendix-A reference தனியான `pastafari_sql_tamil_test` schema-வில் உள்ளது; production entry point அதை அழைக்காது.

அனைத்து நெறிமுறை முழு எண் கணக்குகளும் PostgreSQL `numeric` மூலம் துல்லியமாக நடத்தப்படுகின்றன. மிதவைப் புள்ளி வகைகள், logarithm, floating-point ranking மற்றும் `bigint`-க்கு gate index சுருக்கம் பயன்படுத்தப்படவில்லை.

## ஏற்றும் வரிசை

புதிய PostgreSQL database-இல் பின்வரும் கோப்புகளை வரிசையாக இயக்க வேண்டும்:

1. `sql/00_schema.sql`
2. `sql/01_source_language_catalog.sql`
3. `sql/02_monster_bootstrap.sql`
4. `sql/test/10_normative_reference.sql`
5. `sql/test/20_stage01_tests.sql`

`psql` பயன்படுத்தினால் ஒவ்வொரு கோப்பையும் `-v ON_ERROR_STOP=1` உடன் இயக்குவது பரிந்துரைக்கப்படுகிறது. Test கோப்பு transaction-க்குள் assertions-ஐ இயக்குவதால் ஒரு assertion தோல்வியடைந்தால் பச்சை முடிவு வெளிவராது.

## தற்போதைய நிலை

இந்த artifact உருவாக்கப்பட்ட உள்ளூர் சூழலில் PostgreSQL server/`psql` runtime இல்லை. எனவே SQL execution நடத்தப்பட்டதாகக் கூறப்படவில்லை. நிலையான கோப்பு ஆய்வுகள் செய்யப்பட்டுள்ளன; ஆனால் Stage 1 முழுமையாக முடிந்ததாகக் கருத PostgreSQL runtime-இல் test கோப்பு வெற்றிகரமாக இயங்க வேண்டும்.
