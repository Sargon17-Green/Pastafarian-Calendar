! Gated full-sized total only. Its independent 45-month fixture comes from
! the normative first-day trace; small-shape exhaustiveness is gated separately.
program stage01_normative_count_dp_probe
  use big_integer, only: BigInt, bi_to_string
  use normative_oracle_core, only: count_weavings
  implicit none
  integer, parameter :: lengths(45) = [ &
       115,108,119,109,106,81,115,114,117,120, &
       98,52,81,97,121,97,115,96,107,61, &
       106,115,119,39,84,103,115,107,55,119, &
       97,50,122,110,81,54,101,83,88,40, &
       25,77,98,122,105 ]
  type(BigInt) :: result
  character(len=:), allocatable :: digits

  result=count_weavings(lengths)
  digits=bi_to_string(result)
  if (len(digits)/=6765) error stop 'normative count digits mismatch'
  write(*,'(A)') digits
end program stage01_normative_count_dp_probe
