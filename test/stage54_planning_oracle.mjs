/*
Stage54 / DISCOVERY50 — mixed five-live text-capacity contract and planning oracle
PROJECT_ID=PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
BRANCH=COBOL+简体中文
PARENT=2c188c7b174fdba91511d973df57924a112b1d51
LAST_COMPLETED_STAGE=53; STAGE54=PLANNING_ONLY; NATIVE=NOT_RUN; CI_GATE=NOT_IMPLEMENTED.

Scope confirmation: source at parent. Stage51 harness blob bc4f09f30f58003120c45d97c4ee96ee2bfe8932 (1328 lines), main calls PROBE-TO-TEXT-OVERFLOW once after ordinary cases; lines 1137-1326 test one isolated oversized owner at zero baseline, one status45, no independent full arithmetic. Stage52 blob 29758ca4c709fad201594c3b1db389ea7304c1fc repeats the isolated overflow witness, not mixed five-live coverage. Stage26/35/50/53 harnesses reviewed for overflow markers and representation bounds; no equivalent mixed five-live probe identified. Ledger inventory is not exhaustive line-level historical proof. No reproduced defect asserted.
ABI lock: src/big_integer.cob blob 982c1f266a18c2bcaba79b994177a93750f27bfa, NODE-A lines 34-39, HANDLE-H1-TO-TEXT lines 1710-1769, initialized node allocation lines 955 onward. Same compiler/platform, test-only BASED view exactly PIC 9(9) COMP-5, PREV POINTER, NEXT POINTER, ARENA POINTER. Do not modify production or add ABI.
Native contract: iterate orientation outer 0..3 (swap bit 0, negate bit 1), j inner 1..5. INIT-TEXT legal magnitudes; set normalized negative nonzero sign for full-width negative as in Stage51. For small zero use canonical zero. C=M=10^8192-1, t=[j+1,1,0,-j,-j-1]; global negate/swap; exact distance abs(T-C)+1; expected decimals below. Use independent direct decimal strings and split from right into chunks, not production arithmetic. Each result 911 chunks: first chunk 99 (fit) or 100 (overflow), sign +1. Release input owners after each result after preservation check; verify results disjoint from input before release. At five-live baseline require measured heap 4555 (no arena, no other live owners).
Bounded read-only traversal: status0, expected sign/chunks, nonnull distinct head/tail, check pointer nonnull BEFORE SET ADDRESS; follow NEXT no more than 911 nodes; PREV must equal preceding address, first PREV null, ARENA null; compare all digits to independent decimal chunks, node 911 address equals tail and NEXT null. Fail immediately on unexpected topology, never follow another link or free suspect owner. Different tails + valid bidirectional chains imply no shared nodes. Snapshot each descriptor and all 911 node addresses on first successful traversal; on later traversals compare current address to snapshot before dereference, plus digit/link/arena checks. Never fabricate pointers, never write nodes. Initial traversal cannot establish arbitrary nonnull address validity: isolate in bounded native process; crash/nonzero/timeout is failure, not a safe-pointer proof. Do not continue/free suspect ownership after failure; log case, slot and check before abort.
Exact serialization order 3,1,4,2,5,3,4,5,1,2. For each TO-TEXT require fit status0 len8192 exact text or overflow status45 len0; overflow buffer prefix unspecified. Check all five descriptors and all 911 chunks/pointers after EVERY call, then measured unchanged heap. 200 rounds: 120 rejects and 80 fits. Select slot 3+(zero-based case index modulo 3), targets 7/7/6. Free verified selected owner, check empty descriptor, four survivors and heap=3644. Replace with same orientation (M,2) result M-1; check input release and distinctness, serialize replacement fit, validate all five, heap=4555. Free verified owners exactly once and measure zero in each case. Native gates: 20 cases/pass, initial100 owners, 1000 round owner checks, 80 free survivors, 80 reuse survivors +20 replacement owner checks, 1280 total full owner walks / 1166080 chunk checks (not counting input checks), 20 replacement fits, 20 final measured zero, no unexpected failures. Counts increment ONLY after corresponding successful actual assertions. Require all counts, project/HEAD identity and zero unexpected; no expected-red until reproduced. Native -Werror, compile <=300s, run <=120s, job <=20min, artifact even on failure, canonical prior 54 jobs retained + 1 => 55 total, exact-source completed run/job/log/ZIP SHA256 CRC identity before acceptance. No manual rerun of accepted Stage53. Four QA51-B injections excluded, full calendar not available, no main/merge/release/production change.
Model below checks arithmetic with BigInt vs direct decimal, division-based chunks vs decimal slicing and exact schedule counts. All owner/heap/serialization counters are planned, not observations of COBOL.
*/

