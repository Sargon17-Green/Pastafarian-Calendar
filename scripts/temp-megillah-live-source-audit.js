'use strict';

const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const URL = 'https://the-scroll-of-the-appointed-times.blogspot.com/2026/08/Megilat-HaItim.html';
const OUT = path.resolve(__dirname, '..', 'artifacts', 'temp-megillah-live-source-audit');
fs.mkdirSync(OUT, { recursive: true });

require(path.resolve(__dirname, '..', 'browser', 'i18n', 'locales.js'));
const data = globalThis.PastafariBrowserLocaleData;
if (!data || !data.megillahStageGuide) throw new Error('megillahStageGuide unavailable');

(async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage({
      locale: 'he-IL',
      viewport: { width: 1440, height: 1200 },
    });
    await page.goto(URL, { waitUntil: 'domcontentloaded', timeout: 90000 });
    await page.waitForTimeout(3000);

    const finalUrl = page.url();
    if (/google\.com\/sorry\//.test(finalUrl)) {
      throw new Error('Blogger redirected Chromium to Google Sorry page: ' + finalUrl);
    }

    const extracted = await page.evaluate(() => {
      const candidates = Array.from(document.querySelectorAll(
        '.post-body, .entry-content, article, main'
      )).map((node, index) => ({
        index,
        tag: node.tagName,
        className: String(node.className || ''),
        text: String(node.innerText || ''),
        html: String(node.innerHTML || ''),
      }));
      candidates.sort((a, b) => b.text.length - a.text.length);
      const chosen = candidates[0] || {
        index: -1,
        tag: document.body.tagName,
        className: String(document.body.className || ''),
        text: String(document.body.innerText || ''),
        html: String(document.body.innerHTML || ''),
      };
      return {
        title: document.title,
        chosen,
        candidates: candidates.map(({ index, tag, className, text }) => ({
          index, tag, className, textLength: text.length,
        })),
      };
    });

    fs.writeFileSync(path.join(OUT, 'page-url.txt'), finalUrl + '\n');
    fs.writeFileSync(path.join(OUT, 'page-title.txt'), extracted.title + '\n');
    fs.writeFileSync(path.join(OUT, 'article-text.txt'), extracted.chosen.text);
    fs.writeFileSync(path.join(OUT, 'article.html'), extracted.chosen.html);
    fs.writeFileSync(path.join(OUT, 'selector-candidates.json'), JSON.stringify(extracted.candidates, null, 2));

    const audit = Object.entries(data.megillahStageGuide).map(([key, row]) => {
      const index = extracted.chosen.text.indexOf(row.quote);
      return {
        key,
        source: row.source,
        quote: row.quote,
        foundExact: index >= 0,
        index,
        context: index >= 0
          ? extracted.chosen.text.slice(Math.max(0, index - 180), index + row.quote.length + 180)
          : null,
      };
    });
    fs.writeFileSync(path.join(OUT, 'current-quotes-audit.json'), JSON.stringify(audit, null, 2));

    await page.screenshot({
      path: path.join(OUT, 'live-source.png'),
      fullPage: true,
    });

    console.log(JSON.stringify({
      finalUrl,
      title: extracted.title,
      chosen: {
        tag: extracted.chosen.tag,
        className: extracted.chosen.className,
        textLength: extracted.chosen.text.length,
      },
      found: audit.filter(x => x.foundExact).map(x => x.key),
      missing: audit.filter(x => !x.foundExact).map(x => x.key),
    }, null, 2));
  } finally {
    await browser.close();
  }
})().catch((error) => {
  console.error(error && error.stack || String(error));
  process.exit(1);
});
