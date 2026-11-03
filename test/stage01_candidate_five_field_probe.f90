! Synthetic 45-month candidate integration: exact five-field numeric projection.
! The month word comes from the candidate middle-rank unranker; all expected
! fields are built by a simple independent forward frequency scan and fixed
! cutlet boundaries, NOT by project_calendar_date.
! Does not compare against an external OracleEngine.calendar_date_normative
! and does NOT establish the full normative calendar date contract.
program stage01_candidate_five_field_probe
  use iso_fortran_env, only: int64
  use big_integer, only: BigInt, bi_add_small, bi_equal, bi_one, &
       bi_from_int64, bi_from_string, bi_floor_div
  use normative_oracle_core, only: foundation_day
  use normative_oracle_calendar, only: CalendarDateResult, YearRecord, &
       YearStructure, project_calendar_date
  use stage01_weaving_polynomial, only: PrefixCompletionCache, &
       prepare_prefix_completion_cache, count_prefix_weavings_polynomial
  use stage01_weaving_polynomial_unrank, only: unrank_weaving_polynomial
  implicit none

  integer, parameter :: target(45) = [ &
       115,108,119,109,106,81,115,114,117,120,98,52,81,97,121, &
       97,115,96,107,61,106,115,119,39,84,103,115,107,55,119, &
       97,50,122,110,81,54,101,83,88,40,25,77,98,122,105 ]
  integer, parameter :: cutEnd(3)=[1400,2800,4244]
  integer, parameter :: cutName(3)=[7,12,19]
  type(YearRecord) :: year
  type(YearStructure) :: s
  type(CalendarDateResult) :: actual
  type(BigInt) :: base,total,rank,day
  type(PrefixCompletionCache), target :: shared_cache
  integer :: seen(45),i,dayIndex,month,cut,dayCut,failures,checks
  logical :: ok

  if (sum(target)/=4244) error stop 'candidate projection: invalid fixture'
  base=foundation_day()
  year%number=bi_from_string('123456789012345678901234567890')
  s%yearFirstDay=bi_add_small(base,1_int64)
  s%cutletCount=3
  s%monthCount=45
  allocate(s%cutletFirstDays(3),s%cutletLastDays(3),s%cutletNameIndices(3))
  allocate(s%monthNameIndices(45),s%monthWeaving(sum(target)))
  s%cutletNameIndices=cutName
  do i=1,3
     if (i==1) then
        s%cutletFirstDays(i)=bi_add_small(base,1_int64)
     else
        s%cutletFirstDays(i)=bi_add_small(base,int(cutEnd(i-1)+1,int64))
     end if
     s%cutletLastDays(i)=bi_add_small(base,int(cutEnd(i),int64))
  end do
  do i=1,45
     s%monthNameIndices(i)=46-i
  end do

  call prepare_prefix_completion_cache(target,shared_cache)
  total=count_prefix_weavings_polynomial(target,target,0,0,shared_cache)
  rank=bi_floor_div(bi_add_small(total,1_int64),bi_from_int64(2_int64))
  if (bi_equal(rank,bi_one())) error stop 'candidate projection: non-middle rank'
  call unrank_weaving_polynomial(target,rank,s%monthWeaving,ok,total,shared_cache)
  if (.not.ok) error stop 'candidate projection: unrank did not complete'

  failures=0; checks=0; seen=0
  do dayIndex=1,4244
     month=s%monthWeaving(dayIndex)
     if (month<1 .or. month>45) error stop 'candidate projection: month out of range'
     seen(month)=seen(month)+1
     if (seen(month)>target(month)) error stop 'candidate projection: month count exceeded'
     if (dayIndex<=cutEnd(1)) then
        cut=1
        dayCut=dayIndex
     else if (dayIndex<=cutEnd(2)) then
        cut=2
        dayCut=dayIndex-cutEnd(1)
     else
        cut=3
        dayCut=dayIndex-cutEnd(2)
     end if
     day=bi_add_small(base,int(dayIndex,int64))
     actual=project_calendar_date(day,year,s)
     call check(bi_equal(actual%yearNumber,year%number),1,dayIndex)
     call check(actual%cutletCanonicalIndex==cutName(cut),2,dayIndex)
     call check(actual%dayInCutlet==dayCut,3,dayIndex)
     call check(actual%monthCanonicalIndex==46-month,4,dayIndex)
     call check(actual%dayInMonth==seen(month),5,dayIndex)
  end do
  if (any(seen/=target)) error stop 'candidate projection: incomplete month frequencies'
  write(*,'(A,I0)') 'STAGE01_CANDIDATE_FIVE_FIELD_DAYS=',sum(target)
  write(*,'(A,I0)') 'STAGE01_CANDIDATE_FIVE_FIELD_ASSERTIONS=',checks
  write(*,'(A,I0)') 'STAGE01_CANDIDATE_FIVE_FIELD_FAILURES=',failures
  if (checks/=21220 .or. failures/=0) error stop 1
  write(*,'(A)') 'STAGE01_CANDIDATE_FIVE_FIELD_PASS (synthetic 45-month mapping; NOT full normative date)'

contains
  subroutine check(condition,fieldIndex,position)
    logical, intent(in) :: condition
    integer, intent(in) :: fieldIndex,position
    checks=checks+1
    if (.not.condition) then
       failures=failures+1
       if (failures<=12) then
          write(*,'(A,I0,A,I0)') 'FIVE_FIELD_FAIL field=',fieldIndex,' position=',position
       end if
    end if
  end subroutine check
end program stage01_candidate_five_field_probe
