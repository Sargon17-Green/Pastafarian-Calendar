program stage01_scroll_full_date_probe
  use iso_fortran_env, only: int64
  use big_integer, only: bi_add, bi_from_int64, bi_to_string
  use normative_oracle_core, only: foundation_day
  use normative_oracle_calendar, only: CalendarDateResult, normative_calendar_date, reset_gate_cache
  implicit none
  character(len=64) :: calculation_arg, target_arg
  integer :: status
  integer(int64) :: calculation_offset, target_offset
  type(CalendarDateResult) :: result

  call get_command_argument(1, calculation_arg, status=status)
  if (status /= 0) error stop 'missing calculation offset'
  read(calculation_arg, *, iostat=status) calculation_offset
  if (status /= 0) error stop 'invalid calculation offset'
  call get_command_argument(2, target_arg, status=status)
  if (status /= 0) error stop 'missing target offset'
  read(target_arg, *, iostat=status) target_offset
  if (status /= 0) error stop 'invalid target offset'

  call reset_gate_cache()
  result = normative_calendar_date( &
       bi_add(foundation_day(), bi_from_int64(calculation_offset)), &
       bi_add(foundation_day(), bi_from_int64(target_offset)))

  write(*,'(A,I0)') 'STAGE01_SCROLL_DATE_CALC_OFFSET=', calculation_offset
  write(*,'(A,I0)') 'STAGE01_SCROLL_DATE_TARGET_OFFSET=', target_offset
  write(*,'(A,A,A,I0,A,I0,A,I0,A,I0)') 'STAGE01_SCROLL_DATE_FIELDS=', &
       trim(bi_to_string(result%yearNumber)), ',', result%cutletCanonicalIndex, ',', &
       result%dayInCutlet, ',', result%monthCanonicalIndex, ',', result%dayInMonth
end program stage01_scroll_full_date_probe
