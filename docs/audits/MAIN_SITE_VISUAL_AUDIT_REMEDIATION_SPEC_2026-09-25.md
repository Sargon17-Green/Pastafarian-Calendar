# Main Site Visual Audit — Remediation Specification

Date: 2026-09-25  
Live site: https://sargon17-green.github.io/Pastafarian-Calendar/  
Publishing branch inspected: `JavaScript+Interlingue`  
Scope: main calendar site only. `/about/` and its translations are explicitly out of scope.

## 1. Purpose

This specification turns the completed human-style visual audit into an implementation contract.

It is intentionally stricter than a list of cosmetic tweaks. The live site is technically functional, but several current presentation decisions make the calendar hard to browse at intermediate widths and structurally unwieldy on phones. The repair must improve those surfaces without changing the normative Pastafarian calendar algorithm or its semantic outputs.

No change described here may be merged directly into a publishing branch before the complete QA matrix in section 10 passes.

## 2. Severity model

- **S0 — blocker:** core task impossible, destructive, or result visibly wrong. None observed in the audited ready state.
- **S1 — high:** major responsive/usability/correctness problem that materially impairs a normal user path.
- **S2 — medium:** substantial friction, hierarchy, density, or discoverability problem, but the task remains usable.
- **S3 — low:** polish, consistency, or visual refinement.
- **R — required product gap:** explicitly expected public functionality that is not presently exposed by the live UI.

## 3. Consolidated findings and severity

### S1. Calendar layout breaks at intermediate widths

Observed at 800 px:
- calendar viewport client width about 753 px;
- internal grid width about 928 px;
- day card width about 128 px;
- horizontal scrolling is required;
- cards become very tall because the three lines wrap heavily.

At 1024 px the seven-column layout does not overflow, but cards are already too narrow and visually dense.

**Required outcome**
- The number of columns must adapt before cards become unreadably narrow.
- A normal calendar view must never require horizontal scrolling at 800 px.
- A day card must not be squeezed below a readable minimum width merely to preserve seven columns.
- Seven columns are a presentation choice, not a semantic week structure; preserving seven columns is not a requirement.

**Acceptance**
- 1440, 1024, 800, 768, 390 and 320 px all render without horizontal calendar scrolling.
- No ordinary day card is narrower than approximately 11rem unless a deliberately different compact mobile representation is used.
- No text is hidden because a card was made narrower than its content can reasonably support.

### S1. The calendar is effectively unbounded and creates pathological mobile browsing

Initial ready state rendered approximately:
- 3 cutlet sections;
- 2,321 day cards;
- about 414,521 px of internal scroll height on 320/390 px mobile.

After scrolling far enough to trigger adjacent loads:
- 5 cutlet sections;
- 3,768 day cards;
- about 673,000 px of internal scroll height on mobile.

The present edge-loading behavior extends the scroll surface as the user approaches its edges.

**Required outcome**
- Browsing must have a bounded DOM and a comprehensible position model.
- Adjacent content may be cached, but thousands of full day cards must not accumulate in the live DOM.
- Reaching an edge must not silently grow the scroll universe without an obvious navigation transition.
- The user must be able to reach any intended day without needing to drag through hundreds of thousands of pixels.

**Implementation freedom**
Use one of:
- true list/grid virtualization;
- bounded windowing around the active/target day;
- explicit chunk/page navigation;
- active-cutlet replacement with bounded day windows;
- another design that satisfies the acceptance criteria.

Do not preserve the current unbounded append behavior merely with smaller cards.

**Acceptance**
- At any tested viewport, the rendered day-card count is bounded and does not grow monotonically after repeated previous/next browsing.
- A recommended hard target is at most 200 simultaneously rendered day cards.
- Repeated navigation through at least 20 adjacent ranges does not cause monotonic DOM growth.
- Returning to the target does not require manual long-distance scrolling.

### S1. Nested scroll architecture is too difficult on touch devices

The page scrolls vertically, then the calendar introduces a second vertical scroll region capped at `46rem`; at 800 px the calendar additionally introduces horizontal scroll; the cooking trace has its own horizontally scrollable chapter navigation.

