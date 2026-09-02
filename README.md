# Q#＋日本語 実装 — Stage 1 Bootstrap

このディレクトリは、既存実装を基礎にせず、組み込み仕様だけから新規に作成した独立実装の最初の状態である。

## 目的

Stage 1 では次のものだけを用意する。

- Q# のプロジェクト骨格。
- `BigInt` を使う正確な整数演算。
- 日本語を唯一の人間向け原文とする固定 `SourceLanguageCatalog`。
- 仕様を直接表す test-only oracle。
- oracle と別の production baseline。
- 中立的な base context、dispatcher、validator、metrics/logging shell。
- Q# だけで書かれた回帰テスト。

この段階には、将来の legacy defect、patch、compatibility flag、ghost path、cache scar などを入れない。

## 実行

Microsoft Quantum Development Kit が利用できる環境で、このフォルダーを Q# プロジェクトとして開き、`src/Main.qs` の `Main` を実行する。

テストは `src/Tests.qs` にあり、すべて Q# で記述されている。Python、JavaScript、C#、シェル計算、外部 oracle は使用しない。

## 整数

Q# の組み込み `BigInt` を使用する。浮動小数点は規範計算に使用しない。大きな法は `2^127-1` であり、組合せ数も `BigInt` のまま保持する。

## 名称順序

カツレツ名17件と月名47件には固定 `canonicalIndex` がある。選択、順位付け、unrank は文字列ではなくこの index に従う。日本語文字列は最終表示だけに使う。

## 現在の検証状態

この handoff を作成した環境には Q# の実行環境が存在しなかったため、実行結果を捏造していない。静的構成は作成済みだが、Stage 1 の完了宣言には QDK 上で `Main` を実行し、全テストが成功することが必要である。
