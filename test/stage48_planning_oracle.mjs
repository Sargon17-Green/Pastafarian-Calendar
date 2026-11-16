#!/usr/bin/env node
// Stage48 DISCOVERY44 planning oracle: independent arithmetic plus Map-based
// ownership model. It does not execute COBOL or certify Native gates.
import { strict as assert } from 'node:assert';
function permutationsOfFour() {
  const items=[1,2,3,4], out=[];
  function heap(k) {
    if(k===1) {out.push([...items]);return;}
    heap(k-1);
    for(let i=0;i<k-1;i++){
      const p=k%2===0?i:0;
      [items[p],items[k-1]]=[items[k-1],items[p]];
      heap(k-1);
    }
  }
  heap(4);
  out.sort((a,b)=>a.join('').localeCompare(b.join('')));
  assert.equal(new Set(out.map(x=>x.join(''))).size,24);
  return out;
}
const permutations=permutationsOfFour();
const widths=[3,9,320,8192];
let arithmetic=0,probes=0,transitions=0,large=0;
const targets=[0,0,0,0],pairs=new Set();
for(const width of widths)for(let j=1;j<=6;j++){
  const ten=10n**BigInt(width-1);
  const x=ten+BigInt(5*j+2),y=ten-BigInt(2*j+5);
  const c=j%2?x:y,t=j%2?y:x;
  const pairId=String(c)+'|'+String(t);
  assert.ok(!pairs.has(pairId));pairs.add(pairId);
  const outputs=Array.from({length:4},(_,k)=>c+BigInt((j%2?1:-1)*k));
  for(let k=0;k<4;k++){
    const difference=t-outputs[k];
    const distancePlusOne=(difference<0n?-difference:difference)+1n;
    assert.equal(distancePlusOne,BigInt(7*j+8+k));
    arithmetic++;
  }
  if(width===8192)large++;
  const rank=widths.indexOf(width)*6+j-1;
  const order=permutations[rank];
  const live=new Map(outputs.map((value,k)=>[k+1,{value}]));
  for(const traversal of [order,[...order].reverse()]){
    for(const freedSlot of traversal){
      assert.equal(live.size,4);
      for(let target=1;target<=4;target++){
        const before=new Map(live);
        const status=live.has(target)?175:0;
        assert.equal(status,175);
        for(const [key,reference] of before){
          assert.equal(live.get(key),reference);
          assert.equal(live.get(key).value,outputs[key-1]);
        }
        assert.equal(c,j%2?x:y);
        assert.equal(t,j%2?y:x);
        probes++;targets[target-1]++;
      }
      const released=live.get(freedSlot);
      assert.ok(live.delete(freedSlot));
      assert.equal(live.size,3);
      assert.ok(!live.has(freedSlot));
      live.set(freedSlot,{value:outputs[freedSlot-1]});
      assert.notEqual(live.get(freedSlot),released);
      assert.equal(live.size,4);
      assert.equal(new Set(live.values()).size,4);
      transitions++;
    }
  }
}
assert.equal(arithmetic,96);
assert.equal(pairs.size,24);
assert.equal(large,6);
assert.equal(probes,768);
assert.equal(transitions,192);
assert.deepEqual(targets,[192,192,192,192]);
console.log('STAGE48_PLANNING_ORACLE=96/96');
console.log('STAGE48_PLANNING_OCCUPIED_MATRIX=768/768');
console.log('STAGE48_PLANNING_ROLLING_MODEL=192/192');
console.log('STAGE48_PLANNING_TARGET_BALANCE=192,192,192,192');
console.log('STAGE48_PLANNING_PERMUTATIONS=24/24');
console.log('STAGE48_PLANNING_UNIQUE_PAIRS=24');
console.log('STAGE48_PLANNING_8192_DIGIT_CASES=6');
console.log('STAGE48_PLANNING_GATE=PASS_NOT_NATIVE');
