# टप्पा 23 — PATCH 11: DROP_46 नंतर एकदाच immutable order latch

## मूळ दोषाला न बदलता दुरुस्ती

Stage22 मधील `src/discovery11LegacyOrderMemory.ts` आणि `LegacySharedOrderMemoryAdapter` पूर्णपणे unchanged. ऐतिहासिक shared six-cell buffer वर `DROP_1` ते `DROP_46` व `STIR_1` ते `STIR_12` — एकूण **58 खऱ्या writes** — होतातच. जुनी `queryLegacyOrder()` अजूनही overwritten `STIR_12` order वाचते; अकरावा intentionally-red `test/discovery11Red.ts` archive कायम.

नवीन `src/patch11OrderLatch.ts` मध्ये `Patch11Drop46LatchAdapter` स्वतंत्र `orderAt46Latch` तयार करतो. Corrected handler जुन्या `Discovery11OverwrittenOrderHandler` ला पूर्ण 58 write sequence वर चालवतो, त्याच्या **actual write callback index 46 नंतरच** `patch08Permutation(c,t,visible[46]).order` या production algorithm कडून DROP46 चा क्रम पुन्हा काढून **एकच immutable detached clone** करतो. येथे forensic ledger मधून semantic latch वाचलेला नाही. Stage22 workflow पुढे 12 post-stirs पार पाडतो, original shared memory अजून 12 वेळा overwrite करतो, wrong historical query `STIR_12` वाचतो. मात्र patched semantic query `Patch11Drop46LatchAdapter.queryOrder()` **फक्त स्वतंत्र saved latch वरून** नवीन frozen copy देते.

Outer `MonsterContext` हा child legacy context पेक्षा स्वतंत्र; 58 rounds मध्ये injection exception आल्यास user-provided input आणि outer context बदलेले नाहीत. Success नंतर branchTrace/metrics मध्ये चार processing phases, एक latch write, एक semantic query, एक real legacy query, 58 shared writes, 46 patched drop rounds, 12 post-stirs स्पष्ट. `orderAt46Latch`, `correctedQueryOrder`, historical ledger आणि legacy output सर्व स्वतंत्र references.

## Native TypeScript व QA योजना

- `test/patch11.ts`: 12 normative real day-pairs × positions 1,2,6 = **36 corrected comparisons, 0 mismatches**; जुन्या स्मृतीत **32 wrong / 4 accidental matches**. Every 58 shared writes plus exactly one latch at 46; all six-bowl drop and final post-stir arrays exact normative oracle; frozen detached aliases, physical legacy method instrumentation (58 writes, same old memory), invalid order/arrays/lifecycle, six deterministic failure boundaries (writes 1,45,46,47,52,58), retry/reentrancy.
- `test/patch11Properties.ts`: 12 actual day-pairs + 64 deterministic changed drop1/drop46 + 8 signed giant datasets = 84 full sequences, historical three-position comparisons 206 wrong /46 accidental same preserved. Additionally test each of **720 possible DROP46 permutations** in a distinct full 46+12 sequence; **804 total sequences**, 804 ×58 = **46632 actual shared writes**, 804×6=**4824 corrected order-cell comparisons, zero wrong**; 720 distinct canonical order values and all final bowl outputs independently test-only validated.
- `npm test` continues all Stages1–23. All eleven previous archival expected-red tests are independent nonzero failures enforced in GitHub Actions; their sources and workflow steps unchanged. TypeScript `tsc --noEmit` native.
- `calendarDateSpaghetti` Stage54 पूर्वी unsupported. Stage24 DISCOVERY12 / Stage25 PATCH12 किंवा later next-bowl rule या stage मध्ये अजून नाही.

**स्थिती:** CI GitHub Actions verification प्रलंबित. Verified successful run शिवाय LAST_COMPLETED_STAGE=22 कायम.
