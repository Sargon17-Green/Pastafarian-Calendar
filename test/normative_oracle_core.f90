module normative_oracle_core
  use iso_fortran_env, only: int64
  use big_integer
  implicit none
  private

  integer, parameter, public :: WHEAT=1, BARLEY=2, SALT=3, BITTER=4, RED=5
  integer, parameter, public :: GATE_GAP_MIN=42, GATE_GAP_MAX=963
  integer, parameter, public :: YEAR_MIN_DAYS=252, YEAR_MAX_DAYS=5778
  integer, parameter, public :: MIN_CUTLETS=6, MAX_CUTLETS=17
  integer, parameter, public :: MIN_MONTHS=3, MAX_MONTHS=47
  integer, parameter, public :: MIN_MONTH_DAYS=4, MAX_MONTH_DAYS=123
  integer(int64), parameter, public :: TABLETS_DAY_I64=-278522_int64
  integer(int64), parameter, public :: FOUNDATION_DAY_I64=-15055671_int64

  integer, parameter, public :: SEAL_GATE_GAP=1
  integer, parameter, public :: SEAL_YEAR_5000=10
  integer, parameter, public :: SEAL_NEXT_YEAR=11
  integer, parameter, public :: SEAL_PREVIOUS_YEAR=12
  integer, parameter, public :: SEAL_CUTLET_COUNT=20
  integer, parameter, public :: SEAL_CUTLET_PARTITION=21
  integer, parameter, public :: SEAL_CUTLET_NAMES=22
  integer, parameter, public :: SEAL_MONTH_COUNT=30
  integer, parameter, public :: SEAL_MONTH_LENGTHS=31
  integer, parameter, public :: SEAL_MONTH_WEAVING=32
  integer, parameter, public :: SEAL_MONTH_NAMES=33

  integer, parameter :: HIDDEN_COEFF(7,4) = reshape([ &
       3,5,7,9,11,13,15, &
       4,7,10,13,16,19,22, &
       6,10,14,18,22,26,30, &
       8,12,16,20,24,28,32 ], [7,4])
  integer, parameter :: HIDDEN_GRIND_STONE(7) = [WHEAT,BARLEY,SALT,BITTER,RED,WHEAT,BARLEY]
  integer, parameter :: VISIBLE_GRINDS(11,5) = reshape([ &
       3,5,7,11,13,17,19,23,29,31,37, &
       5,7,11,13,17,19,23,29,31,37,41, &
       7,11,13,17,19,23,29,31,37,41,43, &
       11,13,17,19,23,29,31,37,41,43,47, &
       WHEAT,BARLEY,SALT,BITTER,RED,WHEAT,BARLEY,SALT,BITTER,RED,WHEAT ], [11,5])
  integer, parameter :: BOWL_PRIME(6) = [17,19,23,29,31,37]
  integer, parameter :: BOWL_STIR_STONE_BY_POSITION(6) = [WHEAT,BARLEY,SALT,BITTER,RED,WHEAT]

  type, public :: WorkCounts
     type(BigInt) :: action
     type(BigInt) :: target
     type(BigInt) :: distance
     type(BigInt) :: connection
     integer :: direction = 0
  end type WorkCounts

  type, public :: SauceResult
     type(BigInt) :: bowls(6)
     integer :: orderAtDrop46(6) = 0
  end type SauceResult

  type, public :: AnswerStream
     type(BigInt) :: first
     integer :: directionStep = 0
  end type AnswerStream

  type :: WeaveMemoEntry
     integer, allocatable :: remaining(:)
     integer :: openedUpTo = 0
     integer :: closedUpTo = 0
     type(BigInt) :: count
  end type WeaveMemoEntry

  type :: WeaveMemo
     type(WeaveMemoEntry), allocatable :: entries(:)
  end type WeaveMemo

  public :: normative_M, foundation_day, tablets_day
  public :: save_value, day_count, normative_work_counts
  public :: build_stones, build_hidden_drops, build_visible_drops
  public :: bowl_order_from_number, bowl_order_from_drop, initial_bowls
  public :: apply_visible_drops_to_bowls, post_stir_12, normative_sauce
  public :: ask_bowl, answer_at, choose_rank
  public :: falling_factorial, unrank_distinct_indices
  public :: count_bounded_compositions, unrank_bounded_composition
  public :: count_weavings, unrank_weaving
  public :: ceil_div_small, wrap1

