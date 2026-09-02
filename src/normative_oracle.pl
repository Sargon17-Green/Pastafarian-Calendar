:- module(normative_oracle,
    [ normative_m/1,
      tablets_day/1,
      foundation_day/1,
      save/2,
      day_count/2,
      work_counts/3,
      build_stones/1,
      build_hidden_drops/3,
      build_visible_drops/4,
      bowl_order_from_number/2,
      bowl_order_from_drop/2,
      initial_bowls/2,
      apply_visible_drops_to_bowls/5,
      post_stir12/2,
      sauce/3,
      ask_bowl/4,
      answer_at/3,
      choose_rank/3,
      falling_factorial/3,
      unrank_distinct_indices/3,
      bounded_composition_count/5,
      bounded_composition_unrank/6,
      weaving_count/2,
      weaving_unrank/3,
      reset_oracle_state/0,
      positive_gate_gap/2,
      negative_gate_gap/2,
      ensure_gate_index/2,
      exact_gate_index/2,
      year5000/2,
      find_target_year/3,
      build_year_structure/3,
      calendar_date/3
    ]).

:- use_module(source_language_catalog).
:- use_module(library(lists)).
:- use_module(library(assoc)).

normative_m(170141183460469231731687303715884105727).
tablets_day(-278522).
foundation_day(-15055671).

gate_gap_min(42).
gate_gap_max(963).
year_min_days(252).
year_max_days(5778).
min_gate_gaps_per_year(6).
min_cutlets(6).
max_cutlets(17).
min_month_days(4).
max_month_days(123).
max_months(47).

seal_gate_gap(1).
seal_year_5000(10).
seal_next_year(11).
seal_previous_year(12).
seal_cutlet_count(20).
seal_cutlet_partition(21).
seal_cutlet_names(22).
seal_month_count(30).
seal_month_lengths(31).
seal_month_weaving(32).
seal_month_names(33).

reset_oracle_state :-
    true.

regular_mod(X, D, R) :-
    R is X mod D.

save(X, R) :-
    normative_m(M),
    R is 1 + ((X - 1) mod M).

ceil_div(A, B, R) :-
    R is (A + B - 1) // B.

wrap1(Position, Size, Wrapped) :-
    Wrapped is ((Position - 1) mod Size) + 1.

day_count(Day, Count) :-
    foundation_day(F),
    ( Day =:= F ->
        Count = 1
    ; Day > F ->
        Count is 2 * (Day - F) + 1
    ; Count is 2 * (F - Day)
    ).

work_counts(CalculationDay, TargetDay,
            counts(Action, Target, Distance, Connection, Direction)) :-
    day_count(CalculationDay, Action),
    day_count(TargetDay, Target),
    Distance is abs(TargetDay - CalculationDay) + 1,
    Connection is Action + Target,
    ( TargetDay < CalculationDay -> Direction = 1
    ; TargetDay =:= CalculationDay -> Direction = 2
    ; Direction = 3
    ).

stone_value(Row, 1, V) :- nth1(1, Row, V).
stone_value(Row, 2, V) :- nth1(2, Row, V).
stone_value(Row, 3, V) :- nth1(3, Row, V).
stone_value(Row, 4, V) :- nth1(4, Row, V).
stone_value(Row, 5, V) :- nth1(5, Row, V).

build_stones(Stones) :-
    build_stones_from(2, [17,29,43,71,101], [[17,29,43,71,101]], Rev),
    reverse(Rev, Stones).

build_stones_from(47, _, Acc, Acc) :- !.
build_stones_from(I, Old, Acc, Stones) :-
    Old = [W,B,S,Bitter,Red],
    save(W*W + 3*B + I, NW),
    save(B*B + 5*S + W, NB),
    save(S*S + 7*Bitter + B, NS),
    save(Bitter*Bitter + 11*Red + S, NM),
    save(Red*Red + 13*W + Bitter, NR),
    New = [NW,NB,NS,NM,NR],
    I2 is I + 1,
    build_stones_from(I2, New, [New|Acc], Stones).

hidden_coeff(1, 3,4,6,8).
hidden_coeff(2, 5,7,10,12).
hidden_coeff(3, 7,10,14,16).
hidden_coeff(4, 9,13,18,20).
hidden_coeff(5, 11,16,22,24).
hidden_coeff(6, 13,19,26,28).
hidden_coeff(7, 15,22,30,32).

hidden_grind_kind(1, 1).
hidden_grind_kind(2, 2).
hidden_grind_kind(3, 3).
hidden_grind_kind(4, 4).
hidden_grind_kind(5, 5).
hidden_grind_kind(6, 1).
hidden_grind_kind(7, 2).

build_hidden_drops(Counts, Stones, Hidden) :-
    findall(Value,
        ( between(1, 7, K), hidden_drop(K, Counts, Stones, Value) ),
        Hidden).

hidden_drop(K, counts(Action,Target,Distance,Connection,Direction), Stones, Value) :-
    hidden_coeff(K, A,B,C,D),
    nth1(K, Stones, Stone),
    sum_list(Stone, StoneSum),
    X0Raw is Action + A*Target + B*Distance + C*Connection + D*Direction + StoneSum,
    save(X0Raw, X0),
    hidden_grinds(1, K, Stone, X0, Value).

hidden_grinds(8, _, _, X, X) :- !.
hidden_grinds(G, K, Stone, X, Value) :-
    hidden_grind_kind(G, Kind),
    stone_value(Stone, Kind, SV),
    Raw is X*X + 3*X + SV + G,
    save(Raw, X2),
    G2 is G + 1,
    hidden_grinds(G2, K, Stone, X2, Value).

visible_grind(1, 3,5,7,11,1).
visible_grind(2, 5,7,11,13,2).
visible_grind(3, 7,11,13,17,3).
visible_grind(4, 11,13,17,19,4).
visible_grind(5, 13,17,19,23,5).
visible_grind(6, 17,19,23,29,1).
visible_grind(7, 19,23,29,31,2).
visible_grind(8, 23,29,31,37,3).
visible_grind(9, 29,31,37,41,4).
visible_grind(10, 31,37,41,43,5).
visible_grind(11, 37,41,43,47,1).

build_visible_drops(Counts, Stones, Hidden, Visible) :-
    visible_loop(1, Counts, Stones, Hidden, [], Visible).