**Required outcome**
- On phone and tablet layouts there must be only one primary vertical scroll owner for the calendar browsing experience.
- A user must not need to discover that the pointer/finger has entered a separate vertical-scroll universe in order to continue reading the calendar.
- Any retained secondary scroll region must be clearly bounded, deliberate and not compete with page scrolling.

**Acceptance**
- 320, 390, 768 and 800 px: normal day browsing works with one continuous vertical gesture.
- No simultaneous horizontal+vertical calendar scrolling is required.
- Opening/closing auxiliary UI does not unexpectedly reset the user's day position.

### S1. Sticky cutlet heading obscures day cards

The sticky cutlet heading visibly overlaps the top row while the internal viewport scrolls.

**Required outcome**
- Sticky headers may remain, but they must never cover readable card content.
- Either reserve the correct sticky offset, change the sticky model, or disable stickiness where it harms the layout.

**Acceptance**
- Screenshot at top/middle/bottom internal positions shows no day text behind an opaque heading.
- Keyboard focusing a card never places it under the sticky heading.

### S1. ISO dates are BiDi-unsafe in RTL prose

In Arabic, `2026-09-25` was visually reordered as `25-09-2026`. In narrow Hebrew layouts an ISO date could split after `2026-`.

This is a presentation-correctness issue, not merely typography.

**Required outcome**
- Machine-format ISO values remain visually and copyably `YYYY-MM-DD` in RTL and LTR UIs.
- ISO strings embedded in translated prose must be isolated as LTR directional runs.
- An ISO token must not wrap in the middle.

**Acceptance**
- Hebrew and Arabic show `2026-09-25` exactly in that order.
- Copy/paste yields the same string.
- 320 px does not split a single ISO token across lines.
- Use semantic isolation such as `<bdi dir="ltr">` / an equivalent robust isolation mechanism; do not rely on punctuation coincidence.

### S1. Error-state composition is structurally wrong

When the Worker was intentionally blocked, the visible error elements appeared in a confusing order/position: message, retry control and error heading were spatially separated as though they inherited the loading grid layout.

**Required outcome**
- Error state must be a single coherent component with a clear order:
  1. optional kicker;
  2. error heading;
  3. concise explanation;
  4. retry action.
- The user must not need to visually search for the associated retry button.

**Acceptance**
- Desktop and 320/390 mobile error screenshots show all error content as one bounded block.
- Retry remains visible without horizontal scrolling.
- When the failure is removed and retry is activated, the component recovers to ready state without page reload.

### R1. Public reverse search is absent

The requested audit included reverse search, but the published `<pastafari-date>` UI currently exposes only:
- Gregorian target date;
- optional calculation/action date.

No public reverse-search surface exists in the live site.

This is a feature gap rather than a CSS defect.

**Required outcome**
- Before implementing a new solver, locate the existing authoritative/previous reverse-search contract or implementation in project history.
- Do not invent reverse-search semantics from the presentation layer.
- Expose a clearly separate reverse-search entry point only after its normative behavior is identified.
- Include empty, invalid, no-match, in-progress and result states.
- The result must integrate with the same target/highlight/navigation model as ordinary Gregorian search.

**Acceptance**
- A user can start reverse search without knowing an internal API.
- Result selection lands on and visibly identifies the matched day.
- RTL/LTR, 320/390/800/1440 and keyboard-only use are covered.
- If no authoritative reverse-search contract exists, implementation stops and this item is reported as blocked rather than guessed.

### S2. No dedicated "return to searched date" action

After scrolling away, the toolbar offers previous cutlet, today, and next cutlet. "Today" is not equivalent to the user's searched target.

**Required outcome**
- When the active target is not today's date, provide an explicit way to return to the searched target.
- The control must restore both semantic target context and visible position.

**Acceptance**
- Scroll/navigate far away, activate the control, and the target card becomes visible and correctly highlighted.
- The control is not shown redundantly when target and today are the same unless wording remains unambiguous.

### S2. Mobile navigation hierarchy is broken into an awkward 2+1 arrangement

At narrow widths, previous + today occupy one row while next sits alone at full width.

