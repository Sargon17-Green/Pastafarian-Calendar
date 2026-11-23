# Stage02 — auditoria dos limites ainda não cobertos (Object Pascal + português)

Data: 2026-11-23
PROJECT_ID: PC-BRANCH-OBJECT-PASCAL-PORTUGUESE
SOURCE_SHA_AUDITED: 18f9650c27593ccd99b4a2b9b22ca9df8477b918
Natureza: auditoria estática e contrato de ensaio da próxima fatia, NÃO execução Native, NÃO aceitação integral do Stage02.

## Base verificada

No ramo autorizado, foram lidos os ficheiros `docs/STAGE02_WORKCOUNTS_READINESS_20261123.md`, `docs/STAGE02_CONTEXT_INTEGRATION_20261123.md`, `src/Stage02WorkCounts.pas`, `src/PastafariCalendar.pas`, `src/MonsterBootstrap.pas`, `src/BigInt.pas`, `test/stage02_workcounts_regression.pas`, `test/stage02_context_integration.pas` e `test/build_and_run_stage02_workcounts.sh`.
A integração atual expõe `WorkCountsForContext(Context)`; rejeita `nil` antes do acesso aos campos, calcula através de `ComputeWorkCounts` e não invoca `TMonsterManager` nem altera explicitamente o contexto.
`TMonsterContext.Create` clona os dois `TBigInt`; `ExecuteBootstrap` valida o contexto, atualiza fase/estado, acrescenta métricas e um log de dispatch. `BootstrapProbe` cria e liberta contexto/manager.

Evidência existente — exclusivamente fatias já aceites, não um novo PASS:
- Stage02 run 45087313533 / job 137408761163, Stage01 run 45087313708 / job 137408762048, Names Lock run 45087313643 / job 137408761518: todos `completed/success`, tentativa 1 e `head_sha` igual ao SHA auditado.
- Log Native Stage02: FPC 3.2.2, `STAGE02_CASES=96`, `STAGE02_TOTAL_CHECKS_PASSED=1449`, `STAGE02_CONTEXT_CASES=96`, `STAGE02_CONTEXT_TOTAL_CHECKS_PASSED=1730`, falhas zero, `STAGE02_EXIT=0`.
- ZIP Stage02 14779934546: digest API `sha256:ca9dc8a5f0094772f2ed71394276e011ee915fdeaffcdb7b7224f76b2b9ad508`; ZIP Stage01 14780346795: `sha256:9f9480f1119e3a274656302e38caeb68a13a372a0ed1caf6b73514fff5d34f97`. Os hashes ZIP/CRC/UTF-8 detalhados foram anteriormente verificados e registados no censo; esta auditoria NÃO repete a descarga nem converte metadados de artefactos em verificação de bytes.

## Inventário de fronteiras ainda não ensaiadas por estas duas suites

1. Entrada no estado inicial: coberta pelos 96 casos da suite de contexto (`mpEntry`, `msNew`, arrays vazios, retry 0, erro vazio); não cobre `WorkCountsForContext` depois de `ExecuteBootstrap`.
2. Estado do manager: `ExecuteBootstrap` produz `mpCompleted/msCompleted`, métricas `bootstrap.calls=1` e `bootstrap.completed=1`, e log `bootstrap:dispatch`; o teste Stage02 atual não verifica se a leitura posterior preserva estes valores.
3. Estados não iniciais: não há teste de pureza da leitura quando `Phase/Status`, `RetryBudget`, `Metrics`, `Logs` e `LastErrorCode` contêm sentinelas. O código não os consulta, mas falta prova de regressão.
4. Exceções: `WorkCountsForContext(nil)` já tem duas verificações (rejeição + texto exato). `TMonsterManager.ExecuteBootstrap(nil)`, construtor e libertação em caso de falha não são exercitados por estas duas suites. Não se inferiu defeito a partir dessa ausência.
5. Ownership: há cinco verificações de resultado após mutação e libertação do contexto por vetor, mas não há teste explícito de clonagem profunda dos argumentos do construtor antes da leitura. A API aceita um `TMonsterContext` válido; tratamento de estruturas `TBigInt` deliberadamente corrompidas não faz parte deste contrato.
6. `DEVELOPMENT_STAGE.md` ainda contém metadados históricos de Stage01. Não os alterar nesta fatia; o estado de aceitação exige evidência e decisão próprias.

