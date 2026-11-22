# Stage02 readiness: primeiros contadores de trabalho (Object Pascal + português)
Data: 2026-11-23
PROJECT_ID: PC-BRANCH-OBJECT-PASCAL-PORTUGUESE
Base validada antes desta preparação: Object-Pascal+Português @ 50db302e2588dcdbbae7ac5dad2ebfc0a9e8d2d4

## Âmbito e natureza da decisão
Não existe ainda neste ramo um contrato explícito do Stage02 nem um executor Stage02; DEVELOPMENT_STAGE.md ainda indica CURRENT_STAGE=1 e LAST_COMPLETED_STAGE=0 (metadados históricos, não a decisão posterior de aceitação Stage01). Esta proposta define apenas a primeira fatia verificável de preparação do Stage02: contadores determinísticos de dias/trabalhos. NÃO redefine, aceita nem conclui o Stage02 inteiro.

A decisão de aceitar o Stage01 com exceção de proveniência histórica foi registada em https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/37#issuecomment-7086296174 e permanece estritamente limitada ao SHA 50db302e2588dcdbbae7ac5dad2ebfc0a9e8d2d4. Os patches originais de 12–13 de outubro não foram autenticados. Não há autorização de merge/main/release.

## Origem normativa e fronteira de independência
Fundação F=-15055671, conforme constante FOUNDATION_DAY_DECIMAL no oráculo normativo local test/NormativeOracle.pas. A presente especificação matemática é implementada de novo por Python int, sem importar o código Pascal, sem ler resultados de outro ramo e sem copiar fixtures de outro ramo. O Pascal de produção futuro NÃO poderá invocar unidades de test nem valores gerados em tempo de execução pelo oráculo.

## Interface proposta e entradas
Entrada de cada caso: dois inteiros com sinal de precisão arbitrária (calculation_day, target_day), serializados em decimal ASCII canónico: 0 ou -?[1-9][0-9]*. Rejeitar sinal +, -0, espaços, zeros à esquerda, notação exponencial e campo vazio; o diagnóstico de erro deverá ser estável e sem coerção silenciosa. Os vetores abrangem magnitudes superiores a Int64 e 10^512: não converter pela rota Int64. Distinguir a interface de teste da API pública futura.

Saída: tuplo de cinco inteiros decimais canónicos (action, target, distance, connection, direction), sem dependência do idioma na semântica.

Define-se D(d):
- Se d < F: D(d)=2(F-d).
- Se d >= F: D(d)=2(d-F)+1.

Definir action=D(calculation_day); target=D(target_day); distance=abs(target_day-calculation_day)+1; connection=action+target; direction=1 se target_day<calculation_day, 2 se igual, 3 se maior.

Exemplos imutáveis (calculation_day,target_day => action,target,distance,connection,direction):
- F,F => 1,1,1,2,2
- F-1,F+1 => 2,3,3,5,3
- F+1,F-1 => 3,2,3,5,1
- F,F+3 => 1,7,4,8,3

## Vetores e oracle independente
O ficheiro docs/stage02_workcounts_oracle.py gera 96 pares dirigidos, todos distintos, em 6 grupos de 16: EQUAL, ADJACENT, FORWARD, REVERSE, INTEGER_BOUNDARY, HUGE. Em cada linha, verifica os cinco campos, positividade, identidade da distância, soma da ligação e relação de ordem. Verifica também 1.024 identidades nas 512 distâncias simétricas em torno de F, além de D(F)=1.

Execução local de preparação, NÃO Native nem CI:
python3 docs/stage02_workcounts_oracle.py --self-test
python3 docs/stage02_workcounts_oracle.py --emit /tmp/stage02_workcounts_vectors.tsv
python3 docs/stage02_workcounts_oracle.py --check /tmp/stage02_workcounts_vectors.tsv

Resultado observado antes do commit, Python 3 (2026-11-23): 96/96 linhas, 6 grupos x16, 1.024 identidades; py_compile PASS; emissor/verificador TSV PASS.
SHA256 dos bytes TSV (UTF-8, LF): 1a25f13aacd70d3cf23458d331c7a9148c5d749994099c2c9c9c4849ce674d12.
Os resultados acima certificam APENAS o oráculo gerador local, não a implementação Object Pascal.

## Limites e oráculos negativos
A implementação do Stage02 deverá verificar explícita e separadamente: F-1/F/F+1, 0, igualdade, inversão de direção, inteiros perto de +/-2^63, +/-2^127 e +/-2^255, valores até 10^512 e 2^1024, e as nove entradas inválidas: string vazia; '+'; '-0'; '01'; ' 1'; '1 '; '1.0'; '--1'; dígitos não ASCII. Não impor truncamento de inteiros. Caso haja limites operacionais de memória/tempo, documentá-los sem alterar a aritmética normativa.

## Portões exigidos antes de declarar Stage02 concluído
1. Código de produção Object Pascal criado no ramo autorizado, sem mudança em src/SourceLanguageCatalog.pas, CANONICAL_NAMES_LOCK.sha256 ou semântica de Stage01, com revisão explícita de ownership/contexto e exceções.
2. Teste Pascal de Stage02 separado, que leia os 96 TSV gerados independentemente e compare cada um dos cinco campos; teste os casos inválidos e as metamorfoses. As contagens observadas têm de aparecer no log por nome, não por estimativa.
3. Workflow Stage02 específico para execução Native com Free Pascal real; registo de commit SHA exato, FPC version, status e exit code por suite. Não reutilizar sucesso de Stage01 como Stage02.
4. CI concluído (não queued/in_progress) e Names Lock concluído no MESMO SHA; artefacto de log preservado e validado por SHA256/CRC, UTF-8 estrito e contagem independente. Qualquer differential deve usar um oráculo independente, não outra implementação como autoridade.
5. Só após estas provas e todos os requisitos adicionais aplicáveis pode haver decisão de aceitação integral Stage02; nenhum PASS parcial é aceitação.

## NEXT específico
Implementar a primeira função de produção de contagens no âmbito autorizado; preparar comparador Pascal-vs-TSV e workflow Stage02, executar e avaliar separadamente os gates. Não executar novamente Native de Stage01 no SHA histórico já aceite sem alteração de código que o justifique. Não fazer merge/main/release.
