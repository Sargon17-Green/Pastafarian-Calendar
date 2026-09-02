:- begin_tests(stage01_ownership).
:- use_module(library(plunit)).
:- use_module(library(readutil)).
:- use_module(library(apply)).

:- use_module('../src/source_language_catalog').
:- use_module('../src/normative_oracle').
:- use_module('../src/monster_bootstrap').
:- use_module(stage01_fixtures).

test(non_hai_predicados_dinamicos_do_proxecto) :-
    forall(project_module(Module),
           forall(project_defined_predicate(Module, Head),
                  \+ predicate_property(Module:Head, dynamic))).

test(non_hai_predicados_thread_local_do_proxecto) :-
    forall(project_module(Module),
           forall(project_defined_predicate(Module, Head),
                  \+ predicate_property(Module:Head, thread_local))).

test(non_hai_predicados_tabulados_do_proxecto) :-
    forall(project_module(Module),
           forall(project_defined_predicate(Module, Head),
                  \+ predicate_property(Module:Head, tabled))).

test(non_aparecen_primitivas_de_estado_global_nos_ficheiros_prolog) :-
    project_prolog_files(Files),
    forall(member(File, Files), source_without_forbidden_state(File)).

test(bootstrap_fallo_reintento_non_deixa_estado) :-
    monster_manager_execute(10,20,Baseline),
    monster_manager_execute(non_integer,20,Failed),
    Failed = monster_context(_,_,bootstrap,failed,authoritative,validation_error,
                             0,base_validator,none,_,_,_,invalid_day_input),
    monster_manager_execute(10,20,After),
    assertion(After == Baseline).

test(oraculo_fallo_reintento_non_deixa_estado) :-
    foundation_day(F),
    sauce(F,F,Baseline),
    catch(sauce(non_integer,F,_), _, true),
    sauce(F,F,After),
    assertion(After == Baseline).

test(oraculo_orde_a_b_a_independente) :-
    foundation_day(F),
    T2 is F + 1,
    sauce(F,F,A1),
    sauce(F,T2,B1),
    sauce(F,F,A2),
    sauce(F,T2,B2),
    assertion(A1 == A2),
    assertion(B1 == B2).

test(non_backtrackable_globals_non_medran_por_calculo) :-
    foundation_day(F),
    sauce(F,F,_),
    nb_names(Before),
    sauce(F,F,_),
    monster_manager_execute(F,F,_),
    nb_names(After),
    assertion(After == Before).

project_module(source_language_catalog).
project_module(normative_oracle).
project_module(monster_bootstrap).
project_module(stage01_fixtures).
project_module(plunit_stage01).
project_module(plunit_stage01_ownership).

project_defined_predicate(Module, Head) :-
    current_predicate(Module:Head),
    predicate_property(Module:Head, file(_)),
    \+ predicate_property(Module:Head, imported_from(_)).

nb_names(Names) :-
    findall(Name, nb_current(Name,_), Raw),
    sort(Raw, Names).

project_prolog_files(Files) :-
    source_file(project_prolog_files(_), ThisFile),
    file_directory_name(ThisFile, TestDir),
    file_directory_name(TestDir, Root),
    directory_file_path(Root, src, SrcDir),
    prolog_files_in_dir(SrcDir, SrcFiles),
    prolog_files_in_dir(TestDir, TestFiles),
    append(SrcFiles, TestFiles, Files).

prolog_files_in_dir(Dir, Files) :-
    directory_files(Dir, Entries),
    findall(Path,
        ( member(Name, Entries),
          file_name_extension(_, pl, Name),
          directory_file_path(Dir, Name, Path),
          exists_file(Path)
        ),
        Files).

source_without_forbidden_state(File) :-
    read_file_to_string(File, Text, []),
    forbidden_state_tokens(Tokens),
    forall(member(Token, Tokens), \+ sub_string(Text,_,_,_,Token)).

forbidden_state_tokens(Tokens) :-
    maplist(call_token,
        [asserta,assertz,assert,retract,retractall,nb_setval,nb_getval,
         b_setval,b_getval,recorda,recordz,recorded,erase,abolish_all_tables],
        CallTokens),
    atomic_list_concat([':-',' dynamic'], DynamicSpaced),
    atomic_list_concat([':-','dynamic'], DynamicTight),
    atomic_list_concat([':-',' table'], TableSpaced),
    atomic_list_concat([':-','table'], TableTight),
    atomic_list_concat([':-',' thread_local'], ThreadSpaced),
    atomic_list_concat([':-','thread_local'], ThreadTight),
    append([DynamicSpaced,DynamicTight,TableSpaced,TableTight,
            ThreadSpaced,ThreadTight|CallTokens], [], Tokens).

call_token(Name, Token) :-
    atom_concat(Name, '(', Token).

:- end_tests(stage01_ownership).
