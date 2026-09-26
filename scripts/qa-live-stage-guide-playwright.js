'use strict';

const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 1000 } });
  page.on('console', (msg) => console.log('[browser]', msg.type(), msg.text()));
  await page.goto('http://127.0.0.1:4173/', { waitUntil: 'load' });
  await page.waitForFunction(() => Boolean(customElements.get('pastafari-date')));
  const result = await page.evaluate(async () => {
    document.body.replaceChildren();
    const host = document.createElement('pastafari-date');
    host.setAttribute('lang', 'he');
    host.setAttribute('date', '2026-09-11');
    host.setAttribute('calculation-date', '2026-09-11');
    document.body.append(host);

    const panel = host.shadowRoot.querySelector('pastafari-cooking');
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
    const timer = setInterval(sample, 20);
    sample();
    await Promise.race([
      new Promise((resolve, reject) => {
        host.addEventListener('pastafari-change', resolve, { once: true });
        setTimeout(() => reject(new Error('Timed out waiting for real calculation')), 180000);
      }),
      host.ready,
    ]);
    sample();
    clearInterval(timer);
    await new Promise((resolve) => setTimeout(resolve, 100));
    sample();
    return { transitions, liveState: panel._liveState, entries: panel._liveEntries.length, observed: panel._liveObservedCount };
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
