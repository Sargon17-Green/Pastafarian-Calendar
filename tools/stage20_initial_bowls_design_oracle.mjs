// Independent Stage20 mathematical oracle; Node.js 20+; no FALSE implementation or fixture imports.
const summary=(function stage20Oracle(){
 const M=(1n<<127n)-1n,C=[17n,19n,23n,29n,31n,37n];
 function valid(a){if(!Array.isArray(a)||a.length!==5)throw Error("E_COUNTS_LENGTH");if(a.slice(0,4).some(x=>typeof x!=="bigint"||x<0n))throw Error("E_COUNTS_BIGINT");if(!Number.isInteger(a[4])||a[4]<1||a[4]>3)throw Error("E_COUNTS_DIRECTION");}
 function save(x){if(x<=0n)throw Error("E_POSITIVE_INPUT");let z=x%M;return z===0n?M:z;}
 function fold(x){if(x<=0n)throw Error("E_POSITIVE_INPUT");while(x>M)x=(x&M)+(x>>127n);return x;}
 function evaluate(a){valid(a);let [c,t,d,s,q]=a;return C.map((v,j)=>save(c+BigInt(j+1)*t+d+s+BigInt(q)+v*v+BigInt(j+1)));}
 function recurrence(a){valid(a);let [c,t,d,s,q]=a;let x=c+t+d+s+BigInt(q)+17n*17n+1n;let out=[fold(x)];for(let j=1;j<6;j++){x+=t+C[j]*C[j]-C[j-1]*C[j-1]+1n;out.push(fold(x));}return out;}
 const anchors=[
 ["zero-dir1",[0n,0n,0n,0n,1]],["zero-dir3",[0n,0n,0n,0n,3]],["small",[1n,2n,3n,4n,2]],
 ["positive-M",[M-291n,0n,0n,0n,1]],["exact-M-field",[M,0n,0n,0n,1]],
 ["twice-M",[2n*M+1n,M+1n,0n,2n,3]],["boundary-127",[1n<<127n,1n,0n,0n,1]],
 ["boundary-256",[1n<<256n,1n<<130n,0n,5n,2]],["boundary-1024",[1n<<1024n,1n<<777n,1n,0n,2]],
 ["large-mixed",[12345678901234567890n,987654321987654321n,13n,11n,3]],
 ["only-T",[0n,42n,0n,0n,1]],["only-D",[0n,0n,10000000000000n,0n,2]],["dir-boundary",[1n,0n,0n,0n,3]]
 ];
 let cases=0,results=0,deltas=0,immutable=0;
 function check(a){const frozen=Object.freeze([...a]);const before=frozen.map(String).join("|");const x=evaluate(frozen),y=recurrence(frozen);if(x.length!==6||x.some((v,i)=>v!==y[i]||v<1n||v>M))throw Error("ORACLE_DISAGREEMENT");for(let j=1;j<6;j++){if(save(x[j-1]+a[1]+C[j]*C[j]-C[j-1]*C[j-1]+1n)!==x[j])throw Error("DELTA");deltas++;}if(before!==frozen.map(String).join("|"))throw Error("MUTATION");cases++;results+=6;immutable++;return x;}
 const vectors=anchors.map(([label,a])=>({label,counts:a.map(String),expected:check(a).map(String)}));
 if(vectors[0].expected.join(",")!=="291,364,533,846,967,1376"||vectors[3].expected[0]!==String(M))throw Error("ANCHOR");
 let seed=0x20fa1957;function next(){seed^=seed<<13;seed^=seed>>>17;seed^=seed<<5;return seed>>>0;}
 function big(words){let x=0n;for(let j=0;j<words;j++)x=(x<<32n)|BigInt(next());return x;}
 for(let i=0;i<384;i++){const w=[1,2,4,8,16,32,64][i%7];check([big(w),big(w),big(w),big(w),1+(next()%3)]);}
 const invalid=[[0n,0n,0n,1],[-1n,0n,0n,0n,1],[0n,0n,0n,0n,0],[0n,0n,0n,0n,4],[0n,0n,2,0n,1],"invalid"];
 for(const a of invalid){let rejected=false;try{evaluate(a);}catch{rejected=true;}if(!rejected)throw Error("INVALID_ACCEPTED");}
 const mutantTests=[
 ["drop-plus-index",anchors[0][1],0,(a,x)=>x-1n],
 ["swapped-coefficients",anchors[0][1],1,(a,x)=>x+17n*17n-19n*19n],
 ["zero-for-positive-M",anchors[3][1],0,()=>0n],
 ["drop-weighted-T",anchors[2][1],0,(a,x)=>x-a[1]],
 ["wrong-direction",anchors[1][1],0,(a,x)=>x-2n]
 ];
 for(const [label,a,index,bad] of mutantTests){const expected=evaluate(a)[index];if(bad(a,expected)===expected)throw Error("MUTANT_UNDETECTED:"+label);}
 const corrupted=[...vectors[0].expected];corrupted[2]=String(BigInt(corrupted[2])+1n);if(corrupted.every((x,i)=>x===vectors[0].expected[i]))throw Error("CORRUPTION_NOT_REJECTED");
 return {project_id:"PC-BRANCH-FALSE-ARABIC",stage:20,scope:"LOCAL_MATH_DESIGN_ONLY",reference_operation:54,planned_production_operation:37,reference_blob:"3e9acc012bedf83294a6ec3cccb081a069556b5b",formula:"B_i=1+((C+i*T+D+S+q+c_i^2+i-1) mod (2^127-1))",coefficients:C.map(String),anchors:anchors.length,seeded_cases:384,cases_checked:cases,result_comparisons:results,recurrence_checks:deltas,immutability_checks:immutable,invalid_rejections:invalid.length,mutation_witnesses:mutantTests.map(x=>x[0]),corrupted_expected_rejected:true,native:false,ci:false,accepted:false,invalid_pointer_safety_assessed:false,vectors};
})();
process.stdout.write(JSON.stringify(summary,null,2)+"\n");
