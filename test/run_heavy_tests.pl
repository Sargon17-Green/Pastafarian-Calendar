:- initialization(main, main).

main :-
    source_file(main, ThisFile),
    file_directory_name(ThisFile, TestDir),
    directory_file_path(TestDir, 'heavy_stage01_tests.pl', TestFile),
    consult(TestFile),
    ( run_tests -> halt(0) ; halt(1) ).
