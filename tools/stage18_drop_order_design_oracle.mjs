// Stage18 design-only independent oracle: Node.js 20+; no FALSE code imports.

// Canonical reference: test/normative_reference.false op52, git blob 3e9acc012bedf83294a6ec3cccb081a069556b5b.

import fs from "node:fs";

function euclidMod(a,b){let r=a%b;return r<0n?r+b:r;}

function rankOracle(x){return 1n+euclidMod(x-1n,720n);}

function rankAlternate(x){let r=euclidMod(x,720n);return r===0n?720n:r;}

function signedBase512(x){
  if(typeof x!=="bigint")throw Error("non-BigInt");
  if(x===0n)return {sign:0,count:1,limbs:[0]};
  let v=x<0n?-x:x,limbs=[];
  while(v>0n){limbs.push(Number(v%512n));v/=512n;}
  return {sign:x<0n?-1:1,count:limbs.length,limbs};
}

function decodeBase512(a){
  if(![-1,0,1].includes(a.sign)||a.count<1||a.count!==a.limbs.length)throw Error("invalid header");
  if(a.limbs.some(x=>!Number.isInteger(x)||x<0||x>511))throw Error("invalid limb");
  if(a.count>1&&a.limbs[a.count-1]===0)throw Error("padding");
  if((a.sign===0)!==(a.count===1&&a.limbs[0]===0))throw Error("zero");
  let v=0n;for(let i=a.limbs.length-1;i>=0;i--)v=v*512n+BigInt(a.limbs[i]);
  return v*BigInt(a.sign);
}

function permutationsLex(){
  const all=[];
  function recur(prefix,available){
    if(!available.length){all.push(prefix);return;}
    for(let i=0;i<available.length;i++)recur([...prefix,available[i]],[...available.slice(0,i),...available.slice(i+1)]);
  }
  recur([],[1,2,3,4,5,6]);return all;
}

function generateCases(){
  const vals=new Set();
  for(let n=-1440;n<=1440;n++)vals.add(BigInt(n).toString());
  for(const bits of [9,31,63,127,512,1024,2048]){
    for(const sign of [-1n,1n])for(const delta of [-1n,0n,1n])vals.add((sign*((1n<<BigInt(bits))+delta)).toString());
  }
  let state=0xF18A20261121n;
  const mask=(1n<<64n)-1n;
  for(let i=0;i<384;i++){
    const bits=[9,63,127,512,1024,2048][i%6];
    let n=0n;for(let j=0;j<Math.ceil(bits/64);j++){
      state=(state*6364136223846793005n+1442695040888963407n)&mask;
      n=(n<<64n)|state;
    }
    n&=(1n<<BigInt(bits))-1n;
    vals.add(((i%2?-1n:1n)*n).toString());
  }
  return [...vals].map(BigInt).sort((a,b)=>a<b?-1:a>b?1:0);
}

