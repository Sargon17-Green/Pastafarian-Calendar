// Stage10 independent normative model; no Pascal Native evidence.
// Run: node docs/stage10_hidden_drop_order_preflight.js
function preflight(){
const M=(1n<<127n)-1n,F=-15055671n;
const save=x=>((x-1n)%M+M)%M+1n;
const residue=x=>x%M===0n?M:(x%M+M)%M;
const abs=x=>x<0n?-x:x;
const N=d=>d<F?2n*(F-d):2n*(d-F)+1n;
const seeds=[17n,29n,43n,71n,101n], stones=[seeds];
for(let i=2;i<=7;i++){const [a,b,c,d,e]=stones[i-2];stones.push([save(a*a+3n*b+BigInt(i)),save(b*b+5n*c+a),save(c*c+7n*d+b),save(d*d+11n*e+c),save(e*e+13n*a+d)]);}
const anchor=[119390830530032782664128530203002080344n,11877236279154673426874867061566696749n,24217814924229232987463457533828175476n,166629231917547214614573522551290204247n,81202913407267092008896220686064041568n,73551520026920072430116213847585486272n,6164285870955721082771365327359496898n];
const days=[F-1n,F,F+1n,0n,1n,-278522n,F-M,F+M,F+2n**255n,F-2n**255n];
let pairs=0,trace=0,slots=0,anchors=0,orderSensitive=0;
const check=(v,msg)=>{if(!v)throw Error(msg)};
for(const c of days)for(const t of days){
 const A=N(c),B=N(t),D=abs(t-c)+1n,S=A+B,Q=t<c?1n:t===c?2n:3n;
 const h=[];
 for(let k=1;k<=7;k++){const K=BigInt(k),row=stones[k-1];
 let x=save(A+(2n*K+1n)*B+(3n*K+1n)*D+(4n*K+2n)*S+(4n*K+4n)*Q+row.reduce((a,b)=>a+b,0n));
 // Independent coefficient table and residue formulation, not a production implementation.
 const [a,b,d,e]=[[3n,4n,6n,8n],[5n,7n,10n,12n],[7n,10n,14n,16n],[9n,13n,18n,20n],[11n,16n,22n,24n],[13n,19n,26n,28n],[15n,22n,30n,32n]][k-1];
 let y=residue(A+a*B+b*D+d*S+e*Q+row[0]+row[1]+row[2]+row[3]+row[4]);
 check(x===y&&x>=1n&&x<=M,"initial");trace++;
 for(let r=1;r<=7;r++){x=save(x*x+3n*x+row[(r-1)%5]+BigInt(r));y=residue(y*(y+3n)+[...row,row[0],row[1]][r-1]+BigInt(r));check(x===y&&x>=1n&&x<=M,"grind");trace++;}
 h.push(x);if(c===F&&t===F){check(x===anchor[k-1],"canonical hidden");anchors++;}
 }
 const chronological=[...h].reverse();for(let p=-6;p<=0;p++){check(chronological[p+6]===h[-p],"position");slots++;}
 // The visible-1 witness is only a consumer of the hidden-history layout.
 const first=(history)=>{let x=save(seeds[0]*A+seeds[1]*B+seeds[2]*D+seeds[3]*S+seeds[4]*Q+history[6]+3n*history[4]+5n*history[0]+1n);
 const primes=[3n,5n,7n,11n,13n,17n,19n,23n,29n,31n,37n,41n,43n,47n];
 for(let r=0;r<11;r++)x=save(x*x+primes[r]*x+primes[r+1]*history[6]+primes[r+2]*history[4]+primes[r+3]*history[0]+seeds[r%5]);return x;};
 const v=first(chronological);if(c===F&&t===F){check(v===56644603826892212324764499696091907135n,"canonical visible 1");anchors++;}
 if(v!==first(h))orderSensitive++;
 pairs++;
}
return {pairs,traceChecks:trace,slotChecks:slots,canonicalAnchors:anchors,hypotheticalOrderSensitivity:orderSensitive,failures:0};
}
console.log(JSON.stringify(preflight()));
