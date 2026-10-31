! Bounded, phase-tagged diagnostic of the first-day constituent calls.
! It localizes slow year selection and each year-construction subphase vs projection.
! This does NOT invoke the combined normative_calendar_date entry point.
! No claim of full algorithmic correctness or Stage 1 acceptance.
program stage01_normative_first_day_probe
  use iso_fortran_env, only: int64, output_unit
  use big_integer
  use source_language_catalog, only: CUTLET_NAME_COUNT, MONTH_NAME_COUNT
  use normative_oracle_core, only: foundation_day
  use normative_oracle_calendar, only: YearRecord, YearStructure, CalendarDateResult, &
       reset_gate_cache, year5000, find_target_year, build_year_structure, project_calendar_date
  implicit none

  type(BigInt) :: calculationDay,targetDay
  type(YearRecord) :: anchor, locatedYear
  type(YearStructure) :: structure
  type(CalendarDateResult) :: actual
  integer :: assertions,failures

  assertions=0
  failures=0
  calculationDay=foundation_day()
  call reset_gate_cache()
  anchor=year5000(calculationDay)
  targetDay=bi_add_small(anchor%openGateDay,1_int64)
  write(output_unit,'(A)') 'STAGE01_PHASE=FOUNDATION_YEAR_READY'
  flush(output_unit)
  locatedYear=find_target_year(calculationDay,targetDay)
  write(output_unit,'(A)') 'STAGE01_PHASE=TARGET_YEAR_SELECTED'
  flush(output_unit)
  structure=build_year_structure(calculationDay,locatedYear,diagnostic=.true.)
  write(output_unit,'(A)') 'STAGE01_PHASE=YEAR_STRUCTURE_READY'
  flush(output_unit)
  actual=project_calendar_date(targetDay,locatedYear,structure)
  write(output_unit,'(A)') 'STAGE01_PHASE=FIVE_FIELDS_PROJECTED'
  flush(output_unit)

  call require(bi_equal(anchor%number,bi_from_int64(5000_int64)), &
       'Anchor year is 5000')
  call require(bi_compare(targetDay,anchor%openGateDay)>0, &
       'Target is after exclusive opening boundary')
  call require(bi_compare(targetDay,anchor%closeGateDay)<=0, &
       'Target is on or before inclusive closing boundary')
  call require(bi_equal(actual%yearNumber,bi_from_int64(5000_int64)), &
       'Decomposed calendar year is 5000')
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

  write(*,'(A,I0)') 'STAGE01_PHASED_FIRST_DAY_ASSERTIONS=',assertions
  write(*,'(A,I0)') 'STAGE01_PHASED_FIRST_DAY_FAILURES=',failures
  if (failures/=0 .or. assertions/=8) error stop 1
  write(*,'(A)') 'STAGE01_PHASED_FIRST_DAY_PASS (boundary invariants only; NOT full Stage 1 acceptance)'
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
