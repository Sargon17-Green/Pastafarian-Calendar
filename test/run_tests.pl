:- initialization(main, main).

main :-
    source_file(main, ThisFile),
    file_directory_name(ThisFile, TestDir),
    directory_file_path(TestDir, 'stage01_tests.pl', CoreFile),
    directory_file_path(TestDir, 'ownership_stage01_tests.pl', OwnershipFile),
    consult(CoreFile),
    consult(OwnershipFile),
    ( run_tests -> halt(0) ; halt(1) ).
