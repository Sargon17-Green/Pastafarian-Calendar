#!/usr/bin/env node
// Discovery24 alternative C: isolated bounded streaming lexical transport QA.
// Source lock eaecf2c20acb5acb2d3919c6f3760706bf0602bc; no production change.
// Transport only: no numeric rank admission, p520 oracle, primitive/bit arithmetic, or JVM proof.
function streamingQA(){
 const MAX_FRAME=176120, MAX_CHUNK=4096;
 function reader(frameCap=MAX_FRAME,chunkCap=MAX_CHUNK){
  if(!Number.isInteger(frameCap)||frameCap<1||frameCap>MAX_FRAME||!Number.isInteger(chunkCap)||chunkCap<1||chunkCap>MAX_CHUNK)throw Error("invalid cap");
  const profile=new Uint16Array(33);let m=0,n=0,p=0,num=0,nd=0,rank=null,rlen=0,bytes=0,steps=0,writes=0,peak=66,phase="literal",literal='{"profile":[',idx=0,after="profile",failure=null,ended=false;
  const refuse=s=>{failure=s;return false};
  function expect(s,next){phase="literal";literal=s;idx=0;after=next}
  function digit(b){return b>=48&&b<=57}
  function add(b){if(nd===0&&b===48)return refuse("REFUSE_ENCODING");nd++;num=num*10+b-48;return true}
  function consume(b){
   steps++;
   if(phase==="done")return refuse("REFUSE_ENCODING");
   if(phase==="literal"){if(b!==literal.charCodeAt(idx++))return refuse("REFUSE_ENCODING");if(idx===literal.length)phase=after;return true}
   if(phase==="profile"){
    if(digit(b)){if(nd===3)return refuse("REFUSE_PROFILE_SCOPE");return add(b)}
    if((b!==44&&b!==93)||!nd)return refuse("REFUSE_ENCODING");
    if(num<4||num>123||m===33||n+num>3569)return refuse("REFUSE_PROFILE_SCOPE");
    profile[m++]=num;writes++;n+=num;nd=num=0;
    if(b===93){if(m<2)return refuse("REFUSE_PROFILE_SCOPE");expect(',"p":',"position")}else if(m===33)return refuse("REFUSE_PROFILE_SCOPE");
    return true;
   }
   if(phase==="position"){
    if(digit(b)){if(nd===3)return refuse("REFUSE_POSITION_SCOPE");return add(b)}
    if(b!==44||!nd)return refuse("REFUSE_ENCODING");
    p=num;if(p<1||p>=n||p>520)return refuse("REFUSE_POSITION_SCOPE");
    const B=2*n*Math.ceil(Math.log2(m+1))+2*Math.ceil(Math.log2(n+1))+8;
    rank=new Uint8Array(B);peak=66+B;expect('"rank":"',"rank");return true;
   }
   if(phase==="rank"){
    if(b===34){if(!rlen)return refuse("REFUSE_RANK_ENCODING");expect("}","done");return true}
    if(!digit(b)||(!rlen&&b===48)||rlen===rank.length)return refuse("REFUSE_RANK_ENCODING");
    rank[rlen++]=b;writes++;return true;
   }
   throw Error("state");
  }
  function push(chunk){
   if(ended||failure)return false;
   if(!(chunk instanceof Uint8Array)||chunk.length===0||chunk.length>chunkCap)return refuse("REFUSE_CHUNK");
   for(const b of chunk){if(bytes===frameCap)return refuse("REFUSE_FRAME");bytes++;if(!consume(b))return false}
   return true;
  }
  function finish(){
   if(ended)throw Error("single finish");ended=true;
   if(!failure&&phase!=="done")failure="REFUSE_TRUNCATED";
   const stats={bytes,steps,writes,peakOwnedBufferBytes:peak,rankCapacity:rank?.length||0};
   if(failure)return {status:failure,stats};
   // Exactly one bounded output string, no full frame string or JSON.parse.
   // Joining parts may coexist with the resulting string. Bound logical UTF-16
   // code units by 2*rlen; JS allocator, object metadata and caller buffers excluded.
   const parts=[];for(let i=0;i<rlen;i+=1024)parts.push(String.fromCharCode(...rank.subarray(i,Math.min(i+1024,rlen))));
   const rankString=parts.join("");
   return {status:"OK",request:{profile:Array.from(profile.subarray(0,m)),p,rank:rankString},stats:{...stats,logicalBufferAndStringBytes:peak+4*rlen}};
  }
  return {push,finish};
 }
 const ascii=s=>Uint8Array.from(s,c=>c.charCodeAt(0));
 const raw=(profile,p,rank)=>JSON.stringify({profile,p,rank});
 function run(s,chunk=MAX_CHUNK,fc=MAX_FRAME){const r=reader(fc,chunk);const a=typeof s==="string"?ascii(s):s;for(let i=0;i<a.length;i+=chunk){if(!r.push(a.subarray(i,i+chunk)))break}return r.finish()}
 let checks=0;const assert=(v,msg)=>{checks++;if(!v)throw Error(msg)};
 const sample=raw([4,5],3,"35"),expect=JSON.stringify({profile:[4,5],p:3,rank:"35"});
 for(let i=1;i<sample.length;i++){const r=reader();assert(r.push(ascii(sample.slice(0,i)))&&r.push(ascii(sample.slice(i))),"split push");const z=r.finish();assert(z.status==="OK"&&JSON.stringify(z.request)===expect&&z.stats.steps===sample.length,"split "+i)}
 for(let i=0;i<sample.length;i++)assert(run(sample.slice(0,i),1).status==="REFUSE_TRUNCATED","truncated "+i);
 for(const s of [sample+" ",sample.replace('"p":3','"p":03'),sample.replace('"p":3','"p":0'),sample.replace('"p":3','"p":9'),sample.replace('"p":3','"p":3,"p":3'),sample.replace('"rank":"35"','"rank":"035"'),sample.replace('"rank":"35"','"rank":""'),sample.replace('"rank":"35"','"rank":"3\\u0035"'),sample.replace('"rank":"35"','"rank":35'),raw([3,5],1,"1"),raw([4],1,"1"),raw(Array(34).fill(4),1,"1"),raw(Array(33).fill(123),1,"1"),raw([4,5],1,"+1"),raw([4,5],1,"1\n"),' '+sample])assert(run(s,2).status.startsWith("REFUSE"),"malformed "+s.slice(0,50));
 for(const b of [0,10,127,128,255]){const a=ascii(sample);a[0]=b;assert(run(a).status==="REFUSE_ENCODING","byte "+b)}
 assert(run(sample,1,sample.length).status==="OK","frame exact");assert(run(sample,1,sample.length-1).status==="REFUSE_FRAME","frame minus one");
 const r=reader(MAX_FRAME,4);assert(!r.push(ascii("12345"))&&r.finish().status==="REFUSE_CHUNK","chunk oversized");
 const e=reader();assert(!e.push(new Uint8Array(0))&&e.finish().status==="REFUSE_CHUNK","empty chunk");
 const prof=[103,119,108,107,112,95,116,113,117,70,85,120,111,122,110,75,116,107,121,122,100,93,119,106,80,114,123,117,113,114,117,102,122];
 const n=prof.reduce((a,b)=>a+b,0), B=2*n*Math.ceil(Math.log2(prof.length+1))+2*Math.ceil(Math.log2(n+1))+8;
 const max=raw(prof,520,"9".repeat(B)),z=run(max);
 assert(z.status==="OK"&&z.request.rank.length===B&&z.stats.writes===B+33&&z.stats.steps===max.length,"max lexical rank");
 assert(run(raw(prof,520,"9".repeat(B+1))).status==="REFUSE_RANK_ENCODING","rank minus one budget");
 const canonical=run(raw(prof,520,"1".repeat(5288)),17);
 assert(canonical.status==="OK"&&canonical.request.p===520&&canonical.stats.writes===5288+33,"canonical shape only");
 return {status:"PASS_STREAMING_TRANSPORT_ONLY",checks,canonicalShape:canonical.stats,maximumLexicalRank:z.stats,contract:"ordered compact ASCII JSON only; 1..4096 bytes per nonempty chunk, <=176120 frame; lexical rank only, numeric admission/range downstream; no CPU/heap/Native proof",stage2:"OPEN"};
}
console.log(JSON.stringify(streamingQA(),null,2));
// Observed offline JS: {"status":"PASS_STREAMING_TRANSPORT_ONLY","checks":131,"canonicalShape":{"bytes":5445,"steps":5445,"writes":5321,"peakOwnedBufferBytes":42926,"rankCapacity":42860,"logicalBufferAndStringBytes":64078},"maximumLexicalRank":{"bytes":43017,"steps":43017,"writes":42893,"peakOwnedBufferBytes":42926,"rankCapacity":42860,"logicalBufferAndStringBytes":214366},"contract":"ordered compact ASCII JSON only; 1..4096 bytes per nonempty chunk, <=176120 frame; lexical rank only, numeric admission/range downstream; no CPU/heap/Native proof","stage2":"OPEN"}
