:- module normative_reference.
:- interface.

:- import_module integer.
:- import_module list.
:- import_module maybe.

:- type z == integer.

:- type work_counts
    --->    work_counts(z, z, z, z, z).

:- type stone5
    --->    stone5(z, z, z, z, z).

:- type sauce_result
    --->    sauce_result(list(z), list(int)).

:- type answer_stream
    --->    answer_stream(z, int).

:- type date5
    --->    date5(z, string, z, string, int).

:- func big_m = z.
:- func foundation_day = z.
:- func tablets_day = z.
:- func regular_mod(z, z) = z.
:- func save(z) = z.
:- func day_count(z) = z.
:- func work_counts_for(z, z) = work_counts.
:- func build_stones = list(stone5).
:- func sauce(z, z) = sauce_result.
:- func ask_bowl(sauce_result, int, int) = answer_stream.
:- func answer_at(answer_stream, z) = z.
:- func choose_rank(answer_stream, z) = z.
:- func falling_factorial(int, int) = z.
:- func unrank_distinct_indices(int, int, z) = list(int).
:- func count_bounded_compositions(int, int, int, int) = z.
:- func unrank_bounded_composition(int, int, int, int, z) = list(int).
:- func count_cutlet_partitions(int, int, maybe(int)) = z.
:- func unrank_cutlet_partition(int, int, maybe(int), z) = list(int).
:- func count_weavings(list(int)) = z.
:- func unrank_weaving(list(int), z) = list(int).
:- func calendar_date(z, z) = date5.

:- implementation.

:- import_module bool.
:- import_module map.
:- import_module require.

:- import_module source_language_catalog.

big_m = integer.pow(integer(2), integer(127)) - integer.one.
foundation_day = integer(-15055671).
tablets_day = integer(-278522).

regular_mod(X, D) = X mod D.

save(X) = integer.one + regular_mod(X - integer.one, big_m).

:- func zabs(z) = z.
zabs(X) = ( if X < integer.zero then -X else X ).

:- func zmin(z, z) = z.
zmin(A, B) = ( if A =< B then A else B ).

:- func ceil_div_nonneg(z, z) = z.
ceil_div_nonneg(A, B) = (A + B - integer.one) div B.

day_count(Day) = Result :-
    F = foundation_day,
    ( if Day = F then
        Result = integer.one
    else if Day > F then
        Result = integer(2) * (Day - F) + integer.one
    else
        Result = integer(2) * (F - Day)
    ).

work_counts_for(CDay, TDay) = work_counts(Action, Target, Distance, Connection, Direction) :-
    Action = day_count(CDay),
    Target = day_count(TDay),
    Distance = zabs(TDay - CDay) + integer.one,
    Connection = Action + Target,
    ( if TDay < CDay then
        Direction = integer.one
    else if TDay = CDay then
        Direction = integer(2)
    else
        Direction = integer(3)
    ).

:- func stone_w(stone5) = z.
:- func stone_b(stone5) = z.
:- func stone_s(stone5) = z.
:- func stone_m(stone5) = z.
:- func stone_r(stone5) = z.
stone_w(stone5(W, _, _, _, _)) = W.
stone_b(stone5(_, B, _, _, _)) = B.
stone_s(stone5(_, _, S, _, _)) = S.
stone_m(stone5(_, _, _, M, _)) = M.
stone_r(stone5(_, _, _, _, R)) = R.

:- func next_stone(int, stone5) = stone5.
next_stone(I, Old) = stone5(NW, NB, NS, NM, NR) :-
    ZI = integer(I),
    W = stone_w(Old), B = stone_b(Old), S = stone_s(Old),
    Mm = stone_m(Old), R = stone_r(Old),
    NW = save(W * W + integer(3) * B + ZI),
    NB = save(B * B + integer(5) * S + W),
    NS = save(S * S + integer(7) * Mm + B),
    NM = save(Mm * Mm + integer(11) * R + S),
    NR = save(R * R + integer(13) * W + Mm).

build_stones = build_stones_loop(2, stone5(integer(17), integer(29), integer(43), integer(71), integer(101)),
    [stone5(integer(17), integer(29), integer(43), integer(71), integer(101))]).

:- func build_stones_loop(int, stone5, list(stone5)) = list(stone5).
build_stones_loop(I, Current, Acc) = Out :-
    ( if I > 46 then
        Out = Acc
    else
        Next = next_stone(I, Current),
        Out = build_stones_loop(I + 1, Next, Acc ++ [Next])
    ).

:- func at1(list(T), int) = T.
at1(L, I) = list.det_index1(L, I).

:- func hidden_coeff(int) = {int, int, int, int}.
hidden_coeff(1) = {3,4,6,8}.
hidden_coeff(2) = {5,7,10,12}.
hidden_coeff(3) = {7,10,14,16}.
hidden_coeff(4) = {9,13,18,20}.
hidden_coeff(5) = {11,16,22,24}.
hidden_coeff(6) = {13,19,26,28}.
hidden_coeff(_) = {15,22,30,32}.

:- func stone_by_kind(stone5, int) = z.
stone_by_kind(S, K) = X :-
    ( if K = 1 then X = stone_w(S)
    else if K = 2 then X = stone_b(S)
    else if K = 3 then X = stone_s(S)
    else if K = 4 then X = stone_m(S)
    else X = stone_r(S)
    ).

:- func hidden_grind_kind(int) = int.
hidden_grind_kind(1) = 1.
hidden_grind_kind(2) = 2.
hidden_grind_kind(3) = 3.
hidden_grind_kind(4) = 4.
hidden_grind_kind(5) = 5.
hidden_grind_kind(6) = 1.
hidden_grind_kind(_) = 2.

:- func make_hidden(int, work_counts, list(stone5)) = z.
make_hidden(K, work_counts(Action, Target, Distance, Connection, Direction), Stones) = Result :-
    {A0,B0,C0,D0} = hidden_coeff(K),
    S = at1(Stones, K),
    X0 = Action + integer(A0) * Target + integer(B0) * Distance +
        integer(C0) * Connection + integer(D0) * Direction +
        stone_w(S) + stone_b(S) + stone_s(S) + stone_m(S) + stone_r(S),
    Result = hidden_grind_loop(1, save(X0), S).

