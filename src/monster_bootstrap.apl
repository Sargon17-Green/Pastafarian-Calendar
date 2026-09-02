⍝ Neutrale Monster-Grundlage. Keine spätere Alt- oder Korrekturlogik ist in Stufe 1 zulässig.
⍝ Jeder Aufruf besitzt seinen Kontext vollständig selbst. Globale Werte in dieser Datei sind nur unveränderliche Feldpositionen.

∇ MonsterBootstrapInit
  ⎕IO←1
  ⎕CT←0
  CTX_CALCULATION_DAY←1
  CTX_TARGET_DAY←2
  CTX_PHASE←3
  CTX_SUBPHASE←4
  CTX_MODE←5
  CTX_STATUS←6
  CTX_RETRY_BUDGET←7
  CTX_RECOVERY_DEPTH←8
  CTX_BRANCH_TRACE←9
  CTX_METRICS←10
  CTX_LOGS←11
  CTX_COMMITTED←12
  CTX_PENDING←13
  CTX_ROLLBACK←14
  CTX_COMMIT_TOKEN←15
  CTX_LAST_ERROR←16
  CTX_VALIDATION_FAILURES←17
  CTX_OBSERVATION_ENABLED←18
  MONSTER_CONTEXT_FIELD_COUNT←18
∇

∇ z←MonsterIsExactInteger x;dr;parts
  :If 0≠⍴⍴x
      z←0 ⋄ :Return
  :EndIf
  dr←⎕DR x
  :If dr=14
      parts←4 ⎕DR x
      z←parts[2]=1
  :Else
      z←(dr=6412)∨dr=110
  :EndIf
∇

∇ z←MonsterExactDay x
  :If ~MonsterIsExactInteger x
      ⎕ERROR 'Ein diskreter Tag muss ein skalarer exakter Ganzzahlwert ohne Gleitkommadarstellung sein.'
  :EndIf
  z←x×1x
∇

∇ z←c MonsterNewContext t;cc;tt;committed
  cc←MonsterExactDay c
  tt←MonsterExactDay t
  committed←cc tt
  z←(⊂cc),(⊂tt),(⊂'BOOTSTRAP'),(⊂0),(⊂'AUTHORITATIVE_BOOTSTRAP'),(⊂'NEW'),(⊂2),(⊂0),(⊂⍬),(⊂0 0 0),(⊂⍬),(⊂committed),(⊂⍬),(⊂⍬),(⊂0),(⊂''),(⊂0),(⊂1)
∇

∇ z←MonsterBaseValidate ctx;c;t;committed;pending;rollback
  :If MONSTER_CONTEXT_FIELD_COUNT≠⍴ctx
      z←0 ⋄ :Return
  :EndIf
  c←⊃ctx[CTX_CALCULATION_DAY]
  t←⊃ctx[CTX_TARGET_DAY]
  :If (~MonsterIsExactInteger c)∨~MonsterIsExactInteger t
      z←0 ⋄ :Return
  :EndIf
  committed←⊃ctx[CTX_COMMITTED]
  :If ~((2=⍴committed)∨4=⍴committed)
      z←0 ⋄ :Return
  :EndIf
  :If ~∧/(2↑committed)=c t
      z←0 ⋄ :Return
  :EndIf
  :If (4=⍴committed)∧~ctx MonsterBaseValidateCandidate committed
      z←0 ⋄ :Return
  :EndIf
  pending←⊃ctx[CTX_PENDING]
  rollback←⊃ctx[CTX_ROLLBACK]
  :If ~((0=⍴pending)∨4=⍴pending)
      z←0 ⋄ :Return
  :EndIf
  :If (4=⍴pending)∧~ctx MonsterBaseValidateCandidate pending
      z←0 ⋄ :Return
  :EndIf
  :If ~((0=⍴rollback)∨(2=⍴rollback)∨4=⍴rollback)
      z←0 ⋄ :Return
  :EndIf
  :If (0<⍴rollback)∧~∧/(2↑rollback)=c t
      z←0 ⋄ :Return
  :EndIf
  :If (4=⍴rollback)∧~ctx MonsterBaseValidateCandidate rollback
      z←0 ⋄ :Return
  :EndIf
  :If (~MonsterIsExactInteger ⊃ctx[CTX_RETRY_BUDGET])∨(⊃ctx[CTX_RETRY_BUDGET])<0
      z←0 ⋄ :Return
  :EndIf
  :If (~MonsterIsExactInteger ⊃ctx[CTX_RECOVERY_DEPTH])∨(⊃ctx[CTX_RECOVERY_DEPTH])<0
      z←0 ⋄ :Return
  :EndIf
  :If (~MonsterIsExactInteger ⊃ctx[CTX_COMMIT_TOKEN])∨(⊃ctx[CTX_COMMIT_TOKEN])<0
      z←0 ⋄ :Return
  :EndIf
  :If 3≠⍴⊃ctx[CTX_METRICS]
      z←0 ⋄ :Return
  :EndIf
  :If ~((⊃ctx[CTX_OBSERVATION_ENABLED])∊0 1)
      z←0 ⋄ :Return
  :EndIf
  z←1
∇

∇ z←MonsterBaseCandidate ctx;c;t
  c←⊃ctx[CTX_CALCULATION_DAY]
  t←⊃ctx[CTX_TARGET_DAY]
  z←c t (c+t) (1+(|t-c))
∇

∇ z←ctx MonsterBaseValidateCandidate candidate;c;t
  :If 4≠⍴candidate
      z←0 ⋄ :Return
  :EndIf
  c←⊃ctx[CTX_CALCULATION_DAY]
  t←⊃ctx[CTX_TARGET_DAY]
  z←(candidate[1]=c)∧(candidate[2]=t)∧(candidate[3]=(c+t))∧(candidate[4]=(1+(|t-c)))
