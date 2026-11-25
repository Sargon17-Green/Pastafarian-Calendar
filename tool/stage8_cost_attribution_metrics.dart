final class Stage8CostAttributionMetrics {
  static int _activeChildrenCalls = 0;
  static int _unopenedFactorCalls = 0;
  static int _countCompletionsCalls = 0;
  static int _countCompletionsFromUnopenedFactor = 0;
  static int _countCompletionsOutsideUnopenedFactor = 0;
  static int _activeChildrenMicroseconds = 0;
  static int _unopenedFactorMicroseconds = 0;
  static int _countCompletionsMicroseconds = 0;
  static int _unopenedFactorDepth = 0;

  static final Map<String, int> _activeChildrenStates = <String, int>{};
  static final Map<String, int> _unopenedFactorStates = <String, int>{};
  static final Map<String, int> _countCompletionsStates = <String, int>{};
  static final Map<String, int> _activeBaseBits = <String, int>{};
  static final Map<String, int> _activeChildBits = <String, int>{};
  static final Map<String, int> _unopenedFactorBits = <String, int>{};
  static final Map<String, int> _countCompletionsBits = <String, int>{};

  static void _increment(Map<String, int> histogram, String key) {
    histogram[key] = (histogram[key] ?? 0) + 1;
  }

  static Map<String, int> _sorted(Map<String, int> histogram) {
    final keys = histogram.keys.toList()..sort();
    return <String, int>{
      for (final key in keys) key: histogram[key]!,
    };
  }

  static void reset() {
    _activeChildrenCalls = 0;
    _unopenedFactorCalls = 0;
    _countCompletionsCalls = 0;
    _countCompletionsFromUnopenedFactor = 0;
    _countCompletionsOutsideUnopenedFactor = 0;
    _activeChildrenMicroseconds = 0;
    _unopenedFactorMicroseconds = 0;
    _countCompletionsMicroseconds = 0;
    _unopenedFactorDepth = 0;
    _activeChildrenStates.clear();
    _unopenedFactorStates.clear();
    _countCompletionsStates.clear();
    _activeBaseBits.clear();
    _activeChildBits.clear();
    _unopenedFactorBits.clear();
    _countCompletionsBits.clear();
  }

  static void beginActiveChildren(List<int> counts, BigInt base) {
    _activeChildrenCalls++;
    final days = counts.fold<int>(0, (sum, value) => sum + value);
    final colors = counts.length;
    final key = 'colors=$colors;remainingDays=$days';
    _increment(_activeChildrenStates, key);
    _increment(_activeBaseBits, base.bitLength.toString());
  }

  static void endActiveChildren(List<BigInt> result, int elapsedMicroseconds) {
    _activeChildrenMicroseconds += elapsedMicroseconds;
    for (final value in result) {
      _increment(_activeChildBits, value.bitLength.toString());
    }
  }

  static void beginUnopenedFactor(
    List<int> remaining,
    int opened,
    int nextActiveLength,
  ) {
    _unopenedFactorCalls++;
    _unopenedFactorDepth++;
    final months = remaining.length;
    final key = 'opened=$opened;nextActiveLength=$nextActiveLength;'
        'months=$months';
    _increment(_unopenedFactorStates, key);
  }

  static void endUnopenedFactor(BigInt result, int elapsedMicroseconds) {
    _unopenedFactorDepth--;
    _unopenedFactorMicroseconds += elapsedMicroseconds;
    _increment(_unopenedFactorBits, result.bitLength.toString());
  }

  static void beginCountCompletions(
    List<int> remaining, {
    required int openedUpTo,
    required int closedUpTo,
  }) {
    _countCompletionsCalls++;
    final days = remaining.fold<int>(0, (sum, value) => sum + value);
    final fromUnopenedFactor = _unopenedFactorDepth > 0;
    final origin =
        fromUnopenedFactor ? 'unopenedFactor' : 'outsideUnopenedFactor';
    if (fromUnopenedFactor) {
      _countCompletionsFromUnopenedFactor++;
    } else {
      _countCompletionsOutsideUnopenedFactor++;
    }
    final months = remaining.length;
    final key = 'origin=$origin;opened=$openedUpTo;closed=$closedUpTo;'
        'months=$months;days=$days';
    _increment(_countCompletionsStates, key);
  }

  static void endCountCompletions(BigInt result, int elapsedMicroseconds) {
    _countCompletionsMicroseconds += elapsedMicroseconds;
    _increment(_countCompletionsBits, result.bitLength.toString());
  }

  static Map<String, Object> snapshot() {
    return <String, Object>{
      'callCounts': <String, int>{
        'activeChildren': _activeChildrenCalls,
        'unopenedFactor': _unopenedFactorCalls,
        'countCompletions': _countCompletionsCalls,
        'countCompletionsFromUnopenedFactor':
            _countCompletionsFromUnopenedFactor,
        'countCompletionsOutsideUnopenedFactor':
            _countCompletionsOutsideUnopenedFactor,
      },
      'elapsedMicroseconds': <String, int>{
        'activeChildren': _activeChildrenMicroseconds,
        'unopenedFactor': _unopenedFactorMicroseconds,
        'countCompletions': _countCompletionsMicroseconds,
      },
      'stateHistograms': <String, Map<String, int>>{
        'activeChildren': _sorted(_activeChildrenStates),
        'unopenedFactor': _sorted(_unopenedFactorStates),
        'countCompletions': _sorted(_countCompletionsStates),
      },
      'bigIntBitLengthHistograms': <String, Map<String, int>>{
        'activeBase': _sorted(_activeBaseBits),
        'activeChild': _sorted(_activeChildBits),
        'unopenedFactor': _sorted(_unopenedFactorBits),
        'countCompletions': _sorted(_countCompletionsBits),
      },
    };
  }
}
