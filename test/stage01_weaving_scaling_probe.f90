! Stage1 candidate-only bounded scaling probe on the actual year-5000 month lengths.
! It does NOT invoke normative_calendar_date or validate full date integration.
program stage01_weaving_scaling_probe
  use iso_fortran_env, only: int64, output_unit
  use big_integer, only: BigInt, bi_one, bi_to_string
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
  type(BigInt) :: count
  logical :: ok
  character(len=20) :: arg

  call get_command_argument(1,arg,status=stat)
  if (stat/=0 .or. len_trim(arg)==0) error stop 'expected prefix color count 1..45'
  read(arg,*,iostat=stat) n
  if (stat/=0) error stop 'invalid prefix color count'
  if (n<1 .or. n>size(target)) error stop 'prefix color count outside 1..45'
  lengths=target(1:n)
  allocate(word(sum(lengths)),seen(n))
  if (n==45 .and. sum(lengths)/=4244) error stop 'target month lengths mismatch'
  print '(A,I0,A,I0)', 'STAGE01_SCALING_COLORS=',n,' DAYS=',size(word)
  print '(A)', 'STAGE01_SCALING_PHASE=COUNT_BEGIN'
  flush(output_unit)
  call system_clock(count=startCount,count_rate=clockRate)
  count=count_weavings_polynomial(lengths)
  call system_clock(count=afterCount)
  print '(A,I0)', 'STAGE01_SCALING_COUNT_DIGITS=',len(bi_to_string(count))
  print '(A,I0)', 'STAGE01_SCALING_COUNT_MS=',elapsed_ms(startCount,afterCount,clockRate)
  print '(A)', 'STAGE01_SCALING_PHASE=UNRANK_BEGIN'
  flush(output_unit)
  call unrank_weaving_polynomial(lengths,bi_one(),word,ok)
  call system_clock(count=afterUnrank)
  print '(A,I0)', 'STAGE01_SCALING_UNRANK_MS=',elapsed_ms(afterCount,afterUnrank,clockRate)
  if (.not. ok) error stop 'candidate rank-one unrank failed'
  seen=0; nextOpen=1; nextClose=1
  do i=1,size(word)
     color=word(i)
     if (color<1 .or. color>n) error stop 'invalid month index'
     if (seen(color)==0) then
        if (color/=nextOpen) error stop 'first appearances unordered'
        nextOpen=nextOpen+1
     end if
     seen(color)=seen(color)+1
     if (seen(color)>lengths(color)) error stop 'month length exceeded'
     if (seen(color)==lengths(color)) then
        if (color/=nextClose) error stop 'last appearances unordered'
        nextClose=nextClose+1
     end if
  end do
  checks=0
  call check(all(seen==lengths)); call check(nextOpen==n+1)
  call check(nextClose==n+1); call check(word(1)==1)
  call check(word(size(word))==n); call check(size(word)==sum(lengths))
  print '(A,I0)', 'STAGE01_SCALING_ASSERTIONS=',checks
  print '(A)', 'STAGE01_SCALING_PASS (candidate-only rank one; NOT normative integration)'
contains
  subroutine check(condition)
    logical, intent(in) :: condition
    if (.not. condition) error stop 'candidate rank-one invariant failed'
    checks=checks+1
  end subroutine check

  integer(int64) function elapsed_ms(startTick,endTick,rate) result(ms)
    integer(int64), intent(in) :: startTick,endTick,rate
    ms=(endTick-startTick)*1000_int64/max(1_int64,rate)
  end function elapsed_ms
end program stage01_weaving_scaling_probe
