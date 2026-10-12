import {spawnSync} from "node:child_process";
const r=spawnSync(process.execPath,["--experimental-strip-types",
 "test/discovery15Red.ts"],{encoding:"utf8",timeout:120000,maxBuffer:4*1024*1024});
const log=(r.stdout??"")+(r.stderr??"");
const expected="DISCOVERY_15_EXPECTED_RED mismatches=2 matches=0 gates=-1,-2 asked=FOUNDATION+abs";
if(r.error||r.status===null||r.status===0||!log.includes(expected)){
 process.stderr.write("STAGE_30_EXPECTED_RED_VERIFICATION_FAILED\n"+log);
 if(r.error)process.stderr.write(String(r.error));
 process.exit(1);
}
process.stdout.write("STAGE_30_DISCOVERY_15_EXPECTED_RED_VERIFIED nonzero=1 mismatches=2 matches=0 gates=-1,-2\n");
