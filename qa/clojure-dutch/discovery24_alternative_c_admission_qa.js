#!/usr/bin/env node
// DISCOVERY24 alternative C pilot admission contract, 2026-11-28.
// Reproduce: node qa/clojure-dutch/discovery24_alternative_c_admission_qa.js
// Boundary policy: reject before root count if envelope exceeds any component.
// Limits are chosen rounded analytical ceilings for the pilot only; NOT practical physical limits.
// Transport/parser must cap bytes before allocating; no unbounded raw input claim.
// Regression gate: independent rank/first-last oracle, exact five-field canonical differential,
// actual root count/rank validation, exact and minus-one resource tests, measured JVM heap/time,
// watchdog, production date API and refusal regression, unchanged 128N search contract.
// Existing fixed charge remains in production until implementation/acceptance.
function contract() {
  "use strict";
  // Alternative C, pilot contract only. Source lock fe8dc6a8b601c85e0a139ccb395b7fb1447c2741.
  // This is an admission certificate for the no-cache abstract machine specified in
  // discovery24_independent_interval_charge_audit.js, NOT the current Clojure implementation.
  // The root count, candidate counts, output and serialization are charged. No legacy
  // 5M-unit conversion is asserted. A physical runtime/heap watchdog remains mandatory.
  // Input: already bounded transport; array of 2..33 integer month lengths 4..123;
  // sum <=3569; position 1..min(520,N-1); positive canonical decimal rank.
  // Outside pilot scope must return explicit refusal, never fallback silently.
  // Rank validity <= exact root count must be checked after admission, before traversal.
  // No production API change, no Stage2 acceptance.
  const LIMITS = Object.freeze({scalar:550000000000n,bit:65000000000000000000000n,payload:1000000000n});
  const keys = ["scalar","bit","payload"];
  const ceilLog2 = x => {let k=0n,v=1n;while(v<x){v*=2n;k++}return k};
  function envelope(m,n,p) {
    const B=2n*n*ceilLog2(m+1n)+2n*ceilLog2(n+1n)+8n, W=2n*B+2n;
    const q=1n+(p-1n)*m;
    const scalar=256n*(q*((m+1n)*(n+1n)+n+m+1n)+p*(m+1n)**2n+n+p+1n);
    const chars=4n*B+8n*m+8n*p+256n;
    const bit=16n*(W+1n)**2n*scalar+32n*chars*(W+1n)**2n;
    const payload=W*(3n*(n+1n)+4n*m+p+128n)+8n*chars+16n*(W+1n);
    return {scalar,bit,payload,B,chars,q};
  }
  function admit(profile,pos,rank,limits=LIMITS) {
    if(!Array.isArray(profile)||profile.length<2||profile.length>33) return {status:"REFUSE_PROFILE_SCOPE"};
    if(!profile.every(v=>Number.isInteger(v)&&v>=4&&v<=123))return {status:"REFUSE_PROFILE_SCOPE"};
    const n=profile.reduce((a,b)=>a+b,0);
    if(n>3569)return {status:"REFUSE_PROFILE_SCOPE"};
    if(!Number.isInteger(pos)||pos<1||pos>=n||pos>520)return {status:"REFUSE_POSITION_SCOPE"};
    const e=envelope(BigInt(profile.length),BigInt(n),BigInt(pos));
    // Cheap length check precedes regex or BigInt conversion; the rank is never
    // converted here. B is a deliberately loose bound, in bits, on valid rank.
    if(typeof rank!=="string"||rank.length===0||BigInt(rank.length)>e.B||!/^[1-9][0-9]*$/.test(rank))return {status:"REFUSE_RANK_ENCODING"};
    // Exact decimal length of 2^B-1 checked only downstream, inside metered execution.
    // A length ceiling alone is not proof that rank <= root count.
    if(!limits||keys.some(k=>typeof limits[k]!=="bigint"||limits[k]<1n||limits[k]>LIMITS[k]))return {status:"REFUSE_INVALID_CAP"};
    const exceeded=keys.filter(k=>e[k]>limits[k]);
    return {status:exceeded.length?"REFUSE_RESOURCE_BOUND":"ADMIT_MODEL_ONLY",exceeded,certificate:e,rankValidation:"ROOT_COUNT_REQUIRED"};
  }
  // Independently sum the schedule by counting each class of operation.
  // The primitive factor and word width are specified in the parent proof.
  function reference(m,n,p) {
    let slots=0n;
    for(let j=0n;j<=m;j++)slots+=n+1n;
    slots+=n+m+1n;
    let units=slots;
    for(let j=1n;j<p;j++)for(let k=0n;k<m;k++)units+=slots;
    for(let j=0n;j<p;j++)for(let k=0n;k<=m;k++)units+=m+1n;
    units+=n+p+1n;
    return 256n*units;
  }
  function run() {
    let checks=0;
    function assert(x,msg){checks++;if(!x)throw Error(msg)}
    const profile=[103,119,108,107,112,95,116,113,117,70,85,120,111,122,110,75,116,107,121,122,100,93,119,106,80,114,123,117,113,114,117,102,122];
    assert(profile.reduce((a,b)=>a+b,0)===3569,"canonical profile");
    const cases=[];
    for(const p of [1,81,82,520]){
      const a=admit(profile,p,"9".repeat(5288)),e=a.certificate;
      assert(a.status==="ADMIT_MODEL_ONLY","pilot admission");
      assert(a.rankValidation==="ROOT_COUNT_REQUIRED","rank not certified");
      assert(e.scalar===reference(33n,3569n,BigInt(p)),"independent sum");
      const exact={scalar:e.scalar,bit:e.bit,payload:e.payload};
      assert(admit(profile,p,"1",exact).status==="ADMIT_MODEL_ONLY","exact");
      for(const k of keys){const r=admit(profile,p,"1",{...exact,[k]:exact[k]-1n});assert(r.status==="REFUSE_RESOURCE_BOUND"&&r.exceeded.join()===k,"one below "+k)}
      cases.push({p,...e});
    }
    const max=envelope(33n,3569n,520n);
    // Componentwise monotonicity: nonnegative sums/products and nondecreasing ceilLog2.
    // Verify sampled grid and exact largest corner. The mathematical proof is monotonicity,
    // not enumeration of all possible profiles.
    for(const m of [2n,3n,4n,7n,8n,15n,16n,31n,32n,33n])
    for(const n of [8n,31n,32n,127n,128n,511n,512n,2047n,2048n,3569n])
    for(const p of [1n,2n,81n,82n,519n,520n]){
      const e=envelope(m,n,p);
      assert(keys.every(k=>e[k]<=max[k]&&max[k]<=LIMITS[k]),"monotone grid");
      assert(e.scalar===reference(m,n,p),"reference grid");
    }
    assert(admit(profile,521,"1").status==="REFUSE_POSITION_SCOPE","p outside");
    assert(admit([4,4],8,"1").status==="REFUSE_POSITION_SCOPE","p=N");
    assert(admit(Array(34).fill(4),1,"1").status==="REFUSE_PROFILE_SCOPE","m outside");
    assert(admit(Array(33).fill(123),1,"1").status==="REFUSE_PROFILE_SCOPE","N outside");
    for(const rank of ["","0","01","-1","1.0","1e4"," 1","9".repeat(42861)])assert(admit(profile,520,rank).status==="REFUSE_RANK_ENCODING","rank encoding");
    assert(admit(profile,520,"1",{...LIMITS,scalar:LIMITS.scalar+1n}).status==="REFUSE_INVALID_CAP","cap escalation");
    assert(admit(profile,520,"1",{...LIMITS,bit:0n}).status==="REFUSE_INVALID_CAP","zero cap");
    return {status:"PASS_ADMISSION_CERTIFICATE_MODEL_ONLY",checks,caps:LIMITS,cases,max,stage2:"OPEN",production:"UNCHANGED",rank:"NOT_VERIFIED",native:"NOT_RUN"};
  }
  return run();
}
console.log(JSON.stringify(contract(),(_,v)=>typeof v==='bigint'?String(v):v,2));
/* Observed offline JS model result:
{
  "status": "PASS_ADMISSION_CERTIFICATE_MODEL_ONLY",
  "checks": 1243,
  "caps": {
    "scalar": "550000000000",
    "bit": "65000000000000000000000",
    "payload": "1000000000"
  },
  "cases": [
    {
      "p": 1,
      "scalar": "33205760",
      "bit": "3944602946150406144",
      "payload": "943203374",
      "B": "42860",
      "chars": "171968",
      "q": "1"
    },
    {
      "p": 81,
      "scalar": "84525411840",
      "bit": "9938109433501009373184",
      "payload": "950066254",
      "B": "42860",
      "chars": "172608",
      "q": "2641"
    },
    {
      "p": 82,
      "scalar": "85581564416",
      "bit": "10062286493882945110272",
      "payload": "950152040",
      "B": "42860",
      "chars": "172616",
      "q": "2674"
    },
    {
      "p": 520,
      "scalar": "548176392704",
      "bit": "64451838941170797954816",
      "payload": "987726308",
      "B": "42860",
      "chars": "176120",
      "q": "17128"
    }
  ],
  "max": {
    "scalar": "548176392704",
    "bit": "64451838941170797954816",
    "payload": "987726308",
    "B": "42860",
    "chars": "176120",
    "q": "17128"
  },
  "stage2": "OPEN",
  "production": "UNCHANGED",
  "rank": "NOT_VERIFIED",
  "native": "NOT_RUN"
}
*/