:- func hidden_grind_loop(int, z, stone5) = z.
hidden_grind_loop(G, X, S) = Result :-
    ( if G > 7 then
        Result = X
    else
        K = hidden_grind_kind(G),
        Next = save(X * X + integer(3) * X + stone_by_kind(S, K) + integer(G)),
        Result = hidden_grind_loop(G + 1, Next, S)
    ).

:- func build_hidden(work_counts, list(stone5)) = list(z).
build_hidden(Counts, Stones) = [
    make_hidden(1, Counts, Stones), make_hidden(2, Counts, Stones),
    make_hidden(3, Counts, Stones), make_hidden(4, Counts, Stones),
    make_hidden(5, Counts, Stones), make_hidden(6, Counts, Stones),
    make_hidden(7, Counts, Stones)
].

:- type grind_row ---> grind_row(int, int, int, int, int).

:- func visible_grinds = list(grind_row).
visible_grinds = [
    grind_row(3,5,7,11,1), grind_row(5,7,11,13,2),
    grind_row(7,11,13,17,3), grind_row(11,13,17,19,4),
    grind_row(13,17,19,23,5), grind_row(17,19,23,29,1),
    grind_row(19,23,29,31,2), grind_row(23,29,31,37,3),
    grind_row(29,31,37,41,4), grind_row(31,37,41,43,5),
    grind_row(37,41,43,47,1)
].

:- func prior_value(list(z), list(z), int, int) = z.
prior_value(Visible, Hidden, I, Back) = Value :-
    Slot = I - Back,
    ( if Slot >= 1 then
        Value = at1(Visible, Slot)
    else
        Value = at1(Hidden, 1 - Slot)
    ).

:- func visible_grind_loop(int, z, z, z, z, stone5) = z.
visible_grind_loop(G, X, P1, P3, P7, S) = Result :-
    ( if G > 11 then
        Result = X
    else
        grind_row(A,B,C,D,K) = at1(visible_grinds, G),
        Next = save(X * X + integer(A) * X + integer(B) * P1 +
            integer(C) * P3 + integer(D) * P7 + stone_by_kind(S, K)),
        Result = visible_grind_loop(G + 1, Next, P1, P3, P7, S)
    ).

:- func one_visible(int, work_counts, list(stone5), list(z), list(z)) = z.
one_visible(I, work_counts(Action,Target,Distance,Connection,Direction), Stones, Hidden, Visible) = Result :-
    P1 = prior_value(Visible, Hidden, I, 1),
    P3 = prior_value(Visible, Hidden, I, 3),
    P7 = prior_value(Visible, Hidden, I, 7),
    S = at1(Stones, I),
    X0 = save(stone_w(S) * Action + stone_b(S) * Target + stone_s(S) * Distance +
        stone_m(S) * Connection + stone_r(S) * Direction + P1 + integer(3) * P3 +
        integer(5) * P7 + integer(I)),
    Result = visible_grind_loop(1, X0, P1, P3, P7, S).

:- func build_visible(int, work_counts, list(stone5), list(z), list(z)) = list(z).
build_visible(I, Counts, Stones, Hidden, Acc) = Result :-
    ( if I > 46 then
        Result = Acc
    else
        X = one_visible(I, Counts, Stones, Hidden, Acc),
        Result = build_visible(I + 1, Counts, Stones, Hidden, Acc ++ [X])
    ).

:- func factorial(int) = int.
factorial(N) = ( if N =< 1 then 1 else N * factorial(N - 1) ).

:- func remove_nth(list(T), int) = list(T).
remove_nth(L, I) = Out :-
    ( if list.delete_nth(L, I, Deleted) then Out = Deleted else Out = L ).

:- func permutation_unrank0(int, list(int)) = list(int).
permutation_unrank0(Rank0, Items) = Result :-
    ( if Items = [] then
        Result = []
    else
        N = list.length(Items),
        Block = factorial(N - 1),
        Q = Rank0 // Block,
        R = Rank0 mod Block,
        Chosen = at1(Items, Q + 1),
        Result = [Chosen | permutation_unrank0(R, remove_nth(Items, Q + 1))]
    ).

:- func bowl_order_from_drop(z) = list(int).
bowl_order_from_drop(Drop) = Order :-
    RankZ = regular_mod(Drop - integer.one, integer(720)) + integer.one,
    Rank = integer.det_to_int(RankZ),
    Order = permutation_unrank0(Rank - 1, [1,2,3,4,5,6]).

:- func wrap1(int, int) = int.
wrap1(P, Size) = ((P - 1) mod Size + Size) mod Size + 1.

:- func initial_bowls(work_counts) = list(z).
initial_bowls(Counts) = initial_bowls_loop(1, Counts, []).

:- func initial_bowls_loop(int, work_counts, list(z)) = list(z).
initial_bowls_loop(Id, work_counts(Action,Target,Distance,Connection,Direction), Acc) = Result :-
    ( if Id > 6 then
        Result = Acc
    else
        Prime = at1([17,19,23,29,31,37], Id),
        S = Action + Target * integer(Id) + Distance + Connection + Direction +
            integer(Prime * Prime),
        B = save(S * S + integer(Id)),
        Result = initial_bowls_loop(Id + 1,
            work_counts(Action,Target,Distance,Connection,Direction), Acc ++ [B])
    ).

:- func make_pours(int, z, stone5, list(z), list(int)) = list(z).
make_pours(I, Drop, S, Old, Order) = [P1,P2,P3,integer.zero,integer.zero,integer.zero] :-
    Id1 = at1(Order,1), Id2 = at1(Order,2), Id3 = at1(Order,3),
    P1 = save(Drop * Drop + stone_w(S) * at1(Old,Id1) + integer(3 * I)),
    P2 = save(Drop * Drop + stone_b(S) * at1(Old,Id2) + integer(5 * I)),
    P3 = save(Drop * Drop + stone_s(S) * at1(Old,Id3) + integer(7 * I)).

