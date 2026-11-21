// Research only: sparse reverse-adjoint candidate counts, finite Native QA.
// PC-BRANCH-CHAPEL-UKRAINIAN. No production or Stage6 claim.
use BigInteger;
use List;

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
  var lower: [0..n] int;
  if i >= q then lower[i] = 1;
  if q >= i then lower[q] = max(lower[q],spec.tail);
  lower[n] = max(lower[n],1);
  var required = spec.fixedSum;
  for slot in start..n do required += lower[slot];
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
  for i in 0..n {
    cumulative += previous.at(i);
    if cumulative != 0 {
      const factor = weight(i,n,k,spec);
      if factor != 0 then dense[i+1] = cumulative*factor;
    }
  }
  return pack(dense);
}
// The algebraic transpose (T^t v)[p]=sum_{i>=p} v[i+1]*weight(i).
proc transpose(const ref after: SparseVec, n: int, k: int,
               spec: GapSpec): SparseVec {
  var dense: [0..n] bigint;
  var suffix = new bigint(0);
  for i in 0..n by -1 {
    const a = after.at(i+1);
    if a != 0 {
      const factor = weight(i,n,k,spec);
      if factor != 0 then suffix += a*factor;
    }
    dense[i] = suffix;
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
  for c in word {
    if c < 1 || c > m then halt("Rank word symbol outside family");
    const blocks = candidateBlocks(lens,states,sizes,specs,used,opened,closed,total);
    for earlier in 1..<c do rank += blocks[earlier];
    take(c,lens,states,sizes,specs,used,opened,closed,total,blocks[c]);
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
proc main() {
  var families = 0, words = 0, blocks = 0;
  for m in 1..4 {
    var possibilities = 1;
    for j in 1..m do possibilities *= 3;
    for raw in 0..<possibilities {
      var digits = raw;
      var lens: [1..m] int;
      var days = 0;
      for j in 1..m {
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
