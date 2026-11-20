#!/usr/bin/env node
'use strict';
/** Stage02 DISCOVERY01 independent k5/q6 arithmetic oracle. PROJECT_ID: PC-BRANCH-WAT-SPANISH.
 * Small ring model can have q>6 or n<=M^4; only medium/production assert k5/q6.
 * Not WAT/Native; independently reconstructed, not the uncommitted preflight bytes.
 */
function run() {
  const assert = (ok,msg)=>{if(!ok) throw Error(msg);};
  const check=(base,step,delta,walk)=>{
    assert(base>=13n && base%6n===1n,"M residue/domain");
    assert((step===1||step===-1)&&(delta===0||delta===1),"step/delta domain");
    const first=base-(step===1?7n:3n), space=base**5n;
    const digits=Array.from({length:5},(_,j)=>first+BigInt(step*j));
    assert(digits.every(a=>a>=1n&&a<=base),"five ring responses");
    const x=1n+digits.reduce((v,a,j)=>v+(a-1n)*base**BigInt(j),0n);
    const deficit=step===1
      ?3n*base**4n+4n*base**3n+5n*base**2n+6n*base+7n
      :7n*base**4n+6n*base**3n+5n*base**2n+4n*base+3n;
    assert(x===space-deficit,"radix vs independent polynomial");
    assert(x%6n===0n,"exact sixth required");
    const n=x/6n-BigInt(delta);
    assert(n>0n&&n<space,"positive count domain");
    const quotient=space/n;
    assert(quotient>=6n,"q lower bound");
    const limit=quotient*n;
    assert(limit<=space&&space<(quotient+1n)*n,"floor quotient");
    let accepted,rejected;
    if(x<=limit){accepted=x;rejected=0n;}
    else if(step===1){accepted=1n;rejected=deficit+1n;}
    else {accepted=limit;rejected=x-limit;}
    const rank=1n+(accepted-1n)%n;
    assert(accepted>=1n&&accepted<=limit&&rank>=1n&&rank<=n,"result bounds");
    if(quotient===6n){
      assert(limit===x-6n*BigInt(delta),"q6 exact limit");
      assert(rank===(delta&&step===1?1n:n),"q6 rank");
      if(delta&&step===-1) assert(rejected===6n,"six reverse rejections");
    }
    if(walk){
      let cursor=x,count=0;
      while(cursor>limit){
        cursor=step===1?(cursor===space?1n:cursor+1n):(cursor===1n?space:cursor-1n);
        assert(++count<=1250000,"bounded explicit walk limit");
      }
      assert(cursor===accepted&&BigInt(count)===rejected,"stepwise differential");
    }
    return {base:base.toString(),step,delta,first:first.toString(),
      quotient:quotient.toString(),n:n.toString(),x:x.toString(),
      limit:limit.toString(),accepted:accepted.toString(),
      rank:rank.toString(),rejections:rejected.toString()};
  };
  let small=0,steps=0n,medium=0;
  const smallQuotients={};
  for(const base of [13n,19n,25n]) for(const step of [1,-1]) for(const delta of [0,1]){
    const result=check(base,step,delta,true);
    small++;steps+=BigInt(result.rejections);
    smallQuotients[`${base}_${step}_${delta}`]=result.quotient;
  }
  assert(small===12&&steps===1237658n,"small differential regression total");
  assert(smallQuotients["13_1_0"]==="8"&&smallQuotients["13_-1_0"]==="14"
    &&smallQuotients["19_1_0"]==="7"&&smallQuotients["25_1_0"]==="6",
    "quotient is not universally six");
  for(const base of [55n,61n,67n,73n]) for(const step of [1,-1]) for(const delta of [0,1]){
    const result=check(base,step,delta,false);
    assert(result.quotient==="6"&&BigInt(result.n)>base**4n,"medium true k5/q6 gate");
    medium++;
  }
  assert(medium===16,"medium case count");
  const productionBase=(1n<<127n)-1n,production={};
  for(const step of [1,-1]) for(const delta of [0,1]){
    const result=check(productionBase,step,delta,false);
    assert(result.quotient==="6"&&BigInt(result.n)>productionBase**4n,"production k5/q6 gate");
    production[`${step===1?"forward":"backward"}_${delta===0?"exact":"rejected"}`]=result;
  }
  return {project_id:"PC-BRANCH-WAT-SPANISH",mode:"independent_bigint_math_only_not_native",
    k:5,requested_quotient:6,small_stepwise_cases:small,
    small_rejection_steps:Number(steps),medium_q6_algebraic_cases:medium,
    production_q6_algebraic_cases:4,production,failed:0,
    native:"NOT_EXECUTED_BY_THIS_ORACLE"};
}
if (require.main === module) console.log(JSON.stringify(run()));
module.exports = {run};
