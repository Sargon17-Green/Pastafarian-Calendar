! Non-normative Stage 1 candidate for complete first/last ordered weavings.
! The normative memoized counting/unranking functions are not changed.
!
! Proof sketch: remove every occurrence of the largest color from a legal
! weaving. The remaining word is legal. Its last color (i-1) finishes at
! the end. If its first occurrence is at p, the first new color can be
! inserted after k old letters with k>=p, and the new color must also occur
! in the final gap. For n>=2 occurrences, the remaining n-1 copies are
! distributed among gaps k..N, with the final gap nonempty:
! W(N,n,k)=C(N-k+n-2,n-2). For n=1 the only valid insertion is last.
! This decomposition is reversible, hence the distribution recurrence.
module stage01_weaving_polynomial
  use iso_fortran_env, only: int64
  use big_integer, only: BigInt, bi_zero, bi_one, bi_add, bi_mul, bi_mul_small
  implicit none
  private
  type :: PrefixCompletionRow
    type(BigInt), allocatable :: value(:)
  end type PrefixCompletionRow
  type, public :: PrefixCompletionCache
    private
    integer, allocatable :: source_lengths(:)
    type(PrefixCompletionRow), allocatable :: rows(:)
  end type PrefixCompletionCache
  integer(int64), parameter :: LIMB_BASE=1000000000_int64
  public :: count_weavings_polynomial, weaving_first_positions, count_prefix_weavings_polynomial
  public :: prepare_prefix_completion_cache
