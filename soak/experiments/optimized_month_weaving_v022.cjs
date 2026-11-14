'use strict';
/**
 * DERIVED ALGORITHM EXPERIMENT. The counting recurrence is adapted from
 * pinned Python/Türkçe MonthWeavingFamily, not an independent reference.
 * Never count this derivative as a separate original soak engine.
 */
function makeFastMonthWeavingFamily(lengths) {
  if (!Array.isArray(lengths) || !lengths.length ||
      lengths.some(x => !Number.isSafeInteger(x) || x < 1) ||
      lengths.reduce((a,b) => a+b, 0) > 5778) throw new RangeError('invalid bounded month lengths');
  const m = lengths.length;
  const prefix=[0];
  for (const x of lengths) prefix.push(prefix.at(-1)+x);
  const h=Array(m+1);
  h[m]=Array(prefix[m]+1).fill(1n);
  function choose(n,k) {
    if (!Number.isSafeInteger(n) || !Number.isSafeInteger(k) || k<0 || k>n) return 0n;
    k=Math.min(k,n-k);
    let v=1n;
    for(let i=1;i<=k;i++) v=v*BigInt(n-k+i)/BigInt(i);
    return v;
  }
  for(let opened=m-1;opened>=0;opened--){
    const n=lengths[opened],maxX=prefix[opened];
    if(n===1){ h[opened]=Array(maxX+1).fill(h[opened+1][0]);continue; }
    const weighted=Array(prefix[opened+1]).fill(0n);
    let running=0n,binomial=1n;
    for(let y=0;y<weighted.length;y++){
      if(y>=n-1){
        if(y>n-1) binomial=binomial*BigInt(y-1)/BigInt(y-n+1);
        running+=binomial*h[opened+1][y];
      }
      weighted[y]=running;
    }
    h[opened]=Array.from({length:maxX+1},(_,x)=>weighted[x+n-1]);
  }
  function countState(remaining,opened,closed){
    if(opened<closed||opened>m) return 0n;
    let baseCount=1n,baseLength=0;
    for(let i=closed;i<opened;i++){
      const n=remaining[i];
      if(n<=0) return 0n;
      if(baseLength===0) baseLength=n;
      else{baseCount*=choose(n+baseLength-1,baseLength);baseLength+=n;}
    }
    if(baseLength>=h[opened].length)throw new Error('state table too short');
    return baseCount*h[opened][baseLength];
  }
  function moves(remaining,opened,closed){
    const possibilities=[];
    for(let i=closed;i<opened;i++){
      if(remaining[i]===0||(remaining[i]===1&&i!==closed))continue;
      const next=remaining.slice();next[i]--;
      const nextClosed=next[i]===0?closed+1:closed;
      possibilities.push([i+1,next,opened,nextClosed]);
    }
    if(opened<m){
      const i=opened,next=remaining.slice();next[i]--;
      if(next[i]!==0||i===closed){
        possibilities.push([i+1,next,opened+1,next[i]===0?closed+1:closed]);
      }
    }
    return possibilities;
  }
  function unrank1(rank){
    const total=countState(lengths,0,0);
    if(typeof rank!=='bigint'||rank<1n||rank>total)throw new RangeError('rank beyond month weaving count');
    let remaining=lengths.slice(),opened=0,closed=0,r=rank;
    const out=[];
    while(out.length<prefix[m]){
      let selected=false;
      for(const [id,next,a,b] of moves(remaining,opened,closed)){
        const block=countState(next,a,b);
        if(r>block){r-=block;continue;}
        out.push(id);remaining=next;opened=a;closed=b;selected=true;break;
      }
      if(!selected)throw new Error('no legal next month for rank');
    }
    if(remaining.some(x=>x!==0)||opened!==m||closed!==m)throw new Error('invalid final weaving state');
    return out;
  }
  return Object.freeze({count:()=>countState(lengths,0,0),unrank1,debugTableCells:()=>h.reduce((n,row)=>n+row.length,0)});
}
module.exports = {makeFastMonthWeavingFamily};
