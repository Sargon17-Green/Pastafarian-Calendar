! Stage1 direct normative calendar date versus independently verified Python
! NormativeCalendar.calendar_date_ids, reference commit
! 0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4
! and reference blob d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53.
! Every fixture was observed as an exact Python value in completed
! GitHub CI 41713027953 / artifact fortran-stage01-python-independent-diff.
! One bounded process per case: all five fields must match exactly.
program stage01_normative_real_date_probe
  use iso_fortran_env, only: int64
  use big_integer, only: BigInt, bi_from_int64, bi_equal, bi_to_string
  use normative_oracle_core, only: foundation_day
  use normative_oracle_calendar, only: CalendarDateResult, normative_calendar_date, reset_gate_cache
  implicit none
  integer(int64), parameter :: targets(7)=[ &
       -15057703_int64,-15057702_int64,-15055672_int64,-15055671_int64, &
       -15055670_int64,-15053459_int64,-15053458_int64 ]
  integer(int64), parameter :: years(7)=[ &
       4999_int64,5000_int64,5000_int64,5000_int64, &
       5000_int64,5000_int64,5001_int64 ]
  integer, parameter :: cutlets(7)=[15,15,10,10,14,13,9]
  integer, parameter :: cutlet_days(7)=[433,1,502,503,1,218,1]
  integer, parameter :: months(7)=[32,18,32,20,29,26,41]
  integer, parameter :: month_days(7)=[121,1,21,56,38,105,1]
  type(CalendarDateResult) :: actual
  character(len=32) :: arg
  integer :: caseIndex,istat,matched

  if (command_argument_count()/=1) error stop 'provide one fixture number 1..7'
  call get_command_argument(1,arg,status=istat)
  if (istat/=0) error stop 'cannot read fixture number'
  read(arg,*,iostat=istat) caseIndex
  if (istat/=0) error stop 'invalid fixture number'
  if (caseIndex<1 .or. caseIndex>7) error stop 'fixture number out of range'

  call reset_gate_cache()
  actual=normative_calendar_date(foundation_day(),bi_from_int64(targets(caseIndex)))
  matched=0
  if (bi_equal(actual%yearNumber,bi_from_int64(years(caseIndex)))) matched=matched+1
  if (actual%cutletCanonicalIndex==cutlets(caseIndex)) matched=matched+1
  if (actual%dayInCutlet==cutlet_days(caseIndex)) matched=matched+1
  if (actual%monthCanonicalIndex==months(caseIndex)) matched=matched+1
  if (actual%dayInMonth==month_days(caseIndex)) matched=matched+1

  write(*,'(A,I0,A,I0,A,I0,A)') 'STAGE01_NORMATIVE_CASE=',caseIndex, &
       ' TARGET=',targets(caseIndex),' MATCHED_FIELDS=',matched,'/5'
  if (matched/=5) then
     write(*,'(A,A,A,4(I0,1X))') 'STAGE01_NORMATIVE_ACTUAL=', &
          bi_to_string(actual%yearNumber),' ',actual%cutletCanonicalIndex, &
          actual%dayInCutlet,actual%monthCanonicalIndex,actual%dayInMonth
     error stop 'direct normative date differs from independent Python fixture'
  end if
end program stage01_normative_real_date_probe
