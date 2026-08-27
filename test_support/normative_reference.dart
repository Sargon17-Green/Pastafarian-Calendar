import '../lib/src/source_language_catalog.dart';

final class WorkCounts {
  final BigInt action;
  final BigInt target;
  final BigInt distance;
  final BigInt connection;
  final int direction;

  const WorkCounts({
    required this.action,
    required this.target,
    required this.distance,
    required this.connection,
    required this.direction,
  });
}

final class Stone {
  final BigInt wheat;
  final BigInt barley;
  final BigInt salt;
  final BigInt bitter;
  final BigInt red;

  const Stone(this.wheat, this.barley, this.salt, this.bitter, this.red);

  BigInt byKind(int kind) {
    switch (kind) {
      case 1:
        return wheat;
      case 2:
        return barley;
      case 3:
        return salt;
      case 4:
        return bitter;
      case 5:
        return red;
      default:
        throw RangeError.range(kind, 1, 5, 'kind');
    }
  }
}

final class SauceResult {
  final List<BigInt> bowls;
  final List<int> orderAtDrop46;

  SauceResult(List<BigInt> bowls, List<int> orderAtDrop46)
      : bowls = List<BigInt>.unmodifiable(bowls),
        orderAtDrop46 = List<int>.unmodifiable(orderAtDrop46);
}

final class AnswerStream {
  final BigInt first;
  final int directionStep;

  const AnswerStream(this.first, this.directionStep);
}

final class Year {
  final BigInt number;
  final BigInt openGateIndex;
  final BigInt closeGateIndex;
  final BigInt openGateDay;
  final BigInt closeGateDay;

  const Year({
    required this.number,
    required this.openGateIndex,
    required this.closeGateIndex,
    required this.openGateDay,
    required this.closeGateDay,
  });
}

final class Cutlet {
  final int nameCanonicalIndex;
  final BigInt openGateIndex;
  final BigInt closeGateIndex;
  final BigInt firstDay;
  final BigInt lastDay;

  const Cutlet({
    required this.nameCanonicalIndex,
    required this.openGateIndex,
    required this.closeGateIndex,
    required this.firstDay,
    required this.lastDay,
  });
}

final class YearStructure {
  final int cutletCount;
  final List<BigInt> cutletPartition;
  final List<int> cutletNameCanonicalIndices;
  final List<Cutlet> cutlets;
  final int monthCount;
  final List<BigInt> monthLengths;
  final List<int> monthWeaving;
  final List<int> monthNameCanonicalIndices;

  YearStructure({
    required this.cutletCount,
    required List<BigInt> cutletPartition,
    required List<int> cutletNameCanonicalIndices,
    required List<Cutlet> cutlets,
    required this.monthCount,
    required List<BigInt> monthLengths,
    required List<int> monthWeaving,
    required List<int> monthNameCanonicalIndices,
  })  : cutletPartition = List<BigInt>.unmodifiable(cutletPartition),
        cutletNameCanonicalIndices =
            List<int>.unmodifiable(cutletNameCanonicalIndices),
        cutlets = List<Cutlet>.unmodifiable(cutlets),
        monthLengths = List<BigInt>.unmodifiable(monthLengths),
        monthWeaving = List<int>.unmodifiable(monthWeaving),
        monthNameCanonicalIndices =
            List<int>.unmodifiable(monthNameCanonicalIndices);
}

final class CalendarTuple {
  final BigInt yearNumber;
  final String cutletName;
  final BigInt dayInCutlet;
  final String monthName;
  final BigInt dayInMonth;

  const CalendarTuple({
    required this.yearNumber,
    required this.cutletName,
    required this.dayInCutlet,
    required this.monthName,
    required this.dayInMonth,
  });

  List<Object> asFiveFields() => <Object>[
        yearNumber,
        cutletName,
        dayInCutlet,
        monthName,
        dayInMonth,
      ];
}

final class _VisibleGrindRow {
  final BigInt a;
  final BigInt b;
  final BigInt c;
  final BigInt d;
  final int stoneKind;

  const _VisibleGrindRow(this.a, this.b, this.c, this.d, this.stoneKind);
}

final class _YearPair {
  final BigInt openIndex;
  final BigInt closeIndex;

  const _YearPair(this.openIndex, this.closeIndex);
}

final class _BoundedCompositionCounter {
  final BigInt total;
  final int slots;
  final BigInt lo;
  final BigInt hi;
  final Map<String, BigInt> _memo = <String, BigInt>{};

  _BoundedCompositionCounter(this.total, this.slots, this.lo, this.hi);

  BigInt _count(BigInt remaining, int remainingSlots) {
    if (remainingSlots == 0) {
      return remaining == BigInt.zero ? BigInt.one : BigInt.zero;
    }
    if (remaining < lo * BigInt.from(remainingSlots) ||
        remaining > hi * BigInt.from(remainingSlots)) {
      return BigInt.zero;
    }
    final key = '${remaining.toString()}:$remainingSlots';
    final found = _memo[key];
    if (found != null) {
      return found;
    }
    var sum = BigInt.zero;
    var x = lo;
    while (x <= hi) {
      sum += _count(remaining - x, remainingSlots - 1);
      x += BigInt.one;
    }
    _memo[key] = sum;
    return sum;
  }

  BigInt countAll() => _count(total, slots);

  List<BigInt> unrank1(BigInt rank1) {
    final count = countAll();
    if (rank1 < BigInt.one || rank1 > count) {
      throw RangeError('הדרגה מחוץ למשפחה החסומה.');
    }
    var rank = rank1;
    var remaining = total;
    final result = <BigInt>[];
    for (var position = 0; position < slots; position++) {
      var x = lo;
      while (x <= hi) {
        final block = _count(remaining - x, slots - position - 1);
        if (rank > block) {
          rank -= block;
        } else {
          result.add(x);
          remaining -= x;
          break;
        }
        x += BigInt.one;
      }
    }
    return result;
  }
}

