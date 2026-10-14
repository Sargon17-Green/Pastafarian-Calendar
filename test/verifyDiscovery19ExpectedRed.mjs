import {spawnSync} from "node:child_process";
const proc=spawnSync(process.execPath,["--experimental-strip-types","test/discovery19Red.ts"],
 {encoding:"utf8",timeout:180000,maxBuffer:4*1024*1024});
const output=(proc.stdout??"")+(proc.stderr??"");
const marker="DISCOVERY_19_EXPECTED_RED wrongHits=1 matches=0 oldCacheKey=year.number year=5000 actionGuard=absent";
if(proc.error||proc.status===null||proc.status===0||!output.includes(marker)){
 process.stderr.write("STAGE_38_EXPECTED_RED_VERIFICATION_FAILED\n"+output);
 if(proc.error)process.stderr.write(String(proc.error));
 process.exit(1);
}
process.stdout.write("STAGE_38_DISCOVERY_19_EXPECTED_RED_VERIFIED nonzero=1 wrongHits=1 matches=0 year=5000\n");
