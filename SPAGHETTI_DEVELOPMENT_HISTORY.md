# スパゲッティ開発履歴

## Stage 1 — Bootstrap

### 何を作ったか

Q#＋日本語の新しい実装線を空の状態から開始した。正確な整数演算、固定名称カタログ、規範 oracle、production baseline、Q# テスト、一般的な context/dispatcher/validation/metrics shell を用意した。

### 何をまだ作っていないか

歴史的な誤実装はまだ一つも導入していない。したがって、この段階には legacy defect、patch、ghost path、late filter、bad cache key、recovery detour などの将来要素は存在しない。

### 意味論への影響

base dispatcher と観測用 tick は入力値を変更せず、規範計算の分岐条件にも使われない。production は test-only oracle を呼ばない。
