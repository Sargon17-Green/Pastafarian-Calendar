import { MonsterValidationError } from "./monsterBase.ts";
import type { Patch18Question } from "./patch18YearWalk.ts";

// Post-Stage55 Gate B: native Sauce question materialization from two bigints.
// Constructs inputs only. Native calls and shared-memory writes here are zero;
// the full Patch20 request factory and final date are not yet enabled.
const F = -15055671n;
const M = (1n << 127n) - 1n;
const seedStones = [17n,29n,43n,71n,101n] as const;
const hiddenWeights: readonly (readonly [bigint,bigint,bigint,bigint])[] = [
  [3n,4n,6n,8n], [5n,7n,10n,12n], [7n,10n,14n,16n],
  [9n,13n,18n,20n], [11n,16n,22n,24n],
  [13n,19n,26n,28n], [15n,22n,30n,32n]
];
const hiddenGrindStones = [0,1,2,3,4,0,1] as const;
const visibleGrinds: readonly (readonly [bigint,bigint,bigint,bigint,number])[] = [
  [3n,5n,7n,11n,0], [5n,7n,11n,13n,1],
  [7n,11n,13n,17n,2], [11n,13n,17n,19n,3],
  [13n,17n,19n,23n,4], [17n,19n,23n,29n,0],
  [19n,23n,29n,31n,1], [23n,29n,31n,37n,2],
  [29n,31n,37n,41n,3], [31n,37n,41n,43n,4],
  [37n,41n,43n,47n,0]
];
const bowlPrimes = [17n,19n,23n,29n,31n,37n] as const;

function save(x: bigint): bigint {
  const r = (x-1n)%M;
  return 1n+(r<0n?r+M:r);
}
function count(day: bigint): bigint {
  return day<F?2n*(F-day):2n*(day-F)+1n;
}
function stoneRows(): readonly (readonly bigint[])[] {
  const rows: (readonly bigint[])[] = [Object.freeze([] as bigint[])];
  let prev: readonly bigint[] = seedStones;
  rows.push(Object.freeze([...prev]));
  for(let i=2;i<=46;i++) {
    const [a,b,c,d,e]=prev;
    prev=Object.freeze([
      save(a!*a!+3n*b!+BigInt(i)),
      save(b!*b!+5n*c!+a!),
      save(c!*c!+7n*d!+b!),
      save(d!*d!+11n*e!+c!),
      save(e!*e!+13n*a!+d!)
    ]);
    rows.push(prev);
  }
  return Object.freeze(rows);
}

/** Pure production generator: 46 real drop inputs, 46 stone rows, six bowls.
 * Inputs use exact bigint, no fixtures, caches or test-only imports.
 * Arrays belong exclusively to this invocation and are deeply frozen.
 */
export function createProductionPatch18Question(
  calculationDay: bigint,targetDay: bigint
): Patch18Question {
  if(typeof calculationDay!=="bigint"||typeof targetDay!=="bigint")
    throw new MonsterValidationError("दोन्ही दिवस bigint असणे आवश्यक");
  const action=count(calculationDay),target=count(targetDay);
  const distance=(calculationDay>=targetDay?calculationDay-targetDay:targetDay-calculationDay)+1n;
  const connection=action+target;
  const direction=targetDay<calculationDay?1n:(targetDay===calculationDay?2n:3n);
  const quantities=[action,target,distance,connection,direction] as const;
  const stones=stoneRows();
  const stream=new Map<number,bigint>();

  // Hidden indices -6..0 seed the 1,3,7-lag visible recurrence.
  for(let k=1;k<=7;k++){
    const s=stones[k]!;
    const [a,b,c,d]=hiddenWeights[k-1]!;
    let x=save(action+a*target+b*distance+c*connection+d*direction+
      s.reduce((sum,v)=>sum+v,0n));
    for(let g=1;g<=7;g++){
      const previous=x;
      x=save(previous*previous+3n*previous+
        s[hiddenGrindStones[g-1]!]!+BigInt(g));
    }
    stream.set(1-k,x);
  }

  const visible:bigint[]=[0n];
  for(let i=1;i<=46;i++){
    const preceding=[stream.get(i-1),stream.get(i-3),stream.get(i-7)];
    if(preceding.some(x=>x===undefined))
      throw new Error("Uninitialized native drop predecessor");
    const [p1,p3,p7]=preceding as [bigint,bigint,bigint];
    const s=stones[i]!;
    let value=save(s.reduce((sum,stone,axis)=>
      sum+stone*quantities[axis]!,0n)+p1+3n*p3+5n*p7+BigInt(i));
    for(const [a,b,c,d,stoneIndex] of visibleGrinds){
      const old=value;
      value=save(old*old+a*old+b*p1+c*p3+d*p7+s[stoneIndex]!);
    }
    visible.push(value);
    stream.set(i,value);
  }
  const startBowls:bigint[]=[];
  for(let id=1;id<=6;id++){
    const prime=bowlPrimes[id-1]!;
    const raw=action+target*BigInt(id)+distance+connection+direction+prime*prime;
    startBowls.push(save(raw*raw+BigInt(id)));
  }
  return Object.freeze({
    targetDay,visible:Object.freeze(visible),
    stones,startBowls:Object.freeze(startBowls)
  });
}
