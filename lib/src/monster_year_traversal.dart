import 'monster_bowl_processor.dart';
import 'monster_bowl_questions.dart';
import 'monster_meatball_gates.dart';
import 'monster_seed_feeder.dart';
import 'monster_visible_droplets.dart';
import 'monster_work_counts.dart';
import 'monster_year_eligibility.dart';
import 'monster_year_selection.dart';

/// A single proven year component. This is NOT a five-component calendar date.
final class MonsterTraversedYear {
  final BigInt yearNumber;
  final MonsterYearCandidate candidate;
  final BigInt? questionGate;
  final int? questionSeal;
  final BigInt candidateCount;
  final BigInt choiceIndex;
  final MonsterEqualChoice choice;

  const MonsterTraversedYear._({
    required this.yearNumber,
    required this.candidate,
    required this.questionGate,
    required this.questionSeal,
    required this.candidateCount,
    required this.choiceIndex,
    required this.choice,
  });

  factory MonsterTraversedYear.from5000(MonsterYear5000Selection selection) {
    return MonsterTraversedYear._(
      yearNumber: selection.yearNumber,
      candidate: selection.selectedYear,
      questionGate: null,
      questionSeal: 10,
      candidateCount: selection.candidateCount,
      choiceIndex: selection.choiceIndex,
      choice: selection.choice,
    );
  }

  bool contains(BigInt day) => candidate.contains(day);
}

/// README §R. Every transition uses (calculationDay, boundaryGate) as sauce.
/// Gaps are traversed once per candidate boundary; no 32-gate prefix shortcut.
final class MonsterYearTraversal {
  static final BigInt maximumLength = BigInt.from(5778);
  static final BigInt minimumLength = BigInt.from(252);
  static const int maximumIntervals = 137;
  static const int maximumTransitions = 64;

  final MonsterMeatballGateCalculator gates;
  final MonsterYear5000Selector anchor;
  final MonsterBowlQuestionEngine questions;

  MonsterYearTraversal({
    MonsterMeatballGateCalculator? gates,
    MonsterYear5000Selector? anchor,
    this.questions = const MonsterBowlQuestionEngine(),
  })  : gates = gates ?? MonsterMeatballGateCalculator(),
        anchor = anchor ?? MonsterYear5000Selector();

  /// The right-hand ordinal labels a positive gap, whereas the left-hand
  /// ordinal labels a negative gap. The crossing [-1,0] uses gap -1.
  static BigInt signedGapOrdinal(BigInt rightOrdinal) {
    return rightOrdinal > BigInt.zero
        ? rightOrdinal
        : rightOrdinal - BigInt.one;
  }

  MonsterTraversedYear next(BigInt calculationDay, MonsterTraversedYear year) {
    return _advance(calculationDay, year, true);
  }

  MonsterTraversedYear previous(
    BigInt calculationDay,
    MonsterTraversedYear year,
  ) {
    return _advance(calculationDay, year, false);
  }

  MonsterTraversedYear resolve(
    BigInt calculationDay,
    BigInt requestedDay, {
    int maxTransitions = maximumTransitions,
  }) {
    if (maxTransitions < 0 || maxTransitions > maximumTransitions) {
      throw RangeError.range(maxTransitions, 0, maximumTransitions);
    }
    var year = MonsterTraversedYear.from5000(anchor.select(calculationDay));
    var transitions = 0;
    while (!year.contains(requestedDay)) {
      if (transitions >= maxTransitions) {
        throw IncompleteMonsterYearTraversal(
          calculationDay,
          requestedDay,
          transitions,
        );
      }
      year = requestedDay > year.candidate.closeGate
          ? next(calculationDay, year)
          : previous(calculationDay, year);
      transitions++;
    }
    return year;
  }

  MonsterTraversedYear _advance(
    BigInt calculationDay,
    MonsterTraversedYear current,
    bool forward,
  ) {
    final boundaryOrdinal = forward
        ? current.candidate.closeOrdinal
        : current.candidate.openOrdinal;
    final boundaryGate =
        forward ? current.candidate.closeGate : current.candidate.openGate;
    final candidates = <MonsterYearCandidate>[];
    var edge = boundaryGate;
    for (var step = 1; step <= maximumIntervals; step++) {
      final stepOrdinal = BigInt.from(step);
      final rightOrdinal = forward
          ? boundaryOrdinal + stepOrdinal
          : boundaryOrdinal - stepOrdinal + BigInt.one;
      final signedOrdinal = signedGapOrdinal(rightOrdinal);
      final gap = gates.gapFor(signedOrdinal).length;
      edge = forward ? edge + gap : edge - gap;
      final length = forward ? edge - boundaryGate : boundaryGate - edge;
      if (length > maximumLength) {
        break;
      }
      if (step < 6 || length < minimumLength) {
        continue;
      }
      candidates.add(MonsterYearCandidate(
        openOrdinal: forward ? boundaryOrdinal : boundaryOrdinal - stepOrdinal,
        closeOrdinal: forward ? boundaryOrdinal + stepOrdinal : boundaryOrdinal,
        openGate: forward ? boundaryGate : edge,
        closeGate: forward ? edge : boundaryGate,
        intervalCount: stepOrdinal,
        length: length,
        eligible: true,
      ));
    }
    if (candidates.isEmpty) {
      throw StateError('§R has no eligible adjacent year.');
    }
    // Every candidate shares one boundary, so lengths are strictly increasing.
    final counts =
        const MonsterWorkCounter().calculate(calculationDay, boundaryGate);
    final feeder = const MonsterSeedFeeder();
    final stones = feeder.buildStones();
    final feeds = feeder.buildHiddenFeeds(counts, stones);
    final drops = const MonsterVisibleDropGenerator().buildVisibleDrops(
      counts: counts,
      hiddenFeeds: feeds,
      stones: stones,
    );
    final bowls = const MonsterBowlProcessor().process(
      counts: counts,
      visibleDrops: drops,
      stones: stones,
    );
    final seal = forward ? 11 : 12;
    final answer = questions.createAnswerSequence(
      bowls: bowls,
      bowlId: 1,
      seal: seal,
    );
    final count = BigInt.from(candidates.length);
    final choice = questions.chooseEqual(sequence: answer, modulus: count);
    if (choice.result < BigInt.one || choice.result > count) {
      throw StateError('§R returned an invalid adjacent-year index.');
    }
    final candidate = candidates[(choice.result - BigInt.one).toInt()];
    if (forward
        ? candidate.openGate != current.candidate.closeGate
        : candidate.closeGate != current.candidate.openGate) {
      throw StateError('§R continuity broken at the shared gate.');
    }
    return MonsterTraversedYear._(
      yearNumber: current.yearNumber + (forward ? BigInt.one : -BigInt.one),
      candidate: candidate,
      questionGate: boundaryGate,
      questionSeal: seal,
      candidateCount: count,
      choiceIndex: choice.result,
      choice: choice,
    );
  }
}

/// A bounded walk has not established the requested year's identity.
final class IncompleteMonsterYearTraversal implements Exception {
  final BigInt calculationDay;
  final BigInt requestedDay;
  final int completedTransitions;

  const IncompleteMonsterYearTraversal(
    this.calculationDay,
    this.requestedDay,
    this.completedTransitions,
  );

  @override
  String toString() =>
      'Incomplete §R year traversal after $completedTransitions transitions.';
}
