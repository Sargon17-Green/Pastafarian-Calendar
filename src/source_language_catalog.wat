(module
  ;; SourceLanguageCatalog congelado de la etapa 1.
  ;; La semántica usa exclusivamente canonicalIndex; las cadenas solo son presentación.
  (memory (export "memory") 1)
  (global $CUTLET_BASE i32 (i32.const 4096))
  (global $MONTH_BASE i32 (i32.const 8192))
  (global $STRIDE i32 (i32.const 64))

  (data (i32.const 4096) "Bronce\00")
  (data (i32.const 4160) "Zorro\00")
  (data (i32.const 4224) "Riñón\00")
  (data (i32.const 4288) "Lagash\00")
  (data (i32.const 4352) "Pensamiento\00")
  (data (i32.const 4416) "Cuatro novenos\00")
  (data (i32.const 4480) "Palgurash\00")
  (data (i32.const 4544) "Papiro\00")
  (data (i32.const 4608) "Racimo\00")
  (data (i32.const 4672) "Escorpión\00")
  (data (i32.const 4736) "Ceniza\00")
  (data (i32.const 4800) "Trigo\00")
  (data (i32.const 4864) "Río\00")
  (data (i32.const 4928) "Risa\00")
  (data (i32.const 4992) "Acad\00")
  (data (i32.const 5056) "Cuerno\00")
  (data (i32.const 5120) "La jarra vacía\00")

  (data (i32.const 8192) "Arcilla\00")
  (data (i32.const 8256) "Granada\00")
  (data (i32.const 8320) "Codo\00")
  (data (i32.const 8384) "Envidia\00")
  (data (i32.const 8448) "Eridu\00")
  (data (i32.const 8512) "Pasta de dientes\00")
  (data (i32.const 8576) "Tres quintos\00")
  (data (i32.const 8640) "Karshumav\00")
  (data (i32.const 8704) "Leopardo\00")
  (data (i32.const 8768) "Estaño\00")
  (data (i32.const 8832) "Niebla\00")
  (data (i32.const 8896) "Olíbano\00")
  (data (i32.const 8960) "Huso\00")
  (data (i32.const 9024) "Costilla\00")
  (data (i32.const 9088) "Algarroba\00")
  (data (i32.const 9152) "Uruk\00")
  (data (i32.const 9216) "Vergüenza\00")
  (data (i32.const 9280) "Camello\00")
  (data (i32.const 9344) "Cobre\00")
  (data (i32.const 9408) "Pozo\00")
  (data (i32.const 9472) "Yema\00")
  (data (i32.const 9536) "Estrella\00")
  (data (i32.const 9600) "Miel\00")
  (data (i32.const 9664) "Bazo\00")
  (data (i32.const 9728) "Piedra caliza\00")
  (data (i32.const 9792) "Alegría\00")
  (data (i32.const 9856) "Higo\00")
  (data (i32.const 9920) "Nínive\00")
  (data (i32.const 9984) "Rana\00")
  (data (i32.const 10048) "Alquitrán\00")
  (data (i32.const 10112) "Vela\00")
  (data (i32.const 10176) "La puerta cerrada\00")
  (data (i32.const 10240) "Sésamo\00")
  (data (i32.const 10304) "Nuca\00")
  (data (i32.const 10368) "Plata\00")
  (data (i32.const 10432) "Susa\00")
  (data (i32.const 10496) "Tormenta\00")
  (data (i32.const 10560) "Asno\00")
  (data (i32.const 10624) "Harina\00")
  (data (i32.const 10688) "Arrepentimiento\00")
  (data (i32.const 10752) "Babilonia\00")
  (data (i32.const 10816) "Lengua\00")
  (data (i32.const 10880) "Lino\00")
  (data (i32.const 10944) "Sal\00")
  (data (i32.const 11008) "Pera\00")
  (data (i32.const 11072) "Arco\00")
  (data (i32.const 11136) "Arena\00")

  (func $ptr (param $base i32) (param $index i32) (param $max i32) (result i32)
    (if (i32.or (i32.lt_s (local.get $index) (i32.const 1)) (i32.gt_s (local.get $index) (local.get $max)))
      (then (return (i32.const 0))))
    (i32.add (local.get $base) (i32.mul (i32.sub (local.get $index) (i32.const 1)) (global.get $STRIDE))))

  (func (export "catalog_cutlet_ptr") (param $canonicalIndex i32) (result i32)
    (call $ptr (global.get $CUTLET_BASE) (local.get $canonicalIndex) (i32.const 17)))
  (func (export "catalog_month_ptr") (param $canonicalIndex i32) (result i32)
    (call $ptr (global.get $MONTH_BASE) (local.get $canonicalIndex) (i32.const 47)))

  (func (export "catalog_strlen") (param $p i32) (result i32)
    (local $n i32)
    (if (i32.eqz (local.get $p)) (then (return (i32.const 0))))
    (local.set $n (i32.const 0))
    (block $done (loop $again
      (br_if $done (i32.eqz (i32.load8_u (i32.add (local.get $p) (local.get $n)))))
      (local.set $n (i32.add (local.get $n) (i32.const 1)))
      (br $again)))
    (local.get $n))

  (func $byte_eq (param $p i32) (param $off i32) (param $v i32) (result i32)
    (i32.eq (i32.load8_u (i32.add (local.get $p) (local.get $off))) (local.get $v)))

  (func (export "test_catalog_reconciled_toponyms") (result i32)
    (local $lagash i32) (local $acad i32) (local $susa i32)
    (local.set $lagash (call $ptr (global.get $CUTLET_BASE) (i32.const 4) (i32.const 17)))
    (local.set $acad (call $ptr (global.get $CUTLET_BASE) (i32.const 15) (i32.const 17)))
    (local.set $susa (call $ptr (global.get $MONTH_BASE) (i32.const 36) (i32.const 47)))
    (i32.and
      (i32.and
        (i32.eq (call 3 (local.get $lagash)) (i32.const 6))
        (i32.and
          (call $byte_eq (local.get $lagash) (i32.const 0) (i32.const 76))
          (i32.and
            (call $byte_eq (local.get $lagash) (i32.const 1) (i32.const 97))
            (i32.and
              (call $byte_eq (local.get $lagash) (i32.const 2) (i32.const 103))
              (i32.and
                (call $byte_eq (local.get $lagash) (i32.const 3) (i32.const 97))
                (i32.and
                  (call $byte_eq (local.get $lagash) (i32.const 4) (i32.const 115))
                  (call $byte_eq (local.get $lagash) (i32.const 5) (i32.const 104))))))))
      (i32.and
        (i32.and
          (i32.eq (call 3 (local.get $acad)) (i32.const 4))
          (i32.and
            (call $byte_eq (local.get $acad) (i32.const 0) (i32.const 65))
            (i32.and
              (call $byte_eq (local.get $acad) (i32.const 1) (i32.const 99))
              (i32.and
                (call $byte_eq (local.get $acad) (i32.const 2) (i32.const 97))
                (call $byte_eq (local.get $acad) (i32.const 3) (i32.const 100))))))
        (i32.and
          (i32.eq (call 3 (local.get $susa)) (i32.const 4))
          (i32.and
            (call $byte_eq (local.get $susa) (i32.const 0) (i32.const 83))
            (i32.and
              (call $byte_eq (local.get $susa) (i32.const 1) (i32.const 117))
              (i32.and
                (call $byte_eq (local.get $susa) (i32.const 2) (i32.const 115))
                (call $byte_eq (local.get $susa) (i32.const 3) (i32.const 97)))))))))

  (func (export "test_catalog_complete") (result i32)
    (local $i i32)
    (local.set $i (i32.const 1))
    (block $cd (loop $cl
      (br_if $cd (i32.gt_u (local.get $i) (i32.const 17)))
      (if (i32.eqz (call 3 (call 1 (local.get $i)))) (then (return (i32.const 0))))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $cl)))
    (local.set $i (i32.const 1))
    (block $md (loop $ml
      (br_if $md (i32.gt_u (local.get $i) (i32.const 47)))
      (if (i32.eqz (call 3 (call 2 (local.get $i)))) (then (return (i32.const 0))))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $ml)))
    (i32.const 1))
)
