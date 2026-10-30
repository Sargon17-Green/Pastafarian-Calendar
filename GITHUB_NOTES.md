# GitHub ਲਈ ਨੋਟ

ਇਹ handoff ਸਿਰਫ਼ Stage 1 — Bootstrap ਹੈ। BASIC implementation LibreOffice Basic / StarBasic ਵਿੱਚ ਹੈ ਅਤੇ ਮਨੁੱਖੀ source language ਪੰਜਾਬੀ ਗੁਰਮੁਖੀ ਹੈ।

Implementation ਕਿਸੇ ਹੋਰ language line ਤੋਂ port ਨਹੀਂ ਕੀਤਾ ਗਿਆ। Oracle, fixtures ਅਤੇ tests embedded normative reference ਤੋਂ ਇਸੇ line ਵਿੱਚ ਮੁੜ ਬਣਾਏ ਗਏ ਹਨ। Cross-implementation hashes ਜਾਂ differential outputs ਵਰਤੇ ਨਹੀਂ ਗਏ।

Arbitrary-precision day values, answer offsets ਅਤੇ logical gate indices decimal strings ਵਰਤਦੇ ਹਨ। Frozen `SourceLanguageCatalog` ਵਿੱਚ 17 ਕਟਲੈਟ ਅਤੇ 47 ਮਹੀਨਾ ਨਾਂ canonicalIndex ਨਾਲ ਸਥਿਰ ਹਨ।

Production path ਇਸ ਪੜਾਅ ਵਿੱਚ ਸਿਰਫ਼ neutral skeleton ਹੈ; ਕੋਈ future defect ਜਾਂ patch ਪਹਿਲਾਂ ਨਹੀਂ ਆਇਆ। Local test result: `OVERALL=PASS`।

Stage 2 — DISCOVERY 01 ਦਾ ਵੱਖਰਾ commit legacy remainder defect ਅਤੇ exact expected-RED test pattern ਰੱਖਦਾ ਹੈ। Stage 1 ਦੀ ਪੁਰਾਣੀ native PASS ਰਿਪੋਰਟ ਬਦਲੀ ਨਹੀਂ; Stage 2 native CI ਅਜੇ verify ਕਰਨੀ ਹੈ।