final class _CutletPartitionFamily {
  final BigInt totalGaps;
  final int slots;
  final BigInt? requiredBoundary;
  final Map<String, BigInt> _memo = <String, BigInt>{};

  _CutletPartitionFamily(this.totalGaps, this.slots, this.requiredBoundary);

  BigInt _count(
    BigInt remaining,
    int remainingSlots,
    BigInt cumulative,
    bool hitBoundary,
  ) {
    if (remainingSlots == 0) {
      if (remaining != BigInt.zero) {
        return BigInt.zero;
      }
      if (requiredBoundary == null) {
        return BigInt.one;
      }
      return hitBoundary ? BigInt.one : BigInt.zero;
    }
    if (remaining < BigInt.from(remainingSlots)) {
      return BigInt.zero;
    }
    final key = '${remaining.toString()}:$remainingSlots:'
        '${cumulative.toString()}:${hitBoundary ? 1 : 0}';
    final found = _memo[key];
    if (found != null) {
      return found;
    }
    var total = BigInt.zero;
    final maxX = remaining - BigInt.from(remainingSlots - 1);
    var x = BigInt.one;
    while (x <= maxX) {
      final nextCumulative = cumulative + x;
      var nextHit = hitBoundary;
      if (requiredBoundary != null && !hitBoundary) {
        if (nextCumulative == requiredBoundary) {
          nextHit = true;
        } else if (nextCumulative > requiredBoundary!) {
          x += BigInt.one;
          continue;
        }
      }
      total += _count(
        remaining - x,
        remainingSlots - 1,
        nextCumulative,
        nextHit,
      );
      x += BigInt.one;
    }
    _memo[key] = total;
    return total;
  }

  BigInt countAll() => _count(totalGaps, slots, BigInt.zero, false);

  List<BigInt> unrank1(BigInt rank1) {
    final totalCount = countAll();
    if (rank1 < BigInt.one || rank1 > totalCount) {
      throw RangeError('הדרגה מחוץ למשפחת חלוקות הקציצות.');
    }
    var rank = rank1;
    var remaining = totalGaps;
    var remainingSlots = slots;
    var cumulative = BigInt.zero;
    var hit = false;
    final result = <BigInt>[];
    while (remainingSlots > 0) {
      final maxX = remaining - BigInt.from(remainingSlots - 1);
      var x = BigInt.one;
      while (x <= maxX) {
        final nextCumulative = cumulative + x;
        var nextHit = hit;
        if (requiredBoundary != null && !hit) {
          if (nextCumulative == requiredBoundary) {
            nextHit = true;
          } else if (nextCumulative > requiredBoundary!) {
            x += BigInt.one;
            continue;
          }
        }
        final block = _count(
          remaining - x,
          remainingSlots - 1,
          nextCumulative,
          nextHit,
        );
        if (rank > block) {
          rank -= block;
        } else {
          result.add(x);
          remaining -= x;
          remainingSlots -= 1;
          cumulative = nextCumulative;
          hit = nextHit;
          break;
        }
        x += BigInt.one;
      }
    }
    return result;
  }
}

final class _WeaveState {
  final List<BigInt> remaining;
  final int openedUpTo;
  final int closedUpTo;

  _WeaveState(this.remaining, this.openedUpTo, this.closedUpTo);

  String key() => '${remaining.join(',')}|$openedUpTo|$closedUpTo';
}

final class _WeavingCounter {
  final List<BigInt> lengths;
  final Map<String, BigInt> _memo = <String, BigInt>{};

  _WeavingCounter(List<BigInt> lengths)
      : lengths = List<BigInt>.unmodifiable(lengths);

  _WeaveState initialState() => _WeaveState(
        List<BigInt>.from(lengths),
        0,
        0,
      );

  bool _legal(_WeaveState state, int monthId) {
    final index = monthId - 1;
    if (state.remaining[index] == BigInt.zero) {
      return false;
    }
    final alreadyOpened = state.remaining[index] < lengths[index];
    if (!alreadyOpened && monthId != state.openedUpTo + 1) {
      return false;
    }
    final willClose = state.remaining[index] == BigInt.one;
    if (willClose && monthId != state.closedUpTo + 1) {
      return false;
    }
    return true;
  }

  _WeaveState _apply(_WeaveState state, int monthId) {
    final nextRemaining = List<BigInt>.from(state.remaining);
    final index = monthId - 1;
    var opened = state.openedUpTo;
    var closed = state.closedUpTo;
    if (nextRemaining[index] == lengths[index]) {
      opened = monthId;
    }
    nextRemaining[index] -= BigInt.one;
    if (nextRemaining[index] == BigInt.zero) {
      closed = monthId;
    }
    return _WeaveState(nextRemaining, opened, closed);
  }

  BigInt count(_WeaveState state) {
    var allZero = true;
    for (final value in state.remaining) {
      if (value != BigInt.zero) {
        allZero = false;
        break;
      }
    }
    if (allZero) {
      return BigInt.one;
    }
    final key = state.key();
    final found = _memo[key];
    if (found != null) {
      return found;
    }
    var total = BigInt.zero;
    for (var monthId = 1; monthId <= lengths.length; monthId++) {
      if (_legal(state, monthId)) {
        total += count(_apply(state, monthId));
      }
    }
    _memo[key] = total;
    return total;
  }

