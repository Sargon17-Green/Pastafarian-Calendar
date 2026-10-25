import {MonsterStageError,MonsterValidationError}
 from "./monsterBase.ts";

// Stage49 संशोधन: केवळ कायदेशीर weaving ची अचूक COUNT,
// अंतिम ranked weaving निवड अजून Stage49 मध्ये प्रलंबित.
// Forward invariant: नवीन month j च्या पहिल्या वापराची जागा q;
// मागील महिन्याचा first index p<q. शेवटचा j word च्या शेवटी.
// त्या q साठी उर्वरित insertions = C(S-q+Lj-1,Lj-2).
// त्यामुळे exponential remaining[1..m] states ऐवजी 1D BigInt distribution.
function chooseExact(n:number,k:number):bigint {
 if(!Number.isSafeInteger(n)||!Number.isSafeInteger(k)||k<0||k>n)
  throw new MonsterValidationError("नेमकी द्विपदी गणना वैध हवी");
 let v=1n;
 for(let i=1;i<=Math.min(k,n-k);i++)
  v=v*BigInt(n-Math.min(k,n-k)+i)/BigInt(i);
 return v;
}
export class ScalableLegalWeavingCounter {
 readonly lengths:readonly number[];
 readonly totalDays:number;
 private computed:bigint|null=null;
 private steps=0;
 constructor(monthLengths:readonly bigint[]){
  if(!Array.isArray(monthLengths)||monthLengths.length<3||
     monthLengths.length>47||
     monthLengths.some(x=>typeof x!=="bigint"||x<4n||x>123n))
   throw new MonsterValidationError("मर्यादित ३..४७ महिने, ४..१२३ दिवस आवश्यक");
  this.lengths=Object.freeze(monthLengths.map(x=>Number(x)));
  this.totalDays=this.lengths.reduce((a,b)=>a+b,0);
  if(this.totalDays<12||this.totalDays>5778)
   throw new MonsterValidationError("कुटुंबाचे दिवस १२..५७७८ आवश्यक");
 }
 count():bigint{
  if(this.computed!==null)return this.computed;
  let oldDistribution:readonly bigint[]=[1n]; // काल्पनिक पूर्व-महिन्याचे first p=0
  let olderDays=0;
  for(const len of this.lengths){
   const next=Array<bigint>(olderDays+2).fill(0n);
   let prefix=0n;
   let n=olderDays+len-2;
   const k=len-2;
   let binomial=chooseExact(n,k);
   for(let q=1;q<=olderDays+1;q++){
    prefix+=oldDistribution[q-1]??0n;
    next[q]=prefix*binomial;
    this.steps++;
    if(n>k){
     const numerator=binomial*BigInt(n-k);
     const denominator=BigInt(n);
     if(numerator%denominator!==0n)
      throw new MonsterStageError("द्विपदी recurrence पूर्णांक नाही");
     binomial=numerator/denominator;
    }else binomial=0n;
    n--;
   }
   oldDistribution=next;
   olderDays+=len;
  }
  const sum=oldDistribution.reduce((a,b)=>a+b,0n);
  if(sum<1n)throw new MonsterStageError("कायदेशीर month weaving संख्या शून्य");
  this.computed=sum;
  return sum;
 }
 statistics():Readonly<{months:number;days:number;transitions:number;peakDistributionCells:number}> {
  return Object.freeze({
   months:this.lengths.length,days:this.totalDays,
   transitions:this.steps,peakDistributionCells:this.totalDays+1
  });
 }
}
