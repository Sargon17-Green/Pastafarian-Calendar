(module
  ;; Esqueleto neutral de producción para la etapa 1.
  ;; No contiene rutas heredadas, parches futuros ni una llamada al oráculo.
  (memory (export "memory") 2 65536)

  (global $heap (mut i32) (i32.const 65536))
  (global $metric_invocations (mut i64) (i64.const 0))
  (global $metric_validations (mut i64) (i64.const 0))

  ;; MonsterContext de la etapa 1, propiedad exclusiva de una invocación.
  ;;  0 calculationDayHandle  i32 (referencia opaca al entero exacto)
  ;;  4 targetDayHandle       i32
  ;;  8 phase                 i32
  ;; 12 subPhase              i32
  ;; 16 mode                  i32
  ;; 20 status                i32
  ;; 24 retryBudget           i32 (neutral; no se consume todavía)
  ;; 28 recoveryDepth         i32
  ;; 32 currentHandler        i32
  ;; 36 previousHandler       i32
  ;; 40 lastErrorCode         i32
  ;; 44 validationFailures    i32
  ;; 48 semanticCommitToken   i32
  ;; 52 observabilityFlags    i32
  ;; 56 reserved              i32
  ;; 60 tamaño total
  (global $CTX_SIZE i32 (i32.const 64))

  ;; Estados neutrales de la etapa 1.
  (global $PHASE_NEW i32 (i32.const 0))
  (global $PHASE_VALIDATE i32 (i32.const 10))
  (global $PHASE_READY i32 (i32.const 20))
  (global $PHASE_DONE i32 (i32.const 30))
  (global $STATUS_NEW i32 (i32.const 0))
  (global $STATUS_OK i32 (i32.const 1))
  (global $STATUS_ERROR i32 (i32.const -1))
  (global $MODE_AUTHORITATIVE_BOOTSTRAP i32 (i32.const 1))

  (func $align8 (param $n i32) (result i32)
    (i32.and (i32.add (local.get $n) (i32.const 7)) (i32.const -8)))

  (func $ensure_bytes (param $end i32)
    (local $have i64) (local $need i64) (local $pages i32)
    (local.set $have (i64.shl (i64.extend_i32_u (memory.size)) (i64.const 16)))
    (local.set $need (i64.extend_i32_u (local.get $end)))
    (if (i64.gt_u (local.get $need) (local.get $have))
      (then
        (local.set $pages
          (i32.wrap_i64
            (i64.shr_u
              (i64.add (i64.sub (local.get $need) (local.get $have)) (i64.const 65535))
              (i64.const 16))))
        (if (i32.eq (memory.grow (local.get $pages)) (i32.const -1)) (then unreachable)))))

  (func $alloc (param $bytes i32) (result i32)
    (local $p i32) (local $end i32)
    (local.set $p (global.get $heap))
    (local.set $end (i32.add (local.get $p) (call $align8 (local.get $bytes))))
    (call $ensure_bytes (local.get $end))
    (global.set $heap (local.get $end))
    (local.get $p))

  (func $zero_context (param $ctx i32)
    (local $p i32)
    (local.set $p (i32.const 0))
    (block $done (loop $again
      (br_if $done (i32.ge_u (local.get $p) (global.get $CTX_SIZE)))
      (i32.store (i32.add (local.get $ctx) (local.get $p)) (i32.const 0))
      (local.set $p (i32.add (local.get $p) (i32.const 4)))
      (br $again))))

  (func $monster_context_new (export "monster_context_new") (param $calculationDayHandle i32) (param $targetDayHandle i32) (result i32)
    (local $ctx i32)
    (local.set $ctx (call $alloc (global.get $CTX_SIZE)))
    (call $zero_context (local.get $ctx))
    (i32.store (local.get $ctx) (local.get $calculationDayHandle))
    (i32.store offset=4 (local.get $ctx) (local.get $targetDayHandle))
    (i32.store offset=8 (local.get $ctx) (global.get $PHASE_NEW))
    (i32.store offset=16 (local.get $ctx) (global.get $MODE_AUTHORITATIVE_BOOTSTRAP))
    (i32.store offset=20 (local.get $ctx) (global.get $STATUS_NEW))
    (i32.store offset=24 (local.get $ctx) (i32.const 0))
    (global.set $metric_invocations (i64.add (global.get $metric_invocations) (i64.const 1)))
    (local.get $ctx))

  ;; Validador neutral: solo comprueba integridad estructural del contexto.
  ;; Los manejadores de día son opacos en esta etapa y no se interpretan aquí.
  (func $validate_context (param $ctx i32) (result i32)
    (global.set $metric_validations (i64.add (global.get $metric_validations) (i64.const 1)))
    (if (i32.eqz (local.get $ctx))
      (then (return (i32.const 0))))
    (if (i32.ne (i32.load offset=16 (local.get $ctx)) (global.get $MODE_AUTHORITATIVE_BOOTSTRAP))
      (then
        (i32.store offset=40 (local.get $ctx) (i32.const 1001))
        (i32.store offset=44 (local.get $ctx) (i32.add (i32.load offset=44 (local.get $ctx)) (i32.const 1)))
        (return (i32.const 0))))
    (i32.const 1))

  ;; Despachador neutral. No calcula todavía una fecha de producción.
  (func $monster_dispatch_bootstrap (export "monster_dispatch_bootstrap") (param $ctx i32) (result i32)
    (if (i32.eqz (local.get $ctx)) (then (return (i32.const 0))))
    (i32.store offset=8 (local.get $ctx) (global.get $PHASE_VALIDATE))
    (i32.store offset=32 (local.get $ctx) (i32.const 1))
    (if (i32.eqz (call $validate_context (local.get $ctx)))
      (then
        (i32.store offset=20 (local.get $ctx) (global.get $STATUS_ERROR))
        (return (i32.const 0))))
    (i32.store offset=36 (local.get $ctx) (i32.load offset=32 (local.get $ctx)))
    (i32.store offset=32 (local.get $ctx) (i32.const 2))
    (i32.store offset=8 (local.get $ctx) (global.get $PHASE_READY))
    ;; Confirmación neutral: solo cambia el ciclo de vida; no existe estado semántico calculado todavía.
    (i32.store offset=48 (local.get $ctx) (i32.const 1))
    (i32.store offset=8 (local.get $ctx) (global.get $PHASE_DONE))
    (i32.store offset=20 (local.get $ctx) (global.get $STATUS_OK))
    (i32.const 1))

  (func (export "monster_context_phase") (param $ctx i32) (result i32) (i32.load offset=8 (local.get $ctx)))
  (func (export "monster_context_status") (param $ctx i32) (result i32) (i32.load offset=20 (local.get $ctx)))
  (func (export "monster_context_commit_token") (param $ctx i32) (result i32) (i32.load offset=48 (local.get $ctx)))
  (func (export "metric_invocations") (result i64) (global.get $metric_invocations))
  (func (export "metric_validations") (result i64) (global.get $metric_validations))

  (func (export "test_contexts_are_invocation_owned") (result i32)
    (local $a i32) (local $b i32)
    (local.set $a (call $monster_context_new (i32.const 111) (i32.const 222)))
    (local.set $b (call $monster_context_new (i32.const 333) (i32.const 444)))
    (i32.and
      (i32.ne (local.get $a) (local.get $b))
      (i32.and
        (i32.eq (i32.load (local.get $a)) (i32.const 111))
        (i32.eq (i32.load (local.get $b)) (i32.const 333)))))

  (func (export "test_bootstrap_dispatch") (result i32)
    (local $ctx i32)
    (local.set $ctx (call $monster_context_new (i32.const 1) (i32.const 2)))
    (if (i32.eqz (call $monster_dispatch_bootstrap (local.get $ctx))) (then (return (i32.const 0))))
    (i32.and
      (i32.eq (i32.load offset=8 (local.get $ctx)) (global.get $PHASE_DONE))
      (i32.and
        (i32.eq (i32.load offset=20 (local.get $ctx)) (global.get $STATUS_OK))
        (i32.eq (i32.load offset=48 (local.get $ctx)) (i32.const 1)))))
)
