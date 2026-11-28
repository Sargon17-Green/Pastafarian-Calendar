# מגילת העיתים — Dart + עברית

זהו קו־מימוש חדש ועצמאי שנבנה מאפס עבור Dart, כאשר עברית היא שפת המקור האנושית היחידה שלו.

שלב 1 הוא שלב אתחול בלבד. בשלב זה נבנו קטלוג שמות קנוני וקפוא, oracle נקי לצורכי בדיקה בלבד, שלד production ניטרלי, מנהל בסיסי, dispatcher בסיסי, שכבת אימות בסיסית, מעטפת שגיאות ומעטפת מדדים. לא הוכנס שום טלאי עתידי ואף רכיב legacy של שלבים 2–53.

## קטלוג השמות

הסדר הנורמטיבי נקבע אך ורק לפי `canonicalIndex`. מאחר ששפת המקור האנושית היא עברית, שמות בעלי משמעות נשמרים בעברית כמשמעותם במקור. שמות מקומות נשמרים בכתיב העברי של המקור. צירופי הקולות חסרי המשמעות "פַּלְגּוּרַשׁ" ו"כַּרְשׁוּמַב" נשמרים כצירופי קולות ואינם מקבלים משמעות מומצאת.

אין מיון לפי אלפבית, Unicode או locale. מחרוזת השם אינה משתתפת ב־rank, unrank, בחירה, cache או כל החלטה סמנטית אחרת.

## הרצה

כאשר Dart SDK זמין:

```text
dart run bin/stage1_tests.dart
```

ליצירת fixtures מחדש באותו קו־מימוש בלבד:

```text
dart run tool/generate_stage1_fixtures.dart
```

## Production CLI and distribution

The public CLI is implemented in `bin/pastafari_calendar_cli.dart` and emits JSON. It supports signed proleptic-Gregorian years and uses the same fixed calculation date `c` throughout §R traversal.

Forward conversion:

```sh
dart run bin/pastafari_calendar_cli.dart forward --calculation-date=2026-11-28 --requested-date=2026-11-28
```

Inverse conversion accepts the five numeric components returned by a forward conversion:

```sh
dart run bin/pastafari_calendar_cli.dart inverse --calculation-date=2026-11-28 --year-number=N --cutlet-index=N --day-in-cutlet=N --month-index=N --day-in-month=N
```

Use `--max-transitions=0..64` to set the bounded §R walk (default: 64). Run `dart run bin/pastafari_calendar_cli.dart --help` for the machine-readable usage response. The inverse rejects inconsistent cutlet/month coordinates and never guesses a serial day.

The package intentionally declares `publish_to: none`: no pub.dev publication or GitHub Release is performed. A Windows x64 self-contained executable and source bundle are produced only as a CI artifact after the required Native and public-API gates pass.
