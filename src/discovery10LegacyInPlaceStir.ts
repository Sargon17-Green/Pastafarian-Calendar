import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { patch09Pours } from "./patch09BowlAlias.ts";
import { patch01Save } from "./patch01Save.ts";

// DISCOVERY 10: प्रत्येक position संपताना जुनाच B[id] थेट बदलला जातो.
// पुढच्या positions च्या prev/next reads मध्ये नुकतीच लिहिलेली वाटी येते.
// stage21 मधील vaultOld/pending/simultaneous-write तंत्र येथे मुद्दाम नाही.
export type LegacyStirRead = Readonly<{
  position:number;
  bowlId:number;
  previousId:number;
  nextId:number;
  previousRead:bigint;
  nextRead:bigint;
  previousAlreadyWritten:boolean;
  nextAlreadyWritten:boolean;
  newlyWrittenValue:bigint;
}>;
export type Discovery10StirObservation = Readonly<{
  dropIndex:number;
  dropValue:bigint;
  order:readonly number[];
  pour:readonly bigint[];
  inputBowls:readonly bigint[];
  inputStone:readonly bigint[];
  legacyBowls:readonly bigint[];
  steps:readonly LegacyStirRead[];
  overwrittenReadSlots:number;
  contaminatedPositions:number;
  context:MonsterContext;
}>;

export class LegacyInPlaceBowlStirAdapter {
  // हा जुना helper caller-owned working array मध्ये ताबडतोब write करतो.
  // एकाच ग्राइंडमध्ये प्रत्येक calculation आधीच्या mutated value ला वाचतो.
  stirInPlace(
    c:bigint,t:bigint,i:number,d:bigint,stone:readonly bigint[],
    order:readonly number[],pour:readonly bigint[],workingBowls:bigint[]
  ):readonly LegacyStirRead[] {
    const types=[0,1,2,3,4,0] as const;
    const written=new Set<number>();
    const reads:LegacyStirRead[]=[];
    for(let position=1;position<=6;position++){
      const bowlId=order[position-1]!;
      const previousId=order[(position+4)%6]!;
      const nextId=order[position%6]!;
      const previousRead=workingBowls[previousId-1]!;
      const nextRead=workingBowls[nextId-1]!;
      const previousAlreadyWritten=written.has(previousId);
      const nextAlreadyWritten=written.has(nextId);
      const mix=workingBowls[bowlId-1]! + 2n*previousRead +
        3n*nextRead + pour[position-1]! + d + stone[types[position-1]!]!;
      const newlyWrittenValue=patch01Save(c,t,
        mix*mix + 5n*previousRead*nextRead + BigInt(i*position)).savedValue;
      workingBowls[bowlId-1]=newlyWrittenValue; // ऐतिहासिक defect
      written.add(bowlId);
      reads.push(Object.freeze({position,bowlId,previousId,nextId,
        previousRead,nextRead,previousAlreadyWritten,nextAlreadyWritten,
        newlyWrittenValue}));
    }
    return Object.freeze(reads);
  }
}

export class Discovery10InPlaceStirHandler {
  private readonly old=new LegacyInPlaceBowlStirAdapter();
  private readonly metrics=new BaseMetricsManager();
  run(ctx:MonsterContext,i:number,d:bigint,b:readonly bigint[],stone:readonly bigint[]):Discovery10StirObservation {
    if(ctx.phase!=="READY" || ctx.status!=="VALIDATED"){
      throw new MonsterStageError("वाटी stir शोधापूर्वी तयार context आवश्यक");
    }
    if(typeof ctx.calculationDay!=="bigint"||typeof ctx.targetDay!=="bigint"||
       !Number.isInteger(i)||i<1||i>46||typeof d!=="bigint"||
       !Array.isArray(b)||b.length!==6||
       Array.from({length:6},(_,k)=>typeof b[k]!=="bigint").some(Boolean)||
       !Array.isArray(stone)||stone.length!==5||
       Array.from({length:5},(_,k)=>typeof stone[k]!=="bigint").some(Boolean)){
      throw new MonsterValidationError("वैध index, bigint थेंब, सहा bowls व पाच stones आवश्यक");
    }

    // Stage19 alias-पट्टीने तीन pours बरोबर; stir मधील defect स्वतंत्र.
    const correctedPour=patch09Pours(ctx.calculationDay,ctx.targetDay,i,d,b,stone);
    const order=correctedPour.order;
    const pour=Object.freeze([...correctedPour.correctedPours,0n,0n,0n]);
    const inputBowls=Object.freeze([...b]); // फक्त caller ownership व पुरावा
    const inputStone=Object.freeze([...stone]);
    const ownedWorkingBowls=[...b]; // caller इनपुट बदलू नये; old helper इथे mutate करतो
    const steps=this.old.stirInPlace(ctx.calculationDay,ctx.targetDay,
      i,d,stone,order,pour,ownedWorkingBowls);
    const legacyBowls=Object.freeze(ownedWorkingBowls);
    let overwrittenReadSlots=0,contaminatedPositions=0;
    for(const step of steps){
      const overwritten=Number(step.previousAlreadyWritten)+Number(step.nextAlreadyWritten);
      overwrittenReadSlots+=overwritten;
      if(overwritten)contaminatedPositions++;
    }
    ctx.branchTrace.push("DISCOVERY_10_PATCH09_POURS_CORRECT");
    ctx.branchTrace.push("DISCOVERY_10_OLD_IN_PLACE_STIR");
    ctx.branchTrace.push("DISCOVERY_10_LATER_READS_OBSERVE_WRITES");
    this.metrics.bump(ctx,"discovery10.calls");
    for(let k=0;k<6;k++)this.metrics.bump(ctx,"discovery10.immediate_writes");
    for(let k=0;k<overwrittenReadSlots;k++)this.metrics.bump(ctx,"discovery10.overwritten_read_slots");
    for(let k=0;k<contaminatedPositions;k++)this.metrics.bump(ctx,"discovery10.contaminated_positions");
    ctx.status="DISCOVERY_10_RECORDED";
    return Object.freeze({dropIndex:i,dropValue:d,order,pour,inputBowls,
      inputStone,legacyBowls,steps,overwrittenReadSlots,contaminatedPositions,context:ctx});
  }
}

export function discoverLegacyInPlaceStir(c:bigint,t:bigint,i:number,d:bigint,
 b:readonly bigint[],stone:readonly bigint[]):Discovery10StirObservation {
  return new Discovery10InPlaceStirHandler().run(
    bootstrapMonster(c,t),i,d,b,stone);
}
