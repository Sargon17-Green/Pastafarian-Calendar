import {spawnSync} from "node:child_process";
const p=spawnSync(process.execPath,["--experimental-strip-types","test/discovery18Red.ts"],
 {encoding:"utf8",timeout:120000,maxBuffer:4*1024*1024});
const output=(p.stdout??"")+(p.stderr??"");
const mark="DISCOVERY_18_EXPECTED_RED mismatches=1 matches=0 oldGuess=5002 anchorYear=5000 divisor=365";
if(p.error||p.status===null||p.status===0||!output.includes(mark)){
 process.stderr.write("STAGE_36_EXPECTED_RED_VERIFICATION_FAILED\n"+output);
 if(p.error)process.stderr.write(String(p.error));
 process.exit(1);
}
process.stdout.write("STAGE_36_DISCOVERY_18_EXPECTED_RED_VERIFIED nonzero=1 mismatches=1 matches=0 oldGuess=5002\n");
