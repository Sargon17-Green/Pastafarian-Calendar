:- module stage01_tests.
:- interface.

:- import_module io.

:- pred main(io::di, io::uo) is det.

:- implementation.

:- import_module bool.
:- import_module integer.
:- import_module list.
:- import_module maybe.
:- import_module monster_bootstrap.
:- import_module normative_reference.
:- import_module source_language_catalog.

:- pred report(string::in, bool::in, io::di, io::uo) is det.
report(Name, Passed, !IO) :-
    ( if Passed = yes then
        io.write_string("ТЭНЦСЭН: " ++ Name ++ "\n", !IO)
    else
        io.write_string("АЛДАА: " ++ Name ++ "\n", !IO),
        io.set_exit_status(1, !IO)
    ).

:- func z(int) = integer.
z(N) = integer(N).

:- func entry_indices(list(catalog_entry)) = list(int).
entry_indices([]) = [].
entry_indices([catalog_entry(I, _) | Rest]) = [I | entry_indices(Rest)].

:- func strings_nonempty(list(catalog_entry)) = bool.
strings_nonempty([]) = yes.
strings_nonempty([catalog_entry(_, S) | Rest]) =
    ( if S = "" then no else strings_nonempty(Rest) ).

:- func range_int(int, int) = list(int).
range_int(A, B) = ( if A > B then [] else [A | range_int(A + 1, B)] ).

:- func list_eq_z(list(int), list(int)) = bool.
list_eq_z(A, B) = ( if A = B then yes else no ).

main(!IO) :-
    MExpected = integer.det_from_string("170141183460469231731687303715884105727"),
    report("их тоолуур M", (if big_m = MExpected then yes else no), !IO),
    report("шаврын өдөр ба суурийн өдрийн зөрүү",
        (if tablets_day - foundation_day = z(14777149) then yes else no), !IO),

    M = big_m,
    report("SAVE(M)=M", (if save(M) = M then yes else no), !IO),
    report("SAVE(2M)=M", (if save(z(2) * M) = M then yes else no), !IO),
    report("SAVE(M+1)=1", (if save(M + z(1)) = z(1) then yes else no), !IO),
    report("SAVE(1)=1", (if save(z(1)) = z(1) then yes else no), !IO),

    F = foundation_day,
    report("суурийн өдрийн тоо 1", (if day_count(F) = z(1) then yes else no), !IO),
    report("сууриас өмнөх өдөр тэгш тоотой",
        (if day_count(F - z(1)) = z(2) then yes else no), !IO),
    report("сууриас хойших өдөр сондгой тоотой",
        (if day_count(F + z(1)) = z(3) then yes else no), !IO),

    work_counts_for(F - z(3), F + z(4)) = work_counts(_, _, Distance, _, Direction),
    report("он цагийн зай", (if Distance = z(8) then yes else no), !IO),
    report("чиглэл 3", (if Direction = z(3) then yes else no), !IO),

    Stones = build_stones,
    Stone2 = list.det_index1(Stones, 2),
    report("чулууны хүснэгтийн урт", (if list.length(Stones) = 46 then yes else no), !IO),
    report("хоёр дахь чулуу зэрэгцээ snapshot-аас",
        (if Stone2 = stone5(z(378), z(1073), z(2375), z(6195), z(10493)) then yes else no), !IO),

    report("хязгаартай композици тоолох",
        (if count_bounded_compositions(12, 2, 4, 8) = z(5) then yes else no), !IO),
    report("хязгаартай композици rank 3",
        list_eq_z(unrank_bounded_composition(12, 2, 4, 8, z(3)), [6,6]), !IO),
    report("дотоод хаалгатай котлетын хуваалт",
        (if count_cutlet_partitions(5, 2, yes(2)) = z(1) then yes else no), !IO),
    report("дотоод хаалгатай котлетын unrank",
        list_eq_z(unrank_cutlet_partition(5, 2, yes(2), z(1)), [2,3]), !IO),

    report("[2,2] сарын сүлжээс хоёр янз",
        (if count_weavings([2,2]) = z(2) then yes else no), !IO),
    report("сүлжээс rank 1",
        list_eq_z(unrank_weaving([2,2], z(1)), [1,1,2,2]), !IO),
    report("сүлжээс rank 2",
        list_eq_z(unrank_weaving([2,2], z(2)), [1,2,1,2]), !IO),

    Cutlets = cutlet_entries,
    Months = month_entries,
    report("17 котлетын нэр", (if list.length(Cutlets) = 17 then yes else no), !IO),
    report("47 сарын нэр", (if list.length(Months) = 47 then yes else no), !IO),
    report("котлетын canonicalIndex дараалал",
        list_eq_z(entry_indices(Cutlets), range_int(1, 17)), !IO),
    report("сарын canonicalIndex дараалал",
        list_eq_z(entry_indices(Months), range_int(1, 47)), !IO),
    report("котлетын бүх эх мөр хоосон биш", strings_nonempty(Cutlets), !IO),
    report("сарын бүх эх мөр хоосон биш", strings_nonempty(Months), !IO),
    report("каталог хөлдсөн", (if catalog_is_frozen then yes else no), !IO),

    Ctx0 = new_context(F, F),
    Dispatch = base_dispatch(Ctx0),
    report("саармаг bootstrap dispatcher",
        (if Dispatch = dispatch_ok(Ctx), validate_bootstrap_context(Ctx) then yes else no), !IO),

    S1 = sauce(F, F),
    S2 = sauce(F, F),
    report("oracle sauce детерминист",
        (if S1 = S2 then yes else no), !IO),
    S1 = sauce_result(Bowls, Order),
    report("oracle sauce зургаан аягатай", (if list.length(Bowls) = 6 then yes else no), !IO),
    report("oracle sauce зургаан байрлалтай latch", (if list.length(Order) = 6 then yes else no), !IO),

    io.write_string("Stage 1-ийн Mercury шалгалтууд дууслаа.\n", !IO).
