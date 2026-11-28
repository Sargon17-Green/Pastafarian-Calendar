NB. PATCH 02: înveliș peste dispecerul istoric, fără repararea sursei vechi.
etichetaZiPatch02=: 3 : 0
  n=. dispecerEtichetaZiVeche y
  if. y >: FUNDATIE_ETICHETA_VECHE do.
    n=. n + 1x
  end.
  if. (y = FUNDATIE_ETICHETA_VECHE) *. n ~: 1x do.
    n=. 1x
  end.
  n
)

calendarEtichetaZiSpaghete=: 3 : 0
  etichetaZiPatch02 y
)
