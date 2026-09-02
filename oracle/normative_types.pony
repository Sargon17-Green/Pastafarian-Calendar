use "../src"
class WorkCounts
  let action: BigInt
  let target: BigInt
  let distance: BigInt
  let connection: BigInt
  let direction: BigInt

  new create(action': BigInt, target': BigInt, distance': BigInt, connection': BigInt, direction': BigInt) =>
    action = action'
    target = target'
    distance = distance'
    connection = connection'
    direction = direction'

class Stone
  let wheat: BigInt
  let barley: BigInt
  let salt: BigInt
  let bitter: BigInt
  let red: BigInt

  new create(wheat': BigInt, barley': BigInt, salt': BigInt, bitter': BigInt, red': BigInt) =>
    wheat = wheat'
    barley = barley'
    salt = salt'
    bitter = bitter'
    red = red'

  fun box at(kind: USize): BigInt ? =>
    match kind
    | 1 => wheat
    | 2 => barley
    | 3 => salt
    | 4 => bitter
    | 5 => red
    else error
    end

class SauceResult
  let bowls: Array[BigInt]
  let order_at_drop_46: Array[USize]

  new create(bowls': Array[BigInt], order': Array[USize]) =>
    bowls = bowls'
    order_at_drop_46 = order'

class AnswerStream
  let first: BigInt
  let direction_step: I8

  new create(first': BigInt, direction_step': I8) =>
    first = first'
    direction_step = direction_step'

class Year
  let number: BigInt
  let open_gate_index: BigInt
  let close_gate_index: BigInt
  let open_gate_day: BigInt
  let close_gate_day: BigInt

  new create(number': BigInt, open_index': BigInt, close_index': BigInt, open_day': BigInt, close_day': BigInt) =>
    number = number'
    open_gate_index = open_index'
    close_gate_index = close_index'
    open_gate_day = open_day'
    close_gate_day = close_day'

class Cutlet
  let name_index: USize
  let open_gate_index: BigInt
  let close_gate_index: BigInt
  let first_day: BigInt
  let last_day: BigInt

  new create(name_index': USize, open_index': BigInt, close_index': BigInt, first_day': BigInt, last_day': BigInt) =>
    name_index = name_index'
    open_gate_index = open_index'
    close_gate_index = close_index'
    first_day = first_day'
    last_day = last_day'

class YearStructure
  let year: Year
  let cutlet_count: USize
  let cutlet_partition: Array[USize]
  let cutlet_name_indices: Array[USize]
  let cutlets: Array[Cutlet]
  let month_count: USize
  let month_lengths: Array[USize]
  let month_weaving: Array[USize]
  let month_name_indices: Array[USize]

  new create(
    year': Year,
    cutlet_count': USize,
    cutlet_partition': Array[USize],
    cutlet_name_indices': Array[USize],
    cutlets': Array[Cutlet],
    month_count': USize,
    month_lengths': Array[USize],
    month_weaving': Array[USize],
    month_name_indices': Array[USize]) =>
    year = year'
    cutlet_count = cutlet_count'
    cutlet_partition = cutlet_partition'
    cutlet_name_indices = cutlet_name_indices'
    cutlets = cutlets'
    month_count = month_count'
    month_lengths = month_lengths'
    month_weaving = month_weaving'
    month_name_indices = month_name_indices'

class CalendarTuple
  let year_number: BigInt
  let cutlet_index: USize
  let day_in_cutlet: BigInt
  let month_index: USize
  let day_in_month: USize

  new create(year_number': BigInt, cutlet_index': USize, day_in_cutlet': BigInt, month_index': USize, day_in_month': USize) =>
    year_number = year_number'
    cutlet_index = cutlet_index'
    day_in_cutlet = day_in_cutlet'
    month_index = month_index'
    day_in_month = day_in_month'
