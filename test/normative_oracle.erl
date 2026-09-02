-module(normative_oracle).
-export([
    m/0, tablets_day/0, foundation_day/0,
    regular_mod/2, save/1, ceil_div/2, wrap1/2,
    day_count/1, work_counts/2,
    build_stones/0, build_hidden_drops/2, build_visible_drops/3,
    permutation_unrank1/2, bowl_order_from_number/1, bowl_order_from_drop/1,
    initial_bowls/1, apply_visible_drops_to_bowls/3, post_stir12/1,
    sauce/2, ask_bowl/3, answer_at/2,
    choose_rank_short/2, choose_rank_wide/2, choose_rank/2,
    falling_factorial/2, unrank_distinct_indices/3,
    count_bounded_compositions/4, unrank_bounded_composition/5,
    count_cutlet_partitions/3, unrank_cutlet_partition/4,
    count_weavings/1, unrank_weaving/2,
    new_gate_state/0, ensure_gate_index/2, exact_gate_index/2,
    year5000/2, next_year/3, previous_year/3, find_target_year/3,
    build_year_structure/3, calendar_date_indices/2, calendar_date/2
]).

m() -> (1 bsl 127) - 1.
tablets_day() -> -278522.
foundation_day() -> -15055671.

regular_mod(X, D) when is_integer(X), is_integer(D), D >= 1 ->
    R = X rem D,
    case R < 0 of true -> R + D; false -> R end.

save(X) when is_integer(X) -> 1 + regular_mod(X - 1, m()).
ceil_div(A, B) when A >= 0, B >= 1 -> (A + B - 1) div B.
wrap1(Position, Size) when Size >= 1 -> regular_mod(Position - 1, Size) + 1.
square(X) -> X * X.


day_count(Day) when is_integer(Day) ->
    F = foundation_day(),
    if
        Day =:= F -> 1;
        Day > F -> 2 * (Day - F) + 1;
        true -> 2 * (F - Day)
    end.

work_counts(CalculationDay, TargetDay) ->
    C = day_count(CalculationDay),
    T = day_count(TargetDay),
    Distance = abs(TargetDay - CalculationDay) + 1,
    Direction = if TargetDay < CalculationDay -> 1;
                   TargetDay =:= CalculationDay -> 2;
                   true -> 3
                end,
    #{action => C,
      target => T,
      distance => Distance,
      connection => C + T,
      direction => Direction}.

build_stones() ->
    build_stones(2, {17, 29, 43, 71, 101}, [{17, 29, 43, 71, 101}]).

build_stones(47, _Old, Acc) -> lists:reverse(Acc);
build_stones(I, Old, Acc) ->
    {W, B, S, Bitter, R} = Old,
    Next = {
        save(square(W) + 3 * B + I),
        save(square(B) + 5 * S + W),
        save(square(S) + 7 * Bitter + B),
        save(square(Bitter) + 11 * R + S),
        save(square(R) + 13 * W + Bitter)
    },
    build_stones(I + 1, Next, [Next | Acc]).

hidden_coeff(1) -> {3, 4, 6, 8};
hidden_coeff(2) -> {5, 7, 10, 12};
hidden_coeff(3) -> {7, 10, 14, 16};
hidden_coeff(4) -> {9, 13, 18, 20};
hidden_coeff(5) -> {11, 16, 22, 24};
hidden_coeff(6) -> {13, 19, 26, 28};
hidden_coeff(7) -> {15, 22, 30, 32}.

hidden_grind_kind(1) -> 1;
hidden_grind_kind(2) -> 2;
hidden_grind_kind(3) -> 3;
hidden_grind_kind(4) -> 4;
hidden_grind_kind(5) -> 5;
hidden_grind_kind(6) -> 1;
hidden_grind_kind(7) -> 2.

build_hidden_drops(Counts, Stones) ->
    [build_one_hidden(K, Counts, Stones) || K <- lists:seq(1, 7)].

build_one_hidden(K, Counts, Stones) ->
    {A, B, C, D} = hidden_coeff(K),
    Stone = lists:nth(K, Stones),
    X0 = maps:get(action, Counts)
       + A * maps:get(target, Counts)
       + B * maps:get(distance, Counts)
       + C * maps:get(connection, Counts)
       + D * maps:get(direction, Counts)
       + lists:sum(tuple_to_list(Stone)),
    hidden_grinds(1, 7, save(X0), K, Stones).

hidden_grinds(G, Max, X, _K, _Stones) when G > Max -> X;
hidden_grinds(G, Max, X, K, Stones) ->
    OldX = X,
    Stone = lists:nth(K, Stones),
    Kind = hidden_grind_kind(G),
    X1 = save(square(OldX) + 3 * OldX + element(Kind, Stone) + G),
    hidden_grinds(G + 1, Max, X1, K, Stones).

visible_grind(1) -> {3, 5, 7, 11, 1};
visible_grind(2) -> {5, 7, 11, 13, 2};
visible_grind(3) -> {7, 11, 13, 17, 3};
visible_grind(4) -> {11, 13, 17, 19, 4};
visible_grind(5) -> {13, 17, 19, 23, 5};
visible_grind(6) -> {17, 19, 23, 29, 1};
visible_grind(7) -> {19, 23, 29, 31, 2};
visible_grind(8) -> {23, 29, 31, 37, 3};
visible_grind(9) -> {29, 31, 37, 41, 4};
visible_grind(10) -> {31, 37, 41, 43, 5};
visible_grind(11) -> {37, 41, 43, 47, 1}.