  List<int> unrank1(BigInt rank1) {
    var state = initialState();
    final total = count(state);
    if (rank1 < BigInt.one || rank1 > total) {
      throw RangeError('הדרגה מחוץ למשפחת שזירות החודשים.');
    }
    var rank = rank1;
    var totalLength = BigInt.zero;
    for (final length in lengths) {
      totalLength += length;
    }
    if (totalLength > BigInt.from(10000000)) {
      throw StateError('השזירה גדולה מדי לחומרה בזיכרון בבדיקת הייחוס הזאת.');
    }
    final wantedLength = totalLength.toInt();
    final result = <int>[];
    while (result.length < wantedLength) {
      for (var monthId = 1; monthId <= lengths.length; monthId++) {
        if (!_legal(state, monthId)) {
          continue;
        }
        final next = _apply(state, monthId);
        final block = count(next);
        if (rank > block) {
          rank -= block;
        } else {
          result.add(monthId);
          state = next;
          break;
        }
      }
    }
    return result;
  }
}

final class NormativeReference {
  static final BigInt tabletsDay = BigInt.from(-278522);
  static final BigInt foundationDay = BigInt.from(-15055671);
  static final BigInt m = (BigInt.one << 127) - BigInt.one;
  static final BigInt gateGapMin = BigInt.from(42);
  static final BigInt gateGapMax = BigInt.from(963);
  static final BigInt yearMinDays = BigInt.from(252);
  static final BigInt yearMaxDays = BigInt.from(5778);

  static const int sealGateGap = 1;
  static const int sealYear5000 = 10;
  static const int sealNextYear = 11;
  static const int sealPreviousYear = 12;
  static const int sealCutletCount = 20;
  static const int sealCutletPartition = 21;
  static const int sealCutletNames = 22;
  static const int sealMonthCount = 30;
  static const int sealMonthLengths = 31;
  static const int sealMonthWeaving = 32;
  static const int sealMonthNames = 33;

  static const int wheat = 1;
  static const int barley = 2;
  static const int salt = 3;
  static const int bitter = 4;
  static const int red = 5;

  static final List<Stone> stones = buildStones();

  final Map<BigInt, BigInt> _gates = <BigInt, BigInt>{
    BigInt.zero: foundationDay,
  };
  BigInt _minKnownGateIndex = BigInt.zero;
  BigInt _maxKnownGateIndex = BigInt.zero;

  static BigInt floorDiv(BigInt a, BigInt b) {
    if (b == BigInt.zero) {
      throw ArgumentError('חלוקה באפס.');
    }
    var q = a ~/ b;
    final r = a.remainder(b);
    if (r != BigInt.zero && ((r.isNegative) != (b.isNegative))) {
      q -= BigInt.one;
    }
    return q;
  }

  static BigInt regularMod(BigInt x, BigInt d) {
    if (d < BigInt.one) {
      throw ArgumentError('המחלק חייב להיות חיובי.');
    }
    return x - floorDiv(x, d) * d;
  }

  static BigInt save(BigInt x) => BigInt.one + regularMod(x - BigInt.one, m);

  static BigInt square(BigInt x) => x * x;

  static BigInt ceilDiv(BigInt a, BigInt b) {
    if (a < BigInt.zero || b < BigInt.one) {
      throw ArgumentError('חלוקת תקרה דורשת מונה לא־שלילי ומכנה חיובי.');
    }
    return floorDiv(a + b - BigInt.one, b);
  }

  static int wrap1(int position, int size) {
    if (size < 1) {
      throw ArgumentError('גודל העטיפה חייב להיות חיובי.');
    }
    final p = BigInt.from(position);
    final s = BigInt.from(size);
    return (regularMod(p - BigInt.one, s) + BigInt.one).toInt();
  }

  static BigInt dayCount(BigInt day) {
    if (day == foundationDay) {
      return BigInt.one;
    }
    if (day > foundationDay) {
      return BigInt.from(2) * (day - foundationDay) + BigInt.one;
    }
    return BigInt.from(2) * (foundationDay - day);
  }

  static WorkCounts workCounts(BigInt calculationDay, BigInt targetDay) {
    final action = dayCount(calculationDay);
    final target = dayCount(targetDay);
    final distance = (targetDay - calculationDay).abs() + BigInt.one;
    final connection = action + target;
    final direction = targetDay < calculationDay
        ? 1
        : targetDay == calculationDay
            ? 2
            : 3;
    return WorkCounts(
      action: action,
      target: target,
      distance: distance,
      connection: connection,
      direction: direction,
    );
  }

  static List<Stone> buildStones() {
    final result = <Stone>[
      Stone(
        BigInt.from(17),
        BigInt.from(29),
        BigInt.from(43),
        BigInt.from(71),
        BigInt.from(101),
      ),
    ];
    for (var i = 2; i <= 46; i++) {
      final old = result[i - 2];
      final nextWheat = save(square(old.wheat) + BigInt.from(3) * old.barley + BigInt.from(i));
      final nextBarley = save(square(old.barley) + BigInt.from(5) * old.salt + old.wheat);
      final nextSalt = save(square(old.salt) + BigInt.from(7) * old.bitter + old.barley);
      final nextBitter = save(square(old.bitter) + BigInt.from(11) * old.red + old.salt);
      final nextRed = save(square(old.red) + BigInt.from(13) * old.wheat + old.bitter);
      result.add(Stone(nextWheat, nextBarley, nextSalt, nextBitter, nextRed));
    }
    return List<Stone>.unmodifiable(result);
  }

  static Stone _stoneAt(List<Stone> stoneTable, int oneBasedIndex) =>
      stoneTable[oneBasedIndex - 1];

