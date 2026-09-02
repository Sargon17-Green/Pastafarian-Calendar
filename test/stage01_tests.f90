program stage01_tests
  use iso_fortran_env, only: int8, int64
  use big_integer
  use source_language_catalog
  use bootstrap_infrastructure
  use normative_oracle_core
  use normative_oracle_calendar
  implicit none

  integer :: failures
  failures=0

  call test_bigint(failures)
  call test_catalog(failures)
  call test_bootstrap_infrastructure(failures)
  call test_normative_arithmetic(failures)
  call test_normative_stones(failures)
  call test_permutations(failures)
  call test_ordered_families(failures)
  call test_selection_edges(failures)
  call test_gate_gap_smoke(failures)
  call test_sauce_smoke(failures)
  call test_human_authored_text_language(failures)

  if (failures/=0) then
     write(*,'(A,I0)') 'STAGE01 FAILURES: ',failures
     error stop 1
  end if
  write(*,'(A)') 'STAGE01 PASS'

contains

  subroutine require(condition,label,failures)
    logical, intent(in) :: condition
    character(len=*), intent(in) :: label
    integer, intent(inout) :: failures
    if (.not. condition) then
       failures=failures+1
       write(*,'(A)') 'FAIL: '//trim(label)
    else
       write(*,'(A)') 'PASS: '//trim(label)
    end if
  end subroutine require

  subroutine require_bigint_text(actual,expected,label,failures)
    type(BigInt), intent(in) :: actual
    character(len=*), intent(in) :: expected,label
    integer, intent(inout) :: failures
    call require(bi_to_string(actual)==expected,label,failures)
  end subroutine require_bigint_text

  subroutine test_bigint(failures)
    integer, intent(inout) :: failures
    type(BigInt) :: a,b,c,q,r,m
    a=bi_from_string('12345678901234567890')
    call require(bi_to_string(a)=='12345678901234567890','BigInt decimal round trip',failures)
    c=bi_mul_small(a,10_int64)
    call require_bigint_text(c,'123456789012345678900','BigInt multiply by ten',failures)
    b=bi_from_int64(10_int64)
    call bi_divmod_euclid(c,b,q,r)
    call require_bigint_text(q,'12345678901234567890','BigInt exact quotient',failures)
    call require_bigint_text(r,'0','BigInt zero remainder',failures)
    m=normative_M()
    c=bi_mul(m,m)
    call bi_divmod_euclid(c,m,q,r)
    call require(bi_equal(q,m),'BigInt product and division preserve M squared',failures)
    call require(bi_is_zero(r),'BigInt M squared remainder is zero',failures)
    r=bi_mod(bi_from_int64(-1_int64),m)
    call require_bigint_text(r,'170141183460469231731687303715884105726','BigInt Euclidean negative remainder',failures)
  end subroutine test_bigint

  subroutine test_catalog(failures)
    integer, intent(inout) :: failures
    integer :: i,j
    logical :: unique
    call require(CUTLET_NAME_COUNT==17,'SourceLanguageCatalog has 17 cutlet names',failures)
    call require(MONTH_NAME_COUNT==47,'SourceLanguageCatalog has 47 month names',failures)
    call require(SOURCE_LANGUAGE_CATALOG_VERSION==1,'SourceLanguageCatalog version is frozen at bootstrap version one',failures)
    call require(cutlet_name_from_index(6)=='Four Parts of Nine','Cutlet semantic phrase is translated as one English name',failures)
    call require(cutlet_name_from_index(7)=='Palgurash','Invented cutlet sound name follows frozen transliteration',failures)
    call require(cutlet_name_from_index(12)=='Wheat','Wheat cutlet is semantically translated',failures)
    call require(month_name_from_index(7)=='Three Parts of Five','Month semantic phrase is translated as one English name',failures)
    call require(month_name_from_index(8)=='Karshumav','Invented month sound name follows frozen transliteration',failures)
    call require(month_name_from_index(28)=='Nineveh','Established place name uses established English form',failures)
    unique=.true.
    do i=1,CUTLET_NAME_COUNT
       do j=i+1,CUTLET_NAME_COUNT
          if (trim(CUTLET_NAMES_EN(i))==trim(CUTLET_NAMES_EN(j))) unique=.false.
       end do
    end do
    call require(unique,'All cutlet source strings are unique by canonical index',failures)
    unique=.true.
    do i=1,MONTH_NAME_COUNT
       do j=i+1,MONTH_NAME_COUNT
          if (trim(MONTH_NAMES_EN(i))==trim(MONTH_NAMES_EN(j))) unique=.false.
       end do
    end do
    call require(unique,'All month source strings are unique by canonical index',failures)
  end subroutine test_catalog

  subroutine test_bootstrap_infrastructure(failures)
    integer, intent(inout) :: failures
    type(BaseMonsterContext) :: ctx
    type(BaseDispatcher) :: dispatcher
    call dispatcher%dispatchBootstrap(ctx)
    call require(ctx%phase==1 .and. ctx%status==1,'Base dispatcher initializes neutral bootstrap context',failures)
    call require(ctx%traceCount==1 .and. trim(ctx%branchTrace(1))=='BOOTSTRAP_BASE_DISPATCH','Base context records deterministic trace',failures)
    call require(dispatcher%metrics%dispatchCalls==1_int64 .and. dispatcher%metrics%validationCalls==1_int64,'Base metrics shell is observational and deterministic',failures)
  end subroutine test_bootstrap_infrastructure

  subroutine test_normative_arithmetic(failures)
    integer, intent(inout) :: failures
    type(BigInt) :: m,f,cday,tday
    type(WorkCounts) :: c
    m=normative_M(); f=foundation_day()
    call require_bigint_text(save_value(bi_one()),'1','SAVE one',failures)
    call require(bi_equal(save_value(m),m),'SAVE M returns M',failures)
    call require(bi_equal(save_value(bi_mul_small(m,2_int64)),m),'SAVE two M returns M',failures)
    call require_bigint_text(save_value(bi_add_small(m,1_int64)),'1','SAVE M plus one returns one',failures)
    call require_bigint_text(save_value(bi_zero()),'170141183460469231731687303715884105727','SAVE zero returns M',failures)
    call require_bigint_text(day_count(f),'1','Foundation day count is one',failures)
    call require_bigint_text(day_count(bi_add_small(f,1_int64)),'3','Day after Foundation has odd day count three',failures)
    call require_bigint_text(day_count(bi_add_small(f,-1_int64)),'2','Day before Foundation has even day count two',failures)
    cday=bi_add_small(f,-1_int64); tday=bi_add_small(f,1_int64); c=normative_work_counts(cday,tday)
    call require_bigint_text(c%action,'2','Work action count across Foundation',failures)
    call require_bigint_text(c%target,'3','Work target count across Foundation',failures)
    call require_bigint_text(c%distance,'3','Work chronological inclusive distance across Foundation',failures)
    call require_bigint_text(c%connection,'5','Work connection count across Foundation',failures)
    call require(c%direction==3,'Work direction after calculation day is three',failures)
  end subroutine test_normative_arithmetic

  subroutine test_normative_stones(failures)
    integer, intent(inout) :: failures
    type(BigInt) :: stones(46,5)
    call build_stones(stones)
    call require_bigint_text(stones(2,WHEAT),'378','Stone row two wheat uses the old snapshot',failures)
    call require_bigint_text(stones(2,BARLEY),'1073','Stone row two barley uses the old snapshot',failures)
    call require_bigint_text(stones(2,SALT),'2375','Stone row two salt uses the old snapshot',failures)
    call require_bigint_text(stones(2,BITTER),'6195','Stone row two bitter uses the old snapshot',failures)
    call require_bigint_text(stones(2,RED),'10493','Stone row two red uses the old snapshot',failures)
  end subroutine test_normative_stones

  subroutine test_permutations(failures)
    integer, intent(inout) :: failures
    integer :: order(6)
    call bowl_order_from_number(1,order)
    call require(all(order==[1,2,3,4,5,6]),'Permutation rank one is ascending order',failures)
    call bowl_order_from_number(720,order)
    call require(all(order==[6,5,4,3,2,1]),'Permutation rank 720 is descending order',failures)
    call bowl_order_from_drop(bi_from_int64(720_int64),order)
    call require(all(order==[6,5,4,3,2,1]),'Drop multiple of 720 selects order 720',failures)
  end subroutine test_permutations

  subroutine test_ordered_families(failures)
    integer, intent(inout) :: failures
    type(BigInt) :: n
    integer :: pair(2),names(2),weave(4)
    n=count_bounded_compositions(5,2,1,4)
    call require_bigint_text(n,'4','Bounded composition count preserves lexicographic family',failures)
    call unrank_bounded_composition(5,2,1,4,bi_from_int64(3_int64),pair)
    call require(all(pair==[3,2]),'Bounded composition rank three is three two',failures)
    call unrank_distinct_indices(3,2,bi_from_int64(4_int64),names)
    call require(all(names==[2,3]),'Distinct-name partial permutation rank four is two three',failures)
    n=count_weavings([2,2])
    call require_bigint_text(n,'2','Two-by-two weaving family has two legal rows',failures)
    call unrank_weaving([2,2],bi_from_int64(1_int64),weave)
    call require(all(weave==[1,1,2,2]),'Weaving rank one is 1122',failures)
    call unrank_weaving([2,2],bi_from_int64(2_int64),weave)
    call require(all(weave==[1,2,1,2]),'Weaving rank two is 1212',failures)
    n=count_cutlet_partitions(6,3,-1)
    call require_bigint_text(n,'10','Positive cutlet composition count for six into three is ten',failures)
    n=count_cutlet_partitions(6,3,2)
    call require_bigint_text(n,'4','Internal gate filter keeps exactly four six-into-three partitions at boundary two',failures)
  end subroutine test_ordered_families

  subroutine test_selection_edges(failures)
    integer, intent(inout) :: failures
    type(AnswerStream) :: stream
    type(BigInt) :: m,n,rank
    m=normative_M()
    stream%first=m; stream%directionStep=1
    rank=choose_rank(stream,bi_from_int64(2_int64))
    call require_bigint_text(rank,'1','Short rejection advances on the same answer ring',failures)
    stream%first=bi_one(); stream%directionStep=1
    n=bi_add_small(m,1_int64)
    rank=choose_rank(stream,n)
    call require(bi_equal(rank,n),'Wide selection builds one wide value and accepts its exact rank',failures)
  end subroutine test_selection_edges

  subroutine test_gate_gap_smoke(failures)
    integer, intent(inout) :: failures
    integer :: gp,gn
    gp=positive_gate_gap(1_int64)
    gn=negative_gate_gap(1_int64)
    call require(gp>=GATE_GAP_MIN .and. gp<=GATE_GAP_MAX,'Positive gate one gap is within normative bounds',failures)
    call require(gn>=GATE_GAP_MIN .and. gn<=GATE_GAP_MAX,'Negative gate one gap is within normative bounds',failures)
  end subroutine test_gate_gap_smoke

  subroutine test_sauce_smoke(failures)
    integer, intent(inout) :: failures
    type(SauceResult) :: s
    type(BigInt) :: f,m
    integer :: i,j
    logical :: permutation
    f=foundation_day(); m=normative_M(); s=normative_sauce(f,f)
    permutation=.true.
    do i=1,6
       if (s%orderAtDrop46(i)<1 .or. s%orderAtDrop46(i)>6) permutation=.false.
       do j=i+1,6
          if (s%orderAtDrop46(i)==s%orderAtDrop46(j)) permutation=.false.
       end do
       if (bi_compare(s%bowls(i),bi_one())<0 .or. bi_compare(s%bowls(i),m)>0) permutation=.false.
    end do
    call require(permutation,'Normative sauce Foundation smoke result has six saved bowls and a latched permutation',failures)
  end subroutine test_sauce_smoke

  subroutine test_human_authored_text_language(failures)
    integer, intent(inout) :: failures
    character(len=96), parameter :: paths(6)=[character(len=96) :: &
         'README.md', &
         'SPAGHETTI_DEVELOPMENT_HISTORY.md', &
         'docs/SOURCE_LANGUAGE_CATALOG.md', &
         'handoff/COMMIT_MESSAGE.md', &
         'handoff/GITHUB_NOTES.md', &
         'handoff/FILES_CHANGED.md' ]
    integer :: i
    logical :: ok
    ok=.true.
    do i=1,size(paths)
       if (.not. ascii_file(trim(paths(i)))) ok=.false.
    end do
    call require(ok,'All human-authored prose files under the Stage 1 prose audit are English ASCII',failures)
  end subroutine test_human_authored_text_language

  logical function ascii_file(path)
    character(len=*), intent(in) :: path
    integer :: unit,ios,sizeBytes,i
    integer(int8), allocatable :: bytes(:)
    inquire(file=path,size=sizeBytes,iostat=ios)
    if (ios/=0 .or. sizeBytes<0) then
       ascii_file=.false.; return
    end if
    allocate(bytes(max(1,sizeBytes)))
    open(newunit=unit,file=path,access='stream',form='unformatted',status='old',action='read',iostat=ios)
    if (ios/=0) then; ascii_file=.false.; return; end if
    if (sizeBytes>0) read(unit,iostat=ios) bytes(1:sizeBytes)
    close(unit)
    if (ios/=0 .and. sizeBytes>0) then; ascii_file=.false.; return; end if
    ascii_file=.true.
    do i=1,sizeBytes
       if (int(bytes(i),kind=int64)<0_int64) then
          ascii_file=.false.; return
       end if
    end do
  end function ascii_file

end program stage01_tests
