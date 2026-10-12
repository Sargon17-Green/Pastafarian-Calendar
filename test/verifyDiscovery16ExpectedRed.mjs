import {spawnSync} from "node:child_process";
const r=spawnSync(process.execPath,["--experimental-strip-types","test/discovery16Red.ts"],
 {encoding:"utf8",timeout:120000,maxBuffer:4*1024*1024});
const log=(r.stdout??"")+(r.stderr??"");
const mark="DISCOVERY_16_EXPECTED_RED mismatches=3 matches=0 oldMax=5781 realMax=5778";
if(r.error||r.status===null||r.status===0||!log.includes(mark)){
 process.stderr.write("STAGE_32_EXPECTED_RED_VERIFICATION_FAILED\n"+log);
 if(r.error)process.stderr.write(String(r.error));
 process.exit(1);
}
process.stdout.write("STAGE_32_DISCOVERY_16_EXPECTED_RED_VERIFIED nonzero=1 mismatches=3 matches=0 oldMax=5781\n");
