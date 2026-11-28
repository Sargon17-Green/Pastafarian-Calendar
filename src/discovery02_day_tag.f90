module discovery02_day_tag
  use iso_fortran_env, only: int64
  use big_integer, only: BigInt, bi_from_string, bi_sub, bi_abs, bi_mul_small
  use bootstrap_infrastructure, only: BaseMonsterContext, BaseDispatcher
  implicit none
  private
  character(len=*), parameter :: FOUNDATION_DECIMAL = '-15055671'
  type, public :: Discovery02Context
    type(BaseMonsterContext) :: base
    type(BigInt) :: input, rawDayTag
    integer :: rawCalls = 0
  end type
  type, public :: Discovery02Dispatcher
    type(BaseDispatcher) :: base
  contains
    procedure :: dispatch => dispatchDiscovery02
  end type
  public :: oldDayTag
contains
  function oldDayTag(day) result(tag)
    type(BigInt), intent(in) :: day
    type(BigInt) :: tag
    ! Intentional historical assumption prescribed by Discovery 02.
    tag = bi_mul_small(bi_abs(bi_sub(day,bi_from_string(FOUNDATION_DECIMAL))),2_int64)
  end function
  subroutine dispatchDiscovery02(self,ctx,day)
    class(Discovery02Dispatcher), intent(inout) :: self
    type(Discovery02Context), intent(out) :: ctx
    type(BigInt), intent(in) :: day
    call self%base%dispatchBootstrap(ctx%base)
    ctx%base%phase = 4
    ctx%base%subPhase = 2
    ctx%input = day
    ctx%rawDayTag = oldDayTag(ctx%input)
    ctx%rawCalls = ctx%rawCalls + 1
    ctx%base%traceCount = 2
    ctx%base%branchTrace(2) = 'DISCOVERY02_OLD_DAY_TAG'
  end subroutine
end module
