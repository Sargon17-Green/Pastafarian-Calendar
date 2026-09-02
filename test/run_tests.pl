:- initialization(main, main).

main :-
    consult('stage01_tests.pl'),
    ( run_tests -> halt(0) ; halt(1) ).
