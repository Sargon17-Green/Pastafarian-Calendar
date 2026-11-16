'use strict';
// Reference-month feasibility only. Never imports or calls the Lua oracle.
const assert = require('node:assert/strict');
const HEAD = 'bab5ebcbfdc97c3e7d1bb1f617b6b80ad905e5aa';
const F0 = [{day:-15055671,open:-15057703,close:-15053459,L:4244},
            {day:-15043671,open:-15047236,close:-15042878,L:4358}];
const CAPS = {months:8,dpStates:50000,rawVectors:1000000n,memoStates:20000,
              heapMiB:128,seconds:60};
function months(L) {return [Math.max(3,Math.ceil(L/123)),Math.min(47,Math.floor(L/4))]}
function vectors(a) {return a.reduce((p,n)=>p*BigInt(n+1),1n)}
function extremes(L,m) {
  assert(m*4<=L&&L<=m*123);
  const concentrated=Array(m).fill(4);let surplus=L-4*m;
  for(let i=0;i<m;i++){const step=Math.min(119,surplus);concentrated[i]+=step;surplus-=step}
  const balanced=Array(m).fill(Math.floor(L/m));for(let i=0;i<L%m;i++)balanced[i]++;
  return [vectors(concentrated),vectors(balanced)];
}
function screen(w) {
  assert(w.close-w.open===w.L,'F0 interval mismatch');
  const [min,max]=months(w.L), cases=[];
  for(let m=min;m<=max;m++) {
    const dp=(w.L+1)*(m+1), [minVec,maxVec]=extremes(w.L,m);
    const reason=[];
    if(m>CAPS.months)reason.push('MONTH_CAP');
    if(dp>CAPS.dpStates)reason.push('DP_UPPER_BOUND_CAP');
    if(maxVec>CAPS.rawVectors)reason.push('VECTOR_RECTANGULAR_UPPER_BOUND_CAP');
    cases.push({m,dp,dpTransitionsUpper:dp*120,minVectorDigits:String(minVec).length,
      maxVectorDigits:String(maxVec).length,reason,admitted:reason.length===0});
  }
  return {calculationDay:w.day,L:w.L,minMonths:min,maxMonths:max,
    candidateCount:cases.length,rejected:cases.filter(x=>!x.admitted).length,
    dpStateBound:[cases[0].dp,cases.at(-1).dp],
    minRectangularVectorDigits:Math.min(...cases.map(x=>x.minVectorDigits)),
    maxRectangularVectorDigits:Math.max(...cases.map(x=>x.maxVectorDigits)),
    certified:cases.every(x=>x.admitted)};
}
function guarded(w,thunk){const x=screen(w);if(!x.certified)return false;thunk();return true}
let tests=0;function check(f){f();tests++}
check(()=>assert.deepEqual(months(4244),[35,47]));
check(()=>assert.deepEqual(months(4358),[36,47]));
check(()=>assert.equal(screen(F0[0]).rejected,13));
check(()=>assert.equal(screen(F0[1]).rejected,12));
check(()=>{let n=0;assert.equal(guarded(F0[0],()=>n++),false);assert.equal(n,0)});
check(()=>{let n=0;assert.equal(guarded(F0[1],()=>n++),false);assert.equal(n,0)});
check(()=>assert.equal(vectors(Array(9).fill(123)),124n**9n));
check(()=>assert.throws(()=>screen({...F0[0],close:0}),/interval mismatch/));
const reports=F0.map(screen);
console.log(JSON.stringify({projectId:'PC-BRANCH-LUA-HAITIAN',sourceHead:HEAD,
 budget:{...CAPS,rawVectors:String(CAPS.rawVectors)},reports,tests,
 scope:'STATIC_SCREEN_ONLY',nativeLua:false,calendarDate:false},null,2));
console.log('MONTH_RESOURCE_STATIC_SELFTEST_PASS: '+tests+'/8');
console.log('F0_UNBOUNDED_REFERENCE_PREVENTED: 2/2');
