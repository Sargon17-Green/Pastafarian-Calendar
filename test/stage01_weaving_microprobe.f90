! Independent exhaustive oracle for small weaving instances.
! This probes count and lexical unranking only, not full Stage 1 acceptance.
program stage01_weaving_microprobe
  use iso_fortran_env, only: int64
  use big_integer, only: BigInt, bi_to_int64, bi_from_int64
  use normative_oracle_core, only: count_weavings, unrank_weaving
  implicit none
  integer, allocatable :: lengths(:), remaining(:), word(:), expected(:,:), actual(:)
  integer :: total, monthCount, acceptedCount, assertions, failures, caseNumber
  assertions=0; failures=0; caseNumber=0
  call check_case([1])
  call check_case([2,2])
  call check_case([3,2,1])
  call check_case([2,2,2])
  call check_case([2,3,2])
  call check_case([2,2,2,2])
  write(*,'(A,I0)') 'STAGE01_WEAVING_MICRO_ASSERTIONS=',assertions
  write(*,'(A,I0)') 'STAGE01_WEAVING_MICRO_FAILURES=',failures
  if (assertions/=24 .or. failures/=0) error stop 1
  write(*,'(A)') 'STAGE01_WEAVING_MICRO_PASS (six exhaustive small fixtures; NOT full Stage 1 acceptance)'
contains
  subroutine check_case(values)
    integer, intent(in) :: values(:)
    type(BigInt) :: count
    integer :: samples(3),i
    character(len=80) :: label
    caseNumber=caseNumber+1
    lengths=values; total=sum(lengths); monthCount=size(lengths)
    allocate(remaining(monthCount),word(total),expected(total,10000),actual(total))
    remaining=lengths; acceptedCount=0
    call enumerate(1)
    if (acceptedCount==0) error stop 'weaving oracle produced no candidates'
    count=count_weavings(lengths)
    write(label,'("fixture ",I0," count")') caseNumber
    call check(bi_to_int64(count)==int(acceptedCount,int64),trim(label))
    samples=[1,max(1,(acceptedCount+1)/2),acceptedCount]
    do i=1,3
       call unrank_weaving(lengths,bi_from_int64(int(samples(i),int64)),actual)
       write(label,'("fixture ",I0," rank ",I0)') caseNumber,samples(i)
       call check(all(actual==expected(:,samples(i))),trim(label))
    end do
    deallocate(remaining,word,expected,actual,lengths)
  end subroutine check_case

  recursive subroutine enumerate(position)
    integer, intent(in) :: position
    integer :: j
    if (position>total) then
       if (valid_word()) then
          if (acceptedCount==size(expected,2)) error stop 'fixture oracle capacity exceeded'
          acceptedCount=acceptedCount+1
          expected(:,acceptedCount)=word
       end if
       return
    end if
    do j=1,monthCount
       if (remaining(j)==0) cycle
       remaining(j)=remaining(j)-1
       word(position)=j
       call enumerate(position+1)
       remaining(j)=remaining(j)+1
    end do
  end subroutine enumerate

  logical function valid_word()
    integer :: occurred(monthCount),nextOpen,nextClose,p,j
    valid_word=.false.; occurred=0; nextOpen=1; nextClose=1
    do p=1,total
       j=word(p)
       if (occurred(j)==0) then
          if (j/=nextOpen) return
          nextOpen=nextOpen+1
       end if
       occurred(j)=occurred(j)+1
       if (occurred(j)==lengths(j)) then
          if (j/=nextClose) return
          nextClose=nextClose+1
       end if
    end do
    valid_word=(nextOpen==monthCount+1 .and. nextClose==monthCount+1)
  end function valid_word

  subroutine check(ok,label)
    logical, intent(in) :: ok
    character(len=*), intent(in) :: label
    assertions=assertions+1
    if (ok) then
       write(*,'(A)') 'PASS: '//label
    else
       failures=failures+1
       write(*,'(A)') 'FAIL: '//label
    end if
  end subroutine check
end program stage01_weaving_microprobe
