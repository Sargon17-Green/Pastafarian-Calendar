// INT-02 bounded selection/family QA contract (2026-11-28).
// Author source SHA256 0add0726ef80f160f73594eba50c246c0bdeb0a5f613e14b6baa23e2f5321aae, independently verified.
// Tablets XV-XVI, XX-XXI, final tablet; source lines 463-562, 627-737, 785-812 and notes 881-889.
// Structure sauce input = action day and first day of selected year; seals 20/21/22, 30/31/32/33.
// Cutlet count 6..min(17,gaps); positive compositions of gaps; if action is interior gate require prefix sum.
// Month count max(3,ceil(yearLength/123))..min(47,floor(yearLength/4)); lengths 4..123.
// Names: ordered distinct indices 1..17 or 1..47. All family ranks one-based lexicographic.
// Weaving: prescribed multiplicities, ordered first and last appearances. Remaining counts uniquely
// encode unopened and finished states. Count all legal suffixes; rank/unrank skip exact prefix blocks.
// Wide selection: base M=2^127-1, digits are consecutive cyclic responses minus one, little-endian.
// If first value in rejected tail, forward wraps to 1, backward moves to acceptance limit.
// This is equivalent to literal stepping, NOT an assertion of probability uniformity (author footnote).
// Positive bounded composition count via inclusion-exclusion; gate count splits at mandatory boundary.
// Weave QA only: product(length_i+1)<=200000, sum<=512; explicit rejection outside scope.
// For full 5778 days / 47 months this bound is inadequate; no production readiness or Native claim.
// Future COBOL implementation must use exact BigInt, caller-owned disjoint outputs, explicit scope
// rejection and bounded resources; no Node production dependency. No year scope extension.
// Independent oracle: enumerate all small completed words without prefix legality pruning; compare all ranks.
// Reproduce: node test/int02_family_selection_bounded_model.mjs
// Observed execution in JS isolate (not COBOL): {"cases":302,"rows":2039,"invalid":622,"selection":9398,"large":[["cutlet names 17P17","355687428096000"],["month names 47P47","258623241511168180642964355153611979969197632389120000000000"],["month lengths 3000/47","88003541993000812045696274984690138927794465924381691059914859881723776043204069233708095150800"],["month lengths 5778/47","18424"],["cutlet gaps 137/17 mandatory gate 68","30756373941461374800"],["weave 123,123","1442510947272408307654871619267068456924448054023090354457865375161357600"],["weave 123,123,6","10833957994079260705755737601438586150242245131059118829223333146120866657711848624"]],"verdict":"QA_MODEL_ONLY_NOT_NATIVE"}