:- func stir_drop_positions(int, int, z, stone5, list(z), list(int), list(z), list(z)) = list(z).
stir_drop_positions(Pos, I, Drop, S, Old, Order, Pours, Pending) = Result :-
    ( if Pos > 6 then
        Result = Pending
    else
        Id = at1(Order, Pos),
        Prev = at1(Order, wrap1(Pos - 1, 6)),
        Next = at1(Order, wrap1(Pos + 1, 6)),
        StoneKind = at1([1,2,3,4,5,1], Pos),
        Mix = at1(Old,Id) + integer(2) * at1(Old,Prev) + integer(3) * at1(Old,Next) +
            at1(Pours,Pos) + Drop + stone_by_kind(S,StoneKind),
        NewVal = save(Mix * Mix + integer(5) * at1(Old,Prev) * at1(Old,Next) + integer(I * Pos)),
        NextPending = list.det_replace_nth(Pending, Id, NewVal),
        Result = stir_drop_positions(Pos + 1, I, Drop, S, Old, Order, Pours, NextPending)
    ).

:- func apply_visible_to_bowls(int, list(z), list(stone5), list(z), list(int)) = {list(z), list(int)}.
apply_visible_to_bowls(I, Visible, Stones, Bowls, LastOrder) = Result :-
    ( if I > 46 then
        Result = {Bowls, LastOrder}
    else
        Drop = at1(Visible,I), S = at1(Stones,I), Order = bowl_order_from_drop(Drop),
        Old = Bowls, Pours = make_pours(I,Drop,S,Old,Order),
        Pending0 = [integer.zero,integer.zero,integer.zero,integer.zero,integer.zero,integer.zero],
        NextBowls = stir_drop_positions(1,I,Drop,S,Old,Order,Pours,Pending0),
        Result = apply_visible_to_bowls(I + 1, Visible, Stones, NextBowls, Order)
    ).

:- func post_stir_positions(int, int, z, list(z), list(int), list(z)) = list(z).
post_stir_positions(Pos, Stir, SavedSum, Old, Order, Pending) = Result :-
    ( if Pos > 6 then
        Result = Pending
    else
        Id = at1(Order,Pos), Prev = at1(Order,wrap1(Pos - 1,6)), Next = at1(Order,wrap1(Pos + 1,6)),
        S = at1(Old,Id) + integer(3) * at1(Old,Prev) + integer(5) * at1(Old,Next) +
            SavedSum + integer(Stir) + integer(Pos * Pos),
        V = save(S * S + integer(7) * at1(Old,Prev) * at1(Old,Next)),
        Result = post_stir_positions(Pos + 1, Stir, SavedSum, Old, Order,
            list.det_replace_nth(Pending, Id, V))
    ).

:- func post_stirs(int, list(z)) = list(z).
post_stirs(Stir, Bowls) = Result :-
    ( if Stir > 12 then
        Result = Bowls
    else
        Raw = list.foldl((func(X, A) = X + A), Bowls, integer.zero),
        Saved = save(Raw + integer(149 * Stir)),
        RankZ = regular_mod(Saved - integer.one, integer(720)) + integer.one,
        Order = permutation_unrank0(integer.det_to_int(RankZ) - 1, [1,2,3,4,5,6]),
        P0 = [integer.zero,integer.zero,integer.zero,integer.zero,integer.zero,integer.zero],
        Next = post_stir_positions(1,Stir,Saved,Bowls,Order,P0),
        Result = post_stirs(Stir + 1, Next)
    ).

sauce(CDay, TDay) = sauce_result(Final, Order46) :-
    Counts = work_counts_for(CDay,TDay),
    Stones = build_stones,
    Hidden = build_hidden(Counts,Stones),
    Visible = build_visible(1,Counts,Stones,Hidden,[]),
    Initial = initial_bowls(Counts),
    {AfterDrops,Order46} = apply_visible_to_bowls(1,Visible,Stones,Initial,[1,2,3,4,5,6]),
    Final = post_stirs(1,AfterDrops).

:- func next_bowl(list(int), int) = int.
next_bowl(Order, Queried) = Next :-
    Pos = list.det_index1_of_first_occurrence(Order, Queried),
    Next = at1(Order, wrap1(Pos + 1, 6)).

ask_bowl(sauce_result(Bowls,Order), Queried, Seal) = answer_stream(First,Step) :-
    NextId = next_bowl(Order,Queried),
    First = save((at1(Bowls,Queried) + integer(Seal) + integer(181)) *
        (at1(Bowls,Queried) + integer(Seal) + integer(181)) +
        integer(179) * at1(Bowls,NextId) + integer(Seal)),
    DN = save((First + integer(Seal) + integer.one + integer(193)) *
        (First + integer(Seal) + integer.one + integer(193)) + integer(193) * First +
        integer(197) * at1(Bowls,6)),
    Step = ( if regular_mod(DN, integer(2)) = integer.one then 1 else -1 ).

answer_at(answer_stream(First,Step), K) = integer.one +
    regular_mod(First - integer.one + integer(Step) * K, big_m).

:- func choose_rank_short(answer_stream, z, z) = z.
choose_rank_short(Stream, N, K) = Result :-
    Limit = (big_m div N) * N,
    X = answer_at(Stream,K),
    ( if X =< Limit then
        Result = regular_mod(X - integer.one, N) + integer.one
    else
        Result = choose_rank_short(Stream,N,K + integer.one)
    ).

:- pred smallest_power(z::in, z::in, int::out, z::out) is det.
smallest_power(Base, N, K, Space) :-
    smallest_power_loop(Base,N,1,Base,K,Space).

:- pred smallest_power_loop(z::in, z::in, int::in, z::in, int::out, z::out) is det.
smallest_power_loop(Base,N,K0,Space0,K,Space) :-
    ( if Space0 >= N then
        K = K0, Space = Space0
    else
        smallest_power_loop(Base,N,K0 + 1,Space0 * Base,K,Space)
    ).

:- func make_wide(answer_stream, int, int, z, z) = z.
make_wide(Stream, Places, J, Weight, Acc) = Result :-
    ( if J >= Places then
        Result = Acc
    else
        D = answer_at(Stream,integer(J)) - integer.one,
        Result = make_wide(Stream,Places,J + 1,Weight * big_m,Acc + D * Weight)
    ).

