#!/usr/bin/env node
// Stage42 independent source-text decimal arithmetic and permutation oracle.
import { readFileSync } from "node:fs";
import { strict as assert } from "node:assert";
const source=readFileSync(new URL("./stage43_discovery_tests.cob",import.meta.url),"utf8");
const suffixes=[...source.matchAll(/WHEN ([1-6])\s+MOVE "(\d{2})" TO WS-BASE-X\(WS-X-POS:2\)\s+MOVE "(\d{2})" TO WS-BASE-Y\(WS-Y-POS:2\)/g)];
assert.equal(suffixes.length,6);
const orders=[...source.matchAll(/WHEN (\d+)\s+MOVE ([1-4]) TO WS-ORDER\(1\)\s+MOVE ([1-4]) TO WS-ORDER\(2\)\s+MOVE ([1-4]) TO WS-ORDER\(3\)\s+MOVE ([1-4]) TO WS-ORDER\(4\)/g)];
assert.equal(orders.length,24);
function permute(xs,p=[]) {return xs.length?xs.flatMap((x,i)=>permute(xs.filter((_,j)=>i!==j),[...p,x])):[p.join("")];}
const all=new Set(permute([1,2,3,4])), found=new Set();
orders.forEach((m,i)=>{assert.equal(Number(m[1]),i+1);const x=m.slice(2,6).join("");assert.ok(all.has(x)&&!found.has(x));found.add(x);});
assert.equal(found.size,24);
assert.equal((source.match(/PERFORM PROBE-OCCUPIED/g)||[]).length,2);
assert.ok(source.includes("IF WS-STATUS = 175"));
assert.ok(source.includes("AND WS-REJECTS = 48 AND WS-PRESERVED = 48"));
for(const needle of ["PERFORM PREPARE-ORDER","PERFORM CHECK-SURVIVORS","PERFORM VARYING WS-STEP FROM 4 BY -1","STAGE43_MID_HEAP_ZERO=","STAGE43_HEAP_LIVE_POST_RELEASE=","STAGE43_OCCUPIED_REJECTS=","STAGE43_REJECTED_PRESERVED="])assert.ok(source.includes(needle));
let passed=0,large=0;const unique=new Set();
for(const n of [3,9,320,8192])for(const m of suffixes){
 const j=Number(m[1]),a="1"+"0".repeat(n-3)+m[2],b="9".repeat(n-3)+m[3],k=10n**BigInt(n-1);
 assert.equal(BigInt(a),k+BigInt(5*j+2));
 assert.equal(BigInt(b),k-BigInt(2*j+5));
 const c=j%2?a:b,t=j%2?b:a;
 assert.ok(!unique.has(c+"|"+t));unique.add(c+"|"+t);
 for(let slot=1;slot<=4;slot++){
   const ending=Number(c.slice(-2))+(j%2?1:-1)*(slot-1);
   assert.ok(ending>=0&&ending<100);
   const encoded=c.slice(0,-2)+String(ending).padStart(2,"0");
   assert.equal(encoded.length,c.length);
   const delta=BigInt(t)-BigInt(encoded), actual=(delta<0n?-delta:delta)+1n;
   assert.equal(actual,BigInt(7*j+8+slot-1));
   passed++;
 }
 if(n===8192)large++;
}
assert.equal(passed,96);assert.equal(unique.size,24);assert.equal(large,6);
console.log("STAGE43_ORACLE_PASS=96/96");
console.log("STAGE43_PERMUTATIONS_STATIC=24/24");
console.log("STAGE43_UNIQUE_BASE_PAIRS=24");
console.log("STAGE43_8192_DIGIT_CASES=6");
