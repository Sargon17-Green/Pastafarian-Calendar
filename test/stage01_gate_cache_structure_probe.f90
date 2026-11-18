! Read-only cache-boundary regression for the original Stage 1 gate cache.
! Distinguishes a real reset from a no-op, without changing date arithmetic.
! Structural cache QA only, NOT an independent full-calendar oracle.
program stage01_gate_cache_structure_probe
  use iso_fortran_env, only: int64
  use big_integer, only: BigInt, bi_equal, bi_compare, bi_add_small
  use normative_oracle_core, only: foundation_day
  use normative_oracle_calendar, only: reset_gate_cache, ensure_gate_index, &
       gate_day, gate_cache_bounds, positive_gate_gap, negative_gate_gap, exact_gate_index
  implicit none

  type(BigInt) :: anchor, forward_day, backward_day
  integer :: assertions, failures, i
  integer(int64) :: k, idx, n
  integer(int64), parameter :: sample_indices(4) = [-2_int64, -1_int64, 1_int64, 3_int64]
  type(BigInt) :: boundary, oracle_days(-3:3), wide_days(-8:8)
  integer(int64) :: observed_low, observed_high
  integer :: j, gap_length, offset
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

  ! Independent of gate-cache construction: direct gap-sum reconstruction.
  ! This is a structural oracle, not an independent sauce/calendar oracle.
  oracle_days(0) = anchor
  do n = 1_int64, 3_int64
    oracle_days(n) = bi_add_small(oracle_days(n-1_int64), int(positive_gate_gap(n), int64))
    oracle_days(-n) = bi_add_small(oracle_days(-n+1_int64), -int(negative_gate_gap(n), int64))
  end do
  do n = -3_int64, 3_int64
    write(assertion_label,'(A,I0)') 'gap-sum gate ', n
    call check(bi_equal(gate_day(n), oracle_days(n)), trim(assertion_label))
  end do

  ! From a cold cache, search must grow only to the nearest bounding gate.
  ! Each gate gap is at least 42 days, so +/-1 is never itself a gate.
  call reset_gate_cache()
  idx = exact_gate_index(bi_add_small(anchor, -1_int64), found)
  call check(.not. found .and. idx == -1_int64, 'cold anchor predecessor')
  call assert_bounds(-1_int64, 0_int64, 'cold negative minimal growth')

  call reset_gate_cache()
  idx = exact_gate_index(bi_add_small(anchor, 1_int64), found)
  call check(.not. found .and. idx == 0_int64, 'cold anchor successor')
  call assert_bounds(0_int64, 1_int64, 'cold positive minimal growth')

  call reset_gate_cache()
  idx = exact_gate_index(anchor, found)
  call check(found .and. idx == 0_int64, 'cold exact anchor')
  call assert_bounds(0_int64, 0_int64, 'cold exact no growth')

  call reset_gate_cache()
  idx = exact_gate_index(oracle_days(-3), found)
  call check(found .and. idx == -3_int64, 'cold exact negative gate')
  call assert_bounds(-3_int64, 0_int64, 'cold exact negative growth')

  call reset_gate_cache()
  idx = exact_gate_index(oracle_days(3), found)
  call check(found .and. idx == 3_int64, 'cold exact positive gate')
  call assert_bounds(0_int64, 3_int64, 'cold exact positive growth')

  call reset_gate_cache()
  idx = exact_gate_index(bi_add_small(oracle_days(-3), 1_int64), found)
  call check(.not. found .and. idx == -3_int64, 'cold interior negative')
  call assert_bounds(-3_int64, 0_int64, 'cold negative interior growth')

  call reset_gate_cache()
  idx = exact_gate_index(bi_add_small(oracle_days(3), -1_int64), found)
  call check(.not. found .and. idx == 2_int64, 'cold interior positive')
  call assert_bounds(0_int64, 3_int64, 'cold positive interior growth')


  ! Independent interval-search oracle: reconstruct 17 boundaries from direct
  ! per-gate gaps, then check the binary search against known half-open ranges.
  ! This tests index lookup, not the independent sauce or full calendar.
  wide_days(0) = anchor
  do n = 1_int64, 8_int64
    wide_days(n) = bi_add_small(wide_days(n-1_int64), int(positive_gate_gap(n), int64))
    wide_days(-n) = bi_add_small(wide_days(-n+1_int64), -int(negative_gate_gap(n), int64))
  end do

  ! 16 intervals x 4 offsets = 64 checks, across both directions.
  ! Querying in increasing order exercises hot-cache binary search.
  do k = -8_int64, 7_int64
    if (k < 0_int64) then
      gap_length = negative_gate_gap(-k)
    else
      gap_length = positive_gate_gap(k+1_int64)
    end if
    do j = 1, 4
      select case (j)
      case (1)
        offset = 0
      case (2)
        offset = 1
      case (3)
        offset = gap_length / 2
      case (4)
        offset = gap_length - 1
      end select
      boundary = bi_add_small(wide_days(k), int(offset, int64))
      idx = exact_gate_index(boundary, found)
      write(assertion_label,'(A,I0,A,I0)') 'warm interval ', k, ' offset ', offset
      call check(idx == k .and. (found .eqv. (offset == 0)), trim(assertion_label))
    end do
  end do

  ! 16 middle-of-gap probes from a fresh cache in reverse index order:
  ! one index result and one minimal-extension bound check per interval.
  do k = 7_int64, -8_int64, -1_int64
    if (k < 0_int64) then
      gap_length = negative_gate_gap(-k)
    else
      gap_length = positive_gate_gap(k+1_int64)
    end if
    boundary = bi_add_small(wide_days(k), int(gap_length/2, int64))
    call reset_gate_cache()
    idx = exact_gate_index(boundary, found)
    write(assertion_label,'(A,I0)') 'cold reverse middle index ', k
    call check(idx == k .and. .not. found, trim(assertion_label))
    call gate_cache_bounds(observed_low, observed_high)
    write(assertion_label,'(A,I0)') 'cold reverse minimal bounds ', k
    call check(observed_low == min(k, 0_int64) .and. &
         observed_high == max(k+1_int64, 0_int64), trim(assertion_label))
  end do

  ! A hot cache with both directions populated must be observationally stable
  ! under shuffled cross-direction queries. 5 is coprime to 16, so all 16
  ! intervals are visited exactly once in a non-monotone permutation.
  ! Expected indices use the independent direct-gap-sum wide_days oracle.
  call reset_gate_cache()
  call ensure_gate_index(-8_int64)
  call ensure_gate_index(8_int64)
  do j = 0, 15
    k = int(mod(5*j+3, 16)-8, int64)
    if (k < 0_int64) then
      gap_length = negative_gate_gap(-k)
    else
      gap_length = positive_gate_gap(k+1_int64)
    end if
    do i = 1, 3
      select case (i)
      case (1)
        offset = 0
      case (2)
        offset = gap_length / 2
      case (3)
        offset = gap_length - 1
      end select
      boundary = bi_add_small(wide_days(k), int(offset, int64))
      idx = exact_gate_index(boundary, found)
      write(assertion_label,'(A,I0,A,I0)') 'shuffled hot interval ', k, ' offset ', offset
      call check(idx == k .and. (found .eqv. (offset == 0)), trim(assertion_label))
    end do
    call gate_cache_bounds(observed_low, observed_high)
    write(assertion_label,'(A,I0)') 'shuffled hot stable bounds ', k
    call check(observed_low == -8_int64 .and. observed_high == 8_int64, trim(assertion_label))
  end do

  write(*,'(A,I0)') 'STAGE01_GATE_CACHE_STRUCTURE_ASSERTIONS=', assertions
  write(*,'(A,I0)') 'STAGE01_GATE_CACHE_STRUCTURE_FAILURES=', failures
  if (assertions /= 215 .or. failures /= 0) error stop 'gate cache structural reset contract failed'
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
