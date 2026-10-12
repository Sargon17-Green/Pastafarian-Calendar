import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { patch01Save } from "./patch01Save.ts";
import { patch09Pours } from "./patch09BowlAlias.ts";
import { LegacyInPlaceBowlStirAdapter } from "./discovery10LegacyInPlaceStir.ts";
import type { LegacyStirRead } from "./discovery10LegacyInPlaceStir.ts";

// PATCH 10: प्रत्येक गणिती वाचन फक्त vaultOld मधून; सहा परिणाम pending मध्ये;
// सहाही पूर्ण व वैध झाल्यावरच स्वतंत्र मालकीच्या bowls मध्ये अंतिम commit.
// जुना stirInPlace helper मुद्दाम स्वतंत्र historical shadow साठीच वापरायचा.
export type ShadowStirStep = Readonly<{
  position: number;
  bowlId: number;
  previousId: number;
  nextId: number;
  currentRead: bigint;
  previousRead: bigint;
  nextRead: bigint;
  ingredient: bigint;
  pour: bigint;
  stagedValue: bigint;
}>;

export type ShadowStirPrepared = Readonly<{
  vaultOld: readonly bigint[];
  pending: readonly bigint[];
  steps: readonly ShadowStirStep[];
}>;

export type Patch10StirObservation = Readonly<{
  dropIndex: number;
  dropValue: bigint;
  order: readonly number[];
  pour: readonly bigint[];
  originalBowls: readonly bigint[];
  inputStone: readonly bigint[];
  vaultOld: readonly bigint[];
  pending: readonly bigint[];
  correctedBowls: readonly bigint[];
  correctedSteps: readonly ShadowStirStep[];
  historicalBowls: readonly bigint[];
  historicalSteps: readonly LegacyStirRead[];
  historicalReadContaminations: number;
  oldMethodCalls: 1;
  stagedWrites: 6;
  committedWrites: 6;
  context: MonsterContext;
}>;

export class Patch10ShadowBowlAdapter {
  private validate(b: readonly bigint[], order: readonly number[],
      stone: readonly bigint[], pour: readonly bigint[], i: number, d: bigint): void {
    if(!Number.isInteger(i)||i<1||i>46||typeof d!=="bigint"||
       !Array.isArray(b)||b.length!==6||
       Array.from({length:6},(_,k)=>typeof b[k]!=="bigint").some(Boolean)||
       !Array.isArray(stone)||stone.length!==5||
       Array.from({length:5},(_,k)=>typeof stone[k]!=="bigint").some(Boolean)||
       !Array.isArray(order)||order.length!==6||
       order.some(id=>!Number.isInteger(id)||id<1||id>6)||
       new Set(order).size!==6||!Array.isArray(pour)||pour.length!==6||
       Array.from({length:6},(_,k)=>typeof pour[k]!=="bigint").some(Boolean)){
      throw new MonsterValidationError("सहा bowls, सहा distinct order IDs, सहा pours, पाच stones व bigint आवश्यक");
    }
  }

  stage(
    c: bigint,t: bigint,i: number,d: bigint,b: readonly bigint[],
    stone: readonly bigint[],order: readonly number[],pour: readonly bigint[],
    afterPendingWrite?: (position:number)=>void
  ): ShadowStirPrepared {
    if(typeof c!=="bigint"||typeof t!=="bigint"){
      throw new MonsterValidationError("दोन्ही दिवस bigint हवेत");
    }
    this.validate(b,order,stone,pour,i,d);
    const vaultOld=Object.freeze([...b]);
    const pending=[...b];
    const steps:ShadowStirStep[]=[];
    const stoneKind=[0,1,2,3,4,0] as const;
    for(let position=1;position<=6;position++){
      const bowlId=order[position-1]!;
      const previousId=order[(position+4)%6]!;
      const nextId=order[position%6]!;
      // ही तीन वाचने (आणि currentRead) संपूर्ण stir मध्ये vaultOld वरूनच.
      const currentRead:bigint=vaultOld[bowlId-1]!;
      const previousRead:bigint=vaultOld[previousId-1]!;
      const nextRead:bigint=vaultOld[nextId-1]!;
      const ingredient:bigint=stone[stoneKind[position-1]!]!;
      const portion:bigint=pour[position-1]!;
      const mix:bigint=currentRead+2n*previousRead+3n*nextRead+
        portion+d+ingredient;
      const stagedValue=patch01Save(c,t,
        mix*mix+5n*previousRead*nextRead+BigInt(i*position)).savedValue;
      pending[bowlId-1]=stagedValue; // writes केवळ private pending मध्ये
      steps.push(Object.freeze({position,bowlId,previousId,nextId,
        currentRead,previousRead,nextRead,ingredient,pour:portion,stagedValue}));
      afterPendingWrite?.(position); // explicit failure-injection seam, commit अजून नाही
    }
    return Object.freeze({vaultOld,pending:Object.freeze(pending),
      steps:Object.freeze(steps)});
  }

