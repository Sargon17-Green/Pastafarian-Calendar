program stage01_foundation_candidate_probe
  use iso_fortran_env, only: int64
  use big_integer, only: BigInt, bi_add_small, bi_compare, bi_to_string, bi_from_int64, bi_sub, bi_to_int64
  use normative_oracle_core, only: foundation_day
  use normative_oracle_calendar, only: YearRecord, YearStructure, CalendarDateResult, &
       find_target_year, build_year_structure, project_calendar_date, reset_gate_cache
  implicit none
  type(BigInt) :: calculation_day, target_day, expected_day_in_cutlet
  type(YearRecord) :: year
  type(YearStructure) :: structure
  type(CalendarDateResult) :: fields
  integer :: days, i, j, month_id, cutlet_position, month_offset, expected_day_in_month
  integer, allocatable :: occurrences(:), first_pos(:), last_pos(:)

  call reset_gate_cache()
  calculation_day=foundation_day()
  target_day=calculation_day
  year=find_target_year(calculation_day,target_day)
  structure=build_year_structure(calculation_day,year)
  fields=project_calendar_date(target_day,year,structure)

  if (bi_compare(year%number,bi_from_int64(5000_int64))/=0) &
       error stop 'Foundation Day did not resolve to year 5000'
  if (bi_compare(fields%yearNumber,year%number)/=0) &
       error stop 'projected year differs from selected year'
  if (bi_compare(structure%yearFirstDay,bi_add_small(year%openGateDay,1_int64))/=0) &
       error stop 'year first day is not open gate plus one'
  if (year%closeGateIndex<=year%openGateIndex) error stop 'invalid gate indices'

  if (.not. allocated(structure%cutletPartition) .or. .not. allocated(structure%cutletNameIndices)) &
       error stop 'cutlet structure is missing'
  if (.not. allocated(structure%cutletFirstDays) .or. .not. allocated(structure%cutletLastDays)) &
       error stop 'cutlet day boundaries are missing'
  if (.not. allocated(structure%monthLengths) .or. .not. allocated(structure%monthNameIndices) .or. &
      .not. allocated(structure%monthWeaving)) error stop 'month structure is missing'
  if (structure%cutletCount/=size(structure%cutletPartition) .or. &
      structure%cutletCount/=size(structure%cutletNameIndices) .or. &
      structure%cutletCount/=size(structure%cutletFirstDays) .or. &
      structure%cutletCount/=size(structure%cutletLastDays)) error stop 'cutlet dimensions mismatch'
  if (structure%monthCount/=size(structure%monthLengths) .or. &
      structure%monthCount/=size(structure%monthNameIndices)) error stop 'month dimensions mismatch'
  if (sum(structure%cutletPartition)/=int(year%closeGateIndex-year%openGateIndex)) &
       error stop 'cutlet partition does not span the selected gates'
  if (any(structure%cutletPartition<1)) error stop 'nonpositive cutlet partition'
  if (any(structure%monthLengths<4) .or. any(structure%monthLengths>123)) &
       error stop 'month length outside Scroll bounds'

  days=sum(structure%monthLengths)
  if (days/=size(structure%monthWeaving)) error stop 'month lengths do not cover weaving'
  allocate(occurrences(structure%monthCount),first_pos(structure%monthCount),last_pos(structure%monthCount))
  occurrences=0
  first_pos=days+1
  last_pos=0
  do i=1,days
     month_id=structure%monthWeaving(i)
     if (month_id<1 .or. month_id>structure%monthCount) error stop 'weaving month ID outside structure'
     occurrences(month_id)=occurrences(month_id)+1
     if (first_pos(month_id)==days+1) first_pos(month_id)=i
     last_pos(month_id)=i
  end do
  if (any(occurrences/=structure%monthLengths)) error stop 'weaving frequencies differ from month lengths'
  do i=2,structure%monthCount
     if (first_pos(i)<=first_pos(i-1)) error stop 'first occurrence ordering invalid'
     if (last_pos(i)<=last_pos(i-1)) error stop 'last occurrence ordering invalid'
  end do

  do i=1,structure%cutletCount
     if (structure%cutletNameIndices(i)<1 .or. structure%cutletNameIndices(i)>17) &
          error stop 'cutlet name index outside catalog'
     if (bi_compare(structure%cutletFirstDays(i),structure%cutletLastDays(i))>0) &
          error stop 'cutlet first day exceeds last day'
     if (bi_to_int64(bi_add_small(bi_sub(structure%cutletLastDays(i),structure%cutletFirstDays(i)),1_int64)) &
         /=int(structure%cutletPartition(i),int64)) error stop 'cutlet span differs from partition'
     do j=i+1,structure%cutletCount
        if (structure%cutletNameIndices(i)==structure%cutletNameIndices(j)) &
             error stop 'duplicate cutlet name index'
     end do
  end do
  do i=1,structure%monthCount
     if (structure%monthNameIndices(i)<1 .or. structure%monthNameIndices(i)>47) &
          error stop 'month name index outside catalog'
     do j=i+1,structure%monthCount
        if (structure%monthNameIndices(i)==structure%monthNameIndices(j)) &
             error stop 'duplicate month name index'
     end do
  end do

  cutlet_position=0
  do i=1,structure%cutletCount
     if (bi_compare(structure%cutletFirstDays(i),target_day)<=0 .and. &
         bi_compare(target_day,structure%cutletLastDays(i))<=0) then
        cutlet_position=i
        exit
     end if
  end do
  if (cutlet_position==0) error stop 'Foundation Day is outside selected cutlets'
  expected_day_in_cutlet=bi_add_small(bi_sub(target_day,structure%cutletFirstDays(cutlet_position)),1_int64)
  if (fields%cutletCanonicalIndex/=structure%cutletNameIndices(cutlet_position)) &
       error stop 'projected cutlet name does not match containing cutlet'
  if (fields%dayInCutlet/=int(bi_to_int64(expected_day_in_cutlet))) &
       error stop 'projected day-in-cutlet does not match cutlet boundary'

  month_offset=int(bi_to_int64(bi_sub(target_day,structure%yearFirstDay)))
  if (month_offset<0 .or. month_offset>=days) error stop 'Foundation Day is outside selected year span'
  month_id=structure%monthWeaving(month_offset+1)
  expected_day_in_month=0
  do i=1,month_offset+1
     if (structure%monthWeaving(i)==month_id) expected_day_in_month=expected_day_in_month+1
  end do
  if (fields%monthCanonicalIndex/=structure%monthNameIndices(month_id)) &
       error stop 'projected month name does not match woven month ID'
  if (fields%dayInMonth/=expected_day_in_month) &
       error stop 'projected day-in-month does not match weaving prefix'

  write(*,'(A,A)') 'STAGE01_FOUNDATION_CANDIDATE_CALCULATION_DAY=',trim(bi_to_string(calculation_day))
  write(*,'(A,A)') 'STAGE01_FOUNDATION_CANDIDATE_TARGET_DAY=',trim(bi_to_string(target_day))
  write(*,'(A,A,A,I0,A,I0,A,I0,A,I0)') 'STAGE01_FOUNDATION_CANDIDATE_FIELDS=', &
       trim(bi_to_string(fields%yearNumber)),',',fields%cutletCanonicalIndex,',', &
       fields%dayInCutlet,',',fields%monthCanonicalIndex,',',fields%dayInMonth
  write(*,'(A,I0)') 'STAGE01_FOUNDATION_CANDIDATE_CUTLET_POSITION=',cutlet_position
  write(*,'(A,I0)') 'STAGE01_FOUNDATION_CANDIDATE_MONTH_ID=',month_id
  write(*,'(A,A)') 'STAGE01_FOUNDATION_CANDIDATE_YEAR_NUMBER=',trim(bi_to_string(year%number))
  write(*,'(A,I0)') 'STAGE01_FOUNDATION_CANDIDATE_MONTH_COUNT=',structure%monthCount
  write(*,'(A,I0)') 'STAGE01_FOUNDATION_CANDIDATE_DAY_COUNT=',days
  write(*,'(A,I0,A,I0)') 'STAGE01_FOUNDATION_CANDIDATE_GATE_INDICES=', &
       year%openGateIndex,',',year%closeGateIndex
  write(*,'(A,A,A,A)') 'STAGE01_FOUNDATION_CANDIDATE_GATE_DAYS=', &
       trim(bi_to_string(year%openGateDay)),',',trim(bi_to_string(year%closeGateDay))
  call print_int_array('STAGE01_FOUNDATION_CANDIDATE_CUTLET_PARTITION=',structure%cutletPartition)
  call print_int_array('STAGE01_FOUNDATION_CANDIDATE_CUTLET_NAME_INDICES=',structure%cutletNameIndices)
  call print_big_array('STAGE01_FOUNDATION_CANDIDATE_CUTLET_FIRST_DAYS=',structure%cutletFirstDays)
  call print_big_array('STAGE01_FOUNDATION_CANDIDATE_CUTLET_LAST_DAYS=',structure%cutletLastDays)
  call print_int_array('STAGE01_FOUNDATION_CANDIDATE_MONTH_LENGTHS=',structure%monthLengths)
  call print_int_array('STAGE01_FOUNDATION_CANDIDATE_MONTH_NAME_INDICES=',structure%monthNameIndices)
  call print_int_array('STAGE01_FOUNDATION_CANDIDATE_MONTH_WEAVING=',structure%monthWeaving)
  write(*,'(A)') 'STAGE01_FOUNDATION_CANDIDATE_INVARIANTS=PASS'
  write(*,'(A)') 'STAGE01_FOUNDATION_CANDIDATE_ONLY_NOT_CANONICAL'

contains

  subroutine print_int_array(label,values)
    character(len=*), intent(in) :: label
    integer, intent(in) :: values(:)
    integer :: k
    write(*,'(A)',advance='no') label
    do k=1,size(values)
       if (k>1) write(*,'(A)',advance='no') ','
       write(*,'(I0)',advance='no') values(k)
    end do
    write(*,*)
  end subroutine print_int_array

  subroutine print_big_array(label,values)
    character(len=*), intent(in) :: label
    type(BigInt), intent(in) :: values(:)
    integer :: k
    write(*,'(A)',advance='no') label
    do k=1,size(values)
       if (k>1) write(*,'(A)',advance='no') ','
       write(*,'(A)',advance='no') trim(bi_to_string(values(k)))
    end do
    write(*,*)
  end subroutine print_big_array

end program stage01_foundation_candidate_probe
