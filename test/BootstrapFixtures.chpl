module BootstrapFixtures {
  use BigInteger;

  const EXPECTED_M_DECIMAL = "170141183460469231731687303715884105727";
  const EXPECTED_FOUNDATION_TO_TABLETS = new bigint(14777149);
  const EXPECTED_STONE_2: [1..5] bigint = [
    new bigint(378),
    new bigint(1073),
    new bigint(2375),
    new bigint(6195),
    new bigint(10493)
  ];
  const EXPECTED_PERMUTATION_1: [1..6] int = [1,2,3,4,5,6];
  const EXPECTED_PERMUTATION_720: [1..6] int = [6,5,4,3,2,1];
}
