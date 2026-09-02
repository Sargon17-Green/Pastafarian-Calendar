module big_integer
  use iso_fortran_env, only: int64
  implicit none
  private

  integer(int64), parameter :: BASE = 1000000000_int64

  type, public :: BigInt
     integer :: sign = 0
     integer(int64), allocatable :: limb(:)
  end type BigInt

  public :: bi_zero, bi_one, bi_from_int64, bi_from_string, bi_to_string
  public :: bi_add, bi_sub, bi_mul, bi_mul_small, bi_add_small, bi_neg, bi_abs
  public :: bi_compare, bi_abs_compare, bi_is_zero, bi_is_positive, bi_is_negative
  public :: bi_divmod_euclid, bi_mod, bi_floor_div, bi_to_int64, bi_equal

contains

  function bi_zero() result(z)
    type(BigInt) :: z
    allocate(z%limb(1))
    z%limb = 0_int64
    z%sign = 0
  end function bi_zero

  function bi_one() result(o)
    type(BigInt) :: o
    allocate(o%limb(1))
    o%limb(1) = 1_int64
    o%sign = 1
  end function bi_one

  function bi_from_int64(v) result(x)
    integer(int64), intent(in) :: v
    type(BigInt) :: x
    integer(int64) :: mag, q
    integer :: n, i

    if (v == 0_int64) then
       x = bi_zero()
       return
    end if

    if (v < 0_int64) then
       x%sign = -1
       if (v == -huge(v)-1_int64) then
          ! The bootstrap never needs INT64_MIN as a direct literal conversion.
          error stop 'bi_from_int64 does not accept INT64_MIN'
       end if
       mag = -v
    else
       x%sign = 1
       mag = v
    end if

    q = mag
    n = 0
    do while (q > 0_int64)
       n = n + 1
       q = q / BASE
    end do
    allocate(x%limb(n))
    q = mag
    do i = 1, n
       x%limb(i) = modulo(q, BASE)
       q = q / BASE
    end do
    call normalize(x)
  end function bi_from_int64

  function bi_from_string(text) result(x)
    character(len=*), intent(in) :: text
    type(BigInt) :: x
    integer :: i, first, sgn, digit
    character :: ch

    x = bi_zero()
    first = 1
    sgn = 1
    if (len_trim(text) == 0) error stop 'empty BigInt string'
    if (text(1:1) == '-') then
       sgn = -1
       first = 2
    else if (text(1:1) == '+') then
       first = 2
    end if
    if (first > len_trim(text)) error stop 'invalid BigInt string'

    do i = first, len_trim(text)
       ch = text(i:i)
       if (ch < '0' .or. ch > '9') error stop 'invalid BigInt digit'
       digit = iachar(ch) - iachar('0')
       x = bi_mul_small(x, 10_int64)
       x = bi_add_small(x, int(digit, int64))
    end do
    if (.not. bi_is_zero(x)) x%sign = sgn
    call normalize(x)
  end function bi_from_string

  function bi_to_string(x) result(text)
    type(BigInt), intent(in) :: x
    character(len=:), allocatable :: text
    character(len=32) :: buf
    character(len=9) :: chunk
    integer :: i

    if (bi_is_zero(x)) then
       text = '0'
       return
    end if

    write(buf, '(I0)') x%limb(size(x%limb))
    text = trim(buf)
    do i = size(x%limb)-1, 1, -1
       write(chunk, '(I9.9)') x%limb(i)
       text = text // chunk
    end do
    if (x%sign < 0) text = '-' // text
  end function bi_to_string

  logical function bi_is_zero(x)
    type(BigInt), intent(in) :: x
    bi_is_zero = (x%sign == 0)
  end function bi_is_zero

  logical function bi_is_positive(x)
    type(BigInt), intent(in) :: x
    bi_is_positive = (x%sign > 0)
  end function bi_is_positive

  logical function bi_is_negative(x)
    type(BigInt), intent(in) :: x
    bi_is_negative = (x%sign < 0)
  end function bi_is_negative

  logical function bi_equal(a, b)
    type(BigInt), intent(in) :: a, b
    bi_equal = (bi_compare(a,b) == 0)
  end function bi_equal

  function bi_abs(x) result(y)
    type(BigInt), intent(in) :: x
    type(BigInt) :: y
    y = x
    if (.not. bi_is_zero(y)) y%sign = 1
  end function bi_abs

  function bi_neg(x) result(y)
    type(BigInt), intent(in) :: x
    type(BigInt) :: y
    y = x
    y%sign = -y%sign
  end function bi_neg

  integer function bi_abs_compare(a, b)
    type(BigInt), intent(in) :: a, b
    integer :: i, na, nb

    na = effective_size(a)
    nb = effective_size(b)
    if (na < nb) then
       bi_abs_compare = -1
       return
    else if (na > nb) then
       bi_abs_compare = 1
       return
    end if
    do i = na, 1, -1
       if (a%limb(i) < b%limb(i)) then
          bi_abs_compare = -1
          return
       else if (a%limb(i) > b%limb(i)) then
          bi_abs_compare = 1
          return
       end if
    end do
    bi_abs_compare = 0
  end function bi_abs_compare

  integer function bi_compare(a, b)
    type(BigInt), intent(in) :: a, b
    integer :: c
    if (a%sign < b%sign) then
       bi_compare = -1
       return
    else if (a%sign > b%sign) then
       bi_compare = 1
       return
    end if
    if (a%sign == 0) then
       bi_compare = 0
       return
    end if
    c = bi_abs_compare(a,b)
    if (a%sign < 0) c = -c
    bi_compare = c
  end function bi_compare

  function bi_add(a, b) result(c)
    type(BigInt), intent(in) :: a, b
    type(BigInt) :: c
    integer :: cmp

    if (bi_is_zero(a)) then
       c = b
       return
    else if (bi_is_zero(b)) then
       c = a
       return
    end if

    if (a%sign == b%sign) then
       c = abs_add(a,b)
       c%sign = a%sign
    else
       cmp = bi_abs_compare(a,b)
       if (cmp == 0) then
          c = bi_zero()
       else if (cmp > 0) then
          c = abs_sub(a,b)
          c%sign = a%sign
       else
          c = abs_sub(b,a)
          c%sign = b%sign
       end if
    end if
    call normalize(c)
  end function bi_add

  function bi_sub(a, b) result(c)
    type(BigInt), intent(in) :: a, b
    type(BigInt) :: c
    c = bi_add(a, bi_neg(b))
  end function bi_sub

  function bi_add_small(a, small) result(c)
    type(BigInt), intent(in) :: a
    integer(int64), intent(in) :: small
    type(BigInt) :: c
    c = bi_add(a, bi_from_int64(small))
  end function bi_add_small

  function bi_mul_small(a, small) result(c)
    type(BigInt), intent(in) :: a
    integer(int64), intent(in) :: small
    type(BigInt) :: c
    integer(int64) :: m, carry, t
    integer :: i, n
    integer :: sgn

    if (small == 0_int64 .or. bi_is_zero(a)) then
       c = bi_zero()
       return
    end if
    if (small < 0_int64) then
       m = -small
       sgn = -a%sign
    else
       m = small
       sgn = a%sign
    end if
    n = size(a%limb)
    allocate(c%limb(n+1))
    c%limb = 0_int64
    carry = 0_int64
    do i = 1, n
       t = a%limb(i) * m + carry
       c%limb(i) = modulo(t, BASE)
       carry = t / BASE
    end do
    c%limb(n+1) = carry
    c%sign = sgn
    call normalize(c)
  end function bi_mul_small

  function bi_mul(a, b) result(c)
    type(BigInt), intent(in) :: a, b
    type(BigInt) :: c
    integer :: i, j, na, nb
    integer(int64) :: t, carry

    if (bi_is_zero(a) .or. bi_is_zero(b)) then
       c = bi_zero()
       return
    end if
    na = size(a%limb)
    nb = size(b%limb)
    allocate(c%limb(na+nb))
    c%limb = 0_int64
    do i = 1, na
       carry = 0_int64
       do j = 1, nb
          t = c%limb(i+j-1) + a%limb(i) * b%limb(j) + carry
          c%limb(i+j-1) = modulo(t, BASE)
          carry = t / BASE
       end do
       c%limb(i+nb) = c%limb(i+nb) + carry
    end do
    c%sign = a%sign * b%sign
    call normalize(c)
  end function bi_mul

  subroutine bi_divmod_euclid(a, b, q, r)
    type(BigInt), intent(in) :: a, b
    type(BigInt), intent(out) :: q, r
    type(BigInt) :: qa, ra, aa, bb

    if (bi_is_zero(b) .or. b%sign < 0) error stop 'divisor must be positive'
    aa = bi_abs(a)
    bb = b
    call abs_divmod(aa, bb, qa, ra)

    if (a%sign >= 0) then
       q = qa
       r = ra
    else if (bi_is_zero(ra)) then
       q = bi_neg(qa)
       r = ra
    else
       q = bi_neg(bi_add_small(qa, 1_int64))
       r = bi_sub(bb, ra)
    end if
    call normalize(q)
    call normalize(r)
  end subroutine bi_divmod_euclid

  function bi_floor_div(a, b) result(q)
    type(BigInt), intent(in) :: a, b
    type(BigInt) :: q, r
    call bi_divmod_euclid(a,b,q,r)
  end function bi_floor_div

  function bi_mod(a, b) result(r)
    type(BigInt), intent(in) :: a, b
    type(BigInt) :: q, r
    call bi_divmod_euclid(a,b,q,r)
  end function bi_mod

  function bi_to_int64(x) result(v)
    type(BigInt), intent(in) :: x
    integer(int64) :: v
    integer :: i
    integer(int64) :: limit

    v = 0_int64
    limit = huge(v)
    do i = size(x%limb), 1, -1
       if (v > (limit - x%limb(i)) / BASE) error stop 'BigInt does not fit int64'
       v = v * BASE + x%limb(i)
    end do
    if (x%sign < 0) v = -v
  end function bi_to_int64

  function abs_add(a, b) result(c)
    type(BigInt), intent(in) :: a, b
    type(BigInt) :: c
    integer :: n, i
    integer(int64) :: av, bv, t, carry

    n = max(size(a%limb), size(b%limb))
    allocate(c%limb(n+1))
    c%limb = 0_int64
    carry = 0_int64
    do i = 1, n
       av = 0_int64
       bv = 0_int64
       if (i <= size(a%limb)) av = a%limb(i)
       if (i <= size(b%limb)) bv = b%limb(i)
       t = av + bv + carry
       c%limb(i) = modulo(t, BASE)
       carry = t / BASE
    end do
    c%limb(n+1) = carry
    c%sign = 1
    call normalize(c)
  end function abs_add

  function abs_sub(a, b) result(c)
    type(BigInt), intent(in) :: a, b
    type(BigInt) :: c
    integer :: n, i
    integer(int64) :: av, bv, t, borrow

    if (bi_abs_compare(a,b) < 0) error stop 'abs_sub requires |a| >= |b|'
    n = size(a%limb)
    allocate(c%limb(n))
    c%limb = 0_int64
    borrow = 0_int64
    do i = 1, n
       av = a%limb(i)
       bv = 0_int64
       if (i <= size(b%limb)) bv = b%limb(i)
       t = av - bv - borrow
       if (t < 0_int64) then
          t = t + BASE
          borrow = 1_int64
       else
          borrow = 0_int64
       end if
       c%limb(i) = t
    end do
    c%sign = 1
    call normalize(c)
  end function abs_sub

  subroutine abs_divmod(a, b, q, r)
    type(BigInt), intent(in) :: a, b
    type(BigInt), intent(out) :: q, r
    integer :: i
    integer(int64) :: lo, hi, mid, best
    type(BigInt) :: trial

    if (b%sign <= 0) error stop 'abs_divmod requires positive divisor'
    if (a%sign < 0) error stop 'abs_divmod requires nonnegative dividend'
    if (bi_abs_compare(a,b) < 0) then
       q = bi_zero()
       r = a
       return
    end if

    allocate(q%limb(size(a%limb)))
    q%limb = 0_int64
    q%sign = 1
    r = bi_zero()

    do i = size(a%limb), 1, -1
       r = bi_mul_small(r, BASE)
       r = bi_add_small(r, a%limb(i))

       lo = 0_int64
       hi = BASE - 1_int64
       best = 0_int64
       do while (lo <= hi)
          mid = lo + (hi-lo)/2_int64
          trial = bi_mul_small(b, mid)
          if (bi_abs_compare(trial, r) <= 0) then
             best = mid
             lo = mid + 1_int64
          else
             hi = mid - 1_int64
          end if
       end do
       q%limb(i) = best
       if (best /= 0_int64) r = bi_sub(r, bi_mul_small(b,best))
    end do
    call normalize(q)
    call normalize(r)
  end subroutine abs_divmod

  integer function effective_size(x)
    type(BigInt), intent(in) :: x
    integer :: i
    if (.not. allocated(x%limb)) then
       effective_size = 0
       return
    end if
    i = size(x%limb)
    do while (i > 1 .and. x%limb(i) == 0_int64)
       i = i - 1
    end do
    effective_size = i
  end function effective_size

  subroutine normalize(x)
    type(BigInt), intent(inout) :: x
    integer :: n
    integer(int64), allocatable :: tmp(:)

    if (.not. allocated(x%limb)) then
       allocate(x%limb(1))
       x%limb = 0_int64
       x%sign = 0
       return
    end if
    n = effective_size(x)
    if (n < size(x%limb)) then
       allocate(tmp(n))
       tmp = x%limb(1:n)
       call move_alloc(tmp, x%limb)
    end if
    if (size(x%limb) == 1 .and. x%limb(1) == 0_int64) then
       x%sign = 0
    else if (x%sign == 0) then
       x%sign = 1
    end if
  end subroutine normalize

end module big_integer