**Required outcome**
- Previous/next must remain a perceptual pair.
- "Today" and "return to target" are separate center/reset actions.

**Acceptance**
- 320/390 px: previous and next have symmetric placement and comparable visual weight.
- Reset actions do not visually break the directional pair.

### S2. Target beacon is over-emphasized

The target result currently combines saturated yellow, very heavy black border, white ring, second black ring and deep shadow.

**Required outcome**
- Keep the target unmistakable, but reduce the number of simultaneous high-contrast emphasis devices.
- The target panel must read as the primary result, not as a warning/error alert.

**Acceptance**
- Target remains the first result users notice after calculation.
- It is visually distinguishable from error/warning states.
- At least one of the current competing emphasis layers (fill, multi-ring outline, very heavy shadow) is substantially reduced.

### S2. Selected day card uses too many simultaneous highlight mechanisms and clips on narrow screens

The selected card combines:
- thick white border;
- black outline;
- yellow outer ring;
- black outer ring;
- badge;
- dashed inner frame;
- scale transform.

At 320/390 px the visual decoration extends beyond the calendar viewport.

**Required outcome**
- Use a simpler selected-state system.
- Selection decoration must be included within layout bounds; no visual clipping.

**Acceptance**
- Selected card is obvious in color and monochrome.
- Card plus focus/selection decoration fits within the viewport at 320 px.
- No horizontal scrollbar appears solely because of selection styling.

### S2. Day-card visual density is excessive

Every card currently combines saturated month background/pattern with three separate boxed text rows.

**Required outcome**
- Preserve deterministic month identity, but reduce visual noise.
- Month identity should not require every card to be a fully saturated patterned tile.
- Ensure WCAG-sensible contrast for every month theme.

**Acceptance**
- A dense desktop grid can be scanned by date rather than primarily by background pattern.
- Adjacent month identities remain distinguishable.
- Forced-colors behavior remains functional.

### S2. Day cards repeat section-level information unnecessarily

Every day repeats year and cutlet identity even though those values are shared across long runs and already appear in surrounding context.

**Required outcome**
- Move stable context to section/header level where possible.
- Cards should prioritize values that distinguish one day from another.
- Full semantic information must remain in accessible labels and in the selected-target summary.

**Acceptance**
- Ordinary mobile day cards are materially shorter than today.
- A screen-reader user can still obtain the complete Pastafarian date for a card.
- The selected target can still show the complete five-field representation.

### S2. Cooking trace dominates document flow

Opening "how this date was cooked" inserts a very large inspector inline between the result and calendar controls. On mobile some chapters exceed 10,000 px in height.

**Required outcome**
- The trace must behave as an inspector, not as a giant insertion that displaces the primary calendar.
- Opening it must preserve the user's calendar position.
- Closing it must restore focus and the same calendar position.
- On mobile it should use a dedicated full-screen/sheet/dialog style surface or another bounded inspector model.
- On desktop a bounded dialog/side panel is preferred over unbounded inline expansion.

**Acceptance**
- Open/close trace 5 times: no calendar-position drift.
- Calendar navigation is not pushed many screens away while the trace is open.
- A chapter can be changed without returning to the beginning of a 10,000 px document.
- Escape closes it and returns focus to the opener.

### S2. Trace chapter navigation hides options off-screen

Nine chapter buttons are placed in a horizontally scrolling strip. On narrow screens only a subset is visible and there is little indication that more chapters exist.

**Required outcome**
- All chapter choices must be discoverable.
- Mobile may use wrapped tabs, a compact menu/select, a scroll strip with explicit affordances, or another accessible control.

**Acceptance**
- A first-time 320 px user can discover every chapter without guessing that an invisible horizontal overflow exists.
- Current chapter remains obvious.
- Keyboard and touch both work.

### S2. Trace data hierarchy is too dense

Schema identifiers, exact integers, step controls and nested cards compete at similar visual weight.

**Required outcome**
- Preserve exact schema identifiers where intentionally normative/technical.
- Visually separate human explanation, navigation, schema labels and exact values.
- Long integers must remain expandable without causing uncontrolled reflow.

