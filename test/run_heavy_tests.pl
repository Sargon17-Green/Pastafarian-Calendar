:- initialization(main, main).

main :-
    consult('heavy_stage01_tests.pl'),
    ( run_tests -> halt(0) ; halt(1) ).
