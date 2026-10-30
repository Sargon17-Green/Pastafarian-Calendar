! Bounded Stage 1 adjacent-year and endpoint semantics probe.
! Structural invariants only: no independent year-choice or month oracle.
program stage01_year_boundary_probe
  use iso_fortran_env, only: int64
  use big_integer
  use normative_oracle_core, only: foundation_day, YEAR_MIN_DAYS, YEAR_MAX_DAYS
  use normative_oracle_calendar, only: YearRecord, reset_gate_cache, &
       year5000, next_year, previous_year, find_target_year
  implicit none

  type(YearRecord) :: anchor,before,after,located
  type(BigInt) :: calculationDay
  integer(int64) :: beforeDays,afterDays
  integer :: failures

  failures=0
  call reset_gate_cache()
  calculationDay=foundation_day()
  anchor=year5000(calculationDay)
  before=previous_year(calculationDay,anchor)
  after=next_year(calculationDay,anchor)
  beforeDays=bi_to_int64(bi_sub(before%closeGateDay,before%openGateDay))
  afterDays=bi_to_int64(bi_sub(after%closeGateDay,after%openGateDay))

  call require(bi_equal(before%number,bi_from_int64(4999_int64)), &
       'Previous year is 4999')
  call require(bi_equal(after%number,bi_from_int64(5001_int64)), &
       'Next year is 5001')
  call require(before%closeGateIndex==anchor%openGateIndex, &
       'Previous closing gate joins anchor opening gate')
  call require(after%openGateIndex==anchor%closeGateIndex, &
       'Next opening gate joins anchor closing gate')
  call require(bi_equal(before%closeGateDay,anchor%openGateDay), &
       'Previous last day joins anchor opening boundary')
  call require(bi_equal(after%openGateDay,anchor%closeGateDay), &
       'Next opening boundary joins anchor last day')
  call require(before%closeGateIndex-before%openGateIndex>=6_int64, &
       'Previous year has at least six gate intervals')
  call require(after%closeGateIndex-after%openGateIndex>=6_int64, &
       'Next year has at least six gate intervals')
  call require(beforeDays>=int(YEAR_MIN_DAYS,int64) .and. beforeDays<=int(YEAR_MAX_DAYS,int64), &
       'Previous year has normative length')
  call require(afterDays>=int(YEAR_MIN_DAYS,int64) .and. afterDays<=int(YEAR_MAX_DAYS,int64), &
       'Next year has normative length')

  located=find_target_year(calculationDay,anchor%openGateDay)
  call require(bi_equal(located%number,bi_from_int64(4999_int64)), &
       'Opening gate day belongs to 4999')
  located=find_target_year(calculationDay,bi_add_small(anchor%openGateDay,1_int64))
  call require(bi_equal(located%number,bi_from_int64(5000_int64)), &
       'First day after opening gate belongs to 5000')
  located=find_target_year(calculationDay,anchor%closeGateDay)
  call require(bi_equal(located%number,bi_from_int64(5000_int64)), &
       'Closing gate day belongs to 5000')
  located=find_target_year(calculationDay,bi_add_small(anchor%closeGateDay,1_int64))
  call require(bi_equal(located%number,bi_from_int64(5001_int64)), &
       'First day after closing gate belongs to 5001')

  if (failures/=0) then
     write(*,'(A,I0)') 'STAGE01_YEAR_BOUNDARY_FAILURES=',failures
     error stop 1
  end if
  write(*,'(A)') 'STAGE01_YEAR_BOUNDARY_SMOKE_PASS'

contains

  subroutine require(condition,label)
    logical, intent(in) :: condition
    character(len=*), intent(in) :: label
    if (condition) then
       write(*,'(A)') 'PASS: '//label
    else
       failures=failures+1
       write(*,'(A)') 'FAIL: '//label
    end if
  end subroutine require
end program stage01_year_boundary_probe
