// Independent synthetic enumerator. Does not import normative_oracle.lua or production code.

// No random fixtures, rank/unrank, memoization, factorials or calendarDateSpaghetti.

"use strict";

const data = require("./lua_haitian_f2_fixtures.json");

const {structures,witnesses,cutletNames,monthNames}=data;

function requireF2(condition,message){if(!condition)throw new Error("F2_FAIL "+message);}

function ledgerF2(s){
 requireF2(Number.isSafeInteger(s.number),"year number");
 const gates=s.gates, K=gates.length-1, L=gates[K]-gates[0];
 requireF2(K>=6&&K<=17&&L>=252&&L<=512,"bounded synthetic year limits");
 requireF2(s.cutletIndices.length===K&&new Set(s.cutletIndices).size===K,"cutlet count/uniqueness");
 requireF2(s.cutletIndices.every(x=>Number.isInteger(x)&&cutletNames[x]),"cutlet names");
 for(let i=1;i<gates.length;i++)requireF2(Number.isSafeInteger(gates[i])&&gates[i]-gates[i-1]>=42&&gates[i]-gates[i-1]<=963,"gates and min/max gaps");
 const m=s.monthLengths.length;
 requireF2(m>=3&&m<=47&&m===s.monthNameIndices.length&&new Set(s.monthNameIndices).size===m,"month shape/names");
 requireF2(s.monthNameIndices.every(x=>Number.isInteger(x)&&monthNames[x]),"month canonical names");
 requireF2(s.monthLengths.every(x=>Number.isInteger(x)&&x>=4&&x<=123)&&s.monthLengths.reduce((a,b)=>a+b,0)===L,"month lengths");
 requireF2(s.monthRuns.length<=64,"run limit");
 const dayMonth=[],left=Array(m).fill(0),first=[],last=[];
 for(const pair of s.monthRuns){
  requireF2(Array.isArray(pair)&&pair.length===2&&Number.isInteger(pair[0])&&pair[0]>=1&&pair[0]<=m&&Number.isInteger(pair[1])&&pair[1]>=1,"valid month run");
  const id=pair[0],n=pair[1];
  requireF2(dayMonth.length+n<=L,"weave length upper limit");
  if(first.indexOf(id)<0)first.push(id);
  for(let j=0;j<n;j++){dayMonth.push(id);left[id-1]++}
  const old=last.indexOf(id);if(old>=0)last.splice(old,1);
  last.push(id);
 }
 requireF2(dayMonth.length===L&&left.every((x,i)=>x===s.monthLengths[i]),"weave day coverage");
 requireF2(first.length===m&&first.every((x,i)=>x===i+1),"month opening order");
 const lastPositions=Array(m).fill(-1);
 for(let i=0;i<L;i++)lastPositions[dayMonth[i]-1]=i;
 requireF2(lastPositions.every((x,i)=>i===0||x>lastPositions[i-1]),"month closing order");
 const dayCutlet=[];
 for(let actual=gates[0]+1;actual<=gates[K];actual++){
  let matches=0,cid=0;
  for(let ci=0;ci<K;ci++){if(gates[ci]<actual&&actual<=gates[ci+1]){matches++;cid=ci+1}}
  requireF2(matches===1,"partition disjoint/coverage at "+actual);
  dayCutlet.push(cid);
 }
 requireF2(dayCutlet.length===L,"partition count");
 return {left:gates[0],right:gates[K],month:dayMonth,cutlet:dayCutlet,length:L};
}

function dateF2(s,target){
 requireF2(Number.isSafeInteger(target),"target integer");
 const d=ledgerF2(s);
 if(target<=d.left||target>d.right)return null;
 const offset=target-d.left-1;
 const ci=d.cutlet[offset]-1,mi=d.month[offset]-1;
 let count=0;for(let i=0;i<=offset;i++)if(d.month[i]===mi+1)count++;
 return [s.number,cutletNames[s.cutletIndices[ci]],target-s.gates[ci],monthNames[s.monthNameIndices[mi]],count];
}

function runF2All(){
 let scanned=0; for(const id of Object.keys(structures))scanned+=ledgerF2(structures[id]).length;
 let checked=0;for(const w of witnesses){const got=dateF2(structures[w.structure],w.target);requireF2(got!==null&&got.length===5&&got.every((x,i)=>x===w.expected[i]),"witness "+w.id+" got "+JSON.stringify(got));requireF2(Number.isInteger(got[0])&&typeof got[1]==="string"&&Number.isInteger(got[2])&&typeof got[3]==="string"&&Number.isInteger(got[4]),"tuple types "+w.id);checked++}
 let negative=0;
 const rejected=(name,fn)=>{let caught=false;try{fn()}catch{caught=true}requireF2(caught,name+" did not reject");negative++};
 requireF2(dateF2(structures.A,-300)===null,"opening excluded");negative++;
 requireF2(dateF2(structures.A,-47)===null,"after closing excluded");negative++;
 rejected("noninteger",()=>dateF2(structures.A,-298.5));
 rejected("wrong month opening order",()=>ledgerF2({...structures.A,monthRuns:[[2,4],[1,4],[1,80],[3,4],[2,80],[3,80]]}));
 rejected("duplicate cutlet names",()=>ledgerF2({...structures.B,cutletIndices:[7,6,5,4,3,2,2]}));
 return {checked,scanned,negative};
}

const summary=runF2All();

console.log(`F2_INDEPENDENT_4_OF_4_PASS: ${summary.checked}/4 frozen witnesses`);

console.log(`F2_LEDGER_546_DAYS_PASS: ${summary.scanned} enumerated days`);

console.log(`F2_NEGATIVE_5_OF_5_PASS: ${summary.negative}/5 invalid/boundary checks`);

console.log("F2_ONLY_SYNTHETIC; NO_NATIVE_LUA_OR_PRODUCTION_CALENDAR_CLAIM");