**Acceptance**
- At 320/390 px no technical value causes document horizontal overflow.
- The chapter heading and current step are visually dominant over raw field labels.
- Expanded exact integers remain readable and collapsible.

### S2. Long-running loading state provides insufficient orientation

The normal calculation can remain in loading state for a noticeable period. The UI only shows a spinner and generic text.

**Required outcome**
- Do not invent fake percentages.
- Give the user truthful elapsed-time/status orientation after a reasonable delay.
- Distinguish "still calculating locally" from "failed".
- Provide a cancel/restart path only if the underlying service can support it safely; do not fake cancellation.

**Acceptance**
- At 2–5 seconds the loading state is concise.
- At a longer threshold the explanatory text changes to acknowledge a long local computation.
- Timeout/error transition is visually distinct from normal slowness.

### S2. Search panel has excessive dead space on wide screens

The question sits at one extreme and the CTA at the other, with a large empty middle region.

**Required outcome**
- Treat heading and action as one task group.
- Preserve responsive stacking on mobile.

**Acceptance**
- At 1440 px the relationship between question and CTA is visually immediate.
- CTA does not float as an isolated control on the far edge of a very wide card.

### S2. Masthead is oversized relative to the primary task

The title can reach roughly 7rem and dominates the first screen.

**Required outcome**
- Keep editorial character but reduce masthead dominance.
- Language control and title should read as one header system rather than distant islands.
- Primary date-search action remains immediately visible.

**Acceptance**
- 320/390 px: title, language selector and search CTA all remain comfortably accessible near the top without the brand consuming most of the first screen.
- 1440 px: title does not visually overpower the result/search hierarchy.

### S3. Language control feels detached at wide widths

**Required outcome**
- Rebalance masthead spacing and alignment when performing the masthead revision.
- No separate feature work is needed if the S2 masthead repair resolves it.

## 4. Explicit non-findings / things not to "fix"

The audit did **not** find evidence that the following need a redesign:

- The search dialog fits at desktop and mobile widths tested.
- The advanced calculation-date disclosure is usable.
- Empty/invalid input errors wrap without document overflow.
- A deliberately very long invalid input did not break page width.
- Keyboard focus indication is strong and visible.
- Locale direction switching itself works: Hebrew/Arabic are RTL and English/German are LTR.
- The normal tested ready flows did not emit JavaScript/page/request errors.
- Whole-document horizontal overflow was not observed; the important overflow defects are localized to calendar/selection components.

Do not rewrite these working surfaces merely for consistency unless a required repair makes a small change necessary.

## 5. Responsive design contract

The current single breakpoint at 48rem is insufficient.

The repaired design must satisfy behavior rather than a specific set of CSS breakpoints:

### Wide
Approx. >= 1200 px
- multi-column card grid;
- no horizontal scroll;
- target/result and controls remain visually grouped.

### Medium
Approx. 769–1199 px
- reduce column count as needed;
- never retain seven columns at the expense of readable cards;
- 800 px must be a first-class supported width, not an edge case.

### Narrow
Approx. <= 768 px
- no horizontal calendar scroll;
- one primary vertical scroll owner;
- selected decoration fits inside the viewport;
- navigation remains symmetric;
- repeated static information is reduced;
- trace uses a mobile-appropriate bounded inspector.

These ranges are guidance; implementation may use container queries or content-driven breakpoints if they satisfy all screenshot tests.

## 6. Calendar navigation/state contract

The following states must be explicit and testable:

1. initial loading;
2. long loading;
3. ready at searched target;
4. user browsed away from target;
5. return to target;
6. previous range/cutlet;
7. next range/cutlet;
8. return to today;
9. search dialog open;
10. advanced calculation date open;
11. invalid/empty input;
12. engine failure;
13. successful retry;
14. trace loading;
15. trace ready;
16. trace error/retry where safely simulatable;
17. reverse-search states once the authoritative contract is found.

No state may rely on stale calendar content showing behind a status panel.

## 7. BiDi and typography contract

