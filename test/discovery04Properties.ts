import {
  discoverLegacyStoneMutation, LegacySequentialStoneAdapter, MonsterValidationError
} from "../src/index.ts";
import { FOUNDATION_DAY as F, M, SAVE } from "./normativeOracle.ts";

function check(ok:boolean, reason:string):void { if(!ok)throw new Error(reason); }
const adapter = new LegacySequentialStoneAdapter();
const base = [17n,29n,43n,71n,101n] as const;

// स्थानिक, test-only प्रतिपादन: प्रत्यक्ष जुनी in-place अवलंबित्वे स्पष्ट करा.
function sequentialFormula(i:bigint, data:readonly bigint[]):readonly bigint[]{
  const x=[...data];
  x[0]=SAVE(x[0]!*x[0]!+3n*x[1]!+i);
  x[1]=SAVE(x[1]!*x[1]!+5n*x[2]!+x[0]!);
  x[2]=SAVE(x[2]!*x[2]!+7n*x[3]!+x[1]!);
  x[3]=SAVE(x[3]!*x[3]!+11n*x[4]!+x[2]!);
  x[4]=SAVE(x[4]!*x[4]!+13n*x[0]!+x[3]!);
  return x;
}
let cases=0, values=0;
function verify(index:bigint,input:readonly bigint[]):void{
  const pristine=[...input];
  const exact=sequentialFormula(index,input);
  const actual=discoverLegacyStoneMutation(F-13n,F+29n,index,input);
  for(let k=0;k<5;k++){
    check(actual.legacyStone[k]===exact[k], "जुन्या sequential सूत्राशी तुलना अयशस्वी");
    check(actual.legacyStone[k]!>=1n && actual.legacyStone[k]!<=M, "SAVE बाहेरचा अंक");
    check(input[k]===pristine[k] && actual.inputStone[k]===pristine[k], "मूळ input बदलला");
    values++;
  }
  cases++;
}
verify(2n,base);
verify(46n,base);
const huge=(1n<<8192n)+191n;
verify(2n,[huge,-huge,0n,M,-M]);
verify(46n,[-huge,huge,M+1n,-(M+1n),1n]);

let seed=0x9e3779b97f4a7c15n;
const mask=(1n<<512n)-1n;
for(let j=0;j<512;j++){
  const input:bigint[]=[];
  for(let k=0;k<5;k++){
    seed=(seed*6364136223846793005n+1442695040888963407n)&mask;
    input.push(seed-(1n<<511n));
  }
  verify(BigInt(2+(j%45)),input);
}

// स्वतंत्र संदर्भ आणि छुप्या स्थितीची गळती नाही.
const left=discoverLegacyStoneMutation(F,F,2n,base);
const right=discoverLegacyStoneMutation(F,F,2n,base);
left.context.logs.push("स्वतंत्र नोंद");
left.context.warnings.push("स्थानिक इशारा");
left.context.metrics.set("private",99n);
check(right.context.logs.length===0 && right.context.warnings.length===0 &&
  !right.context.metrics.has("private"),"संदर्भांचे स्वामित्व चुकले");
check(left.legacyStone.every((v,k)=>v===right.legacyStone[k]), "आवाहन-क्रमावर उत्तर अवलंबू नये");

// पहिल्या चुकीच्या इनपुटवर mutation सुरूच होऊ नये.
const malformed=[17n,29n,43n,71n,101n] as [bigint,bigint,bigint,bigint,bigint];
const snapshot=[...malformed];
let failed=false;
try{
  adapter.mutateStonesWrong(1n,malformed,F,F);
}catch(e){failed=e instanceof MonsterValidationError}
check(failed && malformed.every((v,k)=>v===snapshot[k]), "अवैध निर्देशांकाचे rollback");
failed=false;
try{
  adapter.mutateStonesWrong(2n,malformed,F,2 as unknown as bigint);
}catch(e){failed=e instanceof MonsterValidationError}
check(failed && malformed.every((v,k)=>v===snapshot[k]), "अवैध दिवसाचे rollback");
console.log(`STAGE_08_DISCOVERY_04_PROPERTIES_PASS cases=${cases} values=${values}`);