build_visible_drops(Counts, Stones, Hidden) ->
    Timeline0 = seed_hidden(Hidden, 1, #{}),
    {VisibleRev, _Timeline} = visible_loop(1, Counts, Stones, Timeline0, []),
    lists:reverse(VisibleRev).

seed_hidden([], _K, Timeline) -> Timeline;
seed_hidden([V | Rest], K, Timeline) ->
    seed_hidden(Rest, K + 1, maps:put(1 - K, V, Timeline)).

visible_loop(47, _Counts, _Stones, Timeline, Acc) -> {Acc, Timeline};
visible_loop(I, Counts, Stones, Timeline, Acc) ->
    P1 = maps:get(I - 1, Timeline),
    P3 = maps:get(I - 3, Timeline),
    P7 = maps:get(I - 7, Timeline),
    Stone = lists:nth(I, Stones),
    X0 = save(
        element(1, Stone) * maps:get(action, Counts)
        + element(2, Stone) * maps:get(target, Counts)
        + element(3, Stone) * maps:get(distance, Counts)
        + element(4, Stone) * maps:get(connection, Counts)
        + element(5, Stone) * maps:get(direction, Counts)
        + P1 + 3 * P3 + 5 * P7 + I
    ),
    X = visible_grinds(1, X0, P1, P3, P7, Stone),
    Timeline1 = maps:put(I, X, Timeline),
    visible_loop(I + 1, Counts, Stones, Timeline1, [X | Acc]).

visible_grinds(12, X, _P1, _P3, _P7, _Stone) -> X;
visible_grinds(G, X, P1, P3, P7, Stone) ->
    OldX = X,
    {A, B, C, D, Kind} = visible_grind(G),
    X1 = save(square(OldX) + A * OldX + B * P1 + C * P3 + D * P7 + element(Kind, Stone)),
    visible_grinds(G + 1, X1, P1, P3, P7, Stone).

factorial(0) -> 1;
factorial(N) when N > 0 -> N * factorial(N - 1).

permutation_unrank1(Rank1, Items) when Rank1 >= 1 ->
    Max = factorial(length(Items)),
    true = Rank1 =< Max,
    permutation_unrank0(Rank1 - 1, Items, []).

permutation_unrank0(_Rank0, [], Acc) -> lists:reverse(Acc);
permutation_unrank0(Rank0, Remaining, Acc) ->
    Block = factorial(length(Remaining) - 1),
    Q = Rank0 div Block,
    Remainder = regular_mod(Rank0, Block),
    {Chosen, Rest} = take_nth(Q + 1, Remaining),
    permutation_unrank0(Remainder, Rest, [Chosen | Acc]).

take_nth(1, [H | T]) -> {H, T};
take_nth(N, [H | T]) when N > 1 ->
    {Chosen, Rest} = take_nth(N - 1, T),
    {Chosen, [H | Rest]}.

bowl_order_from_number(OrderNumber) when OrderNumber >= 1, OrderNumber =< 720 ->
    permutation_unrank1(OrderNumber, [1, 2, 3, 4, 5, 6]).

bowl_order_from_drop(DropValue) ->
    bowl_order_from_number(regular_mod(DropValue - 1, 720) + 1).

initial_bowls(Counts) ->
    Primes = [17, 19, 23, 29, 31, 37],
    list_to_tuple([
        begin
            Prime = lists:nth(Id, Primes),
            S = maps:get(action, Counts)
              + maps:get(target, Counts) * Id
              + maps:get(distance, Counts)
              + maps:get(connection, Counts)
              + maps:get(direction, Counts)
              + square(Prime),
            save(square(S) + Id)
        end || Id <- lists:seq(1, 6)
    ]).

apply_visible_drops_to_bowls(Bowls, Visible, Stones) ->
    apply_visible_loop(1, Bowls, Visible, Stones, undefined).

apply_visible_loop(47, Bowls, _Visible, _Stones, Order46) -> {Bowls, Order46};
apply_visible_loop(I, Bowls, Visible, Stones, _Order46) ->
    Drop = lists:nth(I, Visible),
    Order = bowl_order_from_drop(Drop),
    Old = Bowls,
    Pour = make_pours(I, Drop, Stones, Old, Order),
    Next = stir_one_visible(I, Drop, Stones, Old, Order, Pour),
    Latch = case I of 46 -> Order; _ -> undefined end,
    apply_visible_loop(I + 1, Next, Visible, Stones, Latch).

make_pours(I, Drop, Stones, Old, Order) ->
    Stone = lists:nth(I, Stones),
    First = lists:nth(1, Order),
    Second = lists:nth(2, Order),
    Third = lists:nth(3, Order),
    #{1 => save(square(Drop) + element(1, Stone) * element(First, Old) + 3 * I),
      2 => save(square(Drop) + element(2, Stone) * element(Second, Old) + 5 * I),
      3 => save(square(Drop) + element(3, Stone) * element(Third, Old) + 7 * I)}.

