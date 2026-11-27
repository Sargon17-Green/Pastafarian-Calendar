program stage02_discovery01
  use iso_fortran_env, only: int64
  use big_integer
  use normative_oracle_core, only: save_value
  use discovery01_remainder
  implicit none
  type(Discovery01Dispatcher) :: dispatcher
  type(Discovery01Context) :: a, b
  type(BigInt) :: m, q, x, expected_raw, expected_save, oracle, saved_a
  character(len=42), parameter :: quotients(7) = [character(len=42) :: &
    '-2', '-1', '0', '1', '2', '-10000000000000000000000000000000000000000', &
    '10000000000000000000000000000000000000000']
  integer :: i, d, cases, reds, matches
  m = bi_from_string('170141183460469231731687303715884105727')
  cases = 0; reds = 0; matches = 0
  do i=1,size(quotients)
    q = bi_from_string(trim(quotients(i)))
    do d=-1,1
      x = bi_add_small(bi_mul(q,m),int(d,int64))
      select case(d)
      case(-1)
        expected_raw = bi_add_small(m,-1_int64)
        expected_save = expected_raw
      case(0)
        expected_raw = bi_zero()
        expected_save = m
      case(1)
        expected_raw = bi_one()
        expected_save = expected_raw
      end select
      call dispatcher%dispatch(a,x)
      oracle = save_value(x)
      if (.not. bi_equal(oracle,expected_save)) error stop 'Independent SAVE expectation disagrees with oracle'
      if (.not. bi_equal(a%rawRemainder,expected_raw)) error stop 'Historical raw value incorrect'
      if (.not. bi_equal(a%input,x)) error stop 'Input context incorrect'
      if (a%rawCalls /= 1 .or. a%base%phase /= 2 .or. a%base%subPhase /= 1) error stop 'Route not executed exactly once'
      if (a%base%traceCount /= 2 .or. a%base%branchTrace(1) /= 'BOOTSTRAP_BASE_DISPATCH' .or. &
        a%base%branchTrace(2) /= 'DISCOVERY01_OLD_REMAINDER') error stop 'Route trace incorrect'
      cases = cases + 1
      if (d == 0) then
        if (bi_equal(a%rawRemainder,oracle)) error stop 'Historical zero divergence missing'
        reds = reds + 1
        write(*,'(A,I0,A,A,A,A,A,A)') 'CASE=',cases,' EXPECTED_RED X=',bi_to_string(x), &
          ' RAW=',bi_to_string(a%rawRemainder),' SAVE=',bi_to_string(oracle)
      else
        if (.not. bi_equal(a%rawRemainder,oracle)) error stop 'Unexpected divergence'
        matches = matches + 1
        write(*,'(A,I0,A,A,A,A,A,A)') 'CASE=',cases,' MATCH X=',bi_to_string(x), &
          ' RAW=',bi_to_string(a%rawRemainder),' SAVE=',bi_to_string(oracle)
      end if
    end do
  end do
  call dispatcher%dispatch(a,m)
  saved_a = a%rawRemainder
  call dispatcher%dispatch(b,bi_one())
  if (.not. bi_equal(a%rawRemainder,saved_a) .or. .not. bi_equal(a%input,m) .or. &
      a%rawCalls /= 1 .or. b%rawCalls /= 1 .or. .not. bi_equal(b%rawRemainder,bi_one())) error stop 'Context isolation'
  call dispatcher%dispatch(b,bi_neg(m))
  if (.not. bi_equal(b%input,bi_neg(m)) .or. .not. bi_is_zero(b%rawRemainder) .or. b%rawCalls /= 1 .or. &
      .not. bi_equal(a%input,m) .or. .not. bi_equal(a%rawRemainder,saved_a)) error stop 'Context reuse isolation'
  if (dispatcher%base%metrics%dispatchCalls /= 24_int64 .or. &
      dispatcher%base%metrics%validationCalls /= 24_int64) error stop 'Observational metrics'
  if (cases /= 21 .or. reds /= 7 .or. matches /= 14) error stop 'Case census mismatch'
  write(*,'(A)') 'STAGE02_DISCOVERY01 CASES=21 EXPECTED_RED=7 MATCH=14 ISOLATION=2 METRICS=1'
  write(*,'(A)') 'STAGE02_DISCOVERY01_GATE_PASS'
end program