  static List<BigInt> buildHiddenDrops(WorkCounts counts, List<Stone> stoneTable) {
    final coeff = <List<int>>[
      <int>[3, 4, 6, 8],
      <int>[5, 7, 10, 12],
      <int>[7, 10, 14, 16],
      <int>[9, 13, 18, 20],
      <int>[11, 16, 22, 24],
      <int>[13, 19, 26, 28],
      <int>[15, 22, 30, 32],
    ];
    final grindKinds = <int>[wheat, barley, salt, bitter, red, wheat, barley];
    final hidden = <BigInt>[];
    for (var k = 1; k <= 7; k++) {
      final c = coeff[k - 1];
      final stone = _stoneAt(stoneTable, k);
      var x = counts.action +
          BigInt.from(c[0]) * counts.target +
          BigInt.from(c[1]) * counts.distance +
          BigInt.from(c[2]) * counts.connection +
          BigInt.from(c[3]) * BigInt.from(counts.direction) +
          stone.wheat +
          stone.barley +
          stone.salt +
          stone.bitter +
          stone.red;
      x = save(x);
      for (var grind = 1; grind <= 7; grind++) {
        final oldX = x;
        x = save(
          square(oldX) +
              BigInt.from(3) * oldX +
              stone.byKind(grindKinds[grind - 1]) +
              BigInt.from(grind),
        );
      }
      hidden.add(x);
    }
    return hidden;
  }

  static final List<_VisibleGrindRow> _visibleGrinds = <_VisibleGrindRow>[
    _VisibleGrindRow(BigInt.from(3), BigInt.from(5), BigInt.from(7), BigInt.from(11), wheat),
    _VisibleGrindRow(BigInt.from(5), BigInt.from(7), BigInt.from(11), BigInt.from(13), barley),
    _VisibleGrindRow(BigInt.from(7), BigInt.from(11), BigInt.from(13), BigInt.from(17), salt),
    _VisibleGrindRow(BigInt.from(11), BigInt.from(13), BigInt.from(17), BigInt.from(19), bitter),
    _VisibleGrindRow(BigInt.from(13), BigInt.from(17), BigInt.from(19), BigInt.from(23), red),
    _VisibleGrindRow(BigInt.from(17), BigInt.from(19), BigInt.from(23), BigInt.from(29), wheat),
    _VisibleGrindRow(BigInt.from(19), BigInt.from(23), BigInt.from(29), BigInt.from(31), barley),
    _VisibleGrindRow(BigInt.from(23), BigInt.from(29), BigInt.from(31), BigInt.from(37), salt),
    _VisibleGrindRow(BigInt.from(29), BigInt.from(31), BigInt.from(37), BigInt.from(41), bitter),
    _VisibleGrindRow(BigInt.from(31), BigInt.from(37), BigInt.from(41), BigInt.from(43), red),
    _VisibleGrindRow(BigInt.from(37), BigInt.from(41), BigInt.from(43), BigInt.from(47), wheat),
  ];

  static List<BigInt> buildVisibleDrops(
    WorkCounts counts,
    List<Stone> stoneTable,
    List<BigInt> hidden,
  ) {
    final timeline = <int, BigInt>{};
    for (var k = 1; k <= 7; k++) {
      timeline[1 - k] = hidden[k - 1];
    }
    final visible = <BigInt>[];
    for (var i = 1; i <= 46; i++) {
      final prev1 = timeline[i - 1]!;
      final prev3 = timeline[i - 3]!;
      final prev7 = timeline[i - 7]!;
      final stone = _stoneAt(stoneTable, i);
      var x = save(
        stone.wheat * counts.action +
            stone.barley * counts.target +
            stone.salt * counts.distance +
            stone.bitter * counts.connection +
            stone.red * BigInt.from(counts.direction) +
            prev1 +
            BigInt.from(3) * prev3 +
            BigInt.from(5) * prev7 +
            BigInt.from(i),
      );
      for (final row in _visibleGrinds) {
        final oldX = x;
        x = save(
          square(oldX) +
              row.a * oldX +
              row.b * prev1 +
              row.c * prev3 +
              row.d * prev7 +
              stone.byKind(row.stoneKind),
        );
      }
      timeline[i] = x;
      visible.add(x);
    }
    return visible;
  }

  static BigInt factorial(int n) {
    if (n < 0) {
      throw ArgumentError('עצרת אינה מוגדרת כאן למספר שלילי.');
    }
    var result = BigInt.one;
    for (var i = 2; i <= n; i++) {
      result *= BigInt.from(i);
    }
    return result;
  }

  static List<int> permutationUnrank1(BigInt rank1, List<int> itemsAscending) {
    final n = itemsAscending.length;
    final total = factorial(n);
    if (rank1 < BigInt.one || rank1 > total) {
      throw RangeError('דרגת התמורה מחוץ לטווח.');
    }
    var rank0 = rank1 - BigInt.one;
    final remaining = List<int>.from(itemsAscending);
    final result = <int>[];
    for (var slotsLeft = n; slotsLeft >= 1; slotsLeft--) {
      final block = factorial(slotsLeft - 1);
      final q = floorDiv(rank0, block).toInt();
      rank0 = regularMod(rank0, block);
      result.add(remaining.removeAt(q));
    }
    return result;
  }

  static List<int> bowlOrderFromNumber(int orderNumber) {
    if (orderNumber < 1 || orderNumber > 720) {
      throw RangeError.range(orderNumber, 1, 720, 'orderNumber');
    }
    return permutationUnrank1(
      BigInt.from(orderNumber),
      const <int>[1, 2, 3, 4, 5, 6],
    );
  }

  static List<int> bowlOrderFromDrop(BigInt dropValue) {
    final orderNumber = regularMod(dropValue - BigInt.one, BigInt.from(720)) + BigInt.one;
    return bowlOrderFromNumber(orderNumber.toInt());
  }

  static List<BigInt> initialBowls(WorkCounts counts) {
    final primes = <int>[17, 19, 23, 29, 31, 37];
    final bowls = List<BigInt>.filled(7, BigInt.zero);
    for (var bowlId = 1; bowlId <= 6; bowlId++) {
      final s = counts.action +
          counts.target * BigInt.from(bowlId) +
          counts.distance +
          counts.connection +
          BigInt.from(counts.direction) +
          square(BigInt.from(primes[bowlId - 1]));
      bowls[bowlId] = save(square(s) + BigInt.from(bowlId));
    }
    return bowls;
  }

