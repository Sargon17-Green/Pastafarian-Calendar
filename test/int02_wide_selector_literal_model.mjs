// Independent literal cyclic walk vs closed-form selector; no Native claim.
let checks=0,rejected=0;
for(let m=2;m<=11;m++){
 const M=BigInt(m);
 for(let n=1;n<=m*m+3;n++)for(let a=1;a<=m;a++)for(const dir of [-1n,1n]){
  const N=BigInt(n);
  let S=1n,X=1n,digit=BigInt(a);
  do { X+=(digit-1n)*S; S*=M; digit=(digit-1n+dir+M)%M+1n; }while(S<N);
  const L=S-S%N; let c=X;
  if(c>L){rejected++;c=dir===1n?1n:L;}
  let literal=X; while(literal>L)literal=(literal-1n+dir+S)%S+1n;
  if((c-1n)%N!==(literal-1n)%N)throw Error("mismatch");
  checks++;
 }
}
console.log(JSON.stringify({checks,rejected,verdict:"ORACLE_ONLY_NOT_NATIVE"}));