contains

  function normative_M() result(m)
    type(BigInt) :: m
    m = bi_from_string('170141183460469231731687303715884105727')
  end function normative_M

  function foundation_day() result(d)
    type(BigInt) :: d
    d = bi_from_int64(FOUNDATION_DAY_I64)
  end function foundation_day

  function tablets_day() result(d)
    type(BigInt) :: d
    d = bi_from_int64(TABLETS_DAY_I64)
  end function tablets_day

  function save_value(x) result(r)
    type(BigInt), intent(in) :: x
    type(BigInt) :: r, m
    m = normative_M()
    r = bi_mod(bi_sub(x,bi_one()),m)
    r = bi_add_small(r,1_int64)
  end function save_value

  function day_count(day) result(n)
    type(BigInt), intent(in) :: day
    type(BigInt) :: n, f, delta
    integer :: cmp
    f = foundation_day()
    cmp = bi_compare(day,f)
    if (cmp == 0) then
       n = bi_one()
    else if (cmp > 0) then
       delta = bi_sub(day,f)
       n = bi_add_small(bi_mul_small(delta,2_int64),1_int64)
    else
       delta = bi_sub(f,day)
       n = bi_mul_small(delta,2_int64)
    end if
  end function day_count

  function normative_work_counts(calculationDay,targetDay) result(c)
    type(BigInt), intent(in) :: calculationDay,targetDay
    type(WorkCounts) :: c
    type(BigInt) :: delta
    integer :: cmp
    c%action = day_count(calculationDay)
    c%target = day_count(targetDay)
    delta = bi_abs(bi_sub(targetDay,calculationDay))
    c%distance = bi_add_small(delta,1_int64)
    c%connection = bi_add(c%action,c%target)
    cmp = bi_compare(targetDay,calculationDay)
    if (cmp < 0) then
       c%direction=1
    else if (cmp == 0) then
       c%direction=2
    else
       c%direction=3
    end if
  end function normative_work_counts

  subroutine build_stones(stones)
    type(BigInt), intent(out) :: stones(46,5)
    type(BigInt) :: old(5), next(5)
    integer :: i
    stones(1,WHEAT)=bi_from_int64(17_int64)
    stones(1,BARLEY)=bi_from_int64(29_int64)
    stones(1,SALT)=bi_from_int64(43_int64)
    stones(1,BITTER)=bi_from_int64(71_int64)
    stones(1,RED)=bi_from_int64(101_int64)
    do i=2,46
       old=stones(i-1,:)
       next(WHEAT)=save_value(bi_add_small(bi_add(bi_mul(old(WHEAT),old(WHEAT)),bi_mul_small(old(BARLEY),3_int64)),int(i,int64)))
       next(BARLEY)=save_value(bi_add(bi_add(bi_mul(old(BARLEY),old(BARLEY)),bi_mul_small(old(SALT),5_int64)),old(WHEAT)))
       next(SALT)=save_value(bi_add(bi_add(bi_mul(old(SALT),old(SALT)),bi_mul_small(old(BITTER),7_int64)),old(BARLEY)))
       next(BITTER)=save_value(bi_add(bi_add(bi_mul(old(BITTER),old(BITTER)),bi_mul_small(old(RED),11_int64)),old(SALT)))
       next(RED)=save_value(bi_add(bi_add(bi_mul(old(RED),old(RED)),bi_mul_small(old(WHEAT),13_int64)),old(BITTER)))
       stones(i,:)=next
    end do
  end subroutine build_stones

  subroutine build_hidden_drops(counts,stones,hidden)
    type(WorkCounts), intent(in) :: counts
    type(BigInt), intent(in) :: stones(46,5)
    type(BigInt), intent(out) :: hidden(7)
    type(BigInt) :: x, oldx
    integer :: k,g,kind
    do k=1,7
       x=counts%action
       x=bi_add(x,bi_mul_small(counts%target,int(HIDDEN_COEFF(k,1),int64)))
       x=bi_add(x,bi_mul_small(counts%distance,int(HIDDEN_COEFF(k,2),int64)))
       x=bi_add(x,bi_mul_small(counts%connection,int(HIDDEN_COEFF(k,3),int64)))
       x=bi_add(x,bi_from_int64(int(HIDDEN_COEFF(k,4)*counts%direction,int64)))
       do kind=1,5
          x=bi_add(x,stones(k,kind))
       end do
       x=save_value(x)
       do g=1,7
          oldx=x
          x=bi_mul(oldx,oldx)
          x=bi_add(x,bi_mul_small(oldx,3_int64))
          x=bi_add(x,stones(k,HIDDEN_GRIND_STONE(g)))
          x=bi_add_small(x,int(g,int64))
          x=save_value(x)
       end do
       hidden(k)=x
    end do
  end subroutine build_hidden_drops

  subroutine build_visible_drops(counts,stones,hidden,visible)
    type(WorkCounts), intent(in) :: counts
    type(BigInt), intent(in) :: stones(46,5),hidden(7)
    type(BigInt), intent(out) :: visible(46)
    type(BigInt) :: timeline(-6:46)
    type(BigInt) :: p1,p3,p7,x,oldx
    integer :: i,g,k,kind
    do k=1,7
       timeline(1-k)=hidden(k)
    end do
    do i=1,46
       p1=timeline(i-1); p3=timeline(i-3); p7=timeline(i-7)
       x=bi_mul(stones(i,WHEAT),counts%action)
       x=bi_add(x,bi_mul(stones(i,BARLEY),counts%target))
       x=bi_add(x,bi_mul(stones(i,SALT),counts%distance))
       x=bi_add(x,bi_mul(stones(i,BITTER),counts%connection))
       x=bi_add(x,bi_mul_small(stones(i,RED),int(counts%direction,int64)))
       x=bi_add(x,p1); x=bi_add(x,bi_mul_small(p3,3_int64)); x=bi_add(x,bi_mul_small(p7,5_int64))
       x=bi_add_small(x,int(i,int64)); x=save_value(x)
       do g=1,11
          oldx=x
          kind=VISIBLE_GRINDS(g,5)
          x=bi_mul(oldx,oldx)
          x=bi_add(x,bi_mul_small(oldx,int(VISIBLE_GRINDS(g,1),int64)))
          x=bi_add(x,bi_mul_small(p1,int(VISIBLE_GRINDS(g,2),int64)))
          x=bi_add(x,bi_mul_small(p3,int(VISIBLE_GRINDS(g,3),int64)))
          x=bi_add(x,bi_mul_small(p7,int(VISIBLE_GRINDS(g,4),int64)))
          x=bi_add(x,stones(i,kind))
          x=save_value(x)
       end do
       timeline(i)=x
       visible(i)=x
    end do
  end subroutine build_visible_drops

  subroutine bowl_order_from_number(orderNumber,order)
    integer, intent(in) :: orderNumber
    integer, intent(out) :: order(6)
    integer :: rank0,remaining(6),remainingCount,slotsLeft,block,q,pos,i
    integer, parameter :: fact(0:5)=[1,1,2,6,24,120]
    if (orderNumber < 1 .or. orderNumber > 720) error stop 'order number out of range'
    rank0=orderNumber-1
    remaining=[1,2,3,4,5,6]
    remainingCount=6
    do pos=1,6
       slotsLeft=remainingCount
       block=fact(slotsLeft-1)
       q=rank0/block
       rank0=modulo(rank0,block)
       order(pos)=remaining(q+1)
       do i=q+1,remainingCount-1
          remaining(i)=remaining(i+1)
       end do
       remainingCount=remainingCount-1
    end do
  end subroutine bowl_order_from_number

  subroutine bowl_order_from_drop(dropValue,order)
    type(BigInt), intent(in) :: dropValue
    integer, intent(out) :: order(6)
    type(BigInt) :: r
    integer :: n
    r=bi_mod(bi_sub(dropValue,bi_one()),bi_from_int64(720_int64))
    n=int(bi_to_int64(r))+1
    call bowl_order_from_number(n,order)
  end subroutine bowl_order_from_drop

  subroutine initial_bowls(counts,bowls)
    type(WorkCounts), intent(in) :: counts
    type(BigInt), intent(out) :: bowls(6)
    type(BigInt) :: s
    integer :: id
    do id=1,6
       s=counts%action
       s=bi_add(s,bi_mul_small(counts%target,int(id,int64)))
       s=bi_add(s,counts%distance); s=bi_add(s,counts%connection)
       s=bi_add_small(s,int(counts%direction,int64))
       s=bi_add_small(s,int(BOWL_PRIME(id)*BOWL_PRIME(id),int64))
       bowls(id)=save_value(bi_add_small(bi_mul(s,s),int(id,int64)))
    end do
  end subroutine initial_bowls

  subroutine apply_visible_drops_to_bowls(bowls,visible,stones,orderAtDrop46)
    type(BigInt), intent(inout) :: bowls(6)
    type(BigInt), intent(in) :: visible(46),stones(46,5)
    integer, intent(out) :: orderAtDrop46(6)
    type(BigInt) :: old(6),nextBowls(6),pour(6),s
    integer :: i,order(6),position,id,prev,next,kind
    do i=1,46
       call bowl_order_from_drop(visible(i),order)
       old=bowls
       pour=bi_zero()
       pour(1)=save_value(bi_add_small(bi_add(bi_mul(visible(i),visible(i)),bi_mul(stones(i,WHEAT),old(order(1)))),int(3*i,int64)))
       pour(2)=save_value(bi_add_small(bi_add(bi_mul(visible(i),visible(i)),bi_mul(stones(i,BARLEY),old(order(2)))),int(5*i,int64)))
       pour(3)=save_value(bi_add_small(bi_add(bi_mul(visible(i),visible(i)),bi_mul(stones(i,SALT),old(order(3)))),int(7*i,int64)))
       do position=1,6
          id=order(position); prev=order(wrap1(position-1,6)); next=order(wrap1(position+1,6)); kind=BOWL_STIR_STONE_BY_POSITION(position)
          s=old(id)
          s=bi_add(s,bi_mul_small(old(prev),2_int64)); s=bi_add(s,bi_mul_small(old(next),3_int64))
          s=bi_add(s,pour(position)); s=bi_add(s,visible(i)); s=bi_add(s,stones(i,kind))
          nextBowls(id)=save_value(bi_add_small(bi_add(bi_mul(s,s),bi_mul_small(bi_mul(old(prev),old(next)),5_int64)),int(i*position,int64)))
       end do
       bowls=nextBowls
       if (i==46) orderAtDrop46=order
    end do
  end subroutine apply_visible_drops_to_bowls

  subroutine post_stir_12(bowls)
    type(BigInt), intent(inout) :: bowls(6)
    type(BigInt) :: old(6),nextBowls(6),savedBowlSum,s
    integer :: stir,position,id,prev,next,order(6),orderNumber
    do stir=1,12
       old=bowls
       savedBowlSum=bi_zero()
       do id=1,6
          savedBowlSum=bi_add(savedBowlSum,old(id))
       end do
       savedBowlSum=save_value(bi_add_small(savedBowlSum,int(149*stir,int64)))
       orderNumber=int(bi_to_int64(bi_mod(bi_sub(savedBowlSum,bi_one()),bi_from_int64(720_int64))))+1
       call bowl_order_from_number(orderNumber,order)
       do position=1,6
          id=order(position); prev=order(wrap1(position-1,6)); next=order(wrap1(position+1,6))
          s=old(id); s=bi_add(s,bi_mul_small(old(prev),3_int64)); s=bi_add(s,bi_mul_small(old(next),5_int64))
          s=bi_add(s,savedBowlSum); s=bi_add_small(s,int(stir+position*position,int64))
          nextBowls(id)=save_value(bi_add(bi_mul(s,s),bi_mul_small(bi_mul(old(prev),old(next)),7_int64)))
       end do
       bowls=nextBowls
    end do
  end subroutine post_stir_12

  function normative_sauce(calculationDay,targetDay) result(r)
    type(BigInt), intent(in) :: calculationDay,targetDay
    type(SauceResult) :: r
    type(WorkCounts) :: counts
    type(BigInt) :: stones(46,5),hidden(7),visible(46),bowls(6)
    counts=normative_work_counts(calculationDay,targetDay)
    call build_stones(stones)
    call build_hidden_drops(counts,stones,hidden)
    call build_visible_drops(counts,stones,hidden,visible)
    call initial_bowls(counts,bowls)
    call apply_visible_drops_to_bowls(bowls,visible,stones,r%orderAtDrop46)
    call post_stir_12(bowls)
    r%bowls=bowls
  end function normative_sauce

  function ask_bowl(sauceData,queriedBowlId,seal) result(stream)
    type(SauceResult), intent(in) :: sauceData
    integer, intent(in) :: queriedBowlId,seal
    type(AnswerStream) :: stream
    integer :: p,nextId
    type(BigInt) :: t,directionNumber
    p=0
    do nextId=1,6
       if (sauceData%orderAtDrop46(nextId)==queriedBowlId) then
          p=nextId
          exit
       end if
    end do
    if (p==0) error stop 'queried bowl not present in order'
    nextId=sauceData%orderAtDrop46(modulo(p,6)+1)
    t=bi_add_small(sauceData%bowls(queriedBowlId),int(seal+181,int64))
    stream%first=save_value(bi_add_small(bi_add(bi_mul(t,t),bi_mul_small(sauceData%bowls(nextId),179_int64)),int(seal,int64)))
    t=bi_add_small(stream%first,int(seal+194,int64))
    directionNumber=save_value(bi_add(bi_add(bi_mul(t,t),bi_mul_small(stream%first,193_int64)),bi_mul_small(sauceData%bowls(6),197_int64)))
    if (bi_to_int64(bi_mod(directionNumber,bi_from_int64(2_int64)))==1_int64) then
       stream%directionStep=1
    else
       stream%directionStep=-1
    end if
  end function ask_bowl

  function answer_at(stream,k) result(x)
    type(AnswerStream), intent(in) :: stream
    type(BigInt), intent(in) :: k
    type(BigInt) :: x,t
    t=bi_add(stream%first,bi_mul_small(k,int(stream%directionStep,int64)))
    x=bi_add_small(bi_mod(bi_sub(t,bi_one()),normative_M()),1_int64)
  end function answer_at

  function choose_rank(stream,N) result(rank)
    type(AnswerStream), intent(in) :: stream
    type(BigInt), intent(in) :: N
    type(BigInt) :: rank,m,space,limit,q,offset,x,placesBI,wide,weight,digit,one,stepBI
    integer :: places,j
    if (bi_compare(N,bi_one())<0) error stop 'choose_rank requires N >= 1'
    m=normative_M(); one=bi_one()
    if (bi_compare(N,m)<=0) then
       q=bi_floor_div(m,N); limit=bi_mul(q,N); offset=bi_zero()
       do
          x=answer_at(stream,offset)
          if (bi_compare(x,limit)<=0) exit
          offset=bi_add_small(offset,1_int64)
       end do
       rank=bi_add_small(bi_mod(bi_sub(x,one),N),1_int64)
       return
    end if
    places=1; space=m
    do while (bi_compare(space,N)<0)
       places=places+1
       space=bi_mul(space,m)
    end do
    wide=bi_one(); weight=bi_one()
    do j=0,places-1
       placesBI=bi_from_int64(int(j,int64))
       digit=bi_sub(answer_at(stream,placesBI),one)
       wide=bi_add(wide,bi_mul(digit,weight))
       weight=bi_mul(weight,m)
    end do
    q=bi_floor_div(space,N); limit=bi_mul(q,N)
    stepBI=bi_from_int64(int(stream%directionStep,int64))
    do while (bi_compare(wide,limit)>0)
       wide=bi_add_small(bi_mod(bi_add(bi_sub(wide,one),stepBI),space),1_int64)
    end do
    rank=bi_add_small(bi_mod(bi_sub(wide,one),N),1_int64)
  end function choose_rank

  function falling_factorial(n,k) result(r)
    integer, intent(in) :: n,k
    type(BigInt) :: r
    integer :: j
    r=bi_one()
    do j=0,k-1
       r=bi_mul_small(r,int(n-j,int64))
    end do
  end function falling_factorial

  subroutine unrank_distinct_indices(n,k,rank1,out)
    integer, intent(in) :: n,k
    type(BigInt), intent(in) :: rank1
    integer, intent(out) :: out(k)
    integer, allocatable :: remaining(:)
    integer :: position,candidate,remainingCount,i,chosen
    type(BigInt) :: r,block
    if (bi_compare(rank1,bi_one())<0 .or. bi_compare(rank1,falling_factorial(n,k))>0) error stop 'distinct-name rank out of range'
    allocate(remaining(n)); remaining=[(i,i=1,n)]; remainingCount=n; r=rank1
    do position=1,k
       block=falling_factorial(remainingCount-1,k-position)
       chosen=0
       do candidate=1,remainingCount
          if (bi_compare(r,block)>0) then
             r=bi_sub(r,block)
          else
             chosen=candidate
             exit
          end if
       end do
       if (chosen==0) error stop 'distinct-name unrank failed'
       out(position)=remaining(chosen)
       do i=chosen,remainingCount-1
          remaining(i)=remaining(i+1)
       end do
       remainingCount=remainingCount-1
    end do
  end subroutine unrank_distinct_indices

  function count_bounded_compositions(total,slots,lo,hi) result(count)
    integer, intent(in) :: total,slots,lo,hi
    type(BigInt) :: count
    type(BigInt), allocatable :: memo(:,:)
    logical, allocatable :: seen(:,:)
    integer :: maxRem
    maxRem=max(0,total)
    allocate(memo(0:maxRem,0:slots),seen(0:maxRem,0:slots)); seen=.false.
    count=C(total,slots)
  contains
    recursive function C(rem,k) result(v)
      integer, intent(in) :: rem,k
      type(BigInt) :: v
      integer :: x
      if (k==0) then
         if (rem==0) then; v=bi_one(); else; v=bi_zero(); end if
         return
      end if
      if (rem<0 .or. rem<k*lo .or. rem>k*hi) then
         v=bi_zero(); return
      end if
      if (seen(rem,k)) then; v=memo(rem,k); return; end if
      v=bi_zero()
      do x=lo,hi
         v=bi_add(v,C(rem-x,k-1))
      end do
      memo(rem,k)=v; seen(rem,k)=.true.
    end function C
  end function count_bounded_compositions

  subroutine unrank_bounded_composition(total,slots,lo,hi,rank1,out)
    integer, intent(in) :: total,slots,lo,hi
    type(BigInt), intent(in) :: rank1
    integer, intent(out) :: out(slots)
    type(BigInt), allocatable :: memo(:,:)
    logical, allocatable :: seen(:,:)
    type(BigInt) :: r,block,totalCount
    integer :: rem,k,pos,x,maxRem
    maxRem=max(0,total); allocate(memo(0:maxRem,0:slots),seen(0:maxRem,0:slots)); seen=.false.
    totalCount=C(total,slots)
    if (bi_compare(rank1,bi_one())<0 .or. bi_compare(rank1,totalCount)>0) error stop 'bounded composition rank out of range'
    r=rank1; rem=total; k=slots
    do pos=1,slots
       do x=lo,hi
          block=C(rem-x,k-1)
          if (bi_compare(r,block)>0) then
             r=bi_sub(r,block)
          else
             out(pos)=x; rem=rem-x; k=k-1; exit
          end if
       end do
    end do
  contains
    recursive function C(remain,left) result(v)
      integer, intent(in) :: remain,left
      type(BigInt) :: v
      integer :: xx
      if (left==0) then
         if (remain==0) then; v=bi_one(); else; v=bi_zero(); end if
         return
      end if
      if (remain<0 .or. remain<left*lo .or. remain>left*hi) then; v=bi_zero(); return; end if
      if (seen(remain,left)) then; v=memo(remain,left); return; end if
      v=bi_zero()
      do xx=lo,hi
         v=bi_add(v,C(remain-xx,left-1))
      end do
      memo(remain,left)=v; seen(remain,left)=.true.
    end function C
  end subroutine unrank_bounded_composition

  function count_weavings(lengths) result(count)
    integer, intent(in) :: lengths(:)
    type(BigInt) :: count
    type(WeaveMemo) :: memo
    integer, allocatable :: rem(:)
    allocate(memo%entries(0)); rem=lengths
    count=C(rem,0,0)
  contains
    recursive function C(remaining,opened,closed) result(v)
      integer, intent(in) :: remaining(:),opened,closed
      type(BigInt) :: v
      integer :: idx,j,newOpened,newClosed
      integer, allocatable :: next(:)
      if (sum(remaining)==0) then; v=bi_one(); return; end if
      idx=findMemo(memo,remaining,opened,closed)
      if (idx>0) then; v=memo%entries(idx)%count; return; end if
      v=bi_zero()
      do j=1,size(lengths)
         if (.not. legalMove(remaining,opened,closed,j,lengths)) cycle
         next=remaining; newOpened=opened; newClosed=closed
         call applyMove(next,newOpened,newClosed,j,lengths)
         v=bi_add(v,C(next,newOpened,newClosed))
      end do
      call putMemo(memo,remaining,opened,closed,v)
    end function C
  end function count_weavings

  subroutine unrank_weaving(lengths,rank1,out)
    integer, intent(in) :: lengths(:)
    type(BigInt), intent(in) :: rank1
    integer, intent(out) :: out(sum(lengths))
    type(WeaveMemo) :: memo
    integer, allocatable :: remaining(:),next(:)
    integer :: opened,closed,newOpened,newClosed,pos,j,idx
    type(BigInt) :: r,block,totalCount
    allocate(memo%entries(0)); remaining=lengths; opened=0; closed=0
    totalCount=C(remaining,opened,closed)
    if (bi_compare(rank1,bi_one())<0 .or. bi_compare(rank1,totalCount)>0) error stop 'weaving rank out of range'
    r=rank1
    do pos=1,sum(lengths)
       do j=1,size(lengths)
          if (.not. legalMove(remaining,opened,closed,j,lengths)) cycle
          next=remaining; newOpened=opened; newClosed=closed
          call applyMove(next,newOpened,newClosed,j,lengths)
          block=C(next,newOpened,newClosed)
          if (bi_compare(r,block)>0) then
             r=bi_sub(r,block)
          else
             out(pos)=j; remaining=next; opened=newOpened; closed=newClosed; exit
          end if
       end do
    end do
  contains
    recursive function C(rem,op,cl) result(v)
      integer, intent(in) :: rem(:),op,cl
      type(BigInt) :: v
      integer :: q,jj,no,nc
      integer, allocatable :: nxt(:)
      if (sum(rem)==0) then; v=bi_one(); return; end if
      q=findMemo(memo,rem,op,cl)
      if (q>0) then; v=memo%entries(q)%count; return; end if
      v=bi_zero()
      do jj=1,size(lengths)
         if (.not. legalMove(rem,op,cl,jj,lengths)) cycle
         nxt=rem; no=op; nc=cl; call applyMove(nxt,no,nc,jj,lengths)
         v=bi_add(v,C(nxt,no,nc))
      end do
      call putMemo(memo,rem,op,cl,v)
    end function C
  end subroutine unrank_weaving

  logical function legalMove(remaining,opened,closed,j,lengths)
    integer, intent(in) :: remaining(:),opened,closed,j,lengths(:)
    logical :: alreadyOpened,willClose
    legalMove=.false.
    if (remaining(j)==0) return
    alreadyOpened=(remaining(j)<lengths(j))
    if (.not. alreadyOpened .and. j/=opened+1) return
    willClose=(remaining(j)==1)
    if (willClose .and. j/=closed+1) return
    legalMove=.true.
  end function legalMove

  subroutine applyMove(remaining,opened,closed,j,lengths)
    integer, intent(inout) :: remaining(:),opened,closed
    integer, intent(in) :: j,lengths(:)
    if (remaining(j)==lengths(j)) opened=j
    remaining(j)=remaining(j)-1
    if (remaining(j)==0) closed=j
  end subroutine applyMove

  integer function findMemo(memo,remaining,opened,closed)
    type(WeaveMemo), intent(in) :: memo
    integer, intent(in) :: remaining(:),opened,closed
    integer :: i
    findMemo=0
    do i=1,size(memo%entries)
       if (memo%entries(i)%openedUpTo/=opened .or. memo%entries(i)%closedUpTo/=closed) cycle
       if (size(memo%entries(i)%remaining)/=size(remaining)) cycle
       if (all(memo%entries(i)%remaining==remaining)) then; findMemo=i; return; end if
    end do
  end function findMemo

  subroutine putMemo(memo,remaining,opened,closed,count)
    type(WeaveMemo), intent(inout) :: memo
    integer, intent(in) :: remaining(:),opened,closed
    type(BigInt), intent(in) :: count
    type(WeaveMemoEntry), allocatable :: tmp(:)
    integer :: n
    n=size(memo%entries); allocate(tmp(n+1))
    if (n>0) tmp(1:n)=memo%entries
    tmp(n+1)%remaining=remaining; tmp(n+1)%openedUpTo=opened; tmp(n+1)%closedUpTo=closed; tmp(n+1)%count=count
    call move_alloc(tmp,memo%entries)
  end subroutine putMemo

  integer function ceil_div_small(a,b)
    integer, intent(in) :: a,b
    if (a<0 .or. b<1) error stop 'ceil_div_small domain error'
    ceil_div_small=(a+b-1)/b
  end function ceil_div_small

  integer function wrap1(position,size)
    integer, intent(in) :: position,size
    if (size<1) error stop 'wrap1 size must be positive'
    wrap1=modulo(position-1,size)+1
  end function wrap1

end module normative_oracle_core
