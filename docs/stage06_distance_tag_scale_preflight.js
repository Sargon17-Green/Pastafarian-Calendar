#!/usr/bin/env node
// Stage06 DISCOVERY03_DISTANCE_TAG_SCALE: preflight independente, sem Native Pascal.
// Norma README.md (56bc4173aae4975ded019ef5ab5a36249f1424df), secao A:
// D = |t-c|+1, sem SAVE ou escala dos tags N(c), N(t).
// Plano congelado: 0c2bad7393f4d66b77f884520f8ab6f5025feedd.
// Entrada: c,t inteiros arbitrarios; saida: cardinalidade do intervalo fechado.
// Oracle: limite superior exclusivo menos limite inferior.
// Modelo: transcricao algebrica da expressao Pascal, NAO execucao Pascal.
// Casos: igualdade, ordem, fundacao, limites binarios, M, base decimal 10^9,
// sinais opostos, transladacao e decomposicao de intervalo.
// A funcao de producao ComputeWorkCounts em dd3e5f2b e a939473f
// usa a mesma expressao; WorkCountsForContext delega para ela.
// O legado injetado Stage04 afeta Action/Target, nao Distance.
// Nenhum RED real identificado nesse caminho; gate Stage06 continua aberto.
// Executar: node docs/stage06_distance_tag_scale_preflight.js
function oracle(c,t){const lo=c<t?c:t,hi=c<t?t:c;return (hi+1n)-lo;}
function modelo(c,t){const d=t-c;return (d<0n?-d:d)+1n;}
function verificar(){const f=-15055671n,m=(1n<<127n)-1n;const anchors=[0n,1n,-1n,f,f-1n,f+1n,m,-m];for(const k of [31n,32n,63n,64n,127n,128n,255n,256n,512n]){const v=1n<<k;for(const d of [-1n,0n,1n]){anchors.push(v+d,-v+d)}}for(const k of [1n,2n,4n,8n,16n]){const v=1000000000n**k;for(const d of [-1n,0n,1n])anchors.push(v+d,-v+d)}const p=[...new Set(anchors)];let pairs=0,checks=0;function check(ok){checks++;if(!ok)throw Error("Falha de preflight");}for(const c of p)for(const t of p){const x=oracle(c,t);pairs++;check(x===modelo(c,t));check(x===oracle(t,c));check(x>=1n);check((x===1n)===(c===t));check(x===oracle(c+m,t+m));const lo=c<t?c:t,hi=c<t?t:c,mid=lo+(hi-lo)/2n;check(x===oracle(lo,mid)+oracle(mid,hi)-1n);}return {anchors:p.length,pairs,checks,failures:0};}
console.log(JSON.stringify(verificar()));