stir_one_visible(I, Drop, Stones, Old, Order, Pour) ->
    Stone = lists:nth(I, Stones),
    Pairs = [
        begin
            Id = lists:nth(Position, Order),
            Prev = lists:nth(wrap1(Position - 1, 6), Order),
            Next = lists:nth(wrap1(Position + 1, 6), Order),
            StoneKind = visible_bowl_stone(Position),
            PourValue = maps:get(Position, Pour, 0),
            S = element(Id, Old)
              + 2 * element(Prev, Old)
              + 3 * element(Next, Old)
              + PourValue + Drop + element(StoneKind, Stone),
            {Id, save(square(S) + 5 * element(Prev, Old) * element(Next, Old) + I * Position)}
        end || Position <- lists:seq(1, 6)
    ],
    Sorted = lists:keysort(1, Pairs),
    list_to_tuple([V || {_Id, V} <- Sorted]).

visible_bowl_stone(1) -> 1;
visible_bowl_stone(2) -> 2;
visible_bowl_stone(3) -> 3;
visible_bowl_stone(4) -> 4;
visible_bowl_stone(5) -> 5;
visible_bowl_stone(6) -> 1.

post_stir12(Bowls) -> post_stir_loop(1, Bowls).
post_stir_loop(13, Bowls) -> Bowls;
post_stir_loop(Stir, Bowls) ->
    Old = Bowls,
    Saved = save(lists:sum(tuple_to_list(Old)) + 149 * Stir),
    OrderNumber = regular_mod(Saved - 1, 720) + 1,
    Order = bowl_order_from_number(OrderNumber),
    Pairs = [post_stir_value(Position, Stir, Old, Order, Saved) || Position <- lists:seq(1, 6)],
    Sorted = lists:keysort(1, Pairs),
    Next = list_to_tuple([V || {_Id, V} <- Sorted]),
    post_stir_loop(Stir + 1, Next).

post_stir_value(Position, Stir, Old, Order, Saved) ->
    Id = lists:nth(Position, Order),
    Prev = lists:nth(wrap1(Position - 1, 6), Order),
    Next = lists:nth(wrap1(Position + 1, 6), Order),
    S = element(Id, Old)
      + 3 * element(Prev, Old)
      + 5 * element(Next, Old)
      + Saved + Stir + square(Position),
    {Id, save(square(S) + 7 * element(Prev, Old) * element(Next, Old))}.

sauce(CalculationDay, TargetDay) ->
    Counts = work_counts(CalculationDay, TargetDay),
    Stones = build_stones(),
    Hidden = build_hidden_drops(Counts, Stones),
    Visible = build_visible_drops(Counts, Stones, Hidden),
    Bowls0 = initial_bowls(Counts),
    {Bowls1, Order46} = apply_visible_drops_to_bowls(Bowls0, Visible, Stones),
    #{bowls => post_stir12(Bowls1), order_at_drop46 => Order46}.

index_of1(Item, List) -> index_of1(Item, List, 1).
index_of1(Item, [Item | _], Pos) -> Pos;
index_of1(Item, [_ | Rest], Pos) -> index_of1(Item, Rest, Pos + 1).

ask_bowl(SauceResult, QueriedBowlId, Seal) ->
    Order = maps:get(order_at_drop46, SauceResult),
    Pos = index_of1(QueriedBowlId, Order),
    NextId = lists:nth(wrap1(Pos + 1, 6), Order),
    Bowls = maps:get(bowls, SauceResult),
    First = save(square(element(QueriedBowlId, Bowls) + Seal + 181)
                 + 179 * element(NextId, Bowls) + Seal),
    DirectionNumber = save(square(First + Seal + 1 + 193)
                           + 193 * First + 197 * element(6, Bowls)),
    Step = case regular_mod(DirectionNumber, 2) of 1 -> 1; _ -> -1 end,
    #{first => First, step => Step}.

answer_at(Stream, K) when K >= 0 ->
    1 + regular_mod(maps:get(first, Stream) - 1 + maps:get(step, Stream) * K, m()).

choose_rank_short(Stream, N) when N >= 1, N =< (1 bsl 127) - 1 ->
    Limit = (m() div N) * N,
    choose_short_loop(Stream, N, Limit, 0).

choose_short_loop(Stream, N, Limit, K) ->
    X = answer_at(Stream, K),
    case X =< Limit of
        true -> regular_mod(X - 1, N) + 1;
        false -> choose_short_loop(Stream, N, Limit, K + 1)
    end.

smallest_power_count(Base, N) -> smallest_power_count(Base, N, 1, Base).
smallest_power_count(_Base, N, K, Space) when Space >= N -> {K, Space};
smallest_power_count(Base, N, K, Space) -> smallest_power_count(Base, N, K + 1, Space * Base).

choose_rank_wide(Stream, N) when N > (1 bsl 127) - 1 ->
    {K, Space} = smallest_power_count(m(), N),
    Wide0 = wide_digits(Stream, 0, K, 1, 1),
    Limit = (Space div N) * N,
    choose_wide_loop(Wide0, Stream, N, Limit, Space).

wide_digits(_Stream, J, K, Wide, _Weight) when J >= K -> Wide;
wide_digits(Stream, J, K, Wide, Weight) ->
    Digit = answer_at(Stream, J) - 1,
    wide_digits(Stream, J + 1, K, Wide + Digit * Weight, Weight * m()).

