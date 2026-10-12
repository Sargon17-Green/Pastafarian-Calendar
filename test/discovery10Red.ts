import { discoverLegacyInPlaceStir } from "../src/index.ts";
import { FOUNDATION_DAY as F } from "./normativeOracle.ts";
import { normativeSingleStir } from "./discovery10Reference.ts";
const b=[101n,211n,307n,401n,503n,601n];
const stone=[2n,3n,5n,7n,11n];
const drops=[-1n,0n,1n,2n,120n,121n,719n,720n] as const;
let mismatches=0,matches=0;
for(const drop of drops){
  const old=discoverLegacyInPlaceStir(F,F,7,drop,b,stone);
  const canonical=normativeSingleStir(7,drop,b,stone);
  for(let p=0;p<6;p++){
    const id=old.order[p]!;
    const got=old.legacyBowls[id-1]!,want=canonical.expectedBowls[id-1]!;
    console.log(`DISCOVERY_10_WITNESS drop=${drop} position=${p+1} bowl=${id} inPlace=${got} snapshotReference=${want} previouslyWrittenNeighbor=${old.steps[p]!.previousAlreadyWritten||old.steps[p]!.nextAlreadyWritten}`);
    if(got===want)matches++;else mismatches++;
  }
}
if(mismatches===40&&matches===8)
  throw new Error("DISCOVERY_10_EXPECTED_RED mismatches=40 matches=8 witnesses=8 positions=48");
throw new Error(`DISCOVERY_10_INVALID_RED mismatches=${mismatches} matches=${matches}`);
