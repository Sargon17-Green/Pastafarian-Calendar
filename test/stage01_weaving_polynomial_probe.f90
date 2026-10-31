! Stage1 candidate-only: independent multiset enumeration and legacy differential.
! Do not interpret this as first-day integration or unrank acceptance.
program stage01_weaving_polynomial_probe
  use iso_fortran_env, only: int64
  use big_integer, only: BigInt, bi_equal, bi_to_int64, bi_to_string
  use normative_oracle_core, only: count_weavings
  use stage01_weaving_polynomial, only: count_weavings_polynomial, weaving_first_positions
  implicit none
  integer, allocatable :: lens(:),remaining(:),word(:)
  integer(int64), allocatable :: enumerated(:)
  integer :: n,code,tmp,j,nCases,nAssertions,nFailures,total
  integer(int64) :: completeWords
  type(BigInt) :: candidate,legacy
  type(BigInt), allocatable :: firstPositions(:)
  character(len=16) :: mode
  integer :: outfile
  integer, parameter :: target(45)=[ &
       115,108,119,109,106,81,115,114,117,120,98,52,81,97,121, &
       97,115,96,107,61,106,115,119,39,84,103,115,107,55,119, &
       97,50,122,110,81,54,101,83,88,40,25,77,98,122,105 ]
  call get_command_argument(1,mode)
  if (trim(mode)=='target') then
     candidate=count_weavings_polynomial(target)
     if (sum(target)/=4244) error stop 'target shape sum mismatch'
     if (len(bi_to_string(candidate))/=6765) error stop 'target decimal digit count mismatch'
     open(newunit=outfile,file='build/stage01_weaving_candidate_count.txt',status='replace',action='write')
     write(outfile,'(A)') bi_to_string(candidate)
     close(outfile)
     print '(A,I0)', 'STAGE01_POLY_TARGET_DIGITS=',len(bi_to_string(candidate))
     print '(A)', 'STAGE01_POLY_TARGET_CANDIDATE_WRITTEN (not normative, hash checked by CI)'
     stop
  end if
  if (trim(mode)/='small') error stop 'expected small or target'
  nCases=0; nAssertions=0; nFailures=0
  do n=1,4
     do code=0,3**n-1
        allocate(lens(n))
        tmp=code
        do j=1,n
           lens(j)=modulo(tmp,3)+1
           tmp=tmp/3
        end do
        total=sum(lens)
        if (total>9) then
           deallocate(lens)
           cycle
        end if
        allocate(remaining(n),word(total),enumerated(total))
        remaining=lens; enumerated=0_int64; completeWords=0_int64
        call enumerate(1)
        candidate=count_weavings_polynomial(lens)
        legacy=count_weavings(lens)
        firstPositions=weaving_first_positions(lens)
        nCases=nCases+1
        call check(bi_to_int64(candidate)==completeWords,'candidate vs independent count')
        call check(bi_equal(candidate,legacy),'candidate vs legacy memo count')
        do j=1,total
           call check(bi_to_int64(firstPositions(j))==enumerated(j),'first occurrence distribution')
        end do
        deallocate(lens,remaining,word,enumerated,firstPositions)
     end do
  end do
  print '(A,I0)', 'STAGE01_POLY_SMALL_CASES=',nCases
  print '(A,I0)', 'STAGE01_POLY_SMALL_ASSERTIONS=',nAssertions
  print '(A,I0)', 'STAGE01_POLY_SMALL_FAILURES=',nFailures
  if (nCases/=105 .or. nAssertions/=906 .or. nFailures/=0) error stop 1
  print '(A)', 'STAGE01_POLY_SMALL_PASS (independent enumeration + legacy; NOT Stage1 acceptance)'
contains
  recursive subroutine enumerate(position)
    integer, intent(in) :: position
    integer :: color
    if (position>total) then
       if (.not. valid_word()) return
       completeWords=completeWords+1_int64
       do color=1,total
          if (word(color)==size(lens)) then
             enumerated(color)=enumerated(color)+1_int64
             exit
          end if
       end do
       return
    end if
    do color=1,size(lens)
       if (remaining(color)<1) cycle
       word(position)=color
       remaining(color)=remaining(color)-1
       call enumerate(position+1)
       remaining(color)=remaining(color)+1
    end do
  end subroutine enumerate

  logical function valid_word()
    integer :: p,color,nextOpen,nextClose
    integer :: observed(size(lens))
    valid_word=.false.
    observed=0; nextOpen=1; nextClose=1
    do p=1,total
       color=word(p)
       if (observed(color)==0) then
          if (color/=nextOpen) return
          nextOpen=nextOpen+1
       end if
       observed(color)=observed(color)+1
       if (observed(color)==lens(color)) then
          if (color/=nextClose) return
          nextClose=nextClose+1
       end if
    end do
    valid_word=(nextOpen==size(lens)+1 .and. nextClose==size(lens)+1)
  end function valid_word

  subroutine check(ok,label)
    logical,intent(in) :: ok
    character(len=*),intent(in) :: label
    nAssertions=nAssertions+1
    if (ok) return
    nFailures=nFailures+1
    print '(A,*(I0,1X))', 'FAIL '//label//' lengths=',lens
  end subroutine check
end program stage01_weaving_polynomial_probe
