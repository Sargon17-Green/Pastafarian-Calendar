! Exact-output five-component date projection fixture.
! Only the date projector is tested: year choice, cutlet partition generation,
! month weaving generation and normative_calendar_date are NOT fully accepted.
program stage01_date_projection_probe
  use iso_fortran_env, only: int64
  use big_integer
  use normative_oracle_core, only: foundation_day
  use normative_oracle_calendar, only: CalendarDateResult, YearRecord, &
       YearStructure, project_calendar_date
  implicit none

  integer, parameter :: expectedCutlet(5)=[7,7,12,12,12]
  integer, parameter :: expectedDayCutlet(5)=[1,2,1,2,3]
  integer, parameter :: expectedMonth(5)=[5,9,5,9,9]
  integer, parameter :: expectedDayMonth(5)=[1,1,2,2,3]
  type(YearRecord) :: y
  type(YearStructure) :: s
  type(CalendarDateResult) :: actual
  type(BigInt) :: f,target
  character(len=16) :: item
  integer :: i,failures,assertions

  failures=0
  assertions=0
  f=foundation_day()
  y%number=bi_from_string('123456789012345678901234567890')
  s%yearFirstDay=bi_add_small(f,1_int64)
  s%cutletCount=2
  s%monthCount=2
  allocate(s%cutletFirstDays(2),s%cutletLastDays(2),s%cutletNameIndices(2))
  allocate(s%monthNameIndices(2),s%monthWeaving(5))
  s%cutletFirstDays(1)=bi_add_small(f,1_int64)
  s%cutletLastDays(1)=bi_add_small(f,2_int64)
  s%cutletFirstDays(2)=bi_add_small(f,3_int64)
  s%cutletLastDays(2)=bi_add_small(f,5_int64)
  s%cutletNameIndices=[7,12]
  s%monthNameIndices=[5,9]
  s%monthWeaving=[1,2,1,2,2]

  do i=1,5
     target=bi_add_small(f,int(i,int64))
     actual=project_calendar_date(target,y,s)
     write(item,'(I0)') i
     call require(bi_equal(actual%yearNumber,y%number), &
          'BigInt year preserved on day '//trim(item))
     call require(actual%cutletCanonicalIndex==expectedCutlet(i), &
          'Canonical cutlet on day '//trim(item))
     call require(actual%dayInCutlet==expectedDayCutlet(i), &
          'Ordinal day in cutlet on day '//trim(item))
     call require(actual%monthCanonicalIndex==expectedMonth(i), &
          'Canonical month on day '//trim(item))
     call require(actual%dayInMonth==expectedDayMonth(i), &
          'Ordinal occurrence in interleaved month on day '//trim(item))
  end do

  write(*,'(A,I0)') 'STAGE01_DATE_PROJECTION_ASSERTIONS=',assertions
  write(*,'(A,I0)') 'STAGE01_DATE_PROJECTION_FAILURES=',failures
  if (failures/=0 .or. assertions/=25) error stop 1
  write(*,'(A)') 'STAGE01_DATE_PROJECTION_PASS (synthetic mapping only; NOT full Stage 1 acceptance)'

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
end program stage01_date_projection_probe