:- func wide_reject(z, z, z, int, z) = z.
wide_reject(W, Limit, Space, Step, N) = Result :-
    ( if W =< Limit then
        Result = regular_mod(W - integer.one,N) + integer.one
    else
        Next = integer.one + regular_mod(W - integer.one + integer(Step), Space),
        Result = wide_reject(Next,Limit,Space,Step,N)
    ).

:- func choose_rank_wide(answer_stream, z) = z.
choose_rank_wide(Stream @ answer_stream(_,Step), N) = Result :-
    smallest_power(big_m,N,Places,Space),
    Wide = make_wide(Stream,Places,0,integer.one,integer.one),
    Limit = (Space div N) * N,
    Result = wide_reject(Wide,Limit,Space,Step,N).

choose_rank(Stream,N) = ( if N =< big_m then choose_rank_short(Stream,N,integer.zero) else choose_rank_wide(Stream,N) ).

falling_factorial(N,K) = falling_factorial_loop(N,K,0,integer.one).

:- func falling_factorial_loop(int,int,int,z) = z.
falling_factorial_loop(N,K,J,Acc) = ( if J >= K then Acc else
    falling_factorial_loop(N,K,J + 1,Acc * integer(N - J)) ).

:- func unrank_distinct_loop(list(int), int, z) = list(int).
unrank_distinct_loop(Remaining, K, R) = Result :-
    ( if K =< 0 then
        Result = []
    else
        Block = falling_factorial(list.length(Remaining) - 1, K - 1),
        QZ = (R - integer.one) div Block,
        Q = integer.det_to_int(QZ) + 1,
        Chosen = at1(Remaining,Q),
        NewR = R - integer(Q - 1) * Block,
        Result = [Chosen | unrank_distinct_loop(remove_nth(Remaining,Q),K - 1,NewR)]
    ).

unrank_distinct_indices(N,K,R) = unrank_distinct_loop(1 `..` N,K,R).

:- func binomial(int,int) = z.
binomial(N,K) = Result :-
    ( if K < 0 then
        Result = integer.zero
    else if K > N then
        Result = integer.zero
    else
        KK = ( if K > N - K then N - K else K ),
        Result = binomial_loop(N,KK,1,integer.one)
    ).

:- func binomial_loop(int,int,int,z) = z.
binomial_loop(N,K,I,Acc) = Result :-
    ( if I > K then
        Result = Acc
    else
        Next = (Acc * integer(N - K + I)) div integer(I),
        Result = binomial_loop(N,K,I + 1,Next)
    ).

count_bounded_compositions(Total,Slots,Lo,Hi) = Result :-
    ( if Slots = 0 then
        Result = ( if Total = 0 then integer.one else integer.zero )
    else
        S = Total - Slots * Lo,
        Width = Hi - Lo,
        ( if S < 0 then
            Result = integer.zero
        else
            MaxJ = S // (Width + 1),
            Result = bounded_ie_sum(0,MaxJ,S,Slots,Width,integer.zero)
        )
    ).

:- func bounded_ie_sum(int,int,int,int,int,z) = z.
bounded_ie_sum(J,MaxJ,S,Slots,Width,Acc) = Result :-
    ( if J > MaxJ then
        Result = Acc
    else
        Top = S - J * (Width + 1) + Slots - 1,
        Term0 = binomial(Slots,J) * binomial(Top,Slots - 1),
        Term = ( if J mod 2 = 0 then Term0 else -Term0 ),
        Result = bounded_ie_sum(J + 1,MaxJ,S,Slots,Width,Acc + Term)
    ).

:- func unrank_bounded_loop(int,int,int,int,z,list(int)) = list(int).
unrank_bounded_loop(Rem,Slots,Lo,Hi,R,Acc) = Result :-
    ( if Slots = 0 then
        Result = Acc
    else
        Result = choose_bounded_x(Lo,Hi,Rem,Slots,Lo,Hi,R,Acc)
    ).

:- func choose_bounded_x(int,int,int,int,int,int,z,list(int)) = list(int).
choose_bounded_x(X,MaxX,Rem,Slots,Lo,Hi,R,Acc) = Result :-
    Count = count_bounded_compositions(Rem - X,Slots - 1,Lo,Hi),
    ( if X > MaxX then
        Result = Acc
    else if R > Count then
        Result = choose_bounded_x(X + 1,MaxX,Rem,Slots,Lo,Hi,R - Count,Acc)
    else
        Result = unrank_bounded_loop(Rem - X,Slots - 1,Lo,Hi,R,Acc ++ [X])
    ).

unrank_bounded_composition(Total,Slots,Lo,Hi,R) = unrank_bounded_loop(Total,Slots,Lo,Hi,R,[]).

:- func positive_composition_count(int,int) = z.
positive_composition_count(Total,Slots) = Result :-
    ( if Slots = 0 then
        Result = ( if Total = 0 then integer.one else integer.zero )
    else if Total < Slots then
        Result = integer.zero
    else if K > N then
        Result = integer.zero
    else
        Result = binomial(Total - 1,Slots - 1)
    ).

count_cutlet_partitions(G,K,Required) = Result :-
    (
        Required = no,
        Result = positive_composition_count(G,K)
    ;
        Required = yes(B),
        ( if B =< 0 then
            Result = integer.zero
        else if B >= G then
            Result = integer.zero
        else
            Result = cutlet_boundary_sum(1,K - 1,G,K,B,integer.zero)
        )
    ).

:- func cutlet_boundary_sum(int,int,int,int,int,z) = z.
cutlet_boundary_sum(J,MaxJ,G,K,B,Acc) = Result :-
    ( if J > MaxJ then
        Result = Acc
    else
        Left = positive_composition_count(B,J),
        Right = positive_composition_count(G - B,K - J),
        Result = cutlet_boundary_sum(J + 1,MaxJ,G,K,B,Acc + Left * Right)
    ).

:- func cutlet_suffix_count(int,int,int,bool,maybe(int)) = z.
cutlet_suffix_count(Rem,Slots,Cumulative,Hit,Required) = Result :-
    (
        Required = no,
        Result = positive_composition_count(Rem,Slots)
    ;
        Required = yes(B),
        ( if Hit = yes then
            Result = positive_composition_count(Rem,Slots)
        else if Cumulative >= B then
            Result = integer.zero
        else if K > N then
        Result = integer.zero
    else
            Need = B - Cumulative,
            ( if Need >= Rem then
                Result = integer.zero
            else if K > N then
        Result = integer.zero
    else
                Result = count_cutlet_partitions(Rem,Slots,yes(Need))
            )
        )
    ).