function runAll(){
  const arr=permutationsLex();
  if(arr.length!==720||new Set(arr.map(a=>a.join(","))).size!==720)throw Error("permutations not exhaustive");
  const known=[
    [-1440n,720,[6,5,4,3,2,1]],[-720n,720,[6,5,4,3,2,1]],
    [-719n,1,[1,2,3,4,5,6]],[-1n,719,[6,5,4,3,1,2]],
    [0n,720,[6,5,4,3,2,1]],[1n,1,[1,2,3,4,5,6]],
    [2n,2,[1,2,3,4,6,5]],[720n,720,[6,5,4,3,2,1]],
    [721n,1,[1,2,3,4,5,6]],[1440n,720,[6,5,4,3,2,1]],
    [1441n,1,[1,2,3,4,5,6]]
  ];
  for(let [v,r,ord] of known){
    if(rankOracle(v)!==BigInt(r)||arr[r-1].join(",")!==ord.join(","))throw Error("known anchor mismatch "+v);
  }
  for(let v=1n;v<=720n;v++)if(rankOracle(v)!==v)throw Error("full cycle gap "+v);
  const values=generateCases();
  let periodic=0;
  for(const v of values){
    const enc=signedBase512(v);
    if(decodeBase512(enc)!==v)throw Error("base512 roundtrip "+v);
    const a=rankOracle(v),b=rankAlternate(v);
    if(a!==b||a<1n||a>720n)throw Error("alternate rank mismatch "+v);
    const perm=arr[Number(a-1n)];
    if(perm.length!==6||new Set(perm).size!==6||perm.some(x=>x<1||x>6))throw Error("bad permutation");
    for(const offset of [-1440n,-720n,720n,1440n]){
      if(rankOracle(v+offset)!==a)throw Error("periodicity "+v);
      periodic++;
    }
  }
  const malformed=[
    {sign:2,count:1,limbs:[1]},{sign:1,count:0,limbs:[]},
    {sign:1,count:2,limbs:[1,0]},{sign:1,count:1,limbs:[512]},
    {sign:0,count:1,limbs:[1]}
  ];
  for(const item of malformed){
    let rejected=false;try{decodeBase512(item);}catch{rejected=true;}
    if(!rejected)throw Error("noncanonical BigInt accepted");
  }
  const mutants={
    "wrong_no_minus_one":v=>v%720n+1n,
    "wrong_absolute_value":v=>rankOracle(v<0n?-v:v),
    "wrong_truncating_remainder":v=>((v-1n)<0n?-(-(v-1n)%720n):(v-1n)%720n)+1n,
    "wrong_uint64_narrowing":v=>rankOracle(v&((1n<<64n)-1n)),
    "wrong_no_plus_one":v=>euclidMod(v-1n,720n),
  };
  const witnesses={};
  for(const [name,fn] of Object.entries(mutants)){
    const witness=values.find(v=>fn(v)!==rankOracle(v));
    if(witness===undefined)throw Error("mutant not rejected "+name);
    witnesses[name]=witness.toString();
  }
  if(arr[719].slice(0,4).join(",")===arr[719].slice().reverse().join(",").slice(0,4))throw Error("permutation mutant guard");
  const sample=new Set(known.map(x=>x[0].toString()));
  for(const v of [-((1n<<2048n)), -(1n<<127n)-1n,-721n,-2n,3n,6n,7n,24n,25n,360n,719n,722n,1442n,(1n<<127n)-1n,(1n<<127n),(1n<<127n)+1n,(1n<<2048n)])sample.add(v.toString());
  const vectors=[...sample].map(BigInt).sort((a,b)=>a<b?-1:a>b?1:0).map(v=>{
    const enc=signedBase512(v),rank=rankOracle(v);
    return {drop:v.toString(),bigint_sign:enc.sign,bigint_limb_count:enc.count,
      bigint_limbs_base512_le:enc.limbs,rank:Number(rank),order_direct:[6,...arr[Number(rank-1n)]]};
  });
  const summary={
    project_id:"PC-BRANCH-FALSE-ARABIC",stage:18,scope:"DESIGN_ONLY",
    normative_op:52,planned_production_op:35,
    reference_git_blob:"3e9acc012bedf83294a6ec3cccb081a069556b5b",
    rule:"1 + EuclideanMod(drop - 1, 720)",
    explicit_manual_anchors:known.length,
    exact_full_cycle_ranks_checked:720,
    contiguous_range:"[-1440,1440]",
    generated_signed_2048bit_max_cases:384,
    unique_bigint_values_checked:values.length,
    base512_roundtrips:values.length,
    periodicity_checks:periodic,
    malformed_bigint_exclusions:malformed.length,
    mutant_witnesses:witnesses,
    fixture_cases:vectors.length,
    native_run:false,ci_dispatched:false,stage18_accepted:false,
    unallocated_pointer_safety_tested:false
  };
  const fixtures={project_id:"PC-BRANCH-FALSE-ARABIC",stage:18,scope:"DESIGN_ONLY",
    input:"one allocated handle pointing to canonical sign/count/base512 little-endian BigInt",
    output:"fresh seven-cell direct [6,o1,o2,o3,o4,o5,o6]",
    cases:vectors};
  return {summary,fixtures};
}

const output=runAll();

fs.mkdirSync("evidence",{recursive:true});fs.mkdirSync("test",{recursive:true});

fs.writeFileSync("test/stage18_drop_order_design_vectors.json",JSON.stringify(output.fixtures,null,2)+"\n","utf8");

fs.writeFileSync("evidence/stage18_drop_order_design_oracle_2026-11-21.json",JSON.stringify(output.summary,null,2)+"\n","utf8");

process.stdout.write(JSON.stringify(output.summary,null,2)+"\n");
