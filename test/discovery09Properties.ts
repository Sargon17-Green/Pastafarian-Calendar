import { discoverLegacyFixedPours,patch08Permutation } from "../src/index.ts";
import { FOUNDATION_DAY as F,M,workCounts,STONES,buildHiddenDrops,
  buildVisibleDrops,initialBowls,bowlOrderFromDrop } from "./normativeOracle.ts";
import { normativeThreePours } from "./discovery09Reference.ts";
function check(ok:boolean,msg:string){if(!ok)throw Error(msg)}
const bowls=[101n,211n,307n,401n,503n,601n],stone=[2n,3n,5n,7n,11n];
let rankOrders=0,rankCells=0,rankMatches=0,rankMismatches=0;
const contexts=new Set<object>();
for(let drop=1n;drop<=720n;drop++){
  const o=discoverLegacyFixedPours(F,F,7,drop,bowls,stone);
  const ref=normativeThreePours(7,drop,bowls,stone);
  check(o.order.join(",")===bowlOrderFromDrop(drop).join(",")&&
    !contexts.has(o.context),"720 ordered permutations and unique contexts");
  contexts.add(o.context);
  for(let p=0;p<3;p++){
    rankCells++;
    if(o.legacyPours[p]===ref[p])rankMatches++;else rankMismatches++;
    check((o.legacyPours[p]===ref[p])===(o.order[p]===p+1),
      "exact source of accidental match");
  }
  rankOrders++;
}
check(rankOrders===720&&rankCells===2160&&rankMatches===360&&
  rankMismatches===1800,"full 6! grid: 1800 wrong, 360 coincident");

const pairs:readonly (readonly [bigint,bigint])[]=[
 [F,F],[F-1n,F],[F+1n,F],[F,F-1n],[F,F+1n],
 [F-89n,F+273n],[F+273n,F-89n],[-278522n,-278522n],
 [-278522n,-268522n],[1n,1n],[100000n,-100000n],[-100000n,100000n]
];
let realPairs=0,realDrops=0,realCells=0,realMismatches=0,realMatches=0;
for(const [c,t] of pairs){
  const counts=workCounts(c,t),hidden=buildHiddenDrops(counts,STONES);
  const drops=buildVisibleDrops(counts,STONES,hidden),b=initialBowls(counts);
  for(let i=1;i<=46;i++){
    const drop=drops[i]!;
    const o=discoverLegacyFixedPours(c,t,i,drop,b,STONES[i]!);
    const ref=normativeThreePours(i,drop,b,STONES[i]!);
    check(drop>=1n&&drop<=M&&
      o.order.join(",")===patch08Permutation(c,t,drop).order.join(","),
      "normative drop and corrected order, fixed legacy bowls");
    for(let p=0;p<3;p++){
      realCells++;
      if(o.legacyPours[p]!==ref[p])realMismatches++;else realMatches++;
    }
    realDrops++;
  }
  realPairs++;
}
check(realPairs===12&&realDrops===552&&realCells===1656&&
  realMismatches>0&&realMatches>0&&
  realMismatches+realMatches===realCells,"552 actual drops");
const huge=(1n<<8192n)+193n;
const values=[huge,-huge,huge*huge,-huge*huge,0n,720n,1n<<16384n,-(1n<<16384n)];
let giantCases=0,giantCells=0;
for(const drop of values){
  const b=[huge+17n,huge+31n,huge+43n,huge+59n,huge+71n,huge+83n];
  const st=[huge,-huge,3n*huge,5n*huge,-5n*huge];
  const o=discoverLegacyFixedPours(F-huge,F+huge,46,drop,b,st);
  const ref=normativeThreePours(46,drop,b,st);
  for(let p=0;p<3;p++){
    check((o.legacyPours[p]===ref[p])===(o.order[p]===p+1),
      "giant bigint fixed IDs remain wrong");
    giantCells++;
  }
  giantCases++;
}
check(giantCases===8&&giantCells===24,"huge signed inputs");
console.log(`STAGE_18_DISCOVERY_09_PROPERTIES_PASS rankOrders=${rankOrders} rankCells=${rankCells} rankMatches=${rankMatches} rankMismatches=${rankMismatches} realPairs=${realPairs} realDrops=${realDrops} realCells=${realCells} realMismatches=${realMismatches} realMatches=${realMatches} giantCases=${giantCases} giantCells=${giantCells}`);
