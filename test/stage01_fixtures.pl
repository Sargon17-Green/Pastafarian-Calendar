:- module(stage01_fixtures,
    [ expected_m/1,
      expected_save_case/2,
      expected_day_count_case/2,
      expected_work_counts_case/3,
      expected_stone_row2/1,
      expected_permutation_case/2,
      expected_falling_factorial_17_6/1,
      expected_bounded_case/6,
      expected_weaving_case/3
    ]).

expected_m(170141183460469231731687303715884105727).

expected_save_case(1, 1).
expected_save_case(170141183460469231731687303715884105726,
                   170141183460469231731687303715884105726).
expected_save_case(170141183460469231731687303715884105727,
                   170141183460469231731687303715884105727).
expected_save_case(170141183460469231731687303715884105728, 1).
expected_save_case(340282366920938463463374607431768211454,
                   170141183460469231731687303715884105727).

expected_day_count_case(-15055671, 1).
expected_day_count_case(-15055670, 3).
expected_day_count_case(-15055672, 2).

expected_work_counts_case(-15055671, -15055671, counts(1,1,1,2,2)).
expected_work_counts_case(-15055671, -15055670, counts(1,3,2,4,3)).
expected_work_counts_case(-15055670, -15055671, counts(3,1,2,4,1)).

expected_stone_row2([378,1073,2375,6195,10493]).

expected_permutation_case(1, [1,2,3,4,5,6]).
expected_permutation_case(720, [6,5,4,3,2,1]).

expected_falling_factorial_17_6(8910720).

expected_bounded_case(5,2,1,4,3,[3,2]).
expected_bounded_case(5,2,1,4,1,[1,4]).
expected_bounded_case(5,2,1,4,4,[4,1]).

expected_weaving_case([2,1], 1, [1,1,2]).
expected_weaving_case([2,2], 1, [1,1,2,2]).
expected_weaving_case([2,2], 2, [1,2,1,2]).
