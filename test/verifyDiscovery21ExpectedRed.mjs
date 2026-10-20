import {spawnSync} from "node:child_process";
const r=spawnSync(process.execPath,["--experimental-strip-types","test/discovery21Red.ts"],
 {encoding:"utf8",timeout:180000,maxBuffer:4*1024*1024});
const result=(r.stdout??"")+(r.stderr??"");
const marker="DISCOVERY_21_EXPECTED_RED wrongBoundary=1 matches=0 trueActionGate=1 oldFilter=absent";
if(r.error||r.status===null||r.status===0||!result.includes(marker)){
 process.stderr.write("STAGE_42_EXPECTED_RED_VERIFICATION_FAILED\n"+result);
 if(r.error)process.stderr.write(String(r.error));
 process.exit(1);
}
process.stdout.write("STAGE_42_DISCOVERY_21_EXPECTED_RED_VERIFIED nonzero=1 trueActionGate=1 wrongBoundary=1\n");