## Contrato mensurável proposto: terceira fatia de QA, sem mudar produção

**Entradas:** as mesmas 96 linhas TSV geradas pelo Python-int independente, em seis grupos de 16, SHA256 `1a25f13aacd70d3cf23458d331c7a9148c5d749994099c2c9c9c4849ce674d12`. Para cada par decimal canónico A/B, criar contextos independentes para dois caminhos:

- **MANAGER_COMPLETED:** criar `TMonsterContext(A,B)`, chamar `TMonsterManager.ExecuteBootstrap` uma vez, e verificar previamente `mpCompleted/msCompleted`, retry 0, duas métricas exatas (nomes/valores 1), um log `bootstrap:dispatch` e erro vazio.
- **FAILED_SENTINEL:** criar novo contexto e definir deliberadamente `mpFailed/msFailed`, retry 7, duas métricas sentinela, log sentinela e `LastErrorCode='E_TEST'`. Este caminho testa APENAS invariância de leitura sobre estado sintético; NÃO simula uma exceção real no manager.

**Saída e oráculo:** `WorkCountsForContext` devolve as cinco strings decimais do TSV (action/target/distance/connection/direction). Comparar com o oracle independente, não com a própria `ComputeWorkCounts` nem fixtures vindos de outros ramos. Para cada contexto/caminho, realizar exatamente **19 verificações**: cinco campos vs TSV; dois dias de entrada intactos; seis componentes de estado intactos (phase, status, retry, conteúdo completo de metrics, conteúdo completo de logs e LastErrorCode); cinco campos do resultado ainda intactos após sobrescrever os dias do contexto e libertar o contexto; uma verificação explícita do estado de pré-condição do caminho. Tomar snapshots profundos dos arrays para impedir falsos positivos por aliasing.

**Negativos adicionais:** duas verificações para `WorkCountsForContext(nil)` (exceção e mensagem literal); duas para `ExecuteBootstrap(nil)` (exceção e mesma mensagem literal); duas verificações de clonagem profunda dos argumentos A e B do construtor, alterando os dígitos dos argumentos originais DEPOIS de criar o contexto e verificando que os valores internos continuam inalterados. Casos inválidos de texto decimal mantêm-se na suite anterior, 9/9, sem duplicação de um gate já aceite.

**Limiar observável:** `96 × 2 × 19 + 2 + 2 + 2 = 3654` checks esperados; 96 pares únicos, 192 contextos independentes para os dois caminhos; 0 falhas; exit=0; FPC real 3.2.2; log de contagens e erros com rótulos estáveis. As seis verificações negativas/ownership têm contador separado dos 3648 checks de matriz. Ausência do log, saída parcial, divergência de TSV ou qualquer exceção inesperada reprova esta fatia.

**Regras de execução/aceitação:** criar um teste Pascal novo e integrar no workflow Stage02 existente, sem criar um novo stage nem alterar Stage01, `src/BigInt.pas`, `src/MonsterBootstrap.pas`, `src/SourceLanguageCatalog.pas`, `CANONICAL_NAMES_LOCK.sha256`, oracle normativo, política ou main. Após implementação autorizada, exigir num novo SHA: run/job `completed/success`, FPC/exit, 3654 checks reais e 0 falhas, Names Lock no mesmo SHA, ZIP de evidência com digest/CRC/UTF-8 e comparação independente. Não duplicar as execuções já aceites no SHA anterior. O resultado desta auditoria é **contrato estático**, não CI/Native/differential PASS.

## Limites explicitamente adiados

Não se reivindica segurança concorrente, proteção contra ponteiro pendente, recuperação de falhas do alocador, nem completude do Stage02. Uma eventual injeção de falhas reais em `TMonsterManager.Create`/`ExecuteBootstrap` precisaria de interface de teste específica e revisão separada antes de mudar produção. Não fazer merge, publicação nem promoção de estágio.
