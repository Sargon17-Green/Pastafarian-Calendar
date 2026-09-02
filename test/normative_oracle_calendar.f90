module normative_oracle_calendar
  use iso_fortran_env, only: int64
  use big_integer
  use source_language_catalog
  use normative_oracle_core
  implicit none
  private

  type, public :: YearRecord
     type(BigInt) :: number
     integer(int64) :: openGateIndex = 0_int64
     integer(int64) :: closeGateIndex = 0_int64
     type(BigInt) :: openGateDay
     type(BigInt) :: closeGateDay
  end type YearRecord

  type, public :: YearStructure
     type(BigInt) :: yearFirstDay
     integer :: cutletCount = 0
     integer, allocatable :: cutletPartition(:)
     integer, allocatable :: cutletNameIndices(:)
     type(BigInt), allocatable :: cutletFirstDays(:)
     type(BigInt), allocatable :: cutletLastDays(:)
     integer :: monthCount = 0
     integer, allocatable :: monthLengths(:)
     integer, allocatable :: monthWeaving(:)
     integer, allocatable :: monthNameIndices(:)
  end type YearStructure

  type, public :: CalendarDateResult
     type(BigInt) :: yearNumber
     integer :: cutletCanonicalIndex = 0
     integer :: dayInCutlet = 0
     integer :: monthCanonicalIndex = 0
     integer :: dayInMonth = 0
  end type CalendarDateResult

  type :: GateCache
     integer(int64) :: minIndex = 0_int64
     integer(int64) :: maxIndex = 0_int64
     type(BigInt), allocatable :: day(:)
  end type GateCache

  type :: CutletMemoEntry
     integer :: rem = 0
     integer :: slots = 0
     integer :: cumulative = 0
     logical :: hit = .false.
     type(BigInt) :: count
  end type CutletMemoEntry

  type :: CutletMemo
     type(CutletMemoEntry), allocatable :: entries(:)
  end type CutletMemo

  type(GateCache), save :: gates
  logical, save :: gatesInitialized = .false.

  public :: reset_gate_cache, ensure_gate_index, gate_day
  public :: positive_gate_gap, negative_gate_gap, exact_gate_index
  public :: year5000, next_year, previous_year, find_target_year
  public :: build_year_structure, normative_calendar_date
  public :: count_cutlet_partitions, unrank_cutlet_partition

