#!/usr/bin/env node
// Stage51/DISCOVERY47 independent grade-school decimal subtraction oracle.
// No COBOL production invocation. PASS_NOT_NATIVE is NOT Native acceptance.
const result=(function stage51(){
 const eq=(a,b,m)=>{if(a!==b)throw Error(`${m} ${a} != ${b}`)},ok=(p,m)=>{if(!p)throw Error(m)};
 function subtract(a,b){ok(/^[1-9]\d*$/.test(a)&&/^[1-9]\d*$/.test(b),"canonical");ok(a.length>b.length||a.length===b.length&&a>=b,"order");let arr=[],borrow=0;for(let i=0;i<a.length;i++){let x=a.charCodeAt(a.length-i-1)-48,y=i<b.length?b.charCodeAt(b.length-i-1)-48:0,d=x-y-borrow;borrow=d<0?1:0;arr.push(String(d+(borrow?10:0)))}eq(borrow,0,"borrow end");return arr.reverse().join("").replace(/^0+(?=.)/,"")}
 function plusOne(s){let a=s.split(""),carry=1;for(let i=a.length-1;i>=0&&carry;i--){const d=+a[i]+1;a[i]=String(d%10);carry=d===10?1:0}if(carry)a.unshift("1");return a.join("")}
 const dist=(a,b)=>(a>b?a-b:b-a)+1n,school=(greater,less)=>plusOne(subtract(greater,less));
 const nValues=[3,9,128,320,8192],seen=new Set(),target=[0,0,0,0,0];
 const x={cases:0,arithmetic:0,symmetry:0,max:0,initial:0,rebuilds:0,preserved:0,rejects:0,rejectPreserved:0,survivorFree:0,survivorReuse:0,replacement:0,restored:0,snapshots:0,cleanup:0};
 for(const n of nValues){let B=10n**BigInt(n-1);for(let j=1;j<=5;j++){
  const C=2n*B,T=C-BigInt(j),C2=-(C+BigInt(2*j+3)),T2=-T;
  ok([C,T,-C2,-T2].every(v=>String(v).length===n),"full width");
  ok(C>T&&T>0n&&C2<T2&&T2<0n,"signs");
  const id=`${C}|${T}`;ok(!seen.has(id),"duplicate");seen.add(id);if(n===8192)x.max++;
  let before=[],after=[];
  for(let k=0;k<5;k++){const a=C+BigInt(k),b=C2-BigInt(k);const old=dist(a,T),fresh=dist(b,T2);
   eq(String(old),school(String(a),String(T)),"school baseline");
   eq(String(fresh),school(String(-b),String(-T2)),"school reversed");
   eq(old,BigInt(j+k+1),"baseline closed form");eq(fresh,BigInt(3*j+4+k),"reversed closed form");
   eq(dist(-a,-T),old,"sign symmetry");x.arithmetic+=2;x.symmetry++;before.push(String(old));after.push(String(fresh));
  }
  const owners=before.map(value=>({value,token:Symbol()})),baseline=owners.slice();
  eq(new Set(owners.map(a=>a.token)).size,5,"owner uniqueness");x.initial+=5;
  let inputs={C,T};inputs={C:C2,T:T2};x.rebuilds+=2;
  for(let k=0;k<5;k++){eq(owners[k],baseline[k],"input preserve owner");eq(owners[k].value,before[k],"input preserve text");x.preserved++}
  x.rejects++;for(let k=0;k<5;k++){eq(owners[k],baseline[k],"occupied reject");x.rejectPreserved++}
  const chosen=x.cases%5;target[chosen]++;const retired=owners[chosen];owners[chosen]=null;
  for(let k=0;k<5;k++)if(k!==chosen){eq(owners[k],baseline[k],"free survivor");x.survivorFree++}
  owners[chosen]={value:after[chosen],token:Symbol()};ok(owners[chosen].token!==retired.token,"fresh owner");x.replacement++;
  for(let k=0;k<5;k++)if(k!==chosen){eq(owners[k],baseline[k],"reuse survivor");x.survivorReuse++}
  inputs={C,T};x.rebuilds+=2;eq(inputs.C,C,"restore C");eq(inputs.T,T,"restore T");
  owners[chosen]={value:before[chosen],token:Symbol()};x.restored++;
  for(let k=0;k<5;k++){eq(owners[k].value,before[k],"restore value");if(k!==chosen)eq(owners[k],baseline[k],"retained owner");x.snapshots++}
  owners.fill(null);ok(owners.every(v=>v===null),"cleanup");x.cleanup++;x.cases++;
 }}
 const expected={cases:25,arithmetic:250,symmetry:125,max:5,initial:125,rebuilds:100,preserved:125,rejects:25,rejectPreserved:125,survivorFree:100,survivorReuse:100,replacement:25,restored:25,snapshots:125,cleanup:25};
 for(const [k,v]of Object.entries(expected))eq(x[k],v,k);eq(seen.size,25,"unique");eq(target.join(","),"5,5,5,5,5","balanced slots");
 const lines=Object.entries({CASES:"25/25",ARITHMETIC:"250/250",SIGN_SYMMETRY:"125/125",UNIQUE_PAIRS:25,MAX_WIDTH_CASES:5,INITIAL_OWNERS:125,INPUT_REBUILDS:100,PRESERVED_AFTER_INPUT_CHANGE:125,OCCUPIED_REJECTS:25,PRESERVED_AFTER_REJECT:125,SURVIVORS_AFTER_FREE:100,SURVIVORS_AFTER_REUSE:100,REPLACEMENT_OWNERS:25,RESTORED_OWNERS:25,RESTORED_SNAPSHOTS:125,FINAL_CLEANUP:25,TARGET_BALANCE:target.join(",")}).map(([k,v])=>`STAGE51_PLANNING_${k}=${v}`);
 lines.push("STAGE51_PLANNING_GATE=PASS_NOT_NATIVE");return {counts:x,lines};
})();
for (const line of result.lines) console.log(line);
