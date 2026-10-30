import {spawnSync} from "node:child_process";
const r=spawnSync(process.execPath,
 ["--experimental-strip-types","test/discovery26Red.ts"],
 {encoding:"utf8",timeout:180000,maxBuffer:4*1024*1024});
const stderr=r.stderr??"";
const mark="DISCOVERY_26_EXPECTED_RED mismatchDays=1,2,8 controls=7,13 model=nextDayOnly";
const genuine=stderr.split(/\r?\n/).some(line=>line.trim()==="Error: "+mark);
if(r.error||r.status!==1||r.signal!==null||!genuine){
 process.stderr.write("STAGE_52_DISCOVERY_26_EXPECTED_RED_VERIFICATION_FAILED\n"+
  (r.stdout??"")+stderr);
 if(r.error)process.stderr.write(String(r.error));
 process.exit(1);
}
console.log("STAGE_52_DISCOVERY_26_EXPECTED_RED_VERIFIED nonzero=1 mismatches=3 controls=2");
