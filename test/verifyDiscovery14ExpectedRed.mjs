// Native Node.js verifier for the fourteenth deliberately failing historical scar.
// This small JS runner requires no TypeScript node typings and is cross-platform.
import { spawnSync } from "node:child_process";
const result=spawnSync(process.execPath,[
  "--experimental-strip-types","test/discovery14Red.ts"
],{encoding:"utf8",timeout:120000,maxBuffer:4*1024*1024});
const log=(result.stdout??"")+(result.stderr??"");
const marker="DISCOVERY_14_EXPECTED_RED mismatches=1 matches=0 N=M+1 blocked=1 old=0";
if(result.error||result.status===null||result.status===0||!log.includes(marker)){
  process.stderr.write("STAGE_28_EXPECTED_RED_VERIFICATION_FAILED\n"+log);
  if(result.error)process.stderr.write(String(result.error));
  process.exit(1);
}
process.stdout.write("STAGE_28_DISCOVERY_14_EXPECTED_RED_VERIFIED nonzero=1 mismatches=1 matches=0 N=M+1 old=0\n");
