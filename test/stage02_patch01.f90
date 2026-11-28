program stage02_patch01
  use iso_fortran_env, only: int64
  use big_integer
  use normative_oracle_core, only: save_value
  use discovery01_remainder
  implicit none
  type(Discovery01Dispatcher) :: dispatcher
  type(Discovery01Context) :: a, b
  type(BigInt) :: m, q, x, raw, expected, oracle
  character(len=42), parameter :: quotients(7) = [character(len=42) :: &
    '-2', '-1', '0', '1', '2', '-10000000000000000000000000000000000000000', &
    '10000000000000000000000000000000000000000']
  integer :: i, d, cases, corrected, preserved
  m = bi_from_string('170141183460469231731687303715884105727')
  cases = 0; corrected = 0; preserved = 0
  do i=1,size(quotients)
    q = bi_from_string(trim(quotients(i)))
    do d=-2,2
      x = bi_add_small(bi_mul(q,m),int(d,int64))
      if (d < 0) then
        raw = bi_add_small(m,int(d,int64))
      else
        raw = bi_from_string('0')
        raw = bi_add_small(raw,int(d,int64))
      end if
      expected = raw
      if (d == 0) expected = m
      oracle = save_value(x)
      if (.not. bi_equal(oracle,expected)) error stop 'Oracle differs from analytic expectation'
      call dispatcher%dispatch(a,x)
      call check_route(a,x,raw,expected)
      cases = cases + 1
      if (d == 0) then
        corrected = corrected + 1
        write(*,'(A,I0,A,A,A,A,A,A)') 'CASE=',cases,' CORRECTED X=',bi_to_string(x), &
          ' RAW=',bi_to_string(a%rawRemainder),' RESULT=',bi_to_string(a%remainder)
      else
        preserved = preserved + 1
        write(*,'(A,I0,A,A,A,A,A,A)') 'CASE=',cases,' PRESERVED X=',bi_to_string(x), &
          ' RAW=',bi_to_string(a%rawRemainder),' RESULT=',bi_to_string(a%remainder)
      end if
    end do
  end do
  call dispatcher%dispatch(a,m)
  call dispatcher%dispatch(b,bi_one())
  call check_route(a,m,bi_zero(),m)
  call check_route(b,bi_one(),bi_one(),bi_one())
  call dispatcher%dispatch(b,bi_neg(m))
  call check_route(a,m,bi_zero(),m)
  call check_route(b,bi_neg(m),bi_zero(),m)
  if (dispatcher%base%metrics%dispatchCalls /= 38_int64 .or. &
      dispatcher%base%metrics%validationCalls /= 38_int64) error stop 'Observational metrics'
  if (cases /= 35 .or. corrected /= 7 .or. preserved /= 28) error stop 'Case census'
  write(*,'(A)') 'STAGE02_PATCH01 CASES=35 CORRECTED=7 PRESERVED=28 ISOLATION=2 METRICS=1'
  write(*,'(A)') 'STAGE02_PATCH01_GATE_PASS'
contains
  subroutine check_route(ctx,input,raw_expected,result_expected)
    type(Discovery01Context), intent(in) :: ctx
    type(BigInt), intent(in) :: input, raw_expected, result_expected
    if (.not. bi_equal(ctx%input,input)) error stop 'Input context'
    if (.not. bi_equal(ctx%rawRemainder,raw_expected)) error stop 'Historical raw value'
    if (.not. bi_equal(ctx%remainder,result_expected)) error stop 'Corrected result'
    if (ctx%rawCalls /= 1 .or. ctx%patchCalls /= 1) error stop 'Call counts'
    if (ctx%base%phase /= 2 .or. ctx%base%subPhase /= 1 .or. ctx%base%traceCount /= 3) error stop 'Route'
    if (ctx%base%branchTrace(1) /= 'BOOTSTRAP_BASE_DISPATCH' .or. &
        ctx%base%branchTrace(2) /= 'DISCOVERY01_OLD_REMAINDER' .or. &
        ctx%base%branchTrace(3) /= 'PATCH01_ZERO_TO_M') error stop 'Trace'
  end subroutine
end program
