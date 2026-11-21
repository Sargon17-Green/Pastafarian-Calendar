program stage01_boundary_neighbor_probe
  use iso_fortran_env, only: int64
  use big_integer, only: BigInt, bi_add_small, bi_to_string
  use normative_oracle_core, only: foundation_day
  use normative_oracle_calendar, only: CalendarDateResult, normative_calendar_date, reset_gate_cache
  implicit none
  integer(int64), parameter :: calc_offsets(4) = [ -1_int64, 1_int64, -1_int64, 1_int64 ]
  integer(int64), parameter :: target_offsets(4) = [ -2033_int64, -2031_int64, 2212_int64, 2214_int64 ]
  type(BigInt) :: foundation, calculation_day, target_day
  type(CalendarDateResult) :: actual
  character(len=16) :: argument
  integer :: case_number, status
  if (command_argument_count() /= 1) error stop 'one boundary-neighbor case required'
  call get_command_argument(1, argument, status=status)
  if (status /= 0) error stop 'cannot read boundary-neighbor case'
  read(argument, *, iostat=status) case_number
  if (status /= 0) error stop 'invalid boundary-neighbor case'
  if (case_number < 1 .or. case_number > 4) error stop 'boundary-neighbor case out of range'
  foundation = foundation_day()
  calculation_day = bi_add_small(foundation, calc_offsets(case_number))
  target_day = bi_add_small(foundation, target_offsets(case_number))
  call reset_gate_cache()
  actual = normative_calendar_date(calculation_day, target_day)
  write(*, '(A,I0)') 'STAGE01_NEIGHBOR_CASE=', case_number
  write(*, '(A,A)') 'STAGE01_NEIGHBOR_CALC=', trim(bi_to_string(calculation_day))
  write(*, '(A,A)') 'STAGE01_NEIGHBOR_TARGET=', trim(bi_to_string(target_day))
  write(*, '(A,A,A,I0,A,I0,A,I0,A,I0)') &
      'STAGE01_NEIGHBOR_FIELDS=', trim(bi_to_string(actual%yearNumber)), ',', &
      actual%cutletCanonicalIndex, ',', actual%dayInCutlet, ',', &
      actual%monthCanonicalIndex, ',', actual%dayInMonth
end program stage01_boundary_neighbor_probe
