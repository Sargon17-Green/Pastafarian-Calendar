module BootstrapFixtures
  ( saveFixtures
  , dayCountFixtures
  , boundedCompositionFixtures
  , cutletPartitionFixtures
  , weavingFixtures
  ) where

import Pastafari.NormativeOracle (foundationDay, m)

saveFixtures :: [(Integer, Integer)]
saveFixtures =
  [ (1, 1)
  , (m - 1, m - 1)
  , (m, m)
  , (m + 1, 1)
  , (2 * m, m)
  ]

dayCountFixtures :: [(Integer, Integer)]
dayCountFixtures =
  [ (foundationDay - 2, 4)
  , (foundationDay - 1, 2)
  , (foundationDay, 1)
  , (foundationDay + 1, 3)
  , (foundationDay + 2, 5)
  ]

boundedCompositionFixtures :: [(Integer, [Int])]
boundedCompositionFixtures =
  [ (1, [1,4])
  , (2, [2,3])
  , (3, [3,2])
  , (4, [4,1])
  ]

cutletPartitionFixtures :: [(Integer, [Int])]
cutletPartitionFixtures =
  [ (1, [1,2,3])
  , (2, [2,1,3])
  , (3, [3,1,2])
  , (4, [3,2,1])
  ]

weavingFixtures :: [(Integer, [Int])]
weavingFixtures =
  [ (1, [1,1,2,2])
  , (2, [1,2,1,2])
  ]