- Human prose follows locale direction.
- Machine/date identifiers use explicit directional isolation.
- ISO dates remain LTR and non-breaking.
- Exact numeric/schema values in trace remain LTR where required.
- Directional isolation must not change copy/paste text.
- Long translated labels must wrap at word boundaries where possible.
- Avoid `overflow-wrap:anywhere` on tokens whose internal order is semantically meaningful, including ISO dates.

## 8. Accessibility requirements

Repairs must preserve or improve:
- visible `:focus-visible`;
- 44 px minimum interactive target size where already provided;
- dialog focus behavior;
- Escape behavior for trace/dialog surfaces;
- focus return to opener;
- ARIA current/selected target semantics;
- full semantic date exposed to assistive technology even if visible cards become more compact;
- forced-colors support;
- reduced-motion support;
- keyboard access to every chapter and navigation action.

## 9. Performance/DOM acceptance

These are UI constraints, not algorithmic changes.

- Do not alter the normative calculation engine to make the UI faster.
- The presentation layer must not render thousands of cards simply because data exists.
- DOM size must stay bounded during repeated browsing.
- Cache may retain semantic data independently of rendered nodes.
- Repeated previous/next use must not cause monotonic memory/DOM growth in the view layer.
- Opening the trace remains lazy.

Recommended automated assertions:
- rendered `.day` count <= 200 after any tested navigation sequence;
- document scroll width <= client width + 1 px;
- calendar viewport scroll width <= client width + 1 px at 800 px and below;
- selected card bounds remain within viewport bounds;
- no day card is obscured by sticky heading;
- no ISO date breaks into more than one visual line.

## 10. Mandatory QA matrix before merge

### Viewports
- 1440×1000
- 1024×1366
- 800×1280
- 768×1024
- 390×844
- 320×740

### Locales
At minimum for every interaction family:
- Hebrew `he`
- Arabic `ar`
- English `en`
- German `de`

Before merge, perform a screenshot smoke pass for **all ten currently supported UI locales**:
- `ie`, `en`, `he`, `ar`, `ru`, `fr`, `de`, `es`, `it`, `cs`.

### Required visual states
- initial loading;
- ready target;
- calendar top/middle/bottom browsing;
- previous/next/today/return-target;
- search dialog;
- advanced calculation date;
- empty input;
- malformed input;
- worker failure;
- recovery through retry;
- trace loading;
- every trace chapter;
- narrow mobile trace navigation;
- reverse search once present.

### Required interaction methods
- pointer/mouse;
- touch-sized viewport;
- keyboard-only Tab/Shift+Tab/Enter/Escape.

### Regression rule
A fix is not complete merely because a DOM assertion passes. The final QA must again inspect rendered screenshots/images as a human-visible surface.

## 11. Implementation order

### Phase A — correctness and responsive blockers
1. ISO BiDi isolation.
2. 800/1024 responsive grid.
3. selected-card clipping.
4. sticky-heading overlap.
5. coherent error-state layout.

### Phase B — calendar browsing architecture
1. bounded rendered-day model;
2. eliminate problematic nested scrolling on narrow/medium widths;
3. explicit return-to-target action;
4. symmetric navigation controls;
5. prove DOM does not grow after repeated browsing.

### Phase C — trace inspector
1. move trace out of unbounded inline document flow;
2. mobile chapter discoverability;
3. data hierarchy/long-number behavior;
4. preserve focus and calendar position.

### Phase D — visual hierarchy
1. simplify target beacon;
2. simplify selected card;
3. reduce month-card noise;
4. remove redundant visible year/cutlet repetition where safe;
5. rebalance masthead/search panel/language control.

### Phase E — reverse-search gap
1. locate authoritative reverse-search contract/history;
2. document semantics;
3. implement public surface;
4. integrate result with target/navigation model;
5. run same responsive/BiDi/error QA.

### Phase F — final QA
Run section 10 in full. Only after it passes should a PR be considered for merge into the publishing branch.

## 12. Merge policy

- Work must occur on a dedicated repair branch based on `JavaScript+Interlingue`.
- Do not merge partial phases merely because unit tests are green.
- Do not merge while any S1 item remains unresolved.
- S2 items may only be deferred explicitly, with a recorded rationale; they must not disappear silently.
- The final merge decision is made only after live-style screenshot QA of the built artifact.
