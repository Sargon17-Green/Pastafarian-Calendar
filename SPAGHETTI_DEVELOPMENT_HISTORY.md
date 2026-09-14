# Kasaysayan ng Paglago ng Spaghetti Monster

## Stage 1 — Bootstrap

### Ano ang itinayo

Nilikha mula sa wala ang PowerShell project tree, ang malinis na normative oracle, ang test harness, ang frozen source-language catalog, at ang neutral na pundasyon ng magiging monster architecture.

### Ano ang sadyang hindi pa umiiral

Wala pang maling legacy remainder, maling day tag, maling distance, in-place stone mutation, backward hidden storage, sentinel grind table, zero-based rank scar, bowl alias, shadow bowl patch, order-at-46 latch, biased selector, wide detour, gate-side scar, year-5781 scar, cache scar, ghost structure sauce, cutlet filter scar, repeated-name scar, virtual legacy list scar, weaving ghost, contiguous-month ghost, o opening-gate scar.

Hindi isinulat nang maaga ang kasaysayan ng alinmang patch. Lalabas lamang ang bawat sugat sa sarili nitong DISCOVERY at PATCH stage.

### Neutral na monster layer

May base invocation context, dispatcher, validation manager, error wrapper, metrics shell, at deterministic log shell. Ang mga ito ay walang normative policy at hindi nagbabasa ng observability state para magpasya ng sagot.

### Pagmamay-ari ng state

Ang semantic state ay pag-aari ng isang invocation context lamang. Ang base shell ay walang mutable semantic global state. Ang metrics at logs ay observability lamang at hindi input sa oracle o sa production skeleton.

## Stage 2 — Discovery 01: legacy remainder

### Natuklasang sugat

Idinagdag sa production path ang makasaysayang pag-uugaling:

```text
oldRemainder(x) = regularMod(x, M)
```

Kapag eksaktong multiple ng `M` ang input, ibinabalik nito ang `0`. Salungat ito sa normative `SAVE`, na nagmamapa sa naturang residue sa `M`.

### Eksaktong regression surface

Ang Discovery 01 verification ay sadyang nangangailangan ng sumusunod:

- `M`: legacy `0`, normative `M`, `EXPECTED_RED`.
- `2M`: legacy `0`, normative `M`, `EXPECTED_RED`.
- `3M`: legacy `0`, normative `M`, `EXPECTED_RED`.
- `M+1`: legacy `1`, normative `1`, tugma.

Ang stable discovery identifier para sa divergence ay `Pastafari:Discovery01:LegacyRemainderDivergence`.

### Production route at ownership

Ang `Invoke-CalendarDateSpaghetti` ay dumadaan sa base dispatcher at saka sa `Invoke-Discovery01LegacyAdapter`. Ang adapter lamang ang tumatawag sa `oldRemainder`. Ang `legacyRemainderInput`, `legacyRemainderValue`, at `discovery01Status` ay pag-aari ng sariling invocation context at dumadaan sa semantic transaction bago ma-commit.

### Sadyang hindi pa inaayos

Walang `savePatch`, walang `0 -> M` correction, at walang code mula sa Stage 3 o sa alinmang mas huling historical patch.
