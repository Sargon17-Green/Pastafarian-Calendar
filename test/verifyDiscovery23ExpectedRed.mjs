import {spawnSync} from "node:child_process";
const out=spawnSync(process.execPath,
 ["--experimental-strip-types","test/discovery23Red.ts"],
 {encoding:"utf8",timeout:180000,maxBuffer:4*1024*1024});
const text=(out.stdout??"")+(out.stderr??"");
const mark="DISCOVERY_23_EXPECTED_RED oldExplicitAllMonthWays=blocked hugeFamily=1 virtualPatch=not_applied";
if(out.error||out.status===null||out.status===0||!text.includes(mark)){
 process.stderr.write("STAGE_46_EXPECTED_RED_VERIFICATION_FAILED\n"+text);
 if(out.error)process.stderr.write(String(out.error));
 process.exit(1);
}
process.stdout.write("STAGE_46_DISCOVERY_23_EXPECTED_RED_VERIFIED nonzero=1 hugeFamily=1\n");
