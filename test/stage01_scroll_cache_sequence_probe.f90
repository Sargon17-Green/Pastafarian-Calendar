program stage01_scroll_cache_sequence_probe
  use iso_fortran_env, only: int64, output_unit
  use big_integer, only: bi_add, bi_from_int64, bi_to_string
  use normative_oracle_core, only: foundation_day
  use normative_oracle_calendar, only: CalendarDateResult, normative_calendar_date, reset_gate_cache
  implicit none

  integer :: count, i, ios, reset_before
  integer(int64) :: calculation_offset, target_offset
  type(CalendarDateResult) :: result
  character(len=64) :: year_text

  read(*, *, iostat=ios) count
  if (ios /= 0 .or. count < 1 .or. count > 256) error stop 1

  call reset_gate_cache()
  do i = 1, count
    read(*, *, iostat=ios) calculation_offset, target_offset, reset_before
    if (ios /= 0) error stop 2
    if (reset_before /= 0 .and. reset_before /= 1) error stop 3
    if (reset_before == 1) call reset_gate_cache()

    result = normative_calendar_date( &
      bi_add(foundation_day(), bi_from_int64(calculation_offset)), &
      bi_add(foundation_day(), bi_from_int64(target_offset)) &
    )
    year_text = bi_to_string(result%yearNumber)
    write(output_unit, '(A,I0,A,I0,A,I0,A,A,A,I0,A,I0,A,I0,A,I0)') &
      'STAGE01_SCROLL_SEQUENCE_RESULT=', i, ',', calculation_offset, ',', target_offset, ',', &
      trim(year_text), ',', result%cutletCanonicalIndex, ',', result%dayInCutlet, ',', &
      result%monthCanonicalIndex, ',', result%dayInMonth
    flush(output_unit)
  end do

  write(output_unit, '(A,I0)') 'STAGE01_SCROLL_SEQUENCE_COUNT=', count
end program stage01_scroll_cache_sequence_probe
