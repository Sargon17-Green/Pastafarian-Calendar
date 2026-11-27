/*
PC-BRANCH-OBJECT-PASCAL-PORTUGUESE | 2026-11-27
Stage08 DISCOVERY04_STONE_SNAPSHOT — independent preflight, NOT ACCEPTED.
Parent e4dd99249b5ba747fbf790f32b0d0d934b805bef; frozen plan 0c2bad7393f4d66b77f884520f8ab6f5025feedd row 9.
Normative source README at 56bc4173aae4975ded019ef5ab5a36249f1424df sections D,E,G.
Contract: no date input; immutable previous row of five BigInts, i=2..46;
output exact decimal TSV i,wheat,barley,salt,bitter,red; seed row i=1.
All five values in 1..2^127-1; all read the same preceding snapshot.
Only the first coordinate adds i; remaining coordinates add previous neighbour.
Native future probe must compare all 230 cells and prove actual live legacy call,
retain matched controls, require real discrepancy and exact checkout/exit/log/TSV.
This script only verifies independent expected-value arithmetic, not Pascal execution.
No mutant seeded. No claim of expected RED. No production or workflow change.

Lineage audit:
Current src listing contains BigInt, MonsterBootstrap, PastafariCalendar,
SourceLanguageCatalog, Stage02WorkCounts only. All inspected; no stone path.
PastafariCalendar exports BootstrapProbe and WorkCountsForContext only.
test/NormativeOracle.pas blob cccddafdf05bc2eb409b060e6f873331b9e24d49
lines 167-186 BuildStones: seed then Old := Result[I-1]; each expression reads Old.
NormativeSave uses ordinary modulo of x-1 then +1, structurally normative.
This test-only routine is not a live production legacy path.
Path history of test/NormativeOracle.pas lists only bootstrap
52d36b0079b3b48c1bd297abae1c7ad04347d8c0; src at bootstrap contains
BigInt, MonsterBootstrap, PastafariCalendar, SourceLanguageCatalog.
Inspected all 12 subsequent Object Pascal src-changing commit patches from
branch-scoped commits?path=src (stop at bootstrap; earlier shared ancestry excluded):
ab43289f9913cdac808755680ae8d6d5ff57ebbe
c8a40699a434b4d9d97b6123c45306689583352a
a939473f325ae98a125e3e1b9e17be2f781a1d3f
995869f83ebb249e6841a66ce5fcf5ecf2392a69
43add99d816cc0a8b5feb17df3e76935957e5a90
a2c8c8fa3fb0605fef07d3f9c945548d7becd02b
18f9650c27593ccd99b4a2b9b22ca9df8477b918
dd3e5f2b84e16c5232ad42d0486e9642622564dc
0ba86bfa969863f404fec60c881bff0e73911c72
453e3614f28e9ce2158582a17277ae7ee12f34f9
43e80adf72418dd9a3a1e4cbf429281aaa56d105
e46cbb3dcee1b6e7f6316ddb115814b9b8054c8d
No stone/snapshot/pedra matches in these src patches; no evidence of a
distinct live stone implementation in this inspected Object Pascal lineage.
No historical defect claim; no authorization to introduce artificial RED.
Decision required: supply genuine live legacy source/discrepancy, or explicitly
authorize constructing a documented seeded legacy path for Stage08 only.
Previous Stage04/06 authorizations do not transfer. No Stage09.
Executed in JS preflight: 694 checks, 205 wrapping raw values, max 254 bits.
225 quotient identity + 225 reverse order + 230 range + 5 hand row2 + 9 SAVE bounds.
Run: node docs/stage08_stone_snapshot_preflight.js
*/
"use strict";
function preflight(){
 const M=(1n<<127n)-1n, seed=[17n,29n,43n,71n,101n], coeff=[3n,5n,7n,11n,13n];
 let checks=0;function check(p){checks++;if(!p)throw Error("check "+checks);}
 function save(x){return ((x-1n)%M+M)%M+1n;}
 function raw(i,s,j){return s[j]**2n+coeff[j]*s[(j+1)%5]+(j===0?BigInt(i):s[j-1]);}
 const rows=[seed.slice()];let wraps=0, maxBits=0;
 for(let i=2;i<=46;i++){const old=Object.freeze(rows[i-2].slice());const next=old.map((_,j)=>save(raw(i,old,j)));for(const j of [4,2,0,3,1]){const x=raw(i,old,j),q=(x-1n)/M;check(next[j]===x-q*M);if(x>M)wraps++;maxBits=Math.max(maxBits,x.toString(2).length);}const reverse=Array(5);for(const j of [4,3,2,1,0])reverse[j]=save(raw(i,old,j));for(let j=0;j<5;j++)check(next[j]===reverse[j]);rows.push(next);}
 for(const row of rows)for(const x of row)check(x>=1n&&x<=M);
 for(const [j,x] of [378n,1073n,2375n,6195n,10493n].entries())check(rows[1][j]===x);
 for(const [x,y] of [[0n,M],[1n,1n],[M-1n,M-1n],[M,M],[M+1n,1n],[2n*M,M],[2n*M+1n,1n],[-1n,M-1n],[-M,M]])check(save(x)===y);
 return {checks,wraps,maxBits,rows:rows.map((r,i)=>[i+1,...r.map(String)])};
}
const result=preflight();
console.log("i\twheat\tbarley\tsalt\tbitter\tred");
for(const row of result.rows) console.log(row.join("\t"));
console.error(JSON.stringify({checks:result.checks,wraps:result.wraps,maxBits:result.maxBits}));
