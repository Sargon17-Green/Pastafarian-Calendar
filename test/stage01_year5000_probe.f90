! Stage 1 bounded runtime and interval-invariant probe.
! Deliberately not an independent candidate-selection or full calendar oracle.
program stage01_year5000_probe
  use iso_fortran_env, only: int64
  use big_integer
  use normative_oracle_core, only: foundation_day, YEAR_MIN_DAYS, YEAR_MAX_DAYS
  use normative_oracle_calendar, only: YearRecord, reset_gate_cache, year5000, gate_day
  implicit none

  type(YearRecord) :: y
  type(BigInt) :: calculationDay,span
  integer(int64) :: lengthDays
  integer :: failures

  failures=0
  call reset_gate_cache()
  calculationDay=foundation_day()
  y=year5000(calculationDay)
  span=bi_sub(y%closeGateDay,y%openGateDay)
  lengthDays=bi_to_int64(span)

  call require(bi_equal(y%number,bi_from_int64(5000_int64)), &
       'Year5000 anchor has year number 5000')
  call require(y%openGateIndex<y%closeGateIndex, &
       'Year5000 opening gate precedes closing gate')
  call require(y%closeGateIndex-y%openGateIndex>=6_int64, &
       'Year5000 has at least six gate intervals')
  call require(lengthDays>=int(YEAR_MIN_DAYS,int64) .and. lengthDays<=int(YEAR_MAX_DAYS,int64), &
       'Year5000 length is within normative day bounds')
  call require(bi_compare(y%openGateDay,calculationDay)<0, &
       'Year5000 opening boundary excludes calculation day')
  call require(bi_compare(calculationDay,y%closeGateDay)<=0, &
       'Year5000 closing boundary includes calculation day')
  call require(bi_equal(y%openGateDay,gate_day(y%openGateIndex)), &
       'Year5000 opening day agrees with its gate index')
  call require(bi_equal(y%closeGateDay,gate_day(y%closeGateIndex)), &
       'Year5000 closing day agrees with its gate index')

  if (failures/=0) then
     write(*,'(A,I0)') 'STAGE01_YEAR5000_FAILURES=',failures
     error stop 1
  end if
  write(*,'(A)') 'STAGE01_YEAR5000_SMOKE_PASS'

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
end program stage01_year5000_probe
