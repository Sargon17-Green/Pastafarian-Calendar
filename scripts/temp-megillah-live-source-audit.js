'use strict';

const fs = require('fs');
const path = require('path');

const OUT = path.resolve(__dirname, '..', 'artifacts', 'temp-megillah-live-source-audit');
fs.mkdirSync(OUT, { recursive: true });

const targets = [
  ['he-page', 'https://the-scroll-of-the-appointed-times.blogspot.com/2026/08/Megilat-HaItim.html'],
  ['he-mobile', 'https://the-scroll-of-the-appointed-times.blogspot.com/2026/08/Megilat-HaItim.html?m=1'],
  ['en-page', 'https://the-scroll-of-the-appointed-times.blogspot.com/2026/08/The-Scroll-of-the-Appointed-Times.html'],
  ['feed-json', 'https://the-scroll-of-the-appointed-times.blogspot.com/feeds/posts/default?alt=json&max-results=100'],
  ['feed-atom', 'https://the-scroll-of-the-appointed-times.blogspot.com/feeds/posts/default?alt=atom&max-results=100'],
  ['feed-summary-json', 'https://the-scroll-of-the-appointed-times.blogspot.com/feeds/posts/summary?alt=json&max-results=100'],
];

(async () => {
  const report = [];
  for (const [name, url] of targets) {
    try {
      const response = await fetch(url, {
        redirect: 'follow',
        headers: {
          'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/140.0.0.0 Safari/537.36',
          'accept-language': 'he-IL,he;q=0.9,en;q=0.8',
          accept: '*/*',
        },
      });
      const body = await response.text();
      fs.writeFileSync(path.join(OUT, name + '.txt'), body);
      report.push({
        name,
        requestedUrl: url,
        finalUrl: response.url,
        status: response.status,
        contentType: response.headers.get('content-type'),
        length: body.length,
        containsCurrentOpening: body.includes('כל צמד ימים הניתן ללוח'),
        containsOldOpening: body.includes('למלאכת הלוח קח שני ימים'),
        containsGateQuote: body.includes('וכן עשה שער אחר שער'),
        containsTitle: body.includes('מגילת העיתים'),
      });
    } catch (error) {
      report.push({ name, requestedUrl: url, error: String(error && error.stack || error) });
    }
  }
  fs.writeFileSync(path.join(OUT, 'probe-report.json'), JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
})().catch((error) => {
  console.error(error && error.stack || String(error));
  process.exit(1);
});