visible_loop(47, _, _, _, Drops, Drops) :- !.
visible_loop(I, Counts, Stones, Hidden, Drops0, Drops) :-
    predecessor_value(I, 1, Drops0, Hidden, P1),
    predecessor_value(I, 3, Drops0, Hidden, P3),
    predecessor_value(I, 7, Drops0, Hidden, P7),
    nth1(I, Stones, Stone),
    Counts = counts(Action,Target,Distance,Connection,Direction),
    Stone = [W,B,S,Bitter,Red],
    Raw0 is W*Action + B*Target + S*Distance + Bitter*Connection + Red*Direction
             + P1 + 3*P3 + 5*P7 + I,
    save(Raw0, X0),
    visible_grinds_loop(1, Stone, P1, P3, P7, X0, X),
    append(Drops0, [X], Drops1),
    I2 is I + 1,
    visible_loop(I2, Counts, Stones, Hidden, Drops1, Drops).

predecessor_value(I, Back, Drops, Hidden, Value) :-
    Slot is I - Back,
    ( Slot >= 1 ->
        nth1(Slot, Drops, Value)
    ; K is 1 - Slot,
      nth1(K, Hidden, Value)
    ).

visible_grinds_loop(12, _, _, _, _, X, X) :- !.
visible_grinds_loop(G, Stone, P1, P3, P7, X, Value) :-
    visible_grind(G, A,B,C,D,Kind),
    stone_value(Stone, Kind, SV),
    Raw is X*X + A*X + B*P1 + C*P3 + D*P7 + SV,
    save(Raw, X2),
    G2 is G + 1,
    visible_grinds_loop(G2, Stone, P1, P3, P7, X2, Value).

factorial(0, 1) :- !.
factorial(N, F) :-
    N > 0,
    N1 is N - 1,
    factorial(N1, F1),
    F is N * F1.

bowl_order_from_number(OrderNumber, Order) :-
    OrderNumber >= 1,
    OrderNumber =< 720,
    Rank0 is OrderNumber - 1,
    permutation_unrank0(Rank0, [1,2,3,4,5,6], Order).

bowl_order_from_drop(Drop, Order) :-
    OrderNumber is ((Drop - 1) mod 720) + 1,
    bowl_order_from_number(OrderNumber, Order).

permutation_unrank0(_, [], []) :- !.
permutation_unrank0(Rank0, Remaining, [Chosen|Rest]) :-
    length(Remaining, N),
    N1 is N - 1,
    factorial(N1, Block),
    Q is Rank0 // Block,
    Rank1 is Rank0 mod Block,
    Index is Q + 1,
    remove_nth1(Index, Remaining, Chosen, NextRemaining),
    permutation_unrank0(Rank1, NextRemaining, Rest).

remove_nth1(1, [X|Xs], X, Xs) :- !.
remove_nth1(N, [X|Xs], Y, [X|Ys]) :-
    N > 1,
    N1 is N - 1,
    remove_nth1(N1, Xs, Y, Ys).

bowl_prime(1,17).
bowl_prime(2,19).
bowl_prime(3,23).
bowl_prime(4,29).
bowl_prime(5,31).
bowl_prime(6,37).

initial_bowls(counts(Action,Target,Distance,Connection,Direction), Bowls) :-
    findall(Value,
        ( between(1,6,Id),
          bowl_prime(Id, Prime),
          S is Action + Target*Id + Distance + Connection + Direction + Prime*Prime,
          save(S*S + Id, Value)
        ),
        Bowls).

stir_stone_kind(1,1).
stir_stone_kind(2,2).
stir_stone_kind(3,3).
stir_stone_kind(4,4).
stir_stone_kind(5,5).
stir_stone_kind(6,1).

apply_visible_drops_to_bowls(Bowls0, Visible, Stones, Bowls, Order46) :-
    apply_drop_loop(1, Bowls0, Visible, Stones, none, Bowls, Order46).

apply_drop_loop(47, Bowls, _, _, Order46, Bowls, Order46) :- !.
apply_drop_loop(I, Bowls0, Visible, Stones, OrderBefore, Bowls, Order46) :-
    nth1(I, Visible, Drop),
    nth1(I, Stones, Stone),
    bowl_order_from_drop(Drop, Order),
    pours_for_drop(I, Drop, Stone, Bowls0, Order, Pours),
    findall(Id-Value,
        ( between(1,6,Position),
          nth1(Position, Order, Id),
          stir_drop_bowl(Position, I, Drop, Stone, Bowls0, Order, Pours, Id, Value)
        ),
        Pairs0),
    keysort(Pairs0, Pairs),
    pair_values(Pairs, Bowls1),
    ( I =:= 46 -> OrderNext = Order ; OrderNext = OrderBefore ),
    I2 is I + 1,
    apply_drop_loop(I2, Bowls1, Visible, Stones, OrderNext, Bowls, Order46).

pours_for_drop(I, Drop, Stone, OldBowls, Order, [P1,P2,P3,0,0,0]) :-
    nth1(1, Order, B1),
    nth1(2, Order, B2),
    nth1(3, Order, B3),
    nth1(B1, OldBowls, V1),
    nth1(B2, OldBowls, V2),
    nth1(B3, OldBowls, V3),
    stone_value(Stone, 1, W),
    stone_value(Stone, 2, B),
    stone_value(Stone, 3, S),
    save(Drop*Drop + W*V1 + 3*I, P1),
    save(Drop*Drop + B*V2 + 5*I, P2),
    save(Drop*Drop + S*V3 + 7*I, P3).

stir_drop_bowl(Position, I, Drop, Stone, OldBowls, Order, Pours, Id, Value) :-
    PrevPos0 is Position - 1,
    NextPos0 is Position + 1,
    wrap1(PrevPos0, 6, PrevPos),
    wrap1(NextPos0, 6, NextPos),
    nth1(PrevPos, Order, PrevId),
    nth1(NextPos, Order, NextId),
    nth1(Id, OldBowls, OldId),
    nth1(PrevId, OldBowls, OldPrev),
    nth1(NextId, OldBowls, OldNext),
    nth1(Position, Pours, Pour),
    stir_stone_kind(Position, Kind),
    stone_value(Stone, Kind, StoneV),
    S is OldId + 2*OldPrev + 3*OldNext + Pour + Drop + StoneV,
    save(S*S + 5*OldPrev*OldNext + I*Position, Value).

pair_values([], []).
pair_values([_-V|Pairs], [V|Values]) :- pair_values(Pairs, Values).

post_stir12(Bowls0, Bowls) :-
    post_stir_loop(1, Bowls0, Bowls).

