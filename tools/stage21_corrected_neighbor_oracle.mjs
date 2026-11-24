function correctedStage21Oracle(){
  "use strict";
  const M=(1n<<127n)-1n, K=[0,1,2,3,4,0];
  const save=x=>1n+(x-1n)%M;
  const fold=x=>{while(x>M)x=(x&M)+(x>>127n);return x;};
  const assert=(v,m)=>{if(!v)throw Error(m)};
  const all=[];
  function perm(p,r){if(!r.length)all.push(p);else r.forEach((v,i)=>perm([...p,v],r.filter((_,j)=>i!==j)));}
  perm([],[0,1,2,3,4,5]);
  function rank(t){let r=Number((t-1n)%720n),pool=[0,1,2,3,4,5],o=[];for(const f of [120,24,6,2,1,1]){o.push(pool.splice(Math.floor(r/f),1)[0]);r%=f}return o}
  for(let r=1;r<=720;r++)assert(rank(BigInt(r)).join()==all[r-1].join(),"rank "+r);
  function stepByID(b,t,s,u,mutation="none"){
    const o=rank(t),res=[];
    for(let id=0;id<6;id++){
      const p=o.indexOf(id),j=mutation==="id-for-position"?id:p;
      let l=b[mutation==="raw-position-neighbors"?(j+5)%6:o[(j+5)%6]],r=b[mutation==="raw-position-neighbors"?(j+1)%6:o[(j+1)%6]];
      if(mutation==="swap-neighbors")[l,r]=[r,l];
      const aux=p<3?save(t*t+b[id]*(mutation==="aux-no-stone"?1n:s[p])+BigInt(u*(2*(p+1)+(mutation==="aux-shift"?2:1)))):2n;
      res.push(save(b[id]*b[id]+2n*l+3n*r+aux+t+s[K[j]]+(mutation==="omit-5LR"?0n:5n*l*r)+BigInt(u*(p+1))));
    }
    return {b:res,o};
  }
  function stepByPosition(b,t,s,u){
    const o=all[Number((t-1n)%720n)],ring=o.map(id=>b[id]),res=Array(6);
    const padded=[ring[5],...ring,ring[0]];
    for(let p=0;p<6;p++){
      const x=ring[p],l=padded[p],r=padded[p+2];
      const aux=p<3?fold(t**2n+x*s[p]+BigInt((2*p+3)*u)):2n;
      res[o[p]]=fold(x**2n+2n*l+3n*r+aux+t+s[p===5?0:p]+5n*l*r+BigInt((p+1)*u));
    }
    return {b:res,o};
  }
  const same=(a,b)=>a.length===b.length&&a.every((v,i)=>v===b[i]);
  let seed=0x25fa2026;
  function random(){let x=0n;for(let i=0;i<4;i++){seed^=seed<<13;seed^=seed>>>17;seed^=seed<<5;x=(x<<32n)+BigInt(seed>>>0)}return (x&M)||1n}
  function anchor(i){const b=Array(6).fill(1n),d=Array(46).fill(1n),s=Array.from({length:46},()=>Array(5).fill(1n));
    if(i===1){b.fill(M);d.fill(M);s.forEach(r=>r.fill(M))}
    if(i>=2){for(let j=0;j<6;j++)b[j]=i===3?M-BigInt(j):BigInt([2,3,5,7,11,13][j]);for(let j=0;j<46;j++){d[j]=i===2?720n:i===3?M-BigInt(j):i===4?721n:i===5?719n:i===6?2n:i===7?BigInt(j+1):i===8?BigInt(720+j):i===9?M:i===10?BigInt(1+720*j):i===11?BigInt(j%2?720:1):BigInt(512+j);s[j]=[2n,3n,5n,7n,11n].map((v,k)=>i===3?M-BigInt(k):i===9?M:i===12?BigInt(j+1)*v:v)}}
    return {b,d,s};}
  let comparisons=0,drops=0,digest=0n,roundtrips=0,immutability=0;
  const trace=[];
  function assess(q,record){const before=JSON.stringify([q.b,q.d,q.s],(_,v)=>typeof v==="bigint"?String(v):v);let a=q.b.slice(),b=q.b.slice(),last;const selected=[];
    for(let u=1;u<=46;u++){
      const x=stepByID(a,q.d[u-1],q.s[u-1],u),y=stepByPosition(b,q.d[u-1],q.s[u-1],u);
      assert(same(x.b,y.b)&&same(x.o,y.o),"differential");
      for(let v of x.b){assert(v>=1n&&v<=M,"range");let n=v,limbs=[];while(n){limbs.push(n%512n);n/=512n}let back=limbs.reduceRight((acc,k)=>acc*512n+k,0n);assert(back===v,"base512");roundtrips++;comparisons++;digest=(digest*1099511628211n+v)&((1n<<64n)-1n)}
      a=x.b;b=y.b;last=x.o;drops++;if(record&&[1,23,46].includes(u))selected.push({drop:u,bowls:a.map(String),order:last.map(x=>x+1)});
    }
    assert(same(last,all[Number((q.d[45]-1n)%720n)]),"final order");
    assert(before===JSON.stringify([q.b,q.d,q.s],(_,v)=>typeof v==="bigint"?String(v):v),"input changed");immutability++;
    if(record)trace.push(selected);
    return a;
  }
  for(let i=0;i<13;i++)assess(anchor(i),true);
  for(let i=0;i<384;i++){const take=()=>random();assess({b:Array.from({length:6},take),d:Array.from({length:46},take),s:Array.from({length:46},()=>Array.from({length:5},take))},false)}
  assert(trace[0][0].bowls.join()==="19,22,25,19,20,21","all ones");
  const witness=anchor(2),correct=stepByID(witness.b,witness.d[0],witness.s[0],1);
  const wrong=stepByID(witness.b,witness.d[0],witness.s[0],1,"raw-position-neighbors");
  assert(!same(correct.b,wrong.b),"must distinguish old defect");
  const mutants=[];
  for(const name of ["raw-position-neighbors","swap-neighbors","id-for-position","omit-5LR","aux-shift","aux-no-stone"]){
    const x=stepByID(witness.b,witness.d[0],witness.s[0],1,name),i=x.b.findIndex((v,j)=>v!==correct.b[j]);assert(i>=0,"undetected mutant "+name);mutants.push({name,bowl_id:i+1,expected:String(correct.b[i]),observed:String(x.b[i])});
  }
  assert(comparisons===109572&&drops===18262&&roundtrips===109572&&immutability===397,"counts");
  const replay=anchor(2);let b=replay.b.slice();for(let i=0;i<46;i++)b=stepByPosition(b,replay.d[i],replay.s[i],i+1).b;assert(same(b.map(String),trace[2][2].bowls),"replay");
  return {project_id:"PC-BRANCH-FALSE-ARABIC",stage:21,status:"CORRECTED_MATH_QA_ONLY_NOT_NATIVE_NOT_ACCEPTED",reference_blob:"3e9acc012bedf83294a6ec3cccb081a069556b5b",supersedes:"stage21_bounded_math_qa_2026-11-23.json: neighbor position-to-ID mapping",source_correction_commit:"c260b2058c1240e91df8df49fd0483bf7e939b9c",cases:397,anchors:13,seeded:384,transitions:drops,comparisons,range_checks:comparisons,roundtrips,immutable_inputs:immutability,rank_checks:720,replays:1,noncrypto_digest:"0x"+digest.toString(16).padStart(16,"0"),old_oracle_counterexample:{input_bowls:witness.b.map(String),t:String(witness.d[0]),stones:witness.s[0].map(String),order:correct.o.map(x=>x+1),correct:correct.b.map(String),old:wrong.b.map(String)},mutants,anchor_traces:trace,native:false,accepted:false};
}
process.stdout.write(JSON.stringify(correctedStage21Oracle(),null,2)+'\n');
