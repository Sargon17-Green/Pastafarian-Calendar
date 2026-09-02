-module(fixtures_stage01).
-export([primitive/0, bounded/0, weaving/0]).

primitive() ->
    #{m => 170141183460469231731687303715884105727,
      foundation => -15055671,
      tablets => -278522,
      foundation_day_count => 1,
      day_before_foundation_count => 2,
      day_after_foundation_count => 3,
      stone_2 => {378, 1073, 2375, 6195, 10493},
      permutation_1 => [1, 2, 3, 4, 5, 6],
      permutation_720 => [6, 5, 4, 3, 2, 1],
      falling_17_6 => 8910720}.

bounded() ->
    #{count_8_2_4_123 => 1,
      row_8_2_4_123_1 => [4, 4],
      count_9_2_4_123 => 2,
      row_9_2_4_123_1 => [4, 5],
      row_9_2_4_123_2 => [5, 4],
      cutlet_8_2_none_count => 7,
      cutlet_8_2_none_first => [1, 7],
      cutlet_8_2_none_last => [7, 1],
      cutlet_6_3_required_3_count => 4,
      cutlet_6_3_required_3_first => [1, 2, 3],
      cutlet_6_3_required_3_last => [3, 2, 1]}.

weaving() ->
    #{count_2_2 => 2,
      row_2_2_1 => [1, 1, 2, 2],
      row_2_2_2 => [1, 2, 1, 2],
      count_1_1 => 1,
      row_1_1_1 => [1, 2]}.