choose_wide_loop(W, Stream, N, Limit, Space) ->
    case W =< Limit of
        true -> regular_mod(W - 1, N) + 1;
        false ->
            W1 = 1 + regular_mod(W - 1 + maps:get(step, Stream), Space),
            choose_wide_loop(W1, Stream, N, Limit, Space)
    end.

choose_rank(Stream, N) when N >= 1 ->
    case N =< m() of
        true -> choose_rank_short(Stream, N);
        false -> choose_rank_wide(Stream, N)
    end.

falling_factorial(_N, 0) -> 1;
falling_factorial(N, K) when K > 0, K =< N -> N * falling_factorial(N - 1, K - 1).

unrank_distinct_indices(N, K, Rank1) when N >= K, K >= 0, Rank1 >= 1 ->
    Total = falling_factorial(N, K),
    true = Rank1 =< Total,
    unrank_distinct_loop(lists:seq(1, N), K, Rank1, []).

unrank_distinct_loop(_Remaining, 0, _Rank, Acc) -> lists:reverse(Acc);
unrank_distinct_loop(Remaining, K, Rank, Acc) ->
    Block = falling_factorial(length(Remaining) - 1, K - 1),
    CandidatePos = ((Rank - 1) div Block) + 1,
    Rank2 = regular_mod(Rank - 1, Block) + 1,
    {Chosen, Rest} = take_nth(CandidatePos, Remaining),
    unrank_distinct_loop(Rest, K - 1, Rank2, [Chosen | Acc]).

