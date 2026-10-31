! Independently enumerate all multiset words, then filter first/last order.
! The enumerator does not call the polynomial prefix-count recurrence.
program stage01_weaving_unrank_probe
  use iso_fortran_env, only: int64
  use big_integer, only: BigInt, bi_from_int64, bi_to_int64, bi_add_small
  use stage01_weaving_polynomial, only: count_weavings_polynomial
  use stage01_weaving_polynomial_unrank, only: unrank_weaving_polynomial
  implicit none
  integer, allocatable :: lengths(:), remaining(:), word(:), expected(:,:), actual(:)
  integer :: n, code, tmp, j, k, total, accepted, cases, ranks, assertions, failures
  type(BigInt) :: count
  logical :: ok
  cases=0; ranks=0; assertions=0; failures=0
  do n=1,4
     do code=0,3**n-1
        allocate(lengths(n))
        tmp=code
        do j=1,n
           lengths(j)=modulo(tmp,3)+1
           tmp=tmp/3
        end do
        total=sum(lengths)
        if (total>9) then
           deallocate(lengths)
           cycle
        end if
        allocate(remaining(n),word(total),actual(total),expected(total,1000))
        remaining=lengths; accepted=0
        call enumerate(1)
        cases=cases+1
        count=count_weavings_polynomial(lengths)
        call check(bi_to_int64(count)==int(accepted,int64),'count vs independent enumeration')
        do k=1,accepted
           call unrank_weaving_polynomial(lengths,bi_from_int64(int(k,int64)),actual,ok)
           call check(ok .and. all(actual==expected(:,k)),'lexicographic rank vs independent enumeration')
           ranks=ranks+1
        end do
        call unrank_weaving_polynomial(lengths,bi_from_int64(0_int64),actual,ok)
        call check(.not.ok .and. all(actual==0),'rank zero rejected')
        call unrank_weaving_polynomial(lengths,bi_from_int64(-1_int64),actual,ok)
        call check(.not.ok .and. all(actual==0),'negative rank rejected')
        call unrank_weaving_polynomial(lengths,bi_add_small(count,1_int64),actual,ok)
        call check(.not.ok .and. all(actual==0),'rank count plus one rejected')
        deallocate(lengths,remaining,word,actual,expected)
     end do
  end do
  print '(A,I0)', 'STAGE01_POLY_UNRANK_CASES=',cases
  print '(A,I0)', 'STAGE01_POLY_UNRANK_RANKS=',ranks
  print '(A,I0)', 'STAGE01_POLY_UNRANK_ASSERTIONS=',assertions
  print '(A,I0)', 'STAGE01_POLY_UNRANK_FAILURES=',failures
  if (cases/=105 .or. ranks/=698 .or. assertions/=1118 .or. failures/=0) error stop 1
  print '(A)', 'STAGE01_POLY_UNRANK_PASS (independent enumeration; NOT Stage1 acceptance)'
contains
  recursive subroutine enumerate(position)
    integer, intent(in) :: position
    integer :: color
    if (position>total) then
       if (.not. valid_word()) return
       accepted=accepted+1
       if (accepted>size(expected,2)) error stop 'oracle capacity exceeded'
       expected(:,accepted)=word
       return
    end if
    do color=1,n
       if (remaining(color)==0) cycle
       remaining(color)=remaining(color)-1
       word(position)=color
       call enumerate(position+1)
       remaining(color)=remaining(color)+1
    end do
  end subroutine enumerate

  logical function valid_word()
    integer :: seen(n),next_open,next_close,p,color
    valid_word=.false.; seen=0; next_open=1; next_close=1
    do p=1,total
       color=word(p)
       if (seen(color)==0) then
          if (color/=next_open) return
          next_open=next_open+1
       end if
       seen(color)=seen(color)+1
       if (seen(color)==lengths(color)) then
          if (color/=next_close) return
          next_close=next_close+1
       end if
    end do
    valid_word=(next_open==n+1 .and. next_close==n+1)
  end function valid_word

  subroutine check(correct,description)
    logical, intent(in) :: correct
    character(len=*), intent(in) :: description
    assertions=assertions+1
    if (correct) return
    failures=failures+1
    if (failures<=10) print '(A)', 'FAIL: '//description
  end subroutine check
end program stage01_weaving_unrank_probe
