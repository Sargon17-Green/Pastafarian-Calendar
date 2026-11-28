#!/usr/bin/env node
// QA ONLY: exact pinned HOST rank/root fixtures; no Foundation H45 or native claim.
// Run: timeout 120s node --max-old-space-size=512 scripts/prepare_general_lex_ranks.js NEW_DIR
'use strict';
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),crypto=require('node:crypto');
if(process.argv.length!==3)throw Error('usage: NEW_DIR');
const dir=path.resolve(process.argv[2]),src=fs.readFileSync(path.join(__dirname,'stage1_multivector_full_oracle.js'));
const oracleBlob=crypto.createHash('sha1').update('blob '+src.length+'\0').update(src).digest('hex');
if(oracleBlob!=='e228f43f2d33b9af59c5fb232281ca403455ca5c')throw Error('oracle blob mismatch');
const sha=b=>crypto.createHash('sha256').update(Buffer.from(b)).digest('hex');
const suffix='fullTest(console.log);\n';
if(!src.toString('utf8').endsWith(suffix))throw Error('oracle anchor drift');
fs.mkdirSync(dir);
const core="\nconst pins=[\n [\"year4999\",20580,20580,\"6a1f8b7536eb8fa908c9472a289c36b6c2e80ab8a882110b2fa39f95a742d675\"],\n [\"year5001\",30153,30152,\"48065ca44d184f2fe002edfcc79ff4ba1612b828dfed71a8afbacf4be1dcee24\"],\n [\"creation_minus1234\",18314,18312,\"705e7e4245ddde6b91291e1d78789b78243127a68d40621d2c256b81035c132a\"],\n [\"creation_plus1234\",18147,18147,\"13fe3563f6f829f1af164b11c847a24f3ba59302a1a4805a92daedfb7daa839b\"],\n [\"year5002\",20372,20371,\"93a05ffb9b7d66bf5d06e5e229fc69bc73bfba19ec5b3324247ef4f8a14ca200\"]];\nconst cache=new Map([[0,F]]),groups=new Map();\nfor(const [c,t,...e] of vectors){\n const o=oracle(c,t,cache);check(o.cut.join()===e.join(),\"canonical cutlet\");\n const key=[c,o.open,o.close].join();if(!groups.has(key))groups.set(key,{c,t,o});\n}\ncheck(groups.size===6,\"group count\");\nconst result=[];let skipped=0;\nfor(const {c,t,o} of groups.values()){\n if(c===F&&o.open===-15057703&&o.close===-15053459){skipped++;continue;}\n const [name,rb,kb,pin]=pins[result.length],l=o.lengths,H=transfer(l),root=H[1][l[0]-1],rank=choose(sauce(c,o.open+1),4,32,root);\n check(root.toString(2).length===rb&&rank.toString(2).length===kb&&rank>=1n&&rank<=root,\"rank/root bounds\");\n const w=unrankWeave(l,H,rank);verifyWord(w,l);check(sha(w)===pin,\"word digest \"+name);\n result.push({name,c,t,year:o.cut[0],open:o.open,close:o.close,days:w.length,months:l.length,lengths:l,rootBits:rb,rankBits:kb,wordSHA256:pin,rootHex:root.toString(16),rankHex:rank.toString(16)});\n}\ncheck(skipped===1&&result.length===5&&result.reduce((n,x)=>n+x.days,0)===20763,\"coverage\");\n";
const result=vm.runInNewContext(src.toString('utf8').slice(0,-suffix.length)+core+'\nresult;', {sha},{timeout:110000});
const cases=[];
for(const {rootHex,rankHex,lengths,...x} of result){
 const geo=Buffer.from([lengths.length,...lengths].join(' ')+'\n'),root=Buffer.from(rootHex.padStart(8192,'0'),'hex'),rank=Buffer.from(rankHex.padStart(8192,'0'),'hex');
 if(root.length!==4096||rank.length!==4096)throw Error('width');
 fs.writeFileSync(path.join(dir,x.name+'.geometry'),geo,{flag:'wx'});
 fs.writeFileSync(path.join(dir,x.name+'.expected'),root,{flag:'wx'});
 fs.writeFileSync(path.join(dir,x.name+'.rank'),rank,{flag:'wx'});
 cases.push({...x,geometrySHA256:sha(geo),rootSHA256:sha(root),rankSHA256:sha(rank),native:'NOT_RUN'});
}
fs.writeFileSync(path.join(dir,'manifest.json'),JSON.stringify({scope:'HOST_RANK_FIXTURES_ONLY_STAGE1_NOT_ACCEPTED',oracleBlob,foundationSkipped:true,cases},null,2)+'\n',{flag:'wx'});
console.log('HOST_GENERAL_LEX_RANKS_PASS cases=5 days=20763 word_hashes=5 NATIVE_NOT_RUN');
