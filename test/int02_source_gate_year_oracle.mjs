// PC-BRANCH-COBOL-SIMPLIFIED-CHINESE | INT-02 integration planning oracle, not Stage56.
// Independently transcribed from author-supplied Pasted text(20261127-150032).txt.
// Raw SHA-256 0add0726ef80f160f73594eba50c246c0bdeb0a5f613e14b6baa23e2f5321aae; 78600 bytes; 894 CRLF; Git blob 97cef204b9ed0c374e3b338926c799da04a501da.
// Source lock applies to this attachment and forward RD scope; raw bytes retained in user attachment, not copied into repository.
// Footnote 13: max year 5778; footnote 12: wide selection deterministic, not probability-uniform.
// No separate Appendix A or explicit inverse contract in supplied text. Do not infer full multi-calendar inverse or Venus day boundary.
// Run: node test/int02_source_gate_year_oracle.mjs. No production linkage. Bounded epoch-local witnesses only.
function int02(){
 const M=(1n<<127n)-1n,E=-15055671n;
 const mod=(x,m)=>((x%m)+m)%m,save=x=>mod(x-1n,M)+1n;
 const number=d=>d>=0n?2n*d+1n:-2n*d;
 const abs=x=>x<0n?-x:x;
 const counts=(a,t)=>[number(a-E),number(t-E),abs(t-a)+1n,number(a-E)+number(t-E),t<a?1n:t===a?2n:3n];
 const factorial=n=>{let r=1n;for(let j=2n;j<=BigInt(n);j++)r*=j;return r};
 function perm(rank){let available=[0,1,2,3,4,5],result=[];for(let n=6;n>0;n--){const f=factorial(n-1),i=Number(rank/f);rank%=f;result.push(available.splice(i,1)[0])}return result}
 const stones=[[17n,29n,43n,71n,101n]];
 for(let k=2;k<=46;k++){let [a,b,c,d,e]=stones.at(-1);stones.push([save(a*a+3n*b+BigInt(k)),save(b*b+5n*c+a),save(c*c+7n*d+b),save(d*d+11n*e+c),save(e*e+13n*a+d)])}
 const primes=[3n,5n,7n,11n,13n,17n,19n,23n,29n,31n,37n,41n,43n,47n];
 function sauce(a,t){
  const w=counts(a,t),v=[];
  for(let h=7;h>=1;h--){let i=BigInt(h),s=stones[h-1],x=save(w[0]+(2n*i+1n)*w[1]+(3n*i+1n)*w[2]+(4n*i+2n)*w[3]+(4n*i+4n)*w[4]+s.reduce((p,q)=>p+q,0n));for(let j=1;j<=7;j++)x=save(x*x+3n*x+s[(j-1)%5]+BigInt(j));v.push(x)}
  let bowls=[17n,19n,23n,29n,31n,37n].map((p,i)=>{let b=BigInt(i+1),x=w[0]+w[1]*b+w[2]+w[3]+w[4]+p*p;return save(x*x+b)}),order;
  for(let k=1;k<=46;k++){const s=stones[k-1],p=v.at(-1),q=v.at(-3),r=v.at(-7),i=BigInt(k);let x=save(s.reduce((sum,z,j)=>sum+z*w[j],0n)+p+3n*q+5n*r+i);
   for(let j=0;j<11;j++)x=save(x*x+primes[j]*x+primes[j+1]*p+primes[j+2]*q+primes[j+3]*r+s[j%5]);
   v.push(x);order=perm((x-1n)%720n);
   const old=bowls.slice(),next=old.slice();
   for(let j=0;j<6;j++){let b=order[j],l=old[order[(j+5)%6]],r=old[order[(j+1)%6]],direct=j<3?save(x*x+s[j]*old[b]+[3n,5n,7n][j]*i):0n,z=old[b]+2n*l+3n*r+direct+x+s[j%5];next[b]=save(z*z+5n*l*r+i*BigInt(j+1))}
   bowls=next;
  }
  const last=order.slice();
  for(let j=1;j<=12;j++){let i=BigInt(j),sum=save(bowls.reduce((x,y)=>x+y,0n)+149n*i),order=perm((sum-1n)%720n),old=bowls.slice(),next=old.slice();
   for(let k=0;k<6;k++){let b=order[k],l=old[order[(k+5)%6]],r=old[order[(k+1)%6]],z=old[b]+3n*l+5n*r+sum+i+BigInt(k+1)**2n;next[b]=save(z*z+7n*l*r)}bowls=next;
  }
  return {bowls,last};
 }
 function answer(s,b,seal){let x=save((s.bowls[b]+seal+181n)**2n+179n*s.bowls[s.last[(s.last.indexOf(b)+1)%6]]+seal);let d=save((x+seal+1n+193n)**2n+193n*x+197n*s.bowls[5]);return [x,d%2n===1n?1n:-1n]}
 // Rejected tail can be skipped exactly: first accepted is 1 (forward) or limit (backward).
 function choose(x,d,n,m=M){if(n<1n||x<1n||x>m||abs(d)!==1n)throw Error("bad choice");let power=m,wide=x,digit=x,weight=m;
  while(power<n){digit=mod(digit-1n+d,m)+1n;wide+=(digit-1n)*weight;weight*=m;power*=m}
  let limit=power-power%n;if(wide>limit)wide=d===1n?1n:limit;return (wide-1n)%n+1n}
 function select(a,t,b,seal,n){const [x,d]=answer(sauce(a,t),b,seal);return choose(x,d,n)}
 function gap(k){if(k===0n)throw Error("gate index zero");return 41n+select(E,E+k,0,1n,922n)}
 function gateWindow(a){let low=a-5778n,high=a+5778n;if(abs(a-E)>20000n)throw Error("oracle bounded to 20000 days from epoch");let pos=[E],neg=[],p=E,q=E;
  for(let k=1n;p<=high;k++){p+=gap(k);pos.push(p)}
  for(let k=1n;q>=low;k++){q-=gap(-k);neg.push(q)}
  return neg.reverse().concat(pos)
 }
 function yearCandidates(a,g){let out=[];for(let i=0;i<g.length;i++)for(let j=i+6;j<g.length;j++){let len=g[j]-g[i];if(len>5778n)break;if(g[i]<a&&a<=g[j]&&len>=252n)out.push([g[i],g[j]])}
  out.sort((a,b)=>{let x=a[1]-a[0],y=b[1]-b[0];return x<y?-1:x>y?1:a[0]<b[0]?-1:a[0]>b[0]?1:0});return out}
 let checks=0;function check(ok,msg){if(!ok)throw Error(msg);checks++}
 check(M===170141183460469231731687303715884105727n,"modulus");
 check(E===-278522n-14777149n,"epoch");
 check([number(-3n),number(-2n),number(-1n),number(0n),number(1n),number(2n),number(3n)].join()==="6,4,2,1,3,5,7","day numbers");
 const all=[];function enumerate(p,remaining){if(!remaining.length){all.push(p);return}for(const z of remaining)enumerate([...p,z],remaining.filter(x=>x!==z))}enumerate([],[0,1,2,3,4,5]);
 for(let k=0;k<720;k++)check(perm(BigInt(k)).join()===all[k].join(),"permutation "+k);
 // Independent literal step-by-step reduced-space oracle, including wide case.
 for(let m=2n;m<=9n;m++)for(let n=1n;n<=m*m+2n;n++)for(let x=1n;x<=m;x++)for(let d of [-1n,1n]){
  let power=m,digits=[x-1n];while(power<n){let next=mod(digits.at(-1)+d,m);digits.push(next);power*=m}
  let z=1n;for(let j=0;j<digits.length;j++)z+=digits[j]*m**BigInt(j);
  let bound=power-power%n;while(z>bound)z=mod(z-1n+d,power)+1n;
  check(choose(x,d,n,m)===(z-1n)%n+1n,"selection literal");
 }
 const witnesses=[];for(let k of [-3n,-2n,-1n,1n,2n,3n]){let g=gap(k);check(g>=42n&&g<=963n,"gap range");witnesses.push({index:k,gap:g})}
 const a=E,window=gateWindow(a),candidates=yearCandidates(a,window);check(candidates.length>0,"candidate existence");
 for(let [l,r] of candidates){check(l<a&&a<=r&&r-l>=252n&&r-l<=5778n,"candidate bounds");check(window.indexOf(r)-window.indexOf(l)>=6,"six intervals")}
 const rank=select(a,a,0,10n,BigInt(candidates.length)),year=candidates[Number(rank-1n)];
 check(year[0]<a&&a<=year[1],"selected year");
 return {checks,source_sha256:"0add0726ef80f160f73594eba50c246c0bdeb0a5f613e14b6baa23e2f5321aae",epoch:E,modulus:M,witnesses,action:a,window_gates:window.length,candidates:candidates.length,rank,year,scope:"MODEL_ONLY_NOT_NATIVE"};
}
console.log(JSON.stringify(int02(), (_,v)=>typeof v==='bigint'?v.toString():v,2));
// Recorded model execution:
// {
//   "checks": 5041,
//   "source_sha256": "0add0726ef80f160f73594eba50c246c0bdeb0a5f613e14b6baa23e2f5321aae",
//   "epoch": "-15055671",
//   "modulus": "170141183460469231731687303715884105727",
//   "witnesses": [
//     {
//       "index": "-3",
//       "gap": "329"
//     },
//     {
//       "index": "-2",
//       "gap": "441"
//     },
//     {
//       "index": "-1",
//       "gap": "503"
//     },
//     {
//       "index": "1",
//       "gap": "345"
//     },
//     {
//       "index": "2",
//       "gap": "818"
//     },
//     {
//       "index": "3",
//       "gap": "831"
//     }
//   ],
//   "action": "-15055671",
//   "window_gates": 23,
//   "candidates": 43,
//   "rank": "15",
//   "year": [
//     "-15057703",
//     "-15053459"
//   ],
//   "scope": "MODEL_ONLY_NOT_NATIVE"
// }
