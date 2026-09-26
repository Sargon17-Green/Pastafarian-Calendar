'use strict';

const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
  page.on('console', (msg) => console.log('[browser]', msg.type(), msg.text()));
  await page.goto('http://127.0.0.1:4173/live-stage-qa.html', { waitUntil: 'load' });
  await page.waitForFunction(() => Boolean(customElements.get('pastafari-date')));
  const result = await page.evaluate(async () => {
    const host = document.querySelector('pastafari-date');
    if (!host || !host.shadowRoot) throw new Error('Preconfigured QA component is not upgraded');
    const panel = host.shadowRoot.querySelector('pastafari-cooking');
    if (!panel || !panel.shadowRoot) throw new Error('Preconfigured cooking panel is not upgraded');

    const transitions = [];
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
      const key = [current, stage, explanation, quote, href].join('\u241f');
      if (key !== last) {
        transitions.push({ ms: Math.round(performance.now() - started), current, stage, explanation, quote, href });
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
    return {
      transitions,
      liveState: panel._liveState,
      entries: panel._liveEntries.length,
      observed: panel._liveObservedCount,
    };
  });
  console.log(JSON.stringify(result, null, 2));
  const stages = result.transitions.map((x) => x.stage).filter(Boolean);
  const distinctStages = [...new Set(stages)];
  if (distinctStages.length < 2) {
    throw new Error('Live guide did not advance across semantic stages: ' + distinctStages.join(', '));
  }
  await browser.close();
})().catch((error) => {
  console.error(error && error.stack ? error.stack : error);
  process.exit(1);
});
