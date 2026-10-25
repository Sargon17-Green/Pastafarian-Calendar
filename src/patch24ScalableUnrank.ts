import {MonsterStageError,MonsterValidationError} from "./monsterBase.ts";
// Stage49: exact suffix counting without enumerating full remaining-vector states.
function C(n:number,k:number):bigint{
 if(!Number.isSafeInteger(n)||!Number.isSafeInteger(k)||k<0||k>n)
  throw new MonsterStageError("binomial सीमा अवैध");
 let a=1n;const z=Math.min(k,n-k);
 for(let i=1;i<=z;i++)a=a*BigInt(n-z+i)/BigInt(i);
 return a;
}
export class ScalableLegalWeavingUnrank {
 readonly lengths:readonly number[];
 readonly totalDays:number;
 private total:bigint|null=null;
 private D=new Map<number,readonly bigint[]>();
 private H=new Map<string,bigint>();
 private queries=0;private transitions=0;
 constructor(lengths:readonly bigint[]){
  if(!Array.isArray(lengths)||lengths.length<3||lengths.length>47||
   lengths.some(x=>typeof x!=="bigint"||x<4n||x>123n))
   throw new MonsterValidationError("३..४७ महिने, ४..१२३ दिवस आवश्यक");
  this.lengths=Object.freeze(lengths.map(x=>Number(x)));
  this.totalDays=this.lengths.reduce((a,b)=>a+b,0);
  if(this.totalDays>5778)throw new MonsterValidationError("कमाल ५७७८ दिवस");
 }
 // D_a[k]: last occurrence of first still-unopened month at day k
 // in a fully legal word formed only of the unopened months.
 // Reverse time and month IDs to reuse first-of-latest distribution.
 private lastFirst(a:number):readonly bigint[]{
  const old=this.D.get(a);if(old)return old;
  let p:bigint[]=[1n],s=0;
  for(let j=this.lengths.length-1;j>=a;j--){
   const h=this.lengths[j]!,n=Array<bigint>(s+2).fill(0n);
   let prefix=0n,bin=C(s+h-2,h-2);
   for(let q=1;q<=s+1;q++){
    prefix+=p[q-1]??0n;n[q]=prefix*bin;this.transitions++;
    const nn=s-q+h-1;
    if(nn>h-2){
     const num=bin*BigInt(nn-h+2),den=BigInt(nn);
     if(num%den!==0n)throw new MonsterStageError("binomial recurrence अचूक नाही");
     bin=num/den;
    }else bin=0n;
   }
   p=n;s+=h;
  }
  const res=Array<bigint>(s+1).fill(0n);
  for(let k=1;k<=s;k++)res[k]=p[s+1-k]??0n;
  const answer=Object.freeze(res);this.D.set(a,answer);return answer;
 }
 // Insert active suffix of S days before final appearance of new first ID.
 private factor(a:number,S:number):bigint{
  if(a===this.lengths.length)return 1n;
  const key=a+":"+S,old=this.H.get(key);
  if(old!==undefined)return old;
  const dist=this.lastFirst(a);
  let sum=0n,bin=1n;
  for(let k=1;k<dist.length;k++){
   sum+=dist[k]!*bin; // bin = C(S+k-1,S)
   const numerator=bin*BigInt(S+k),den=BigInt(k);
   if(numerator%den!==0n)throw new MonsterStageError("interleaving पूर्णांक नाही");
   bin=numerator/den;
  }
  if(sum<1n)throw new MonsterStageError("suffix रिकामा");
  if(this.H.size>=12000)this.H.clear();
  this.H.set(key,sum);return sum;
 }
 private suffix(rem:readonly number[],opened:number,closed:number):bigint{
  this.queries++;
  let S=0n,B=1n;
  for(let j=closed;j<opened;j++){
   const r=rem[j]!;
   if(r<1)throw new MonsterStageError("active month शून्य");
   S+=BigInt(r);B*=C(Number(S)-1,r-1);
  }
  return B*this.factor(opened,Number(S));
 }
 count():bigint{
  if(this.total===null)this.total=this.suffix(this.lengths,0,0);
  return this.total;
 }
 itemAt1(rank:bigint):readonly number[]{
  if(typeof rank!=="bigint"||rank<1n||rank>this.count())
   throw new MonsterValidationError("1-based lex rank वैध हवा");
  let r=rank,opened=0,closed=0;
  const left=[...this.lengths],out:number[]=[];
  for(let day=0;day<this.totalDays;day++){
   let hit=false;
   for(let j=1;j<=Math.min(left.length,opened+1);j++){
    const i=j-1,n=left[i]!;
    if(n===0)continue;
    const first=n===this.lengths[i],last=n===1;
    if(first&&j!==opened+1)continue;
    if(last&&j!==closed+1)continue;
    left[i]=n-1;
    const nextOpen=opened+(first?1:0),nextClose=closed+(last?1:0);
    const ways=this.suffix(left,nextOpen,nextClose);
    if(r>ways){r-=ways;left[i]=n;continue;}
    out.push(j);opened=nextOpen;closed=nextClose;hit=true;break;
   }
   if(!hit)throw new MonsterStageError("exact lex branch अयशस्वी");
  }
  if(r!==1n||opened!==left.length||closed!==left.length||
   left.some(x=>x!==0))
   throw new MonsterStageError("exact lex weaving अपूर्ण");
  return Object.freeze(out);
 }
 statistics():Readonly<{distributionKinds:number;distributionCells:number;
  transitions:number;suffixQueries:number;cachedFactors:number}>{
  let cells=0;for(const x of this.D.values())cells+=x.length;
  return Object.freeze({distributionKinds:this.D.size,distributionCells:cells,
   transitions:this.transitions,suffixQueries:this.queries,cachedFactors:this.H.size});
 }
}
