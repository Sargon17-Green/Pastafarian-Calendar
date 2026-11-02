! Stage1 non-normative diagnostic: middle and near-last lexicographic ranks.
! Existing stage01_weaving_unrank_probe supplies an independent exhaustive
! small-shape oracle. This larger-shape probe checks structural invariants
! and reports bounded timing only; it does not establish the exact rank.
program stage01_weaving_rank_probe
  use iso_fortran_env, only: int64, output_unit
  use big_integer, only: BigInt, bi_one, bi_from_int64, bi_add_small, &
       bi_floor_div, bi_sub, bi_compare, bi_to_string
  use stage01_weaving_polynomial, only: count_weavings_polynomial
  use stage01_weaving_polynomial_unrank, only: unrank_weaving_polynomial
  implicit none
  integer, parameter :: target(45) = [ &
       115,108,119,109,106,81,115,114,117,120,98,52,81,97,121, &
       97,115,96,107,61,106,115,119,39,84,103,115,107,55,119, &
       97,50,122,110,81,54,101,83,88,40,25,77,98,122,105 ]
  integer, allocatable :: lengths(:), word(:), seen(:)
  integer :: n, stat, i, color, nextOpen, nextClose, checks
  integer(int64) :: startCount, afterCount, afterUnrank, clockRate
  type(BigInt) :: total, rank
  logical :: ok
  character(len=20) :: arg, mode

  call get_command_argument(1,arg,status=stat)
  if (stat/=0 .or. len_trim(arg)==0) error stop 'expected color count'
  read(arg,*,iostat=stat) n
  if (stat/=0) error stop 'invalid color count'
  if (n<2 .or. n>size(target)) error stop 'color count outside 2..45'
  call get_command_argument(2,mode,status=stat)
  if (stat/=0) error stop 'expected rank mode'
  if (trim(mode)/='middle' .and. trim(mode)/='near_last') &
       error stop 'rank mode must be middle or near_last'
  lengths=target(1:n)
  allocate(word(sum(lengths)),seen(n))
  if (n==45 .and. sum(lengths)/=4244) error stop 'target lengths mismatch'
  print '(A,I0,A,I0,A,A)', 'STAGE01_RANK_COLORS=',n, &
       ' DAYS=',size(word),' MODE=',trim(mode)
  print '(A)', 'STAGE01_RANK_PHASE=COUNT_BEGIN'
  flush(output_unit)
  call system_clock(count=startCount,count_rate=clockRate)
  total=count_weavings_polynomial(lengths)
  call system_clock(count=afterCount)
  if (bi_compare(total,bi_one())<=0) error stop 'no nontrivial ranks'
  select case(trim(mode))
  case('middle')
     rank=bi_floor_div(bi_add_small(total,1_int64),bi_from_int64(2_int64))
  case('near_last')
     rank=bi_sub(total,bi_one())
  end select
  print '(A,I0)', 'STAGE01_RANK_TOTAL_DIGITS=',len(bi_to_string(total))
  print '(A,I0)', 'STAGE01_RANK_REQUEST_DIGITS=',len(bi_to_string(rank))
  print '(A,I0)', 'STAGE01_RANK_COUNT_MS=',elapsed_ms(startCount,afterCount,clockRate)
  print '(A)', 'STAGE01_RANK_PHASE=UNRANK_BEGIN'
  flush(output_unit)
  ! Reuse the exact total computed above; the unranker accepts this trusted hint.
  call unrank_weaving_polynomial(lengths,rank,word,ok,total)
  call system_clock(count=afterUnrank)
  print '(A,I0)', 'STAGE01_RANK_UNRANK_MS=',elapsed_ms(afterCount,afterUnrank,clockRate)
  if (.not.ok) error stop 'candidate arbitrary-rank unrank failed'
  seen=0; nextOpen=1; nextClose=1
  do i=1,size(word)
     color=word(i)
     if (color<1 .or. color>n) error stop 'invalid color index'
     if (seen(color)==0) then
        if (color/=nextOpen) error stop 'first appearances unordered'
        nextOpen=nextOpen+1
     end if
     seen(color)=seen(color)+1
     if (seen(color)>lengths(color)) error stop 'color length exceeded'
     if (seen(color)==lengths(color)) then
        if (color/=nextClose) error stop 'last appearances unordered'
        nextClose=nextClose+1
     end if
  end do
  checks=0
  call check(all(seen==lengths))
  call check(nextOpen==n+1)
  call check(nextClose==n+1)
  call check(word(1)==1)
  call check(word(size(word))==n)
  call check(sum(seen)==sum(lengths))
  call check(bi_compare(rank,bi_one())>=0)
  call check(bi_compare(rank,total)<=0)
  print '(A,I0)', 'STAGE01_RANK_ASSERTIONS=',checks
  print '(A)', 'STAGE01_RANK_PASS (structural only; independent small oracle is separate)'
contains
  subroutine check(condition)
    logical, intent(in) :: condition
    if (.not.condition) error stop 'candidate arbitrary-rank invariant failed'
    checks=checks+1
  end subroutine check
  integer(int64) function elapsed_ms(startTick,endTick,rate) result(ms)
    integer(int64), intent(in) :: startTick,endTick,rate
    ms=(endTick-startTick)*1000_int64/max(1_int64,rate)
  end function elapsed_ms
end program stage01_weaving_rank_probe