:- func unrank_cutlet_loop(int,int,int,bool,maybe(int),z,list(int)) = list(int).
unrank_cutlet_loop(Rem,Slots,Cumulative,Hit,Required,R,Acc) = Result :-
    ( if Slots = 0 then
        Result = Acc
    else
        MaxX = Rem - (Slots - 1),
        Result = choose_cutlet_x(1,MaxX,Rem,Slots,Cumulative,Hit,Required,R,Acc)
    ).

:- func choose_cutlet_x(int,int,int,int,int,bool,maybe(int),z,list(int)) = list(int).
choose_cutlet_x(X,MaxX,Rem,Slots,Cumulative,Hit,Required,R,Acc) = Result :-
    NextCum = Cumulative + X,
    (
        Required = no,
        NextHit = Hit,
        Allowed = yes
    ;
        Required = yes(B),
        ( if Hit = no, NextCum > B then
            NextHit = no,
            Allowed = no
        else if NextCum = B then
            NextHit = yes,
            Allowed = yes
        else
            NextHit = Hit,
            Allowed = yes
        )
    ),
    ( if X > MaxX then
        Result = Acc
    else if Allowed = no then
        Result = choose_cutlet_x(X + 1,MaxX,Rem,Slots,Cumulative,Hit,Required,R,Acc)
    else
        Count = cutlet_suffix_count(Rem - X,Slots - 1,NextCum,NextHit,Required),
        ( if R > Count then
            Result = choose_cutlet_x(X + 1,MaxX,Rem,Slots,Cumulative,Hit,Required,R - Count,Acc)
        else
            Result = unrank_cutlet_loop(Rem - X,Slots - 1,NextCum,NextHit,Required,R,Acc ++ [X])
        )
    ).

unrank_cutlet_partition(G,K,Required,R) = unrank_cutlet_loop(G,K,0,no,Required,R,[]).

:- type weave_state
    --->    weave_state(list(int), int, int).

:- func all_zero(list(int)) = bool.
all_zero([]) = yes.
all_zero([X | Xs]) = ( if X = 0 then all_zero(Xs) else no ).

:- func legal_weave_move(weave_state,list(int),int) = bool.
legal_weave_move(weave_state(Remaining,Opened,Closed),Lengths,J) = Result :-
    R = at1(Remaining,J),
    Original = at1(Lengths,J),
    ( if R = 0 then
        Result = no
    else
        AlreadyOpened = ( if R < Original then yes else no ),
        OpensOk = ( if AlreadyOpened = yes then yes else if J = Opened + 1 then yes else no ),
        WillClose = ( if R = 1 then yes else no ),
        ClosesOk = ( if WillClose = yes then ( if J = Closed + 1 then yes else no ) else yes ),
        Result = ( if OpensOk = yes, ClosesOk = yes then yes else no )
    ).

:- func apply_weave_move(weave_state,list(int),int) = weave_state.
apply_weave_move(weave_state(Remaining,Opened,Closed),Lengths,J) = weave_state(NewRemaining,NewOpened,NewClosed) :-
    R = at1(Remaining,J),
    Original = at1(Lengths,J),
    NewOpened = ( if R = Original then J else Opened ),
    NewR = R - 1,
    NewRemaining = list.det_replace_nth(Remaining,J,NewR),
    NewClosed = ( if NewR = 0 then J else Closed ).

:- pred count_weavings_memo(list(int)::in, weave_state::in, z::out,
    map(weave_state,z)::in, map(weave_state,z)::out) is det.
count_weavings_memo(Lengths,State @ weave_state(Remaining,_,_),Count,!Memo) :-
    ( if all_zero(Remaining) = yes then
        Count = integer.one
    else if map.search(!.Memo,State,Cached) then
        Count = Cached
    else
        M = list.length(Lengths),
        count_weave_choices(1,M,Lengths,State,integer.zero,Count,!Memo),
        map.set(State,Count,!Memo)
    ).

:- pred count_weave_choices(int::in,int::in,list(int)::in,weave_state::in,z::in,z::out,
    map(weave_state,z)::in,map(weave_state,z)::out) is det.
count_weave_choices(J,M,Lengths,State,Acc,Count,!Memo) :-
    ( if J > M then
        Count = Acc
    else if legal_weave_move(State,Lengths,J) = yes then
        Next = apply_weave_move(State,Lengths,J),
        count_weavings_memo(Lengths,Next,Block,!Memo),
        count_weave_choices(J + 1,M,Lengths,State,Acc + Block,Count,!Memo)
    else
        count_weave_choices(J + 1,M,Lengths,State,Acc,Count,!Memo)
    ).

count_weavings(Lengths) = Count :-
    State = weave_state(Lengths,0,0),
    Memo0 = map.init,
    count_weavings_memo(Lengths,State,Count,Memo0,_).

:- pred unrank_weave_loop(list(int)::in,weave_state::in,z::in,list(int)::in,list(int)::out,
    map(weave_state,z)::in,map(weave_state,z)::out) is det.
unrank_weave_loop(Lengths,State @ weave_state(Remaining,_,_),R,Acc,Out,!Memo) :-
    ( if all_zero(Remaining) = yes then
        Out = Acc
    else
        choose_weave_move(1,list.length(Lengths),Lengths,State,R,Acc,Out,!Memo)
    ).

:- pred choose_weave_move(int::in,int::in,list(int)::in,weave_state::in,z::in,
    list(int)::in,list(int)::out,map(weave_state,z)::in,map(weave_state,z)::out) is det.
choose_weave_move(J,M,Lengths,State,R,Acc,Out,!Memo) :-
    ( if J > M then
        Out = Acc
    else if legal_weave_move(State,Lengths,J) = no then
        choose_weave_move(J + 1,M,Lengths,State,R,Acc,Out,!Memo)
    else
        Next = apply_weave_move(State,Lengths,J),
        count_weavings_memo(Lengths,Next,Block,!Memo),
        ( if R > Block then
            choose_weave_move(J + 1,M,Lengths,State,R - Block,Acc,Out,!Memo)
        else
            unrank_weave_loop(Lengths,Next,R,Acc ++ [J],Out,!Memo)
        )
    ).

