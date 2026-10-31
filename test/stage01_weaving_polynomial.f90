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
  integer(int64), parameter :: LIMB_BASE=1000000000_int64
  public :: count_weavings_polynomial, weaving_first_positions
contains
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
