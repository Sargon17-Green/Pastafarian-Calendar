program stage01_scroll_gate_diff_probe
  use iso_fortran_env, only: int64
  use big_integer, only: BigInt, bi_sub, bi_to_string
  use normative_oracle_core, only: foundation_day
  use normative_oracle_calendar, only: gate_day, reset_gate_cache
  implicit none
  integer(int64) :: k
  type(BigInt) :: origin, delta
  call reset_gate_cache()
  origin=foundation_day()
  do k=-10_int64,10_int64
     delta=bi_sub(gate_day(k),origin)
     write(*,'(A,I0,A,A)') 'GATE=',k,',',trim(bi_to_string(delta))
  end do
end program stage01_scroll_gate_diff_probe
