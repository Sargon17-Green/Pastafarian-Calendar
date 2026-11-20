program stage01_calculation_context_probe
  use iso_fortran_env, only: int64
  use big_integer, only: BigInt, bi_add_small, bi_to_string
  use normative_oracle_core, only: foundation_day
  use normative_oracle_calendar, only: CalendarDateResult, normative_calendar_date, reset_gate_cache
  implicit none

  integer(int64), parameter :: calculation_offsets(14) = [ &
       -8192_int64, 8192_int64, 137_int64, -1_int64, 0_int64, 1_int64, &
       -2048_int64, 2048_int64, 0_int64, 0_int64, 1_int64, -1_int64, &
       -1_int64, 1_int64 ]
  integer(int64), parameter :: target_offsets(14) = [ &
       -3192_int64, 3192_int64, 137_int64, 0_int64, 0_int64, 0_int64, &
       0_int64, 0_int64, -1_int64, 1_int64, -2032_int64, 2213_int64, &
       -2032_int64, 2213_int64 ]
  type(BigInt) :: foundation, calculation_day, target_day
  type(CalendarDateResult) :: actual
  character(len=16) :: argument
  integer :: case_index, status, step, steps

  steps = command_argument_count()
  if (steps < 1 .or. steps > 8) error stop 'provide 1..8 calculation-context cases'
  foundation = foundation_day()
  ! Reset exactly once: subsequent contexts must reuse the same process state.
  call reset_gate_cache()
  do step = 1, steps
     call get_command_argument(step, argument, status=status)
     if (status /= 0) error stop 'cannot read calculation-context case'
     read(argument, *, iostat=status) case_index
     if (status /= 0) error stop 'invalid calculation-context case'
     if (case_index < 1 .or. case_index > 14) error stop 'calculation-context case out of range'

     calculation_day = bi_add_small(foundation, calculation_offsets(case_index))
     target_day = bi_add_small(foundation, target_offsets(case_index))
     actual = normative_calendar_date(calculation_day, target_day)

     ! The one-case protocol remains byte-for-byte compatible with existing QA.
     if (steps > 1) write(*, '(A,I0)') 'STAGE01_CONTEXT_SEQ_STEP=', step
     write(*, '(A,I0)') 'STAGE01_CONTEXT_CASE=', case_index
     write(*, '(A,A)') 'STAGE01_CONTEXT_CALCULATION_DAY=', trim(bi_to_string(calculation_day))
     write(*, '(A,A)') 'STAGE01_CONTEXT_TARGET_DAY=', trim(bi_to_string(target_day))
     write(*, '(A,A,A,I0,A,I0,A,I0,A,I0)') &
          'STAGE01_CONTEXT_FIELDS=', trim(bi_to_string(actual%yearNumber)), ',', &
          actual%cutletCanonicalIndex, ',', actual%dayInCutlet, ',', &
          actual%monthCanonicalIndex, ',', actual%dayInMonth
  end do
end program stage01_calculation_context_probe
