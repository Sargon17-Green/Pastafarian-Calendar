! Bounded diagnostic of the real end-to-end normative_calendar_date path.
! First day of anchor year: independent boundary/ordinal invariants only.
! Names and complete year construction still require an independent oracle.
program stage01_normative_first_day_probe
  use iso_fortran_env, only: int64
  use big_integer
  use source_language_catalog, only: CUTLET_NAME_COUNT, MONTH_NAME_COUNT
  use normative_oracle_core, only: foundation_day
  use normative_oracle_calendar, only: YearRecord, CalendarDateResult, &
       reset_gate_cache, year5000, normative_calendar_date
  implicit none

  type(BigInt) :: calculationDay,targetDay
  type(YearRecord) :: anchor
  type(CalendarDateResult) :: actual
  integer :: assertions,failures

  assertions=0
  failures=0
  calculationDay=foundation_day()
  call reset_gate_cache()
  anchor=year5000(calculationDay)
  targetDay=bi_add_small(anchor%openGateDay,1_int64)
  actual=normative_calendar_date(calculationDay,targetDay)

  call require(bi_equal(anchor%number,bi_from_int64(5000_int64)), &
       'Anchor year is 5000')
  call require(bi_compare(targetDay,anchor%openGateDay)>0, &
       'Target is after exclusive opening boundary')
  call require(bi_compare(targetDay,anchor%closeGateDay)<=0, &
       'Target is on or before inclusive closing boundary')
  call require(bi_equal(actual%yearNumber,bi_from_int64(5000_int64)), &
       'End-to-end calendar year is 5000')
  call require(actual%dayInCutlet==1, &
       'First day of year is first day of its cutlet')
  call require(actual%dayInMonth==1, &
       'First day of year is first occurrence of its month')
  call require(actual%cutletCanonicalIndex>=1 .and. &
       actual%cutletCanonicalIndex<=CUTLET_NAME_COUNT, &
       'Canonical cutlet name index is in catalogue')
  call require(actual%monthCanonicalIndex>=1 .and. &
       actual%monthCanonicalIndex<=MONTH_NAME_COUNT, &
       'Canonical month name index is in catalogue')

  write(*,'(A,I0)') 'STAGE01_NORMATIVE_FIRST_DAY_ASSERTIONS=',assertions
  write(*,'(A,I0)') 'STAGE01_NORMATIVE_FIRST_DAY_FAILURES=',failures
  if (failures/=0 .or. assertions/=8) error stop 1
  write(*,'(A)') 'STAGE01_NORMATIVE_FIRST_DAY_PASS (boundary invariants only; NOT full Stage 1 acceptance)'
contains
  subroutine require(ok,label)
    logical, intent(in) :: ok
    character(len=*), intent(in) :: label
    assertions=assertions+1
    if (ok) then
       write(*,'(A)') 'PASS: '//label
    else
       failures=failures+1
       write(*,'(A)') 'FAIL: '//label
    end if
  end subroutine require
end program stage01_normative_first_day_probe
