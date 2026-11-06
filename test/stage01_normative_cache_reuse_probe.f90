! Same-process cache regression against previously verified SHA-pinned Python
! normative values (CI 41713027953; original Fortran run 41788817744).
! The three-year sequence revisits years 4999 and 5000 after crossing 5001,
! WITHOUT resetting the gate cache between calls. Not full Stage 1 acceptance.
program stage01_normative_cache_reuse_probe
  use iso_fortran_env, only: int64
  use big_integer, only: bi_from_int64, bi_equal, bi_to_string
  use normative_oracle_core, only: foundation_day
  use normative_oracle_calendar, only: CalendarDateResult, normative_calendar_date, reset_gate_cache
  implicit none

  integer(int64), parameter :: targets(3) = [-15057703_int64, -15053458_int64, -15055671_int64]
  integer(int64), parameter :: years(3) = [4999_int64, 5001_int64, 5000_int64]
  integer, parameter :: cutlets(3) = [15, 9, 10]
  integer, parameter :: days_in_cutlet(3) = [433, 1, 503]
  integer, parameter :: months(3) = [32, 41, 20]
  integer, parameter :: days_in_month(3) = [121, 1, 56]
  integer :: order(5), nsteps, step, fixture, matched, status
  type(CalendarDateResult) :: actual
  character(len=16) :: mode

  if (command_argument_count() /= 1) error stop 'expected forward, reverse or three-year'
  call get_command_argument(1, mode, status=status)
  if (status /= 0) error stop 'cannot read mode'
  select case (trim(mode))
  case ('forward')
     order = [1, 2, 1, 0, 0]
     nsteps = 3
  case ('reverse')
     order = [2, 1, 2, 0, 0]
     nsteps = 3
  case ('three-year')
     order = [1, 3, 2, 3, 1]
     nsteps = 5
  case default
     error stop 'unsupported cache-reuse mode'
  end select

  call reset_gate_cache()
  do step = 1, nsteps
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
  write(*,'(A,A,A,I0,A,I0,A,I0)') 'STAGE01_NORMATIVE_CACHE_PASS MODE=', &
       trim(mode), ' CALLS=', nsteps, ' MATCHED_FIELDS=', 5*nsteps, '/', 5*nsteps
end program stage01_normative_cache_reuse_probe
