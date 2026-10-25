import {spawnSync} from "node:child_process";
const out=spawnSync(process.execPath,["--experimental-strip-types","test/discovery24Red.ts"],
 {encoding:"utf8",timeout:180000,maxBuffer:4*1024*1024});
const text=(out.stdout??"")+(out.stderr??"");
const mark="DISCOVERY_24_EXPECTED_RED independentDailyWrong=1 required=4,4,5 observed=5,4,4 patch24=not_applied";
if(out.error||out.status===null||out.status===0||!text.includes(mark)){
 process.stderr.write("STAGE_48_EXPECTED_RED_VERIFICATION_FAILED\n"+text);
 if(out.error)process.stderr.write(String(out.error));
 process.exit(1);
}
process.stdout.write("STAGE_48_DISCOVERY_24_EXPECTED_RED_VERIFIED nonzero=1 wrongGhost=1\n");
