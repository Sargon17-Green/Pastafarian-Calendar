:- begin_tests(stage01).
:- use_module(library(plunit)).
:- use_module(library(readutil)).

:- use_module('../src/source_language_catalog').
:- use_module('../src/normative_oracle').
:- use_module('../src/monster_bootstrap').
:- use_module(stage01_fixtures).

test(catalogo_version_conxelada) :-
    source_language_catalog_version('1.0.0').

test(catalogo_costeletas_completo) :-
    canonical_cutlet_indices(Indices),
    length(Indices, 17),
    cutlet_source_names(Names),
    length(Names, 17),
    sort(Names, Unique),
    length(Unique, 17).

test(catalogo_meses_completo) :-
    canonical_month_indices(Indices),
    length(Indices, 47),
    month_source_names(Names),
    length(Names, 47),
    sort(Names, Unique),
    length(Unique, 47).

test(catalogo_indices_exactos) :-
    canonical_cutlet_indices([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17]),
    canonical_month_indices([
        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,
        25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47
    ]).

test(m_normativo) :-
    expected_m(Expected),
    normative_m(Actual),
    assertion(Actual =:= Expected).

test(save_casos_fixos, [forall(expected_save_case(Input, Expected))]) :-
    save(Input, Actual),
    assertion(Actual =:= Expected).

test(contaxe_dia_casos_fixos, [forall(expected_day_count_case(Day, Expected))]) :-
    day_count(Day, Actual),
    assertion(Actual =:= Expected).

test(contaxes_traballo_casos_fixos,
     [forall(expected_work_counts_case(C,T,Expected))]) :-
    work_counts(C,T,Actual),
    assertion(Actual == Expected).

test(taboa_pedras_ten_46_filas) :-
    build_stones(Stones),
    length(Stones, 46).

test(segundo_estado_das_pedras) :-
    build_stones(Stones),
    nth1(2, Stones, Actual),
    expected_stone_row2(Expected),
    assertion(Actual == Expected).

test(permutacions_extremos,
     [forall(expected_permutation_case(Rank, Expected))]) :-
    bowl_order_from_number(Rank, Actual),
    assertion(Actual == Expected).

test(drop_multiplo_720_abre_rango_720) :-
    bowl_order_from_drop(720, Actual),
    assertion(Actual == [6,5,4,3,2,1]).

test(factorial_descendente_17_6) :-
    falling_factorial(17,6,Actual),
    expected_falling_factorial_17_6(Expected),
    assertion(Actual =:= Expected).

test(nomes_distintos_primeiro_rango) :-
    unrank_distinct_indices(6,1,Actual),
    assertion(Actual == [1,2,3,4,5,6]).

test(composicions_limitadas_contaxe) :-
    bounded_composition_count(5,2,1,4,Count),
    assertion(Count =:= 4).

test(composicions_limitadas_desrango,
     [forall(expected_bounded_case(Total,Slots,Lo,Hi,Rank,Expected))]) :-
    bounded_composition_unrank(Total,Slots,Lo,Hi,Rank,Actual),
    assertion(Actual == Expected).

test(tecido_2_1_contaxe) :-
    weaving_count([2,1], Count),
    assertion(Count =:= 1).

test(tecido_2_2_contaxe) :-
    weaving_count([2,2], Count),
    assertion(Count =:= 2).

test(tecidos_desrango,
     [forall(expected_weaving_case(Lengths,Rank,Expected))]) :-
    weaving_unrank(Lengths,Rank,Actual),
    assertion(Actual == Expected).

test(bootstrap_contexto_independente) :-
    monster_manager_execute(10,20,A),
    monster_manager_execute(10,20,B),
    assertion(A == B),
    assertion(A \== _Unbound).

test(bootstrap_rexeita_dia_non_entero) :-
    monster_manager_execute(day,20,Context),
    Context = monster_context(_,_,bootstrap,failed,authoritative,validation_error,
                              0,base_validator,none,_,_,_,invalid_day_input).

test(ownership_fallo_e_reintento_bootstrap) :-
    monster_manager_execute(10,20,Baseline),
    monster_manager_execute(day,20,Failed),
    Failed = monster_context(_,_,bootstrap,failed,authoritative,validation_error,
                             0,base_validator,none,_,_,_,invalid_day_input),
    monster_manager_execute(10,20,AfterFailure),
    assertion(AfterFailure == Baseline).

test(ownership_orde_chamadas_bootstrap) :-
    monster_manager_execute(10,20,A1),
    monster_manager_execute(-7,31,B1),
    monster_manager_execute(-7,31,B2),
    monster_manager_execute(10,20,A2),
    assertion(A1 == A2),
    assertion(B1 == B2).

test(ownership_memo_composicion_tras_fallo) :-
    bounded_composition_count(5,2,1,4,BaselineCount),
    \+ bounded_composition_unrank(5,2,1,4,99,_),
    bounded_composition_count(5,2,1,4,AfterCount),
    bounded_composition_unrank(5,2,1,4,3,AfterValue),
    assertion(BaselineCount =:= 4),
    assertion(AfterCount =:= BaselineCount),
    assertion(AfterValue == [3,2]).

test(ownership_memo_tecido_tras_fallo) :-
    weaving_count([2,2],BaselineCount),
    \+ weaving_unrank([2,2],99,_),
    weaving_count([2,2],AfterCount),
    weaving_unrank([2,2],2,AfterValue),
    assertion(BaselineCount =:= 2),
    assertion(AfterCount =:= BaselineCount),
    assertion(AfterValue == [1,2,1,2]).

test(ownership_orde_portas) :-
    ensure_gate_index(2,PFirst),
    ensure_gate_index(-2,NSecond),
    ensure_gate_index(-2,NFirst),
    ensure_gate_index(2,PSecond),
    assertion(PFirst =:= PSecond),
    assertion(NFirst =:= NSecond).


test(production_non_chama_oraculo, [throws(error(stage_not_available(54),_))]) :-
    calendar_date_spaghetti(10,20,_).

test(production_rexeita_entrada_invalida, [throws(error(invalid_day_input,_))]) :-
    calendar_date_spaghetti(non_integer,20,_).

test(salsa_determinista) :-
    foundation_day(F),
    sauce(F,F,A),
    sauce(F,F,B),
    assertion(A == B),
    A = sauce(Bowls,Order),
    length(Bowls,6),
    sort(Order,[1,2,3,4,5,6]).

test(distancia_porta_positiva_en_rango) :-
    reset_oracle_state,
    positive_gate_gap(1,Gap),
    assertion(Gap >= 42),
    assertion(Gap =< 963).

test(distancia_porta_negativa_en_rango) :-
    reset_oracle_state,
    negative_gate_gap(1,Gap),
    assertion(Gap >= 42),
    assertion(Gap =< 963).


:- end_tests(stage01).