  // पूर्ण stage यशस्वी झाल्याशिवाय हा स्वतंत्र अंतिम सहा-write commit होत नाही.
  // destination हा केवळ handler-owned clone असावा; caller input नाही.
  commit(destination:bigint[],prepared:ShadowStirPrepared):readonly bigint[]{
    if(!Array.isArray(destination)||destination.length!==6||
       Array.from({length:6},(_,k)=>typeof destination[k]!=="bigint").some(Boolean)||
       !Array.isArray(prepared.pending)||prepared.pending.length!==6||
       Array.from({length:6},(_,k)=>typeof prepared.pending[k]!=="bigint").some(Boolean)||
       !Array.isArray(prepared.vaultOld)||prepared.vaultOld.length!==6||
       !prepared.vaultOld.every((v,k)=>v===destination[k])){
      throw new MonsterValidationError("commit साठी अखंड सहा-वाट्यांचा मूळ snapshot आवश्यक");
    }
    // या बिंदूपूर्वी सर्व सहा calculations यशस्वीपणे पूर्ण झालेले आहेत.
    for(let bowlId=1;bowlId<=6;bowlId++){
      destination[bowlId-1]=prepared.pending[bowlId-1]!;
    }
    return Object.freeze([...destination]);
  }
}

export class Patch10SnapshotStirHandler {
  private readonly shadow=new Patch10ShadowBowlAdapter();
  private readonly historical=new LegacyInPlaceBowlStirAdapter();
  private readonly metrics=new BaseMetricsManager();
  private readonly afterPendingWrite?: (position:number)=>void;
  constructor(afterPendingWrite?: (position:number)=>void){
    this.afterPendingWrite=afterPendingWrite;
  }

  run(ctx:MonsterContext,i:number,d:bigint,b:readonly bigint[],
      stone:readonly bigint[]):Patch10StirObservation{
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED"){
      throw new MonsterStageError("shadow stir पूर्वी तयार context आवश्यक");
    }
    if(typeof ctx.calculationDay!=="bigint"||typeof ctx.targetDay!=="bigint"||
       !Number.isInteger(i)||i<1||i>46||typeof d!=="bigint"||
       !Array.isArray(b)||b.length!==6||
       Array.from({length:6},(_,k)=>typeof b[k]!=="bigint").some(Boolean)||
       !Array.isArray(stone)||stone.length!==5||
       Array.from({length:5},(_,k)=>typeof stone[k]!=="bigint").some(Boolean)){
      throw new MonsterValidationError("valid index, bigint drop, सहा bowls व पाच stones आवश्यक");
    }
    const pourResult=patch09Pours(ctx.calculationDay,ctx.targetDay,i,d,b,stone);
    const order=pourResult.order;
    const pour=Object.freeze([...pourResult.correctedPours,0n,0n,0n]);
    const originalBowls=Object.freeze([...b]);
    const inputStone=Object.freeze([...stone]);
    // Shadow observation ही जुन्याच दोषपूर्ण actual helper ची स्वतंत्र invocation.
    const historicalWorking=[...b];
    const historicalSteps=this.historical.stirInPlace(
      ctx.calculationDay,ctx.targetDay,i,d,stone,order,pour,historicalWorking);
    const historicalBowls=Object.freeze([...historicalWorking]);
    const historicalReadContaminations=historicalSteps.reduce(
      (n,step)=>n+Number(step.previousAlreadyWritten)+Number(step.nextAlreadyWritten),0);

    // फक्त stage() मध्ये vaultOld व pending; old helper इथे कधीच नाही.
    const prepared=this.shadow.stage(ctx.calculationDay,ctx.targetDay,i,d,
      b,stone,order,pour,this.afterPendingWrite);
    const committedWorking=[...b];
    const correctedBowls=this.shadow.commit(committedWorking,prepared);
    // बाहेरून निरीक्षणयोग्य context लिहिणे हे सर्व गणना-commit नंतर.
    ctx.branchTrace.push("PATCH_10_VAULT_OLD_CLONE");
    ctx.branchTrace.push("PATCH_10_PENDING_CLONE");
    ctx.branchTrace.push("PATCH_10_ALL_READS_FROM_VAULT_OLD");
    ctx.branchTrace.push("PATCH_10_SIX_PENDING_WRITES");
    ctx.branchTrace.push("PATCH_10_FINAL_SIX_BOWL_COMMIT");
    this.metrics.bump(ctx,"patch10.calls");
    this.metrics.bump(ctx,"patch10.real_legacy_shadow_calls");
    this.metrics.bump(ctx,"patch10.vaultOld_clones");
    this.metrics.bump(ctx,"patch10.pending_clones");
    for(let k=0;k<6;k++){
      this.metrics.bump(ctx,"patch10.vaultOld_step_reads");
      this.metrics.bump(ctx,"patch10.pending_writes");
      this.metrics.bump(ctx,"patch10.final_commit_writes");
    }
    for(let k=0;k<historicalReadContaminations;k++){
      this.metrics.bump(ctx,"patch10.historical_overwritten_reads");
    }
    ctx.status="PATCH_10_APPLIED";
    return Object.freeze({
      dropIndex:i,dropValue:d,order,pour,originalBowls,inputStone,
      vaultOld:prepared.vaultOld,pending:prepared.pending,correctedBowls,
      correctedSteps:prepared.steps,historicalBowls,historicalSteps,
      historicalReadContaminations,oldMethodCalls:1 as const,
      stagedWrites:6 as const,committedWrites:6 as const,context:ctx
    });
  }
}

export function patch10Stir(c:bigint,t:bigint,i:number,d:bigint,
 b:readonly bigint[],stone:readonly bigint[]):Patch10StirObservation{
  return new Patch10SnapshotStirHandler().run(
    bootstrapMonster(c,t),i,d,b,stone);
}
