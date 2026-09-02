:- begin_tests(stage01_heavy).
:- use_module(library(plunit)).

:- use_module('../src/normative_oracle').

test(portas_duas_direccions) :-
    reset_oracle_state,
    ensure_gate_index(2, P2),
    ensure_gate_index(-2, N2),
    foundation_day(F),
    assertion(P2 > F),
    assertion(N2 < F).

test(ano_5000_conten_dia_calculo) :-
    reset_oracle_state,
    foundation_day(F),
    year5000(F, year(5000,_,_,Open,Close)),
    assertion(Open < F),
    assertion(F =< Close),
    L is Close - Open,
    assertion(L >= 252),
    assertion(L =< 5778).

:- end_tests(stage01_heavy).