function stage54Planning() {
  const require = (ok, detail) => { if (!ok) throw new Error(detail); };
  const width=8192, base=1000000000n, M=10n**BigInt(width)-1n;
  const schedule=[3,1,4,2,5,3,4,5,1,2];
  const stats={cases:0,arithmetic:0,fit:0,overflow:0,chunkComparisons:0,
    replacementArithmetic:0,replacementChunks:0,rounds:0,rejects:0,
    serialFit:0,initialOwnerChecks:0,roundOwnerChecks:0,freeSurvivors:0,
    reuseSurvivors:0,replacementFit:0,afterReuseOwnerChecks:0,cleanup:0};
  const targets=[0,0,0], anchors=new Set();
  function verify(c,t,expected) {
    const delta=t-c, result=(delta<0n?-delta:delta)+1n;
    require(result.toString()===expected,"arithmetic");
    const arithmeticChunks=[];
    for(let remaining=result;remaining>0n;remaining/=base)
      arithmeticChunks.unshift(Number(remaining%base));
    const decimalChunks=[];
    for(let end=expected.length;end>0;end-=9)
      decimalChunks.unshift(Number(expected.slice(Math.max(0,end-9),end)));
    require(arithmeticChunks.length===911 && decimalChunks.length===911,"count");
    require(arithmeticChunks[0]===(expected.length===8192?99:100),"leading");
    for(let k=0;k<911;k++)
      require(arithmeticChunks[k]===decimalChunks[k],"chunk "+k);
    return arithmeticChunks.length;
  }
  for(let orientation=0;orientation<4;orientation++) {
    for(let j=1;j<=5;j++) {
      const flip=(orientation&2)!==0, swap=(orientation&1)!==0;
      function orient(t) {
        const c=flip?-M:M, x=flip?-BigInt(t):BigInt(t);
        return swap?[x,c]:[c,x];
      }
      const ts=[j+1,1,0,-j,-j-1];
      const expected=["9".repeat(8191)+(9-j),"9".repeat(8192),
        "1"+"0".repeat(8192),"1"+"0".repeat(8191)+j,
        "1"+"0".repeat(8191)+(j+1)];
      const anchor=orient(ts[0]).join(",");
      require(!anchors.has(anchor),"duplicate case anchor");
      anchors.add(anchor);
      const live=expected.slice();
      for(let slot=0;slot<5;slot++){
        const [c,t]=orient(ts[slot]);
        stats.chunkComparisons+=verify(c,t,live[slot]);
        stats.arithmetic++; stats.initialOwnerChecks++;
        if(live[slot].length===8192)stats.fit++;
        else{require(live[slot].length===8193,"width");stats.overflow++;}
      }
      for(const slot of schedule){
        require(live.every(x=>x!==null),"five-live schedule");
        stats.rounds++;stats.roundOwnerChecks+=5;
        if(live[slot-1].length===8192)stats.serialFit++;
        else stats.rejects++;
      }
      const target=2+(stats.cases%3);
      targets[target-2]++;live[target]=null;
      require(live.filter(x=>x!==null).length===4,"free model");
      stats.freeSurvivors+=4;
      const [rc,rt]=orient(2);
      const replacement="9".repeat(8191)+"8";
      stats.replacementChunks+=verify(rc,rt,replacement);
      stats.replacementArithmetic++;live[target]=replacement;
      require(live.filter(x=>x?.length===8192).length===3,"reuse model");
      stats.replacementFit++;stats.reuseSurvivors+=4;stats.afterReuseOwnerChecks+=5;
      live.fill(null); stats.cleanup++;stats.cases++;
    }
  }
  const wanted={cases:20,arithmetic:100,fit:40,overflow:60,
    chunkComparisons:91100,replacementArithmetic:20,replacementChunks:18220,
    rounds:200,rejects:120,serialFit:80,initialOwnerChecks:100,
    roundOwnerChecks:1000,freeSurvivors:80,reuseSurvivors:80,replacementFit:20,
    afterReuseOwnerChecks:100,cleanup:20};
  for(const [k,v] of Object.entries(wanted))require(stats[k]===v,k);
  require(anchors.size===20 && targets.join(",")==="7,7,6","coverage");
  const ownerChecks=stats.initialOwnerChecks+stats.roundOwnerChecks+
    stats.freeSurvivors+stats.afterReuseOwnerChecks;
  require(ownerChecks===1280,"total native owner check plan");
  return {...stats,anchors:anchors.size,targets,plannedNativeOwnerChecks:ownerChecks,
    plannedNativeChunkChecks:ownerChecks*911,gate:"PASS_NOT_NATIVE"};
}

console.log(JSON.stringify(stage54Planning()));
