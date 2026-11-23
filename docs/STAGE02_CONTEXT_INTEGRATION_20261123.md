# Stage02 — contrato da segunda fatia: integração isolada por contexto

PROJECT_ID: PC-BRANCH-OBJECT-PASCAL-PORTUGUESE
Parent locked at authoring: dd3e5f2b84e16c5232ad42d0486e9642622564dc
Status: implementação e ensaio pendentes de Native, NÃO aceitação do Stage02 inteiro.

## Problema e âmbito
A primeira fatia já calcula WorkCounts com inteiros ilimitados, mas o ponto de entrada
PastafariCalendar não expõe essa operação para uma invocação TMonsterContext.
Esta fatia adiciona somente WorkCountsForContext(Context), de leitura.
Não executa bootstrap, não muda as fases do manager e não importa qualquer oráculo na produção.

## Contrato
Entrada: Context do tipo TMonsterContext, com CalculationDay e TargetDay TBigInt
já construídos e possuídos pela instância. Para Context=nil, lançar Exception com
mensagem exata 'Contexto de invocação ausente.' (sem dereference).
Saída: TWorkCounts idêntico à especificação DayCount/WorkCounts da primeira fatia:
Action=D(A), Target=D(B), Distance=abs(B-A)+1, Connection=Action+Target e
Direction=1/2/3 segundo B<A/B=A/B>A, onde F=-15055671.
O retorno mantém os seus valores mesmo após alteração dos dias do contexto e
destruição do contexto; a operação não altera dias, Phase, Status, RetryBudget,
Metrics, Logs ou LastErrorCode.

## Oracle e portas mensuráveis
Reutiliza o TSV produzido pelo oráculo Python-int independente da primeira fatia,
com SHA256 canónico 1a25f13aacd70d3cf23458d331c7a9148c5d749994099c2c9c9c4849ce674d12,
96 pares dirigidos únicos, seis grupos de 16, até magnitudes 10^512/2^1024.
O novo test/stage02_context_integration.pas cria um contexto novo por caso e
executa 18 verificações/caso: cinco campos do oracle, duas invariâncias de input,
seis invariâncias de estado e cinco verificações de resultado depois de mutação
e destruição do contexto. Duas verificações adicionais validam exceção e
mensagem de Context=nil. Esperado: 96 casos, 1730/1730 checks, zero falhas, exit=0.
A verificação de entrada decimal inválida continua na suite independente existente
(nove classes rejeitadas), com 1449/1449 checks da primeira fatia.

A workflow Stage02 deve construir e executar ambas as suites em FPC 3.2.2,
após regenerar/comparar o TSV independente e verificar o SHA. Exigir run/job
completed SUCCESS no SHA exato, Names Lock completed SUCCESS no mesmo SHA,
log e artefacto ZIP íntegros (SHA256, CRC, UTF-8), contagens reais e códigos
de saída zero. Preflight estático, commit ou filas queued/in_progress NÃO são Native PASS.
Não reexecutar as três runs já aceites em dd3e5f2b sem motivo.

## Limites
Sem alteração de src/BigInt.pas, src/MonsterBootstrap.pas, nomes congelados,
oráculos normativos, branch main ou políticas de stage. Esta fatia não prova
o contrato completo do Stage02, nem autoriza merge, release ou mudança de etapa.