unrank_weaving(Lengths,R) = Out :-
    State = weave_state(Lengths,0,0),
    Memo0 = map.init,
    unrank_weave_loop(Lengths,State,R,[],Out,Memo0,_).

:- type gate_entry ---> gate_entry(z,z).
:- type year_rec ---> year_rec(z,z,z,z,z).
:- type year_with_gates ---> year_with_gates(year_rec,list(gate_entry)).

:- func gate_index(gate_entry) = z.
:- func gate_day(gate_entry) = z.
gate_index(gate_entry(I,_)) = I.
gate_day(gate_entry(_,D)) = D.

:- func gate_gap(z) = z.
gate_gap(SignedStep) = Gap :-
    QDay = ( if SignedStep < integer.zero then
        foundation_day - zabs(SignedStep)
    else
        foundation_day + SignedStep
    ),
    R = sauce(foundation_day,QDay),
    Stream = ask_bowl(R,1,1),
    Gap = integer(41) + choose_rank(Stream,integer(922)).

:- func max_gate_index(list(gate_entry)) = z.
max_gate_index(Gates) = gate_index(list.det_last(Gates)).

:- func min_gate_index(list(gate_entry)) = z.
min_gate_index([G | _]) = gate_index(G).
min_gate_index([]) = integer.zero.

:- func max_gate_day(list(gate_entry)) = z.
max_gate_day(Gates) = gate_day(list.det_last(Gates)).

:- func min_gate_day(list(gate_entry)) = z.
min_gate_day([G | _]) = gate_day(G).
min_gate_day([]) = foundation_day.

:- func extend_positive_to(z,list(gate_entry)) = list(gate_entry).
extend_positive_to(High,Gates) = Result :-
    ( if max_gate_day(Gates) >= High then
        Result = Gates
    else
        I = max_gate_index(Gates) + integer.one,
        D = max_gate_day(Gates) + gate_gap(I),
        Result = extend_positive_to(High,Gates ++ [gate_entry(I,D)])
    ).

:- func extend_negative_to(z,list(gate_entry)) = list(gate_entry).
extend_negative_to(Low,Gates) = Result :-
    ( if min_gate_day(Gates) =< Low then
        Result = Gates
    else
        I = min_gate_index(Gates) - integer.one,
        D = min_gate_day(Gates) - gate_gap(I),
        Result = extend_negative_to(Low,[gate_entry(I,D) | Gates])
    ).

:- func ensure_gates_cover(z,z,list(gate_entry)) = list(gate_entry).
ensure_gates_cover(Low,High,Gates0) = Gates :-
    Gates1 = extend_negative_to(Low,Gates0),
    Gates = extend_positive_to(High,Gates1).

:- func gate_day_for_index(list(gate_entry),z) = z.
gate_day_for_index([gate_entry(I,D) | Rest],Wanted) =
    ( if I = Wanted then D else gate_day_for_index(Rest,Wanted) ).
gate_day_for_index([],_) = D :-
    unexpected($pred, "GATE_INDEX_NOT_FOUND"),
    D = foundation_day.

:- func exact_gate_index(list(gate_entry),z) = maybe(z).
exact_gate_index([],_) = no.
exact_gate_index([gate_entry(I,D) | Rest],Day) =
    ( if D = Day then yes(I) else exact_gate_index(Rest,Day) ).

:- func valid_year_pair(list(gate_entry),z,z) = bool.
valid_year_pair(Gates,Open,Close) = Result :-
    Gaps = Close - Open,
    L = gate_day_for_index(Gates,Close) - gate_day_for_index(Gates,Open),
    Result = ( if Gaps >= integer(6), L >= integer(252), L =< integer(5778) then yes else no ).

:- type year_candidate ---> year_candidate(z,z,z,z).

:- func insert_year_candidate(year_candidate,list(year_candidate)) = list(year_candidate).
insert_year_candidate(C,[]) = [C].
insert_year_candidate(C @ year_candidate(_,_,Len,OpenDay),[H @ year_candidate(_,_,HLen,HOpen) | T]) = Result :-
    ( if Len < HLen then
        Result = [C,H | T]
    else if Len = HLen, OpenDay < HOpen then
        Result = [C,H | T]
    else
        Result = [H | insert_year_candidate(C,T)]
    ).
:- func sort_year_candidates(list(year_candidate)) = list(year_candidate).
sort_year_candidates([]) = [].
sort_year_candidates([H | T]) = insert_year_candidate(H,sort_year_candidates(T)).

:- func anchor_candidates_outer(list(gate_entry),z,list(gate_entry),list(year_candidate)) = list(year_candidate).
anchor_candidates_outer([],_,_,Acc) = Acc.
anchor_candidates_outer([gate_entry(I,DI) | Rest],CDay,All,Acc) = Result :-
    New = anchor_candidates_inner(All,I,DI,CDay,All,Acc),
    Result = anchor_candidates_outer(Rest,CDay,All,New).

:- func anchor_candidates_inner(list(gate_entry),z,z,z,list(gate_entry),list(year_candidate)) = list(year_candidate).
anchor_candidates_inner([],_,_,_,_,Acc) = Acc.
anchor_candidates_inner([gate_entry(J,DJ) | Rest],I,DI,CDay,All,Acc) = Result :-
    ( if J > I, valid_year_pair(All,I,J) = yes, DI < CDay, CDay =< DJ then
        C = year_candidate(I,J,DJ - DI,DI),
        Result = anchor_candidates_inner(Rest,I,DI,CDay,All,[C | Acc])
    else
        Result = anchor_candidates_inner(Rest,I,DI,CDay,All,Acc)
    ).

