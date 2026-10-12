import {spawnSync} from "node:child_process";
const r=spawnSync(process.execPath,["--experimental-strip-types","test/discovery17Red.ts"],
 {encoding:"utf8",timeout:120000,maxBuffer:4*1024*1024});
const log=(r.stdout??"")+(r.stderr??"");
const marker="DISCOVERY_17_EXPECTED_RED mismatches=2 matches=0 length=1000 tie=opening-gate";
if(r.error||r.status===null||r.status===0||!log.includes(marker)){
 process.stderr.write("STAGE_34_EXPECTED_RED_VERIFICATION_FAILED\n"+log);
 if(r.error)process.stderr.write(String(r.error));
 process.exit(1);
}
process.stdout.write("STAGE_34_DISCOVERY_17_EXPECTED_RED_VERIFIED nonzero=1 mismatches=2 matches=0 length=1000\n");
