! Stage 1 read-only probe of the ORIGINAL normative entry point.
! Expected fields are calculated independently at runtime by a pinned Python oracle.
program stage01_expanded_real_date_probe
  use iso_fortran_env, only: int64
  use big_integer, only: bi_from_int64, bi_to_string
  use normative_oracle_core, only: foundation_day
  use normative_oracle_calendar, only: CalendarDateResult, normative_calendar_date, reset_gate_cache
  implicit none
  type(CalendarDateResult) :: actual
  character(len=64) :: argument
  integer(int64) :: target
  integer :: status

  if (command_argument_count() /= 1) error stop 'provide exactly one target day'
  call get_command_argument(1, argument, status=status)
  if (status /= 0) error stop 'unable to read target day'
  read(argument, *, iostat=status) target
  if (status /= 0) error stop 'invalid integer target day'

  call reset_gate_cache()
  actual = normative_calendar_date(foundation_day(), bi_from_int64(target))
  write(*, '(A,I0)') 'STAGE01_EXPANDED_TARGET=', target
  write(*, '(A,A,A,I0,A,I0,A,I0,A,I0)') &
       'STAGE01_EXPANDED_FIELDS=', trim(bi_to_string(actual%yearNumber)), ',', &
       actual%cutletCanonicalIndex, ',', actual%dayInCutlet, ',', &
       actual%monthCanonicalIndex, ',', actual%dayInMonth
end program stage01_expanded_real_date_probe
