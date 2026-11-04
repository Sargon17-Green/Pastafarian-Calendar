! Independent multiset-word enumeration, not a call to the DP recurrence.
! For every length vector with 1..4 colors and multiplicities 1..3,
! enumerate lexicographically, reject first/last-order violations and compare
! each accepted word with its exact normative unrank (both call signatures).
program stage01_normative_unrank_diff_probe
  use iso_fortran_env, only: int64
  use big_integer, only: BigInt, bi_from_int64, bi_to_int64
  use normative_oracle_core, only: count_weavings, unrank_weaving
  implicit none
  integer, allocatable :: lengths(:),remaining(:),word(:),actual(:)
  type(BigInt) :: totalCount
  integer :: colors,shape,code,j,places,accepted,cases,assertions,failures

  cases=0
  assertions=0
  failures=0
  do colors=1,4
     do shape=0,3**colors-1
        allocate(lengths(colors))
        code=shape
        do j=1,colors
           lengths(j)=mod(code,3)+1
           code=code/3
        end do
        places=sum(lengths)
        allocate(remaining(colors),word(places),actual(places))
        remaining=lengths
        totalCount=count_weavings(lengths)
        accepted=0
        call enumerate(1)
        cases=cases+1
        assertions=assertions+1
        if (bi_to_int64(totalCount)/=int(accepted,int64)) failures=failures+1
        deallocate(lengths,remaining,word,actual)
     end do
  end do
  write(*,'(A,I0)') 'STAGE01_NORMATIVE_UNRANK_DIFF_CASES=',cases
  write(*,'(A,I0)') 'STAGE01_NORMATIVE_UNRANK_DIFF_ASSERTIONS=',assertions
  write(*,'(A,I0)') 'STAGE01_NORMATIVE_UNRANK_DIFF_FAILURES=',failures
  if (cases/=120 .or. assertions/=4060 .or. failures/=0) error stop 1
  write(*,'(A)') 'STAGE01_NORMATIVE_UNRANK_DIFF_PASS (independent exhaustive words; NOT full Stage1)'
contains
  recursive subroutine enumerate(position)
    integer, intent(in) :: position
    integer :: c
    if (position>places) then
       if (.not.valid_word()) return
       accepted=accepted+1
       if (mod(accepted,2)==0) then
          call unrank_weaving(lengths,bi_from_int64(int(accepted,int64)),actual,totalCount)
       else
          call unrank_weaving(lengths,bi_from_int64(int(accepted,int64)),actual)
       end if
       assertions=assertions+1
       if (any(actual/=word)) failures=failures+1
       return
    end if
    do c=1,colors
       if (remaining(c)==0) cycle
       remaining(c)=remaining(c)-1
       word(position)=c
       call enumerate(position+1)
       remaining(c)=remaining(c)+1
    end do
  end subroutine enumerate

  logical function valid_word()
    integer :: seen(colors),nextOpen,nextClose,p,c
    valid_word=.false.
    seen=0; nextOpen=1; nextClose=1
    do p=1,places
       c=word(p)
       if (seen(c)==0) then
          if (c/=nextOpen) return
          nextOpen=nextOpen+1
       end if
       seen(c)=seen(c)+1
       if (seen(c)==lengths(c)) then
          if (c/=nextClose) return
          nextClose=nextClose+1
       end if
    end do
    valid_word=(nextOpen==colors+1 .and. nextClose==colors+1)
  end function valid_word
end program stage01_normative_unrank_diff_probe
