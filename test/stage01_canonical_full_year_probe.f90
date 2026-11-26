! QA-only adapter: one ORIGINAL Fortran year construction, all daily projections.
! It also probes original unrank_weaving at ranks 1, 2, N-1 and N.
! Deliberately not a substitute for repeated normative_calendar_date entry calls.
program stage01_canonical_full_year_probe
  use iso_fortran_env, only: int64
  use big_integer, only: BigInt, bi_add_small, bi_compare, bi_to_string, bi_one, bi_sub
  use normative_oracle_core, only: foundation_day, count_weavings, unrank_weaving
  use normative_oracle_calendar, only: YearRecord, YearStructure, CalendarDateResult, &
       year5000, build_year_structure, project_calendar_date, reset_gate_cache
  implicit none
  type(BigInt) :: calculation_day, target, weaving_count, rank_second, rank_penultimate
  type(YearRecord) :: year
  type(YearStructure) :: structure
  type(CalendarDateResult) :: fields
  integer :: i, days
  integer, allocatable :: month_occurrences(:)
  integer, allocatable :: rank_first(:), rank_second_ids(:), rank_penultimate_ids(:), rank_last(:)

  if (command_argument_count() /= 0) error stop 'no arguments permitted'
  calculation_day=foundation_day()
  call reset_gate_cache()
  year=year5000(calculation_day)
  structure=build_year_structure(calculation_day,year)
  days=size(structure%monthWeaving)
  if (structure%monthCount /= 44 .or. days /= 4399) error stop 'unexpected actual year 5000'
  if (size(structure%monthLengths) /= 44 .or. size(structure%monthNameIndices) /= 44) &
       error stop 'month structures mismatch'
  if (bi_compare(bi_add_small(year%openGateDay,int(days,int64)),year%closeGateDay) /= 0) &
       error stop 'actual gate span mismatch'
  if (sum(structure%monthLengths) /= days) error stop 'actual lengths do not cover year'

  ! Recompute the exact total so the original unrank routine can be checked
  ! independently at both extremal and their adjacent ranks.
  weaving_count=count_weavings(structure%monthLengths)
  if (bi_compare(weaving_count,bi_add_small(bi_one(),1_int64)) <= 0) &
       error stop 'actual weaving family has too few ranks'
  rank_second=bi_add_small(bi_one(),1_int64)
  rank_penultimate=bi_sub(weaving_count,bi_one())
  allocate(rank_first(days),rank_second_ids(days),rank_penultimate_ids(days),rank_last(days))
  call unrank_weaving(structure%monthLengths,bi_one(),rank_first,weaving_count)
  call unrank_weaving(structure%monthLengths,rank_second,rank_second_ids,weaving_count)
  call unrank_weaving(structure%monthLengths,rank_penultimate,rank_penultimate_ids,weaving_count)
  call unrank_weaving(structure%monthLengths,weaving_count,rank_last,weaving_count)

  call check_weave(structure%monthWeaving,structure%monthLengths)
  call check_weave(rank_first,structure%monthLengths)
  call check_weave(rank_second_ids,structure%monthLengths)
  call check_weave(rank_penultimate_ids,structure%monthLengths)
  call check_weave(rank_last,structure%monthLengths)

  allocate(month_occurrences(44))
  month_occurrences=0
  write(*,'(A,A,A,A,A,A,A,I0,A,I0)') 'STAGE01_CANONICAL_YEAR_META=', &
       trim(bi_to_string(year%number)),',',trim(bi_to_string(year%openGateDay)),',', &
       trim(bi_to_string(year%closeGateDay)),',',days,',',structure%monthCount
  write(*,'(A)',advance='no') 'STAGE01_CANONICAL_YEAR_LENGTHS='
  do i=1,44
     if (i>1) write(*,'(A)',advance='no') ','
     write(*,'(I0)',advance='no') structure%monthLengths(i)
  end do
  write(*,*)
  write(*,'(A,A)') 'STAGE01_CANONICAL_YEAR_RANK_TOTAL=',trim(bi_to_string(weaving_count))

  do i=1,days
     if (structure%monthWeaving(i)<1 .or. structure%monthWeaving(i)>44) &
          error stop 'invalid month ID'
     month_occurrences(structure%monthWeaving(i))=month_occurrences(structure%monthWeaving(i))+1
     target=bi_add_small(year%openGateDay,int(i,int64))
     fields=project_calendar_date(target,year,structure)
     write(*,'(A,I0,A,I0,A,A,A,I0,A,I0,A,I0,A,I0)') 'STAGE01_CANONICAL_YEAR_ROW=',i,',', &
          structure%monthWeaving(i),',',trim(bi_to_string(fields%yearNumber)),',', &
          fields%cutletCanonicalIndex,',',fields%dayInCutlet,',', &
          fields%monthCanonicalIndex,',',fields%dayInMonth
     write(*,'(A,I0,A,I0,A,I0,A,I0,A,I0)') 'STAGE01_CANONICAL_YEAR_RANK_ROW=',i,',', &
          rank_first(i),',',rank_second_ids(i),',',rank_penultimate_ids(i),',',rank_last(i)
  end do
  if (any(month_occurrences /= structure%monthLengths)) &
       error stop 'actual month frequency mismatch'
  write(*,'(A,I0)') 'STAGE01_CANONICAL_YEAR_DONE=',days
  write(*,'(A,I0)') 'STAGE01_CANONICAL_YEAR_RANK_DONE=',days
  write(*,'(A)') 'STAGE01_CANONICAL_YEAR_ORDERING_PASS=5/5'

contains

  subroutine check_weave(sequence,lengths)
    integer, intent(in) :: sequence(:),lengths(:)
    integer, allocatable :: counts(:),first_pos(:),last_pos(:)
    integer :: i,month_id,n,days

    n=size(lengths)
    days=size(sequence)
    allocate(counts(n),first_pos(n),last_pos(n))
    counts=0
    first_pos=days+1
    last_pos=0
    do i=1,days
       month_id=sequence(i)
       if (month_id<1 .or. month_id>n) error stop 'weaving month ID out of range'
       counts(month_id)=counts(month_id)+1
       if (first_pos(month_id)==days+1) first_pos(month_id)=i
       last_pos(month_id)=i
    end do
    if (any(counts/=lengths)) error stop 'weaving month frequency mismatch'
    do i=2,n
       if (first_pos(i)<=first_pos(i-1)) error stop 'first occurrence order mismatch'
       if (last_pos(i)<=last_pos(i-1)) error stop 'last occurrence order mismatch'
    end do
  end subroutine check_weave

end program stage01_canonical_full_year_probe
