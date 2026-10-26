import {spawnSync} from "node:child_process";
const r=spawnSync(process.execPath,
 ["--experimental-strip-types","test/discovery25Red.ts"],
 {encoding:"utf8",timeout:180000,maxBuffer:4*1024*1024});
const out=(r.stdout??"")+(r.stderr??"");
const mark="DISCOVERY_25_EXPECTED_RED oldContiguousMonthDayGuess=6 actualPrefixOccurrences=5 patch25=not_applied";
if(r.error||r.status===null||r.status===0||!out.includes(mark)){
 process.stderr.write("STAGE_50_EXPECTED_RED_VERIFICATION_FAILED\n"+out);
 if(r.error)process.stderr.write(String(r.error));
 process.exit(1);
}
process.stdout.write("STAGE_50_DISCOVERY_25_EXPECTED_RED_VERIFIED nonzero=1 wrongContiguousSpan=1\n");
