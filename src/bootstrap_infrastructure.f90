module bootstrap_infrastructure
  use iso_fortran_env, only: int64
  implicit none
  private

  integer, parameter :: MAX_TRACE = 128
  integer, parameter :: MAX_DIAGNOSTICS = 128

  type, public :: BaseMonsterContext
     integer(int64) :: calculationDayHint = 0_int64
     integer(int64) :: targetDayHint = 0_int64
     integer :: phase = 0
     integer :: subPhase = 0
     integer :: mode = 0
     integer :: status = 0
     integer :: retryBudget = 0
     integer :: recoveryDepth = 0
     integer :: traceCount = 0
     character(len=48) :: branchTrace(MAX_TRACE) = ''
     integer :: diagnosticCount = 0
     character(len=96) :: diagnostics(MAX_DIAGNOSTICS) = ''
  end type BaseMonsterContext

  type, public :: BaseMetricsShell
     integer(int64) :: dispatchCalls = 0_int64
     integer(int64) :: validationCalls = 0_int64
     integer(int64) :: wrappedErrors = 0_int64
  contains
     procedure :: bumpDispatch
     procedure :: bumpValidation
     procedure :: bumpWrappedError
  end type BaseMetricsShell

  type, public :: BaseValidationManager
  contains
     procedure :: requireBootstrapContext
  end type BaseValidationManager

  type, public :: BaseErrorWrapper
  contains
     procedure :: recordDiagnostic
  end type BaseErrorWrapper

  type, public :: BaseDispatcher
     type(BaseMetricsShell) :: metrics
     type(BaseValidationManager) :: validator
     type(BaseErrorWrapper) :: errors
  contains
     procedure :: dispatchBootstrap
  end type BaseDispatcher

contains

  subroutine bumpDispatch(self)
    class(BaseMetricsShell), intent(inout) :: self
    self%dispatchCalls = self%dispatchCalls + 1_int64
  end subroutine bumpDispatch

  subroutine bumpValidation(self)
    class(BaseMetricsShell), intent(inout) :: self
    self%validationCalls = self%validationCalls + 1_int64
  end subroutine bumpValidation

  subroutine bumpWrappedError(self)
    class(BaseMetricsShell), intent(inout) :: self
    self%wrappedErrors = self%wrappedErrors + 1_int64
  end subroutine bumpWrappedError

  subroutine requireBootstrapContext(self, ctx)
    class(BaseValidationManager), intent(in) :: self
    type(BaseMonsterContext), intent(in) :: ctx
    if (ctx%retryBudget < 0) error stop 'bootstrap retry budget must be nonnegative'
    if (ctx%traceCount < 0 .or. ctx%traceCount > MAX_TRACE) error stop 'bootstrap trace count is invalid'
  end subroutine requireBootstrapContext

  subroutine recordDiagnostic(self, ctx, text)
    class(BaseErrorWrapper), intent(in) :: self
    type(BaseMonsterContext), intent(inout) :: ctx
    character(len=*), intent(in) :: text
    if (ctx%diagnosticCount >= MAX_DIAGNOSTICS) error stop 'bootstrap diagnostic capacity exceeded'
    ctx%diagnosticCount = ctx%diagnosticCount + 1
    ctx%diagnostics(ctx%diagnosticCount) = text
  end subroutine recordDiagnostic

  subroutine dispatchBootstrap(self, ctx)
    class(BaseDispatcher), intent(inout) :: self
    type(BaseMonsterContext), intent(inout) :: ctx
    call self%metrics%bumpDispatch()
    ctx%phase = 1
    ctx%subPhase = 0
    ctx%mode = 1
    ctx%status = 1
    ctx%retryBudget = 0
    ctx%traceCount = 1
    ctx%branchTrace(1) = 'BOOTSTRAP_BASE_DISPATCH'
    call self%metrics%bumpValidation()
    call self%validator%requireBootstrapContext(ctx)
  end subroutine dispatchBootstrap

end module bootstrap_infrastructure
