# முதல் கட்ட கட்டமைப்பு

## தனித்துவமான தொடக்கம்

இந்த செயலாக்க வரி வெற்றிடத்திலிருந்து உருவாக்கப்பட்டது. வேறு programming-language செயலாக்கத்தின் source, test, fixture, output, log, snapshot, generated table, checksum அல்லது oracle எதுவும் semantic அல்லது validation உள்ளீடாகப் பயன்படுத்தப்படவில்லை.

## production எல்லை

`pastafari_sql_tamil` schema Stage 1-இல் பின்வரும் பொதுவான அமைப்புகளை மட்டும் கொண்டுள்ளது:

- ஒவ்வொரு அழைப்பிற்கும் தனியே உருவாக்கப்படும் `monster_context` composite;
- நடுநிலையான `base_dispatch` மற்றும் `base_validate_context`;
- semantic முடிவில் வாசிக்கப்படாத metrics/log tables;
- Stage 54க்கு முன் tuple வழங்காத `calendar_date_spaghetti` skeleton.

எந்த future patch flag, legacy defect, ghost path, latch, detour அல்லது compatibility repair-உம் இந்த கட்டத்தில் இல்லை.

## சோதனை reference எல்லை

`pastafari_sql_tamil_test` schema Appendix A-இன் சுத்தமான reference-ஐ SQL-இல் மட்டும் நிறுவுகிறது. Production schema test schema-வை அழைக்காது. Reference முழு நாள்காட்டி பாதைக்கு தேவையான நாள்-மனைகள், கற்கள், மறை/வெளித் துளிகள், கிண்ணங்கள், பிந்தைய கிளறல்கள், பதில் வளையம், gate-கள், ஆண்டுகள், பெயர் unrank, bounded composition, cutlet partition, month weaving மற்றும் இறுதி ஐந்து புலங்கள் ஆகியவற்றை வரையறுக்கிறது.

## துல்லிய முழு எண் நடைமுறை

பெரும் எண்ணான `2^127-1` நேரடியாக துல்லிய `numeric` literal ஆக வைக்கப்பட்டுள்ளது. Square கணக்குகள் `x*x` என்ற முழு எண் பெருக்கலால் செய்யப்படுகின்றன. Gate index-கள் `numeric` ஆகவே தக்கவைக்கப்படுகின்றன; தொலைதூர காலங்களில் `bigint` overflow வராதபடி `numeric_series` பயன்படுத்தப்படுகிறது.

Bounded composition எண்ணிக்கைக்கு inclusion-exclusion பயன்படுத்தப்படுகிறது. `binomial_exact` ஒவ்வொரு படியிலும் துல்லிய integer division கொண்ட multiplicative recurrence மூலம் binomial எண்ணை கணக்கிடுகிறது. இது முழு பட்டியலை materialize செய்யாமல் Appendix A-இன் அதே எண்ணிக்கையைத் தருகிறது.

உள் calculation-day gate கட்டாயமாக cutlet boundary ஆக வேண்டிய family-க்கு, boundary-க்கு முன் மற்றும் பின் உள்ள positive compositions-ன் binomial எண்ணிக்கைகள் கூட்டப்படுகின்றன. Unrank இன்னும் candidate prefix-களை ஏறுவரிசையில் பரிசோதித்து block அளவுகளை கழிப்பதால் lexicographic வரிசை மாறாது.

Month weaving-க்கு Appendix A state-ஐ நேரடியாக வைத்த exact memoized DP பயன்படுத்தப்படுகிறது. இது பட்டியலை உருவாக்காது; state count மற்றும் lexicographic unrank மட்டுமே செய்கிறது. Cache key-இல் original lengths, remaining counts, opened boundary மற்றும் closed boundary அனைத்தும் இருப்பதால் cache history semantic பதிலை மாற்றாது.
