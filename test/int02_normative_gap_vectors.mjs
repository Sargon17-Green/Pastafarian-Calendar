// PC-BRANCH-COBOL-SIMPLIFIED-CHINESE; independent QA-only literal primary-source transcription.
// Run with node; outputs deterministic JSON. Not Native or a production implementation.
function normativeVectors(){
 const M=170141183460469231731687303715884105727n,E=-15055671n;
 const S=x=>{const r=x%M;return r===0n?M:r};
 const perms=[];const enumerate=(prefix,remaining)=>{if(!remaining.length){perms.push(prefix);return}for(const b of remaining)enumerate(prefix.concat(b),remaining.filter(v=>v!==b))};enumerate([], [1,2,3,4,5,6]);
 const sq=x=>x*x, day=d=>d<E?2n*(E-d):2n*(d-E)+1n;
 const table=[[17n,29n,43n,71n,101n]];
 for(let i=2;i<=46;i++){const a=table.at(-1);table.push(a.map((v,j)=>S(sq(v)+BigInt([3,5,7,11,13][j])*a[(j+1)%5]+(j===0?BigInt(i):a[j-1]))))}
 const coefficients=[[3,5,7,11],[5,7,11,13],[7,11,13,17],[11,13,17,19],[13,17,19,23],[17,19,23,29],[19,23,29,31],[23,29,31,37],[29,31,37,41],[31,37,41,43],[37,41,43,47]];
 const hiddenWeights=[[3,4,6,8],[5,7,10,12],[7,10,14,16],[9,13,18,20],[11,16,22,24],[13,19,26,28],[15,22,30,32]];
 const sum=a=>a.reduce((x,y)=>x+y,0n);
 function sauce(action,target){
  const a=day(action),t=day(target),distance=(action>target?action-target:target-action)+1n,joined=a+t,path=target<action?1n:target===action?2n:3n,counts=[a,t,distance,joined,path];
  const drops=new Map(),trace={};
  for(let h=1;h<=7;h++){
   const stones=table[h-1],weights=[1,...hiddenWeights[h-1]];
   let v=S(sum(counts.map((c,j)=>c*BigInt(weights[j])))+sum(stones));
   for(let grind=1;grind<=7;grind++)v=S(sq(v)+3n*v+stones[(grind-1)%5]+BigInt(grind));
   drops.set(-h,v)
  }
  let bowls=new Map([17,19,23,29,31,37].map((p,j)=>[j+1,S(sq(a+BigInt(j+1)*t+distance+joined+path+BigInt(p*p))+BigInt(j+1))]));
  let last;
  for(let i=1;i<=46;i++){
   const lookup=offset=>drops.get(i-offset>0?i-offset:i-offset-1);
   const p=lookup(1),q=lookup(3),r=lookup(7),stones=table[i-1];
   let x=S(sum(stones.map((v,j)=>v*counts[j]))+p+3n*q+5n*r+BigInt(i));
   for(const [j,c] of coefficients.entries())x=S(sq(x)+BigInt(c[0])*x+BigInt(c[1])*p+BigInt(c[2])*q+BigInt(c[3])*r+stones[j%5]);
   drops.set(i,x);last=perms[Number((x-1n)%720n)];
   const old=bowls;bowls=new Map(last.map((b,j)=>{const l=old.get(last[(j+5)%6]),rr=old.get(last[(j+1)%6]),v=old.get(b);
    const pour=j<3?S(sq(x)+stones[j]*v+BigInt([3,5,7][j]*i)):0n;
    return [b,S(sq(v+2n*l+3n*rr+pour+x+stones[j%5])+5n*l*rr+BigInt(i*(j+1)))]
   }));
   if(i===1||i===46)trace["drop"+i]={value:x,order:last,bowls:Array.from({length:6},(_,j)=>bowls.get(j+1))}
  }
  for(let i=1;i<=12;i++){const total=S(sum([...bowls.values()])+149n*BigInt(i)),order=perms[Number((total-1n)%720n)],old=bowls;
   bowls=new Map(order.map((b,j)=>{const l=old.get(order[(j+5)%6]),r=old.get(order[(j+1)%6]);return [b,S(sq(old.get(b)+3n*l+5n*r+total+BigInt(i+(j+1)**2))+7n*l*r)]}))
  }
  return {bowls:Array.from({length:6},(_,j)=>bowls.get(j+1)),last,hidden:Array.from({length:7},(_,j)=>drops.get(-j-1)),trace}
 }
 function query(s,seal,n){const next=s.last[(s.last.indexOf(1)+1)%6],x=S(sq(s.bowls[0]+seal+181n)+179n*s.bowls[next-1]+seal),direction=S(sq(x+seal+194n)+193n*x+197n*s.bowls[5]),limit=M-M%n;
  let accepted=x;if(x>limit)accepted=direction%2n===1n?1n:limit;
  return {first:x,direction,rank:(accepted-1n)%n+1n}
 }
 const cache=new Map();function gap(k){if(!cache.has(k)){const s=sauce(E,E+BigInt(k)),q=query(s,1n,922n);cache.set(k,{index:k,gap:Number(41n+q.rank),...s,query:q})}return cache.get(k).gap}
 const neg=[],pos=[];let lo=E,hi=E;
 for(let k=1;lo>=E-5778n;k++){lo-=BigInt(gap(-k));neg.push(lo)}
 for(let k=1;hi<=E+5778n;k++){hi+=BigInt(gap(k));pos.push(hi)}
 const window=neg.reverse().concat([E],pos),candidates=[];
 for(let left=0;left<window.length;left++)for(let right=left+6;right<window.length;right++){const l=window[left],r=window[right];if(l<E&&E<=r&&r-l>=252n&&r-l<=5778n)candidates.push([l,r])}
 candidates.sort((p,q)=>Number((p[1]-p[0])-(q[1]-q[0]))||Number(p[0]-q[0]));
 const selection=query(sauce(E,E),10n,BigInt(candidates.length));
 const six=[-3,-2,-1,1,2,3].map(k=>gap(k));
 if(six.join()!=="329,441,503,345,818,831"||window.length!==23||candidates.length!==43||selection.rank!==15n||candidates[14].join()!=="-15057703,-15053459")throw Error("reference disagreement");
 return {source_sha256:"0add0726ef80f160f73594eba50c246c0bdeb0a5f613e14b6baa23e2f5321aae",epoch:E,scope:"QA_MODEL_ONLY_NOT_NATIVE",signed_gaps:[...cache.values()].sort((a,b)=>a.index-b.index),window,candidates,selection,year:candidates[14],epoch_sauce:sauce(E,E)};
}
console.log(JSON.stringify(normativeVectors(),(_,v)=>typeof v==='bigint'?v.toString():v,2));
