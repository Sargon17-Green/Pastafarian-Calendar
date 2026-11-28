// INT-02 isolated Native name-family differential gate.
// Build (repo root):
// cobc -x -free -Wall -Wstrict-typing -Wcall-params -Wlinkage -Wtruncate -Werror -o int02-name-driver test/int02_name_driver.cob src/calendar_name_family.cob src/big_integer.cob
// Run: node test/int02_name_diff.mjs ./int02-name-driver
// Independent oracle: explicit enumeration for small cases; reverse
// mixed-radix division for large cases, not production prefix skipping.
// Strict subprocess deadline, exact rows/status/word/input rank/heap.
import {spawnSync} from "node:child_process";
const check=(v,m)=>{if(!v)throw Error(m)};
const p=(n,k)=>{let t=1n;for(let i=0;i<k;i++)t*=BigInt(n-i);return t};
function reverse(n,k,r){
 let v=r-1n,d=Array(k);
 for(let i=k-1;i>=0;i--){let b=BigInt(n-i);d[i]=Number(v%b);v/=b}
 check(v===0n,"oracle range");
 let a=Array.from({length:n},(_,i)=>i+1);
 return d.map(x=>a.splice(x,1)[0]);
}
const requests=[],expected=[];
const pad=(x,n)=>String(x).padStart(n,"0");
const word=(a,fill=98)=>[...a,...Array(47-a.length).fill(fill)];
function add(mode,n,k,r,a,status,res,out=a,occupied=0){
 requests.push(mode+occupied+pad(n,2)+pad(k,2)+String(r).padStart(61," ")+a.map(x=>pad(x,2)).join(""));
 expected.push([status,String(res),String(r),out.map(x=>pad(x,2)).join(""),0]);
}
let families=0,smallRows=0,large=0;
for(let n=1;n<=5;n++)for(let k=1;k<=n;k++){
 let all=[];
 function gen(a){if(a.length===k){all.push(a);return}for(let x=1;x<=n;x++)if(!a.includes(x))gen([...a,x])}
 gen([]);check(BigInt(all.length)===p(n,k),"oracle count");
 add("C",n,k,0n,word([]),0,p(n,k));families++;
 all.forEach((a,i)=>{let r=BigInt(i+1);check(String(reverse(n,k,r))===String(a),"oracle agreement");
  add("R",n,k,0n,word(a),0,r);add("U",n,k,r,word([]),0,0n,word(a,0));smallRows++;
 });
 add("U",n,k,0n,word([]),23,0n);
 add("U",n,k,p(n,k)+1n,word([]),23,0n);
}
for(const [n,k] of [[17,6],[17,17],[47,3],[47,23],[47,47]]){
 const t=p(n,k);add("C",n,k,0n,word([]),0,t);
 for(const r of [1n,t,(t+1n)/2n]){
  const a=reverse(n,k,r);add("R",n,k,0n,word(a),0,r);
  add("U",n,k,r,word([]),0,0n,word(a,0));large++;
 }
 add("U",n,k,t+1n,word([]),23,0n);
}
add("R",5,3,0n,word([1,1,2]),23,0n);
add("R",5,3,0n,word([0,1,2]),23,0n);
add("R",5,3,0n,word([6,1,2]),23,0n);
add("C",0,1,0n,word([]),22,0n);
add("C",48,1,0n,word([]),22,0n);
add("C",5,0,0n,word([]),22,0n);
add("C",5,6,0n,word([]),22,0n);
add("X",5,3,0n,word([]),22,0n);
add("U",5,3,-1n,word([]),23,0n);
for(const m of ["C","R","U"])add(m,5,3,1n,word([1,2,3]),24,7n,word([1,2,3]),1);
check(requests.every(x=>x.length===161),"wire width");
if(process.argv[2]==="--oracle-only"){
 console.log(JSON.stringify({families,smallRows,large,requests:requests.length,verdict:"ORACLE_ONLY_NOT_NATIVE"}));process.exit(0)
}
check(process.argv[2],"missing executable");
const z=spawnSync(process.argv[2],[],{input:pad(requests.length,6)+"\n"+requests.join("\n")+"\n",encoding:"utf8",timeout:120000,maxBuffer:8*1024*1024});
check(!z.error&&z.status===0,"native process: "+String(z.error)+" exit="+z.status+" stderr="+z.stderr);
const lines=z.stdout.trimEnd().split(/\r?\n/);check(lines.length===expected.length,"row count "+lines.length);
for(let i=0;i<lines.length;i++){const a=lines[i].split("|"),e=expected[i];
 check(a.length===5&&Number(a[0])===e[0]&&a[1]===e[1]&&a[2]===e[2]&&a[3]===e[3]&&Number(a[4])===0,"row "+i+" actual="+lines[i]+" expected="+e.join("|"));
}
console.log(JSON.stringify({families,smallRows,large,requests:requests.length,heapNonzero:0,unexpected:0,verdict:"INT02_NAME_NATIVE_PASS"}));
