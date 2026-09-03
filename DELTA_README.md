# JavaScript + Interlingue browser scroll navigation rebuild — v16

Base branch: `JavaScript+Interlingue`
Base HEAD: `2506723d40e273a55089952564607896d936fb2c`

## Scope

This delta rebuilds the browser calendar scrolling/navigation path as one coherent viewport-owned mechanism. It does not change the Pastafarian semantic core, `package.json`, GitHub workflows, persistent-cache schema, Worker protocol, or public calculation API.

Changed implementation:

- `browser/pastafari-date.js`

Changed regression tests:

- `tests/browser-component-runtime.js`
- `tests/browser-built-artifacts.js`

## Structural defect removed

The previous DOM used the class `cutlet` for two unrelated objects:

- the complete cutlet container: `section.cutlet`;
- the cutlet text line inside every day card: `span.day-line.cutlet`.

Navigation code queried `querySelectorAll('.cutlet')` for cutlet containers. Consequently, scroll-state and anchor code could receive an inner text span instead of a cutlet section. An inner span has no `data-start-jdn`, so active-cutlet resolution and scroll-anchor restoration could lose the actual cutlet identity. A preceding-cutlet preload could then re-render the list without restoring the visible location correctly.

The DOM vocabulary is now unambiguous:

- cutlet container: `section.cutlet-section`;
- card text line: `span.day-line.cutlet-line`.

All structural navigation selectors use `section.cutlet-section` explicitly.

## One scrolling owner

The browser calendar no longer uses `Element.scrollIntoView()`.

Target positioning, previous/next cutlet positioning, and re-render restoration all move only the calendar viewport through one primitive that owns the sole `viewport.scrollTop = ...` assignment in the implementation.

The direct conversion creates one immutable scroll target containing:

- target JDN;
- derived cutlet start JDN;
- year;
- cutlet name;
- day in cutlet;
- month name;
- day in month.

The same object determines the initially loaded cutlet, rendered current card, target lookup, containing section, and final viewport position.

## Re-render anchoring

Adjacent-cutlet preload and locale re-render no longer preserve only a section heading. They capture the first visible day card by JDN plus the complete five-part Pastafarian date and preserve its exact pixel offset after the DOM is rebuilt. The containing cutlet start is also retained so trimming cannot discard the visible cutlet while a preload is being committed.

## Initial layout timing

The loading state hides the viewport with `display:none`. The new path first renders the target cutlet, reveals the viewport, waits for a browser layout frame, and only then measures the target card and updates `scrollTop`. Adjacent preload begins after target positioning.

## Local verification

- `node tests/browser-component-runtime.js`: PASS
- `node tests/browser-interface-all.js`: PASS
- `node scripts/build-browser.js`: PASS
- deterministic browser build ID after this delta: `20019f0618963ba2c3010bcc`
- static portion of `tests/browser-built-artifacts.js`: PASS
- full `tests/browser-built-artifacts.js` local run reaches the expensive real-core witness and was stopped by the local time limit; this remains a GitHub CI gate.
- raw Hebrew Unicode scan of changed JS files: PASS
- classic-script parse of changed JS files: PASS
- implementation contains zero `scrollIntoView(` calls.
- implementation contains zero ambiguous `.cutlet` structural selectors.
- implementation contains exactly one `viewport.scrollTop =` assignment.

A real headless Chromium layout exercise was also run with a target cutlet plus asynchronously preloaded previous and next cutlets. The target remained in the `bronze` cutlet and its viewport offset changed by only `0.046875px` across the two preload re-renders; the active cutlet start remained unchanged.

Generated `dist/` and standalone bundles are intentionally not included. GitHub CI must rebuild them from source.
