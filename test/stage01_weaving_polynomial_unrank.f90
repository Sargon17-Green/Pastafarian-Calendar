! Stage 1 non-normative candidate: lexicographic unranking using exact
! polynomial prefix completion counts. No calendar-date integration here.
module stage01_weaving_polynomial_unrank
  use iso_fortran_env, only: int64
  use big_integer, only: BigInt, bi_one, bi_compare, bi_sub, bi_mul_small
  use stage01_weaving_polynomial, only: count_weavings_polynomial, count_prefix_weavings_polynomial, &
       PrefixCompletionCache, prepare_prefix_completion_cache
  implicit none
  private
  integer(int64), parameter :: LIMB_BASE=1000000000_int64
  public :: unrank_weaving_polynomial
contains
  subroutine unrank_weaving_polynomial(lengths, rank, word, ok, total_hint)
    integer, intent(in) :: lengths(:)
    type(BigInt), intent(in) :: rank
    integer, intent(out) :: word(:)
    logical, intent(out) :: ok
    ! Optional exact total already computed for these same lengths.
    ! Supplying it avoids repeating the expensive full count in diagnostics.
    type(BigInt), intent(in), optional :: total_hint
    integer, allocatable :: remaining(:)
    type(BigInt) :: total, offset, state_total, leftover, completions
    type(PrefixCompletionCache) :: cache
    integer :: p, color, opened, closed, new_opened, new_closed
    integer :: first_legal, last_legal
    logical :: chosen

    word=0
    ok=.false.
    if (size(lengths)<1 .or. size(lengths)>47) return
    if (any(lengths<1) .or. any(lengths>123)) return
    if (sum(lengths)>5778) return
    if (size(word)/=sum(lengths)) return
    if (bi_compare(rank,bi_one())<0) return
    ! The lexicographically first word is always sorted blocks.
    if (bi_compare(rank,bi_one())==0) then
       p=0
       do color=1,size(lengths)
          word(p+1:p+lengths(color))=color
          p=p+lengths(color)
       end do
       ok=.true.
       return
    end if
    if (present(total_hint)) then
       total=total_hint
    else
       total=count_weavings_polynomial(lengths)
    end if
    if (bi_compare(total,bi_one())<0) return
    if (bi_compare(rank,total)>0) return

    ! Independently proven C-1 shortcut; retained from prior candidate.
    if (bi_compare(rank,bi_sub(total,bi_one()))==0) then
       call unrank_penultimate(lengths,word,ok)
       return
    end if

    call prepare_prefix_completion_cache(lengths,cache)
    if (bi_compare(count_prefix_weavings_polynomial(lengths,lengths,0,0,cache),total)/=0) &
         error stop 'prefix cache does not match independent total'
    remaining=lengths
    opened=0; closed=0; offset=rank; state_total=total
    do p=1,size(word)
       ! Every locally legal symbol permits at least one full completion.
       ! Thus rank 1 and the current maximum rank have constructive
       ! lexicographically minimal/maximal suffixes, without any DP calls.
       if (bi_compare(offset,bi_one())==0) then
          call complete_lexical_suffix(lengths,remaining,opened,closed,word,p,.false.,ok)
          return
       end if
       if (bi_compare(offset,state_total)==0) then
          call complete_lexical_suffix(lengths,remaining,opened,closed,word,p,.true.,ok)
          return
       end if
       ! Once all colors have appeared, only ordered final occurrences remain.
       ! Maintain a single exact suffix product and update it by small ratios.
       if (opened==size(lengths)) then
          call unrank_closure_only_suffix(lengths,remaining,closed,word,p,offset,state_total,ok)
          return
       end if

       first_legal=0; last_legal=0
       do color=1,size(lengths)
          if (.not. legal_next(lengths,remaining,opened,closed,color)) cycle
          if (first_legal==0) first_legal=color
          last_legal=color
       end do
       if (first_legal==0) then
          word=0
          return
       end if
       ! A forced transition preserves the number of suffix completions.
       if (first_legal==last_legal) then
          word(p)=first_legal
          call consume_next(lengths,remaining,opened,closed,first_legal)
          cycle
       end if

       ! State partition invariant: sum of all legal child completions
       ! equals state_total. Never recalculate the last child's count.
       leftover=state_total
       chosen=.false.
       do color=first_legal,last_legal
          if (.not. legal_next(lengths,remaining,opened,closed,color)) cycle
          if (color==last_legal) then
             completions=leftover
          else
             new_opened=opened; new_closed=closed
             if (remaining(color)==lengths(color)) new_opened=color
             if (remaining(color)==1) new_closed=color
             remaining(color)=remaining(color)-1
             completions=count_prefix_weavings_polynomial( &
                  lengths,remaining,new_opened,new_closed,cache)
             remaining(color)=remaining(color)+1
          end if
          if (bi_compare(offset,completions)>0) then
             offset=bi_sub(offset,completions)
             leftover=bi_sub(leftover,completions)
          else
             word(p)=color
             call consume_next(lengths,remaining,opened,closed,color)
             state_total=completions
             chosen=.true.
             exit
          end if
       end do
       if (.not. chosen) then
          word=0
          return
       end if
    end do
    ok=(all(remaining==0) .and. bi_compare(offset,bi_one())==0)
    if (.not. ok) word=0
  end subroutine unrank_weaving_polynomial

  ! Fast lexicographic unranking after every color has appeared.
  !
  ! For active colors first..n, let S_j=sum(remaining(first:j)) and
  ! F_j=C(S_j-1,r_j-1). The current total is product(F_j). Define
  ! B_c=total*product_{j=c+1..n}(S_{j-1}/(S_j-1)).
  ! B_first is obtained by replacing F_j with
  ! G_j=C(S_j-2,r_j-1), from right to left. Then the child count for
  ! choosing c>first is B_{c-1}*(r_c-1)/S_{c-1}, and
  ! B_c=B_{c-1}*(S_c-1)/S_{c-1}. Every division is exact by the
  ! binomial identities. This computes all child blocks in O(n) small
  ! BigInt multiply/divides, without rebuilding a DP or multiplying
  ! large BigInts together at every position.
  subroutine unrank_closure_only_suffix(lengths,remaining,closed,word,start,rank,total,ok)
    integer, intent(in) :: lengths(:),start
    integer, intent(inout) :: remaining(:),closed
    integer, intent(inout) :: word(:)
    type(BigInt), intent(inout) :: rank,total
    logical, intent(out) :: ok
    type(BigInt) :: b,child
    integer, allocatable :: cumulative(:)
    integer :: n,first,j,c,p,old_first_remaining,opened
    logical :: chosen

    n=size(lengths)
    opened=n
    allocate(cumulative(n))
    ok=.false.
    do p=start,size(word)
       if (bi_compare(rank,bi_one())==0) then
          call complete_lexical_suffix(lengths,remaining,opened,closed,word,p,.false.,ok)
          return
       end if
       if (bi_compare(rank,total)==0) then
          call complete_lexical_suffix(lengths,remaining,opened,closed,word,p,.true.,ok)
          return
       end if
       if (bi_compare(rank,bi_one())<0 .or. bi_compare(rank,total)>0) then
          word=0
          return
       end if

       first=closed+1
       if (first>n) exit
       cumulative(first)=remaining(first)
       do j=first+1,n
          if (remaining(j)<1) then
             word=0
             return
          end if
          cumulative(j)=cumulative(j-1)+remaining(j)
       end do

       ! B_first = total * product_{j>first} S_(j-1)/(S_j-1).
       ! Descending order keeps each exact binomial denominator available.
       b=total
       do j=n,first+1,-1
          b=multiply_divide_small(b,cumulative(j-1),cumulative(j)-1)
       end do

       chosen=.false.
       do c=first,n
          if (c==first) then
             child=b
          else
             ! A non-first color with one remaining occurrence cannot close yet.
             ! Its skipped block is zero and B_c=B_(c-1), since S_c-1=S_(c-1).
             if (remaining(c)<=1) cycle
             child=multiply_divide_small(b,remaining(c)-1,cumulative(c-1))
          end if

          if (bi_compare(rank,child)>0) then
             rank=bi_sub(rank,child)
             if (c>first) then
                b=multiply_divide_small(b,cumulative(c)-1,cumulative(c-1))
             end if
          else
             old_first_remaining=remaining(c)
             word(p)=c
             remaining(c)=remaining(c)-1
             if (c==first .and. old_first_remaining==1) closed=first
             total=child
             chosen=.true.
             exit
          end if
       end do
       if (.not.chosen) then
          word=0
          return
       end if
    end do
    ok=all(remaining==0) .and. bi_compare(rank,bi_one())==0
    if (.not.ok) word=0
  end subroutine unrank_closure_only_suffix

  function multiply_divide_small(a,numerator,denominator) result(q)
    type(BigInt), intent(in) :: a
    integer, intent(in) :: numerator,denominator
    type(BigInt) :: q
    if (numerator<1 .or. denominator<1) error stop 'closure unrank: invalid ratio'
    q=divide_exact_small(bi_mul_small(a,int(numerator,int64)),denominator)
  end function multiply_divide_small

  ! Exact nonnegative base-1e9 division; all closure ratios are integral
  ! by Pascal's binomial identities.
  function divide_exact_small(a,d) result(q)
    type(BigInt), intent(in) :: a
    integer, intent(in) :: d
    type(BigInt) :: q
    integer(int64) :: carry,value
    integer(int64), allocatable :: shortened(:)
    integer :: j,sz,top
    if (d<=0 .or. a%sign<=0) error stop 'closure unrank: invalid exact division'
    sz=size(a%limb)
    allocate(q%limb(sz))
    carry=0_int64
    do j=sz,1,-1
       value=carry*LIMB_BASE+a%limb(j)
       q%limb(j)=value/int(d,int64)
       carry=modulo(value,int(d,int64))
    end do
    if (carry/=0_int64) error stop 'closure unrank: non-exact binomial ratio'
    top=sz
    do while (top>1)
       if (q%limb(top)/=0_int64) exit
       top=top-1
    end do
    if (top<sz) then
       allocate(shortened(top))
       shortened=q%limb(1:top)
       call move_alloc(shortened,q%limb)
    end if
    q%sign=1
  end function divide_exact_small

  ! Construct an extreme suffix directly, for ANY input rank whose
  ! residual rank is 1 or the exact remaining state total.
  subroutine complete_lexical_suffix(lengths,remaining,opened,closed,word,start,largest,ok)
    integer, intent(in) :: lengths(:), start
    integer, intent(inout) :: remaining(:), opened, closed, word(:)
    logical, intent(in) :: largest
    logical, intent(out) :: ok
    integer :: p, i, color, n
    logical :: chosen

    n=size(lengths)
    ok=.false.
    do p=start,size(word)
       chosen=.false.
       do i=1,n
          color=i
          if (largest) color=n+1-i
          if (.not. legal_next(lengths,remaining,opened,closed,color)) cycle
          word(p)=color
          call consume_next(lengths,remaining,opened,closed,color)
          chosen=.true.
          exit
       end do
       if (.not. chosen) then
          word=0
          return
       end if
    end do
    ok=all(remaining==0)
    if (.not. ok) word=0
  end subroutine complete_lexical_suffix

  ! Construct the greatest legal complete word greedily, recording each
  ! prefix state. Its immediate predecessor is obtained by changing the
  ! rightmost position with a smaller locally legal symbol, selecting the
  ! greatest such symbol, and greedily maximizing the remaining suffix.
  ! Independent exhaustive enumeration: 105 shapes, 65 nontrivial, 698
  ! legal words; no mismatches (not a substitute for production Native).
  subroutine unrank_penultimate(lengths,word,ok)
    integer, intent(in) :: lengths(:)
    integer, intent(out) :: word(:)
    logical, intent(out) :: ok
    integer, allocatable :: remaining(:), maximum(:), history(:,:)
    integer, allocatable :: opened_before(:), closed_before(:)
    integer :: n,positions,p,pivot,color,tail_color,opened,closed
    logical :: chosen

    n=size(lengths); positions=sum(lengths)
    allocate(remaining(n),maximum(positions),history(n,positions), &
         opened_before(positions),closed_before(positions))
    remaining=lengths; opened=0; closed=0
    word=0; ok=.false.
    do p=1,positions
       history(:,p)=remaining
       opened_before(p)=opened
       closed_before(p)=closed
       chosen=.false.
       do color=n,1,-1
          if (.not. legal_next(lengths,remaining,opened,closed,color)) cycle
          maximum(p)=color
          call consume_next(lengths,remaining,opened,closed,color)
          chosen=.true.
          exit
       end do
       if (.not. chosen) return
    end do

    do pivot=positions,1,-1
       remaining=history(:,pivot)
       opened=opened_before(pivot); closed=closed_before(pivot)
       do color=maximum(pivot)-1,1,-1
          if (.not. legal_next(lengths,remaining,opened,closed,color)) cycle
          if (pivot>1) word(1:pivot-1)=maximum(1:pivot-1)
          word(pivot)=color
          call consume_next(lengths,remaining,opened,closed,color)
          do p=pivot+1,positions
             chosen=.false.
             do tail_color=n,1,-1
                if (.not. legal_next(lengths,remaining,opened,closed,tail_color)) cycle
                word(p)=tail_color
                call consume_next(lengths,remaining,opened,closed,tail_color)
                chosen=.true.
                exit
             end do
             if (.not. chosen) then
                word=0
                return
             end if
          end do
          ok=all(remaining==0)
          if (.not. ok) word=0
          return
       end do
    end do
  end subroutine unrank_penultimate

  logical function legal_next(lengths,remaining,opened,closed,color) result(legal)
    integer, intent(in) :: lengths(:),remaining(:),opened,closed,color
    legal=.false.
    if (remaining(color)==0) return
    if (remaining(color)==lengths(color) .and. color/=opened+1) return
    if (remaining(color)==1 .and. color/=closed+1) return
    legal=.true.
  end function legal_next

  subroutine consume_next(lengths,remaining,opened,closed,color)
    integer, intent(in) :: lengths(:),color
    integer, intent(inout) :: remaining(:),opened,closed
    if (remaining(color)==lengths(color)) opened=color
    if (remaining(color)==1) closed=color
    remaining(color)=remaining(color)-1
  end subroutine consume_next
end module stage01_weaving_polynomial_unrank