∇

∇ z←MonsterBaseDispatch ctx;trace;logs
  :If ~MonsterBaseValidate ctx
      ⎕ERROR 'Interner Bootstrap-Invariantenfehler.'
  :EndIf
  ctx[CTX_PHASE]←⊂'BOOTSTRAP_DISPATCH'
  ctx[CTX_STATUS]←⊂'READY'
  trace←⊃ctx[CTX_BRANCH_TRACE]
  ctx[CTX_BRANCH_TRACE]←⊂trace,⊂'DISPATCH'
  :If ⊃ctx[CTX_OBSERVATION_ENABLED]
      logs←⊃ctx[CTX_LOGS]
      ctx[CTX_LOGS]←⊂logs,⊂'Bootstrap-Verteiler betreten'
  :EndIf
  z←ctx
∇

∇ z←ctx MonsterBaseRunTransaction failures;budget;attempt;remainingFailures;rollback;candidate;metrics;trace;logs
  :If ~MonsterBaseValidate ctx
      ⎕ERROR 'Interner Bootstrap-Invariantenfehler.'
  :EndIf
  :If (~MonsterIsExactInteger failures)∨(failures<0)
      ⎕ERROR 'Interner Bootstrap-Invariantenfehler.'
  :EndIf
  budget←⊃ctx[CTX_RETRY_BUDGET]
  attempt←0
  remainingFailures←failures
  :Repeat
      attempt←attempt+1
      rollback←⊃ctx[CTX_COMMITTED]
      ctx[CTX_ROLLBACK]←⊂rollback
      candidate←MonsterBaseCandidate ctx
      ctx[CTX_PENDING]←⊂candidate
      metrics←⊃ctx[CTX_METRICS]
      metrics[1]←metrics[1]+1
      ctx[CTX_METRICS]←⊂metrics
      :If ~ctx MonsterBaseValidateCandidate candidate
          ctx[CTX_COMMITTED]←⊂rollback
          ctx[CTX_PENDING]←⊂⍬
          ctx[CTX_ROLLBACK]←⊂⍬
          ctx[CTX_STATUS]←⊂'VALIDATION_FAILED'
          ctx[CTX_LAST_ERROR]←⊂'BOOTSTRAP_CANDIDATE_INVALID'
          ctx[CTX_VALIDATION_FAILURES]←⊂1+⊃ctx[CTX_VALIDATION_FAILURES]
          ⎕ERROR 'Die neutrale Kandidatenvalidierung ist fehlgeschlagen; es wird keine Teilantwort zurückgegeben.'
      :EndIf
      :If remainingFailures>0
          ctx[CTX_COMMITTED]←⊂rollback
          ctx[CTX_PENDING]←⊂⍬
          ctx[CTX_ROLLBACK]←⊂⍬
          ctx[CTX_RECOVERY_DEPTH]←⊂1+⊃ctx[CTX_RECOVERY_DEPTH]
          metrics←⊃ctx[CTX_METRICS]
          metrics[2]←metrics[2]+1
          ctx[CTX_METRICS]←⊂metrics
          trace←⊃ctx[CTX_BRANCH_TRACE]
          ctx[CTX_BRANCH_TRACE]←⊂trace,⊂'EXACT_ROLLBACK'
          :If ⊃ctx[CTX_OBSERVATION_ENABLED]
              logs←⊃ctx[CTX_LOGS]
              ctx[CTX_LOGS]←⊂logs,⊂'Deterministischer Testfehler; exakte Wiederherstellung ausgeführt'
          :EndIf
          remainingFailures←remainingFailures-1
          :If attempt>budget
              ctx[CTX_STATUS]←⊂'RETRY_EXHAUSTED'
              ctx[CTX_LAST_ERROR]←⊂'BOOTSTRAP_RETRY_EXHAUSTED'
              ⎕ERROR 'Das feste Wiederholungsbudget ist erschöpft; es wird keine Ersatzantwort zurückgegeben.'
          :EndIf
      :Else
          ctx[CTX_COMMITTED]←⊂candidate
          ctx[CTX_PENDING]←⊂⍬
          ctx[CTX_ROLLBACK]←⊂⍬
          ctx[CTX_COMMIT_TOKEN]←⊂1+⊃ctx[CTX_COMMIT_TOKEN]
          metrics←⊃ctx[CTX_METRICS]
          metrics[3]←metrics[3]+1
          ctx[CTX_METRICS]←⊂metrics
          ctx[CTX_STATUS]←⊂'BOOTSTRAP_OK'
          ctx[CTX_LAST_ERROR]←⊂''
          z←ctx ⋄ :Return
      :EndIf
  :EndRepeat
∇

∇ z←MonsterBaseExecute ctx
  ctx←MonsterBaseDispatch ctx
  ctx←ctx MonsterBaseRunTransaction 0
  :If ~'BOOTSTRAP_OK'≡⊃ctx[CTX_STATUS]
      ⎕ERROR 'Interner Bootstrap-Invariantenfehler.'
  :EndIf
  :If ~MonsterBaseValidate ctx
      ⎕ERROR 'Interner Bootstrap-Invariantenfehler.'
  :EndIf
  z←ctx
∇

∇ z←MonsterBaseSemanticState ctx
  z←⊃ctx[CTX_COMMITTED]
∇

∇ z←MonsterBasePendingIsEmpty ctx
  z←0=⍴⊃ctx[CTX_PENDING]
∇

∇ z←MonsterBaseRollbackIsEmpty ctx
  z←0=⍴⊃ctx[CTX_ROLLBACK]
∇
