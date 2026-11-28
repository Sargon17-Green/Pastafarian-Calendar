program stage04_discovery02
  use iso_fortran_env, only: int64
  use big_integer
  use normative_oracle_core, only: day_count
  use discovery02_day_tag
  implicit none
  type(Discovery02Dispatcher) :: dispatcher
  type(Discovery02Context) :: a,b
  type(BigInt) :: x,rank,expectedRaw,oracle,half,parity,decoded,f
  type(BigInt) :: observed(17)
  integer :: i,divergences,matches,collisions
  character(len=48), parameter :: days(17) = [character(len=48) :: &
    '-15055671', &
    '-15055672', &
    '-15055670', &
    '-15055673', &
    '-15055669', &
    '-15055674', &
    '-15055668', &
    '-29832820', &
    '-278522', &
    '-2162539319', &
    '2132427977', &
    '-9223372036869831479', &
    '9223372036839720137', &
    '-170141183460469231731687303715899161399', &
    '170141183460469231731687303715869050057', &
    '-10000000000000000000000000000000015055671', &
    '9999999999999999999999999999999984944329']
  character(len=48), parameter :: ranks(17) = [character(len=48) :: &
    '1', &
    '2', &
    '3', &
    '4', &
    '5', &
    '6', &
    '7', &
    '29554298', &
    '29554299', &
    '4294967296', &
    '4294967297', &
    '18446744073709551616', &
    '18446744073709551617', &
    '340282366920938463463374607431768211456', &
    '340282366920938463463374607431768211457', &
    '20000000000000000000000000000000000000000', &
    '20000000000000000000000000000000000000001']
  character(len=48), parameter :: raws(17) = [character(len=48) :: &
    '0', &
    '2', &
    '2', &
    '4', &
    '4', &
    '6', &
    '6', &
    '29554298', &
    '29554298', &
    '4294967296', &
    '4294967296', &
    '18446744073709551616', &
    '18446744073709551616', &
    '340282366920938463463374607431768211456', &
    '340282366920938463463374607431768211456', &
    '20000000000000000000000000000000000000000', &
    '20000000000000000000000000000000000000000']

  f = bi_from_string('-15055671')
  divergences=0; matches=0; collisions=0
  do i=1,17
    x=bi_from_string(trim(days(i)))
    rank=bi_from_string(trim(ranks(i)))
    expectedRaw=bi_from_string(trim(raws(i)))
    ! Inverse rank: odd r -> F+(r-1)/2; even r -> F-r/2.
    half=bi_floor_div(rank,bi_from_string('2'))
    parity=bi_mod(rank,bi_from_string('2'))
    if (bi_is_zero(parity)) then
      decoded=bi_sub(f,half)
    else
      decoded=bi_add(f,half)
    end if
    if (.not. bi_equal(decoded,x)) error stop 'Inverse rank mismatch'
    oracle=day_count(x)
    if (.not. bi_equal(oracle,rank)) error stop 'Independent literal versus clean oracle mismatch'
    call dispatcher%dispatch(a,x)
    call check_route(a,x,expectedRaw)
    observed(i)=a%rawDayTag
    if (i == 1 .or. mod(i,2) == 1) then
      if (bi_equal(a%rawDayTag,rank)) error stop 'Expected divergence absent'
      if (.not. bi_equal(bi_sub(rank,a%rawDayTag),bi_one())) error stop 'Wrong divergence magnitude'
      divergences=divergences+1
      write(*,'(A,I0,A,A,A,A,A,A)') 'CASE=',i,' EXPECTED_RED DAY=',bi_to_string(x), &
        ' RAW=',bi_to_string(a%rawDayTag),' RANK=',bi_to_string(rank)
    else
      if (.not. bi_equal(a%rawDayTag,rank)) error stop 'Unexpected divergence'
      matches=matches+1
      write(*,'(A,I0,A,A,A,A,A,A)') 'CASE=',i,' MATCH DAY=',bi_to_string(x), &
        ' RAW=',bi_to_string(a%rawDayTag),' RANK=',bi_to_string(rank)
    end if
  end do
  if (.not. bi_is_zero(observed(1))) error stop 'Foundation not zero'
  do i=2,16,2
    if (.not. bi_equal(observed(i),observed(i+1))) error stop 'Expected mirrored collision absent'
    collisions=collisions+1
  end do
  call dispatcher%dispatch(a,f)
  call dispatcher%dispatch(b,bi_from_string(trim(days(17))))
  call check_route(a,f,bi_zero())
  call check_route(b,bi_from_string(trim(days(17))),bi_from_string(trim(raws(17))))
  call dispatcher%dispatch(b,bi_from_string(trim(days(2))))
  call check_route(a,f,bi_zero())
  call check_route(b,bi_from_string(trim(days(2))),bi_from_string(trim(raws(2))))
  if (dispatcher%base%metrics%dispatchCalls /= 20_int64 .or. &
      dispatcher%base%metrics%validationCalls /= 20_int64 .or. &
      dispatcher%base%metrics%wrappedErrors /= 0_int64) error stop 'Dispatcher metrics'
  if (divergences /= 9 .or. matches /= 8 .or. collisions /= 8) error stop 'Case census'
  write(*,'(A)') 'STAGE04_DISCOVERY02 CASES=17 EXPECTED_RED=9 MATCH=8 COLLISIONS=8 ISOLATION=2 METRICS=1'
  write(*,'(A)') 'STAGE04_DISCOVERY02_OBSERVATION_GATE_PASS_NOT_PATCH'
contains
  subroutine check_route(ctx,input,raw)
    type(Discovery02Context), intent(in) :: ctx
    type(BigInt), intent(in) :: input,raw
    if (.not. bi_equal(ctx%input,input)) error stop 'Context input'
    if (.not. bi_equal(ctx%rawDayTag,raw)) error stop 'Raw value'
    if (ctx%rawCalls /= 1) error stop 'Raw calls'
    if (ctx%base%phase /= 4 .or. ctx%base%subPhase /= 2 .or. ctx%base%traceCount /= 2) error stop 'Route'
    if (ctx%base%branchTrace(1) /= 'BOOTSTRAP_BASE_DISPATCH' .or. &
        ctx%base%branchTrace(2) /= 'DISCOVERY02_OLD_DAY_TAG') error stop 'Trace'
  end subroutine
end program
