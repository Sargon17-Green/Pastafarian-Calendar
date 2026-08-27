# Arquitetura de Stage 1

## Objetos base

`MonsterContext.ctl` debe es un cluster typedef par un invocation sola. En Stage 1, lo conteni sola campos neutral:

- `calculationDay`
- `targetDay`
- `phase`
- `subPhase`
- `mode`
- `status`
- `retryBudget`
- `recoveryDepth`
- `currentHandler`
- `previousHandler`
- `branchTrace`
- `metrics`
- `logs`
- `diagnostics`
- `warnings`
- `lastError`
- `validationFailures`

No campo spesifia de patches 01–26 es permitida ora.

## Proprieta de state

State semantical es privada a un invocation e usa la patron `snapshot -> compute -> validate -> commit`. Logs, metrics, diagnostics e warnings es observabil sola e no pote es lejeda per un deside normativa.

## Capas base

- `MonsterManager.lvclass`: posese referencias a dispatcher, validator, error wrapper e managers observabil.
- `MonsterDispatcher.lvclass`: route sola fases de Bootstrap, sin branch de patch futur.
- `MonsterValidationManager.lvclass`: proba invariantes; failure produi error, no un normalisa silente.
- `MonsterErrorWrapper.lvclass`: ajunta contexto deterministe a errors.
- `MonsterMetricsManager.lvclass`: observa sola; no retorna un valua usada par semantica.
- `MonsterLogManager.lvclass`: registra sola; no retorna un valua usada par semantica.

## Oracle

La oracle es sola en `tests/oracle/` e debe implementa direta la referensa normativa en G. Production no pote linka a la biblioteca oracle.

## Enteros esata

LabVIEW integer natives no es suficiente per tota contas combinatorial. Stage 1 debe crea un tipo `BigNat` e `BigInt` en G sola. La representa recomendada es un array little-endian de limbs `U32`, con sinia separada per `BigInt`. Tota operas debe es esata e no usa floating point.

Operas minima: compara, addi, sutrae, multia, square, floorDiv nonnegative, regularMod, pow2, pow, factorial, fallingFactorial, serialisa per debug, e parse de constantes decimal.
