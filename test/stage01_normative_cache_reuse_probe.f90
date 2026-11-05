! Same-process regression against pinned independent Python values already
! verified in run 41713027953 and direct Fortran run 41788817744.
! The original normative entry point is called A-B-A/B-A-B WITHOUT resetting
! the gate cache between calls. This does not assert full Stage 1 acceptance.
program stage01_normative_cache_reuse_probe
  use iso_fortran_env, only: int64
  use big_integer, only: bi_from_int64, bi_equal, bi_to_string
  use normative_oracle_core, only: foundation_day
  use normative_oracle_calendar, only: CalendarDateResult, normative_calendar_date, reset_gate_cache
  implicit none

  integer(int64), parameter :: targets(2) = [-15057703_int64, -15053458_int64]
  integer(int64), parameter :: years(2) = [4999_int64, 5001_int64]
  integer, parameter :: cutlets(2) = [15, 9]
  integer, parameter :: days_in_cutlet(2) = [433, 1]
  integer, parameter :: months(2) = [32, 41]
  integer, parameter :: days_in_month(2) = [121, 1]
  integer :: order(3), step, fixture, matched, status
  type(CalendarDateResult) :: actual
  character(len=16) :: mode

  if (command_argument_count() /= 1) error stop 'expected forward or reverse'
  call get_command_argument(1, mode, status=status)
  if (status /= 0) error stop 'cannot read mode'
  select case (trim(mode))
  case ('forward')
     order = [1, 2, 1]
  case ('reverse')
     order = [2, 1, 2]
  case default
     error stop 'unsupported cache-reuse mode'
  end select

  call reset_gate_cache()
  do step = 1, 3
     fixture = order(step)
     actual = normative_calendar_date(foundation_day(), bi_from_int64(targets(fixture)))
     matched = 0
     if (bi_equal(actual%yearNumber, bi_from_int64(years(fixture)))) matched = matched + 1
     if (actual%cutletCanonicalIndex == cutlets(fixture)) matched = matched + 1
     if (actual%dayInCutlet == days_in_cutlet(fixture)) matched = matched + 1
     if (actual%monthCanonicalIndex == months(fixture)) matched = matched + 1
     if (actual%dayInMonth == days_in_month(fixture)) matched = matched + 1
     write(*,'(A,I0,A,A,A,I0,A,I0,A,I0,A)') &
          'STAGE01_NORMATIVE_CACHE_STEP=', step, ' MODE=', trim(mode), &
          ' FIXTURE=', fixture, ' TARGET=', targets(fixture), &
          ' MATCHED_FIELDS=', matched, '/5'
     if (matched /= 5) then
        write(*,'(A,A,A,4(I0,1X))') 'STAGE01_NORMATIVE_CACHE_ACTUAL=', &
             bi_to_string(actual%yearNumber), ' ', actual%cutletCanonicalIndex, &
             actual%dayInCutlet, actual%monthCanonicalIndex, actual%dayInMonth
        error stop 'same-process normative date diverged from pinned Python values'
     end if
  end do
  write(*,'(A,A,A)') 'STAGE01_NORMATIVE_CACHE_PASS MODE=', trim(mode), &
       ' CALLS=3 MATCHED_FIELDS=15/15'
end program stage01_normative_cache_reuse_probe
