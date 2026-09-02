Object subclass: #PSTMonsterContext
    instanceVariableNames: 'calculationDay targetDay phase status semanticState pendingState metrics logs lastError'
    classVariableNames: ''
    package: 'Pastafarian-Stage01'!

!PSTMonsterContext methodsFor: 'accessing'!
calculationDay
    ^ calculationDay
!

calculationDay: anInteger
    calculationDay := anInteger
!

targetDay
    ^ targetDay
!

targetDay: anInteger
    targetDay := anInteger
!

phase
    ^ phase
!

phase: aSymbol
    phase := aSymbol
!

status
    ^ status
!

status: aSymbol
    status := aSymbol
!

semanticState
    ^ semanticState
!

semanticState: anObject
    semanticState := anObject
!

pendingState
    ^ pendingState
!

pendingState: anObject
    pendingState := anObject
!

metrics
    ^ metrics
!

metrics: anObject
    metrics := anObject
!

logs
    ^ logs
!

logs: anObject
    logs := anObject
!

lastError
    ^ lastError
!

lastError: anObject
    lastError := anObject
!
! !

Object subclass: #PSTMonsterMetrics
    instanceVariableNames: 'counters'
    classVariableNames: ''
    package: 'Pastafarian-Stage01'!

!PSTMonsterMetrics methodsFor: 'initialization'!
initialize
    super initialize.
    counters := Dictionary new.
    ^ self
!
! !

!PSTMonsterMetrics methodsFor: 'recording'!
bump: aSymbol
    counters at: aSymbol put: ((counters at: aSymbol ifAbsent: [ 0 ]) + 1)
!

valueAt: aSymbol
    ^ counters at: aSymbol ifAbsent: [ 0 ]
!

snapshot
    ^ counters copy
!
! !

Object subclass: #PSTMonsterValidator
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'Pastafarian-Stage01'!

!PSTMonsterValidator methodsFor: 'validation'!
requireIntegerDay: anObject
    anObject isInteger ifFalse: [ self error: 'دن کا عدد صحیح ہونا لازم ہے' ].
    ^ true
!

requireContextOwnedState: aContext
    (aContext pendingState notNil and: [ aContext pendingState == aContext semanticState ])
        ifTrue: [ self error: 'زیر التوا حالت اور منظور شدہ حالت ایک ہی قابل تغیر شے نہیں ہو سکتیں' ].
    ^ true
!
! !

Object subclass: #PSTMonsterErrorWrapper
    instanceVariableNames: ''
    classVariableNames: ''
    package: 'Pastafarian-Stage01'!

!PSTMonsterErrorWrapper methodsFor: 'errors'!
run: aBlock context: aContext
    ^ [ aBlock value ] on: Error do: [ :error |
        aContext lastError: error.
        aContext status: #FAILED.
        error pass ]
!
! !

Object subclass: #PSTMonsterDispatcher
    instanceVariableNames: 'handlers'
    classVariableNames: ''
    package: 'Pastafarian-Stage01'!

!PSTMonsterDispatcher methodsFor: 'initialization'!
initialize
    super initialize.
    handlers := Dictionary new.
    ^ self
!
! !

!PSTMonsterDispatcher methodsFor: 'dispatching'!
register: aSymbol handler: aBlock
    handlers at: aSymbol put: aBlock
!

dispatch: aSymbol context: aContext
    | handler |
    handler := handlers at: aSymbol ifAbsent: [ self error: 'مطلوبہ مرحلے کے لیے کوئی ہینڈلر درج نہیں ہے' ].
    ^ handler value: aContext
!
! !

Object subclass: #PSTMonsterManager
    instanceVariableNames: 'dispatcher validator errorWrapper metrics'
    classVariableNames: ''
    package: 'Pastafarian-Stage01'!

!PSTMonsterManager methodsFor: 'initialization'!
initialize
    super initialize.
    dispatcher := PSTMonsterDispatcher new.
    validator := PSTMonsterValidator new.
    errorWrapper := PSTMonsterErrorWrapper new.
    metrics := PSTMonsterMetrics new.
    dispatcher register: #BOOTSTRAP handler: [ :ctx |
        validator requireIntegerDay: ctx calculationDay.
        validator requireIntegerDay: ctx targetDay.
        validator requireContextOwnedState: ctx.
        ctx phase: #READY.
        ctx status: #READY.
        metrics bump: #bootstrapCompleted.
        ctx ].
    ^ self
!
! !

!PSTMonsterManager methodsFor: 'execution'!
bootstrapCalculationDay: calculationDay targetDay: targetDay
    | ctx |
    ctx := PSTMonsterContext new.
    ctx calculationDay: calculationDay.
    ctx targetDay: targetDay.
    ctx phase: #BOOTSTRAP.
    ctx status: #NEW.
    ctx semanticState: Dictionary new.
    ctx pendingState: nil.
    ctx metrics: metrics.
    ctx logs: OrderedCollection new.
    ^ errorWrapper run: [ dispatcher dispatch: #BOOTSTRAP context: ctx ] context: ctx
!

metricsSnapshot
    ^ metrics snapshot
!
! !
