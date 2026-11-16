! Read-only cache-boundary regression for the original Stage 1 gate cache.
! Distinguishes a real reset from a no-op, without changing date arithmetic.
! Structural cache QA only, NOT an independent full-calendar oracle.
program stage01_gate_cache_structure_probe
  use iso_fortran_env, only: int64
  use big_integer, only: BigInt, bi_equal, bi_compare, bi_add_small
  use normative_oracle_core, only: foundation_day
  use normative_oracle_calendar, only: reset_gate_cache, ensure_gate_index, &
       gate_day, gate_cache_bounds, exact_gate_index
  implicit none

  type(BigInt) :: anchor, forward_day, backward_day
  integer :: assertions, failures, i
  integer(int64) :: k, idx
  integer(int64), parameter :: sample_indices(4) = [-2_int64, -1_int64, 1_int64, 3_int64]
  type(BigInt) :: boundary
  logical :: found
  character(len=64) :: assertion_label

  assertions = 0
  failures = 0
  anchor = foundation_day()

  call reset_gate_cache()
  call assert_bounds(0_int64, 0_int64, 'cold reset')                         ! 1
  call check(bi_equal(gate_day(0_int64), anchor), 'cold anchor')              ! 2
  call ensure_gate_index(3_int64)
  call assert_bounds(0_int64, 3_int64, 'forward extension')                  ! 3
  forward_day = gate_day(3_int64)
  call check(bi_compare(forward_day, anchor) > 0, 'forward direction')       ! 4
  call ensure_gate_index(-2_int64)
  call assert_bounds(-2_int64, 3_int64, 'backward extension')                ! 5
  backward_day = gate_day(-2_int64)
  call check(bi_compare(backward_day, anchor) < 0, 'backward direction')     ! 6
  call check(bi_equal(gate_day(3_int64), forward_day), 'keep forward')       ! 7
  call check(bi_equal(gate_day(-2_int64), backward_day), 'keep backward')    ! 8

  call reset_gate_cache()
  call assert_bounds(0_int64, 0_int64, 'reset after bidirectional cache')   ! 9
  call check(bi_equal(gate_day(0_int64), anchor), 'reset anchor')            ! 10
  call ensure_gate_index(-2_int64)
  call assert_bounds(-2_int64, 0_int64, 'reverse first extension')          ! 11
  call check(bi_equal(gate_day(-2_int64), backward_day), 'reverse negative') ! 12
  call ensure_gate_index(3_int64)
  call assert_bounds(-2_int64, 3_int64, 'reverse second extension')         ! 13
  call check(bi_equal(gate_day(3_int64), forward_day), 'reverse positive')   ! 14
  call ensure_gate_index(3_int64)
  call assert_bounds(-2_int64, 3_int64, 'idempotent extension')             ! 15

  call reset_gate_cache()
  call assert_bounds(0_int64, 0_int64, 'first repeated reset')              ! 16
  call reset_gate_cache()
  call assert_bounds(0_int64, 0_int64, 'second repeated reset')             ! 17
  call ensure_gate_index(3_int64)
  call assert_bounds(0_int64, 3_int64, 'rebuild forward')                    ! 18
  call check(bi_equal(gate_day(3_int64), forward_day), 'rebuild positive')   ! 19
  call ensure_gate_index(-2_int64)
  call assert_bounds(-2_int64, 3_int64, 'rebuild backward')                  ! 20
  call check(bi_equal(gate_day(-2_int64), backward_day), 'rebuild negative') ! 21

  ! Metamorphic boundary lookup: exact gate, preceding day, succeeding day.
  ! The expected index is derived from strict gate spacing (each gap >= 42),
  ! not from the search implementation or an external calendar oracle.
  do i = 1, size(sample_indices)
    k = sample_indices(i)
    boundary = gate_day(k)
    idx = exact_gate_index(boundary, found)
    write(assertion_label,'(A,I0)') 'exact lookup gate ', k
    call check(found .and. idx == k, trim(assertion_label))
    idx = exact_gate_index(bi_add_small(boundary, -1_int64), found)
    write(assertion_label,'(A,I0)') 'lookup before gate ', k
    call check(.not. found .and. idx == k-1_int64, trim(assertion_label))
    idx = exact_gate_index(bi_add_small(boundary, 1_int64), found)
    write(assertion_label,'(A,I0)') 'lookup after gate ', k
    call check(.not. found .and. idx == k, trim(assertion_label))
  end do
  call assert_bounds(-3_int64, 4_int64, 'boundary queries extend cache minimally') ! 34

  write(*,'(A,I0)') 'STAGE01_GATE_CACHE_STRUCTURE_ASSERTIONS=', assertions
  write(*,'(A,I0)') 'STAGE01_GATE_CACHE_STRUCTURE_FAILURES=', failures
  if (assertions /= 34 .or. failures /= 0) error stop 'gate cache structural reset contract failed'
  write(*,'(A)') 'STAGE01_GATE_CACHE_STRUCTURE_PASS (reset state only; NOT full Stage1)'

contains
  subroutine check(ok, label)
    logical, intent(in) :: ok
    character(len=*), intent(in) :: label
    assertions = assertions + 1
    if (ok) then
      write(*,'(A,A)') 'PASS: ', label
    else
      failures = failures + 1
      write(*,'(A,A)') 'FAIL: ', label
    end if
  end subroutine check

  subroutine assert_bounds(expected_low, expected_high, label)
    integer(int64), intent(in) :: expected_low, expected_high
    character(len=*), intent(in) :: label
    integer(int64) :: observed_low, observed_high
    call gate_cache_bounds(observed_low, observed_high)
    call check(observed_low == expected_low .and. observed_high == expected_high, label)
    if (observed_low /= expected_low .or. observed_high /= expected_high) then
      write(*,'(A,4(1X,I0))') 'GATE_CACHE_BOUNDS actual-low actual-high expected-low expected-high:', &
           observed_low, observed_high, expected_low, expected_high
    end if
  end subroutine assert_bounds
end program stage01_gate_cache_structure_probe
