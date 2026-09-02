# Stage 1 アーキテクチャ

Stage 1 は、後の歴史的な傷を先取りしない最小限の基盤だけを持つ。

`Pastafari.CanonicalCore` は production baseline の規範計算を保持する。`Pastafari.NormativeOracle` は test-only の独立名前空間として同じ組み込み仕様を直接実装し、production から参照しない。

`Pastafari.ProductionBaseline.CalendarDateSpaghetti` は中立的な `BaseMonsterContext` と `BaseDispatcher` を通過した後、production baseline を呼ぶ。ここには legacy path、patch-specific flag、retry/recovery、cache、ghost computation はまだ存在しない。

`Pastafari.MonsterInfrastructure` は将来の複雑化のための一般的な入れ物だけを提供する。現在の metrics と log の tick は観測状態であり、規範結果へ読み戻されない。

意味論的な値は Q# の不変値として関数間を渡す。Stage 1 の base context も呼び出しごとに新規生成され、別 invocation と共有しない。
