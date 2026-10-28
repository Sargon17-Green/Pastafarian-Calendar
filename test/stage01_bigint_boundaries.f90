! This diagnostic covers the bounded, supported Stage 1 BigInt domain only.
! It does not validate the known unintegrated INT64_MIN or full-width
! small-multiplier fixes; a green result is NOT full Stage 1 acceptance.
program stage01_bigint_boundaries
  use iso_fortran_env, only: int64
  use big_integer
  implicit none

  integer :: failures, checks, k
  type(BigInt) :: a, b, q, r, scaled, product, restored

  failures = 0
  checks = 0
  call expect_text(bi_from_string('-0000000000000000'), '0', 'negative zero normalization')
  call expect_text(bi_from_string('+000123456789000'), '123456789000', 'positive leading zero normalization')
  call expect_text(bi_from_string('-000123456789000'), '-123456789000', 'negative leading zero normalization')
  call expect_text(bi_add(bi_from_string('999999999'), bi_one()), '1000000000', 'base limb carry')
  call expect_text(bi_sub(bi_from_string('1000000000'), bi_one()), '999999999', 'base limb borrow')
  call expect_text(bi_mul_small(bi_from_string('999999999'), 999999999_int64), &
       '999999998000000001', 'maximum safe limb-by-limb multiplication')
  call expect_text(bi_mul_small(bi_from_string('1000000000'), -999999999_int64), &
       '-999999999000000000', 'negative small multiplication')
  call expect_text(bi_mul(bi_from_string('1000000000'), bi_from_string('1000000000')), &
       '1000000000000000000', 'base squared')
  call expect(bi_to_int64(bi_from_string('9223372036854775807')) == huge(0_int64), &
       'positive int64 maximum conversion')
  call expect(bi_to_int64(bi_from_string('-9223372036854775807')) == -huge(0_int64), &
       'negative safe int64 conversion')

  a = bi_from_string('123456789012345678901234567890123456789')
  b = bi_from_string('123456789123456789')
  do k = -50, 50
     scaled = bi_mul_small(a, int(k, int64))
     product = bi_mul(a, bi_from_int64(int(k, int64)))
     call expect(bi_equal(scaled, product), 'small/full multiplication agreement')
     call bi_divmod_euclid(scaled, b, q, r)
     restored = bi_add(bi_mul(q, b), r)
     call expect(bi_equal(restored, scaled), 'Euclidean quotient identity')
     call expect(bi_compare(r, bi_zero()) >= 0 .and. bi_compare(r, b) < 0, &
          'Euclidean remainder bounds')
  end do

  write(*,'(A,I0,A,I0)') 'BIGINT_SAFE_BOUNDARY_CHECKS=', checks, ' FAILURES=', failures
  if (failures /= 0) error stop 1
  write(*,'(A)') 'BIGINT_SAFE_BOUNDARY_PASS (NOT FULL STAGE01 PASS)'

contains

  subroutine expect(condition, label)
    logical, intent(in) :: condition
    character(len=*), intent(in) :: label
    checks = checks + 1
    if (.not. condition) then
       failures = failures + 1
       write(*,'(A)') 'FAIL: '//label
    end if
  end subroutine expect

  subroutine expect_text(value, expected, label)
    type(BigInt), intent(in) :: value
    character(len=*), intent(in) :: expected, label
    call expect(bi_to_string(value) == expected, label)
  end subroutine expect_text

end program stage01_bigint_boundaries