  static SauceResult applyVisibleDropsToBowls(
    List<BigInt> initial,
    List<BigInt> visible,
    List<Stone> stoneTable,
  ) {
    var bowls = List<BigInt>.from(initial);
    List<int>? orderAtDrop46;
    const stirStoneByPosition = <int>[wheat, barley, salt, bitter, red, wheat];
    for (var i = 1; i <= 46; i++) {
      final drop = visible[i - 1];
      final order = bowlOrderFromDrop(drop);
      final old = List<BigInt>.from(bowls);
      final pour = List<BigInt>.filled(7, BigInt.zero);
      final stone = _stoneAt(stoneTable, i);
      pour[1] = save(square(drop) + stone.wheat * old[order[0]] + BigInt.from(3 * i));
      pour[2] = save(square(drop) + stone.barley * old[order[1]] + BigInt.from(5 * i));
      pour[3] = save(square(drop) + stone.salt * old[order[2]] + BigInt.from(7 * i));
      final nextBowls = List<BigInt>.filled(7, BigInt.zero);
      for (var position = 1; position <= 6; position++) {
        final bowlId = order[position - 1];
        final prevId = order[wrap1(position - 1, 6) - 1];
        final nextId = order[wrap1(position + 1, 6) - 1];
        final s = old[bowlId] +
            BigInt.from(2) * old[prevId] +
            BigInt.from(3) * old[nextId] +
            pour[position] +
            drop +
            stone.byKind(stirStoneByPosition[position - 1]);
        nextBowls[bowlId] = save(
          square(s) +
              BigInt.from(5) * old[prevId] * old[nextId] +
              BigInt.from(i * position),
        );
      }
      bowls = nextBowls;
      if (i == 46) {
        orderAtDrop46 = List<int>.from(order);
      }
    }
    return SauceResult(bowls, orderAtDrop46!);
  }

  static List<BigInt> postStir12(List<BigInt> initial) {
    var bowls = List<BigInt>.from(initial);
    for (var stir = 1; stir <= 12; stir++) {
      final old = List<BigInt>.from(bowls);
      var rawSum = BigInt.zero;
      for (var bowlId = 1; bowlId <= 6; bowlId++) {
        rawSum += old[bowlId];
      }
      final savedBowlSum = save(rawSum + BigInt.from(149 * stir));
      final orderNumber = regularMod(savedBowlSum - BigInt.one, BigInt.from(720)) + BigInt.one;
      final order = bowlOrderFromNumber(orderNumber.toInt());
      final nextBowls = List<BigInt>.filled(7, BigInt.zero);
      for (var position = 1; position <= 6; position++) {
        final bowlId = order[position - 1];
        final prevId = order[wrap1(position - 1, 6) - 1];
        final nextId = order[wrap1(position + 1, 6) - 1];
        final s = old[bowlId] +
            BigInt.from(3) * old[prevId] +
            BigInt.from(5) * old[nextId] +
            savedBowlSum +
            BigInt.from(stir) +
            BigInt.from(position * position);
        nextBowls[bowlId] = save(
          square(s) + BigInt.from(7) * old[prevId] * old[nextId],
        );
      }
      bowls = nextBowls;
    }
    return bowls;
  }

  static SauceResult sauce(BigInt calculationDay, BigInt targetDay) {
    final counts = workCounts(calculationDay, targetDay);
    final hidden = buildHiddenDrops(counts, stones);
    final visible = buildVisibleDrops(counts, stones, hidden);
    final bowls = initialBowls(counts);
    final afterDrops = applyVisibleDropsToBowls(bowls, visible, stones);
    final finalBowls = postStir12(afterDrops.bowls);
    return SauceResult(finalBowls, afterDrops.orderAtDrop46);
  }

  static int nextBowlInDrop46Order(SauceResult result, int queriedBowlId) {
    final position = result.orderAtDrop46.indexOf(queriedBowlId);
    if (position < 0) {
      throw StateError('מזהה הקערה אינו נמצא בסדר הטיפה הארבעים ושש.');
    }
    return result.orderAtDrop46[(position + 1) % 6];
  }

  static AnswerStream askBowl(SauceResult result, int queriedBowlId, int seal) {
    final nextId = nextBowlInDrop46Order(result, queriedBowlId);
    final first = save(
      square(result.bowls[queriedBowlId] + BigInt.from(seal + 181)) +
          BigInt.from(179) * result.bowls[nextId] +
          BigInt.from(seal),
    );
    final directionNumber = save(
      square(first + BigInt.from(seal + 194)) +
          BigInt.from(193) * first +
          BigInt.from(197) * result.bowls[6],
    );
    final step = regularMod(directionNumber, BigInt.from(2)) == BigInt.one ? 1 : -1;
    return AnswerStream(first, step);
  }

  static BigInt answerAt(AnswerStream stream, BigInt k) {
    return BigInt.one + regularMod(
      stream.first - BigInt.one + BigInt.from(stream.directionStep) * k,
      m,
    );
  }

  static BigInt chooseRankShort(AnswerStream stream, BigInt n) {
    if (n < BigInt.one || n > m) {
      throw ArgumentError('הבחירה הקצרה דורשת גודל בין אחד למניין הגדול.');
    }
    final acceptanceLimit = floorDiv(m, n) * n;
    var k = BigInt.zero;
    while (true) {
      final x = answerAt(stream, k);
      if (x <= acceptanceLimit) {
        return regularMod(x - BigInt.one, n) + BigInt.one;
      }
      k += BigInt.one;
    }
  }

