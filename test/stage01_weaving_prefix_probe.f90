! Candidate-only independent prefix oracle, not normative Stage1 acceptance.
program stage01_weaving_prefix_probe
  use iso_fortran_env, only: int64
  use big_integer, only: BigInt, bi_to_int64
  use stage01_weaving_polynomial, only: count_prefix_weavings_polynomial, &
       PrefixCompletionCache, prepare_prefix_completion_cache
  implicit none
  integer, allocatable :: lengths(:),remaining(:)
  integer :: n,code,tmp,j,nCases,nAssertions,nFailures,nCacheAssertions,nCacheFailures
  type(PrefixCompletionCache) :: cache
  integer(int64) :: count
  nCases=0; nAssertions=0; nFailures=0; nCacheAssertions=0; nCacheFailures=0
  do n=1,4
     do code=0,3**n-1
        allocate(lengths(n),remaining(n))
        tmp=code
        do j=1,n
           lengths(j)=modulo(tmp,3)+1
           tmp=tmp/3
        end do
        if (sum(lengths)>9) then
           deallocate(lengths,remaining)
           cycle
        end if
        remaining=lengths
        call prepare_prefix_completion_cache(lengths,cache)
        nCases=nCases+1
        count=explore(0,0)
        deallocate(lengths,remaining)
     end do
  end do
  print '(A,I0)', 'STAGE01_POLY_PREFIX_CASES=',nCases
  print '(A,I0)', 'STAGE01_POLY_PREFIX_ASSERTIONS=',nAssertions
  print '(A,I0)', 'STAGE01_POLY_PREFIX_FAILURES=',nFailures
  print '(A,I0)', 'STAGE01_POLY_CACHE_ASSERTIONS=',nCacheAssertions
  print '(A,I0)', 'STAGE01_POLY_CACHE_FAILURES=',nCacheFailures
  if (nCases/=105 .or. nAssertions/=3455 .or. nFailures/=0) error stop 1
  if (nCacheAssertions/=3455 .or. nCacheFailures/=0) error stop 1
  print '(A)', 'STAGE01_POLY_PREFIX_PASS (exhaustive independent recursion; NOT Stage1 acceptance)'
contains
  recursive function explore(opened,closed) result(completions)
    integer, intent(in) :: opened,closed
    integer(int64) :: completions,child
    integer :: color,newOpened,newClosed
    type(BigInt) :: candidate, cached_candidate
    if (sum(remaining)==0) then
       completions=1_int64
    else
       completions=0_int64
       do color=1,n
          if (remaining(color)==0) cycle
          if (remaining(color)==lengths(color) .and. color/=opened+1) cycle
          if (remaining(color)==1 .and. color/=closed+1) cycle
          newOpened=opened; newClosed=closed
          if (remaining(color)==lengths(color)) newOpened=color
          if (remaining(color)==1) newClosed=color
          remaining(color)=remaining(color)-1
          child=explore(newOpened,newClosed)
          remaining(color)=remaining(color)+1
          completions=completions+child
       end do
    end if
    candidate=count_prefix_weavings_polynomial(lengths,remaining,opened,closed)
    cached_candidate=count_prefix_weavings_polynomial(lengths,remaining,opened,closed,cache)
    nCacheAssertions=nCacheAssertions+1
    if (bi_to_int64(cached_candidate)/=completions) then
       nCacheFailures=nCacheFailures+1
       print '(A,*(I0,1X))', 'FAIL cached prefix lengths=',lengths
       print '(A,*(I0,1X))', 'remaining=',remaining
    end if
    nAssertions=nAssertions+1
    if (bi_to_int64(candidate)/=completions) then
       nFailures=nFailures+1
       print '(A,*(I0,1X))', 'FAIL prefix completion lengths=',lengths
       print '(A,*(I0,1X))', 'remaining=',remaining
       print '(A,2(I0,1X),A,I0)', 'opened/closed=',opened,closed,' expected=',completions
    end if
  end function explore
end program stage01_weaving_prefix_probe
