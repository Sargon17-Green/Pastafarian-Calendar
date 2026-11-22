#!/usr/bin/env node
'use strict';
// Standalone source-locked static audit; no WAT execution or Native PASS.
const fs=require('node:fs'),crypto=require('node:crypto'),path=require('node:path');
const audit=function audit(calendar,selector){
  function check(cond,msg){if(!cond)throw Error("STATIC_AUDIT_FAIL: "+msg);}
  function fn(src,name){
    const t=src.replace(/;;[^\n]*/g,"");
    const re=new RegExp("\\(func\\s+\\$"+name+"(?=\\s|\\))","g");
    const matches=[...t.matchAll(re)];check(matches.length===1,"unique function "+name);
    const start=matches[0].index;let depth=0,quoted=false,esc=false;
    for(let i=start;i<t.length;i++){const c=t[i];if(quoted){if(esc)esc=false;else if(c==="\\")esc=true;else if(c==='"')quoted=false;}else if(c==='"')quoted=true;else if(c==="(")depth++;else if(c===")"&&--depth===0)return t.slice(start,i+1);}
    throw Error("unbalanced "+name);
  }
  function count(body,name){return [...body.matchAll(new RegExp("\\(call\\s+\\$"+name+"(?=\\s|\\))","g"))].length}
  function has(body,re,msg){check(re.test(body),msg)}
  const root=fn(calendar,"calendar_date_wide"),lookup=fn(calendar,"find_target_year_wide");
  check(count(root,"find_target_year_wide")===1&&count(root,"resolve_year_structure_wide")===1,"calendar root");
  check(count(lookup,"year5000_wide")===1&&count(lookup,"next_year_wide")===1&&count(lookup,"previous_year_wide")===1,"year navigation");
  check(count(fn(calendar,"resolve_year_structure_wide"),"build_year_structure_wide")===1,"structure resolver");
  const yearFamilies=[["origin_year_pairs","year5000_wide",10,"total"],["next_year","next_year_wide",11,"countc"],["previous_year","previous_year_wide",12,"countc"]];
  for(const [family,name,seal,n] of yearFamilies){const b=fn(calendar,name);check(count(b,"choose_small_n")===1,"year selection "+family);has(b,new RegExp("\\(call\\s+\\$ask\\s+\\(i32\\.const\\s+1\\)\\s+\\(i32\\.const\\s+"+seal+"\\)"),family+" ask seal");has(b,new RegExp("\\(call\\s+\\$choose_small_n\\s+\\(global\\.get\\s+\\$TMP4\\)\\s+\\(local\\.get\\s+\\$dir\\)\\s+\\(local\\.get\\s+\\$"+n+"\\)"),family+" count input");}
  const structure=fn(calendar,"build_year_structure_wide");
  const calls=[...structure.matchAll(/\(call\s+\$s_select_family\s+\(i32\.const\s+(\d+)\)\s+\(i32\.const\s+(\d+)\)\s+\(global\.get\s+\$s_N\)/g)];
  const expected=[[2,20],[2,21],[5,22],[3,30],[3,31],[4,32],[5,33]];
  check(calls.length===7&&count(structure,"s_select_family")===7,"seven structure calls");
  check(JSON.stringify(calls.map(m=>[+m[1],+m[2]]))===JSON.stringify(expected),"bowl/seal mapping");
  const producerExpressions=[
    /\(call\s+\$s_from_u64\s+\(global\.get\s+\$s_N\)\s+\(i64\.extend_i32_u\s+\(local\.get\s+\$candidateCount\)\)\)/,
    /\(call\s+\$s_fi_cutlet_suffix_count\s/,
    /\(call\s+\$s_fi_falling_factorial\s+\(i32\.const\s+17\)\s+\(local\.get\s+\$cutletCount\)\s+\(global\.get\s+\$s_N\)\)/,
    /\(call\s+\$s_from_u64\s+\(global\.get\s+\$s_N\)\s+\(i64\.extend_i32_u\s+\(local\.get\s+\$candidateCount\)\)\)/,
    /\(call\s+\$s_count_bounded\s+\(local\.get\s+\$L\)\s+\(local\.get\s+\$monthCount\)\s+\(i32\.const\s+4\)\s+\(i32\.const\s+123\)\s+\(global\.get\s+\$s_N\)\)/,
    /\(call\s+\$s_wp_build\s+\(global\.get\s+\$s_N\)\)/,
    /\(call\s+\$s_fi_falling_factorial\s+\(i32\.const\s+47\)\s+\(local\.get\s+\$monthCount\)\s+\(global\.get\s+\$s_N\)\)/
  ];
  for(let i=0;i<7;i++)has(structure.slice(i?calls[i-1].index+calls[i-1][0].length:0,calls[i].index),producerExpressions[i],"N producer for seal "+expected[i][1]);
  const bridge=fn(calendar,"s_select_family"),dispatch=fn(calendar,"s_choose"),isolated=fn(selector,"choose");
  for(const n of ["ask","s_copy","s_choose"])check(count(bridge,n)===1,"bridge "+n);
  for(const n of ["s_choose_short","s_choose_wide"])check(count(dispatch,n)===1,"calendar selector "+n);
  for(const n of ["choose_short","choose_wide"])check(count(isolated,n)===1,"isolated selector "+n);
  const gate=fn(calendar,"gate_gap_wide");check(count(gate,"choose_922")===1,"gate helper");
  has(gate,/\(call\s+\$ask\s+\(i32\.const\s+1\)\s+\(i32\.const\s+1\)/,"gate helper asks bowl1 seal1");
  check(!/\(import\s/.test(calendar),"unexpected module import");
  const M=(1n<<127n)-1n;let fact=1n;for(let i=2n;i<=47n;i++)fact*=i;
  check(M<fact&&fact<=M*M,"47! wide k2 oracle");
  return {project:"PC-BRANCH-WAT-SPANISH",type:"STATIC_SOURCE_AWARE",result:"PASS",branch:"WAT+Español",calendarBlob:"70267bb5730678f81d6138a2224d6b8d9a193eb8",isolatedSelectorBlob:"e23f013ab96b498b0ac365dbb1b25273c845e790",yearPaths:yearFamilies.map(x=>({family:x[0],function:x[1],seal:x[2],N:x[3],selector:"choose_small_n"})),structurePaths:expected.map((x,i)=>({family:["cutlet_count","cutlet_partition","cutlet_names","month_count","month_lengths","month_weaving","month_names"][i],bowl:x[0],seal:x[1],selector:"s_select_family -> s_choose"})),extraHelper:{family:"gate_gap",selector:"choose_922",N:922},monthName47FactDigits:2,productionCallsIsolatedTestSelector:false,native:false,ci:false,differential:false,stage02Accepted:false};
};
const root=path.resolve(__dirname,'..');
const cal=fs.readFileSync(path.join(root,'oracle/normative_calendar_wide.wat'));
const sel=fs.readFileSync(path.join(root,'tests/normative_selector.wat'));
const blob=b=>crypto.createHash('sha1').update('blob '+b.length+'\0').update(b).digest('hex');
try{
  if(blob(cal)!=='70267bb5730678f81d6138a2224d6b8d9a193eb8')throw Error('Calendar source drift');
  if(blob(sel)!=='e23f013ab96b498b0ac365dbb1b25273c845e790')throw Error('Selector source drift');
  console.log(JSON.stringify(audit(cal.toString('utf8'),sel.toString('utf8')),null,2));
}catch(e){console.error('STATIC_AUDIT_FAIL:',e.stack||String(e));process.exitCode=1;}
