! Corrective test, authored after the original ordinal error. Never historical evidence.
program correction_patch01
  use iso_fortran_env, only: int64
  use big_integer
  use discovery01_remainder
  use normative_oracle_core, only: save_value
  implicit none
  type(Discovery01Dispatcher) :: dispatcher
  type(Discovery01Context) :: ctx
  type(BigInt) :: input, raw_expected, norm_expected, oracle
  character(len=42), parameter :: x(6) = [character(len=42) :: &
    '-510423550381407695195061911147652317182', &
    '-510423550381407695195061911147652317181', &
    '-510423550381407695195061911147652317180', &
    '510423550381407695195061911147652317180', &
    '510423550381407695195061911147652317181', &
    '510423550381407695195061911147652317182' ]
  character(len=42), parameter :: raw(6) = [character(len=42) :: &
    '170141183460469231731687303715884105726', &
    '0', &
    '1', &
    '170141183460469231731687303715884105726', &
    '0', &
    '1' ]
  character(len=42), parameter :: save(6) = [character(len=42) :: &
    '170141183460469231731687303715884105726', &
    '170141183460469231731687303715884105727', &
    '1', &
    '170141183460469231731687303715884105726', &
    '170141183460469231731687303715884105727', &
    '1' ]
  integer :: i, divergences
  divergences = 0
  do i=1,size(x)
    input = bi_from_string(trim(x(i)))
    raw_expected = bi_from_string(trim(raw(i)))
    norm_expected = bi_from_string(trim(save(i)))
    oracle = save_value(input)
    if (.not. bi_equal(oracle,norm_expected)) error stop 'Independent literal expectation vs oracle'
    call dispatcher%dispatch(ctx,input)
    if (.not. bi_equal(ctx%input,input)) error stop 'Input ownership'
    if (.not. bi_equal(ctx%rawRemainder,raw_expected)) error stop 'Historical raw remainder'
    if (ctx%rawCalls /= 1) error stop 'Raw invocation count'
    if (ctx%base%phase /= 2 .or. ctx%base%subPhase /= 1) error stop 'Route phase'
    if (ctx%base%traceCount /= 3) error stop 'Trace count'
    if (ctx%base%branchTrace(1) /= 'BOOTSTRAP_BASE_DISPATCH' .or. &
        ctx%base%branchTrace(2) /= 'DISCOVERY01_OLD_REMAINDER') error stop 'Historical trace'
    if (.not. bi_equal(ctx%remainder,norm_expected)) error stop 'Patch output'
    if (ctx%patchCalls /= 1) error stop 'Patch call count'
    if (ctx%base%branchTrace(3) /= 'PATCH01_ZERO_TO_M') error stop 'Patch trace'
    if (.not. bi_equal(ctx%rawRemainder,norm_expected)) divergences = divergences + 1
    write(*,'(A,I0,A,A,A,A,A,A)') 'CORRECTION_CASE=',i,' X=',bi_to_string(input), &
       ' RAW=',bi_to_string(ctx%rawRemainder),' NORM=',bi_to_string(norm_expected)
    write(*,'(A,A)') 'CORRECTION_PATCH_RESULT=',bi_to_string(ctx%remainder)
  end do
  if (divergences /= 2) error stop 'Divergence census'
  if (dispatcher%base%metrics%dispatchCalls /= 6_int64 .or. &
      dispatcher%base%metrics%validationCalls /= 6_int64) error stop 'Metrics'
  write(*,'(A)') 'CORRECTIVE_PATCH01_CASES=6 RAW_DIVERGENCES=2 RAW_MATCHES=4'
  write(*,'(A)') 'CORRECTIVE_PATCH01_GATE_PASS'
end program
