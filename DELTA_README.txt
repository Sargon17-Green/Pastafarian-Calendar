JavaScript + Interlingue browser-interface delta v6

This delta continues the external browser-interface work after localized calendar names.

Main changes
------------
1. CalendarService now uses BoundedCalendarMemory by default.
   - 2048 exact conversion entries.
   - 8 cutlet-view entries.
   - local process memory only; no storage/network/persistence.
   - every key is isolated by calculationDay.

2. Cutlet-view memory is range-aware.
   A cached view for one target can serve any later target inside the same cutlet by
   retargeting selectedDay/selectedIndex over the same immutable day array.

3. convert() can answer directly from a cached cutlet-view.
   This avoids a new Worker/core call after a cutlet was already derived.

4. Identical concurrent conversion/getCutletView requests are coalesced.
   Multiple components asking the same semantic question share one in-flight Worker call.

5. retry/dispose generation isolation.
   An asynchronous request that began before retry cannot repopulate semantic memory
   after the retry, even with a custom engine client that settles late.

6. Stronger executable browser-layer tests.
   - browser-engine-client.js validates Worker reuse, serialization, fatal errors,
     retry recovery and timeout cleanup.
   - browser-worker-runtime.js executes the actual Worker entry message protocol against
     a black-box fake core and verifies convert/getCutletView/error paths.
   - browser-interface-service.js now covers LRU eviction, range reuse, calculation-day
     isolation, in-flight coalescing, cutlet-backed conversion, and stale completion.

Local fixture QA
----------------
PASS: browser-stage01-compatibility
PASS: browser-interface-service
PASS: browser-engine-client
PASS: browser-worker-runtime
PASS: browser-interface-contract
PASS: browser-interface-black-box
PASS: browser-i18n-locales
PASS: browser-interface-all
PASS: scripts/build-browser.js
PASS: browser-built-artifacts

The fixture uses the same browser layer and a deterministic stub core for build/runtime
protocol verification. This delta does not modify src/** or the normative core.
