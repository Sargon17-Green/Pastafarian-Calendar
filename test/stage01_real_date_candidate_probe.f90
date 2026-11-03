! Bounded real-date candidate path, NOT an independent normative differential.
! Seven actual calculation/target day pairs cover the foundation and both
! boundaries of the selected year, including previous and next year.
! Emits exact five-field numeric results for an external reference comparison.
program stage01_real_date_candidate_probe
  use iso_fortran_env, only: int64, output_unit
  use big_integer
  use normative_oracle_core, only: foundation_day
  use normative_oracle_calendar, only: YearRecord, YearStructure, &
       CalendarDateResult, reset_gate_cache, year5000, find_target_year, &
       project_calendar_date
  use stage01_fast_calendar_candidate, only: build_candidate_year_structure, &
       candidate_calendar_date
  implicit none
  type(BigInt) :: calculationDay,targets(7),offsetBI
  type(YearRecord) :: anchor,year
  type(YearStructure) :: structure
  type(CalendarDateResult) :: date,once
  integer(int64) :: previousOpen,previousClose
  integer :: i,dayOffset,monthId,cutletId,expectedDay,assertions,failures
  logical :: haveStructure

  calculationDay=foundation_day()
  call reset_gate_cache()
  anchor=year5000(calculationDay)
  targets(1)=anchor%openGateDay
  targets(2)=bi_add_small(anchor%openGateDay,1_int64)
  targets(3)=bi_add_small(calculationDay,-1_int64)
  targets(4)=calculationDay
  targets(5)=bi_add_small(calculationDay,1_int64)
  targets(6)=anchor%closeGateDay
  targets(7)=bi_add_small(anchor%closeGateDay,1_int64)
  assertions=0; failures=0
  haveStructure=.false.
  previousOpen=huge(0_int64); previousClose=huge(0_int64)
  do i=1,size(targets)
     year=find_target_year(calculationDay,targets(i))
     if (.not.haveStructure .or. year%openGateIndex/=previousOpen .or. &
          year%closeGateIndex/=previousClose) then
        write(output_unit,'(A,I0)') 'STAGE01_REAL_DATE_STRUCTURE_BEGIN=',i
        flush(output_unit)
        structure=build_candidate_year_structure(calculationDay,year)
        previousOpen=year%openGateIndex
        previousClose=year%closeGateIndex
        haveStructure=.true.
     end if
     date=project_calendar_date(targets(i),year,structure)

     call check(bi_equal(date%yearNumber,year%number),i,1)
     cutletId=0
     block
       integer :: j
       do j=1,structure%cutletCount
          if (bi_compare(structure%cutletFirstDays(j),targets(i))<=0 .and. &
               bi_compare(targets(i),structure%cutletLastDays(j))<=0) then
             cutletId=j
             exit
          end if
       end do
     end block
     if (cutletId==0) error stop 'candidate calendar: target outside cutlets'
     expectedDay=int(bi_to_int64(bi_sub(targets(i),structure%cutletFirstDays(cutletId))))+1
     call check(date%cutletCanonicalIndex==structure%cutletNameIndices(cutletId),i,2)
     call check(date%dayInCutlet==expectedDay,i,3)
     offsetBI=bi_sub(targets(i),structure%yearFirstDay)
     dayOffset=int(bi_to_int64(offsetBI))+1
     if (dayOffset<1 .or. dayOffset>size(structure%monthWeaving)) &
          error stop 'candidate calendar: month offset out of bounds'
     monthId=structure%monthWeaving(dayOffset)
     call check(date%monthCanonicalIndex==structure%monthNameIndices(monthId),i,4)
     call check(date%dayInMonth==count(structure%monthWeaving(1:dayOffset)==monthId),i,5)

     write(*,'(A,I0)') 'STAGE01_REAL_DATE_CASE=',i
     write(*,'(A,A)') 'STAGE01_REAL_DATE_CALCULATION=',bi_to_string(calculationDay)
     write(*,'(A,A)') 'STAGE01_REAL_DATE_TARGET=',bi_to_string(targets(i))
     write(*,'(A,A)') 'STAGE01_REAL_DATE_YEAR=',bi_to_string(date%yearNumber)
     write(*,'(A,I0)') 'STAGE01_REAL_DATE_CUTLET=',date%cutletCanonicalIndex
     write(*,'(A,I0)') 'STAGE01_REAL_DATE_DAY_IN_CUTLET=',date%dayInCutlet
     write(*,'(A,I0)') 'STAGE01_REAL_DATE_MONTH=',date%monthCanonicalIndex
     write(*,'(A,I0)') 'STAGE01_REAL_DATE_DAY_IN_MONTH=',date%dayInMonth
     flush(output_unit)
  end do

  write(*,'(A,I0)') 'STAGE01_REAL_DATE_CANDIDATE_CASES=',size(targets)
  write(*,'(A,I0)') 'STAGE01_REAL_DATE_CANDIDATE_ASSERTIONS=',assertions
  write(*,'(A,I0)') 'STAGE01_REAL_DATE_CANDIDATE_FAILURES=',failures
  if (assertions/=35 .or. failures/=0) error stop 1
  write(*,'(A)') 'STAGE01_REAL_DATE_CANDIDATE_PASS (internal invariants only; NOT independent OracleEngine comparison)'
contains
  subroutine check(valid,caseNumber,field)
    logical, intent(in) :: valid
    integer, intent(in) :: caseNumber,field
    assertions=assertions+1
    if (valid) return
    failures=failures+1
    if (failures<=12) write(*,'(A,I0,A,I0)') 'STAGE01_REAL_DATE_FAIL case=',caseNumber,' field=',field
  end subroutine check
end program stage01_real_date_candidate_probe
