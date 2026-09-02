package pastafari

object BootstrapFixtures {
  val ExpectedFoundationDistance: BigInt = BigInt(14777149)
  val ExpectedStoneRow1: Vector[BigInt] = Vector[BigInt](17, 29, 43, 71, 101)
  val ExpectedStoneRow2: Vector[BigInt] = Vector[BigInt](378, 1073, 2375, 6195, 10493)
  val ExpectedPermutationRank1: Vector[Int] = Vector(1, 2, 3, 4, 5, 6)
  val ExpectedPermutationRank720: Vector[Int] = Vector(6, 5, 4, 3, 2, 1)
  val ExpectedBoundedCompositions: Vector[Vector[Int]] = Vector(
    Vector(2, 5), Vector(3, 4), Vector(4, 3), Vector(5, 2)
  )
  val ExpectedBoundaryPartitions: Vector[Vector[Int]] = Vector(
    Vector(1, 2, 3), Vector(2, 1, 3), Vector(3, 1, 2), Vector(3, 2, 1)
  )
  val ExpectedDistinctPairsOfThree: Vector[Vector[Int]] = Vector(
    Vector(1, 2), Vector(1, 3), Vector(2, 1),
    Vector(2, 3), Vector(3, 1), Vector(3, 2)
  )
  val ExpectedWeavingsTwoByTwo: Vector[Vector[Int]] = Vector(
    Vector(1, 1, 2, 2), Vector(1, 2, 1, 2)
  )
}