:- func year5000(z) = year_with_gates.
year5000(CDay) = year_with_gates(Y,Gates) :-
    Gates0 = [gate_entry(integer.zero,foundation_day)],
    Gates = ensure_gates_cover(CDay - integer(5778),CDay + integer(5778),Gates0),
    Candidates0 = anchor_candidates_outer(Gates,CDay,Gates,[]),
    Candidates = sort_year_candidates(Candidates0),
    R = sauce(CDay,CDay), Stream = ask_bowl(R,1,10),
    Rank = integer.det_to_int(choose_rank(Stream,integer(list.length(Candidates)))),
    year_candidate(O,C,_,_) = at1(Candidates,Rank),
    Y = year_rec(integer(5000),O,C,gate_day_for_index(Gates,O),gate_day_for_index(Gates,C)).

:- func ensure_index_available(z,list(gate_entry)) = list(gate_entry).
ensure_index_available(Index,Gates) = Result :-
    ( if Index > max_gate_index(Gates) then
        LastDay = max_gate_day(Gates),
        I = max_gate_index(Gates) + integer.one,
        D = LastDay + gate_gap(I),
        Result = ensure_index_available(Index,Gates ++ [gate_entry(I,D)])
    else if Index < min_gate_index(Gates) then
        FirstDay = min_gate_day(Gates),
        I = min_gate_index(Gates) - integer.one,
        D = FirstDay - gate_gap(I),
        Result = ensure_index_available(Index,[gate_entry(I,D) | Gates])
    else
        Result = Gates
    ).

:- func next_year(z,year_rec,list(gate_entry)) = year_with_gates.
next_year(CDay,year_rec(Number,_,Close,_,_),Gates0) = year_with_gates(Y,Gates) :-
    Open = Close,
    {Candidates,Gates} = next_year_candidates(Open,Open + integer.one,Gates0,[]),
    R = sauce(CDay,gate_day_for_index(Gates,Open)), Stream = ask_bowl(R,1,11),
    Rank = integer.det_to_int(choose_rank(Stream,integer(list.length(Candidates)))),
    NewClose = at1(Candidates,Rank),
    Y = year_rec(Number + integer.one,Open,NewClose,gate_day_for_index(Gates,Open),gate_day_for_index(Gates,NewClose)).

:- func next_year_candidates(z,z,list(gate_entry),list(z)) = {list(z),list(gate_entry)}.
next_year_candidates(Open,J,Gates0,Acc) = Result :-
    Gates1 = ensure_index_available(J,Gates0),
    L = gate_day_for_index(Gates1,J) - gate_day_for_index(Gates1,Open),
    ( if L > integer(5778) then
        Result = {Acc,Gates1}
    else
        Acc1 = ( if valid_year_pair(Gates1,Open,J) = yes then Acc ++ [J] else Acc ),
        Result = next_year_candidates(Open,J + integer.one,Gates1,Acc1)
    ).

:- func previous_year(z,year_rec,list(gate_entry)) = year_with_gates.
previous_year(CDay,year_rec(Number,Open,_,_,_),Gates0) = year_with_gates(Y,Gates) :-
    Close = Open,
    {Candidates,Gates} = previous_year_candidates(Close,Close - integer.one,Gates0,[]),
    R = sauce(CDay,gate_day_for_index(Gates,Close)), Stream = ask_bowl(R,1,12),
    Rank = integer.det_to_int(choose_rank(Stream,integer(list.length(Candidates)))),
    NewOpen = at1(Candidates,Rank),
    Y = year_rec(Number - integer.one,NewOpen,Close,gate_day_for_index(Gates,NewOpen),gate_day_for_index(Gates,Close)).

:- func previous_year_candidates(z,z,list(gate_entry),list(z)) = {list(z),list(gate_entry)}.
previous_year_candidates(Close,I,Gates0,Acc) = Result :-
    Gates1 = ensure_index_available(I,Gates0),
    L = gate_day_for_index(Gates1,Close) - gate_day_for_index(Gates1,I),
    ( if L > integer(5778) then
        Result = {Acc,Gates1}
    else
        Acc1 = ( if valid_year_pair(Gates1,I,Close) = yes then Acc ++ [I] else Acc ),
        Result = previous_year_candidates(Close,I - integer.one,Gates1,Acc1)
    ).

:- func find_target_year(z,z) = year_with_gates.
find_target_year(CDay,TDay) = Result :-
    year_with_gates(Y0,G0) = year5000(CDay),
    Result = walk_to_year(CDay,TDay,Y0,G0).

:- func walk_to_year(z,z,year_rec,list(gate_entry)) = year_with_gates.
walk_to_year(CDay,TDay,Y @ year_rec(_,_,_,OpenDay,CloseDay),Gates) = Result :-
    ( if TDay > CloseDay then
        year_with_gates(YN,GN) = next_year(CDay,Y,Gates),
        Result = walk_to_year(CDay,TDay,YN,GN)
    else if TDay =< OpenDay then
        year_with_gates(YP,GP) = previous_year(CDay,Y,Gates),
        Result = walk_to_year(CDay,TDay,YP,GP)
    else
        Result = year_with_gates(Y,Gates)
    ).

:- type cutlet_rec ---> cutlet_rec(int,z,z).
:- type year_structure ---> year_structure(list(cutlet_rec),list(int),list(int),list(int)).

:- func choose_cutlet_count(sauce_result,year_rec) = int.
choose_cutlet_count(R,year_rec(_,Open,Close,_,_)) = K :-
    Gaps = integer.det_to_int(Close - Open),
    MaxK = ( if Gaps < 17 then Gaps else 17 ),
    Candidates = 6 `..` MaxK,
    Stream = ask_bowl(R,2,20),
    Rank = integer.det_to_int(choose_rank(Stream,integer(list.length(Candidates)))),
    K = at1(Candidates,Rank).

:- func choose_cutlet_partition(z,sauce_result,year_rec,list(gate_entry),int) = list(int).
choose_cutlet_partition(CDay,R,year_rec(_,Open,Close,OpenDay,CloseDay),Gates,K) = Partition :-
    G = integer.det_to_int(Close - Open),
    Exact = exact_gate_index(Gates,CDay),
    (
        Exact = yes(GI),
        ( if OpenDay < CDay, CDay < CloseDay, GI > Open, GI < Close then
            Required = yes(integer.det_to_int(GI - Open))
        else
            Required = no
        )
    ;
        Exact = no,
        Required = no
    ),
    Count = count_cutlet_partitions(G,K,Required),
    Stream = ask_bowl(R,2,21),
    Rank = choose_rank(Stream,Count),
    Partition = unrank_cutlet_partition(G,K,Required,Rank).

