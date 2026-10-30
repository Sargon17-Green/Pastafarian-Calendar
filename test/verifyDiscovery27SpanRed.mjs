import {spawnSync} from "node:child_process";
import {fileURLToPath} from "node:url";
const fixture=fileURLToPath(new URL("./discovery27SpanRed.mjs",import.meta.url));
const result=spawnSync(process.execPath,[fixture],{encoding:"utf8",timeout:10000,maxBuffer:1048576});
const stderr=result.stderr||"";
if(result.error || result.signal || result.status!==1 ||
 !stderr.includes("AssertionError") ||
 !stderr.includes("DISCOVERY27_SYNTHETIC_SPAN_EXPECTED_RED") ||
 !stderr.includes("true !== false")){
 console.error("STAGE_54_DISCOVERY_27_EXPECTED_RED_INVALID",result.status,result.signal,stderr.slice(0,1000));
 process.exit(2);
}
console.log("STAGE_54_DISCOVERY_27_EXPECTED_RED_VERIFIED nonzero=1 synthetic=1");
