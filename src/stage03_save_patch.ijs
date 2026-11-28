NB. Stage 3 / PATCH 01: înveliș peste restul istoric; restVechi rămâne intact.
salvarePatch01=: 3 : 0
  r=. dispecerRestVechi y
  if. r = 0x do.
    r=. MODUL_REST_VECHI
  end.
  r
)

NB. Ruta activă trece prin înveliș; dispecerul vechi rămâne accesibil.
calendarSalvareSpaghete=: 3 : 0
  salvarePatch01 y
)