contains

  subroutine reset_gate_cache()
    if (allocated(gates%day)) deallocate(gates%day)
    allocate(gates%day(0:0))
    gates%day(0)=foundation_day()
    gates%minIndex=0_int64
    gates%maxIndex=0_int64
    gatesInitialized=.true.
  end subroutine reset_gate_cache

  subroutine ensure_gate_boot()
    if (.not. gatesInitialized) call reset_gate_cache()
  end subroutine ensure_gate_boot

  function positive_gate_gap(n) result(gap)
    integer(int64), intent(in) :: n
    integer :: gap
    type(BigInt) :: target,rank
    type(SauceResult) :: s
    type(AnswerStream) :: a
    if (n<1_int64) error stop 'positive gate index must be at least one'
    target=bi_add(foundation_day(),bi_from_int64(n))
    s=normative_sauce(foundation_day(),target)
    a=ask_bowl(s,1,SEAL_GATE_GAP)
    rank=choose_rank(a,bi_from_int64(922_int64))
    gap=41+int(bi_to_int64(rank))
  end function positive_gate_gap

  function negative_gate_gap(n) result(gap)
    integer(int64), intent(in) :: n
    integer :: gap
    type(BigInt) :: target,rank
    type(SauceResult) :: s
    type(AnswerStream) :: a
    if (n<1_int64) error stop 'negative gate magnitude must be at least one'
    target=bi_sub(foundation_day(),bi_from_int64(n))
    s=normative_sauce(foundation_day(),target)
    a=ask_bowl(s,1,SEAL_GATE_GAP)
    rank=choose_rank(a,bi_from_int64(922_int64))
    gap=41+int(bi_to_int64(rank))
  end function negative_gate_gap

  subroutine ensure_gate_index(k)
    integer(int64), intent(in) :: k
    type(BigInt), allocatable :: nextDays(:)
    integer(int64) :: n,oldMin,oldMax
    integer :: gap
    call ensure_gate_boot()
    if (k>gates%maxIndex) then
       oldMin=gates%minIndex; oldMax=gates%maxIndex
       allocate(nextDays(oldMin:k))
       nextDays(oldMin:oldMax)=gates%day(oldMin:oldMax)
       do n=oldMax+1_int64,k
          gap=positive_gate_gap(n)
          nextDays(n)=bi_add_small(nextDays(n-1_int64),int(gap,int64))
       end do
       call move_alloc(nextDays,gates%day)
       gates%maxIndex=k
    end if
    if (k<gates%minIndex) then
       oldMin=gates%minIndex; oldMax=gates%maxIndex
       allocate(nextDays(k:oldMax))
       nextDays(oldMin:oldMax)=gates%day(oldMin:oldMax)
       do n=oldMin-1_int64,k,-1_int64
          gap=negative_gate_gap(abs(n))
          nextDays(n)=bi_sub(nextDays(n+1_int64),bi_from_int64(int(gap,int64)))
       end do
       call move_alloc(nextDays,gates%day)
       gates%minIndex=k
    end if
  end subroutine ensure_gate_index

  function gate_day(k) result(d)
    integer(int64), intent(in) :: k
    type(BigInt) :: d
    call ensure_gate_index(k)
    d=gates%day(k)
  end function gate_day

  subroutine ensure_gates_cover(lowDay,highDay)
    type(BigInt), intent(in) :: lowDay,highDay
    if (bi_compare(lowDay,highDay)>0) error stop 'gate cover bounds are reversed'
    call ensure_gate_boot()
    do while (bi_compare(gates%day(gates%minIndex),lowDay)>0)
       call ensure_gate_index(gates%minIndex-1_int64)
    end do
    do while (bi_compare(gates%day(gates%maxIndex),highDay)<0)
       call ensure_gate_index(gates%maxIndex+1_int64)
    end do
  end subroutine ensure_gates_cover

  function gate_index_at_or_before(day) result(idx)
    type(BigInt), intent(in) :: day
    integer(int64) :: idx,lo,hi,mid
    call ensure_gates_cover(day,day)
    lo=gates%minIndex; hi=gates%maxIndex
    do while (lo<hi)
       mid=lo+(hi-lo+1_int64)/2_int64
       if (bi_compare(gates%day(mid),day)<=0) then
          lo=mid
       else
          hi=mid-1_int64
       end if
    end do
    idx=lo
  end function gate_index_at_or_before

  function exact_gate_index(day,found) result(idx)
    type(BigInt), intent(in) :: day
    logical, intent(out) :: found
    integer(int64) :: idx
    idx=gate_index_at_or_before(day)
    found=bi_equal(gates%day(idx),day)
  end function exact_gate_index

  integer function year_length(openIndex,closeIndex)
    integer(int64), intent(in) :: openIndex,closeIndex
    type(BigInt) :: d
    call ensure_gate_index(openIndex); call ensure_gate_index(closeIndex)
    d=bi_sub(gates%day(closeIndex),gates%day(openIndex))
    year_length=int(bi_to_int64(d))
  end function year_length

  logical function valid_year_pair(openIndex,closeIndex)
    integer(int64), intent(in) :: openIndex,closeIndex
    integer :: L
    valid_year_pair=.false.
    if (closeIndex-openIndex<6_int64) return
    L=year_length(openIndex,closeIndex)
    valid_year_pair=(L>=YEAR_MIN_DAYS .and. L<=YEAR_MAX_DAYS)
  end function valid_year_pair

  function year5000(calculationDay) result(y)
    type(BigInt), intent(in) :: calculationDay
    type(YearRecord) :: y
    type(BigInt) :: lowDay,highDay,rank
    type(SauceResult) :: s
    type(AnswerStream) :: a
    integer(int64), allocatable :: opens(:),closes(:)
    integer, allocatable :: lengths(:)
    integer(int64) :: i,j
    integer :: cap,n,p,q,tmpL,chosen
    integer(int64) :: tmpI

    lowDay=bi_sub(calculationDay,bi_from_int64(int(YEAR_MAX_DAYS,int64)))
    highDay=bi_add(calculationDay,bi_from_int64(int(YEAR_MAX_DAYS,int64)))
    call ensure_gates_cover(lowDay,highDay)
    cap=int((gates%maxIndex-gates%minIndex+1_int64)*(gates%maxIndex-gates%minIndex)/2_int64)
    allocate(opens(max(1,cap)),closes(max(1,cap)),lengths(max(1,cap)))
    n=0
    do i=gates%minIndex,gates%maxIndex-1_int64
       do j=i+1_int64,gates%maxIndex
          if (.not. valid_year_pair(i,j)) cycle
          if (.not. (bi_compare(gates%day(i),calculationDay)<0 .and. bi_compare(calculationDay,gates%day(j))<=0)) cycle
          n=n+1; opens(n)=i; closes(n)=j; lengths(n)=year_length(i,j)
       end do
    end do
    if (n==0) error stop 'year 5000 candidate set is empty'
    do p=2,n
       q=p
       do while (q>1)
          if (lengths(q-1)<lengths(q)) exit
          if (lengths(q-1)==lengths(q)) then
             if (bi_compare(gates%day(opens(q-1)),gates%day(opens(q)))<=0) exit
          end if
          tmpL=lengths(q-1); lengths(q-1)=lengths(q); lengths(q)=tmpL
          tmpI=opens(q-1); opens(q-1)=opens(q); opens(q)=tmpI
          tmpI=closes(q-1); closes(q-1)=closes(q); closes(q)=tmpI
          q=q-1
       end do
    end do
    s=normative_sauce(calculationDay,calculationDay)
    a=ask_bowl(s,1,SEAL_YEAR_5000)
    rank=choose_rank(a,bi_from_int64(int(n,int64)))
    chosen=int(bi_to_int64(rank))
    y%number=bi_from_int64(5000_int64)
    y%openGateIndex=opens(chosen); y%closeGateIndex=closes(chosen)
    y%openGateDay=gates%day(y%openGateIndex); y%closeGateDay=gates%day(y%closeGateIndex)
  end function year5000

  function next_year(calculationDay,knownYear) result(y)
    type(BigInt), intent(in) :: calculationDay
    type(YearRecord), intent(in) :: knownYear
    type(YearRecord) :: y
    integer(int64), allocatable :: candidates(:)
    integer, allocatable :: lengths(:)
    integer(int64) :: openIndex,closeIndex,tmpI
    integer :: n,cap,p,q,tmpL,chosen
    type(BigInt) :: rank
    type(SauceResult) :: s
    type(AnswerStream) :: a
    openIndex=knownYear%closeGateIndex
    cap=YEAR_MAX_DAYS/42+2; allocate(candidates(cap),lengths(cap)); n=0
    closeIndex=openIndex+1_int64
    do
       call ensure_gate_index(closeIndex)
       if (year_length(openIndex,closeIndex)>YEAR_MAX_DAYS) exit
       if (valid_year_pair(openIndex,closeIndex)) then
          n=n+1; candidates(n)=closeIndex; lengths(n)=year_length(openIndex,closeIndex)
       end if
       closeIndex=closeIndex+1_int64
    end do
    if (n==0) error stop 'next year candidate set is empty'
    do p=2,n
       q=p
       do while (q>1 .and. lengths(q-1)>lengths(q))
          tmpL=lengths(q-1); lengths(q-1)=lengths(q); lengths(q)=tmpL
          tmpI=candidates(q-1); candidates(q-1)=candidates(q); candidates(q)=tmpI; q=q-1
       end do
    end do
    s=normative_sauce(calculationDay,gates%day(openIndex)); a=ask_bowl(s,1,SEAL_NEXT_YEAR)
    rank=choose_rank(a,bi_from_int64(int(n,int64))); chosen=int(bi_to_int64(rank)); closeIndex=candidates(chosen)
    y%number=bi_add_small(knownYear%number,1_int64); y%openGateIndex=openIndex; y%closeGateIndex=closeIndex
    y%openGateDay=gates%day(openIndex); y%closeGateDay=gates%day(closeIndex)
  end function next_year

  function previous_year(calculationDay,knownYear) result(y)
    type(BigInt), intent(in) :: calculationDay
    type(YearRecord), intent(in) :: knownYear
    type(YearRecord) :: y
    integer(int64), allocatable :: candidates(:)
    integer, allocatable :: lengths(:)
    integer(int64) :: openIndex,closeIndex,tmpI
    integer :: n,cap,p,q,tmpL,chosen
    type(BigInt) :: rank
    type(SauceResult) :: s
    type(AnswerStream) :: a
    closeIndex=knownYear%openGateIndex
    cap=YEAR_MAX_DAYS/42+2; allocate(candidates(cap),lengths(cap)); n=0
    openIndex=closeIndex-1_int64
    do
       call ensure_gate_index(openIndex)
       if (year_length(openIndex,closeIndex)>YEAR_MAX_DAYS) exit
       if (valid_year_pair(openIndex,closeIndex)) then
          n=n+1; candidates(n)=openIndex; lengths(n)=year_length(openIndex,closeIndex)
       end if
       openIndex=openIndex-1_int64
    end do
    if (n==0) error stop 'previous year candidate set is empty'
    do p=2,n
       q=p
       do while (q>1 .and. lengths(q-1)>lengths(q))
          tmpL=lengths(q-1); lengths(q-1)=lengths(q); lengths(q)=tmpL
          tmpI=candidates(q-1); candidates(q-1)=candidates(q); candidates(q)=tmpI; q=q-1
       end do
    end do
    s=normative_sauce(calculationDay,gates%day(closeIndex)); a=ask_bowl(s,1,SEAL_PREVIOUS_YEAR)
    rank=choose_rank(a,bi_from_int64(int(n,int64))); chosen=int(bi_to_int64(rank)); openIndex=candidates(chosen)
    y%number=bi_add_small(knownYear%number,-1_int64); y%openGateIndex=openIndex; y%closeGateIndex=closeIndex
    y%openGateDay=gates%day(openIndex); y%closeGateDay=gates%day(closeIndex)
  end function previous_year

  function find_target_year(calculationDay,targetDay) result(y)
    type(BigInt), intent(in) :: calculationDay,targetDay
    type(YearRecord) :: y
    y=year5000(calculationDay)
    do while (bi_compare(targetDay,y%closeGateDay)>0)
       y=next_year(calculationDay,y)
    end do
    do while (bi_compare(targetDay,y%openGateDay)<=0)
       y=previous_year(calculationDay,y)
    end do
    if (.not. (bi_compare(y%openGateDay,targetDay)<0 .and. bi_compare(targetDay,y%closeGateDay)<=0)) error stop 'target year invariant failed'
  end function find_target_year

  function count_cutlet_partitions(G,K,requiredBoundary) result(count)
    integer, intent(in) :: G,K,requiredBoundary
    type(BigInt) :: count
    type(CutletMemo) :: memo
    allocate(memo%entries(0))
    count=C(G,K,0,.false.)
  contains
    recursive function C(rem,slots,cumulative,hit) result(v)
      integer, intent(in) :: rem,slots,cumulative
      logical, intent(in) :: hit
      type(BigInt) :: v
      integer :: idx,x,maxX,nextCumulative
      logical :: nextHit
      if (slots==0) then
         if (rem/=0) then
            v=bi_zero()
         else if (requiredBoundary<0) then
            v=bi_one()
         else if (hit) then
            v=bi_one()
         else
            v=bi_zero()
         end if
         return
      end if
      if (rem<slots) then; v=bi_zero(); return; end if
      idx=findCutletMemo(memo,rem,slots,cumulative,hit)
      if (idx>0) then; v=memo%entries(idx)%count; return; end if
      v=bi_zero(); maxX=rem-(slots-1)
      do x=1,maxX
         nextCumulative=cumulative+x; nextHit=hit
         if (requiredBoundary>=0 .and. .not. hit) then
            if (nextCumulative==requiredBoundary) then
               nextHit=.true.
            else if (nextCumulative>requiredBoundary) then
               cycle
            end if
         end if
         v=bi_add(v,C(rem-x,slots-1,nextCumulative,nextHit))
      end do
      call putCutletMemo(memo,rem,slots,cumulative,hit,v)
    end function C
  end function count_cutlet_partitions

  subroutine unrank_cutlet_partition(G,K,requiredBoundary,rank1,out)
    integer, intent(in) :: G,K,requiredBoundary
    type(BigInt), intent(in) :: rank1
    integer, intent(out) :: out(K)
    type(CutletMemo) :: memo
    type(BigInt) :: r,block,total
    integer :: rem,slots,cumulative,pos,x,maxX,nextCumulative,idx
    logical :: hit,nextHit
    allocate(memo%entries(0)); total=C(G,K,0,.false.)
    if (bi_compare(rank1,bi_one())<0 .or. bi_compare(rank1,total)>0) error stop 'cutlet partition rank out of range'
    r=rank1; rem=G; slots=K; cumulative=0; hit=.false.
    do pos=1,K
       maxX=rem-(slots-1)
       do x=1,maxX
          nextCumulative=cumulative+x; nextHit=hit
          if (requiredBoundary>=0 .and. .not. hit) then
             if (nextCumulative==requiredBoundary) then
                nextHit=.true.
             else if (nextCumulative>requiredBoundary) then
                cycle
             end if
          end if
          block=C(rem-x,slots-1,nextCumulative,nextHit)
          if (bi_compare(r,block)>0) then
             r=bi_sub(r,block)
          else
             out(pos)=x; rem=rem-x; slots=slots-1; cumulative=nextCumulative; hit=nextHit; exit
          end if
       end do
    end do
  contains
    recursive function C(rr,ss,cc,hh) result(v)
      integer, intent(in) :: rr,ss,cc
      logical, intent(in) :: hh
      type(BigInt) :: v
      integer :: q,xx,mx,nc
      logical :: nh
      if (ss==0) then
         if (rr/=0) then; v=bi_zero(); else if (requiredBoundary<0 .or. hh) then; v=bi_one(); else; v=bi_zero(); end if
         return
      end if
      if (rr<ss) then; v=bi_zero(); return; end if
      q=findCutletMemo(memo,rr,ss,cc,hh); if (q>0) then; v=memo%entries(q)%count; return; end if
      v=bi_zero(); mx=rr-(ss-1)
      do xx=1,mx
         nc=cc+xx; nh=hh
         if (requiredBoundary>=0 .and. .not. hh) then
            if (nc==requiredBoundary) then; nh=.true.; else if (nc>requiredBoundary) then; cycle; end if
         end if
         v=bi_add(v,C(rr-xx,ss-1,nc,nh))
      end do
      call putCutletMemo(memo,rr,ss,cc,hh,v)
    end function C
  end subroutine unrank_cutlet_partition

  integer function findCutletMemo(memo,rem,slots,cumulative,hit)
    type(CutletMemo), intent(in) :: memo
    integer, intent(in) :: rem,slots,cumulative
    logical, intent(in) :: hit
    integer :: i
    findCutletMemo=0
    do i=1,size(memo%entries)
       if (memo%entries(i)%rem==rem .and. memo%entries(i)%slots==slots .and. memo%entries(i)%cumulative==cumulative .and. (memo%entries(i)%hit .eqv. hit)) then
          findCutletMemo=i; return
       end if
    end do
  end function findCutletMemo

  subroutine putCutletMemo(memo,rem,slots,cumulative,hit,count)
    type(CutletMemo), intent(inout) :: memo
    integer, intent(in) :: rem,slots,cumulative
    logical, intent(in) :: hit
    type(BigInt), intent(in) :: count
    type(CutletMemoEntry), allocatable :: tmp(:)
    integer :: n
    n=size(memo%entries); allocate(tmp(n+1)); if (n>0) tmp(1:n)=memo%entries
    tmp(n+1)%rem=rem; tmp(n+1)%slots=slots; tmp(n+1)%cumulative=cumulative; tmp(n+1)%hit=hit; tmp(n+1)%count=count
    call move_alloc(tmp,memo%entries)
  end subroutine putCutletMemo

  function build_year_structure(calculationDay,year) result(s)
    type(BigInt), intent(in) :: calculationDay
    type(YearRecord), intent(in) :: year
    type(YearStructure) :: s
    type(SauceResult) :: r
    type(AnswerStream) :: a
    type(BigInt) :: rank,N
    integer :: G,K,L,lowM,highM,required,i,monthCount
    integer(int64) :: kidx,cursor
    integer(int64) :: gateIdx
    logical :: found

    s%yearFirstDay=bi_add_small(year%openGateDay,1_int64)
    r=normative_sauce(calculationDay,s%yearFirstDay)
    G=int(year%closeGateIndex-year%openGateIndex)

    a=ask_bowl(r,2,SEAL_CUTLET_COUNT)
    K=min(MAX_CUTLETS,G)-MIN_CUTLETS+1
    if (K<1) error stop 'no cutlet-count candidate'
    rank=choose_rank(a,bi_from_int64(int(K,int64)))
    s%cutletCount=MIN_CUTLETS+int(bi_to_int64(rank))-1

    required=-1
    gateIdx=exact_gate_index(calculationDay,found)
    if (found .and. gateIdx>year%openGateIndex .and. gateIdx<year%closeGateIndex) required=int(gateIdx-year%openGateIndex)
    N=count_cutlet_partitions(G,s%cutletCount,required)
    a=ask_bowl(r,2,SEAL_CUTLET_PARTITION); rank=choose_rank(a,N)
    allocate(s%cutletPartition(s%cutletCount)); call unrank_cutlet_partition(G,s%cutletCount,required,rank,s%cutletPartition)

    N=falling_factorial(CUTLET_NAME_COUNT,s%cutletCount)
    a=ask_bowl(r,5,SEAL_CUTLET_NAMES); rank=choose_rank(a,N)
    allocate(s%cutletNameIndices(s%cutletCount)); call unrank_distinct_indices(CUTLET_NAME_COUNT,s%cutletCount,rank,s%cutletNameIndices)

    allocate(s%cutletFirstDays(s%cutletCount),s%cutletLastDays(s%cutletCount))
    cursor=year%openGateIndex
    do i=1,s%cutletCount
       kidx=cursor+int(s%cutletPartition(i),int64)
       s%cutletFirstDays(i)=bi_add_small(gate_day(cursor),1_int64)
       s%cutletLastDays(i)=gate_day(kidx)
       cursor=kidx
    end do

    L=year_length(year%openGateIndex,year%closeGateIndex)
    lowM=ceil_div_small(L,MAX_MONTH_DAYS); highM=min(MAX_MONTHS,L/MIN_MONTH_DAYS)
    if (lowM<MIN_MONTHS .or. lowM>highM) error stop 'month-count bounds invalid'
    a=ask_bowl(r,3,SEAL_MONTH_COUNT); rank=choose_rank(a,bi_from_int64(int(highM-lowM+1,int64)))
    monthCount=lowM+int(bi_to_int64(rank))-1; s%monthCount=monthCount

    N=count_bounded_compositions(L,monthCount,MIN_MONTH_DAYS,MAX_MONTH_DAYS)
    a=ask_bowl(r,3,SEAL_MONTH_LENGTHS); rank=choose_rank(a,N)
    allocate(s%monthLengths(monthCount)); call unrank_bounded_composition(L,monthCount,MIN_MONTH_DAYS,MAX_MONTH_DAYS,rank,s%monthLengths)

    N=count_weavings(s%monthLengths)
    a=ask_bowl(r,4,SEAL_MONTH_WEAVING); rank=choose_rank(a,N)
    allocate(s%monthWeaving(L)); call unrank_weaving(s%monthLengths,rank,s%monthWeaving)

    N=falling_factorial(MONTH_NAME_COUNT,monthCount)
    a=ask_bowl(r,5,SEAL_MONTH_NAMES); rank=choose_rank(a,N)
    allocate(s%monthNameIndices(monthCount)); call unrank_distinct_indices(MONTH_NAME_COUNT,monthCount,rank,s%monthNameIndices)
  end function build_year_structure

  function normative_calendar_date(calculationDay,targetDay) result(resultFive)
    type(BigInt), intent(in) :: calculationDay,targetDay
    type(CalendarDateResult) :: resultFive
    type(YearRecord) :: year
    type(YearStructure) :: s
    type(BigInt) :: offsetBI,dayBI
    integer :: i,cutletId,offset,monthId
    year=find_target_year(calculationDay,targetDay)
    s=build_year_structure(calculationDay,year)
    cutletId=0
    do i=1,s%cutletCount
       if (bi_compare(s%cutletFirstDays(i),targetDay)<=0 .and. bi_compare(targetDay,s%cutletLastDays(i))<=0) then
          cutletId=i; exit
       end if
    end do
    if (cutletId==0) error stop 'target day is outside materialized cutlets'
    dayBI=bi_add_small(bi_sub(targetDay,s%cutletFirstDays(cutletId)),1_int64)
    resultFive%dayInCutlet=int(bi_to_int64(dayBI))
    resultFive%cutletCanonicalIndex=s%cutletNameIndices(cutletId)
    offsetBI=bi_sub(targetDay,s%yearFirstDay); offset=int(bi_to_int64(offsetBI))
    monthId=s%monthWeaving(offset+1); resultFive%monthCanonicalIndex=s%monthNameIndices(monthId)
    resultFive%dayInMonth=0
    do i=1,offset+1
       if (s%monthWeaving(i)==monthId) resultFive%dayInMonth=resultFive%dayInMonth+1
    end do
    resultFive%yearNumber=year%number
  end function normative_calendar_date

end module normative_oracle_calendar