:- func choose_name_indices(sauce_result,int,int,int,int) = list(int).
choose_name_indices(R,Bowl,Seal,MasterCount,K) = Names :-
    Count = falling_factorial(MasterCount,K),
    Stream = ask_bowl(R,Bowl,Seal),
    Rank = choose_rank(Stream,Count),
    Names = unrank_distinct_indices(MasterCount,K,Rank).

:- func materialize_cutlets(list(gate_entry),z,list(int),list(int)) = list(cutlet_rec).
materialize_cutlets(Gates,Open,Partition,Names) = materialize_cutlets_loop(Gates,Open,Partition,Names,[]).

:- func materialize_cutlets_loop(list(gate_entry),z,list(int),list(int),list(cutlet_rec)) = list(cutlet_rec).
materialize_cutlets_loop(_,_,[],[],Acc) = Acc.
materialize_cutlets_loop(Gates,Cursor,[P | Ps],[Name | Ns],Acc) = Result :-
    Close = Cursor + integer(P),
    FirstDay = gate_day_for_index(Gates,Cursor) + integer.one,
    LastDay = gate_day_for_index(Gates,Close),
    Result = materialize_cutlets_loop(Gates,Close,Ps,Ns,Acc ++ [cutlet_rec(Name,FirstDay,LastDay)]).
materialize_cutlets_loop(_,_,_,_,Acc) = Acc.

:- func choose_month_count(sauce_result,year_rec) = int.
choose_month_count(R,year_rec(_,_,_,OpenDay,CloseDay)) = K :-
    L = CloseDay - OpenDay,
    LowZ = ceil_div_nonneg(L,integer(123)),
    HighZ = zmin(integer(47),L div integer(4)),
    Low = integer.det_to_int(LowZ),
    High = integer.det_to_int(HighZ),
    Stream = ask_bowl(R,3,30),
    Rank = integer.det_to_int(choose_rank(Stream,integer(High - Low + 1))),
    K = Low + Rank - 1.

:- func choose_month_lengths(sauce_result,year_rec,int) = list(int).
choose_month_lengths(R,year_rec(_,_,_,OpenDay,CloseDay),K) = Lengths :-
    L = integer.det_to_int(CloseDay - OpenDay),
    Count = count_bounded_compositions(L,K,4,123),
    Stream = ask_bowl(R,3,31),
    Rank = choose_rank(Stream,Count),
    Lengths = unrank_bounded_composition(L,K,4,123,Rank).

:- func choose_month_weaving(sauce_result,list(int)) = list(int).
choose_month_weaving(R,Lengths) = Weave :-
    Count = count_weavings(Lengths),
    Stream = ask_bowl(R,4,32),
    Rank = choose_rank(Stream,Count),
    Weave = unrank_weaving(Lengths,Rank).

:- func build_year_structure(z,year_rec,list(gate_entry)) = year_structure.
build_year_structure(CDay,Y @ year_rec(_,OpenIndex,_,OpenDay,_),Gates) =
    year_structure(Cutlets,MonthLengths,Weave,MonthNames) :-
    R = sauce(CDay,OpenDay + integer.one),
    K = choose_cutlet_count(R,Y),
    Partition = choose_cutlet_partition(CDay,R,Y,Gates,K),
    CutletNames = choose_name_indices(R,5,22,17,K),
    Cutlets = materialize_cutlets(Gates,OpenIndex,Partition,CutletNames),
    MonthCount = choose_month_count(R,Y),
    MonthLengths = choose_month_lengths(R,Y,MonthCount),
    Weave = choose_month_weaving(R,MonthLengths),
    MonthNames = choose_name_indices(R,5,33,47,MonthCount).

:- func find_cutlet(list(cutlet_rec),z) = {int,z}.
find_cutlet([cutlet_rec(Name,First,Last) | Rest],Day) = Result :-
    ( if First =< Day, Day =< Last then
        Result = {Name,Day - First + integer.one}
    else
        Result = find_cutlet(Rest,Day)
    ).
find_cutlet([],_) = Result :-
    unexpected($pred, "CUTLET_NOT_FOUND"),
    Result = {1, integer.one}.

:- func count_occurrences_prefix(list(int),int,int) = int.
count_occurrences_prefix(Weave,Limit,MonthId) = count_occurrences_loop(Weave,1,Limit,MonthId,0).

:- func count_occurrences_loop(list(int),int,int,int,int) = int.
count_occurrences_loop([],_,_,_,Acc) = Acc.
count_occurrences_loop([X | Xs],Pos,Limit,Id,Acc) = Result :-
    ( if Pos > Limit then
        Result = Acc
    else
        NextAcc = ( if X = Id then Acc + 1 else Acc ),
        Result = count_occurrences_loop(Xs,Pos + 1,Limit,Id,NextAcc)
    ).

:- func resolve_required(source_language_catalog.catalog_kind,int) = string.
resolve_required(Kind,Index) = Text :-
    R = source_language_catalog.resolve(Kind,Index),
    ( R = yes(S), Text = S
    ; R = no, Text = "НЭР_ОЛДСОНГҮЙ"
    ).

calendar_date(CDay,TDay) = date5(YearNumber,CutletText,DayInCutlet,MonthText,DayInMonth) :-
    year_with_gates(Y @ year_rec(YearNumber,_,_,OpenDay,_),Gates) = find_target_year(CDay,TDay),
    year_structure(Cutlets,_,Weave,MonthNames) = build_year_structure(CDay,Y,Gates),
    {CutletIndex,DayInCutlet} = find_cutlet(Cutlets,TDay),
    OffsetZ = TDay - (OpenDay + integer.one),
    Offset = integer.det_to_int(OffsetZ),
    MonthId = at1(Weave,Offset + 1),
    MonthCanonicalIndex = at1(MonthNames,MonthId),
    DayInMonth = count_occurrences_prefix(Weave,Offset + 1,MonthId),
    CutletText = resolve_required(cutlet,CutletIndex),
    MonthText = resolve_required(month,MonthCanonicalIndex).
