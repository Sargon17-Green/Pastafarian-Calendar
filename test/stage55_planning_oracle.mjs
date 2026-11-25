import { readFileSync } from "node:fs";

function requireCheck(ok, detail) {
  if (!ok) throw new Error(detail);
}

function enumeratePermutations(values) {
  const result = [];
  function visit(prefix, remaining) {
    if (remaining.length === 0) {
      result.push(prefix);
      return;
    }
    for (let i = 0; i < remaining.length; i += 1) {
      visit([...prefix, remaining[i]],
        [...remaining.slice(0, i), ...remaining.slice(i + 1)]);
    }
  }
  visit([], values);
  return result;
}

function decimalChunks(valueText) {
  const chunks = [];
  for (let end = valueText.length; end > 0; end -= 9) {
    chunks.unshift(Number(valueText.slice(Math.max(0, end - 9), end)));
  }
  return chunks;
}

function arithmeticChunks(value) {
  const chunks = [];
  let remaining = value;
  do {
    chunks.unshift(Number(remaining % 1000000000n));
    remaining /= 1000000000n;
  } while (remaining > 0n);
  return chunks;
}

function absolute(value) {
  return value < 0n ? -value : value;
}

function stage55Planning() {
  const width = 8192n;
  const tenToWidth = 10n ** width;
  const maximum = tenToWidth - 1n;
  const permutations = enumeratePermutations([1, 2, 3, 4, 5]);
  requireCheck(permutations.length === 120, "permutation count");
  const permutationKeys = permutations.map(p => p.join(""));
  requireCheck(new Set(permutationKeys).size === 120, "permutation uniqueness");
  requireCheck(permutationKeys[0] === "12345", "first permutation");
  requireCheck(permutationKeys[119] === "54321", "last permutation");

  const anchors = new Set();
  const orientationCounts = [0, 0, 0, 0];
  const stats = {
    cases: 0,
    permutations: 0,
    arithmetic: 0,
    chunkComparisons: 0,
    initialOwners: 0,
    rebuildOwners: 0,
    releaseSteps: 0,
    ownerWalks: 0,
    chunkChecks: 0,
    distinctChecks: 0,
    heapSamples: 0,
    heapZero: 0,
    expected8192DigitOwners: 0,
    expected8193DigitOwners: 0
  };

  for (let p = 0; p < permutations.length; p += 1) {
    const orientation = Math.floor(p / 30);
    const j = (p % 30) + 1;
    orientationCounts[orientation] += 1;
    const flip = (orientation & 2) !== 0;
    const swap = (orientation & 1) !== 0;
    const small = [BigInt(j + 1), 1n, 0n, -BigInt(j), -BigInt(j + 1)];
    const expected = [
      maximum - BigInt(j),
      maximum,
      tenToWidth,
      tenToWidth + BigInt(j),
      tenToWidth + BigInt(j + 1)
    ];

    const firstSmall = flip ? -small[0] : small[0];
    const firstBig = flip ? -maximum : maximum;
    const anchor = swap
      ? [firstSmall.toString(), firstBig.toString()].join("|")
      : [firstBig.toString(), firstSmall.toString()].join("|");
    requireCheck(!anchors.has(anchor), "duplicate case anchor");
    anchors.add(anchor);

    for (let slot = 0; slot < 5; slot += 1) {
      let c = flip ? -maximum : maximum;
      let t = flip ? -small[slot] : small[slot];
      if (swap) [c, t] = [t, c];
      const actual = absolute(t - c) + 1n;
      const expectedText = expected[slot].toString();
      requireCheck(actual.toString() === expectedText,
        `arithmetic orientation=${orientation} j=${j} slot=${slot + 1}`);

      const fromArithmetic = arithmeticChunks(actual);
      const fromDecimal = decimalChunks(expectedText);
      requireCheck(fromArithmetic.length === 911 && fromDecimal.length === 911,
        "911 chunk boundary");
      requireCheck(fromArithmetic[0] === (expectedText.length === 8192 ? 99 : 100),
        "leading chunk");
      for (let k = 0; k < 911; k += 1) {
        requireCheck(fromArithmetic[k] === fromDecimal[k],
          `chunk orientation=${orientation} j=${j} slot=${slot + 1} index=${k}`);
        stats.chunkComparisons += 1;
      }
      stats.arithmetic += 1;
      if (expectedText.length === 8192) stats.expected8192DigitOwners += 1;
      else {
        requireCheck(expectedText.length === 8193, "unexpected width");
        stats.expected8193DigitOwners += 1;
      }
    }

    const live = new Set();
    for (const slot of permutations[p]) {
      live.add(slot);
      stats.initialOwners += 1;
      stats.ownerWalks += live.size;
      stats.chunkChecks += live.size * 911;
      stats.distinctChecks += 1;
      stats.heapSamples += 1;
    }
    for (const slot of permutations[p]) {
      live.delete(slot);
      stats.releaseSteps += 1;
      stats.ownerWalks += live.size;
      stats.chunkChecks += live.size * 911;
      stats.distinctChecks += 1;
      stats.heapSamples += 1;
      if (live.size === 0) stats.heapZero += 1;
    }
    for (const slot of [...permutations[p]].reverse()) {
      live.add(slot);
      stats.rebuildOwners += 1;
      stats.ownerWalks += live.size;
      stats.chunkChecks += live.size * 911;
      stats.distinctChecks += 1;
      stats.heapSamples += 1;
    }
    for (const slot of permutations[p]) {
      live.delete(slot);
      stats.releaseSteps += 1;
      stats.ownerWalks += live.size;
      stats.chunkChecks += live.size * 911;
      stats.distinctChecks += 1;
      stats.heapSamples += 1;
      if (live.size === 0) stats.heapZero += 1;
    }
    requireCheck(live.size === 0, "case cleanup");
    stats.cases += 1;
    stats.permutations += 1;
  }

  const wanted = {
    cases: 120,
    permutations: 120,
    arithmetic: 600,
    chunkComparisons: 546600,
    initialOwners: 600,
    rebuildOwners: 600,
    releaseSteps: 1200,
    ownerWalks: 6000,
    chunkChecks: 5466000,
    distinctChecks: 2400,
    heapSamples: 2400,
    heapZero: 240,
    expected8192DigitOwners: 240,
    expected8193DigitOwners: 360
  };
  for (const [key, value] of Object.entries(wanted)) {
    requireCheck(stats[key] === value, key);
  }
  requireCheck(anchors.size === 120, "anchor coverage");
  requireCheck(orientationCounts.join(",") === "30,30,30,30",
    "orientation balance");

  const cobol = readFileSync("test/stage55_discovery_tests.cob", "utf8");
  const paragraphNames = [...cobol.matchAll(/^([A-Z][A-Z0-9-]+)\.\s*$/gm)]
    .map(match => match[1]);
  const paragraphSet = new Set(paragraphNames);
  const performed = [...cobol.matchAll(/(?<!END-)\bPERFORM[ \t]+([A-Z][A-Z0-9-]+)/g)]
    .map(match => match[1])
    .filter(name => name !== "VARYING" && name !== "UNTIL");
  const missingParagraphs = [...new Set(performed)]
    .filter(name => !paragraphSet.has(name));
  const requiredFields = [
    "CHUNK-COUNT", "NODE-NUM", "POS-NUM", "PIECE-LEN",
    "CNT-ORIENTATION-0", "CNT-ORIENTATION-1",
    "CNT-ORIENTATION-2", "CNT-ORIENTATION-3"
  ];
  const cobolLines = cobol.split(/\r?\n/);
  const missingFields = requiredFields.filter(name =>
    !cobolLines.some(line => line.startsWith("01 " + name + " ")));
  const orientationUpdates = new Set(
    [...cobol.matchAll(/ADD 1 TO CNT-ORIENTATION-([0-3])/g)]
      .map(match => match[1]));
  requireCheck(missingFields.length === 0,
    `missing COBOL fields: ${missingFields.join(",")}`);
  requireCheck(orientationUpdates.size === 4,
    "orientation counters are not all updated");
  const maxLineLength = Math.max(...cobolLines.map(line => line.length));
  requireCheck(paragraphNames.length >= 15, "paragraph inventory");
  requireCheck(missingParagraphs.length === 0,
    `missing PERFORM targets: ${missingParagraphs.join(",")}`);
  requireCheck(maxLineLength <= 100, "free-format line width");
  requireCheck(!/FAULT.INJECT|MOCK.SERVICE|ALLOCATOR.INJECT/i.test(cobol),
    "forbidden injection seam");

  return {
    ...stats,
    anchors: anchors.size,
    orientationCounts,
    plannedNativeOwnerChecks: stats.ownerWalks,
    plannedNativeChunkChecks: stats.chunkChecks,
    plannedNativeDistinctChecks: stats.distinctChecks,
    plannedNativeHeapSamples: stats.heapSamples,
    plannedNativeHeapZero: stats.heapZero,
    staticParagraphs: paragraphNames.length,
    staticPerformTargets: new Set(performed).size,
    staticRequiredFields: requiredFields.length,
    staticOrientationUpdates: orientationUpdates.size,
    staticMaxLineLength: maxLineLength,
    staticGate: "PASS",
    gate: "PASS_NOT_NATIVE"
  };
}

console.log(JSON.stringify(stage55Planning()));
