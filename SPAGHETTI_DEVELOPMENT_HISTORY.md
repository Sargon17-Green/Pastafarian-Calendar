# ஸ்பகெட்டி வளர்ச்சி வரலாறு

## கட்டம் 1 — தொடக்க விதை

### என்ன கட்டப்பட்டது

SQL + தமிழ் செயலாக்க வரி வெற்றிடத்திலிருந்து தொடங்கப்பட்டது. உறையவைக்கப்பட்ட தமிழ் `SourceLanguageCatalog`, SQL-இல் எழுதப்பட்ட test-only clean normative reference, மற்றும் பொதுவான per-invocation context/dispatcher/validator/observability அடுக்குகள் சேர்க்கப்பட்டன.

### இன்னும் என்ன நடக்கவில்லை

வரலாற்றுப் பிழை 01–26 இல் எதுவும் production பாதையில் சேர்க்கப்படவில்லை. அவற்றின் patch-களும் இல்லை. Production entry point oracle-ஐ அழைக்காது மற்றும் Stage 54க்கு முன் நாள்காட்டி tuple வழங்காது.

### இந்த கட்டத்தில் வளர்ந்த monster அடுக்கு

ஒவ்வொரு invocation-க்கும் தனியான composite context, அடிப்படை dispatcher, validation shell, deterministic metrics/log storage ஆகியவை மட்டும் சேர்க்கப்பட்டன. இவை semantic பதிலை உருவாக்குவதில்லை; எனவே இந்த கட்டத்தில் அவை semantic-ஆக நடுநிலையானவை.
