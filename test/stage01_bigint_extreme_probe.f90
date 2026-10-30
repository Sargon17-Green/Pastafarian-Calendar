! Isolated, bounded Stage 1 BigInt diagnostics; no full calendar oracle.
! Each mode is a separate process; nonzero exit is not a passing test.
program stage01_bigint_extreme_probe
  use iso_fortran_env, only: int64
  use big_integer
  implicit none
  character(len=48) :: mode
  integer(int64) :: minimum, observed
  type(BigInt) :: a, actual, expected
  if (command_argument_count() /= 1) then
     write(*,'(A)') 'ERROR: exactly one probe mode is required'
     error stop 2
  end if
  call get_command_argument(1, mode)
  minimum = -huge(0_int64) - 1_int64
  select case (trim(mode))
  case ('from-int64-min')
     actual = bi_from_int64(minimum)
     call check(bi_to_string(actual) == '-9223372036854775808', trim(mode))
  case ('to-int64-min')
     observed = bi_to_int64(bi_from_string('-9223372036854775808'))
     call check(observed == minimum, trim(mode))
  case ('multiply-int64-max')
     a = bi_from_string('2')
     actual = bi_mul_small(a, huge(0_int64))
     expected = bi_mul(a, bi_from_int64(huge(0_int64)))
     call check(bi_equal(actual, expected) .and. &
          bi_to_string(actual) == '18446744073709551614', trim(mode))
  case ('multiply-wide-limb')
     a = bi_from_string('999999999')
     actual = bi_mul_small(a, 10000000000_int64)
     expected = bi_mul(a, bi_from_string('10000000000'))
     call check(bi_equal(actual, expected) .and. &
          bi_to_string(actual) == '9999999990000000000', trim(mode))
  case ('multiply-int64-min')
     a = bi_from_string('2')
     actual = bi_mul_small(a, minimum)
     expected = bi_mul(a, bi_from_int64(minimum))
     call check(bi_equal(actual, expected) .and. &
          bi_to_string(actual) == '-18446744073709551616', trim(mode))
  case ('multiply-wide-negative')
     a = bi_from_string('-1000000001')
     actual = bi_mul_small(a, 10000000000_int64)
     expected = bi_mul(a, bi_from_string('10000000000'))
     call check(bi_equal(actual, expected) .and. &
          bi_to_string(actual) == '-10000000010000000000', trim(mode))
  case ('to-int64-overflow-positive')
     ! The isolated process must terminate with the specific range error.
     observed = bi_to_int64(bi_from_string('9223372036854775808'))
     write(*,'(A,I0)') 'UNEXPECTED_RETURN=', observed
  case ('to-int64-overflow-negative')
     observed = bi_to_int64(bi_from_string('-9223372036854775809'))
     write(*,'(A,I0)') 'UNEXPECTED_RETURN=', observed
  case default
     write(*,'(A)') 'ERROR: unknown probe mode '//trim(mode)
     error stop 2
  end select
contains
  subroutine check(ok, name)
    logical, intent(in) :: ok
    character(len=*), intent(in) :: name
    if (.not. ok) then
       write(*,'(A)') 'PROBE_RESULT=FAIL MODE='//name
       error stop 1
    end if
    write(*,'(A)') 'PROBE_RESULT=PASS MODE='//name
  end subroutine check
end program stage01_bigint_extreme_probe
