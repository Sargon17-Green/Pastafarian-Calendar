# Kasaysayan ng Paglago ng Spaghetti Monster

## Stage 1 — Bootstrap

### Ano ang itinayo

Nilikha mula sa wala ang PowerShell project tree, ang malinis na normative oracle, ang test harness, ang frozen source-language catalog, at ang neutral na pundasyon ng magiging monster architecture.

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

Napatunayan sa aktuwal na Windows PowerShell 5.1 ang sumusunod:

- `M`: legacy `0`, normative `M`, `EXPECTED_RED`.
- `2M`: legacy `0`, normative `M`, `EXPECTED_RED`.
- `3M`: legacy `0`, normative `M`, `EXPECTED_RED`.
- `M+1`: legacy `1`, normative `1`, tugma.

Ang stable discovery identifier ay `Pastafari:Discovery01:LegacyRemainderDivergence`.

### Production route at ownership

Ang Discovery 01 adapter ay nagtatala ng `legacyRemainderInput` at `legacyRemainderValue` sa sariling invocation context at dumadaan sa semantic transaction bago mag-commit.

## Stage 3 — Patch 01: save correction

### Correction

Idinagdag ang `savePatch`, na tumatanggap ng output ng `oldRemainder` at gumagawa lamang ng isang correction:

```text
0 -> M
```

Lahat ng nonzero legacy remainder ay ibinabalik nang walang pagbabago.

### Historical scar retention

Hindi binura, pinalitan, o itinago ang `oldRemainder`. Maaari pa ring tawagin nang direkta ang legacy function at mapatunayan ang Stage 2 defect. Ang Patch 01 ay isang hiwalay na layer sa ibabaw nito.

### Kasalukuyang production route

Ang `Invoke-CalendarDateSpaghetti` ay dumadaan sa `Invoke-Patch01SaveAdapter`. Kinukuha ng adapter ang legacy remainder, ina-apply ang `savePatch`, at nagko-commit ng parehong legacy at patched value sa sariling invocation context.

### Inaasahang estado

Ang Stage 3 production result ay GREEN para sa dating divergent cases at para sa mga control case, habang nananatiling hiwalay at deterministic ang semantic state.

Wala pang Stage 4 discovery behavior.