count_bounded_compositions(Total, Slots, Lo, Hi) ->
    {Count, _Memo} = bounded_count(Total, Slots, Lo, Hi, #{}),
    Count.

bounded_count(Rem, 0, _Lo, _Hi, Memo) ->
    {case Rem of 0 -> 1; _ -> 0 end, Memo};
bounded_count(Rem, K, Lo, Hi, Memo) ->
    case Rem < K * Lo orelse Rem > K * Hi of
        true -> {0, Memo};
        false ->
            Key = {Rem, K},
            case maps:find(Key, Memo) of
                {ok, V} -> {V, Memo};
                error ->
                    {Sum, Memo1} = bounded_sum(Lo, Hi, Rem, K, Lo, Hi, 0, Memo),
                    {Sum, maps:put(Key, Sum, Memo1)}
            end
    end.

bounded_sum(X, HiX, _Rem, _K, _Lo, _Hi, Sum, Memo) when X > HiX -> {Sum, Memo};
bounded_sum(X, HiX, Rem, K, Lo, Hi, Sum, Memo) ->
    {C, Memo1} = bounded_count(Rem - X, K - 1, Lo, Hi, Memo),
    bounded_sum(X + 1, HiX, Rem, K, Lo, Hi, Sum + C, Memo1).

unrank_bounded_composition(Total, Slots, Lo, Hi, Rank1) ->
    {Count, Memo0} = bounded_count(Total, Slots, Lo, Hi, #{}),
    true = Rank1 >= 1 andalso Rank1 =< Count,
    {Out, _Memo} = unrank_bounded_loop(Total, Slots, Lo, Hi, Rank1, [], Memo0),
    Out.

unrank_bounded_loop(_Rem, 0, _Lo, _Hi, _Rank, Acc, Memo) -> {lists:reverse(Acc), Memo};
unrank_bounded_loop(Rem, Slots, Lo, Hi, Rank, Acc, Memo) ->
    MaxX = min(Hi, Rem - (Slots - 1) * Lo),
    choose_bounded_x(Lo, MaxX, Rem, Slots, Lo, Hi, Rank, Acc, Memo).

choose_bounded_x(X, MaxX, Rem, Slots, Lo, Hi, Rank, Acc, Memo) when X =< MaxX ->
    {Block, Memo1} = bounded_count(Rem - X, Slots - 1, Lo, Hi, Memo),
    case Rank > Block of
        true -> choose_bounded_x(X + 1, MaxX, Rem, Slots, Lo, Hi, Rank - Block, Acc, Memo1);
        false -> unrank_bounded_loop(Rem - X, Slots - 1, Lo, Hi, Rank, [X | Acc], Memo1)
    end.

count_cutlet_partitions(G, K, Required) ->
    {Count, _Memo} = cutlet_count_dp(G, K, 0, false, Required, #{}),
    Count.

cutlet_count_dp(Rem, 0, _Cum, Hit, Required, Memo) ->
    Valid = case {Rem, Required} of
                {0, none} -> 1;
                {0, _} -> case Hit of true -> 1; false -> 0 end;
                _ -> 0
            end,
    {Valid, Memo};
cutlet_count_dp(Rem, Slots, _Cum, _Hit, _Required, Memo) when Rem < Slots -> {0, Memo};
cutlet_count_dp(Rem, Slots, Cum, Hit, Required, Memo) ->
    Key = {Rem, Slots, Cum, Hit, Required},
    case maps:find(Key, Memo) of
        {ok, V} -> {V, Memo};
        error ->
            MaxX = Rem - (Slots - 1),
            {Sum, Memo1} = cutlet_sum(1, MaxX, Rem, Slots, Cum, Hit, Required, 0, Memo),
            {Sum, maps:put(Key, Sum, Memo1)}
    end.

cutlet_sum(X, MaxX, _Rem, _Slots, _Cum, _Hit, _Required, Sum, Memo) when X > MaxX -> {Sum, Memo};
cutlet_sum(X, MaxX, Rem, Slots, Cum, Hit, Required, Sum, Memo) ->
    NextCum = Cum + X,
    case cutlet_transition_allowed(NextCum, Hit, Required) of
        skip -> cutlet_sum(X + 1, MaxX, Rem, Slots, Cum, Hit, Required, Sum, Memo);
        NextHit ->
            {C, Memo1} = cutlet_count_dp(Rem - X, Slots - 1, NextCum, NextHit, Required, Memo),
            cutlet_sum(X + 1, MaxX, Rem, Slots, Cum, Hit, Required, Sum + C, Memo1)
    end.

cutlet_transition_allowed(_NextCum, Hit, none) -> Hit;
cutlet_transition_allowed(_NextCum, true, _Required) -> true;
cutlet_transition_allowed(NextCum, false, Required) ->
    if NextCum =:= Required -> true;
       NextCum > Required -> skip;
       true -> false
    end.

unrank_cutlet_partition(G, K, Required, Rank1) ->
    {Count, Memo0} = cutlet_count_dp(G, K, 0, false, Required, #{}),
    true = Rank1 >= 1 andalso Rank1 =< Count,
    {Out, _Memo} = unrank_cutlet_loop(G, K, 0, false, Required, Rank1, [], Memo0),
    Out.

unrank_cutlet_loop(_Rem, 0, _Cum, _Hit, _Required, _Rank, Acc, Memo) -> {lists:reverse(Acc), Memo};
unrank_cutlet_loop(Rem, Slots, Cum, Hit, Required, Rank, Acc, Memo) ->
    MaxX = Rem - (Slots - 1),
    choose_cutlet_x(1, MaxX, Rem, Slots, Cum, Hit, Required, Rank, Acc, Memo).

choose_cutlet_x(X, MaxX, Rem, Slots, Cum, Hit, Required, Rank, Acc, Memo) when X =< MaxX ->
    NextCum = Cum + X,
    case cutlet_transition_allowed(NextCum, Hit, Required) of
        skip -> choose_cutlet_x(X + 1, MaxX, Rem, Slots, Cum, Hit, Required, Rank, Acc, Memo);
        NextHit ->
            {Block, Memo1} = cutlet_count_dp(Rem - X, Slots - 1, NextCum, NextHit, Required, Memo),
            case Rank > Block of
                true -> choose_cutlet_x(X + 1, MaxX, Rem, Slots, Cum, Hit, Required, Rank - Block, Acc, Memo1);
                false -> unrank_cutlet_loop(Rem - X, Slots - 1, NextCum, NextHit, Required, Rank, [X | Acc], Memo1)
            end
    end.

count_weavings(Lengths) when is_list(Lengths), Lengths =/= [] ->
    LT = list_to_tuple(Lengths),
    {Count, _Memo} = weave_count(LT, 0, 0, LT, #{}),
    Count.

weave_count(Remaining, Opened, Closed, Lengths, Memo) ->
    case all_zero(tuple_to_list(Remaining)) of
        true -> {1, Memo};
        false ->
            Key = {Remaining, Opened, Closed},
            case maps:find(Key, Memo) of
                {ok, V} -> {V, Memo};
                error ->
                    {Sum, Memo1} = weave_sum(1, tuple_size(Remaining), Remaining, Opened, Closed, Lengths, 0, Memo),
                    {Sum, maps:put(Key, Sum, Memo1)}
            end
    end.

all_zero([]) -> true;
all_zero([0 | T]) -> all_zero(T);
all_zero(_) -> false.

weave_sum(J, M, _Rem, _Open, _Closed, _Lengths, Sum, Memo) when J > M -> {Sum, Memo};
weave_sum(J, M, Rem, Open, Closed, Lengths, Sum, Memo) ->
    case legal_weave_move(Rem, Open, Closed, Lengths, J) of
        false -> weave_sum(J + 1, M, Rem, Open, Closed, Lengths, Sum, Memo);
        true ->
            {Rem2, Open2, Closed2} = apply_weave_move(Rem, Open, Closed, Lengths, J),
            {C, Memo1} = weave_count(Rem2, Open2, Closed2, Lengths, Memo),
            weave_sum(J + 1, M, Rem, Open, Closed, Lengths, Sum + C, Memo1)
    end.

legal_weave_move(Rem, Open, Closed, Lengths, J) ->
    R = element(J, Rem),
    L = element(J, Lengths),
    case R =:= 0 of
        true -> false;
        false ->
            AlreadyOpened = R < L,
            OpeningOkay = AlreadyOpened orelse J =:= Open + 1,
            WillClose = R =:= 1,
            ClosingOkay = (not WillClose) orelse J =:= Closed + 1,
            OpeningOkay andalso ClosingOkay
    end.

apply_weave_move(Rem, Open, Closed, Lengths, J) ->
    R = element(J, Rem),
    L = element(J, Lengths),
    Open2 = case R =:= L of true -> J; false -> Open end,
    Rem2 = setelement(J, Rem, R - 1),
    Closed2 = case R - 1 of 0 -> J; _ -> Closed end,
    {Rem2, Open2, Closed2}.

unrank_weaving(Lengths, Rank1) ->
    LT = list_to_tuple(Lengths),
    {Count, Memo0} = weave_count(LT, 0, 0, LT, #{}),
    true = Rank1 >= 1 andalso Rank1 =< Count,
    {Out, _Memo} = unrank_weave_loop(LT, 0, 0, LT, Rank1, [], Memo0),
    lists:reverse(Out).

unrank_weave_loop(Rem, Open, Closed, Lengths, Rank, Acc, Memo) when tuple_size(Rem) > 0 ->
    case all_zero(tuple_to_list(Rem)) of
        true -> {Acc, Memo};
        false -> choose_weave_j(1, tuple_size(Rem), Rem, Open, Closed, Lengths, Rank, Acc, Memo)
    end.

choose_weave_j(J, M, Rem, Open, Closed, Lengths, Rank, Acc, Memo) when J =< M ->
    case legal_weave_move(Rem, Open, Closed, Lengths, J) of
        false -> choose_weave_j(J + 1, M, Rem, Open, Closed, Lengths, Rank, Acc, Memo);
        true ->
            {Rem2, Open2, Closed2} = apply_weave_move(Rem, Open, Closed, Lengths, J),
            {Block, Memo1} = weave_count(Rem2, Open2, Closed2, Lengths, Memo),
            case Rank > Block of
                true -> choose_weave_j(J + 1, M, Rem, Open, Closed, Lengths, Rank - Block, Acc, Memo1);
                false -> unrank_weave_loop(Rem2, Open2, Closed2, Lengths, Rank, [J | Acc], Memo1)
            end
    end.

new_gate_state() -> #{gates => #{0 => foundation_day()}, min => 0, max => 0}.

ensure_gate_index(K, State) ->
    Min = maps:get(min, State),
    Max = maps:get(max, State),
    if K > Max -> ensure_positive_gate(Max + 1, K, State);
       K < Min -> ensure_negative_gate(Min - 1, K, State);
       true -> State
    end.

ensure_positive_gate(N, K, State) when N > K -> State;
ensure_positive_gate(N, K, State) ->
    Gates = maps:get(gates, State),
    Prev = maps:get(N - 1, Gates),
    Gap = gate_gap(N),
    State1 = State#{gates := maps:put(N, Prev + Gap, Gates), max := N},
    ensure_positive_gate(N + 1, K, State1).

ensure_negative_gate(N, K, State) when N < K -> State;
ensure_negative_gate(N, K, State) ->
    Gates = maps:get(gates, State),
    Next = maps:get(N + 1, Gates),
    Gap = gate_gap(N),
    State1 = State#{gates := maps:put(N, Next - Gap, Gates), min := N},
    ensure_negative_gate(N - 1, K, State1).

gate_gap(SignedIndex) ->
    Magnitude = abs(SignedIndex),
    QuestionDay = foundation_day() + case SignedIndex > 0 of true -> Magnitude; false -> -Magnitude end,
    R = sauce(foundation_day(), QuestionDay),
    Stream = ask_bowl(R, 1, 1),
    41 + choose_rank(Stream, 922).

ensure_gates_cover(LowDay, HighDay, State) ->
    State1 = ensure_low_gate(LowDay, State),
    ensure_high_gate(HighDay, State1).

ensure_low_gate(LowDay, State) ->
    Gates = maps:get(gates, State), Min = maps:get(min, State),
    case maps:get(Min, Gates) > LowDay of
        true -> ensure_low_gate(LowDay, ensure_gate_index(Min - 1, State));
        false -> State
    end.

ensure_high_gate(HighDay, State) ->
    Gates = maps:get(gates, State), Max = maps:get(max, State),
    case maps:get(Max, Gates) < HighDay of
        true -> ensure_high_gate(HighDay, ensure_gate_index(Max + 1, State));
        false -> State
    end.

gate_index_at_or_before(Day, State0) ->
    State = ensure_gates_cover(Day, Day, State0),
    Gates = maps:get(gates, State),
    {binary_gate_before(Day, maps:get(min, State), maps:get(max, State), Gates), State}.

binary_gate_before(_Day, Lo, Hi, _Gates) when Lo >= Hi -> Lo;
binary_gate_before(Day, Lo, Hi, Gates) ->
    Mid = Lo + ((Hi - Lo + 1) div 2),
    case maps:get(Mid, Gates) =< Day of
        true -> binary_gate_before(Day, Mid, Hi, Gates);
        false -> binary_gate_before(Day, Lo, Mid - 1, Gates)
    end.

gate_index_at_or_after(Day, State0) ->
    {I, State1} = gate_index_at_or_before(Day, State0),
    Gates = maps:get(gates, State1),
    case maps:get(I, Gates) =:= Day of
        true -> {I, State1};
        false -> {I + 1, ensure_gate_index(I + 1, State1)}
    end.

exact_gate_index(Day, State0) ->
    {I, State1} = gate_index_at_or_before(Day, State0),
    Gates = maps:get(gates, State1),
    case maps:get(I, Gates) =:= Day of
        true -> {{ok, I}, State1};
        false -> {none, State1}
    end.

year_length(I, J, State) ->
    Gates = maps:get(gates, State),
    maps:get(J, Gates) - maps:get(I, Gates).

valid_year_pair(I, J, State) ->
    L = year_length(I, J, State),
    J - I >= 6 andalso L >= 252 andalso L =< 5778.

year5000(CDay, State0) ->
    StateA = ensure_gates_cover(CDay - 5778, CDay + 5778, State0),
    StateB = ensure_gate_index(maps:get(min, StateA) - 1, StateA),
    State1 = ensure_gate_index(maps:get(max, StateB) + 1, StateB),
    {Before, State2} = gate_index_at_or_before(CDay, State1),
    {After, State3} = gate_index_at_or_after(CDay, State2),
    Opens = collect_opens(CDay, Before, State3, []),
    Closes = collect_closes(CDay, After, State3, []),
    Gates = maps:get(gates, State3),
    Candidates = lists:sort([
        {year_length(I, J, State3), maps:get(I, Gates), I, J}
        || I <- Opens, J <- Closes, I < J, valid_year_pair(I, J, State3),
           maps:get(I, Gates) < CDay, CDay =< maps:get(J, Gates)
    ]),
    true = Candidates =/= [],
    R = sauce(CDay, CDay),
    Stream = ask_bowl(R, 1, 10),
    Rank = choose_rank(Stream, length(Candidates)),
    {_Len, _OpenDay, I, J} = lists:nth(Rank, Candidates),
    {make_year(5000, I, J, State3), State3}.

collect_opens(CDay, I, State, Acc) ->
    Gates = maps:get(gates, State),
    Day = maps:get(I, Gates),
    if Day >= CDay -> collect_opens(CDay, I - 1, State, Acc);
       CDay - Day =< 5778 -> collect_opens(CDay, I - 1, State, [I | Acc]);
       true -> Acc
    end.

collect_closes(CDay, J, State, Acc) ->
    Gates = maps:get(gates, State),
    Day = maps:get(J, Gates),
    if Day < CDay -> collect_closes(CDay, J + 1, State, Acc);
       Day - CDay =< 5778 -> collect_closes(CDay, J + 1, State, [J | Acc]);
       true -> Acc
    end.

make_year(Number, I, J, State) ->
    Gates = maps:get(gates, State),
    #{number => Number,
      open_gate_index => I,
      close_gate_index => J,
      open_gate_day => maps:get(I, Gates),
      close_gate_day => maps:get(J, Gates)}.

next_year(CDay, Known, State0) ->
    Open = maps:get(close_gate_index, Known),
    OpenDay = maps:get(close_gate_day, Known),
    StateA = ensure_gates_cover(OpenDay, OpenDay + 5778, State0),
    State1 = ensure_gate_index(maps:get(max, StateA) + 1, StateA),
    Candidates0 = collect_next_candidates(Open, Open + 1, State1, 1, []),
    Candidates = lists:sort(Candidates0),
    R = sauce(CDay, OpenDay),
    Stream = ask_bowl(R, 1, 11),
    Rank = choose_rank(Stream, length(Candidates)),
    {_Len, _Seq, Close} = lists:nth(Rank, Candidates),
    {make_year(maps:get(number, Known) + 1, Open, Close, State1), State1}.

collect_next_candidates(Open, J, State, Seq, Acc) ->
    L = year_length(Open, J, State),
    case L > 5778 of
        true -> Acc;
        false ->
            Acc1 = case valid_year_pair(Open, J, State) of true -> [{L, Seq, J} | Acc]; false -> Acc end,
            collect_next_candidates(Open, J + 1, State, Seq + 1, Acc1)
    end.

previous_year(CDay, Known, State0) ->
    Close = maps:get(open_gate_index, Known),
    CloseDay = maps:get(open_gate_day, Known),
    StateA = ensure_gates_cover(CloseDay - 5778, CloseDay, State0),
    State1 = ensure_gate_index(maps:get(min, StateA) - 1, StateA),
    Candidates0 = collect_previous_candidates(Close, Close - 1, State1, 1, []),
    Candidates = lists:sort(Candidates0),
    R = sauce(CDay, CloseDay),
    Stream = ask_bowl(R, 1, 12),
    Rank = choose_rank(Stream, length(Candidates)),
    {_Len, _Seq, Open} = lists:nth(Rank, Candidates),
    {make_year(maps:get(number, Known) - 1, Open, Close, State1), State1}.

collect_previous_candidates(Close, I, State, Seq, Acc) ->
    L = year_length(I, Close, State),
    case L > 5778 of
        true -> Acc;
        false ->
            Acc1 = case valid_year_pair(I, Close, State) of true -> [{L, Seq, I} | Acc]; false -> Acc end,
            collect_previous_candidates(Close, I - 1, State, Seq + 1, Acc1)
    end.

find_target_year(CDay, TDay, State0) ->
    {Y0, State1} = year5000(CDay, State0),
    walk_year(CDay, TDay, Y0, State1).

walk_year(CDay, TDay, Y, State) ->
    CloseDay = maps:get(close_gate_day, Y),
    OpenDay = maps:get(open_gate_day, Y),
    if TDay > CloseDay ->
            {Y1, State1} = next_year(CDay, Y, State),
            walk_year(CDay, TDay, Y1, State1);
       TDay =< OpenDay ->
            {Y1, State1} = previous_year(CDay, Y, State),
            walk_year(CDay, TDay, Y1, State1);
       true -> {Y, State}
    end.

build_year_structure(CDay, Year, State0) ->
    FirstDay = maps:get(open_gate_day, Year) + 1,
    R = sauce(CDay, FirstDay),
    GateGaps = maps:get(close_gate_index, Year) - maps:get(open_gate_index, Year),
    CutletCandidates = [K || K <- lists:seq(6, 17), K =< GateGaps],
    A20 = ask_bowl(R, 2, 20),
    CutletCount = lists:nth(choose_rank(A20, length(CutletCandidates)), CutletCandidates),
    {Required, State1} = required_cutlet_boundary(CDay, Year, State0),
    G = GateGaps,
    PartitionCount = count_cutlet_partitions(G, CutletCount, Required),
    A21 = ask_bowl(R, 2, 21),
    Partition = unrank_cutlet_partition(G, CutletCount, Required, choose_rank(A21, PartitionCount)),
    CutletNameSpace = falling_factorial(17, CutletCount),
    A22 = ask_bowl(R, 5, 22),
    CutletNames = unrank_distinct_indices(17, CutletCount, choose_rank(A22, CutletNameSpace)),
    Cutlets = materialize_cutlets(Year, Partition, CutletNames, State1),

    L = maps:get(close_gate_day, Year) - maps:get(open_gate_day, Year),
    MinMonths = ceil_div(L, 123),
    MaxMonths = min(47, L div 4),
    true = MinMonths >= 3 andalso MinMonths =< MaxMonths andalso MaxMonths =< 47,
    MonthCandidates = lists:seq(MinMonths, MaxMonths),
    A30 = ask_bowl(R, 3, 30),
    MonthCount = lists:nth(choose_rank(A30, length(MonthCandidates)), MonthCandidates),
    MonthLengthCount = count_bounded_compositions(L, MonthCount, 4, 123),
    A31 = ask_bowl(R, 3, 31),
    MonthLengths = unrank_bounded_composition(L, MonthCount, 4, 123, choose_rank(A31, MonthLengthCount)),
    WeavingCount = count_weavings(MonthLengths),
    A32 = ask_bowl(R, 4, 32),
    MonthWeaving = unrank_weaving(MonthLengths, choose_rank(A32, WeavingCount)),
    MonthNameSpace = falling_factorial(47, MonthCount),
    A33 = ask_bowl(R, 5, 33),
    MonthNames = unrank_distinct_indices(47, MonthCount, choose_rank(A33, MonthNameSpace)),
    {#{cutlet_count => CutletCount,
       cutlet_partition => Partition,
       cutlet_name_indices => CutletNames,
       cutlets => Cutlets,
       month_count => MonthCount,
       month_lengths => MonthLengths,
       month_weaving => MonthWeaving,
       month_name_indices => MonthNames}, State1}.

required_cutlet_boundary(CDay, Year, State0) ->
    {Exact, State1} = exact_gate_index(CDay, State0),
    case Exact of
        {ok, G} ->
            Open = maps:get(open_gate_index, Year),
            Close = maps:get(close_gate_index, Year),
            case Open < G andalso G < Close of
                true -> {G - Open, State1};
                false -> {none, State1}
            end;
        none -> {none, State1}
    end.

materialize_cutlets(Year, Partition, NameIndices, State) ->
    materialize_cutlets_loop(maps:get(open_gate_index, Year), Partition, NameIndices, State, []).

materialize_cutlets_loop(_Cursor, [], [], _State, Acc) -> lists:reverse(Acc);
materialize_cutlets_loop(Cursor, [Part | Parts], [Name | Names], State, Acc) ->
    Close = Cursor + Part,
    Gates = maps:get(gates, State),
    C = #{name_index => Name,
          open_gate_index => Cursor,
          close_gate_index => Close,
          first_day => maps:get(Cursor, Gates) + 1,
          last_day => maps:get(Close, Gates)},
    materialize_cutlets_loop(Close, Parts, Names, State, [C | Acc]).

calendar_date_indices(CDay, TDay) when is_integer(CDay), is_integer(TDay) ->
    {Year, GateState} = find_target_year(CDay, TDay, new_gate_state()),
    {Structure, _State2} = build_year_structure(CDay, Year, GateState),
    Cutlet = find_cutlet(maps:get(cutlets, Structure), TDay),
    DayInCutlet = TDay - maps:get(first_day, Cutlet) + 1,
    Offset0 = TDay - (maps:get(open_gate_day, Year) + 1),
    Weave = maps:get(month_weaving, Structure),
    MonthId = lists:nth(Offset0 + 1, Weave),
    MonthNames = maps:get(month_name_indices, Structure),
    MonthNameIndex = lists:nth(MonthId, MonthNames),
    DayInMonth = count_occurrences_prefix(Weave, MonthId, Offset0 + 1),
    {maps:get(number, Year), maps:get(name_index, Cutlet), DayInCutlet, MonthNameIndex, DayInMonth}.

find_cutlet([C | Rest], Day) ->
    case maps:get(first_day, C) =< Day andalso Day =< maps:get(last_day, C) of
        true -> C;
        false -> find_cutlet(Rest, Day)
    end.

count_occurrences_prefix(List, Item, Count) ->
    Prefix = lists:sublist(List, Count),
    length([X || X <- Prefix, X =:= Item]).

calendar_date(CDay, TDay) ->
    {Year, CutletIndex, DayInCutlet, MonthIndex, DayInMonth} = calendar_date_indices(CDay, TDay),
    {Year,
     source_language_catalog:cutlet_name(CutletIndex),
     DayInCutlet,
     source_language_catalog:month_name(MonthIndex),
     DayInMonth}.
