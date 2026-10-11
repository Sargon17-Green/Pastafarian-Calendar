import {
  discoverLegacyStoneMutation, patch04Stones, LegacySequentialStoneAdapter
} from "../src/index.ts";
import { FOUNDATION_DAY as F, M, SAVE, STONES } from "./normativeOracle.ts";

function check(ok:boolean, label:string):void {if(!ok)throw Error(label);}
const historical = new LegacySequentialStoneAdapter();
let comparisons=0, invariantCells=0, liveLegacyDifferences=0;

function test(index:bigint, input:readonly bigint[], shift:readonly bigint[]):void {
  const altered=input.map((x,k)=>x+M*shift[k]!);
  const a=patch04Stones(F,F+1n,index,input);
  const b=patch04Stones(F-127n,F+127n,index,altered);
  const mutationCopy=[...input] as [bigint,bigint,bigint,bigint,bigint];
  historical.mutateStonesWrong(index,mutationCopy,F,F);
  const oldWitness=discoverLegacyStoneMutation(F,F,index,input);
  check(a.correctedStone.length===5 && a.legacyGarbage.length===5, "पाच दगडांचा आकार");
  for(let k=0;k<5;k++){
    check(a.correctedStone[k]===b.correctedStone[k],
      "M-गुणक स्थानांतराने नियमाधारित परिणाम बदलू नये");
    check(a.legacyGarbage[k]===b.legacyGarbage[k],
      "M-गुणक स्थानांतराने ऐतिहासिक अवशेष बदलू नये");
    check(a.legacyGarbage[k]===mutationCopy[k] &&
      oldWitness.legacyStone[k]===mutationCopy[k], "जुनी प्रत्यक्ष क्रिया व clone garbage जुळावे");
    if(a.correctedStone[k]!==a.legacyGarbage[k])liveLegacyDifferences++;
    invariantCells++;
  }
  comparisons++;
}

// शून्य, ऋण गुणक, दोन टोकाची बीजे आणि पूर्ण 45 दगडांमध्ये गुणक-स्थानांतर.
for(let i=2;i<=46;i++){
  const old=STONES[i-1]!;
  test(BigInt(i),old,[1n,-1n,0n,2n,-2n]);
}
let seed=0x243f6a8885a308d3n;
const mask=(1n<<512n)-1n;
for(let t=0;t<256;t++){
  const vector:bigint[]=[];
  const multiples:bigint[]=[];
  for(let k=0;k<5;k++){
    seed=(seed*0x5851f42d4c957f2dn+0x14057b7ef767814fn)&mask;
    vector.push(seed-(1n<<511n));
    multiples.push(BigInt((t+3*k)%11-5));
  }
  test(BigInt(2+t%45),vector,multiples);
}
check(comparisons===301 && invariantCells===1505 && liveLegacyDifferences>0,
  "अपेक्षित तुलना / प्रत्यक्ष जुना दोष");
console.log(`STAGE_09_PATCH_04_METAMORPHIC_PASS comparisons=${comparisons} cells=${invariantCells} historicalDifferences=${liveLegacyDifferences}`);
