! QA-only adapter: one ORIGINAL Fortran year construction, all daily projections.
! Deliberately not a substitute for repeated normative_calendar_date entry calls.
program stage01_actual_45_full_year_probe
  use iso_fortran_env, only: int64
  use big_integer, only: BigInt, bi_add_small, bi_compare, bi_to_string
  use normative_oracle_core, only: foundation_day
  use normative_oracle_calendar, only: YearRecord, YearStructure, CalendarDateResult, &
       year5000, build_year_structure, project_calendar_date, reset_gate_cache
  implicit none
  type(BigInt) :: calculation_day, target
  type(YearRecord) :: year
  type(YearStructure) :: structure
  type(CalendarDateResult) :: fields
  integer :: i, days
  integer, allocatable :: month_occurrences(:)

  if (command_argument_count() /= 0) error stop 'no arguments permitted'
  calculation_day=foundation_day()
  call reset_gate_cache()
  year=year5000(calculation_day)
  structure=build_year_structure(calculation_day,year)
  days=size(structure%monthWeaving)
  if (structure%monthCount /= 45 .or. days /= 4244) error stop 'unexpected actual year 5000'
  if (size(structure%monthLengths) /= 45 .or. size(structure%monthNameIndices) /= 45) &
       error stop 'month structures mismatch'
  if (bi_compare(bi_add_small(year%openGateDay,int(days,int64)),year%closeGateDay) /= 0) &
       error stop 'actual gate span mismatch'
  if (sum(structure%monthLengths) /= days) error stop 'actual lengths do not cover year'
  allocate(month_occurrences(45))
  month_occurrences=0
  write(*,'(A,A,A,A,A,A,A,I0,A,I0)') 'STAGE01_45_META=', &
       trim(bi_to_string(year%number)),',',trim(bi_to_string(year%openGateDay)),',', &
       trim(bi_to_string(year%closeGateDay)),',',days,',',structure%monthCount
  write(*,'(A)',advance='no') 'STAGE01_45_LENGTHS='
  do i=1,45
     if (i>1) write(*,'(A)',advance='no') ','
     write(*,'(I0)',advance='no') structure%monthLengths(i)
  end do
  write(*,*)
  do i=1,days
     if (structure%monthWeaving(i)<1 .or. structure%monthWeaving(i)>45) &
          error stop 'invalid month ID'
     month_occurrences(structure%monthWeaving(i))=month_occurrences(structure%monthWeaving(i))+1
     target=bi_add_small(year%openGateDay,int(i,int64))
     fields=project_calendar_date(target,year,structure)
     write(*,'(A,I0,A,I0,A,A,A,I0,A,I0,A,I0,A,I0)') 'STAGE01_45_ROW=',i,',', &
          structure%monthWeaving(i),',',trim(bi_to_string(fields%yearNumber)),',', &
          fields%cutletCanonicalIndex,',',fields%dayInCutlet,',', &
          fields%monthCanonicalIndex,',',fields%dayInMonth
  end do
  if (any(month_occurrences /= structure%monthLengths)) &
       error stop 'actual month frequency mismatch'
  write(*,'(A,I0)') 'STAGE01_45_DONE=',days
end program stage01_actual_45_full_year_probe
