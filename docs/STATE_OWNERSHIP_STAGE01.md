# Propiedade do estado no Stage 1

A propiedade do estado semántico foi revisada expresamente para o Bootstrap de Prolog.

O módulo de produción non declara predicados dinámicos, non usa `assert` nin `retract`, non usa variables globais non retrocedibles, non usa a base `recorded` e non emprega tabulación. Cada termo `monster_context` créase de novo para unha única chamada e transmítese por argumentos.

O oráculo tampouco conserva estado semántico entre chamadas. As memorias de programación dinámica das composicións limitadas, das particións de costeletas e do tecido de meses son estruturas `assoc` locais. Cada operación crea a súa raíz baleira e devolve novas versións por argumentos; non existe publicación global nin commit compartido.

O estado das portas segue o mesmo modelo. `new_gate_state/1` crea unha asociación nova coa porta cero e as operacións internas reciben e devolven explicitamente o estado seguinte. Unha chamada pública non deixa unha caché que poida ser lida pola chamada posterior.

`reset_oracle_state/0` queda como operación nula de compatibilidade interna das probas do Bootstrap. Non limpa nada porque xa non existe estado global do oráculo que limpar.

As probas de propiedade comproban catro grupos de invariantes: ausencia de predicados dinámicos, locais por fío ou tabulados; ausencia das primitivas de mutación global nos ficheiros Prolog do proxecto; estabilidade das variables globais non retrocedibles antes e despois de cálculos repetidos; e independencia observable en repeticións, orde A→B→A e fallo seguido de reintento.

Un fallo antes de completar un cálculo só descarta os termos locais alcanzables desde esa rama de Prolog. Non hai ningún `assert`, valor global, táboa, rexistro ou caché publicada que precise rollback. Por tanto, o último estado comprometido dunha invocación non é visible para outra invocación.
