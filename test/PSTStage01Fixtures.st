Object subclass: #PSTStage01Fixtures
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'Pastafarian-Stage01-Tests'!

!PSTStage01Fixtures class methodsFor: 'fixtures'!
foundationDay
    ^ -15055671
!

m
    ^ 170141183460469231731687303715884105727
!

saveInputsAndExpected
    ^ #(
        (1 1)
        (170141183460469231731687303715884105726 170141183460469231731687303715884105726)
        (170141183460469231731687303715884105727 170141183460469231731687303715884105727)
        (170141183460469231731687303715884105728 1)
        (340282366920938463463374607431768211454 170141183460469231731687303715884105727)
        (0 170141183460469231731687303715884105727)
    )
!

dayCountFixtures
    ^ #(
        (-15055671 1)
        (-15055670 3)
        (-15055672 2)
        (-15055669 5)
        (-15055673 4)
    )
!

stoneRowTwo
    ^ #(378 1073 2375 6195 10493)
!

permutationFirst
    ^ #(1 2 3 4 5 6)
!

permutationLast
    ^ #(6 5 4 3 2 1)
!

boundedCompositionsTenTwo
    ^ #((4 6) (5 5) (6 4))
!

cutletPartitionsSixThreeBoundaryTwo
    ^ #((1 1 4) (2 1 3) (2 2 2) (2 3 1))
!

weavingsTwoTwo
    ^ #((1 1 2 2) (1 2 1 2))
!

distinctThreeTakeTwo
    ^ #((1 2) (1 3) (2 1) (2 3) (3 1) (3 2))
!
! !
