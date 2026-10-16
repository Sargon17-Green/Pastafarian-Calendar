import {spawnSync} from "node:child_process";
const p=spawnSync(process.execPath,["--experimental-strip-types","test/discovery20Red.ts"],
 {encoding:"utf8",timeout:180000,maxBuffer:4*1024*1024});
const log=(p.stdout??"")+(p.stderr??"");
const marker="DISCOVERY_20_EXPECTED_RED wrongSauce=1 correctSauce=0 oldTarget=original firstDaySubstitution=absent";
if(p.error||p.status===null||p.status===0||!log.includes(marker)){
 process.stderr.write("STAGE_40_EXPECTED_RED_VERIFICATION_FAILED\n"+log);
 if(p.error)process.stderr.write(String(p.error));
 process.exit(1);
}
process.stdout.write("STAGE_40_DISCOVERY_20_EXPECTED_RED_VERIFIED nonzero=1 wrongSauce=1 correctedCalls=0\n");
