'use strict';

const fs = require('fs');
const path = require('path');

const CANONICAL = 'https://the-scroll-of-the-appointed-times.blogspot.com/2026/08/Megilat-HaItim.html';
const FEED = 'https://the-scroll-of-the-appointed-times.blogspot.com/feeds/posts/default?alt=json&max-results=100';
const OUT = path.resolve(__dirname, '..', 'artifacts', 'temp-megillah-live-source-audit');
fs.mkdirSync(OUT, { recursive: true });

require(path.resolve(__dirname, '..', 'browser', 'i18n', 'locales.js'));
const localeData = globalThis.PastafariBrowserLocaleData;
if (!localeData || !localeData.megillahStageGuide) throw new Error('megillahStageGuide unavailable');

(async () => {
  const response = await fetch(FEED, {
    headers: {
      'user-agent': 'Mozilla/5.0',
      accept: 'application/json',
    },
  });
  if (!response.ok) throw new Error('Blogger feed HTTP ' + response.status);
  const feed = await response.json();
  const entries = feed && feed.feed && Array.isArray(feed.feed.entry) ? feed.feed.entry : [];
  const entry = entries.find((row) =>
    Array.isArray(row.link) && row.link.some((link) => link.rel === 'alternate' && link.href === CANONICAL)
  );
  if (!entry) throw new Error('Canonical Hebrew post not found in Blogger feed');

  const body = String(entry.content && entry.content.$t || '');
  if (!body) throw new Error('Canonical Hebrew post has no content body');

  const rows = Object.entries(localeData.megillahStageGuide).map(([key, guide]) => {
    const quoteCount = body.split(guide.quote).length - 1;
    const sourceParts = String(guide.source || '').split(' · ').slice(1);
    const missingSourceParts = sourceParts.filter((part) => !body.includes(part));
    return {
      key,
      quote: guide.quote,
      quoteCount,
      source: guide.source,
      missingSourceParts,
    };
  });

  const staleGateQuote = 'וכן עשה שער אחר שער.';
  const report = {
    canonicalUrl: CANONICAL,
    feedUrl: FEED,
    postTitle: entry.title && entry.title.$t,
    published: entry.published && entry.published.$t,
    updated: entry.updated && entry.updated.$t,
    bodyLength: body.length,
    staleGateQuoteCount: body.split(staleGateQuote).length - 1,
    rows,
  };

  fs.writeFileSync(path.join(OUT, 'audit.json'), JSON.stringify(report, null, 2));
  fs.writeFileSync(path.join(OUT, 'current-post.html'), body);

  const failures = rows.filter((row) => row.quoteCount !== 1 || row.missingSourceParts.length);
  console.log(JSON.stringify(report, null, 2));
  if (failures.length) {
    throw new Error('Live source audit failed for: ' + failures.map((row) => row.key).join(', '));
  }
  if (report.staleGateQuoteCount !== 0) {
    throw new Error('Stale gate quote unexpectedly exists in current live post');
  }
  console.log('PASS: all 16 stage quotations occur exactly once in the current Blogger post body.');
})().catch((error) => {
  console.error(error && error.stack || String(error));
  process.exit(1);
});
