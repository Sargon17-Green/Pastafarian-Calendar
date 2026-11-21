// Research only: sparse reverse-adjoint candidate counts, finite Native QA.
// PC-BRANCH-CHAPEL-UKRAINIAN. No production or Stage6 claim.
use BigInteger;
use List;

config const runMode = "finite";
config const rankInput = "";

proc isCheckpoint(depth: int): bool {
  return depth == 6 || depth == 16 || depth == 32 || depth == 64 ||
         depth == 96 || depth == 128 || depth == 256 ||
         depth == 512 || depth == 1024 || depth == 2048 ||
         depth == 4096 || depth == 4244;
}

record GapSpec {
  var q: int = 0;
  var fixedSum: int = 0;
  var firstFixed: int = -1;
  var tail: int = 0;
}
record SparseVec {
  var first: int = 0;
  var values: list(bigint);
  proc at(position: int): bigint {
    if position < first || position >= first + values.size then return new bigint(0);
    return values[position-first];
  }
  proc mass(): bigint {
    var result = new bigint(0);
    for x in values do result += x;
    return result;
  }
}
proc pack(const ref dense: [?D] bigint): SparseVec {
  var first = -1, last = -1;
  for i in D {
    if dense[i] != 0 {
      if first < 0 then first = i;
      last = i;
    }
  }
  var result: SparseVec;
  if first >= 0 {
    result.first = first;
    for i in first..last do result.values.pushBack(dense[i]);
  }
  return result;
}
proc chooseBig(n: int, k: int): bigint {
  if k < 0 || k > n then return new bigint(0);
  const small = min(k, n-k);
  var result = new bigint(1);
  for t in 1..small {
    result = (result * new bigint(n-small+t)) / new bigint(t);
  }
  return result;
}
proc weight(i: int, n: int, k: int, spec: GapSpec): bigint {
  const q = spec.q;
  if i < q {
    if spec.firstFixed != i then return new bigint(0);
  } else if spec.fixedSum != 0 || (i > q && spec.tail != 0) {
    return new bigint(0);
  }
  const start = max(i,q);
  if start > n then return new bigint(0);
  // The lower-bound vector has support only at i, q, and n.
  // Sum those at most three positions without allocating/scanning [0..n].
  // Coincident positions use max, exactly as the original lower[] updates.
  var required = spec.fixedSum;
  if i >= q {
    if i == n {
      if q == n then required += max(1, spec.tail);
      else required += 1;
    } else {
      required += 2; // lower[i]=1 and lower[n]=1
      if q == i && spec.tail > 1 then required += spec.tail - 1;
    }
  } else {
    if q == n then required += max(1, spec.tail);
    else required += spec.tail + 1;
  }
  const slack = k-required;
  if slack < 0 then return new bigint(0);
  return chooseBig(slack + n-start,n-start);
}
proc extendSpec(old: GapSpec, month: int, candidate: int): GapSpec {
  var result = old;
  if candidate == month {
    result.tail += 1;
  } else {
    if result.firstFixed < 0 && result.tail > 0 then result.firstFixed = result.q;
    result.q += 1;
    result.fixedSum += result.tail;
    result.tail = 0;
  }
  return result;
}
// Exact T[i+1,p]=[p<=i]*weight(i), with trimmed sparse stored vectors.
proc transfer(const ref previous: SparseVec, n: int, k: int,
              spec: GapSpec): SparseVec {
  var dense: [0..n+k] bigint;
  var cumulative = new bigint(0);
  // In the empty-fixed-gap case, weight(i)=C(k-2+n-i,n-i) for i>=q.
  // Advance adjacent coefficients by exact integer ratios instead of
  // recomputing a full binomial product at every supported position.
  // Keep the original path for short ranges, small k, and all other specs.
  const firstActive = max(spec.q, previous.first);
  const useRecurrence = spec.fixedSum == 0 && spec.tail == 0 &&
                        k >= 8 && previous.values.size > 0 &&
                        firstActive <= n && n-firstActive >= 8;
  var coefficient = new bigint(0);
  if useRecurrence then
    coefficient = chooseBig(k-2+n-firstActive,n-firstActive);
  for i in 0..n {
    cumulative += previous.at(i);
    if cumulative != 0 {
      if useRecurrence && i >= firstActive {
        if coefficient != 0 then dense[i+1] = cumulative*coefficient;
      } else {
        const factor = weight(i,n,k,spec);
        if factor != 0 then dense[i+1] = cumulative*factor;
      }
    }
    if useRecurrence && i >= firstActive && i < n then
      coefficient = (coefficient * new bigint(n-i)) /
                    new bigint(k-2+n-i);
  }
  return pack(dense);
}
// The algebraic transpose (T^t v)[p]=sum_{i>=p} v[i+1]*weight(i).
proc transpose(const ref after: SparseVec, n: int, k: int,
               spec: GapSpec): SparseVec {
  var dense: [0..n] bigint;
  var suffix = new bigint(0);
  // Only indices overlapping the stored sparse vector can contribute.
  // In the common empty-fixed-gap case, walk C(k-2+n-i,n-i) backwards
  // using w(i-1)=w(i)*(k-1+n-i)/(n-i+1), with exact integer division.
  const lowActive = max(spec.q, after.first-1);
  const highActive = min(n, after.first+after.values.size-2);
  const useRecurrence = spec.fixedSum == 0 && spec.tail == 0 &&
                        k >= 8 && highActive-lowActive >= 8;
  var coefficient = new bigint(0);
  if useRecurrence then
    coefficient = chooseBig(k-2+n-highActive,n-highActive);
  for i in 0..n by -1 {
    const a = after.at(i+1);
    if a != 0 {
      if useRecurrence && i >= lowActive && i <= highActive {
        if coefficient != 0 then suffix += a*coefficient;
      } else {
        const factor = weight(i,n,k,spec);
        if factor != 0 then suffix += a*factor;
      }
    }
    dense[i] = suffix;
    if useRecurrence && i <= highActive && i > lowActive then
      coefficient = (coefficient * new bigint(k-1+n-i)) /
                    new bigint(n-i+1);
  }
  return pack(dense);
}
proc dot(const ref a: SparseVec, const ref b: SparseVec): bigint {
  var result = new bigint(0);
  for t in 0..<b.values.size {
    const i = b.first + t;
    const x = a.at(i);
    if x != 0 then result += x*b.values[t];
  }
  return result;
}
proc setup(const ref lens: [?D] int, ref states: [?S] SparseVec,
           ref sizes: [?Z] int, const ref specs: [?Q] GapSpec): bigint {
  const m = D.high;
  var start: [0..lens[1]] bigint;
  start[1] = new bigint(1);
  states[1] = pack(start);
  sizes[1] = lens[1];
  for j in 2..m {
    states[j] = transfer(states[j-1],sizes[j-1],lens[j],specs[j]);
    sizes[j] = sizes[j-1] + lens[j];
  }
  return states[m].mass();
}
proc eligible(c: int, const ref lens: [?D] int, const ref used: [?U] int,
              opened: int, closed: int): bool {
  const remaining = lens[c] - used[c];
  return remaining > 0 && c <= opened+1 &&
         (remaining != 1 || c == closed+1);
}
proc candidateBlocks(const ref lens: [?D] int,
                     const ref states: [?S] SparseVec,
                     const ref sizes: [?Z] int,
                     const ref specs: [?Q] GapSpec,
                     const ref used: [?U] int, opened: int, closed: int,
                     const ref total: bigint): [D] bigint {
  const m = D.high;
  var result: [D] bigint;
  var identity: [0..sizes[m]] bigint;
  for i in 0..sizes[m] do identity[i] = new bigint(1);
  var adjoint = pack(identity);
  if m >= 2 {
    for j in 2..m by -1 {
      if eligible(j,lens,used,opened,closed) {
        const own = extendSpec(specs[j],j,j);
        const trial = transfer(states[j-1],sizes[j-1],lens[j],own);
        result[j] = dot(adjoint,trial);
      }
      const older = extendSpec(specs[j],j,1);
      adjoint = transpose(adjoint,sizes[j-1],lens[j],older);
    }
  }
  if eligible(1,lens,used,opened,closed) then
    result[1] = dot(adjoint,states[1]);
  var partition = new bigint(0);
  for j in 1..m do partition += result[j];
  if partition != total then halt("Reverse-adjoint candidate partition mismatch");
  return result;
}
proc take(c: int, const ref lens: [?D] int,
          ref states: [?S] SparseVec, const ref sizes: [?Z] int,
          ref specs: [?Q] GapSpec, ref used: [?U] int,
          ref opened: int, ref closed: int, ref total: bigint,
          const ref ways: bigint) {
  if !eligible(c,lens,used,opened,closed) || ways <= 0 then
    halt("Attempt to take an illegal or empty candidate");
  for j in max(2,c)..D.high {
    specs[j] = extendSpec(specs[j],j,c);
    states[j] = transfer(states[j-1],sizes[j-1],lens[j],specs[j]);
  }
  used[c] += 1;
  if used[c] == 1 then opened += 1;
  if used[c] == lens[c] then closed += 1;
  total = ways;
  if states[D.high].mass() != total then halt("Forward state and selected block differ");
}
proc unrank(const ref lens: [?D] int, rank0: bigint): list(int) {
  const m = D.high;
  var specs: [D] GapSpec;
  var states: [D] SparseVec;
  var sizes: [D] int;
  var used: [D] int;
  var opened = 0, closed = 0;
  var total = setup(lens,states,sizes,specs);
  if rank0 < 0 || rank0 >= total then halt("Rank out of range");
  var residual = rank0;
  var word = new list(int);
  for step in 1..sizes[m] {
    const blocks = candidateBlocks(lens,states,sizes,specs,used,opened,closed,total);
    var chosen = 0;
    for c in 1..m {
      if residual >= blocks[c] then residual -= blocks[c];
      else {
        chosen = c;
        take(c,lens,states,sizes,specs,used,opened,closed,total,blocks[c]);
        word.pushBack(c);
        if runMode != "finite" && isCheckpoint(step) then
          writeln("NATIVE_MEDIAN_CHECKPOINT=", step, ";", total);
        break;
      }
    }
    if chosen == 0 then halt("Unrank selection failed");
  }
  if residual != 0 || total != 1 then halt("Unrank terminal invariant failed");
  return word;
}
proc rankWord(const ref lens: [?D] int, const ref word: list(int)): bigint {
  const m = D.high;
  var specs: [D] GapSpec;
  var states: [D] SparseVec;
  var sizes: [D] int;
  var used: [D] int;
  var opened = 0, closed = 0;
  var total = setup(lens,states,sizes,specs);
  if word.size != sizes[m] then halt("Rank word length mismatch");
  var rank = new bigint(0);
  var step = 0;
  for c in word {
    if c < 1 || c > m then halt("Rank word symbol outside family");
    const blocks = candidateBlocks(lens,states,sizes,specs,used,opened,closed,total);
    for earlier in 1..<c do rank += blocks[earlier];
    take(c,lens,states,sizes,specs,used,opened,closed,total,blocks[c]);
    step += 1;
    if runMode != "finite" && isCheckpoint(step) then
      writeln("NATIVE_MEDIAN_CHECKPOINT=", step, ";", total);
  }
  if total != 1 then halt("Rank terminal invariant failed");
  return rank;
}
proc csv(const ref seq: list(int)): string {
  var result = "";
  for x in seq {
    if result != "" then result += ",";
    result += x:string;
  }
  return result;
}
proc csvInt(const ref seq: [?D] int): string {
  var result = "";
  for x in seq {
    if result != "" then result += ",";
    result += x:string;
  }
  return result;
}
proc csvBig(const ref seq: [?D] bigint): string {
  var result = "";
  for x in seq {
    if result != "" then result += ",";
    result += x:string;
  }
  return result;
}
proc emitBlocks(const ref lens: [?D] int, const ref word: list(int)) {
  var specs: [D] GapSpec;
  var states: [D] SparseVec;
  var sizes: [D] int;
  var used: [D] int;
  var opened = 0, closed = 0;
  var total = setup(lens,states,sizes,specs);
  var prefix = new list(int);
  for c in word {
    const blocks = candidateBlocks(lens,states,sizes,specs,used,opened,closed,total);
    writeln("NATIVE_ADJOINT_BLOCK=",csvInt(lens),";",csv(prefix),";",csvBig(blocks));
    take(c,lens,states,sizes,specs,used,opened,closed,total,blocks[c]);
    prefix.pushBack(c);
  }
}
// Research-only complete-word attempt; no Stage 6 or production claims.
proc runFullYear() {
  const lens: [1..45] int =
    [115,108,119,109,106,81,115,114,117,120,98,52,81,97,121,
     97,115,96,107,61,106,115,119,39,84,103,115,107,55,119,
     97,50,122,110,81,54,101,83,88,40,25,77,98,122,105];
  var days = 0;
  for k in lens do days += k;
  if days != 4244 then halt("Full-year length lock mismatch");
  var specs: [1..45] GapSpec;
  var states: [1..45] SparseVec;
  var sizes: [1..45] int;
  const root = setup(lens,states,sizes,specs);
  writeln("NATIVE_MEDIAN_ROOT=",root);
  if runMode == "unrank" {
    const word = unrank(lens,root / new bigint(2));
    writeln("NATIVE_MEDIAN_WORD=",csv(word));
    writeln("NATIVE_MEDIAN_RESIDUAL=0");
  } else if runMode == "rank" {
    if rankInput == "" then halt("Missing rankInput witness");
    var word = new list(int);
    for token in rankInput.split(",") {
      if token == "" then halt("Empty rankInput field");
      word.pushBack(token:int);
    }
    const result = rankWord(lens,word);
    writeln("NATIVE_MEDIAN_WORD=",csv(word));
    writeln("NATIVE_MEDIAN_RESULT_RANK=",result);
  } else {
    halt("Unknown research runMode");
  }
  writeln("NATIVE_MEDIAN_COMPLETE=1");
}
proc main() {
  if runMode != "finite" {
    runFullYear();
    return;
  }
  var families = 0, words = 0, blocks = 0;
  for m in 1..4 {
    var possibilities = 1;
    for j in 1..m do possibilities *= 3;
    for raw in 0..<possibilities {
      var digits = raw;
      var lens: [1..m] int;
      var days = 0;
      for j in 1..m by -1 {
        lens[j] = 1 + digits%3;
        digits /= 3;
        days += lens[j];
      }
      if days > 8 then continue;
      var specs: [1..m] GapSpec;
      var states: [1..m] SparseVec;
      var sizes: [1..m] int;
      const root = setup(lens,states,sizes,specs);
      writeln("NATIVE_ADJOINT_CASE=",csvInt(lens),";",root);
      families += 1;
      for r in 0..<(root:int) {
        const word = unrank(lens,new bigint(r));
        if rankWord(lens,word) != new bigint(r) then halt("Finite roundtrip failed");
        writeln("NATIVE_ADJOINT_WORD=",csvInt(lens),";",r,";",csv(word));
        emitBlocks(lens,word);
        words += 1;
        blocks += word.size;
      }
    }
  }
  writeln("NATIVE_ADJOINT_FAMILIES=",families);
  writeln("NATIVE_ADJOINT_WORDS=",words);
  writeln("NATIVE_ADJOINT_BLOCK_ROWS=",blocks);
  writeln("NATIVE_ADJOINT_4244=NOT_TESTED");
  writeln("NATIVE_ADJOINT_STAGE6=NOT_CLAIMED");
  writeln("NATIVE_ADJOINT_PRODUCTION_CHANGE=NONE");
}