contains
  ! Independent-factor cache for lexicographic unranking. For each stage s
  ! and each old-word remainder R, rows(s)%value(R) counts ways to add all
  ! not-yet-opened colors s..n around ONE fixed old legal suffix of length R.
  ! This depends only on (s,R), not on the detailed old color ordering.
  !
  ! Let k=lengths(s). If R=0, the next symbol must be s, giving
  ! F_s(0)=F_(s+1)(k-1). For R>0, either the next symbol is old, or
  ! it is s. In the latter case the last s must follow the last old
  ! symbol; its other k-2 copies have C(R+k-2,k-2) legal interleavings.
  ! Hence F_s(R)=F_s(R-1)+C(R+k-2,k-2)*F_(s+1)(R+k-1)
  ! when k>1; the second term is 0 for k=1.
  ! Base case F_(n+1)(R)=1. Exact counts, no floating-point arithmetic.
  subroutine prepare_prefix_completion_cache(lengths,cache)
    integer, intent(in) :: lengths(:)
    type(PrefixCompletionCache), intent(inout) :: cache
    type(BigInt) :: weight
    integer :: n,s,k,r,limit
    n=size(lengths)
    if (n<1 .or. n>47) error stop 'prefix cache: invalid number of colors'
    if (any(lengths<1) .or. any(lengths>123) .or. sum(lengths)>5778) &
         error stop 'prefix cache: invalid lengths'
    if (allocated(cache%rows)) deallocate(cache%rows)
    if (allocated(cache%source_lengths)) deallocate(cache%source_lengths)
    cache%source_lengths=lengths
    allocate(cache%rows(n+1))
    allocate(cache%rows(n+1)%value(0:sum(lengths)))
    cache%rows(n+1)%value=bi_one()
    limit=sum(lengths)
    do s=n,1,-1
       k=lengths(s)
       limit=limit-k
       allocate(cache%rows(s)%value(0:limit))
       cache%rows(s)%value(0)=cache%rows(s+1)%value(k-1)
       weight=bi_one()
       do r=1,limit
          if (k==1) then
             cache%rows(s)%value(r)=cache%rows(s)%value(r-1)
          else
             weight=divide_exact_small(bi_mul_small(weight,int(r+k-2,int64)),r)
             cache%rows(s)%value(r)=bi_add(cache%rows(s)%value(r-1), &
                  bi_mul(weight,cache%rows(s+1)%value(r+k-1)))
          end if
       end do
    end do
  end subroutine prepare_prefix_completion_cache

  function count_weavings_polynomial(lengths) result(total)
    integer, intent(in) :: lengths(:)
    type(BigInt) :: total
    type(BigInt), allocatable :: positions(:)
    integer :: k
    positions=weaving_first_positions(lengths)
    total=bi_zero()
    do k=1,size(positions)
       total=bi_add(total,positions(k))
    end do
  end function count_weavings_polynomial

  ! positions(p): number of legal complete words whose final color first
  ! occurs in position p (positions are 1-based in the NEW word).
  function weaving_first_positions(lengths) result(positions)
    integer, intent(in) :: lengths(:)
    type(BigInt), allocatable :: positions(:),next(:)
    type(BigInt) :: running,ways
    integer :: m,n,k,oldTotal
    if (size(lengths)<1 .or. size(lengths)>47) error stop 'weaving candidate: invalid color count'
    if (any(lengths<1) .or. any(lengths>123)) error stop 'weaving candidate: invalid color length'
    if (sum(lengths)>5778) error stop 'weaving candidate: too many positions'
    oldTotal=lengths(1)
    allocate(positions(oldTotal)); positions=bi_zero()
    positions(1)=bi_one()
    do m=2,size(lengths)
       n=lengths(m)
       allocate(next(oldTotal+n)); next=bi_zero()
       if (n==1) then
          ! The sole occurrence is both first and last: it must be at the end.
          running=bi_zero()
          do k=1,oldTotal
             running=bi_add(running,positions(k))
          end do
          next(oldTotal+1)=running
       else
          running=bi_zero()
          ways=bi_one()  ! C(oldTotal-oldTotal+n-2,n-2)=1.
          ! Walk backwards to update binomial weights exactly with small division.
          ! Prefix sums are evaluated in a separate forward sweep.
          block
            type(BigInt), allocatable :: weights(:)
            allocate(weights(oldTotal))
            weights(oldTotal)=ways
            do k=oldTotal-1,1,-1
               ways=divide_exact_small( &
                    bi_mul_small(ways,int(oldTotal-k+n-2,int64)),oldTotal-k)
               weights(k)=ways
            end do
            do k=1,oldTotal
               running=bi_add(running,positions(k))
               next(k+1)=bi_mul(running,weights(k))
            end do
          end block
       end if
       call move_alloc(next,positions)
       oldTotal=oldTotal+n
    end do
  end function weaving_first_positions


  ! Independent candidate-only completion count for a valid legal prefix.
  ! Opened colors may begin at any suffix position; as-yet-unopened colors
  ! must open in ascending order. All remaining colors close in order.
  function count_prefix_weavings_polynomial(lengths,remaining,opened,closed,cache) result(total)
    integer, intent(in) :: lengths(:),remaining(:),opened,closed
    type(PrefixCompletionCache), intent(in), optional :: cache
    type(BigInt) :: total,running,ways
    type(BigInt), allocatable :: positions(:),next(:),weights(:)
    integer :: m,n,k,oldTotal
    if (size(lengths)<1 .or. size(lengths)>47 .or. size(remaining)/=size(lengths)) &
         error stop 'prefix candidate: invalid color count'
    if (any(lengths<1) .or. any(lengths>123) .or. sum(lengths)>5778) &
         error stop 'prefix candidate: invalid lengths'
    if (closed<0 .or. opened<closed .or. opened>size(lengths)) &
         error stop 'prefix candidate: invalid opened/closed indices'
    if (any(remaining<0) .or. any(remaining>lengths)) &
         error stop 'prefix candidate: invalid remaining counts'
    if (any(remaining(1:closed)/=0)) error stop 'prefix candidate: closed colors not exhausted'
    if (any(remaining(closed+1:opened)<1)) error stop 'prefix candidate: opened color exhausted'
    if (any(remaining(opened+1:)/=lengths(opened+1:))) &
         error stop 'prefix candidate: unopened color already consumed'
    if (present(cache)) then
       if (.not.allocated(cache%source_lengths)) error stop 'prefix cache not prepared'
       if (size(cache%source_lengths)/=size(lengths)) error stop 'prefix cache size mismatch'
       if (any(cache%source_lengths/=lengths)) error stop 'prefix cache lengths mismatch'
       oldTotal=sum(remaining(closed+1:opened))
       if (oldTotal>size(cache%rows(opened+1)%value)-1) error stop 'prefix cache bound exceeded'
       total=bi_one()
       if (opened>closed) total=count_closure_only_suffix(remaining(1:opened),closed)
       total=bi_mul(total,cache%rows(opened+1)%value(oldTotal))
       return
    end if
    ! Once every color has already appeared, only the relative order of
    ! their FINAL occurrences is constrained. For active colors with
    ! remaining lengths r_1,...,r_q, the exact number of suffix words is
    ! product_{j=2..q} C((r_1+...+r_j)-1,r_j-1).
    ! Insert each subsequent color into the previous legal word, reserving
    ! the final position for the latest color. This eliminates the
    ! first-position distribution DP on all-open prefix states.
    if (opened==size(lengths)) then
       total=count_closure_only_suffix(remaining,closed)
       return
    end if
    ! The already-open active colors have no first-appearance constraint
    ! left. Count their legal suffixes directly by the exact closure-only
    ! product; their first-position distributions are not needed.
    ! The first unopened color starts the distribution afresh, using only
    ! this base total. Subsequent unopened colors retain the same DP.
    oldTotal=sum(remaining(closed+1:opened))
    total=bi_one()
    if (opened>closed) total=count_closure_only_suffix(remaining(1:opened),closed)
    allocate(positions(0))
    do m=opened+1,size(lengths)
       n=remaining(m)
       allocate(next(oldTotal+n)); next=bi_zero()
       if (n==1) then
          next(oldTotal+1)=total
       else
          allocate(weights(0:oldTotal))
          ways=bi_one()
          weights(oldTotal)=ways
          do k=oldTotal-1,0,-1
             ways=divide_exact_small( &
                  bi_mul_small(ways,int(oldTotal-k+n-2,int64)),oldTotal-k)
             weights(k)=ways
          end do
          running=bi_zero()
          do k=0,oldTotal
             if (m<=opened+1) then
                running=total
             else if (k>0) then
                running=bi_add(running,positions(k))
             end if
             next(k+1)=bi_mul(running,weights(k))
          end do
          deallocate(weights)
       end if
       call move_alloc(next,positions)
       oldTotal=oldTotal+n
       total=bi_zero()
       do k=1,size(positions)
          total=bi_add(total,positions(k))
       end do
    end do
  end function count_prefix_weavings_polynomial

  ! Independent closed-form branch: all colors have opened; close order
  ! remains ascending. Each insertion has C(oldTotal+n-1,n-1) choices.
  ! Exact binomials are built as C(oldTotal+k,k), so every division is exact.
  function count_closure_only_suffix(remaining,closed) result(total)
    integer, intent(in) :: remaining(:),closed
    type(BigInt) :: total,choose
    integer :: m,n,k,oldTotal
    total=bi_one()
    oldTotal=0
    do m=closed+1,size(remaining)
       n=remaining(m)
       if (n<=0) error stop 'closure-only candidate: invalid active length'
       if (oldTotal>0 .and. n>1) then
          choose=bi_one()
          do k=1,n-1
             choose=divide_exact_small( &
                  bi_mul_small(choose,int(oldTotal+k,int64)),k)
          end do
          total=bi_mul(total,choose)
       end if
       oldTotal=oldTotal+n
    end do
  end function count_closure_only_suffix

  ! Exact long division in base 10^9 (nonnegative, positive integral result).
  ! Here all dividends are binomial recurrence numerators and have no remainder.
  function divide_exact_small(a,d) result(q)
    type(BigInt), intent(in) :: a
    integer, intent(in) :: d
    type(BigInt) :: q
    integer(int64) :: carry,value
    integer(int64), allocatable :: shortened(:)
    integer :: j,sz,top
    if (d<=0 .or. a%sign<=0) error stop 'weaving candidate: invalid exact division'
    sz=size(a%limb)
    allocate(q%limb(sz))
    carry=0_int64
    do j=sz,1,-1
       value=carry*LIMB_BASE+a%limb(j)
       q%limb(j)=value/int(d,int64)
       carry=modulo(value,int(d,int64))
    end do
    if (carry/=0_int64) error stop 'weaving candidate: non-exact binomial recurrence'
    top=sz
    do while (top>1)
       if (q%limb(top)/=0_int64) exit
       top=top-1
    end do
    if (top<sz) then
       allocate(shortened(top)); shortened=q%limb(1:top)
       call move_alloc(shortened,q%limb)
    end if
    q%sign=1
  end function divide_exact_small
end module stage01_weaving_polynomial
