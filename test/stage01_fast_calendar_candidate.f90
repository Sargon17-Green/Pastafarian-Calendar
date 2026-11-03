! Test-only Stage 1 fast complete-date candidate.
! The normative_oracle_calendar module is deliberately left unchanged.
! All calendar rules other than month weaving are exercised through the
! same public reference primitives, while exact polynomial counting and
! lexicographic unranking replace the reference's expensive memoized weave.
! This is NOT independent proof of the normative five-field result.
module stage01_fast_calendar_candidate
  use iso_fortran_env, only: int64
  use big_integer
  use source_language_catalog, only: CUTLET_NAME_COUNT, MONTH_NAME_COUNT
  use normative_oracle_core, only: SauceResult, AnswerStream, &
       MIN_CUTLETS, MAX_CUTLETS, MIN_MONTHS, MAX_MONTHS, &
       MIN_MONTH_DAYS, MAX_MONTH_DAYS, &
       SEAL_CUTLET_COUNT, SEAL_CUTLET_PARTITION, SEAL_CUTLET_NAMES, &
       SEAL_MONTH_COUNT, SEAL_MONTH_LENGTHS, SEAL_MONTH_WEAVING, SEAL_MONTH_NAMES, &
       normative_sauce, ask_bowl, choose_rank, falling_factorial, &
       unrank_distinct_indices, count_bounded_compositions, &
       unrank_bounded_composition, ceil_div_small
  use normative_oracle_calendar, only: YearRecord, YearStructure, &
       CalendarDateResult, find_target_year, exact_gate_index, gate_day, &
       count_cutlet_partitions, unrank_cutlet_partition, project_calendar_date
  use stage01_weaving_polynomial, only: PrefixCompletionCache, &
       prepare_prefix_completion_cache, count_prefix_weavings_polynomial
  use stage01_weaving_polynomial_unrank, only: unrank_weaving_polynomial
  implicit none
  private
  public :: build_candidate_year_structure, candidate_calendar_date
contains
  function build_candidate_year_structure(calculationDay,year) result(s)
    type(BigInt), intent(in) :: calculationDay
    type(YearRecord), intent(in) :: year
    type(YearStructure) :: s
    type(SauceResult) :: sauceData
    type(AnswerStream) :: answers
    type(PrefixCompletionCache) :: exactCache
    type(BigInt) :: rank,total
    integer :: gaps,choices,required,monthDays,minMonths,maxMonths,i,monthCount
    integer(int64) :: gateIndex,atIndex,nextIndex
    logical :: found,ok

    s%yearFirstDay=bi_add_small(year%openGateDay,1_int64)
    sauceData=normative_sauce(calculationDay,s%yearFirstDay)
    gaps=int(year%closeGateIndex-year%openGateIndex)
    choices=min(MAX_CUTLETS,gaps)-MIN_CUTLETS+1
    if (choices<1) error stop 'candidate calendar: no cutlet-count candidates'
    answers=ask_bowl(sauceData,2,SEAL_CUTLET_COUNT)
    rank=choose_rank(answers,bi_from_int64(int(choices,int64)))
    s%cutletCount=MIN_CUTLETS+int(bi_to_int64(rank))-1

    required=-1
    gateIndex=exact_gate_index(calculationDay,found)
    if (found .and. gateIndex>year%openGateIndex .and. &
         gateIndex<year%closeGateIndex) required=int(gateIndex-year%openGateIndex)
    total=count_cutlet_partitions(gaps,s%cutletCount,required)
    answers=ask_bowl(sauceData,2,SEAL_CUTLET_PARTITION)
    rank=choose_rank(answers,total)
    allocate(s%cutletPartition(s%cutletCount))
    call unrank_cutlet_partition(gaps,s%cutletCount,required,rank,s%cutletPartition)

    total=falling_factorial(CUTLET_NAME_COUNT,s%cutletCount)
    answers=ask_bowl(sauceData,5,SEAL_CUTLET_NAMES)
    rank=choose_rank(answers,total)
    allocate(s%cutletNameIndices(s%cutletCount))
    call unrank_distinct_indices(CUTLET_NAME_COUNT,s%cutletCount,rank,s%cutletNameIndices)

    allocate(s%cutletFirstDays(s%cutletCount),s%cutletLastDays(s%cutletCount))
    atIndex=year%openGateIndex
    do i=1,s%cutletCount
       nextIndex=atIndex+int(s%cutletPartition(i),int64)
       s%cutletFirstDays(i)=bi_add_small(gate_day(atIndex),1_int64)
       s%cutletLastDays(i)=gate_day(nextIndex)
       atIndex=nextIndex
    end do
    if (atIndex/=year%closeGateIndex) error stop 'candidate calendar: cutlet partition incomplete'

    monthDays=int(bi_to_int64(bi_sub(year%closeGateDay,year%openGateDay)))
    minMonths=ceil_div_small(monthDays,MAX_MONTH_DAYS)
    maxMonths=min(MAX_MONTHS,monthDays/MIN_MONTH_DAYS)
    if (minMonths<MIN_MONTHS .or. minMonths>maxMonths) &
         error stop 'candidate calendar: month-count bounds invalid'
    answers=ask_bowl(sauceData,3,SEAL_MONTH_COUNT)
    rank=choose_rank(answers,bi_from_int64(int(maxMonths-minMonths+1,int64)))
    monthCount=minMonths+int(bi_to_int64(rank))-1
    s%monthCount=monthCount

    total=count_bounded_compositions(monthDays,monthCount,MIN_MONTH_DAYS,MAX_MONTH_DAYS)
    answers=ask_bowl(sauceData,3,SEAL_MONTH_LENGTHS)
    rank=choose_rank(answers,total)
    allocate(s%monthLengths(monthCount))
    call unrank_bounded_composition(monthDays,monthCount,MIN_MONTH_DAYS,MAX_MONTH_DAYS, &
         rank,s%monthLengths)
    if (sum(s%monthLengths)/=monthDays) error stop 'candidate calendar: month lengths incorrect'

    ! One exact table is shared by total counting and arbitrary-rank decoding.
    call prepare_prefix_completion_cache(s%monthLengths,exactCache)
    total=count_prefix_weavings_polynomial(s%monthLengths,s%monthLengths,0,0,exactCache)
    answers=ask_bowl(sauceData,4,SEAL_MONTH_WEAVING)
    rank=choose_rank(answers,total)
    allocate(s%monthWeaving(monthDays))
    call unrank_weaving_polynomial(s%monthLengths,rank,s%monthWeaving,ok,total,exactCache)
    if (.not.ok) error stop 'candidate calendar: month weaving unrank failed'

    total=falling_factorial(MONTH_NAME_COUNT,monthCount)
    answers=ask_bowl(sauceData,5,SEAL_MONTH_NAMES)
    rank=choose_rank(answers,total)
    allocate(s%monthNameIndices(monthCount))
    call unrank_distinct_indices(MONTH_NAME_COUNT,monthCount,rank,s%monthNameIndices)
  end function build_candidate_year_structure

  function candidate_calendar_date(calculationDay,targetDay) result(date)
    type(BigInt), intent(in) :: calculationDay,targetDay
    type(CalendarDateResult) :: date
    type(YearRecord) :: year
    type(YearStructure) :: structure
    year=find_target_year(calculationDay,targetDay)
    structure=build_candidate_year_structure(calculationDay,year)
    date=project_calendar_date(targetDay,year,structure)
  end function candidate_calendar_date
end module stage01_fast_calendar_candidate
