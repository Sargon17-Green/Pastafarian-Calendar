# መጽሐፈ ዘመን — ግዕዝ

መጽሐፍ · ዕለት · ዘመን

SM83-Assembly+ግዕዝ is an independent, from-zero Assembly branch for the original monochrome Nintendo Game Boy (DMG). Production code uses only SM83 instructions assembled with RGBDS. The human source language is Classical Ge'ez, distinct from modern Amharic and Coptic.

CURRENT_STAGE=1 (BOOTSTRAP). LAST_COMPLETED_STAGE=0. No Pastafarian date has been computed and no full Stage-1 verification has been claimed. The source-language names and classical-language review are outstanding; English technical notes here are a declared localization gap, not Ge'ez text.

Build a real 32 KiB MBC5+RAM ROM with make build; the compatible cartridge supplies 128 KiB of banked external RAM. Run the independent emulator inspection with make test (RGBDS and PyBoy required). ROM WRAM C000 = A5 means the smoke suite passed (most recently 33 verified tests; 40-case extension pending), E0 means a failed check; C001 is the case number. WRAM C002 = 40 explicitly marks that the calendar dispatcher is not yet implemented. Unsigned 128x128 multiplication with a full 256-bit output and 256-bit SAVE reduction are now implemented in Assembly. Arithmetic smoke tests are not a substitute for the normative Stage-1 oracle and full calendar implementation.

The authoritative calendar rules and canonical content remain available in the main branch. Never import a production implementation from another language branch. Keep the historical 55-stage BOOTSTRAP, DISCOVERY, PATCH, INTEGRATION and AUDIT sequence, without jumping to later patches.

See DEVELOPMENT_STAGE.md, SPAGHETTI_DEVELOPMENT_HISTORY.md, docs/ARCHITECTURE.md, and docs/SOURCE_LANGUAGE_CATALOG.md.
