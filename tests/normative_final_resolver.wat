(module
  ;; Resolver final limpio: trabaja solo con IDs canónicos; las cadenas españolas son presentación.
  (memory (export "memory") 2)

  ;; Chuleta: [firstDay i64, lastDay i64, canonicalNameIndex i32, relleno i32], 24 bytes.
  ;; Entrelazado: i32 monthId por día; monthNames: i32 canonicalNameIndex por monthId-1.
  ;; Resultado: año i64, índice del nombre de chuleta i32, día de chuleta i32, índice del nombre de mes i32 y día de mes i32.
  (global $RESULT i32 (i32.const 4096))

  (func $cutlet_addr (param $base i32) (param $i i32) (result i32)
    (i32.add (local.get $base) (i32.mul (local.get $i) (i32.const 24))))

  (func $resolve
    (param $yearNumber i64) (param $openDay i64) (param $targetDay i64)
    (param $cutletCount i32) (param $cutlets i32)
    (param $weave i32) (param $monthNames i32)
    (param $dst i32)
    (local $i i32) (local $ca i32) (local $chosen i32)
    (local $first i64) (local $last i64) (local $offset i32)
    (local $monthId i32) (local $p i32) (local $dayInMonth i32)

    (local.set $chosen (i32.const -1))
    (local.set $i (i32.const 0))
    (block $found
      (loop $scan
        (br_if $found (i32.ge_u (local.get $i) (local.get $cutletCount)))
        (local.set $ca (call $cutlet_addr (local.get $cutlets) (local.get $i)))
        (local.set $first (i64.load (local.get $ca)))
        (local.set $last (i64.load offset=8 (local.get $ca)))
        (if (i32.and
              (i64.ge_s (local.get $targetDay) (local.get $first))
              (i64.le_s (local.get $targetDay) (local.get $last)))
          (then
            (local.set $chosen (local.get $i))
            (br $found)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $scan)))
    (if (i32.lt_s (local.get $chosen) (i32.const 0)) (then unreachable))

    (local.set $ca (call $cutlet_addr (local.get $cutlets) (local.get $chosen)))
    (local.set $first (i64.load (local.get $ca)))
    (local.set $offset
      (i32.wrap_i64 (i64.sub (local.get $targetDay) (i64.add (local.get $openDay) (i64.const 1)))))
    (if (i32.lt_s (local.get $offset) (i32.const 0)) (then unreachable))
    (local.set $monthId
      (i32.load (i32.add (local.get $weave) (i32.mul (local.get $offset) (i32.const 4)))))
    (if (i32.le_s (local.get $monthId) (i32.const 0)) (then unreachable))

    (local.set $p (i32.const 0))
    (local.set $dayInMonth (i32.const 0))
    (block $done
      (loop $count
        (br_if $done (i32.gt_u (local.get $p) (local.get $offset)))
        (if (i32.eq
              (i32.load (i32.add (local.get $weave) (i32.mul (local.get $p) (i32.const 4))))
              (local.get $monthId))
          (then
            (local.set $dayInMonth
              (i32.add (local.get $dayInMonth) (i32.const 1)))))
        (local.set $p (i32.add (local.get $p) (i32.const 1)))
        (br $count)))

    (i64.store (local.get $dst) (local.get $yearNumber))
    (i32.store offset=8 (local.get $dst) (i32.load offset=16 (local.get $ca)))
    (i32.store offset=12 (local.get $dst)
      (i32.add (i32.wrap_i64 (i64.sub (local.get $targetDay) (local.get $first))) (i32.const 1)))
    (i32.store offset=16 (local.get $dst)
      (i32.load
        (i32.add (local.get $monthNames) (i32.mul (i32.sub (local.get $monthId) (i32.const 1)) (i32.const 4)))))
    (i32.store offset=20 (local.get $dst) (local.get $dayInMonth))
  )
  (func $prepare_interleaved_fixture
    ;; Año (100,110]: dos chuletas; tejido 1,2 repetido durante diez días.
    (i64.store (i32.const 8192) (i64.const 101))
    (i64.store offset=8 (i32.const 8192) (i64.const 105))
    (i32.store offset=16 (i32.const 8192) (i32.const 7))
    (i64.store (i32.const 8216) (i64.const 106))
    (i64.store offset=8 (i32.const 8216) (i64.const 110))
    (i32.store offset=16 (i32.const 8216) (i32.const 9))
    (i32.store (i32.const 9000) (i32.const 1))
    (i32.store offset=4 (i32.const 9000) (i32.const 2))
    (i32.store offset=8 (i32.const 9000) (i32.const 1))
    (i32.store offset=12 (i32.const 9000) (i32.const 2))
    (i32.store offset=16 (i32.const 9000) (i32.const 1))
    (i32.store offset=20 (i32.const 9000) (i32.const 2))
    (i32.store offset=24 (i32.const 9000) (i32.const 1))
    (i32.store offset=28 (i32.const 9000) (i32.const 2))
    (i32.store offset=32 (i32.const 9000) (i32.const 1))
    (i32.store offset=36 (i32.const 9000) (i32.const 2))
    (i32.store (i32.const 9100) (i32.const 31))
    (i32.store offset=4 (i32.const 9100) (i32.const 47))
    (call $resolve
      (i64.const 5000) (i64.const 100) (i64.const 109)
      (i32.const 2) (i32.const 8192) (i32.const 9000) (i32.const 9100)
      (global.get $RESULT)))

  (func (export "test_final_resolver_interleaved") (result i32)
    (call $prepare_interleaved_fixture)
    (if (i64.ne (i64.load (global.get $RESULT)) (i64.const 5000)) (then (return (i32.const 0))))
    (if (i32.ne (i32.load offset=8 (global.get $RESULT)) (i32.const 9)) (then (return (i32.const 0))))
    (if (i32.ne (i32.load offset=12 (global.get $RESULT)) (i32.const 4)) (then (return (i32.const 0))))
    (if (i32.ne (i32.load offset=16 (global.get $RESULT)) (i32.const 31)) (then (return (i32.const 0))))
    (if (i32.ne (i32.load offset=20 (global.get $RESULT)) (i32.const 5)) (then (return (i32.const 0))))
    (i32.const 1))

  (func (export "result_ptr") (result i32) (global.get $RESULT))
)
