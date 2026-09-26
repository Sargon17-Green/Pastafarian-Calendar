'use strict';

const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const CANONICAL = 'https://the-scroll-of-the-appointed-times.blogspot.com/2026/08/Megilat-HaItim.html';
const ARTIFACT_DIR = path.join(process.cwd(), 'qa-artifacts', 'live-stage-guide');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

(async () => {
  fs.mkdirSync(ARTIFACT_DIR, { recursive: true });
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
  page.on('console', (msg) => console.log('[browser]', msg.type(), msg.text()));

  await page.goto('http://127.0.0.1:4173/live-stage-qa.html', { waitUntil: 'load' });
  await page.waitForFunction(() => Boolean(customElements.get('pastafari-date')));

  const live = await page.evaluate(async (canonical) => {
    const host = document.querySelector('pastafari-date');
    if (!host || !host.shadowRoot) throw new Error('Preconfigured QA component is not upgraded');
    const panel = host.shadowRoot.querySelector('pastafari-cooking');
    if (!panel || !panel.shadowRoot) throw new Error('Preconfigured cooking panel is not upgraded');

    const transitions = [];
    const mismatches = [];
    const badLinks = [];
    let last = '';
    const started = performance.now();

    const sample = () => {
      const sr = panel.shadowRoot;
      const current = sr.querySelector('.live-current')?.textContent || '';
      const guide = sr.querySelector('.live-stage-guide');
      const stage = guide?.dataset.stage || '';
      const explanation = sr.querySelector('.live-explanation')?.textContent || '';
      const quote = sr.querySelector('.megillah-quote blockquote')?.textContent || '';
      const href = sr.querySelector('.megillah-source-link')?.getAttribute('href') || '';
      const expectedStage = panel._liveCurrentEvent
        ? panel._liveCurrentStage(panel._liveCurrentEvent)
        : stage;

      if (stage && expectedStage && stage !== expectedStage) {
        mismatches.push({ current, stage, expectedStage });
      }
      if (href && href !== canonical) badLinks.push({ current, stage, href });

      const key = [current, stage, explanation, quote, href].join('\u241f');
      if (key !== last) {
        transitions.push({
          ms: Math.round(performance.now() - started),
          current,
          stage,
          explanation,
          quote,
          href,
        });
        last = key;
      }
    };

    const observer = new MutationObserver(sample);
    observer.observe(panel.shadowRoot, {
      subtree: true,
      childList: true,
      characterData: true,
      attributes: true,
      attributeFilter: ['data-stage', 'href'],
    });
    sample();

    if (!host.value) {
      await new Promise((resolve, reject) => {
        host.addEventListener('pastafari-change', resolve, { once: true });
        setTimeout(() => reject(new Error('Timed out waiting for isolated real calculation')), 180000);
      });
    }
    sample();
    observer.disconnect();

    const observedBeforeOpen = panel._liveObservedCount;
    panel.setAttribute('open', '');
    await Promise.resolve();
    await new Promise((resolve) => requestAnimationFrame(() => requestAnimationFrame(resolve)));

    const retainedGuides = Array.from(panel.shadowRoot.querySelectorAll('.retained-stage-guide'));
    const retained = {
      count: retainedGuides.length,
      stages: retainedGuides.map((node) => node.dataset.stage || ''),
      links: Array.from(panel.shadowRoot.querySelectorAll('.retained-stage-guide .megillah-source-link')).map((node) => ({
        href: node.getAttribute('href'),
        target: node.getAttribute('target'),
        rel: node.getAttribute('rel'),
      })),
      aria: retainedGuides.map((node) => node.getAttribute('aria-live')),
      quoteFonts: retainedGuides.map((node) => {
        const quote = node.querySelector('.megillah-quote blockquote');
        return quote ? getComputedStyle(quote).fontFamily : '';
      }),
      documentOverflow: document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
      paneOverflow: panel._els.pane.scrollWidth > panel._els.pane.clientWidth + 1,
      observedBeforeOpen,
      observedAfterOpen: panel._liveObservedCount,
      sourceTexts: Array.from(panel.shadowRoot.querySelectorAll('.retained-stage-guide .megillah-source-link'))
        .map((node) => node.textContent || ''),
    };

    return {
      transitions,
      mismatches,
      badLinks,
      liveState: panel._liveState,
      entries: panel._liveEntries.length,
      observed: panel._liveObservedCount,
      retained,
    };
  }, CANONICAL);

  const stages = live.transitions.map((x) => x.stage).filter(Boolean);
  const distinctStages = [...new Set(stages)];
  console.log(JSON.stringify({
    transitionCount: live.transitions.length,
    distinctStages,
    liveState: live.liveState,
    entries: live.entries,
    observed: live.observed,
    mismatches: live.mismatches,
    badLinks: live.badLinks,
    retained: live.retained,
  }, null, 2));

  assert(live.liveState === 'complete', 'Real calculation did not finish in complete state');
  assert(live.observed > 1000, 'Real Chromium probe did not observe a substantial real progress stream');
  assert(distinctStages.length >= 10,
    'Live guide did not expose enough real semantic stage boundaries: ' + distinctStages.join(', '));
  assert(live.mismatches.length === 0,
    'Current operation and live stage guide diverged: ' + JSON.stringify(live.mismatches.slice(0, 5)));
  assert(live.badLinks.length === 0, 'A live Megillah source link diverged from the canonical Blog URL');

  const retainedUnique = [...new Set(live.retained.stages.filter(Boolean))];
  assert(live.retained.count >= 10, 'Retained how-cooked view is missing semantic stage guidance');
  assert(live.retained.count <= 16, 'Retained how-cooked view duplicates stage guidance');
  assert(retainedUnique.length === live.retained.count,
    'Retained how-cooked view contains duplicate semantic stage guide cards');
  assert(live.retained.stages.includes('inputs'), 'Retained view is missing the inputs guide');
  assert(live.retained.stages.includes('gates'), 'Retained view is missing the gates guide');
  assert(live.retained.stages.includes('stones'), 'Retained view is missing the stones guide');
  assert(live.retained.stages.includes('position'), 'Retained view is missing the final-positioning guide');
  assert(live.retained.links.every((x) =>
    x.href === CANONICAL && x.target === '_blank' && x.rel === 'noopener noreferrer'
  ), 'Retained Megillah source links are not canonical/safe');
  assert(live.retained.aria.every((x) => x === 'off'),
    'Retained Megillah guide must remain outside aria-live announcements');
  assert(live.retained.quoteFonts.every((x) => x.includes('SBL Hebrew')),
    'Retained Megillah quotations lost their dedicated Hebrew serif font stack');
  assert(live.retained.observedAfterOpen === live.retained.observedBeforeOpen,
    'Opening how-cooked caused new semantic progress instead of reusing the retained trace');
  assert(!live.retained.documentOverflow, 'Hebrew desktop retained view causes document-level horizontal overflow');
  assert(!live.retained.paneOverflow, 'Hebrew desktop retained trace pane causes horizontal overflow');

  await page.screenshot({ path: path.join(ARTIFACT_DIR, 'he-desktop-retained.png'), fullPage: true });

  await page.setViewportSize({ width: 390, height: 844 });
  const mobile = await page.evaluate(() => {
    const host = document.querySelector('pastafari-date');
    const panel = host.shadowRoot.querySelector('pastafari-cooking');
    const shell = panel.shadowRoot.querySelector('.shell');
    const pane = panel.shadowRoot.querySelector('.pane');
    return {
      documentOverflow: document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
      shellOverflow: shell.scrollWidth > shell.clientWidth + 1,
      paneOverflow: pane.scrollWidth > pane.clientWidth + 1,
    };
  });
  console.log('MOBILE', JSON.stringify(mobile));
  assert(!mobile.documentOverflow && !mobile.shellOverflow && !mobile.paneOverflow,
    'Hebrew mobile retained view has horizontal overflow: ' + JSON.stringify(mobile));
  await page.screenshot({ path: path.join(ARTIFACT_DIR, 'he-mobile-retained.png'), fullPage: true });

  await page.setViewportSize({ width: 1280, height: 900 });
  for (const locale of ['en', 'ar']) {
    const localeState = await page.evaluate(async (code) => {
      const host = document.querySelector('pastafari-date');
      const panel = host.shadowRoot.querySelector('pastafari-cooking');
      panel.setAttribute('lang', code);
      await Promise.resolve();
      await new Promise((resolve) => requestAnimationFrame(resolve));
      const guides = Array.from(panel.shadowRoot.querySelectorAll('.retained-stage-guide'));
      return {
        code: panel.getAttribute('lang'),
        count: guides.length,
        quotesHebrew: guides.every((guide) => {
          const quote = guide.querySelector('blockquote');
          return quote && quote.getAttribute('dir') !== 'ltr' && /[א-ת]/.test(quote.textContent || '');
        }),
        linksCanonical: guides.every((guide) =>
          guide.querySelector('.megillah-source-link')?.getAttribute('href') === 'https://the-scroll-of-the-appointed-times.blogspot.com/2026/08/Megilat-HaItim.html'
        ),
        paneOverflow: panel._els.pane.scrollWidth > panel._els.pane.clientWidth + 1,
      };
    }, locale);
    console.log('LOCALE', JSON.stringify(localeState));
    assert(localeState.count === live.retained.count, locale + ' rerender changed retained guide count');
    assert(localeState.quotesHebrew, locale + ' did not preserve canonical Hebrew quotations');
    assert(localeState.linksCanonical, locale + ' did not preserve canonical source links');
    assert(!localeState.paneOverflow, locale + ' retained view has horizontal overflow');
    await page.screenshot({
      path: path.join(ARTIFACT_DIR, locale + '-desktop-retained.png'),
      fullPage: true,
    });
  }

  await page.emulateMedia({ reducedMotion: 'reduce' });
  const reduced = await page.evaluate(() => {
    const host = document.querySelector('pastafari-date');
    const panel = host.shadowRoot.querySelector('pastafari-cooking');
    const monster = panel.shadowRoot.querySelector('.monster');
    const drip = panel.shadowRoot.querySelector('.sauce-drip');
    return {
      monsterAnimation: getComputedStyle(monster).animationName,
      dripAnimation: getComputedStyle(drip).animationName,
    };
  });
  console.log('REDUCED_MOTION', JSON.stringify(reduced));
  assert(reduced.monsterAnimation === 'none' && reduced.dripAnimation === 'none',
    'prefers-reduced-motion no longer disables live animation');

  await page.emulateMedia({ forcedColors: 'active', reducedMotion: 'reduce' });
  const forcedColors = await page.evaluate(() => {
    const host = document.querySelector('pastafari-date');
    const panel = host.shadowRoot.querySelector('pastafari-cooking');
    const guide = panel.shadowRoot.querySelector('.retained-stage-guide');
    return guide ? getComputedStyle(guide).borderTopStyle : '';
  });
  console.log('FORCED_COLORS_BORDER', forcedColors);
  assert(forcedColors !== 'none', 'forced-colors removed the retained stage-guide boundary');

  await browser.close();
})().catch((error) => {
  console.error(error && error.stack ? error.stack : error);
  process.exit(1);
});
