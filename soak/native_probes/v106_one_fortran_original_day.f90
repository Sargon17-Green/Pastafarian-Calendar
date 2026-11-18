! v106: one read-only F(c,t) call to the original Fortran normative source.
! This QA adapter does not implement, optimize, or change calendar arithmetic.
program v106_one_original_fortran_day
  use big_integer, only: BigInt, bi_to_string
  use normative_oracle_core, only: foundation_day
  use normative_oracle_calendar, only: CalendarDateResult, normative_calendar_date, reset_gate_cache
  implicit none
  type(BigInt) :: c
  type(CalendarDateResult) :: r
  c=foundation_day()
  call reset_gate_cache()
  r=normative_calendar_date(c,c)
  write(*,'(A,1X,A,1X,A,1X,A,1X,I0,1X,I0,1X,I0,1X,I0)') &
       'V106_FORTRAN_ORIGINAL_FCT_NATIVE', &
       trim(bi_to_string(c)),trim(bi_to_string(c)),trim(bi_to_string(r%yearNumber)), &
       r%cutletCanonicalIndex,r%dayInCutlet,r%monthCanonicalIndex,r%dayInMonth
end program v106_one_original_fortran_day
