#!/usr/bin/env node
// v101: one call of frozen original TypeScript F(c,t) per OS process.
// Only the source calculates dates; this adapter writes exact native values.
import {createHash} from 'node:crypto';
import {openSync,writeSync,fsyncSync,closeSync,realpathSync} from 'node:fs';
import {resolve,join} from 'node:path';
import {pathToFileURL} from 'node:url';
const C='-15055671';
const TARGETS=new Set(['-15055671','-15055658','-15056671','-15054671']);
function fail(s){throw Error('V101_FAIL_CLOSED: '+s)}
function args(tokens){
  const names=['--source-root','--calculation-day','--target-day','--raw-out','--catalog-out'];
  const m=new Map();
  if(tokens.length!==names.length*2)fail('wrong argument count');
  for(let i=0;i<tokens.length;i+=2){
    if(!names.includes(tokens[i])||m.has(tokens[i]))fail('unknown or duplicate switch');
    m.set(tokens[i],tokens[i+1]);
  }
  if(m.size!==names.length||names.some(k=>!m.has(k)))fail('missing switch');
  if(m.get('--calculation-day')!==C||!TARGETS.has(m.get('--target-day')))
    fail('unauthorized calculation/target date');
  if(!/^-?(?:0|[1-9][0-9]*)$/.test(m.get('--target-day')))fail('noncanonical target');
  return m;
}
function catalogValues(a,n,label){
  if(!Array.isArray(a)||a.length!==n)fail(label+' length');
  const values=[];
  for(let i=0;i<n;i++){
    if(a[i]?.canonicalIndex!==i+1||typeof a[i]?.text!=='string'||!a[i].text)
      fail(label+' invalid source catalog');
    values.push(a[i].text);
  }
  if(new Set(values).size!==n)fail(label+' duplicate');
  return values;
}
function createOnce(name,bytes){
  const fd=openSync(name,'wx',0o600);
  try{writeSync(fd,bytes);fsyncSync(fd)}finally{closeSync(fd)}
}
const o=args(process.argv.slice(2));
if(process.env.PASTAFARI_V101_LINUX_SAMPLE_ADMITTED!=='1')fail('missing resource admission');
const root=realpathSync(resolve(o.get('--source-root')));
const ts=await import(pathToFileURL(realpathSync(join(root,'src/postStage55FinalDate.ts'))).href);
const names=await import(pathToFileURL(realpathSync(join(root,'src/sourceLanguageCatalog.ts'))).href);
if(typeof ts.calendarDateSpaghetti!=='function')fail('original two-bigint source absent');
const cutlets=catalogValues(names.CUTLET_CATALOG,17,'cutlet');
const months=catalogValues(names.MONTH_CATALOG,47,'month');
const t=o.get('--target-day');
const v=ts.calendarDateSpaghetti(BigInt(C),BigInt(t));
if(!Array.isArray(v)||v.length!==5||typeof v[0]!=='bigint'||
   typeof v[1]!=='string'||typeof v[2]!=='bigint'||
   typeof v[3]!=='string'||typeof v[4]!=='bigint'||v[2]<=0n||v[4]<=0n||
   !cutlets.includes(v[1])||!months.includes(v[3]))fail('original malformed tuple');
const native=[v[0].toString(),v[1],v[2].toString(),v[3],v[4].toString()];
const line=Buffer.from(JSON.stringify({calculation_day:C,target_day:t,native_tuple:native})+'\n');
createOnce(o.get('--raw-out'),line);
createOnce(o.get('--catalog-out'),Buffer.from(JSON.stringify({cutlets,months})+'\n'));
console.log('V101_ONE_UNCHANGED_TYPESCRIPT_SOURCE_DAY_NOT_YEAR target='+t+' raw_sha256='+createHash('sha256').update(line).digest('hex'));
