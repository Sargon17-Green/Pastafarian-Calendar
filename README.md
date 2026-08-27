# Pastafari-kalendern — Haxe + svenska

Detta arkiv är den självständiga början på en ny implementeringslinje. Den har skapats från noll för programmeringsspråket Haxe och källspråket svenska. Inget annat kalenderutförande har använts som kodkälla, testkälla, orakel, tabell, fixtur, kontrollsumma eller jämförelsegrund.

## Steg 1 av 55

Steg 1 innehåller fyra saker:

- ett fryst `SourceLanguageCatalog` med 17 kotlettnamn och 47 månadsnamn, ordnade enbart efter `canonicalIndex`;
- ett rent testorakel som följer den inbäddade normativa referensen;
- exakt heltalsaritmetik med godtycklig precision, skriven i Haxe utan främmande körmiljö;
- ett neutralt produktionsskelett med kontext, dispatcher, validering och mätarskal, men utan någon framtida historisk felväg eller korrigering.

`calendarDateSpaghetti` är därför ännu inte en färdig kalenderfunktion. I steg 1 bygger den endast den neutrala infrastrukturen och avbryter därefter uttryckligen. Den fullständiga produktionsvägen skall växa historiskt under senare steg och får inte förhandsimplementeras här.

## Test

Kör från arkivets rot:

```text
haxe test.hxml
```

Ett godkänt steg skriver maskinkoderna:

```text
STAGE_01_PASS
STAGE_01_AUDIT_PASS
```

Testerna använder endast Haxe. `test.hxml` kör Haxes egen tolk. Inga externa bibliotek krävs.

## Normativ aritmetik

Ingen normativ beräkning använder flyttal. Den lokala typen `BigInt` lagrar decimaler exakt och implementerar addition, subtraktion, multiplikation, golvdivision och euklidisk rest med heltalsoperationer. Därmed kan både `M = 2^127 - 1` och större kombinatoriska antal representeras utan avkortning.

## Språklig källa

Svenska är den enda mänskliga källspråksversionen i detta arkiv. Maskinidentifierare, API-namn, filnamn och statuskoder behåller tekniska namn, men all skapad mänsklig prosa är svensk. Lokala namnval och translittereringsregler dokumenteras i `SOURCE_LANGUAGE_CATALOG.md`.
