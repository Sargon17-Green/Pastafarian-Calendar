! Test-only adapter for the original normative five-field entry point.
program stage01_actual_weave_probe
  use iso_fortran_env, only: int64
  use big_integer, only: BigInt, bi_from_int64, bi_to_string
  use normative_oracle_core, only: foundation_day
  use normative_oracle_calendar, only: CalendarDateResult, normative_calendar_date, reset_gate_cache
  implicit none
  type(BigInt) :: calc, target
  type(CalendarDateResult) :: actual
  integer(int64) :: day
  integer :: status
  character(len=64) :: arg
  if (command_argument_count() /= 1) error stop 'expected one integer target'
  call get_command_argument(1,arg,status=status)
  if (status /= 0) error stop 'missing target'
  read(arg,*,iostat=status) day
  if (status /= 0) error stop 'target not int64'
  calc=foundation_day()
  target=bi_from_int64(day)
  call reset_gate_cache()
  actual=normative_calendar_date(calc,target)
  write(*,'(A,A)') 'STAGE01_ACTUAL_WEAVE_CALC=',trim(bi_to_string(calc))
  write(*,'(A,A)') 'STAGE01_ACTUAL_WEAVE_TARGET=',trim(bi_to_string(target))
  write(*,'(A,A,A,I0,A,I0,A,I0,A,I0)') &
      'STAGE01_ACTUAL_WEAVE_FIELDS=',trim(bi_to_string(actual%yearNumber)),',', &
      actual%cutletCanonicalIndex,',',actual%dayInCutlet,',', &
      actual%monthCanonicalIndex,',',actual%dayInMonth
end program stage01_actual_weave_probe
