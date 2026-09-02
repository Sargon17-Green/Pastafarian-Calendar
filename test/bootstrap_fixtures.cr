require "big"

module Stage01Fixtures
  M = BigInt.new("170141183460469231731687303715884105727")
  TABLETS_DAY = BigInt.new(-278522)
  FOUNDATION_DAY = BigInt.new(-15055671)
  TABLETS_FROM_FOUNDATION = BigInt.new(14777149)

  STONE_ROW_2 = {
    BigInt.new(378),
    BigInt.new(1073),
    BigInt.new(2375),
    BigInt.new(6195),
    BigInt.new(10493),
  }

  FIRST_BOWL_ORDER = {1, 2, 3, 4, 5, 6}
  LAST_BOWL_ORDER = {6, 5, 4, 3, 2, 1}

  BOUNDED_8_2_3_5 = {
    {3, 5},
    {4, 4},
    {5, 3},
  }

  WEAVINGS_2_2 = {
    {1, 1, 2, 2},
    {1, 2, 1, 2},
  }
end
