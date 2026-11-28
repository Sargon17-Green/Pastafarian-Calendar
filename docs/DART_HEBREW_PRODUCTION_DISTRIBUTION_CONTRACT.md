# Production distribution contract — Dart+Hebrew

PROJECT_ID: PC-BRANCH-DART-HEBREW
TARGET: Windows x64 executable plus source bundle
STATUS: CI artifact only; no merge, GitHub Release or pub.dev publication.

## CLI contract

The executable exposes two commands and emits one JSON object on stdout.

- `forward --calculation-date=YYYY-MM-DD --requested-date=YYYY-MM-DD [--max-transitions=0..64]`: returns both civil dates, the requested serial day and the five Pastafarian components.
- `inverse --calculation-date=YYYY-MM-DD --year-number=N --cutlet-index=N --day-in-cutlet=N --month-index=N --day-in-month=N [--max-transitions=0..64]`: returns the serial day and Gregorian civil date.
- `--help` (or no arguments) returns a JSON usage object. Signed proleptic Gregorian years are accepted.
- `max-transitions` defaults to 64. Invalid options/components return exit code 2; bounded traversal refusal returns 3; unexpected runtime errors return 1; success returns 0.

The calculation date c is fixed throughout the §R year walk and inverse partition reconstruction. The inverse must validate that cutlet and month coordinates identify the same serial day; no best-effort result is permitted.

## Distribution

- Build on `windows-latest` with Dart SDK 3.13.2 using `dart compile exe`.
- Package contains the self-contained `pastafari-calendar.exe`, `RUN.cmd`, JSON smoke evidence, `pubspec.yaml`, README, library source and the production contracts.
- A SHA-256 sidecar is generated for the ZIP. The workflow uploads the ZIP, sidecar and JSON smoke evidence as a 30-day Actions artifact.
- The package job depends on Stage1 Native, §R year-walk, Stage2 production date, Stage3 public API, Stage4/5 consumer and production Gregorian/inverse gates.
- `publish_to: none` remains unchanged. No pub.dev publish, main merge, tag or GitHub Release is performed.

## Bounds and environment

- Dart SDK used to build: 3.13.2 stable.
- No external package dependencies or runtime network access.
- Year-number traversal is bounded to 64 transitions; the §Q streaming window remains bounded by its own 400,000-gap-call budget and retained-window contract.
- The executable is Windows x64-specific; the source bundle remains portable to Dart 3.13.2 environments.