function qa(){
const M=(1n<<127n)-1n;
function check(x,msg){if(!x)throw Error(msg)}
function C(n,k){if(k<0||n<k)return 0n;let v=1n;k=Math.min(k,n-k);for(let i=1;i<=k;i++)v=v*BigInt(n-k+i)/BigInt(i);return v}
function P(n,k){let v=1n;for(let i=0;i<k;i++)v*=BigInt(n-i);return v}
function comp(s,k,l,h){
 if(k===0)return s===0?1n:0n;
 const t=s-k*l;if(t<0||s>k*h)return 0n;
 let v=0n;for(let j=0;j<=Math.min(k,Math.floor(t/(h-l+1)));j++)v+=(j%2?-1n:1n)*C(k,j)*C(t-j*(h-l+1)+k-1,k-1);return v
}
function gates(s,k,g){if(g===0||g===s||g===null)return comp(s,k,1,s||1);if(g<0||g>s)return 0n;let z=0n;for(let i=1;i<k;i++)z+=comp(g,i,1,g)*comp(s-g,k-i,1,s-g);return z}
function compositions(s,k,l,h,g=null){
 function count(s,k,g){return g===null?comp(s,k,l,h):gates(s,k,g)}
 function children(st){const [s,k,g]=st;if(k===0)return [];let a=[];for(let x=l;x<=Math.min(h,s);x++){if(g!==null&&g>0&&x>g)continue;const ng=g===null||g===0||x===g?null:g-x;const next=[s-x,k-1,ng];let n=count(...next);if(n)a.push([x,next,n])}return a}
 return family([s,k,g],count(s,k,g),children,k)
}
function names(n,k){function children(st){const [a,k]=st;if(!k)return [];return a.map((x,i)=>[x,[a.filter((_,j)=>j!==i),k-1],P(a.length-1,k-1)])}return family([Array.from({length:n},(_,i)=>i+1),k],P(n,k),children,k)}
function family(root,total,children,length){
 function unrank(r){if(typeof r!=="bigint"||r<1n||r>total)throw RangeError("rank");let st=root,out=[];for(let p=0;p<length;p++){let found=false;for(const [x,next,n] of children(st)){if(r>n){r-=n;continue}out.push(x);st=next;found=true;break}check(found,"unrank exhausted")}return out}
 function rank(a){if(!Array.isArray(a)||a.length!==length)throw RangeError("length");let r=1n,st=root;for(const x of a){let found=false;for(const [v,next,n] of children(st)){if(v===x){st=next;found=true;break}r+=n}if(!found)throw RangeError("word")}return r}
 return {total,rank,unrank}
}
function weave(lens){
 const n=lens.length,L=lens.reduce((a,b)=>a+b,0);
 // Refuse before allocation; exact QA scope only, not a production resource claim.
 if(n<1||n>47||lens.some(x=>!Number.isInteger(x)||x<1||x>123)||L>512||lens.reduce((a,b)=>a*BigInt(b+1),1n)>200000n)throw RangeError("weave scope");
 const memo=new Map();
 function nexts(r){let a=[];for(let i=0;i<n;i++){if(!r[i])continue;if(r[i]===lens[i]&&i&&r[i-1]===lens[i-1])continue;if(r[i]===1&&i&&r[i-1]!==0)continue;const t=r.slice();t[i]--;a.push([i+1,t])}return a}
 function count(r){if(r.every(x=>!x))return 1n;let key=r.join(",");if(memo.has(key))return memo.get(key);let sum=0n;for(const [,t] of nexts(r))sum+=count(t);memo.set(key,sum);return sum}
 return family(lens.slice(),count(lens),(r)=>nexts(r).map(([x,t])=>[x,t,count(t)]).filter(x=>x[2]>0n),L)
}
function select(n,r,d,m=M){
 if(typeof n!=="bigint"||typeof r!=="bigint"||typeof m!=="bigint"||m<2n||n<1n||r<1n||r>m||!(d===1||d===-1))throw RangeError("selection");
 let space=m,k=1;while(space<n){space*=m;k++}
 let v=0n,p=1n,q=r-1n;for(let j=0;j<k;j++){v+=q*p;p*=m;q=(q+BigInt(d)+m)%m}v++;
 const lim=space-space%n;if(v>lim)v=d===1?1n:lim;
 return (v-1n)%n+1n
}
// Independent literal enumeration; constraints applied only to completed rows.
function bruteComp(s,k,l,h,g){let out=[];function rec(a,sum){if(a.length===k){if(sum===s&&(g===null||a.some((_,i)=>a.slice(0,i+1).reduce((u,v)=>u+v,0)===g)))out.push(a);return}for(let x=l;x<=h;x++)if(sum+x<=s)rec([...a,x],sum+x)}rec([],0);return out}
function bruteNames(n,k){let out=[];function rec(a){if(a.length===k){if(new Set(a).size===k)out.push(a);return}for(let x=1;x<=n;x++)rec([...a,x])}rec([]);return out}
function bruteWeave(lens){let out=[],r=lens.slice(),a=[];let L=r.reduce((u,v)=>u+v,0);function rec(){if(a.length===L){for(let i=1;i<lens.length;i++)if(a.indexOf(i)>a.indexOf(i+1)||a.lastIndexOf(i)>a.lastIndexOf(i+1))return;out.push(a.slice());return}for(let i=0;i<r.length;i++)if(r[i]){r[i]--;a.push(i+1);rec();a.pop();r[i]++}}rec();return out}
let cases=0,rows=0,invalid=0,selection=0;
function reject(f){let yes=false;try{f()}catch(e){if(e instanceof RangeError)yes=true;else throw e}check(yes,"invalid accepted");invalid++}
function compare(f,arr){check(f.total===BigInt(arr.length),"count");cases++;for(let j=0;j<arr.length;j++){let r=BigInt(j+1);check(JSON.stringify(f.unrank(r))===JSON.stringify(arr[j]),"unrank");check(f.rank(arr[j])===r,"rank");rows++}reject(()=>f.unrank(0n));reject(()=>f.unrank(f.total+1n))}
for(let s=1;s<=10;s++)for(let k=1;k<=4;k++){compare(compositions(s,k,1,3),bruteComp(s,k,1,3,null));for(let g=1;g<=s;g++)compare(compositions(s,k,1,s,g),bruteComp(s,k,1,s,g))}
for(let n=1;n<=5;n++)for(let k=1;k<=n;k++)compare(names(n,k),bruteNames(n,k));
for(let a=1;a<=3;a++)for(let b=1;b<=3;b++)for(let c=1;c<=3;c++)compare(weave([a,b,c]),bruteWeave([a,b,c]));
for(let m=2n;m<=7n;m++)for(let n=1n;n<=m*m*m;n++)for(let r=1n;r<=m;r++)for(let d of [-1,1]){
 let p=m,k=1;while(p<n){p*=m;k++}let q=r,v=1n;for(let j=0;j<k;j++){v+=(q-1n)*m**BigInt(j);q+=BigInt(d);if(q<1n)q=m;if(q>m)q=1n}while(v>p-p%n){v+=BigInt(d);if(v<1n)v=p;if(v>p)v=1n}check(select(n,r,d,m)===(v-1n)%n+1n,"select");selection++
}
const large=[];
function largeCase(label,f){for(let r of [1n,f.total,(f.total+1n)/2n])check(f.rank(f.unrank(r))===r,"large inverse");reject(()=>f.unrank(0n));reject(()=>f.unrank(f.total+1n));large.push([label,String(f.total)])}
largeCase("cutlet names 17P17",names(17,17));largeCase("month names 47P47",names(47,47));
largeCase("month lengths 3000/47",compositions(3000,47,4,123));
largeCase("month lengths 5778/47",compositions(5778,47,4,123));
largeCase("cutlet gaps 137/17 mandatory gate 68",compositions(137,17,1,137,68));
let w=weave([123,123]);check(w.total===C(244,122),"two-thread exact independent binomial");largeCase("weave 123,123",w);
w=weave([123,123,6]);check(w.total>53n*10n**78n,"author lower bound");largeCase("weave 123,123,6",w);
reject(()=>weave(Array(47).fill(123)));reject(()=>names(5,3).rank([1,1,2]));reject(()=>weave([2,2]).rank([2,1,1,2]));reject(()=>compositions(9,3,1,9,4).rank([3,3,3]));
for(let n of [1n,M-1n,M,M+1n,M*M-1n,M*M,M*M+1n,10n**100n])for(let r of [1n,M-1n,M])for(let d of [-1,1]){let v=select(n,r,d);check(v>=1n&&v<=n,"large select bounds");selection++}
return {cases,rows,invalid,selection,large,verdict:"QA_MODEL_ONLY_NOT_NATIVE"};
}
console.log(JSON.stringify(qa(),null,2));
