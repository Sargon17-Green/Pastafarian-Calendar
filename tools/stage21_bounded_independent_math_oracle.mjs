const report = (function stage21Oracle() {
  "use strict";
  const M=(1n<<127n)-1n, MASK64=(1n<<64n)-1n;
  const FACT=[120,24,6,2,1,1], K=[1,2,3,4,5,1];
  function must(condition, why){if(!condition)throw new Error(why);}
  function save(x){must(typeof x==="bigint"&&x>0n,"E_SAVE_POSITIVE");return 1n+(x-1n)%M;}
  function fold(x){
    must(typeof x==="bigint"&&x>0n,"E_FOLD_POSITIVE");
    while(x>M)x=(x&M)+(x>>127n);
    return x;
  }
  function valid(q){
    must(q&&typeof q==="object"&&Array.isArray(q.bowls)&&q.bowls.length===6,"E_BOWLS_HEADER");
    must(Array.isArray(q.visible)&&q.visible.length===46,"E_VISIBLE_HEADER");
    must(Array.isArray(q.stones)&&q.stones.length===46,"E_STONES_HEADER");
    const check=(v)=>typeof v==="bigint"&&v>=1n&&v<=M;
    must(q.bowls.every(check),"E_BOWLS_BIGINT");
    must(q.visible.every(check),"E_VISIBLE_BIGINT");
    for(const row of q.stones){
      must(Array.isArray(row)&&row.length===5,"E_ROW_HEADER");
      must(row.every(check),"E_ROW_BIGINT");
    }
    return true;
  }
  function factoradic(rank){
    let n=rank-1, remain=[1,2,3,4,5,6], out=[];
    for(let j=0;j<6;j++){
      const index=Math.floor(n/FACT[j]);n%=FACT[j];
      must(index<remain.length,"E_FACTORADIC");
      out.push(remain.splice(index,1)[0]);
    }
    return out;
  }
  const permutations=[];
  (function enumerate(prefix,remaining){
    if(remaining.length===0){permutations.push(prefix);return;}
    for(let i=0;i<remaining.length;i++)
      enumerate(prefix.concat(remaining[i]),remaining.slice(0,i).concat(remaining.slice(i+1)));
  })([],[1,2,3,4,5,6]);
  must(permutations.length===720,"E_PERM_COUNT");
  for(let rank=1;rank<=720;rank++)
    must(factoradic(rank).join(",")===permutations[rank-1].join(","),"E_PERM_MISMATCH_"+rank);

  // Algorithm A: iterate bowl IDs and map ID -> order position, using Euclidean modulo.
  function stepA(B,t,S,u,mode="correct"){
    const O=factoradic(Number((t-1n)%720n)+1);
    const position=new Array(7);
    O.forEach((id,index)=>position[id]=index+1);
    const A=new Array(7);
    for(let p=1;p<=6;p++){
      let x=p<=3 ? t*t+B[O[p-1]-1]*(mode==="aux-no-stone"?1n:S[p-1])+BigInt(u*(2*p+(mode==="aux-shift"?2:1))) : 2n;
      A[p]=p<=3?save(x):x;
    }
    const result=[];
    for(let id=1;id<=6;id++){
      let p=position[id], z=mode==="id-for-position"?id:p;
      let left=B[(z+4)%6],right=B[z%6];
      if(mode==="swap-neighbors"){const temp=left;left=right;right=temp;}
      const mixed=mode==="omit-5LR"?0n:5n*left*right;
      const raw=B[id-1]*B[id-1]+2n*left+3n*right+A[p]+t+S[K[z-1]-1]+mixed+BigInt(u*p);
      result.push(save(raw));
    }
    return {bowls:result,order:O};
  }
  // Algorithm B: enumerate lexicographic orders independently, iterate order positions,
  // use Mersenne 127-bit folding instead of remainder and write results by bowl ID.
  function stepB(B,t,S,u){
    const O=permutations[Number((t-1n)%720n)];
    const next=new Array(6);
    for(let j=0;j<6;j++){
      const p=j+1,id=O[j],left=B[(p+4)%6],right=B[p%6];
      const auxiliary=p<=3?fold(t*t+B[id-1]*S[j]+BigInt(u*(2*p+1))):2n;
      const stone=S[p===6?0:j];
      const candidate=B[id-1]**2n+2n*left+3n*right+auxiliary+t+stone+5n*left*right+BigInt(u*p);
      next[id-1]=fold(candidate);
    }
    return {bowls:next,order:[...O]};
  }
  function sourceSignature(q){
    return q.bowls.map(String).join(",")+"|"+q.visible.map(String).join(",")+
      "|"+q.stones.map(row=>row.map(String).join(",")).join(";");
  }
  function encode(x){
    must(x>=1n&&x<=M,"E_ENCODING_RANGE");
    const limbs=[];let n=x;
    while(n>0n){limbs.push(Number(n&511n));n>>=9n;}
    return {sign:1,digits:limbs.length,limbs};
  }
  function decode(record){
    must(record&&record.sign===1&&Number.isInteger(record.digits)&&record.digits>=1&&Array.isArray(record.limbs)&&record.limbs.length===record.digits,"E_CANONICAL_HEADER");
    must(record.limbs.every(d=>Number.isInteger(d)&&d>=0&&d<512),"E_CANONICAL_DIGIT");
    must(record.limbs[record.limbs.length-1]!==0,"E_CANONICAL_HIGH_ZERO");
    let n=0n;
    for(let i=record.limbs.length-1;i>=0;i--)n=(n<<9n)+BigInt(record.limbs[i]);
    must(n>=1n&&n<=M,"E_CANONICAL_RANGE");
    return n;
  }
  function digest(h,x){return (h*0x100000001b3n+(x&MASK64)+0x9e3779b97f4a7c15n)&MASK64;}
  let randomState=0x21fa2026;
  function rand32(){randomState^=randomState<<13;randomState^=randomState>>>17;randomState^=randomState<<5;return randomState>>>0;}
  function randomBig(){
    let x=0n;
    for(let i=0;i<4;i++)x=(x<<32n)+BigInt(rand32());
    x&=M;return x||1n;
  }
  function seededInput(i){
    function take(j){
      if((i+j)%31===0)return M;
      if((i+j)%29===0)return 1n;
      if((i+j)%23===0)return M-1n;
      if((i+j)%19===0)return 720n;
      if((i+j)%17===0)return 721n;
      return randomBig();
    }
    const bowls=Array.from({length:6},(_,j)=>take(j));
    const visible=Array.from({length:46},(_,j)=>take(j+7));
    const stones=Array.from({length:46},(_,u)=>Array.from({length:5},(_,p)=>take(60+u*5+p)));
    return {bowls,visible,stones};
  }
  function anchor(i){
    const B=Array(6).fill(1n),D=Array(46).fill(1n),S=Array.from({length:46},()=>Array(5).fill(1n));
    const M2=M-1n;
    switch(i){
      case 0: break;
      case 1: B.fill(M);D.fill(M);S.forEach(r=>r.fill(M));break;
      case 2: B.splice(0,6,1n,2n,3n,4n,5n,6n);D.forEach((_,j)=>D[j]=BigInt(j+1));S.forEach((r,u)=>r.forEach((_,p)=>r[p]=BigInt(u+p+1)));break;
      case 3: B.splice(0,6,M,M-1n,M-2n,M-3n,M-4n,M-5n);D.fill(720n);S.forEach(r=>r.splice(0,5,M-9n,M-8n,M-7n,M-6n,M-5n));break;
      case 4: B.splice(0,6,2n,3n,5n,7n,11n,13n);D.fill(721n);S.forEach(r=>r.splice(0,5,2n,3n,5n,7n,11n));break;
      case 5: B.splice(0,6,13n,11n,7n,5n,3n,2n);D.fill(720n);D[45]=1n;break;
      case 6: B.splice(0,6,1n,M,2n,M2,3n,M-2n);D[45]=720n;break;
      case 7: B.splice(0,6,2n,4n,8n,16n,32n,64n);D.forEach((_,j)=>D[j]=BigInt((j%2===0)?719:2));break;
      case 8: B.splice(0,6,M,1n,M,1n,M,1n);D.forEach((_,j)=>D[j]=BigInt(j+715));break;
      case 9: B.splice(0,6,2n,3n,5n,7n,11n,13n);D.forEach((_,j)=>D[j]=M-BigInt(j));break;
      case 10: B[2]=M;S.forEach((r,u)=>r[u%5]=M);break;
      case 11: S.forEach((r,u)=>r.splice(0,5,1n,M,2n,M2,3n));D.fill(719n);break;
      case 12: B.splice(0,6,1n,127n,511n,512n,513n,M);D.forEach((_,j)=>D[j]=BigInt(1+j*720));S.forEach((r,u)=>r.splice(0,5,1n,512n,513n,1024n,M));break;
      default:throw Error("E_ANCHOR_INDEX");
    }
    return {bowls:B,visible:D,stones:S};
  }
  const state={cases:0,drops:0,comparisons:0,range:0,immutability:0,roundtrips:0,final_orders:0,replays:0,digest:0xcbf29ce484222325n};
  function assess(q,keepTrace=false){
    valid(q);
    const before=sourceSignature(q);
    let a=q.bowls.slice(),b=q.bowls.slice(),lastA=null,lastB=null,trace=[];
    for(let u=1;u<=46;u++){
      const aa=stepA(a,q.visible[u-1],q.stones[u-1],u);
      const bb=stepB(b,q.visible[u-1],q.stones[u-1],u);
      must(aa.order.join(",")===bb.order.join(","),"E_ORDER_AT_DROP_"+u);
      for(let id=0;id<6;id++){
        must(aa.bowls[id]===bb.bowls[id],"E_NUMERIC_DIFF_CASE_"+state.cases+"_DROP_"+u+"_BOWL_"+(id+1));
        must(aa.bowls[id]>=1n&&aa.bowls[id]<=M,"E_RANGE");
        must(decode(encode(aa.bowls[id]))===aa.bowls[id],"E_CANONICAL_ROUNDTRIP");
        state.comparisons++;state.range++;state.roundtrips++;
        state.digest=digest(state.digest,aa.bowls[id]);
      }
      if(keepTrace&&(u===1||u===23||u===46))trace.push({drop:u,bowls:aa.bowls.map(String),order:aa.order});
      a=aa.bowls;b=bb.bowls;lastA=aa.order;lastB=bb.order;state.drops++;
    }
    must(lastA.join(",")===permutations[Number((q.visible[45]-1n)%720n)].join(","),"E_LAST_ORDER");
    must(lastA.join(",")===lastB.join(","),"E_LAST_ORDER_B");
    must(sourceSignature(q)===before,"E_INPUT_MUTATED");
    state.immutability++;state.final_orders++;state.cases++;
    lastA.forEach(n=>state.digest=digest(state.digest,BigInt(n)));
    return {bowls:a.map(String),order:lastA,trace};
  }
  must(save(M)===M&&save(M+1n)===1n&&fold(M)===M&&fold(M+1n)===1n,"E_SAVE_BOUNDARIES");
  const anchors=[];
  for(let i=0;i<13;i++){
    const q=anchor(i),out=assess(q,true);
    anchors.push({label:"anchor_"+String(i).padStart(2,"0"),initial_bowls:q.bowls.map(String),first_visible:String(q.visible[0]),last_visible:String(q.visible[45]),final_bowls:out.bowls,final_order:out.order,trace:out.trace});
  }
  must(anchors[0].trace[0].bowls.join(",")==="19,22,25,19,20,21","E_HAND_WITNESS");
  for(let i=0;i<384;i++)assess(seededInput(i));
  const replayIDs=[0,4,12];
  for(const i of replayIDs){
    const q=anchor(i),pre=sourceSignature(q);
    let a=q.bowls.slice(),b=q.bowls.slice();
    for(let u=1;u<=46;u++){
      a=stepA(a,q.visible[u-1],q.stones[u-1],u).bowls;
      b=stepB(b,q.visible[u-1],q.stones[u-1],u).bowls;
    }
    must(a.map(String).join(",")===anchors[i].final_bowls.join(",")&&b.map(String).join(",")===anchors[i].final_bowls.join(",")&&sourceSignature(q)===pre,"E_REPLAY");
    state.replays++;
  }
  const invalidInputs=[];
  function rejected(label,q){let ok=false;try{valid(q);}catch{ok=true;}must(ok,"E_INVALID_NOT_REJECTED_"+label);invalidInputs.push(label);}
  const base=anchor(4);
  rejected("bowls_5",{...base,bowls:base.bowls.slice(0,5)});
  rejected("bowls_7",{...base,bowls:base.bowls.concat(1n)});
  rejected("visible_45",{...base,visible:base.visible.slice(0,45)});
  rejected("visible_47",{...base,visible:base.visible.concat(1n)});
  rejected("stones_45",{...base,stones:base.stones.slice(0,45)});
  rejected("stones_47",{...base,stones:base.stones.concat([Array(5).fill(1n)])});
  rejected("row_4",{...base,stones:[base.stones[0].slice(0,4),...base.stones.slice(1)]});
  rejected("row_6",{...base,stones:[base.stones[0].concat(1n),...base.stones.slice(1)]});
  rejected("zero",{...base,bowls:[0n,...base.bowls.slice(1)]});
  rejected("negative",{...base,visible:[-1n,...base.visible.slice(1)]});
  rejected("overflow",{...base,stones:[[M+1n,...base.stones[0].slice(1)],...base.stones.slice(1)]});
  rejected("non_bigint",{...base,bowls:["2",...base.bowls.slice(1)]});
  const malformed=[
    ["zero_sign",{sign:0,digits:1,limbs:[1]}],
    ["negative_sign",{sign:-1,digits:1,limbs:[1]}],
    ["digit_512",{sign:1,digits:1,limbs:[512]}],
    ["digit_negative",{sign:1,digits:1,limbs:[-1]}],
    ["highest_zero",{sign:1,digits:2,limbs:[1,0]}],
    ["truncated_digits",{sign:1,digits:2,limbs:[1]}],
    ["zero_value",{sign:1,digits:1,limbs:[0]}],
    ["overflow_value",{sign:1,digits:15,limbs:[...Array(14).fill(511),511]}]
  ];
  for(const [label,record] of malformed){let failed=false;try{decode(record);}catch{failed=true;}must(failed,"E_BAD_METADATA_ACCEPTED_"+label);}
  const fixtureB=[2n,3n,5n,7n,11n,13n],fixtureS=[2n,3n,5n,7n,11n];
  const truth=stepA(fixtureB,719n,fixtureS,1).bowls;
  const mutationNames=["swap-neighbors","id-for-position","omit-5LR","aux-shift","aux-no-stone"];
  const mutantWitnesses=mutationNames.map(mode=>{
    const wrong=stepA(fixtureB,719n,fixtureS,1,mode).bowls;
    const ix=wrong.findIndex((x,i)=>x!==truth[i]);
    must(ix>=0,"E_MUTANT_NOT_DISTINGUISHED_"+mode);
    return {mutant:mode,bowl_id:ix+1,expected:String(truth[ix]),mutant_value:String(wrong[ix])};
  });
  const expected=anchors[4].final_bowls;
  function auditNumbers(got){return Array.isArray(got)&&got.length===6&&got.every((x,i)=>x===expected[i]);}
  must(auditNumbers(expected),"E_AUDIT_POSITIVE");
  const corrupted=expected.slice();corrupted[3]=String(BigInt(corrupted[3])+1n);
  must(!auditNumbers(corrupted),"E_CORRUPT_NUMERIC_NOT_REJECTED");
  const expectedMarkers=["STAGE21_ORACLE_BEGIN","STAGE21_ORACLE_COMPLETE","STAGE21_ORACLE_PASS"];
  function auditMarkers(got){return Array.isArray(got)&&got.length===3&&got.every((v,i)=>v===expectedMarkers[i]);}
  must(auditMarkers(expectedMarkers),"E_MARKER_POSITIVE");
  must(!auditMarkers([expectedMarkers[0],"STAGE21_ORACLE_COMPLTE",expectedMarkers[2]]),"E_CORRUPT_MARKER_NOT_REJECTED");
  must(state.cases===397&&state.drops===18262&&state.comparisons===109572&&state.roundtrips===109572&&state.replays===3,"E_COUNTS");
  return {
    project_id:"PC-BRANCH-FALSE-ARABIC",branch:"FALSE+العربية",
    stage:21,status:"INDEPENDENT_MATHEMATICAL_QA_ONLY_NOT_NATIVE_NOT_ACCEPTED",
    prior_accepted_stage:20,reference_operation:55,planned_production_operation:38,
    normative_blob_sha1:"3e9acc012bedf83294a6ec3cccb081a069556b5b",
    input_domain:"six 1..M bowls, 46 1..M visible, 46 rows of five 1..M stones; M=2^127-1",
    algorithms:["factoradic per bowl ID, BigInt modulo","recursive lexical enumeration per position, 127-bit Mersenne folding"],
    anchor_cases:anchors.length,seeded_cases:384,prng:"xorshift32 seed 0x21fa2026",
    cases_checked:state.cases,transitions_compared:state.drops,
    individual_bowl_comparisons:state.comparisons,range_assertions:state.range,
    canonical_base512_roundtrips:state.roundtrips,
    input_immutability_cases:state.immutability,final_order_checks:state.final_orders,
    replay_checks:state.replays,permutation_cross_checks:720,
    positive_mod_boundary_checks:4,semantic_invalid_rejections:invalidInputs,
    invalid_base512_metadata_rejections:malformed.map(x=>x[0]),numeric_mutant_witnesses:mutantWitnesses,
    deliberately_corrupt_numeric_result_rejected:true,
    deliberately_corrupt_output_marker_rejected:true,
    all_outputs_digest_fnv1a64_derived:"0x"+state.digest.toString(16).padStart(16,"0"),
    witness_drop1:anchors[0].trace[0],
    anchors,native_run:false,ci_run:false,production_op38_implemented:false,stage21_accepted:false,
    physical_pointer_safety_assessed:false
  };
})();
process.stdout.write(JSON.stringify(report,null,2)+"\n");
