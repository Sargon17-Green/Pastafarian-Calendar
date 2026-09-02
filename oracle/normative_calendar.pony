use "../src"
use "collections"

class YearPair
  let open_index: BigInt
  let close_index: BigInt
  let length: BigInt
  let open_day: BigInt

  new create(open_index': BigInt, close_index': BigInt, length': BigInt, open_day': BigInt) =>
    open_index = open_index'
    close_index = close_index'
    length = length'
    open_day = open_day'

class NormativeGateStore
  let gates: Map[String, BigInt] = Map[String, BigInt]
  var min_known: BigInt = BigInt.from_u64(0)
  var max_known: BigInt = BigInt.from_u64(0)

  new create() =>
    gates("0") = NormativeConstants.foundation_day()

  fun ref _known(index: BigInt box): BigInt ? => gates(index.string())?

  fun ref one_gap(signed_step: BigInt box): BigInt ? =>
    if signed_step.is_zero() then error end
    let f = NormativeConstants.foundation_day()
    let q = if signed_step.is_negative() then f.sub(signed_step.abs()) else f.add(signed_step.abs()) end
    let sauce = NormativeSauce(f, q)?
    let stream = NormativeAnswers.ask(sauce, 1, 1)?
    NormativeSelection.choose(stream, BigInt.from_u64(922))?.add(BigInt.from_u64(41))

  fun ref ensure_index(index: BigInt box): BigInt ? =>
    if index.gt(max_known) then
      var n = max_known.add(BigInt.from_u64(1))
      while n.lte(index) do
        let prev_index = n.sub(BigInt.from_u64(1))
        let prev = _known(prev_index)?
        let value = prev.add(one_gap(n)?)
        gates(n.string()) = value
        max_known = BigInt.from_parts(false, n.string())
        n = n.add(BigInt.from_u64(1))
      end
    end
    if index.lt(min_known) then
      var n = min_known.sub(BigInt.from_u64(1))
      while n.gte(index) do
        let next_index = n.add(BigInt.from_u64(1))
        let next_value = _known(next_index)?
        let value = next_value.sub(one_gap(n)?)
        gates(n.string()) = value
        min_known = BigInt(n.string())?
        n = n.sub(BigInt.from_u64(1))
      end
    end
    _known(index)?

  fun ref ensure_cover(low_day: BigInt box, high_day: BigInt box) ? =>
    if low_day.gt(high_day) then error end
    while _known(min_known)?.gt(low_day) do
      ensure_index(min_known.sub(BigInt.from_u64(1)))?
    end
    while _known(max_known)?.lt(high_day) do
      ensure_index(max_known.add(BigInt.from_u64(1)))?
    end

  fun ref index_at_or_before(day: BigInt box): BigInt ? =>
    ensure_cover(day, day)?
    var lo = BigInt(min_known.string())?
    var hi = BigInt(max_known.string())?
    let two = BigInt.from_u64(2)
    while lo.lt(hi) do
      let span = hi.sub(lo).add(BigInt.from_u64(1))
      let mid = lo.add(span.floor_div(two)?)
      if _known(mid)?.lte(day) then
        lo = mid
      else
        hi = mid.sub(BigInt.from_u64(1))
      end
    end
    lo

  fun ref index_at_or_after(day: BigInt box): BigInt ? =>
    let i = index_at_or_before(day)?
    if _known(i)?.eqv(day) then i else i.add(BigInt.from_u64(1)) end

  fun ref exact_index(day: BigInt box): (BigInt | None) ? =>
    let i = index_at_or_before(day)?
    if _known(i)?.eqv(day) then i else None end

  fun ref gate(index: BigInt box): BigInt ? => ensure_index(index)?

