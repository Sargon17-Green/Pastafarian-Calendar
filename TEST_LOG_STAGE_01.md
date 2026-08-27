# יומן אימות שלב 1

תאריך האימות: 2026-08-27

## תחום האימות

האימות הוגבל לשלב 1 של קו Dart + עברית. לא נוספה functionality חדשה, לא הוכנס קוד של טלאים עתידיים ולא התחיל שלב 2.

`pubspec.yaml` דורש Dart בטווח `>=3.0.0 <4.0.0`. לצורך האימות נבחרה גרסת stable הנוכחית `3.13.2`, המתאימה לטווח זה.

## בדיקת סביבת ההרצה

המערכת המקומית היא Linux x86_64.

הפקודות והתוצאות:

```text
$ command -v dart
<אין פלט>
exit=1

$ command -v flutter
<אין פלט>
exit=1

$ apt-cache policy dart
<אין חבילת dart זמינה במטמון המקומי>
exit=0
```

נבדקה גם נגישות ארכיון ה־SDK הרשמי:

```text
$ curl -I --max-time 5 https://storage.googleapis.com/dart-archive/channels/stable/release/3.13.2/sdk/dartsdk-linux-x64-release.zip
curl: (6) Could not resolve host: storage.googleapis.com
exit=6
```

לכן לא ניתן היה להתקין Dart SDK בסביבת ההרצה הזאת. החסם הוא נגישות רשת/זמינות כלי ההרצה, ולא failure שנצפה בקוד Dart.

## פקודות Dart שנדרשו

הפקודות הבאות לא הורצו, משום שאין executable של Dart זמין:

```text
dart --version
dart format --output=none --set-exit-if-changed .
dart analyze
dart run bin/stage1_tests.dart
```

מצב כולן: `BLOCKED_BY_MISSING_DART_SDK`.

לא קיים בפרויקט `analysis_options.yaml` או `analysis_options.yml`, ולכן לא נמצאה תצורת analyzer ייעודית נוספת.

## בדיקות סטטיות שאינן מחליפות הרצת Dart

בוצעה סריקה של `lib`, `bin` ו־`tool` אחר סמלים ייחודיים לטלאים עתידיים, ובהם `oldRemainder`, `savePatch`, `oldDayTag`, `mutateStonesWrong`, `LEGACY_YEAR_MAX`, `oldJumpGuess`, `VirtualLegacyList` ונתיבי legacy נוספים. תוצאה: `NO_MATCHES`.

בדיקה זו מוכיחה רק שלא זוהתה זליגה גלויה של קוד מטלאים עתידיים בקבצים שנבדקו; היא אינה תחליף ל־formatter, analyzer או tests של Dart.

## תוצאה

```text
SDK_INSTALL=BLOCKED
DART_VERSION_RUNTIME=UNAVAILABLE
FORMATTER=NOT_RUN
ANALYZER=NOT_RUN
STAGE1_TESTS=NOT_RUN
FUTURE_PATCH_SYMBOL_SCAN=PASS
STAGE1_VERIFICATION=INCOMPLETE
LAST_COMPLETED_STAGE=0
```

אין לסמן את שלב 1 כ־GREEN ואין לעדכן `LAST_COMPLETED_STAGE=1` עד להרצה בפועל של פקודות Dart ולקבלת תוצאות תקינות.
