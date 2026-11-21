# Object Pascal Stage 1: supplementary Portuguese static-label encoding audit (2026-11-21)

Project: PC-BRANCH-OBJECT-PASCAL-PORTUGUESE
Authorized branch: `Object-Pascal+Português`
Verified parent HEAD: `fd5f8ff21ea5a526e1e4c60f26c67a370e7b01d4`, base tree `a9ea04c7f8c0ffa82afbe35738a592fcced8f929`.

## Completed native gates before this correction
- Native: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44937659213, job 136947731805, completed SUCCESS, attempt 1, exact parent SHA.
- Names Lock: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44937659217, job 136947731663, completed SUCCESS, attempt 1, same SHA.
- Real native artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44937659213/artifacts/14722212337; ZIP 4,080 bytes, independently recomputed SHA-256 `2cfb8943c19178d2a34a7d0abe56c3c02753477e410d6409091cbd03c862024c`, equal to API digest and uploader. ZIP CRC passed.
- Original `stage01-native-fpc.log` bytes: 29,899, SHA-256 `a1ce30057f77c8c5ada54b897123424e5d11f59f73dc6f5d53dcbb061d94334f`. Strict UTF-8 decoding PASS.
- Independently counted 30 suite exit markers, all zero; independently parsed 30 suite summaries totaling 22,977/22,977 checks and zero failures.
- Earlier whole-log UTF-8 PASS and 12/12 dynamic label exact-byte PASS are accepted only in this scoped, exact-SHA sense.

## Distinct semantically invalid UTF-8 output
Even though every byte is valid UTF-8, seven static assertion labels are double-encoded. Exact observed -> intended examples:
- `OK: BigInt subtraÃ§Ã£o` -> `OK: BigInt subtração`
- `OK: BigInt multiplicaÃ§Ã£o simples` -> `OK: BigInt multiplicação simples`
- `OK: BigInt mÃ³dulo euclidiano negativo` -> `OK: BigInt módulo euclidiano negativo`
- `OK: diferenÃ§a Tablets-Foundation` -> `OK: diferença Tablets-Foundation`
- `OK: permutaÃ§Ã£o rank 1` -> `OK: permutação rank 1`
- `OK: permutaÃ§Ã£o rank 720` -> `OK: permutação rank 720`
- `OK: drop mÃºltiplo de 720` -> `OK: drop múltiplo de 720`

All seven labels flow through `AssertBig` or `AssertOrder`, which accepted `Name: string` before forwarding to a `UnicodeString` diagnostic. This permits an unnecessary intermediary conversion. Proposed bounded fix makes these parameter types `UnicodeString`, matching already correctly handled direct `AssertTrue` and `AssertEqualText` names.

## Independent regression contract
Input: unmodified ZIP artifact produced by Native on the new exact SHA; inspect original byte stream.
- Existing strict whole-log UTF-8 gate still PASS.
- Existing 12 dynamic Portuguese exact labels once each, zero ISO-8859-1 legacy output.
- New static-label Python literal oracle requires 7/7 exact UTF-8 lines once each; none of the seven UTF-8-through-Latin-1 double-encoded variants may appear.
- 30/30 process exits zero, 22,977/22,977 summary assertions, zero failures; Names Lock SUCCESS at exact SHA; ZIP digest recomputed independently equals API/uploader; CRC PASS.
- No source algorithm, production code, fixture, calendar policy, canonical names, main or merge modified. Pending Native evidence is **not** a PASS until real completed run and artifact inspection.
- Global Stage 1 remains NOT ACCEPTED because the 12/13 October original source-patch provenance is absent. Previous searches exhausted; do not repeat without new evidence.
