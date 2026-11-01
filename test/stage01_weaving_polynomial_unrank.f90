! Stage 1 non-normative candidate: lexicographic unranking using exact
! polynomial prefix completion counts. No calendar-date integration here.
module stage01_weaving_polynomial_unrank
  use big_integer, only: BigInt, bi_one, bi_compare, bi_sub
  use stage01_weaving_polynomial, only: count_weavings_polynomial, count_prefix_weavings_polynomial
  implicit none
  private
  public :: unrank_weaving_polynomial
contains
  subroutine unrank_weaving_polynomial(lengths, rank, word, ok)
    integer, intent(in) :: lengths(:)
    type(BigInt), intent(in) :: rank
    integer, intent(out) :: word(:)
    logical, intent(out) :: ok
    integer, allocatable :: remaining(:)
    type(BigInt) :: total, offset, completions
    integer :: p, color, opened, closed, new_opened, new_closed
    logical :: chosen

    word=0
    ok=.false.
    if (size(lengths)<1 .or. size(lengths)>47) return
    if (any(lengths<1) .or. any(lengths>123)) return
    if (sum(lengths)>5778) return
    if (size(word)/=sum(lengths)) return
    if (bi_compare(rank,bi_one())<0) return
    ! A sorted block word (all 1s, then all 2s, etc.) always obeys
    ! ordered first and last appearances, so rank one is valid for
    ! every validated nonempty shape. Avoid an expensive total count.
    if (bi_compare(rank,bi_one())==0) then
       p=0
       do color=1,size(lengths)
          word(p+1:p+lengths(color))=color
          p=p+lengths(color)
       end do
       ok=.true.
       return
    end if
    total=count_weavings_polynomial(lengths)
    if (bi_compare(rank,total)>0) return

    ! The penultimate legal word is the lexicographic predecessor of
    ! the maximal word. Local legality implies completion is possible:
    ! close already-open colors in order, then open/close the rest.
    ! This avoids thousands of expensive prefix-count calls for rank C-1.
    if (bi_compare(rank,bi_sub(total,bi_one()))==0) then
       call unrank_penultimate(lengths,word,ok)
       return
    end if
    remaining=lengths
    opened=0; closed=0; offset=rank
    do p=1,size(word)
       chosen=.false.
       ! Any locally legal next symbol has a legal completion: finish
       ! already-open colors in closing order, then open/finish the rest.
       ! Once the residual rank is one, the smallest legal symbol is
       ! therefore the lexicographically first completion. This fast
       ! suffix is valid for arbitrary initial ranks, not just rank one.
       if (bi_compare(offset,bi_one())==0) then
          do color=1,size(lengths)
             if (remaining(color)==0) cycle
             if (remaining(color)==lengths(color) .and. color/=opened+1) cycle
             if (remaining(color)==1 .and. color/=closed+1) cycle
             if (remaining(color)==lengths(color)) opened=color
             if (remaining(color)==1) closed=color
             remaining(color)=remaining(color)-1
             word(p)=color
             chosen=.true.
             exit
          end do
          if (.not. chosen) then
             word=0
             return
          end if
          cycle
       end if
       do color=1,size(lengths)
          if (remaining(color)==0) cycle
          if (remaining(color)==lengths(color) .and. color/=opened+1) cycle
          if (remaining(color)==1 .and. color/=closed+1) cycle
          new_opened=opened
          new_closed=closed
          if (remaining(color)==lengths(color)) new_opened=color
          if (remaining(color)==1) new_closed=color
          remaining(color)=remaining(color)-1
          completions=count_prefix_weavings_polynomial(lengths,remaining,new_opened,new_closed)
          if (bi_compare(offset,completions)>0) then
             offset=bi_sub(offset,completions)
             remaining(color)=remaining(color)+1
          else
             word(p)=color
             opened=new_opened
             closed=new_closed
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