post_stir_loop(13, Bowls, Bowls) :- !.
post_stir_loop(Stir, OldBowls, Bowls) :-
    sum_list(OldBowls, RawSum),
    save(RawSum + 149*Stir, SavedBowlSum),
    OrderNumber is ((SavedBowlSum - 1) mod 720) + 1,
    bowl_order_from_number(OrderNumber, Order),
    findall(Id-Value,
        ( between(1,6,Position),
          nth1(Position, Order, Id),
          post_stir_bowl(Position, Stir, SavedBowlSum, OldBowls, Order, Id, Value)
        ),
        Pairs0),
    keysort(Pairs0, Pairs),
    pair_values(Pairs, NewBowls),
    Stir2 is Stir + 1,
    post_stir_loop(Stir2, NewBowls, Bowls).

post_stir_bowl(Position, Stir, SavedBowlSum, OldBowls, Order, Id, Value) :-
    wrap1(Position - 1, 6, PrevPos),
    wrap1(Position + 1, 6, NextPos),
    nth1(PrevPos, Order, PrevId),
    nth1(NextPos, Order, NextId),
    nth1(Id, OldBowls, OldId),
    nth1(PrevId, OldBowls, OldPrev),
    nth1(NextId, OldBowls, OldNext),
    S is OldId + 3*OldPrev + 5*OldNext + SavedBowlSum + Stir + Position*Position,
    save(S*S + 7*OldPrev*OldNext, Value).

sauce(CalculationDay, TargetDay, sauce(FinalBowls, Order46)) :-
    work_counts(CalculationDay, TargetDay, Counts),
    build_stones(Stones),
    build_hidden_drops(Counts, Stones, Hidden),
    build_visible_drops(Counts, Stones, Hidden, Visible),
    initial_bowls(Counts, Bowls0),
    apply_visible_drops_to_bowls(Bowls0, Visible, Stones, BowlsAfterDrops, Order46),
    post_stir12(BowlsAfterDrops, FinalBowls).

next_bowl_in_order(Order, QueriedId, NextId) :-
    nth1(Pos, Order, QueriedId),
    NextPos is (Pos mod 6) + 1,
    nth1(NextPos, Order, NextId).

ask_bowl(sauce(Bowls, Order), QueriedId, Seal, stream(First, Step)) :-
    next_bowl_in_order(Order, QueriedId, NextId),
    nth1(QueriedId, Bowls, Q),
    nth1(NextId, Bowls, N),
    nth1(6, Bowls, B6),
    save((Q + Seal + 181)*(Q + Seal + 181) + 179*N + Seal, First),
    save((First + Seal + 1 + 193)*(First + Seal + 1 + 193) + 193*First + 197*B6,
         DirectionNumber),
    ( DirectionNumber mod 2 =:= 1 -> Step = 1 ; Step = -1 ).

answer_at(stream(First, Step), K, Answer) :-
    normative_m(M),
    Answer is 1 + ((First - 1 + Step*K) mod M).

choose_rank(Stream, N, Rank) :-
    normative_m(M),
    N >= 1,
    ( N =< M -> choose_rank_short(Stream, N, Rank)
    ; choose_rank_wide(Stream, N, Rank)
    ).

