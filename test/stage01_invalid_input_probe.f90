! Stage 1 negative-input contracts. Execute exactly one mode per process.
! The caller must demand a specific ERROR STOP message and exit code 1.
program stage01_invalid_input_probe
  use iso_fortran_env, only: int64
  use big_integer
  use bootstrap_infrastructure
  implicit none

  type(BigInt) :: parsed, quotient, remainder
  type(BaseMonsterContext) :: ctx
  type(BaseValidationManager) :: validator
  type(BaseErrorWrapper) :: errors
  character(len=48) :: mode

  if (command_argument_count() /= 1) error stop 'exactly one invalid-input mode is required'
  call get_command_argument(1, mode)

  select case (trim(mode))
  case ('empty-text')
     parsed = bi_from_string('')
  case ('plus-only')
     parsed = bi_from_string('+')
  case ('minus-only')
     parsed = bi_from_string('-')
  case ('invalid-digit')
     parsed = bi_from_string('12x3')
  case ('leading-space')
     parsed = bi_from_string(' 123')
  case ('internal-space')
     parsed = bi_from_string('12 3')
  case ('zero-divisor')
     call bi_divmod_euclid(bi_one(), bi_zero(), quotient, remainder)
  case ('negative-divisor')
     call bi_divmod_euclid(bi_one(), bi_from_int64(-1_int64), quotient, remainder)
  case ('negative-retry-budget')
     ctx%retryBudget = -1
     call validator%requireBootstrapContext(ctx)
  case ('negative-trace-count')
     ctx%traceCount = -1
     call validator%requireBootstrapContext(ctx)
  case ('excessive-trace-count')
     ctx%traceCount = 129
     call validator%requireBootstrapContext(ctx)
  case ('negative-diagnostic-count')
     ctx%diagnosticCount = -1
     call errors%recordDiagnostic(ctx, 'test')
  case ('exhausted-diagnostic-capacity')
     ctx%diagnosticCount = 128
     call errors%recordDiagnostic(ctx, 'test')
  case default
     error stop 'unknown invalid-input probe mode'
  end select

  ! Reaching this point means the rejected input unexpectedly succeeded.
  write(*,'(A)') 'UNEXPECTED_RETURN=' // trim(mode)
  error stop 'invalid input was accepted'
end program stage01_invalid_input_probe
