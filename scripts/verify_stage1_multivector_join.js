#!/usr/bin/env node
// QA only: native join of HOST-derived year/cutlet geometry, names and weave.
// Does not prove native year selection, composition or H/unrank. No production use.
// timeout 120s node --max-old-space-size=512 scripts/verify_stage1_multivector_join.js --prepare-only NEW_DIR
// With Icarus installed, replace --prepare-only with --native (outer timeout 240s).
'use strict';
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),crypto=require('node:crypto'),cp=require('node:child_process');
const [mode,destination]=process.argv.slice(2);
if(process.argv.length!==4||!['--prepare-only','--native'].includes(mode)||!destination)throw Error('usage: --prepare-only|--native NEW_DIR');
const dir=path.resolve(destination),src=fs.readFileSync(path.join(__dirname,'stage1_multivector_full_oracle.js'));
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const blob=crypto.createHash('sha1').update('blob '+src.length+'\0').update(src).digest('hex');
if(blob!=='e228f43f2d33b9af59c5fb232281ca403455ca5c')throw Error('oracle blob mismatch');
fs.mkdirSync(dir); // refuse pre-existing evidence directory
let code=src.toString('utf8');
const anchor='check(left===0&&rank===1n,"composition residual");return {cut,open:gate(i),close:gate(j),m,lengths,monthNames,position:t-gate(i)}';
if(code.split(anchor).length!==2||!code.endsWith('fullTest(console.log);\n'))throw Error('observation anchor drift');
code=code.replace(anchor,'let a=i; const cutlets=parts.map((v,p)=>{a+=v;return [gate(a)-gate(i),names[p]]}); '+anchor.replace('{cut,','{cut,cutlets,'));
code=code.slice(0,-'fullTest(console.log);\n'.length);
const result=vm.runInNewContext(code+`
 const groups=new Map(),cache=new Map([[0,F]]);
 for(let i=0;i<vectors.length;i++){let [c,t,...e]=vectors[i],o=oracle(c,t,cache),key=[c,o.open,o.close].join();check(o.cut.join()===e.join(),'canonical first3');if(!groups.has(key))groups.set(key,[]);groups.get(key).push({i,c,t,o})}
 const hashes=['e1a291eafc34153031a0fba5e8ae0bc99a06cf0c59f4a65665c5b027b56c3a29','6a1f8b7536eb8fa908c9472a289c36b6c2e80ab8a882110b2fa39f95a742d675','48065ca44d184f2fe002edfcc79ff4ba1612b828dfed71a8afbacf4be1dcee24','705e7e4245ddde6b91291e1d78789b78243127a68d40621d2c256b81035c132a','13fe3563f6f829f1af164b11c847a24f3ba59302a1a4805a92daedfb7daa839b','93a05ffb9b7d66bf5d06e5e229fc69bc73bfba19ec5b3324247ef4f8a14ca200'];
 let lines=[String(groups.size)],meta=[],days=0,canonical=0;
 for(const items of groups.values()){
  const {c,o}=items[0],l=o.lengths,H=transfer(l),root=H[1][l[0]-1],rank=choose(sauce(c,o.open+1),4,32,root),w=unrankWeave(l,H,rank);verifyWord(w,l);
  const hash=sha(Buffer.from(w));check(hash===hashes[meta.length],'word SHA');
  lines.push([c,o.open,o.close,o.cut[0],o.m,o.cutlets.length].join(' '));
  for(const row of o.cutlets)lines.push(row.join(' '));
  for(let j=0;j<o.m;j++)lines.push([l[j],o.monthNames[j]].join(' '));
  let count=Array(o.m).fill(0),start=0,ci=0;
  for(let p=1;p<=w.length;p++){
   if(p>o.cutlets[ci][0]){start=o.cutlets[ci][0];ci++}
   const k=w[p-1]-1,tuple=[o.cut[0],o.cutlets[ci][1],p-start,o.monthNames[k],++count[k]];
   for(const a of items)if(a.o.position===p){check(tuple.join()===[...vectors[a.i].slice(2),...expectedMonths[a.i]].join(),'canonical tuple');canonical++}
   lines.push([k+1,...tuple].join(' '));days++;
  }
  meta.push({c,open:o.open,close:o.close,year:o.cut[0],days:w.length,months:o.m,wordSHA256:hash,rootBits:root.toString(2).length,rankBits:rank.toString(2).length});
 }
 check(days===25007&&canonical===10&&meta.length===6,'coverage');({lines,meta,days,canonical});
`,{sha,Buffer},{timeout:110000});
const fixture=Buffer.from(result.lines.join('\n')+'\n');
fs.writeFileSync(path.join(dir,'fixture.txt'),fixture);
fs.writeFileSync(path.join(dir,'manifest.json'),JSON.stringify({oracleBlob:blob,fixtureSHA256:sha(fixture),days:result.days,canonical:result.canonical,groups:result.meta,scope:'HOST_GEOMETRY_NATIVE_JOIN_ONLY'},null,2)+'\n');
const sv=`module multivector_join;
integer f,rc,g,ng,c,opn,cls,y,m,k,i,j,p,n,prev,ci,start,ord,ey,ec,ed,em,eo,days,extra;
integer ends[1:17],cutname[1:17],lens[1:47],names[1:47],cnt[1:47],fp[1:47],lp[1:47];
initial begin
 f=$fopen("fixture.txt","r"); if(!f)$fatal(1,"OPEN");
 rc=$fscanf(f,"%d",ng); if(rc!=1||ng!=6)$fatal(1,"GROUP_COUNT"); days=0;
 for(g=0;g<ng;g=g+1)begin
  rc=$fscanf(f,"%d %d %d %d %d %d",c,opn,cls,y,m,k); n=cls-opn;
  if(rc!=6||n<1||n>5778||m<1||m>47||k<1||k>17)$fatal(1,"GEOMETRY");
  prev=0;
  for(i=1;i<=k;i=i+1)begin
   rc=$fscanf(f,"%d %d",ends[i],cutname[i]);
   if(rc!=2||ends[i]<=prev||ends[i]>n||cutname[i]<1||cutname[i]>17)$fatal(1,"CUTLET");
   for(j=1;j<i;j=j+1)if(cutname[j]==cutname[i])$fatal(1,"CUTLET_DUP"); prev=ends[i];
  end
  if(prev!=n)$fatal(1,"CUTLET_COVER"); prev=0;
  for(i=1;i<=m;i=i+1)begin
   rc=$fscanf(f,"%d %d",lens[i],names[i]);
   if(rc!=2||lens[i]<4||lens[i]>123||names[i]<1||names[i]>47)$fatal(1,"MONTH");
   for(j=1;j<i;j=j+1)if(names[j]==names[i])$fatal(1,"MONTH_DUP");
   prev=prev+lens[i];cnt[i]=0;fp[i]=0;lp[i]=0;
  end
  if(prev!=n)$fatal(1,"MONTH_COVER");ci=1;start=0;
  for(p=1;p<=n;p=p+1)begin
   rc=$fscanf(f,"%d %d %d %d %d %d",ord,ey,ec,ed,em,eo);
   if(rc!=6||ord<1||ord>m)$fatal(1,"ORDINAL");
   if(p>ends[ci])begin start=ends[ci];ci=ci+1;end
   cnt[ord]=cnt[ord]+1;if(cnt[ord]==1)fp[ord]=p;lp[ord]=p;
   if(y!=ey||cutname[ci]!=ec||p-start!=ed||names[ord]!=em||cnt[ord]!=eo)$fatal(1,"TUPLE_MISMATCH");
   days=days+1;
  end
  for(i=1;i<=m;i=i+1)begin
   if(cnt[i]!=lens[i])$fatal(1,"MULTIPLICITY");
   if(i>1)if(fp[i]<=fp[i-1]||lp[i]<=lp[i-1])$fatal(1,"ORDER");
  end
 end
 rc=$fscanf(f,"%d",extra);if(rc!=-1)$fatal(1,"TRAILING_DATA");
 if(days!=25007)$fatal(1,"DAY_COUNT");
 $display("NATIVE_HOST_GEOMETRY_JOIN_PASS days=%0d groups=%0d",days,ng);$finish;
end
endmodule
`;
fs.writeFileSync(path.join(dir,'join.sv'),sv);
function run(label,cmd,args,marker,negative=false){
 const p=cp.spawnSync(cmd,args,{cwd:dir,encoding:'utf8',timeout:30000,maxBuffer:1024*1024});
 const log=(p.stdout||'')+(p.stderr||'');fs.writeFileSync(path.join(dir,label+'.log'),log);
 if(p.error||p.signal||(negative?(p.status===0||!log.includes(marker)):(p.status!==0||(marker&&!log.includes(marker)))))throw Error(label+' failed: '+p.status+' '+p.error);
}
if(mode==='--prepare-only'){console.log('HOST_FIXTURE_PREPARED days=25007 groups=6 canonical=10 NATIVE_NOT_RUN SHA='+sha(fixture));}
else{
 run('compile','iverilog',['-g2012','-s','multivector_join','-o','join.vvp','join.sv'],'');
 const marker='NATIVE_HOST_GEOMETRY_JOIN_PASS days=25007 groups=6';run('positive','vvp',['join.vvp'],marker);
 const rows=result.lines.slice(),header=rows[1].split(' ').map(Number),first=2+header[4]+header[5];
 try{for(let field=1;field<=5;field++){let mutant=rows.slice(),v=mutant[first].split(' ').map(Number);v[field]++;mutant[first]=v.join(' ');fs.writeFileSync(path.join(dir,'fixture.txt'),mutant.join('\n')+'\n');run('mutant_'+field,'vvp',['join.vvp'],'TUPLE_MISMATCH',true)}}finally{fs.writeFileSync(path.join(dir,'fixture.txt'),fixture)}
 run('positive_restored','vvp',['join.vvp'],marker);
 console.log(marker+' mutants=5 SCOPE=HOST_GEOMETRY_JOIN_ONLY STAGE1_NOT_ACCEPTED');
}
