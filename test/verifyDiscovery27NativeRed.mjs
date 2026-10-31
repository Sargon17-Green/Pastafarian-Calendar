import {spawnSync} from "node:child_process";
const p=spawnSync(process.execPath,["--experimental-strip-types","test/discovery27NativeRed.ts"],{
 encoding:"utf8",timeout:120000,maxBuffer:1048576
});
const stderr=p.stderr||"";
if(p.error||p.signal||p.status!==1||
 !stderr.includes("Error: DISCOVERY27_NATIVE_EXPECTED_RED realYear5000=1 month=44")||
 !stderr.includes("nativeCalls=61")||
 stderr.includes("DISCOVERY27_NATIVE_NO_REAL_GAP_OBSERVED")){
 console.error("STAGE_54_DISCOVERY_27_NATIVE_EXPECTED_RED_INVALID",p.status,p.signal,stderr.slice(-1600));
 process.exit(2);
}
console.log("STAGE_54_DISCOVERY_27_NATIVE_EXPECTED_RED_VERIFIED realYear5000=1 nonzero=1");