  static List<BigInt> smallestPowerCount(BigInt base, BigInt n) {
    var k = BigInt.one;
    var space = base;
    while (space < n) {
      k += BigInt.one;
      space *= base;
    }
    return <BigInt>[k, space];
  }

  static BigInt chooseRankWide(AnswerStream stream, BigInt n) {
    if (n <= m) {
      throw ArgumentError('הבחירה הרחבה דורשת משפחה גדולה מן המניין הגדול.');
    }
    final power = smallestPowerCount(m, n);
    final k = power[0].toInt();
    final space = power[1];
    var wide = BigInt.one;
    var weight = BigInt.one;
    for (var j = 0; j < k; j++) {
      final digit = answerAt(stream, BigInt.from(j)) - BigInt.one;
      wide += digit * weight;
      weight *= m;
    }
    final acceptanceLimit = floorDiv(space, n) * n;
    var w = wide;
    while (true) {
      if (w <= acceptanceLimit) {
        return regularMod(w - BigInt.one, n) + BigInt.one;
      }
      w = BigInt.one + regularMod(
        w - BigInt.one + BigInt.from(stream.directionStep),
        space,
      );
    }
  }

  static BigInt chooseRank(AnswerStream stream, BigInt n) {
    if (n < BigInt.one) {
      throw ArgumentError('משפחה לבחירה חייבת להכיל לפחות איבר אחד.');
    }
    return n <= m ? chooseRankShort(stream, n) : chooseRankWide(stream, n);
  }

  static BigInt fallingFactorial(int n, int k) {
    if (n < 0 || k < 0 || k > n) {
      throw ArgumentError('פרמטרים לא חוקיים למכפלה היורדת.');
    }
    var result = BigInt.one;
    for (var j = 0; j < k; j++) {
      result *= BigInt.from(n - j);
    }
    return result;
  }

  static List<int> unrankDistinctNameIndices(int masterLength, int k, BigInt rank1) {
    final total = fallingFactorial(masterLength, k);
    if (rank1 < BigInt.one || rank1 > total) {
      throw RangeError('דרגת השמות מחוץ לטווח.');
    }
    final remaining = <int>[for (var i = 1; i <= masterLength; i++) i];
    final result = <int>[];
    var rank = rank1;
    for (var position = 1; position <= k; position++) {
      final suffixLength = k - position;
      final block = fallingFactorial(remaining.length - 1, suffixLength);
      for (var candidate = 0; candidate < remaining.length; candidate++) {
        if (rank > block) {
          rank -= block;
        } else {
          result.add(remaining.removeAt(candidate));
          break;
        }
      }
    }
    return result;
  }

  BigInt positiveGateGap(BigInt n) {
    if (n < BigInt.one) {
      throw ArgumentError('אינדקס שער חיובי חייב להיות לפחות אחד.');
    }
    final result = sauce(foundationDay, foundationDay + n);
    final stream = askBowl(result, 1, sealGateGap);
    final chosen = chooseRank(stream, BigInt.from(922));
    return BigInt.from(41) + chosen;
  }

  BigInt negativeGateGap(BigInt n) {
    if (n < BigInt.one) {
      throw ArgumentError('גודל צעד שער שלילי חייב להיות לפחות אחד.');
    }
    final result = sauce(foundationDay, foundationDay - n);
    final stream = askBowl(result, 1, sealGateGap);
    final chosen = chooseRank(stream, BigInt.from(922));
    return BigInt.from(41) + chosen;
  }

  BigInt ensureGateIndex(BigInt k) {
    if (k > _maxKnownGateIndex) {
      var n = _maxKnownGateIndex + BigInt.one;
      while (n <= k) {
        _gates[n] = _gates[n - BigInt.one]! + positiveGateGap(n);
        _maxKnownGateIndex = n;
        n += BigInt.one;
      }
    }
    if (k < _minKnownGateIndex) {
      var n = _minKnownGateIndex - BigInt.one;
      while (n >= k) {
        _gates[n] = _gates[n + BigInt.one]! - negativeGateGap(n.abs());
        _minKnownGateIndex = n;
        n -= BigInt.one;
      }
    }
    return _gates[k]!;
  }

  void ensureGatesCover(BigInt lowDay, BigInt highDay) {
    if (lowDay > highDay) {
      throw ArgumentError('טווח השערים הפוך.');
    }
    while (_gates[_minKnownGateIndex]! > lowDay) {
      ensureGateIndex(_minKnownGateIndex - BigInt.one);
    }
    while (_gates[_maxKnownGateIndex]! < highDay) {
      ensureGateIndex(_maxKnownGateIndex + BigInt.one);
    }
  }

  BigInt gateIndexAtOrBefore(BigInt day) {
    ensureGatesCover(day, day);
    var lo = _minKnownGateIndex;
    var hi = _maxKnownGateIndex;
    while (lo < hi) {
      final mid = lo + floorDiv(hi - lo + BigInt.one, BigInt.from(2));
      if (_gates[mid]! <= day) {
        lo = mid;
      } else {
        hi = mid - BigInt.one;
      }
    }
    return lo;
  }

  BigInt gateIndexAtOrAfter(BigInt day) {
    final i = gateIndexAtOrBefore(day);
    if (_gates[i] == day) {
      return i;
    }
    return i + BigInt.one;
  }

  BigInt? exactGateIndex(BigInt day) {
    final i = gateIndexAtOrBefore(day);
    return _gates[i] == day ? i : null;
  }

  BigInt _yearLength(BigInt openIndex, BigInt closeIndex) {
    ensureGateIndex(openIndex);
    ensureGateIndex(closeIndex);
    return _gates[closeIndex]! - _gates[openIndex]!;
  }

  bool _validYearPair(BigInt openIndex, BigInt closeIndex) {
    if (closeIndex - openIndex < BigInt.from(6)) {
      return false;
    }
    final length = _yearLength(openIndex, closeIndex);
    return length >= yearMinDays && length <= yearMaxDays;
  }

