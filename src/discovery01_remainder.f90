module discovery01_remainder
  use big_integer, only: BigInt, bi_from_string, bi_mod
  use bootstrap_infrastructure, only: BaseMonsterContext, BaseDispatcher
  implicit none
  private
  character(len=*), parameter :: M_OLD_DECIMAL = '170141183460469231731687303715884105727'

  type, public :: Discovery01Context
    type(BaseMonsterContext) :: base
    type(BigInt) :: input
    type(BigInt) :: rawRemainder
    integer :: rawCalls = 0
  end type
  type, public :: Discovery01Dispatcher
    type(BaseDispatcher) :: base
  contains
    procedure :: dispatch => dispatchDiscovery01
  end type
  public :: oldRemainder
contains
  function oldRemainder(x) result(r)
    type(BigInt), intent(in) :: x
    type(BigInt) :: r
    ! Historical defect: exact multiples map to zero, not M.
    r = bi_mod(x, bi_from_string(M_OLD_DECIMAL))
  end function

  subroutine dispatchDiscovery01(self, ctx, x)
    class(Discovery01Dispatcher), intent(inout) :: self
    type(Discovery01Context), intent(out) :: ctx
    type(BigInt), intent(in) :: x
    call self%base%dispatchBootstrap(ctx%base)
    ctx%base%phase = 2
    ctx%base%subPhase = 1
    ctx%input = x
    ctx%rawRemainder = oldRemainder(ctx%input)
    ctx%rawCalls = ctx%rawCalls + 1
    ctx%base%traceCount = 2
    ctx%base%branchTrace(2) = 'DISCOVERY01_OLD_REMAINDER'
  end subroutine
end module
