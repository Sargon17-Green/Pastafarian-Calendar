// PROJECT_ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
// Host feasibility QA only, no Native or AC.1 acceptance.
// Exact upper bound B=product binom(S+sum_{i<=j}L_i,L_j).
// All counts nonnegative <= B; pairwise coprime product M>B makes CRT unique.
// Each p>5778, so every positive binomial update denominator is invertible.
// JS Number intermediates <2^53 for these 16-bit primes; CRT itself BigInt.
// V8 2026-11-28: 2040 differential checks; full L282 and L5778 exact.
// L5778: B 31877 bits, 2028 primes, 269744280 DP products, 31483 count bits.
// Storage: two CRT arrays 7970 bytes + 188 bytes residues/coefficients
// + 11558-byte inverse table = 19716 bytes, excluding metadata, rank,
// bound, temporaries, word, lease restoration and prime generation.
// The arrays alone exceed a single 8192-byte lease when inverse table used;
// removing inverse table leaves 34 bytes in lease, still not a complete fit.
// Per-count CPU excludes modular coefficient updates, CRT, etc.
// Prior synthetic whole-word row DP had 4237567 products per direction.
// Extrapolating a fixed 2028-prime pass to every product gives
// 8593785876 products (not measured, not a lower bound on adaptive CRT).
// At even 4 clocks/product that extrapolation exceeds 120000*70224 clocks.
// No claim that other algorithms or adaptive prime counts cannot fit.
function modularSuite(prior){
 const assert=(x,m)=>{if(!x)throw Error(m)};
 const primes=[];for(let p=65521;p>=32768;p-=2){let ok=true;for(let d=3;d*d<=p;d+=2)if(p%d===0){ok=false;break}if(ok)primes.push(p)}
 function residue(S,L,p){
  const T=S+L.reduce((a,b)=>a+b,0);assert(T<p,"prime domain");
  const inv=new Uint16Array(T+1);inv[1]=1;for(let i=2;i<=T;i++)inv[i]=(p-Math.floor(p/i)*inv[p%i]%p)%p;
  const C=(n,k)=>{let v=1;for(let i=1;i<=k;i++)v=v*(n-k+i)%p*inv[i]%p;return v};
  let t=S,ops=0;const rows=L.map(r=>{const s=t;t+=r;return {s,t,r,a:0,z:r===1?0:C(t-2,r-2)}});
  for(let k=1;k<=T;k++)for(let j=rows.length-1;j>=0;j--){const x=rows[j],q=j?rows[j-1].a:1;if(x.r===1){if(k===x.t)x.a=(x.a+q)%p}else if(k<=x.s+1){x.a=(x.a+q*x.z)%p;ops++;if(k<x.s+1)x.z=x.z*(x.s+1-k)%p*inv[x.t-1-k]%p}}
  return {v:rows.length?rows.at(-1).a:1,ops,invBytes:inv.byteLength}
 }
 function reconstruct(S,L){
  // Upper bound ignores ordering: choose positions of each new label among existing symbols.
  let bound=1n,n=S;for(const r of L){for(let i=1;i<=r;i++){bound=bound*BigInt(n+i)/BigInt(i)}n+=r}
  let x=0n,M=1n,used=0,ops=0;
  // Modular inverse of M mod p, independently via Euclid.
  function inverse(a,p){let b=p,u=1,v=0;while(b){let q=Math.floor(a/b);[a,b]=[b,a-q*b];[u,v]=[v,u-q*v]}assert(a===1,"coprime");return (u%p+p)%p}
  while(M<=bound){const p=primes[used++];assert(p,"primes exhausted");const P=BigInt(p),z=residue(S,L,p);ops+=z.ops;
   let d=(z.v-Number(x%P)+p)%p;d=d*inverse(Number(M%P),p)%p;x+=M*BigInt(d);M*=P;
  }
  assert(x<=bound,"CRT bound");return {x,used,ops,bits:bound.toString(2).length,actualBits:x.toString(2).length,crtBytes:2*Math.ceil(M.toString(2).length/8)}
 }
 let checks=0;for(let m=1;m<=4;m++){function gen(L){if(L.length<m){for(let r=1;r<=4;r++)gen([...L,r]);return}for(let S=0;S<=5;S++){const a=reconstruct(S,L),b=prior.suffix(S,L,0,{slots:0,ops:0});assert(a.x===b,"CRT mismatch "+S+"/"+L);checks++}}gen([])}
 const large=[];for(const L of [Array(47).fill(6),[...Array(46).fill(123),120]]){const start=Date.now(),b=prior.suffix(0,L,0,{slots:0,ops:0});const a=reconstruct(0,L);assert(a.x===b,"large CRT mismatch");const {x,...rest}=a;large.push({...rest,L:L.reduce((a,b)=>a+b,0),ms:Date.now()-start})}
 return {checks,large,primePool:primes.length};
}
if(typeof require!=="undefined"&&require.main===module){
 const fs=require("fs"),path=require("path");
 const src=fs.readFileSync(path.join(__dirname,"sm83_v32_shared_prefix_qa.js"),"utf8");
 const prior=new Function(src+"\nreturn optimizedSuite(true);")();
 console.log("HOST_V32_MODULAR_CRT="+JSON.stringify(modularSuite(prior)));
}
