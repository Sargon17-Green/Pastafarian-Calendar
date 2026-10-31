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
    total=count_weavings_polynomial(lengths)
    if (bi_compare(rank,total)>0) return

    remaining=lengths
    opened=0; closed=0; offset=rank
    do p=1,size(word)
       chosen=.false.
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
end module stage01_weaving_polynomial_unrank
