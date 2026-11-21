program stage01_scroll_stir_probe
  use iso_fortran_env, only: int64
  use big_integer, only: BigInt, bi_from_int64, bi_to_string
  use normative_oracle_core, only: post_stir_12
  implicit none
  type(BigInt) :: bowls(6)
  integer(int64) :: value
  integer :: i,istat
  character(len=64) :: arg

  if (command_argument_count()/=6) error stop 'provide exactly six positive bowl values'
  do i=1,6
     call get_command_argument(i,arg,status=istat)
     if (istat/=0) error stop 'cannot read bowl argument'
     read(arg,*,iostat=istat) value
     if (istat/=0) error stop 'invalid integer bowl argument'
     if (value<1_int64) error stop 'bowl values must be positive'
     bowls(i)=bi_from_int64(value)
  end do

  call post_stir_12(bowls)
  do i=1,6
     write(*,'(A,I0,A,A)') 'STAGE01_SCROLL_STIR_BOWL=',i,',',trim(bi_to_string(bowls(i)))
  end do
end program stage01_scroll_stir_probe
