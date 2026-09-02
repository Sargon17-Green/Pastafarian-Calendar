# Magila dos Tempos — Object Pascal / Delphi + português

Este diretório é um ramo de implementação iniciado do zero para o Stage 1. Não foi copiado, traduzido ou comparado com qualquer implementação noutra linguagem.

## Conteúdo do Bootstrap

`src/BigInt.pas` contém aritmética inteira de precisão arbitrária implementada diretamente em Object Pascal. `src/SourceLanguageCatalog.pas` contém o catálogo canónico congelado de 17 nomes de costeletas e 47 nomes de meses. `src/MonsterBootstrap.pas` fornece apenas a infraestrutura neutra permitida no Stage 1: contexto por invocação, gestor, dispatcher, validação e métricas não semânticas. `src/PastafariCalendar.pas` expõe apenas uma sonda de Bootstrap; não contém caminhos legacy nem patches futuros.

A referência de testes foi reconstruída localmente a partir do Appendix A. `test/NormativeOracle.pas` implementa a aritmética normativa, contagens de dias, pedras, gotas, taças, doze mexidas, consultas e seleção curta/larga. `test/NormativeFamilies.pas` implementa famílias ordenadas por contagem exata e unrank lexicográfico. `test/NormativeCalendarOracle.pas` monta portais, anos, costeletas, meses, tecelagem e a tupla final de cinco campos.

## Compilação prevista

É necessário Free Pascal 3.2.2 ou um compilador Delphi compatível. Para Free Pascal, a partir de `test`:

```text
fpc -B -Fu../src -Fu. -FE../build stage01_tests.pas
../build/stage01_tests
```

O comando de compilação e execução não contém lógica normativa; toda a computação do calendário está em Object Pascal.

## Estado desta entrega

A máquina em que esta entrega foi preparada não disponibilizou `fpc`, `dcc32` ou `dcc64`, e a instalação automática do compilador não foi possível porque a rede do ambiente de execução estava indisponível. Por isso, os testes ainda não foram executados aqui e o Stage 1 não deve ser marcado como concluído antes de uma compilação e execução reais.

Nenhuma ação Git ou GitHub foi executada.