choose_rank_short(Stream, N, Rank) :-
    normative_m(M),
    Limit is (M // N) * N,
    short_accept(Stream, N, Limit, 0, Rank).

short_accept(Stream, N, Limit, K, Rank) :-
    answer_at(Stream, K, X),
    ( X =< Limit -> Rank is ((X - 1) mod N) + 1
    ; K2 is K + 1,
      short_accept(Stream, N, Limit, K2, Rank)
    ).

smallest_power_count(Base, N, K, Space) :-
    smallest_power_loop(Base, N, 1, Base, K, Space).

smallest_power_loop(_, N, K, Space, K, Space) :- Space >= N, !.
smallest_power_loop(Base, N, K0, Space0, K, Space) :-
    K1 is K0 + 1,
    Space1 is Space0 * Base,
    smallest_power_loop(Base, N, K1, Space1, K, Space).

choose_rank_wide(Stream, N, Rank) :-
    normative_m(M),
    smallest_power_count(M, N, K, Space),
    wide_digits(Stream, 0, K, 1, 1, Wide0),
    Limit is (Space // N) * N,
    wide_accept(Stream, N, Space, Limit, Wide0, Rank).

wide_digits(_, J, K, _, Wide, Wide) :- J >= K, !.
wide_digits(Stream, J, K, Weight, Wide0, Wide) :-
    answer_at(Stream, J, A),
    Digit is A - 1,
    Wide1 is Wide0 + Digit*Weight,
    normative_m(M),
    Weight1 is Weight*M,
    J1 is J + 1,
    wide_digits(Stream, J1, K, Weight1, Wide1, Wide).

wide_accept(_, N, _, Limit, Wide, Rank) :-
    Wide =< Limit,
    !,
    Rank is ((Wide - 1) mod N) + 1.
wide_accept(Stream, N, Space, Limit, Wide0, Rank) :-
    Stream = stream(_,Step),
    Wide1 is 1 + ((Wide0 - 1 + Step) mod Space),
    wide_accept(Stream, N, Space, Limit, Wide1, Rank).

falling_factorial(_, 0, 1) :- !.
falling_factorial(N, K, R) :-
    K > 0,
    K1 is K - 1,
    N1 is N - 1,
    falling_factorial(N1, K1, R1),
    R is N * R1.

unrank_distinct_indices(K, Rank1, Indices) :-
    range_list(1, 17, Remaining),
    unrank_distinct_from(Remaining, K, Rank1, Indices).

unrank_distinct_from(_, 0, _, []) :- !.
unrank_distinct_from(Remaining, K, Rank, [Chosen|Rest]) :-
    K > 0,
    length(Remaining, L),
    Suffix is K - 1,
    L1 is L - 1,
    falling_factorial(L1, Suffix, Block),
    distinct_choose(Remaining, Block, Rank, Chosen, NextRemaining, NextRank),
    K1 is K - 1,
    unrank_distinct_from(NextRemaining, K1, NextRank, Rest).

distinct_choose([X|Xs], Block, Rank, Chosen, Remaining, NextRank) :-
    ( Rank =< Block ->
        Chosen = X,
        Remaining = Xs,
        NextRank = Rank
    ; Rank2 is Rank - Block,
      distinct_choose(Xs, Block, Rank2, Chosen, RestRemaining, NextRank),
      Remaining = [X|RestRemaining]
    ).

range_list(Low, High, []) :- Low > High, !.
range_list(Low, High, [Low|Rest]) :-
    Low2 is Low + 1,
    range_list(Low2, High, Rest).

bounded_composition_count(Total, Slots, Lo, Hi, Count) :-
    bc_prepare(Total, Slots, Lo, Hi, _, Count).

bc_prepare(Total, Slots, Lo, Hi, Memo, Count) :-
    empty_assoc(Memo0),
    bc_count(Total, Slots, Lo, Hi, Memo0, Memo, Count).

bc_count(Rem, Slots, Lo, Hi, Memo0, Memo, Count) :-
    Key = bc(Rem, Slots, Lo, Hi),
    ( get_assoc(Key, Memo0, Cached) ->
        Count = Cached,
        Memo = Memo0
    ; bc_count_uncached(Rem, Slots, Lo, Hi, Memo0, Memo1, Count),
      put_assoc(Key, Memo1, Count, Memo)
    ).

bc_count_uncached(Rem, 0, _, _, Memo, Memo, Count) :-
    !,
    ( Rem =:= 0 -> Count = 1 ; Count = 0 ).
bc_count_uncached(Rem, Slots, Lo, Hi, Memo, Memo, 0) :-
    ( Rem < Slots*Lo ; Rem > Slots*Hi ),
    !.
bc_count_uncached(Rem, Slots, Lo, Hi, Memo0, Memo, Count) :-
    Slots1 is Slots - 1,
    bc_sum_candidates(Lo, Hi, Rem, Slots1, Lo, Hi, Memo0, Memo, 0, Count).

bc_sum_candidates(X, Hi, _, _, _, _, Memo, Memo, Acc, Acc) :- X > Hi, !.
bc_sum_candidates(X, Hi, Rem, Slots1, Lo, BoundHi, Memo0, Memo, Acc0, Count) :-
    Rem1 is Rem - X,
    bc_count(Rem1, Slots1, Lo, BoundHi, Memo0, Memo1, C),
    Acc1 is Acc0 + C,
    X1 is X + 1,
    bc_sum_candidates(X1, Hi, Rem, Slots1, Lo, BoundHi, Memo1, Memo, Acc1, Count).

bounded_composition_unrank(Total, Slots, Lo, Hi, Rank, Composition) :-
    bc_prepare(Total, Slots, Lo, Hi, Memo0, Count),
    Rank >= 1,
    Rank =< Count,
    bc_unrank(Total, Slots, Lo, Hi, Rank, Memo0, _, Composition).

bc_unrank(_, 0, _, _, _, Memo, Memo, []) :- !.
bc_unrank(Rem, Slots, Lo, Hi, Rank, Memo0, Memo, [X|Rest]) :-
    Slots1 is Slots - 1,
    bc_pick_x(Lo, Hi, Rem, Slots1, Lo, Hi, Rank, Memo0, Memo1, X, NextRank),
    Rem1 is Rem - X,
    bc_unrank(Rem1, Slots1, Lo, Hi, NextRank, Memo1, Memo, Rest).

bc_pick_x(X, Hi, Rem, Slots1, Lo, BoundHi, Rank, Memo0, Memo, Chosen, NextRank) :-
    X =< Hi,
    Rem1 is Rem - X,
    bc_count(Rem1, Slots1, Lo, BoundHi, Memo0, Memo1, Block),
    ( Rank > Block ->
        Rank2 is Rank - Block,
        X2 is X + 1,
        bc_pick_x(X2, Hi, Rem, Slots1, Lo, BoundHi, Rank2,
                  Memo1, Memo, Chosen, NextRank)
    ; Chosen = X,
      NextRank = Rank,
      Memo = Memo1
    ).

weaving_count(Lengths, Count) :-
    weave_prepare(Lengths, _, Count).

weave_prepare(Lengths, Memo, Count) :-
    empty_assoc(Memo0),
    weave_count_state(Lengths, Lengths, 0, 0, Memo0, Memo, Count).

weave_count_state(Lengths, Remaining, Opened, Closed, Memo0, Memo, Count) :-
    Key = weave(Remaining, Opened, Closed),
    ( get_assoc(Key, Memo0, Cached) ->
        Count = Cached,
        Memo = Memo0
    ; weave_count_uncached(Lengths, Remaining, Opened, Closed, Memo0, Memo1, Count),
      put_assoc(Key, Memo1, Count, Memo)
    ).

weave_count_uncached(_, Remaining, _, _, Memo, Memo, 1) :- all_zero(Remaining), !.
weave_count_uncached(Lengths, Remaining, Opened, Closed, Memo0, Memo, Count) :-
    length(Lengths, M),
    weave_sum_moves(1, M, Lengths, Remaining, Opened, Closed,
                    Memo0, Memo, 0, Count).

weave_sum_moves(J, M, _, _, _, _, Memo, Memo, Acc, Acc) :- J > M, !.
weave_sum_moves(J, M, Lengths, Remaining, Opened, Closed,
                Memo0, Memo, Acc0, Count) :-
    ( legal_weave_move(J, Lengths, Remaining, Opened, Closed) ->
        apply_weave_move(J, Lengths, Remaining, Opened, Closed,
                         NextRemaining, NextOpened, NextClosed),
        weave_count_state(Lengths, NextRemaining, NextOpened, NextClosed,
                          Memo0, Memo1, Block)
    ; Block = 0,
      Memo1 = Memo0
    ),
    Acc1 is Acc0 + Block,
    J1 is J + 1,
    weave_sum_moves(J1, M, Lengths, Remaining, Opened, Closed,
                    Memo1, Memo, Acc1, Count).

legal_weave_move(J, Lengths, Remaining, Opened, Closed) :-
    nth1(J, Remaining, RemJ),
    RemJ > 0,
    nth1(J, Lengths, OrigJ),
    ( RemJ < OrigJ -> true ; J =:= Opened + 1 ),
    ( RemJ =:= 1 -> J =:= Closed + 1 ; true ).

apply_weave_move(J, Lengths, Remaining, Opened, Closed,
                 NextRemaining, NextOpened, NextClosed) :-
    nth1(J, Remaining, RemJ),
    nth1(J, Lengths, OrigJ),
    ( RemJ =:= OrigJ -> NextOpened = J ; NextOpened = Opened ),
    NewRem is RemJ - 1,
    replace_nth1(J, Remaining, NewRem, NextRemaining),
    ( NewRem =:= 0 -> NextClosed = J ; NextClosed = Closed ).

replace_nth1(1, [_|Xs], V, [V|Xs]) :- !.
replace_nth1(N, [X|Xs], V, [X|Ys]) :-
    N > 1,
    N1 is N - 1,
    replace_nth1(N1, Xs, V, Ys).

all_zero([]).
all_zero([0|Xs]) :- all_zero(Xs).

weaving_unrank(Lengths, Rank, Weave) :-
    weave_prepare(Lengths, Memo0, Count),
    Rank >= 1,
    Rank =< Count,
    weave_unrank_state(Lengths, Lengths, 0, 0, Rank, Memo0, _, [], Rev),
    reverse(Rev, Weave).

weave_unrank_state(_, Remaining, _, _, _, Memo, Memo, Acc, Acc) :- all_zero(Remaining), !.
weave_unrank_state(Lengths, Remaining, Opened, Closed, Rank,
                   Memo0, Memo, Acc, Out) :-
    length(Lengths, M),
    weave_pick_move(1, M, Lengths, Remaining, Opened, Closed, Rank,
                    Memo0, Memo1,
                    J, NextRemaining, NextOpened, NextClosed, NextRank),
    weave_unrank_state(Lengths, NextRemaining, NextOpened, NextClosed,
                       NextRank, Memo1, Memo, [J|Acc], Out).

weave_pick_move(J, M, Lengths, Remaining, Opened, Closed, Rank,
                Memo0, Memo,
                Chosen, NextRemaining, NextOpened, NextClosed, NextRank) :-
    J =< M,
    ( legal_weave_move(J, Lengths, Remaining, Opened, Closed) ->
        apply_weave_move(J, Lengths, Remaining, Opened, Closed,
                         CandidateRemaining, CandidateOpened, CandidateClosed),
        weave_count_state(Lengths, CandidateRemaining, CandidateOpened, CandidateClosed,
                          Memo0, Memo1, Block),
        ( Rank > Block ->
            Rank2 is Rank - Block,
            J2 is J + 1,
            weave_pick_move(J2, M, Lengths, Remaining, Opened, Closed, Rank2,
                            Memo1, Memo,
                            Chosen, NextRemaining, NextOpened, NextClosed, NextRank)
        ; Chosen = J,
          NextRemaining = CandidateRemaining,
          NextOpened = CandidateOpened,
          NextClosed = CandidateClosed,
          NextRank = Rank,
          Memo = Memo1
        )
    ; J2 is J + 1,
      weave_pick_move(J2, M, Lengths, Remaining, Opened, Closed, Rank,
                      Memo0, Memo,
                      Chosen, NextRemaining, NextOpened, NextClosed, NextRank)
    ).

positive_gate_gap(N, Gap) :-
    foundation_day(F),
    Target is F + N,
    sauce(F, Target, R),
    seal_gate_gap(Seal),
    ask_bowl(R, 1, Seal, Stream),
    choose_rank(Stream, 922, Chosen),
    Gap is 41 + Chosen.

negative_gate_gap(N, Gap) :-
    foundation_day(F),
    Target is F - N,
    sauce(F, Target, R),
    seal_gate_gap(Seal),
    ask_bowl(R, 1, Seal, Stream),
    choose_rank(Stream, 922, Chosen),
    Gap is 41 + Chosen.

new_gate_state(Cache) :-
    empty_assoc(Empty),
    foundation_day(F),
    put_assoc(0, Empty, F, Cache).

ensure_gate_index(Index, Day) :-
    new_gate_state(Cache0),
    ensure_gate_index_state(Index, Cache0, _, Day).

ensure_gate_index_state(Index, Cache0, Cache, Day) :-
    ( get_assoc(Index, Cache0, Existing) ->
        Day = Existing,
        Cache = Cache0
    ; Index > 0 ->
        Prev is Index - 1,
        ensure_gate_index_state(Prev, Cache0, Cache1, PrevDay),
        positive_gate_gap(Index, Gap),
        Day is PrevDay + Gap,
        put_assoc(Index, Cache1, Day, Cache)
    ; Index < 0 ->
        Next is Index + 1,
        ensure_gate_index_state(Next, Cache0, Cache1, NextDay),
        N is abs(Index),
        negative_gate_gap(N, Gap),
        Day is NextDay - Gap,
        put_assoc(Index, Cache1, Day, Cache)
    ).

ensure_gates_cover_state(Low, High, Cache0, Cache) :-
    ensure_day_reached_state(Low, Cache0, Cache1),
    ensure_day_reached_state(High, Cache1, Cache).

ensure_day_reached_state(Day, Cache0, Cache) :-
    foundation_day(F),
    ( Day >= F -> extend_positive_to_day_state(1, Day, Cache0, Cache)
    ; extend_negative_to_day_state(-1, Day, Cache0, Cache)
    ).

extend_positive_to_day_state(Index, Day, Cache0, Cache) :-
    ensure_gate_index_state(Index, Cache0, Cache1, GateDay),
    ( GateDay >= Day -> Cache = Cache1
    ; Index2 is Index + 1,
      extend_positive_to_day_state(Index2, Day, Cache1, Cache)
    ).

extend_negative_to_day_state(Index, Day, Cache0, Cache) :-
    ensure_gate_index_state(Index, Cache0, Cache1, GateDay),
    ( GateDay =< Day -> Cache = Cache1
    ; Index2 is Index - 1,
      extend_negative_to_day_state(Index2, Day, Cache1, Cache)
    ).

known_gate_bounds(Cache, Min, Max) :-
    assoc_to_keys(Cache, Indices),
    min_list(Indices, Min),
    max_list(Indices, Max).

gate_index_at_or_before_state(Day, Cache0, Cache, Index) :-
    ensure_day_reached_state(Day, Cache0, Cache1),
    known_gate_bounds(Cache1, Min, Max),
    binary_gate_before_state(Min, Max, Day, Cache1, Index),
    Cache = Cache1.

binary_gate_before_state(Lo, Hi, _, _, Lo) :- Lo >= Hi, !.
binary_gate_before_state(Lo, Hi, Day, Cache, Index) :-
    Mid is Lo + ((Hi - Lo + 1) // 2),
    get_assoc(Mid, Cache, MidDay),
    ( MidDay =< Day -> binary_gate_before_state(Mid, Hi, Day, Cache, Index)
    ; Hi2 is Mid - 1,
      binary_gate_before_state(Lo, Hi2, Day, Cache, Index)
    ).

gate_index_at_or_after_state(Day, Cache0, Cache, Index) :-
    gate_index_at_or_before_state(Day, Cache0, Cache1, I),
    get_assoc(I, Cache1, GateDay),
    ( GateDay =:= Day ->
        Index = I,
        Cache = Cache1
    ; I2 is I + 1,
      ensure_gate_index_state(I2, Cache1, Cache, _),
      Index = I2
    ).

exact_gate_index(Day, Index) :-
    new_gate_state(Cache0),
    exact_gate_index_state(Day, Cache0, _, Index).

exact_gate_index_state(Day, Cache0, Cache, Index) :-
    gate_index_at_or_before_state(Day, Cache0, Cache, I),
    get_assoc(I, Cache, GateDay),
    ( GateDay =:= Day -> Index = I ; Index = none ).

year_pair_valid_cached(Cache, Open, Close) :-
    min_gate_gaps_per_year(MinGaps),
    Close - Open >= MinGaps,
    get_assoc(Open, Cache, OD),
    get_assoc(Close, Cache, CD),
    L is CD - OD,
    year_min_days(MinDays),
    year_max_days(MaxDays),
    L >= MinDays,
    L =< MaxDays.

year5000(CalculationDay, Year) :-
    new_gate_state(Cache0),
    year5000_state(CalculationDay, Cache0, _, Year).

year5000_state(CalculationDay, Cache0, Cache, Year) :-
    year_max_days(MaxDays),
    Low is CalculationDay - MaxDays,
    High is CalculationDay + MaxDays,
    ensure_gates_cover_state(Low, High, Cache0, Cache1),
    gate_index_at_or_before_state(Low, Cache1, Cache2, MinIndex),
    gate_index_at_or_after_state(High, Cache2, Cache3, MaxIndex),
    findall(key(Len,OpenDay)-pair(I,J),
        ( between(MinIndex, MaxIndex, I),
          J0 is I + 1,
          J0 =< MaxIndex,
          between(J0, MaxIndex, J),
          year_pair_valid_cached(Cache3,I,J),
          get_assoc(I, Cache3, OpenDay),
          get_assoc(J, Cache3, CloseDay),
          OpenDay < CalculationDay,
          CalculationDay =< CloseDay,
          Len is CloseDay - OpenDay
        ),
        Candidates0),
    keysort(Candidates0, Candidates),
    length(Candidates, N),
    N >= 1,
    sauce(CalculationDay, CalculationDay, R),
    seal_year_5000(Seal),
    ask_bowl(R, 1, Seal, Stream),
    choose_rank(Stream, N, Rank),
    nth1(Rank, Candidates, _-pair(Open,Close)),
    get_assoc(Open, Cache3, OpenDay),
    get_assoc(Close, Cache3, CloseDay),
    Year = year(5000,Open,Close,OpenDay,CloseDay),
    Cache = Cache3.

next_year_state(CalculationDay, year(Number,_,Close,_,_), Cache0, Cache, Year) :-
    J0 is Close + 1,
    collect_next_year_candidates_state(Close, J0, Cache0, Cache1, [], Rev),
    reverse(Rev, CandidatesInGenerationOrder),
    keysort(CandidatesInGenerationOrder, Sorted),
    length(Sorted, N),
    N >= 1,
    get_assoc(Close, Cache1, OpenDay),
    sauce(CalculationDay, OpenDay, R),
    seal_next_year(Seal),
    ask_bowl(R, 1, Seal, Stream),
    choose_rank(Stream, N, Rank),
    nth1(Rank, Sorted, _Len-CloseIndex),
    get_assoc(CloseIndex, Cache1, CloseDay),
    Number2 is Number + 1,
    Year = year(Number2,Close,CloseIndex,OpenDay,CloseDay),
    Cache = Cache1.

collect_next_year_candidates_state(Open, J, Cache0, Cache, Acc, Candidates) :-
    ensure_gate_index_state(Open, Cache0, Cache1, OpenDay),
    ensure_gate_index_state(J, Cache1, Cache2, CloseDay),
    Len is CloseDay - OpenDay,
    year_max_days(MaxDays),
    ( Len > MaxDays ->
        Candidates = Acc,
        Cache = Cache2
    ; ( year_pair_valid_cached(Cache2,Open,J) -> Acc1 = [Len-J|Acc] ; Acc1 = Acc ),
      J2 is J + 1,
      collect_next_year_candidates_state(Open, J2, Cache2, Cache, Acc1, Candidates)
    ).

previous_year_state(CalculationDay, year(Number,Open,_,_,_), Cache0, Cache, Year) :-
    I0 is Open - 1,
    collect_previous_year_candidates_state(Open, I0, Cache0, Cache1, [], Rev),
    reverse(Rev, CandidatesInGenerationOrder),
    keysort(CandidatesInGenerationOrder, Sorted),
    length(Sorted, N),
    N >= 1,
    get_assoc(Open, Cache1, CloseDay),
    sauce(CalculationDay, CloseDay, R),
    seal_previous_year(Seal),
    ask_bowl(R, 1, Seal, Stream),
    choose_rank(Stream, N, Rank),
    nth1(Rank, Sorted, _Len-OpenIndex),
    get_assoc(OpenIndex, Cache1, OpenDay),
    Number2 is Number - 1,
    Year = year(Number2,OpenIndex,Open,OpenDay,CloseDay),
    Cache = Cache1.

collect_previous_year_candidates_state(Close, I, Cache0, Cache, Acc, Candidates) :-
    ensure_gate_index_state(Close, Cache0, Cache1, CloseDay),
    ensure_gate_index_state(I, Cache1, Cache2, OpenDay),
    Len is CloseDay - OpenDay,
    year_max_days(MaxDays),
    ( Len > MaxDays ->
        Candidates = Acc,
        Cache = Cache2
    ; ( year_pair_valid_cached(Cache2,I,Close) -> Acc1 = [Len-I|Acc] ; Acc1 = Acc ),
      I2 is I - 1,
      collect_previous_year_candidates_state(Close, I2, Cache2, Cache, Acc1, Candidates)
    ).

find_target_year(CalculationDay, TargetDay, Year) :-
    new_gate_state(Cache0),
    find_target_year_state(CalculationDay, TargetDay, Cache0, _, Year).

find_target_year_state(CalculationDay, TargetDay, Cache0, Cache, Year) :-
    year5000_state(CalculationDay, Cache0, Cache1, Y0),
    walk_forward_if_needed_state(CalculationDay, TargetDay, Y0, Cache1, Cache2, Y1),
    walk_backward_if_needed_state(CalculationDay, TargetDay, Y1, Cache2, Cache, Year).

walk_forward_if_needed_state(CalculationDay, TargetDay, Y0, Cache0, Cache, Year) :-
    Y0 = year(_,_,_,_,CloseDay),
    ( TargetDay > CloseDay ->
        next_year_state(CalculationDay, Y0, Cache0, Cache1, Y1),
        walk_forward_if_needed_state(CalculationDay, TargetDay, Y1, Cache1, Cache, Year)
    ; Year = Y0,
      Cache = Cache0
    ).

walk_backward_if_needed_state(CalculationDay, TargetDay, Y0, Cache0, Cache, Year) :-
    Y0 = year(_,_,_,OpenDay,_),
    ( TargetDay =< OpenDay ->
        previous_year_state(CalculationDay, Y0, Cache0, Cache1, Y1),
        walk_backward_if_needed_state(CalculationDay, TargetDay, Y1, Cache1, Cache, Year)
    ; Year = Y0,
      Cache = Cache0
    ).

choose_cutlet_count(StructureSauce, year(_,Open,Close,_,_), K) :-
    GapCount is Close - Open,
    min_cutlets(MinK),
    max_cutlets(MaxK),
    findall(X, (between(MinK,MaxK,X), X =< GapCount), Candidates),
    length(Candidates, N),
    seal_cutlet_count(Seal),
    ask_bowl(StructureSauce, 2, Seal, Stream),
    choose_rank(Stream, N, Rank),
    nth1(Rank, Candidates, K).

required_cutlet_boundary(CalculationDay, year(_,Open,Close,OpenDay,CloseDay), Required) :-
    ( CalculationDay > OpenDay,
      CalculationDay < CloseDay,
      exact_gate_index(CalculationDay, GateIndex),
      GateIndex \= none,
      GateIndex > Open,
      GateIndex < Close ->
        Required is GateIndex - Open
    ; Required = none
    ).

cutlet_partition_prepare(G, K, Required, Memo, Count) :-
    empty_assoc(Memo0),
    cp_count(G, K, Required, G, K, 0, false, Memo0, Memo, Count).

cp_count(G, K, Req, Rem, Slots, Cum, Hit, Memo0, Memo, Count) :-
    Key = cp(G,K,Req,Rem,Slots,Cum,Hit),
    ( get_assoc(Key, Memo0, Cached) ->
        Count = Cached,
        Memo = Memo0
    ; cp_count_uncached(G,K,Req,Rem,Slots,Cum,Hit,Memo0,Memo1,Count),
      put_assoc(Key, Memo1, Count, Memo)
    ).

cp_count_uncached(_,_,Req,Rem,0,_,Hit,Memo,Memo,Count) :-
    !,
    ( Rem =:= 0,
      ( Req == none ; Hit == true ) -> Count = 1 ; Count = 0 ).
cp_count_uncached(_,_,_,Rem,Slots,_,_,Memo,Memo,0) :- Rem < Slots, !.
cp_count_uncached(G,K,Req,Rem,Slots,Cum,Hit,Memo0,Memo,Count) :-
    MaxX is Rem - (Slots - 1),
    cp_sum_x(1, MaxX, G,K,Req,Rem,Slots,Cum,Hit,Memo0,Memo,0,Count).

cp_sum_x(X, MaxX, _,_,_,_,_,_,_,Memo,Memo,Acc,Acc) :- X > MaxX, !.
cp_sum_x(X, MaxX, G,K,Req,Rem,Slots,Cum,Hit,Memo0,Memo,Acc0,Count) :-
    cp_transition(Req, X, Cum, Hit, NextCum, NextHit, Allowed),
    ( Allowed == true ->
        Rem1 is Rem - X,
        Slots1 is Slots - 1,
        cp_count(G,K,Req,Rem1,Slots1,NextCum,NextHit,Memo0,Memo1,Block)
    ; Block = 0,
      Memo1 = Memo0
    ),
    Acc1 is Acc0 + Block,
    X2 is X + 1,
    cp_sum_x(X2, MaxX, G,K,Req,Rem,Slots,Cum,Hit,Memo1,Memo,Acc1,Count).

cp_transition(none, X, Cum, Hit, NextCum, Hit, true) :-
    NextCum is Cum + X.
cp_transition(Req, X, Cum, true, NextCum, true, true) :-
    Req \== none,
    NextCum is Cum + X.
cp_transition(Req, X, Cum, false, NextCum, NextHit, Allowed) :-
    Req \== none,
    NextCum is Cum + X,
    ( NextCum =:= Req -> NextHit = true, Allowed = true
    ; NextCum < Req -> NextHit = false, Allowed = true
    ; NextHit = false, Allowed = false
    ).

cutlet_partition_unrank(G,K,Req,Rank,Memo0,Partition) :-
    cp_unrank(G,K,Req,G,K,0,false,Rank,Memo0,_,Partition).

cp_unrank(_,_,_,_,0,_,_,_,Memo,Memo,[]) :- !.
cp_unrank(G,K,Req,Rem,Slots,Cum,Hit,Rank,Memo0,Memo,[X|Rest]) :-
    MaxX is Rem - (Slots - 1),
    cp_pick_x(1,MaxX,G,K,Req,Rem,Slots,Cum,Hit,Rank,Memo0,Memo1,
              X,NextCum,NextHit,NextRank),
    Rem1 is Rem - X,
    Slots1 is Slots - 1,
    cp_unrank(G,K,Req,Rem1,Slots1,NextCum,NextHit,NextRank,Memo1,Memo,Rest).

cp_pick_x(X,MaxX,G,K,Req,Rem,Slots,Cum,Hit,Rank,
          Memo0,Memo,Chosen,NextCum,NextHit,NextRank) :-
    X =< MaxX,
    cp_transition(Req,X,Cum,Hit,CandidateCum,CandidateHit,Allowed),
    ( Allowed == true ->
        Rem1 is Rem - X,
        Slots1 is Slots - 1,
        cp_count(G,K,Req,Rem1,Slots1,CandidateCum,CandidateHit,Memo0,Memo1,Block)
    ; Block = 0,
      Memo1 = Memo0
    ),
    ( Block =:= 0 ->
        X2 is X + 1,
        cp_pick_x(X2,MaxX,G,K,Req,Rem,Slots,Cum,Hit,Rank,
                  Memo1,Memo,Chosen,NextCum,NextHit,NextRank)
    ; Rank > Block ->
        Rank2 is Rank - Block,
        X2 is X + 1,
        cp_pick_x(X2,MaxX,G,K,Req,Rem,Slots,Cum,Hit,Rank2,
                  Memo1,Memo,Chosen,NextCum,NextHit,NextRank)
    ; Chosen = X,
      NextCum = CandidateCum,
      NextHit = CandidateHit,
      NextRank = Rank,
      Memo = Memo1
    ).

choose_cutlet_partition(CalculationDay, StructureSauce,
                        Year = year(_,Open,Close,_,_), K, Partition) :-
    G is Close - Open,
    required_cutlet_boundary(CalculationDay, Year, Required),
    cutlet_partition_prepare(G,K,Required,Memo,Count),
    Count >= 1,
    seal_cutlet_partition(Seal),
    ask_bowl(StructureSauce, 2, Seal, Stream),
    choose_rank(Stream, Count, Rank),
    cutlet_partition_unrank(G,K,Required,Rank,Memo,Partition).

choose_cutlet_names(StructureSauce, K, Indices) :-
    falling_factorial(17,K,N),
    seal_cutlet_names(Seal),
    ask_bowl(StructureSauce, 5, Seal, Stream),
    choose_rank(Stream,N,Rank),
    unrank_distinct_indices(K,Rank,Indices).

materialize_cutlets(year(_,Open,_,_,_), Partition, NameIndices, Cutlets) :-
    materialize_cutlets_loop(Open, Partition, NameIndices, Cutlets).

materialize_cutlets_loop(_, [], [], []).
materialize_cutlets_loop(Cursor, [Gap|Gaps], [Name|Names],
                         [cutlet(Name,Cursor,Close,FirstDay,LastDay)|Rest]) :-
    Close is Cursor + Gap,
    ensure_gate_index(Cursor, OpenDay),
    ensure_gate_index(Close, CloseDay),
    FirstDay is OpenDay + 1,
    LastDay = CloseDay,
    materialize_cutlets_loop(Close, Gaps, Names, Rest).

choose_month_count(StructureSauce, year(_,_,_,OpenDay,CloseDay), K) :-
    L is CloseDay - OpenDay,
    min_month_days(MinD),
    max_month_days(MaxD),
    ceil_div(L, MaxD, Lo),
    Hi0 is L // MinD,
    max_months(MaxM),
    ( Hi0 < MaxM -> Hi = Hi0 ; Hi = MaxM ),
    Lo =< Hi,
    Count is Hi - Lo + 1,
    seal_month_count(Seal),
    ask_bowl(StructureSauce, 3, Seal, Stream),
    choose_rank(Stream, Count, Rank),
    K is Lo + Rank - 1.

choose_month_lengths(StructureSauce, year(_,_,_,OpenDay,CloseDay), K, Lengths) :-
    L is CloseDay - OpenDay,
    min_month_days(Lo),
    max_month_days(Hi),
    bounded_composition_count(L,K,Lo,Hi,Count),
    seal_month_lengths(Seal),
    ask_bowl(StructureSauce, 3, Seal, Stream),
    choose_rank(Stream,Count,Rank),
    bounded_composition_unrank(L,K,Lo,Hi,Rank,Lengths).

choose_month_weaving(StructureSauce, Lengths, Weave) :-
    weaving_count(Lengths,Count),
    seal_month_weaving(Seal),
    ask_bowl(StructureSauce,4,Seal,Stream),
    choose_rank(Stream,Count,Rank),
    weaving_unrank(Lengths,Rank,Weave).

unrank_distinct_master(N, K, Rank, Indices) :-
    range_list(1,N,Remaining),
    unrank_distinct_from(Remaining,K,Rank,Indices).

choose_month_names(StructureSauce, K, Indices) :-
    falling_factorial(47,K,N),
    seal_month_names(Seal),
    ask_bowl(StructureSauce,5,Seal,Stream),
    choose_rank(Stream,N,Rank),
    unrank_distinct_master(47,K,Rank,Indices).

build_year_structure(CalculationDay,
                     Year = year(_,_,_,OpenDay,_),
                     year_structure(K,Partition,CutletNames,Cutlets,
                                    MonthCount,MonthLengths,Weave,MonthNames)) :-
    FirstDay is OpenDay + 1,
    sauce(CalculationDay, FirstDay, StructureSauce),
    choose_cutlet_count(StructureSauce,Year,K),
    choose_cutlet_partition(CalculationDay,StructureSauce,Year,K,Partition),
    choose_cutlet_names(StructureSauce,K,CutletNames),
    materialize_cutlets(Year,Partition,CutletNames,Cutlets),
    choose_month_count(StructureSauce,Year,MonthCount),
    choose_month_lengths(StructureSauce,Year,MonthCount,MonthLengths),
    choose_month_weaving(StructureSauce,MonthLengths,Weave),
    choose_month_names(StructureSauce,MonthCount,MonthNames).

find_cutlet_for_day([cutlet(Name,_,_,First,Last)|_], Day,
                     cutlet(Name,First,Last)) :-
    Day >= First,
    Day =< Last,
    !.
find_cutlet_for_day([_|Rest], Day, Cutlet) :-
    find_cutlet_for_day(Rest, Day, Cutlet).

count_occurrences_prefix(List, Limit, Value, Count) :-
    count_occurrences_prefix(List, 1, Limit, Value, 0, Count).

count_occurrences_prefix(_, Pos, Limit, _, Acc, Acc) :- Pos > Limit, !.
count_occurrences_prefix(List, Pos, Limit, Value, Acc0, Count) :-
    nth1(Pos,List,X),
    ( X =:= Value -> Acc1 is Acc0 + 1 ; Acc1 = Acc0 ),
    Pos1 is Pos + 1,
    count_occurrences_prefix(List,Pos1,Limit,Value,Acc1,Count).

calendar_date(CalculationDay, TargetDay,
              date(YearNumber,CutletName,DayInCutlet,MonthName,DayInMonth)) :-
    integer(CalculationDay),
    integer(TargetDay),
    find_target_year(CalculationDay,TargetDay,Year),
    Year = year(YearNumber,_,_,OpenDay,_),
    build_year_structure(CalculationDay,Year,Structure),
    Structure = year_structure(_,_,_,Cutlets,_,_,Weave,MonthNames),
    find_cutlet_for_day(Cutlets,TargetDay,cutlet(CutletIndex,CutletFirst,_)),
    DayInCutlet is TargetDay - CutletFirst + 1,
    Offset0 is TargetDay - (OpenDay + 1),
    Position is Offset0 + 1,
    nth1(Position,Weave,MonthId),
    nth1(MonthId,MonthNames,MonthIndex),
    count_occurrences_prefix(Weave,Position,MonthId,DayInMonth),
    cutlet_source_name(CutletIndex,CutletName),
    month_source_name(MonthIndex,MonthName).
