# Go + Kotava — Stage 1

Bat kobara tir taneafa nesida ke Go is Kotava.

`SourceLanguageCatalog` va 17 krimbaxaf yolt is 47 aksataf yolt ponar. Ranmara va `canonicalIndex` rapar; me va sutera ke yolt rapar. Kotavaf yolt koe finafa rupa zo faver.

`internal/testoracle` tir test-only `NormativeReference`. In va Appendix A nemon implementar, aze kan `math/big` va kota vaja otukara rokur. Production va bata reference me faver.

`monster` va taneafa stara ponar: `Context`, `Dispatcher`, `ValidationManager`, `MonsterError`, `Metrics` is `EventLog`. Bat stara tir neutrala. Meka legacy patch ke radimafa nesida koe bata production tir.

Kobara mal doza zo redur. Ar implementafa artifact, hash, fixture, output ik differential test me zo faver.

## Robara

```text
go test ./...
go vet ./...
go run ./cmd/stage01check
```

Alerafa tuzara:

```text
STAGE01_GREEN
```
