NB. Stage 4 / DISCOVERY 02: exact positive-residue SAVE primitive for later sauce.
NB. Production-only arithmetic; never imports the test oracle or changes the public context.

STAGE04_SAVE_MODULUS=: <: 2x ^ 127

stage04Save=: 3 : 0
  NB. Exact integer/rational input, canonicalized to J extended integer.
  whole=. stage02CanonicalDay y
  NB. 1-based residue: SAVE(n)=1+((n-1) mod M), including n=0 and negatives.
  1x + STAGE04_SAVE_MODULUS | (whole - 1x)
)

stage04SaveCounts=: 3 : 0
  NB. Helper for precisely the five working counts; not the final calendar date.
  assert. 1 = # $ y
  assert. 5 = # y
  stage04Save"0 y
)
