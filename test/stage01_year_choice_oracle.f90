! Independent bounded candidate-choice oracle for year 5000.
! Gate generator and sauce are shared inputs; candidate enumeration, stable
! counting sort and rejection-sampling rank are independent of year5000.
program stage01_year_choice_oracle
  use iso_fortran_env, only: int64
  use big_integer
  use normative_oracle_core, only: foundation_day, normative_M, normative_sauce, &
       ask_bowl, SauceResult, AnswerStream, SEAL_YEAR_5000, &
       GATE_GAP_MIN, YEAR_MIN_DAYS, YEAR_MAX_DAYS
  use normative_oracle_calendar, only: YearRecord, reset_gate_cache, gate_day, year5000
  implicit none

  integer, parameter :: BOUND=YEAR_MAX_DAYS/GATE_GAP_MIN+2
  integer :: failures,assertions

  failures=0
  assertions=0
  call reset_gate_cache()
  call check_anchor(-1_int64)
  call check_anchor( 0_int64)
  call check_anchor( 1_int64)
  write(*,'(A,I0)') 'STAGE01_YEAR_CHOICE_ASSERTIONS=',assertions
  write(*,'(A,I0)') 'STAGE01_YEAR_CHOICE_FAILURES=',failures
  if (failures/=0 .or. assertions/=21) error stop 1
  write(*,'(A)') 'STAGE01_YEAR_CHOICE_ORACLE_PASS (candidate choice only; NOT full Stage 1 acceptance)'

contains

  subroutine check_anchor(delta)
    integer(int64), intent(in) :: delta
    type(BigInt) :: calculation,modulus,nBig,limit,x,rank
    type(SauceResult) :: sauce
    type(AnswerStream) :: stream
    type(YearRecord) :: actual
    integer(int64) :: offsets(-BOUND:BOUND),span
    integer, allocatable :: opens(:),closes(:),lengths(:),ordered(:)
    integer :: counts(YEAR_MIN_DAYS:YEAR_MAX_DAYS)
    integer :: positions(YEAR_MIN_DAYS:YEAR_MAX_DAYS)
    integer :: i,j,n,cap,L,p,chosen,expectedOpen,expectedClose,attempt
    logical :: accepted

    calculation=bi_add_small(foundation_day(),delta)
    do i=-BOUND,BOUND
       offsets(i)=bi_to_int64(bi_sub(gate_day(int(i,int64)),foundation_day()))
    end do
    ! BOUND*minimum_gap is greater than MAX_YEAR_DAYS+1.
    if (offsets(-BOUND)>=delta-int(YEAR_MAX_DAYS,int64) .or. &
        offsets(BOUND)<=delta+int(YEAR_MAX_DAYS,int64)) then
       error stop 'independent year oracle gate coverage is insufficient'
    end if

    cap=(2*BOUND+1)*(2*BOUND+1)
    allocate(opens(cap),closes(cap),lengths(cap))
    n=0
    do i=-BOUND,BOUND-1
       if (offsets(i)>=delta) cycle
       do j=i+1,BOUND
          if (offsets(j)<delta) cycle
          if (j-i<6) cycle
          span=offsets(j)-offsets(i)
          if (span<int(YEAR_MIN_DAYS,int64) .or. span>int(YEAR_MAX_DAYS,int64)) cycle
          n=n+1
          opens(n)=i
          closes(n)=j
          lengths(n)=int(span)
       end do
    end do
    if (n<2) error stop 'independent year oracle has fewer than two candidates'

    ! Stable counting sort: ties remain ordered by increasing opening gate.
    counts=0
    do i=1,n
       counts(lengths(i))=counts(lengths(i))+1
    end do
    positions(YEAR_MIN_DAYS)=1
    do L=YEAR_MIN_DAYS+1,YEAR_MAX_DAYS
       positions(L)=positions(L-1)+counts(L-1)
    end do
    allocate(ordered(n))
    do i=1,n
       p=positions(lengths(i))
       ordered(p)=i
       positions(lengths(i))=p+1
    end do

    sauce=normative_sauce(calculation,calculation)
    stream=ask_bowl(sauce,1,SEAL_YEAR_5000)
    modulus=normative_M()
    nBig=bi_from_int64(int(n,int64))
    limit=bi_mul(bi_floor_div(modulus,nBig),nBig)
    x=bi_add_small(bi_mod(bi_sub(stream%first,bi_one()),modulus),1_int64)
    accepted=.false.
    ! Rejected tail has length smaller than N; +/-1 reaches acceptance <=N steps.
    do attempt=0,n
       if (bi_compare(x,limit)<=0) then
          accepted=.true.
          exit
       end if
       x=bi_add_small(bi_mod(bi_add_small(bi_sub(x,bi_one()), &
            int(stream%directionStep,int64)),modulus),1_int64)
    end do
    if (.not. accepted) error stop 'independent rank walk exceeded bound'
    rank=bi_add_small(bi_mod(bi_sub(x,bi_one()),nBig),1_int64)
    chosen=int(bi_to_int64(rank))
    if (chosen<1 .or. chosen>n) error stop 'independent year rank out of bounds'
    expectedOpen=opens(ordered(chosen))
    expectedClose=closes(ordered(chosen))
    actual=year5000(calculation)

    call require(n>1,'Multiple candidate intervals')
    call require(chosen>=1 .and. chosen<=n,'Independent rank in candidate bounds')
    call require(actual%openGateIndex==int(expectedOpen,int64),'Opening index matches independent choice')
    call require(actual%closeGateIndex==int(expectedClose,int64),'Closing index matches independent choice')
    call require(bi_equal(actual%openGateDay,gate_day(int(expectedOpen,int64))), &
         'Opening date matches independently selected gate')
    call require(bi_equal(actual%closeGateDay,gate_day(int(expectedClose,int64))), &
         'Closing date matches independently selected gate')
    call require(bi_equal(actual%number,bi_from_int64(5000_int64)), &
         'Chosen year number is 5000')
    write(*,'(A,I0,A,I0,A,I0)') 'YEAR_CHOICE_DELTA=',delta, &
         ' CANDIDATES=',n,' RANK=',chosen
  end subroutine check_anchor

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
end program stage01_year_choice_oracle
