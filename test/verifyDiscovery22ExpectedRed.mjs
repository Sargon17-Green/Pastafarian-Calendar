import {spawnSync} from "node:child_process";
const x=spawnSync(process.execPath,["--experimental-strip-types","test/discovery22Red.ts"],
 {encoding:"utf8",timeout:180000,maxBuffer:4*1024*1024});
const output=(x.stdout??"")+(x.stderr??"");
const mark="DISCOVERY_22_EXPECTED_RED duplicateNativeNames=1 correctedDistinctness=not_applied bowl=5 seal=22";
if(x.error||x.status===null||x.status===0||!output.includes(mark)){
 process.stderr.write("STAGE_44_EXPECTED_RED_VERIFICATION_FAILED\n"+output);
 if(x.error)process.stderr.write(String(x.error));
 process.exit(1);
}
process.stdout.write("STAGE_44_DISCOVERY_22_EXPECTED_RED_VERIFIED nonzero=1 naturalNativeWitness=1 duplicateNames=1\n");