  Year _makeYear(BigInt number, BigInt openIndex, BigInt closeIndex) {
    return Year(
      number: number,
      openGateIndex: openIndex,
      closeGateIndex: closeIndex,
      openGateDay: ensureGateIndex(openIndex),
      closeGateDay: ensureGateIndex(closeIndex),
    );
  }

  Year year5000(BigInt calculationDay) {
    ensureGatesCover(
      calculationDay - yearMaxDays,
      calculationDay + yearMaxDays,
    );
    final candidates = <_YearPair>[];
    var i = _minKnownGateIndex;
    while (i < _maxKnownGateIndex) {
      var j = i + BigInt.one;
      while (j <= _maxKnownGateIndex) {
        final length = _gates[j]! - _gates[i]!;
        if (length > yearMaxDays) {
          break;
        }
        if (_validYearPair(i, j) &&
            _gates[i]! < calculationDay &&
            calculationDay <= _gates[j]!) {
          candidates.add(_YearPair(i, j));
        }
        j += BigInt.one;
      }
      i += BigInt.one;
    }
    if (candidates.isEmpty) {
      throw StateError('לא נמצאה שנת עוגן חוקית.');
    }
    candidates.sort((a, b) {
      final lengthA = _gates[a.closeIndex]! - _gates[a.openIndex]!;
      final lengthB = _gates[b.closeIndex]! - _gates[b.openIndex]!;
      final byLength = lengthA.compareTo(lengthB);
      if (byLength != 0) {
        return byLength;
      }
      return _gates[a.openIndex]!.compareTo(_gates[b.openIndex]!);
    });
    final result = sauce(calculationDay, calculationDay);
    final stream = askBowl(result, 1, sealYear5000);
    final rank = chooseRank(stream, BigInt.from(candidates.length)).toInt();
    final pair = candidates[rank - 1];
    return _makeYear(BigInt.from(5000), pair.openIndex, pair.closeIndex);
  }

  Year nextYear(BigInt calculationDay, Year knownYear) {
    final openIndex = knownYear.closeGateIndex;
    final openDay = ensureGateIndex(openIndex);
    ensureGatesCover(openDay, openDay + yearMaxDays);
    final candidates = <BigInt>[];
    var closeIndex = openIndex + BigInt.one;
    while (true) {
      ensureGateIndex(closeIndex);
      if (_gates[closeIndex]! - _gates[openIndex]! > yearMaxDays) {
        break;
      }
      if (_validYearPair(openIndex, closeIndex)) {
        candidates.add(closeIndex);
      }
      closeIndex += BigInt.one;
    }
    candidates.sort((a, b) => _yearLength(openIndex, a).compareTo(_yearLength(openIndex, b)));
    final result = sauce(calculationDay, _gates[openIndex]!);
    final stream = askBowl(result, 1, sealNextYear);
    final rank = chooseRank(stream, BigInt.from(candidates.length)).toInt();
    return _makeYear(knownYear.number + BigInt.one, openIndex, candidates[rank - 1]);
  }

  Year previousYear(BigInt calculationDay, Year knownYear) {
    final closeIndex = knownYear.openGateIndex;
    final closeDay = ensureGateIndex(closeIndex);
    ensureGatesCover(closeDay - yearMaxDays, closeDay);
    final candidates = <BigInt>[];
    var openIndex = closeIndex - BigInt.one;
    while (true) {
      ensureGateIndex(openIndex);
      if (_gates[closeIndex]! - _gates[openIndex]! > yearMaxDays) {
        break;
      }
      if (_validYearPair(openIndex, closeIndex)) {
        candidates.add(openIndex);
      }
      openIndex -= BigInt.one;
    }
    candidates.sort((a, b) => _yearLength(a, closeIndex).compareTo(_yearLength(b, closeIndex)));
    final result = sauce(calculationDay, _gates[closeIndex]!);
    final stream = askBowl(result, 1, sealPreviousYear);
    final rank = chooseRank(stream, BigInt.from(candidates.length)).toInt();
    return _makeYear(knownYear.number - BigInt.one, candidates[rank - 1], closeIndex);
  }

  Year findTargetYear(BigInt calculationDay, BigInt targetDay) {
    var year = year5000(calculationDay);
    while (targetDay > year.closeGateDay) {
      year = nextYear(calculationDay, year);
    }
    while (targetDay <= year.openGateDay) {
      year = previousYear(calculationDay, year);
    }
    return year;
  }

  int chooseCutletCount(SauceResult structureSauce, Year year) {
    final gateGaps = year.closeGateIndex - year.openGateIndex;
    final candidates = <int>[];
    for (var k = 6; k <= 17; k++) {
      if (BigInt.from(k) <= gateGaps) {
        candidates.add(k);
      }
    }
    final stream = askBowl(structureSauce, 2, sealCutletCount);
    final rank = chooseRank(stream, BigInt.from(candidates.length)).toInt();
    return candidates[rank - 1];
  }

  List<BigInt> chooseCutletPartition(
    BigInt calculationDay,
    SauceResult structureSauce,
    Year year,
    int cutletCount,
  ) {
    final gaps = year.closeGateIndex - year.openGateIndex;
    final gateIndex = exactGateIndex(calculationDay);
    BigInt? required;
    if (gateIndex != null &&
        year.openGateIndex < gateIndex &&
        gateIndex < year.closeGateIndex) {
      required = gateIndex - year.openGateIndex;
    }
    final family = _CutletPartitionFamily(gaps, cutletCount, required);
    final stream = askBowl(structureSauce, 2, sealCutletPartition);
    final rank = chooseRank(stream, family.countAll());
    return family.unrank1(rank);
  }