class NormativeCalendarOracle
  let gate_store: NormativeGateStore = NormativeGateStore

  fun ref _year_length(open_index: BigInt box, close_index: BigInt box): BigInt ? =>
    gate_store.gate(close_index)?.sub(gate_store.gate(open_index)?)

  fun ref _valid_year_pair(open_index: BigInt box, close_index: BigInt box): Bool ? =>
    let gaps = close_index.sub(open_index)
    if gaps.lt(BigInt.from_u64(6)) then return false end
    let len = _year_length(open_index, close_index)?
    len.gte(BigInt.from_usize(NormativeConstants.year_min_days())) and len.lte(BigInt.from_usize(NormativeConstants.year_max_days()))

  fun _insert_pair_sorted(list: Array[YearPair] ref, pair: YearPair, opening_tie: Bool) ? =>
    var pos = list.size()
    list.push(pair)
    while pos > 0 do
      let prev = list(pos - 1)?
      var move = prev.length.gt(pair.length)
      if opening_tie and prev.length.eqv(pair.length) and prev.open_day.gt(pair.open_day) then move = true end
      if not move then break end
      list.update(pos, prev)?
      pos = pos - 1
    end
    list.update(pos, pair)?

  fun ref year5000(calculation_day: BigInt box): Year ? =>
    let radius = BigInt.from_usize(NormativeConstants.year_max_days())
    gate_store.ensure_cover(calculation_day.sub(radius), calculation_day.add(radius))?
    let candidates = Array[YearPair]
    var i = BigInt(gate_store.min_known.string())?
    while i.lt(gate_store.max_known) do
      var j = i.add(BigInt.from_u64(1))
      while j.lte(gate_store.max_known) do
        if _valid_year_pair(i, j)? then
          let open_day = gate_store.gate(i)?
          let close_day = gate_store.gate(j)?
          if open_day.lt(calculation_day) and calculation_day.lte(close_day) then
            _insert_pair_sorted(candidates, YearPair(i, j, close_day.sub(open_day), open_day), true)?
          end
        end
        j = j.add(BigInt.from_u64(1))
      end
      i = i.add(BigInt.from_u64(1))
    end
    if candidates.size() == 0 then error end
    let sauce = NormativeSauce(calculation_day, calculation_day)?
    let stream = NormativeAnswers.ask(sauce, 1, 10)?
    let rank = NormativeSelection.choose(stream, BigInt.from_usize(candidates.size()))?.to_usize()?
    let chosen = candidates(rank - 1)?
    Year(BigInt.from_u64(5000), chosen.open_index, chosen.close_index, gate_store.gate(chosen.open_index)?, gate_store.gate(chosen.close_index)?)

  fun ref next_year(calculation_day: BigInt box, known: Year): Year ? =>
    let open_index = known.close_gate_index
    let open_day = gate_store.gate(open_index)?
    let candidates = Array[YearPair]
    var close_index = open_index.add(BigInt.from_u64(1))
    while true do
      let close_day = gate_store.gate(close_index)?
      let len = close_day.sub(open_day)
      if len.gt(BigInt.from_usize(NormativeConstants.year_max_days())) then break end
      if _valid_year_pair(open_index, close_index)? then
        _insert_pair_sorted(candidates, YearPair(open_index, close_index, len, open_day), false)?
      end
      close_index = close_index.add(BigInt.from_u64(1))
    end
    if candidates.size() == 0 then error end
    let sauce = NormativeSauce(calculation_day, open_day)?
    let stream = NormativeAnswers.ask(sauce, 1, 11)?
    let rank = NormativeSelection.choose(stream, BigInt.from_usize(candidates.size()))?.to_usize()?
    let chosen = candidates(rank - 1)?
    Year(known.number.add(BigInt.from_u64(1)), open_index, chosen.close_index, open_day, gate_store.gate(chosen.close_index)?)

  fun ref previous_year(calculation_day: BigInt box, known: Year): Year ? =>
    let close_index = known.open_gate_index
    let close_day = gate_store.gate(close_index)?
    let candidates = Array[YearPair]
    var open_index = close_index.sub(BigInt.from_u64(1))
    while true do
      let open_day = gate_store.gate(open_index)?
      let len = close_day.sub(open_day)
      if len.gt(BigInt.from_usize(NormativeConstants.year_max_days())) then break end
      if _valid_year_pair(open_index, close_index)? then
        _insert_pair_sorted(candidates, YearPair(open_index, close_index, len, open_day), false)?
      end
      open_index = open_index.sub(BigInt.from_u64(1))
    end
    if candidates.size() == 0 then error end
    let sauce = NormativeSauce(calculation_day, close_day)?
    let stream = NormativeAnswers.ask(sauce, 1, 12)?
    let rank = NormativeSelection.choose(stream, BigInt.from_usize(candidates.size()))?.to_usize()?
    let chosen = candidates(rank - 1)?
    Year(known.number.sub(BigInt.from_u64(1)), chosen.open_index, close_index, gate_store.gate(chosen.open_index)?, close_day)

  fun ref find_target_year(calculation_day: BigInt box, target_day: BigInt box): Year ? =>
    var y = year5000(calculation_day)?
    while target_day.gt(y.close_gate_day) do y = next_year(calculation_day, y)? end
    while target_day.lte(y.open_gate_day) do y = previous_year(calculation_day, y)? end
    if not (y.open_gate_day.lt(target_day) and target_day.lte(y.close_gate_day)) then error end
    y

  fun ref choose_cutlet_count(r: SauceResult, year: Year): USize ? =>
    let gaps = year.close_gate_index.sub(year.open_gate_index).to_usize()?
    let candidates = Array[USize]
    var k: USize = 6
    while k <= 17 do
      if k <= gaps then candidates.push(k) end
      k = k + 1
    end
    let stream = NormativeAnswers.ask(r, 2, 20)?
    let rank = NormativeSelection.choose(stream, BigInt.from_usize(candidates.size()))?.to_usize()?
    candidates(rank - 1)?

  fun ref choose_cutlet_partition(calculation_day: BigInt box, r: SauceResult, year: Year, cutlet_count: USize): Array[USize] ? =>
    let gaps = year.close_gate_index.sub(year.open_gate_index).to_usize()?
    var required: (USize | None) = None
    match gate_store.exact_index(calculation_day)?
    | let g: BigInt =>
      if g.gt(year.open_gate_index) and g.lt(year.close_gate_index) then
        required = g.sub(year.open_gate_index).to_usize()?
      end
    | None => None
    end
    let family = CutletPartitionCounter(gaps, cutlet_count, required)
    let stream = NormativeAnswers.ask(r, 2, 21)?
    let rank = NormativeSelection.choose(stream, family.count_all())?
    family.unrank1(rank)?

  fun choose_cutlet_names(r: SauceResult, cutlet_count: USize): Array[USize] ? =>
    let n = NormativeNames.falling_factorial(17, cutlet_count)
    let stream = NormativeAnswers.ask(r, 5, 22)?
    let rank = NormativeSelection.choose(stream, n)?
    NormativeNames.unrank_distinct(17, cutlet_count, rank)?

  fun ref materialize_cutlets(year: Year, partition: Array[USize] box, names: Array[USize] box): Array[Cutlet] ? =>
    let out = Array[Cutlet](partition.size())
    var cursor = BigInt(year.open_gate_index.string())?
    var k: USize = 0
    while k < partition.size() do
      let open_index = cursor
      let close_index = cursor.add(BigInt.from_usize(partition(k)?))
      out.push(Cutlet(names(k)?, open_index, close_index, gate_store.gate(open_index)?.add(BigInt.from_u64(1)), gate_store.gate(close_index)?))
      cursor = close_index
      k = k + 1
    end
    out

  fun choose_month_count(r: SauceResult, year: Year): USize ? =>
    let len = year.close_gate_day.sub(year.open_gate_day).to_usize()?
    let low = NormativeArithmetic.ceil_div_usize(len, 123)
    let high = USize(47).min(len / 4)
    if (low < 3) or (low > high) then error end
    let stream = NormativeAnswers.ask(r, 3, 30)?
    let rank = NormativeSelection.choose(stream, BigInt.from_usize((high - low) + 1))?.to_usize()?
    low + rank - 1

  fun choose_month_lengths(r: SauceResult, year: Year, month_count: USize): Array[USize] ? =>
    let len = year.close_gate_day.sub(year.open_gate_day).to_usize()?
    let family = BoundedCompositionCounter(len, month_count, 4, 123)
    let stream = NormativeAnswers.ask(r, 3, 31)?
    let rank = NormativeSelection.choose(stream, family.count_all())?
    family.unrank1(rank)?

  fun choose_month_weaving(r: SauceResult, lengths: Array[USize]): Array[USize] ? =>
    let family = WeavingCounter(lengths)
    let count = family.count_all()?
    let stream = NormativeAnswers.ask(r, 4, 32)?
    let rank = NormativeSelection.choose(stream, count)?
    family.unrank1(rank)?

  fun choose_month_names(r: SauceResult, month_count: USize): Array[USize] ? =>
    let n = NormativeNames.falling_factorial(47, month_count)
    let stream = NormativeAnswers.ask(r, 5, 33)?
    let rank = NormativeSelection.choose(stream, n)?
    NormativeNames.unrank_distinct(47, month_count, rank)?

  fun ref build_year_structure(calculation_day: BigInt box, year: Year): YearStructure ? =>
    let first_day = year.open_gate_day.add(BigInt.from_u64(1))
    let r = NormativeSauce(calculation_day, first_day)?
    let cutlet_count = choose_cutlet_count(r, year)?
    let partition = choose_cutlet_partition(calculation_day, r, year, cutlet_count)?
    let cutlet_names = choose_cutlet_names(r, cutlet_count)?
    let cutlets = materialize_cutlets(year, partition, cutlet_names)?
    let month_count = choose_month_count(r, year)?
    let month_lengths = choose_month_lengths(r, year, month_count)?
    let weaving = choose_month_weaving(r, month_lengths)?
    let month_names = choose_month_names(r, month_count)?
    YearStructure(year, cutlet_count, partition, cutlet_names, cutlets, month_count, month_lengths, weaving, month_names)

  fun ref calendar_date(calculation_day: BigInt box, target_day: BigInt box): CalendarTuple ? =>
    let year = find_target_year(calculation_day, target_day)?
    let structure = build_year_structure(calculation_day, year)?
    var chosen: (Cutlet | None) = None
    for c in structure.cutlets.values() do
      if c.first_day.lte(target_day) and target_day.lte(c.last_day) then
        chosen = c
        break
      end
    end
    let cutlet = match chosen | let c: Cutlet => c | None => error end
    let day_in_cutlet = target_day.sub(cutlet.first_day).add(BigInt.from_u64(1))
    let offset = target_day.sub(year.open_gate_day.add(BigInt.from_u64(1))).to_usize()?
    let month_id = structure.month_weaving(offset)?
    let month_index = structure.month_name_indices(month_id - 1)?
    var day_in_month: USize = 0
    var p: USize = 0
    while p <= offset do
      if structure.month_weaving(p)? == month_id then day_in_month = day_in_month + 1 end
      p = p + 1
    end
    CalendarTuple(year.number, cutlet.name_index, day_in_cutlet, month_index, day_in_month)

  fun ref present(calculation_day: BigInt box, target_day: BigInt box): Array[String] ? =>
    let x = calendar_date(calculation_day, target_day)?
    [
      x.year_number.string()
      SourceLanguageCatalog.cutlet_text(x.cutlet_index)?
      x.day_in_cutlet.string()
      SourceLanguageCatalog.month_text(x.month_index)?
      x.day_in_month.string()
    ]
