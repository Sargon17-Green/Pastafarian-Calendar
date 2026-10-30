// Stage54/DISCOVERY27: research-only synthetic legacy-span diagnostic.
// A guessed contiguous month span is NOT the production month membership rule.
import assert from "node:assert/strict";
const MAX_DAYS=5778;
function legacySpan(word,month,day){
  assert(Array.isArray(word) && word.length>=1 && word.length<=MAX_DAYS,"valid word");
  assert(word.every(m=>Number.isSafeInteger(m)&&m>=1&&m<=47),"valid months");
  assert(Number.isSafeInteger(month)&&month>=1&&month<=47,"target month");
  assert(Number.isSafeInteger(day)&&day>=1&&day<=word.length,"day bound");
  const first=word.indexOf(month);
  const last=word.lastIndexOf(month);
  return first>=0 && day-1>=first && day-1<=last;
}
// Independent direct-membership oracle, not interval-search or shared implementation.
function oracle(word,month,day){return word[day-1]===month;}
const witness=[1,2,1,2,1,2,1,3,2,3,3,3,3];
let red=0,controls=0,wrongAccept=0,wrongReject=0;
const gaps=new Map([[1,[2,4,6]],[2,[3,5,7,8]],[3,[9]]]);
for(let month=1;month<=3;month++){
  const actualHoles=[];
  for(let day=1;day<=witness.length;day++){
    const old=legacySpan(witness,month,day), truth=oracle(witness,month,day);
    if(old!==truth){
      red++;
      if(old){wrongAccept++;actualHoles.push(day);}else wrongReject++;
    }else controls++;
  }
  assert.deepEqual(actualHoles,gaps.get(month),"independent 13-day witness");
}
assert.equal(red,8);assert.equal(controls,31);
assert.equal(wrongAccept,8);assert.equal(wrongReject,0);
assert.equal(legacySpan(witness,47,1),false,"absent month");
assert.equal(legacySpan([3,3,3],3,2),true,"single month");
const malformed=[
  ()=>legacySpan([],1,1),
  ()=>legacySpan(witness,0,1),
  ()=>legacySpan(witness,48,1),
  ()=>legacySpan(witness,1,0),
  ()=>legacySpan(witness,1,14),
  ()=>legacySpan(witness,1,1.5),
  ()=>legacySpan([1,48],1,1),
  ()=>legacySpan([0,1],1,1)
];
for(const f of malformed)assert.throws(f,assert.AssertionError);
let families=0,queries=0,falseAccept=0,falseReject=0,matched=0;
for(let seed=0;seed<256;seed++){
  let state=(seed+1)>>>0;
  const word=Array.from({length:47},(_,i)=>1+(i%5));
  for(let i=word.length-1;i>0;i--){
    state=(Math.imul(state,1664525)+1013904223)>>>0;
    const j=state%(i+1);
    [word[i],word[j]]=[word[j],word[i]];
  }
  for(let month=1;month<=5;month++){
    const actualDays=word.filter(v=>v===month).length;
    assert(actualDays>0,"present month");
    let membershipCount=0;
    for(let day=1;day<=word.length;day++){
      const old=legacySpan(word,month,day), truth=oracle(word,month,day);
      if(truth)membershipCount++;
      if(old&&!truth)falseAccept++;
      else if(!old&&truth)falseReject++;
      else matched++;
      queries++;
    }
    assert.equal(membershipCount,actualDays,"membership conservation");
  }
  families++;
}
assert.equal(families,256);assert.equal(queries,60160);
assert.equal(falseAccept,39124);assert.equal(falseReject,0);
assert.equal(matched,21036);
console.log("STAGE_54_DISCOVERY_27_SYNTHETIC_AUDIT_PASS witnesses=39 red=8 controls=31 rejected=8 families="+families+" queries="+queries+" falseAccept="+falseAccept+" falseReject="+falseReject+" oracleMismatch=0 nativeExecuted=0");
