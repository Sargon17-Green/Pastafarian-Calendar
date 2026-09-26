'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const DIST = path.join(ROOT, 'browser', 'dist');

function preparePagesSite(outputPath = path.join(ROOT, '_site')) {
  const output = path.resolve(outputPath);
  const distIndex = path.join(DIST, 'index.html');

  if (!fs.existsSync(distIndex)) {
    throw new Error('Li browser dist ne es constructet: manca browser/dist/index.html.');
  }

  fs.rmSync(output, { recursive: true, force: true });
  fs.mkdirSync(output, { recursive: true });

  const outputDist = path.join(output, 'dist');
  fs.cpSync(DIST, outputDist, { recursive: true });

  const stagedIndex = path.join(outputDist, 'index.html');
  fs.copyFileSync(stagedIndex, path.join(output, 'index.html'));
  fs.rmSync(stagedIndex);

  for (const name of ['favicon.ico', 'favicon-16x16.png', 'favicon-32x32.png']) {
    const source = path.join(ROOT, name);
    if (!fs.existsSync(source)) {
      throw new Error('Manca li favicon source: ' + name);
    }
    fs.copyFileSync(source, path.join(output, name));
  }

  fs.writeFileSync(path.join(output, '.nojekyll'), '', 'utf8');

  return output;
}

if (require.main === module) {
  try {
    const output = preparePagesSite(process.argv[2] || path.join(ROOT, '_site'));
    process.stdout.write('Pages artefact preparat: ' + path.relative(ROOT, output).replace(/\\/g, '/') + '\n');
  } catch (error) {
    console.error(error && error.stack ? error.stack : error);
    process.exitCode = 1;
  }
}

module.exports = Object.freeze({ preparePagesSite });
