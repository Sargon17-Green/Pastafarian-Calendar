// Research-only exact lexical prefix rank/unrank baseline in Native Chapel.
// Polynomial insertion-count recurrence, independently checked against permutations.
// Finite families only: this is NOT an optimized 4244-symbol implementation or Stage 6.
use BigInteger;
use List;

proc chooseBig(n: int, r: int): bigint {
  if r < 0 || r > n then return new bigint(0);
  const short = min(r, n-r);
  var resultValue = new bigint(1);
  for j in 1..short {
    resultValue = (resultValue * new bigint(n-short+j)) / new bigint(j);
  }
  return resultValue;
}

proc gapWeight(i: int, n: int, k: int, q: int,
               fixedSum: int, firstFixed: int, tail: int): bigint {
  if i < q {
    if firstFixed != i then return new bigint(0);
  } else {
    if fixedSum != 0 || (i > q && tail != 0) then return new bigint(0);
  }
  const start = max(i, q);
  if start > n then return new bigint(0);
  var lower: [0..n] int;
  if i >= q then lower[i] = 1;
  if q >= i then lower[q] = max(lower[q], tail);
  lower[n] = max(lower[n], 1);
  var mandatory = 0;
  for slot in start..n do mandatory += lower[slot];
  const remaining = k - fixedSum - mandatory;
  if remaining < 0 then return new bigint(0);
  return chooseBig(remaining+n-start, n-start);
}

proc countPrefix(const ref lengths: list(int),
                 const ref prefix: list(int)): bigint {
  const months = lengths.size;
  if months == 0 then halt("A positive, nonempty family is required.");
  var totalDays = 0;
  for k in lengths {
    if k <= 0 then halt("Nonpositive length.");
    totalDays += k;
  }
  if prefix.size > totalDays then return new bigint(0);
  var used: [1..months] int;
  for symbol in prefix {
    if symbol < 1 || symbol > months then return new bigint(0);
    used[symbol] += 1;
    if used[symbol] > lengths[symbol-1] then return new bigint(0);
  }
  var previous: [0..totalDays] bigint;
  var next: [0..totalDays] bigint;
  previous[1] = new bigint(1);
  var days = lengths[0];
  for month in 2..months {
    const k = lengths[month-1];
    var gaps: [0..totalDays] int;
    var q = 0;
    for symbol in prefix {
      if symbol > month then continue;
      if symbol == month then gaps[q] += 1;
      else q += 1;
    }
    var fixedSum = 0;
    var firstFixed = -1;
    for slot in 0..<q {
      fixedSum += gaps[slot];
      if firstFixed == -1 && gaps[slot] > 0 then firstFixed = slot;
    }
    const tail = gaps[q];
    for p in 0..(days+k) do next[p] = new bigint(0);
    var cumulative = new bigint(0);
    for i in 0..days {
      cumulative += previous[i];
      if cumulative != 0 {
        const ways = gapWeight(i, days, k, q, fixedSum, firstFixed, tail);
        if ways != 0 then next[i+1] = cumulative * ways;
      }
    }
    days += k;
    for p in 0..days do previous[p] = next[p];
  }
  var answer = new bigint(0);
  for p in 1..days do answer += previous[p];
  return answer;
}

proc lexUnrank(const ref lengths: list(int),
               const ref rank0: bigint): list(int) {
  const total = countPrefix(lengths, new list(int));
  if rank0 < 0 || rank0 >= total then halt("Invalid finite rank.");
  var rank = rank0;
  var word = new list(int);
  var days = 0;
  for k in lengths do days += k;
  for step in 1..days {
    var found = false;
    for symbol in 1..lengths.size {
      var trial = word;
      trial.pushBack(symbol);
      const block = countPrefix(lengths, trial);
      if rank >= block {
        rank -= block;
      } else {
        if block == 0 then halt("Zero rank block selected.");
        word = trial;
        found = true;
        break;
      }
    }
    if !found then halt("Unrank failed to select a legal symbol.");
  }
  if rank != 0 || countPrefix(lengths, word) != 1 then
    halt("Finite unrank residual mismatch.");
  return word;
}

proc lexRank(const ref lengths: list(int),
             const ref word: list(int)): bigint {
  var prefix = new list(int);
  var rank = new bigint(0);
  for symbol in word {
    for earlier in 1..<symbol {
      var candidate = prefix;
      candidate.pushBack(earlier);
      rank += countPrefix(lengths, candidate);
    }
    prefix.pushBack(symbol);
    if countPrefix(lengths, prefix) == 0 then
      halt("Illegal word supplied to finite rank.");
  }
  var expectedDays = 0;
  for k in lengths do expectedDays += k;
  if prefix.size != expectedDays then
    halt("Finite word length mismatch.");
  return rank;
}

proc csv(const ref values: list(int)): string {
  var output = "";
  for value in values {
    if output != "" then output += ",";
    output += value:string;
  }
  return output;
}

proc main() {
  var families = 0;
  var words = 0;
  var prefixChecks = 0;
  var invalidChecks = 0;
  for m in 1..4 {
    var possibilities = 1;
    for j in 1..m do possibilities *= 3;
    for raw in 0..<possibilities {
      var digits = raw;
      var lengths = new list(int);
      var days = 0;
      for j in 1..m {
        const k = 1 + digits % 3;
        digits /= 3;
        lengths.pushBack(k);
        days += k;
      }
      if days > 8 then continue;
      const total = countPrefix(lengths, new list(int));
      if total <= 0 || total > 1000000 then halt("Bad finite total.");
      writeln("NATIVE_PREFIX_CASE=", csv(lengths), ";", total);
      families += 1;
      if m > 1 {
        var forbidden = new list(int);
        forbidden.pushBack(m);
        const zero = countPrefix(lengths, forbidden);
        if zero != 0 then halt("Forbidden first month accepted.");
        writeln("NATIVE_PREFIX_INVALID=", csv(lengths), ";", m, ";", zero);
        invalidChecks += 1;
      }
      for r in 0..<(total:int) {
        const word = lexUnrank(lengths, new bigint(r));
        if lexRank(lengths, word) != new bigint(r) then
          halt("Finite rank/unrank mismatch.");
        writeln("NATIVE_PREFIX_WORD=", csv(lengths), ";", r, ";", csv(word));
        words += 1;
        var prefix = new list(int);
        writeln("NATIVE_PREFIX_COUNT=", csv(lengths), ";;", countPrefix(lengths, prefix));
        prefixChecks += 1;
        for symbol in word {
          prefix.pushBack(symbol);
          writeln("NATIVE_PREFIX_COUNT=", csv(lengths), ";", csv(prefix), ";",
                  countPrefix(lengths, prefix));
          prefixChecks += 1;
        }
      }
    }
  }
  writeln("NATIVE_PREFIX_FINITE_FAMILIES=", families);
  writeln("NATIVE_PREFIX_FINITE_WORDS=", words);
  writeln("NATIVE_PREFIX_FINITE_PREFIX_CHECKS=", prefixChecks);
  writeln("NATIVE_PREFIX_FINITE_INVALID_CHECKS=", invalidChecks);
  writeln("NATIVE_PREFIX_FULL_4244=NOT_TESTED");
  writeln("NATIVE_PREFIX_STAGE6_ACCEPTANCE=NOT_CLAIMED");
  writeln("NATIVE_PREFIX_PRODUCTION_CHANGE=NONE");
}