  List<int> chooseCutletNames(SauceResult structureSauce, int cutletCount) {
    final count = fallingFactorial(17, cutletCount);
    final stream = askBowl(structureSauce, 5, sealCutletNames);
    final rank = chooseRank(stream, count);
    return unrankDistinctNameIndices(17, cutletCount, rank);
  }

  List<Cutlet> materializeCutlets(
    Year year,
    List<BigInt> partition,
    List<int> names,
  ) {
    final result = <Cutlet>[];
    var cursorGate = year.openGateIndex;
    for (var k = 0; k < partition.length; k++) {
      final openGateIndex = cursorGate;
      final closeGateIndex = cursorGate + partition[k];
      final firstDay = ensureGateIndex(openGateIndex) + BigInt.one;
      final lastDay = ensureGateIndex(closeGateIndex);
      result.add(Cutlet(
        nameCanonicalIndex: names[k],
        openGateIndex: openGateIndex,
        closeGateIndex: closeGateIndex,
        firstDay: firstDay,
        lastDay: lastDay,
      ));
      cursorGate = closeGateIndex;
    }
    return result;
  }

  int chooseMonthCount(SauceResult structureSauce, Year year) {
    final length = year.closeGateDay - year.openGateDay;
    final minMonths = ceilDiv(length, BigInt.from(123)).toInt();
    final floorByFour = floorDiv(length, BigInt.from(4)).toInt();
    final maxMonths = floorByFour < 47 ? floorByFour : 47;
    if (minMonths < 3 || minMonths > maxMonths || maxMonths > 47) {
      throw StateError('גבולות מספר החודשים אינם חוקיים.');
    }
    final stream = askBowl(structureSauce, 3, sealMonthCount);
    final rank = chooseRank(stream, BigInt.from(maxMonths - minMonths + 1)).toInt();
    return minMonths + rank - 1;
  }

  List<BigInt> chooseMonthLengths(
    SauceResult structureSauce,
    Year year,
    int monthCount,
  ) {
    final length = year.closeGateDay - year.openGateDay;
    final family = _BoundedCompositionCounter(
      length,
      monthCount,
      BigInt.from(4),
      BigInt.from(123),
    );
    final stream = askBowl(structureSauce, 3, sealMonthLengths);
    final rank = chooseRank(stream, family.countAll());
    return family.unrank1(rank);
  }

  List<int> chooseMonthWeaving(
    SauceResult structureSauce,
    List<BigInt> monthLengths,
  ) {
    final family = _WeavingCounter(monthLengths);
    final total = family.count(family.initialState());
    final stream = askBowl(structureSauce, 4, sealMonthWeaving);
    final rank = chooseRank(stream, total);
    return family.unrank1(rank);
  }

  List<int> chooseMonthNames(SauceResult structureSauce, int monthCount) {
    final count = fallingFactorial(47, monthCount);
    final stream = askBowl(structureSauce, 5, sealMonthNames);
    final rank = chooseRank(stream, count);
    return unrankDistinctNameIndices(47, monthCount, rank);
  }

  YearStructure buildYearStructure(BigInt calculationDay, Year year) {
    final firstDay = year.openGateDay + BigInt.one;
    final structureSauce = sauce(calculationDay, firstDay);
    final cutletCount = chooseCutletCount(structureSauce, year);
    final partition = chooseCutletPartition(
      calculationDay,
      structureSauce,
      year,
      cutletCount,
    );
    final cutletNames = chooseCutletNames(structureSauce, cutletCount);
    final cutlets = materializeCutlets(year, partition, cutletNames);
    final monthCount = chooseMonthCount(structureSauce, year);
    final monthLengths = chooseMonthLengths(structureSauce, year, monthCount);
    final monthWeaving = chooseMonthWeaving(structureSauce, monthLengths);
    final monthNames = chooseMonthNames(structureSauce, monthCount);
    return YearStructure(
      cutletCount: cutletCount,
      cutletPartition: partition,
      cutletNameCanonicalIndices: cutletNames,
      cutlets: cutlets,
      monthCount: monthCount,
      monthLengths: monthLengths,
      monthWeaving: monthWeaving,
      monthNameCanonicalIndices: monthNames,
    );
  }

  CalendarTuple calendarDate(BigInt calculationDay, BigInt targetDay) {
    final year = findTargetYear(calculationDay, targetDay);
    final structure = buildYearStructure(calculationDay, year);
    Cutlet? chosenCutlet;
    for (final cutlet in structure.cutlets) {
      if (cutlet.firstDay <= targetDay && targetDay <= cutlet.lastDay) {
        chosenCutlet = cutlet;
        break;
      }
    }
    if (chosenCutlet == null) {
      throw StateError('היום הנשאל אינו נמצא באף קציצה.');
    }
    final dayInCutlet = targetDay - chosenCutlet.firstDay + BigInt.one;
    final yearOffset0 = targetDay - (year.openGateDay + BigInt.one);
    if (yearOffset0 < BigInt.zero || yearOffset0 > BigInt.from(10000000)) {
      throw StateError('היסט היום אינו ניתן לחומרה בטוחה בבדיקת הייחוס הזאת.');
    }
    final offset = yearOffset0.toInt();
    final monthId = structure.monthWeaving[offset];
    final monthCanonicalIndex = structure.monthNameCanonicalIndices[monthId - 1];
    var dayInMonth = BigInt.zero;
    for (var p = 0; p <= offset; p++) {
      if (structure.monthWeaving[p] == monthId) {
        dayInMonth += BigInt.one;
      }
    }
    return CalendarTuple(
      yearNumber: year.number,
      cutletName: SourceLanguageCatalog.cutletText(chosenCutlet.nameCanonicalIndex),
      dayInCutlet: dayInCutlet,
      monthName: SourceLanguageCatalog.monthText(monthCanonicalIndex),
      dayInMonth: dayInMonth,
    );
  }
}
