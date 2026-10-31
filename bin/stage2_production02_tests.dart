import 'dart:io';

import '../lib/src/monster_modular_math.dart';

var _checks = 0;

void _check(bool condition, String description) {
  _checks += 1;
  if (!condition) {
    throw StateError('PRODUCTION02_CHECK_FAILED: $description');
  }
}

void _expectArgumentError(void Function() action, String description) {
  var rejected = false;
  try {
    action();
  } on ArgumentError {
    rejected = true;
  }
  _check(rejected, description);
}

void main() {
  final math = const MonsterModularMath();
  var floorCases = 0;
  var modCases = 0;

  // A separate small-integer oracle using floating point only where
  // all inputs and quotients are exactly representable.
  for (var numerator = -80; numerator <= 80; numerator++) {
    for (var denominator = -11; denominator <= 11; denominator++) {
      if (denominator == 0) {
        continue;
      }
      final actual = math.floorDiv(
        BigInt.from(numerator),
        BigInt.from(denominator),
      );
      final expected = BigInt.from((numerator / denominator).floor());
      _check(actual == expected, 'Bounded floor division');
      floorCases += 1;
    }
  }

  for (var divisorInt = 1; divisorInt <= 19; divisorInt++) {
    final divisor = BigInt.from(divisorInt);
    for (var number = -80; number <= 80; number++) {
      final value = BigInt.from(number);
      final residue = math.regularMod(value, divisor);
      _check(
        residue >= BigInt.zero && residue < divisor,
        'Euclidean residue range',
      );
      _check(
        (value - residue) % divisor == BigInt.zero,
        'Euclidean congruence',
      );
      final integerWitness =
          ((number % divisorInt) + divisorInt) % divisorInt;
      _check(
        residue == BigInt.from(integerWitness),
        'Independent integer witness',
      );
      modCases += 1;
    }
  }

  final m = MonsterModularMath.modulus;
  _check(m == (BigInt.one << 127) - BigInt.one, 'Exact modulus');
  _check(math.save(BigInt.zero) == m, 'Save zero');
  _check(math.save(BigInt.one) == BigInt.one, 'Save one');
  _check(math.save(m) == m, 'Save modulus');
  _check(math.save(m + BigInt.one) == BigInt.one, 'Save wrap');
  _check(math.save(-m) == m, 'Save negative modulus');

  final wide = (BigInt.one << 200) + BigInt.from(17);
  for (final value in <BigInt>[
    -wide,
    -m,
    -BigInt.one,
    BigInt.zero,
    BigInt.one,
    m,
    wide,
  ]) {
    final saved = math.save(value);
    _check(saved >= BigInt.one && saved <= m, 'Save interval');
    _check(math.save(value + m * BigInt.from(7)) == saved, 'Period +');
    _check(math.save(value - m * BigInt.from(7)) == saved, 'Period -');
    _check(math.save(saved) == saved, 'Save idempotence');
  }

  final high = wide * m + BigInt.from(13);
  _check(math.floorDiv(high, m) == wide, 'Wide positive floor');
  _check(
    math.floorDiv(-high, m) == -wide - BigInt.one,
    'Wide negative floor',
  );
  _check(
    math.floorDiv(high, -m) == -wide - BigInt.one,
    'Wide negative divisor',
  );
  _check(math.square(wide) == wide * wide, 'Wide square');
  _check(
    math.ceilDiv(BigInt.from(5), BigInt.from(2)) == BigInt.from(3),
    'Positive nonexact ceiling',
  );
  _check(
    math.ceilDiv(BigInt.from(6), BigInt.from(2)) == BigInt.from(3),
    'Positive exact ceiling',
  );
  _check(
    math.ceilDiv(BigInt.zero, BigInt.from(2)) == BigInt.zero,
    'Zero ceiling',
  );
  _check(math.ceilDiv(high, m) == wide + BigInt.one, 'Wide ceiling');
  _expectArgumentError(
    () => math.floorDiv(BigInt.one, BigInt.zero),
    'Reject zero divisor',
  );
  _expectArgumentError(
    () => math.regularMod(BigInt.one, BigInt.zero),
    'Reject zero modulus',
  );
  _expectArgumentError(
    () => math.regularMod(BigInt.one, -BigInt.one),
    'Reject negative modulus',
  );
  _expectArgumentError(
    () => math.ceilDiv(-BigInt.one, BigInt.one),
    'Reject negative ceiling numerator',
  );
  _expectArgumentError(
    () => math.ceilDiv(BigInt.one, BigInt.zero),
    'Reject zero ceiling divisor',
  );

  stdout.writeln(
    'PRODUCTION02_MODULAR_PASS; checks=$_checks; '
    'floor_cases=$floorCases; mod_cases=$modCases; '
    'five_component_calendar_ready=false',
  );
}
