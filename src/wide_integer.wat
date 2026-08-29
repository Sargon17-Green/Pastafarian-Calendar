(module
  ;; Entero con signo de precisión variable en base 2^30.
  ;; El tamaño no está ligado a i64: cada objeto conserva su propia capacidad y el asignador amplía la memoria.
  (memory (export "memory") 4 65536)
  (global $BASE i64 (i64.const 1073741824))
  (global $MASK i64 (i64.const 1073741823))
  (global $heap (mut i32) (i32.const 65536))

  ;; Formato: signo i32 (-1,0,+1), longitud i32, capacidad i32, seguido de miembros i32 del menos significativo al más significativo.
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

  (func (export "arena_mark") (result i32) (global.get $heap))
  (func (export "arena_restore") (param $mark i32)
    (if (i32.lt_u (local.get $mark) (i32.const 65536)) (then unreachable))
    (if (i32.gt_u (local.get $mark) (global.get $heap)) (then unreachable))
    (global.set $heap (local.get $mark)))

  (func $limb_addr (param $p i32) (param $i i32) (result i32)
    (i32.add (i32.add (local.get $p) (i32.const 12)) (i32.mul (local.get $i) (i32.const 4))))
  (func $sign (param $p i32) (result i32) (i32.load (local.get $p)))
  (func $len (param $p i32) (result i32) (i32.load offset=4 (local.get $p)))
  (func $cap (param $p i32) (result i32) (i32.load offset=8 (local.get $p)))
  (func $limb (param $p i32) (param $i i32) (result i32) (i32.load (call $limb_addr (local.get $p) (local.get $i))))
  (func $set_sign (param $p i32) (param $s i32) (i32.store (local.get $p) (local.get $s)))
  (func $set_len (param $p i32) (param $n i32) (i32.store offset=4 (local.get $p) (local.get $n)))
  (func $set_limb (param $p i32) (param $i i32) (param $v i32)
    (if (i32.ge_u (local.get $i) (call $cap (local.get $p))) (then unreachable))
    (i32.store (call $limb_addr (local.get $p) (local.get $i)) (local.get $v)))

  (func $new (export "wide_new") (param $capacity i32) (result i32)
    (local $p i32)
    (if (i32.eqz (local.get $capacity)) (then (local.set $capacity (i32.const 1))))
    (local.set $p (call $alloc (i32.add (i32.const 12) (i32.mul (local.get $capacity) (i32.const 4)))))
    (call $set_sign (local.get $p) (i32.const 0))
    (call $set_len (local.get $p) (i32.const 0))
    (i32.store offset=8 (local.get $p) (local.get $capacity))
    (local.get $p))

  (func $normalize (param $p i32)
    (local $n i32)
    (local.set $n (call $len (local.get $p)))
    (block $done
      (loop $again
        (br_if $done (i32.eqz (local.get $n)))
        (br_if $done (i32.ne (call $limb (local.get $p) (i32.sub (local.get $n) (i32.const 1))) (i32.const 0)))
        (local.set $n (i32.sub (local.get $n) (i32.const 1)))
        (br $again)))
    (call $set_len (local.get $p) (local.get $n))
    (if (i32.eqz (local.get $n)) (then (call $set_sign (local.get $p) (i32.const 0)))))

  (func $from_i64 (export "wide_from_i64") (param $x i64) (result i32)
    (local $p i32) (local $mag i64) (local $n i32)
    (local.set $p (call $new (i32.const 3)))
    (if (i64.eqz (local.get $x)) (then (return (local.get $p))))
    (if (i64.lt_s (local.get $x) (i64.const 0))
      (then
        (call $set_sign (local.get $p) (i32.const -1))
        ;; Evita el desbordamiento para INT64_MIN mediante una magnitud sin signo: -(x+1)+1.
        (local.set $mag (i64.add (i64.sub (i64.const 0) (i64.add (local.get $x) (i64.const 1))) (i64.const 1))))
      (else
        (call $set_sign (local.get $p) (i32.const 1))
        (local.set $mag (local.get $x))))
    (local.set $n (i32.const 0))
    (block $done
      (loop $again
        (br_if $done (i64.eqz (local.get $mag)))
        (call $set_limb (local.get $p) (local.get $n) (i32.wrap_i64 (i64.and (local.get $mag) (global.get $MASK))))
        (local.set $mag (i64.shr_u (local.get $mag) (i64.const 30)))
        (local.set $n (i32.add (local.get $n) (i32.const 1)))
        (br $again)))
    (call $set_len (local.get $p) (local.get $n))
    (local.get $p))

  ;; Constructor explícito para pruebas y para llamadores que ya poseen miembros base 2^30.
  (func (export "wide_set_header") (param $p i32) (param $s i32) (param $n i32)
    (if (i32.gt_u (local.get $n) (call $cap (local.get $p))) (then unreachable))
    (if (i32.gt_s (local.get $s) (i32.const 1)) (then unreachable))
    (if (i32.lt_s (local.get $s) (i32.const -1)) (then unreachable))
    (call $set_sign (local.get $p) (local.get $s))
    (call $set_len (local.get $p) (local.get $n))
    (call $normalize (local.get $p)))
  (func (export "wide_set_limb") (param $p i32) (param $i i32) (param $v i32)
    (if (i32.ge_u (local.get $v) (i32.const 1073741824)) (then unreachable))
    (call $set_limb (local.get $p) (local.get $i) (local.get $v)))
  (func (export "wide_sign") (param $p i32) (result i32) (call $sign (local.get $p)))
  (func (export "wide_length") (param $p i32) (result i32) (call $len (local.get $p)))
  (func (export "wide_limb") (param $p i32) (param $i i32) (result i32) (call $limb (local.get $p) (local.get $i)))

  (func $copy (export "wide_copy") (param $src i32) (result i32)
    (local $dst i32) (local $i i32) (local $n i32)
    (local.set $n (call $len (local.get $src)))
    (local.set $dst (call $new (i32.add (local.get $n) (i32.const 1))))
    (call $set_sign (local.get $dst) (call $sign (local.get $src)))
    (call $set_len (local.get $dst) (local.get $n))
    (local.set $i (i32.const 0))
    (block $done
      (loop $again
        (br_if $done (i32.ge_u (local.get $i) (local.get $n)))
        (call $set_limb (local.get $dst) (local.get $i) (call $limb (local.get $src) (local.get $i)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $again)))
    (local.get $dst))

  (func $cmp_mag (param $a i32) (param $b i32) (result i32)
    (local $la i32) (local $lb i32) (local $i i32) (local $av i32) (local $bv i32)
    (local.set $la (call $len (local.get $a)))
    (local.set $lb (call $len (local.get $b)))
    (if (i32.lt_u (local.get $la) (local.get $lb)) (then (return (i32.const -1))))
    (if (i32.gt_u (local.get $la) (local.get $lb)) (then (return (i32.const 1))))
    (local.set $i (local.get $la))
    (block $equal
      (loop $again
        (br_if $equal (i32.eqz (local.get $i)))
        (local.set $i (i32.sub (local.get $i) (i32.const 1)))
        (local.set $av (call $limb (local.get $a) (local.get $i)))
        (local.set $bv (call $limb (local.get $b) (local.get $i)))
        (if (i32.lt_u (local.get $av) (local.get $bv)) (then (return (i32.const -1))))
        (if (i32.gt_u (local.get $av) (local.get $bv)) (then (return (i32.const 1))))
        (br $again)))
    (i32.const 0))

  (func $cmp (export "wide_cmp") (param $a i32) (param $b i32) (result i32)
    (local $sa i32) (local $sb i32) (local $m i32)
    (local.set $sa (call $sign (local.get $a)))
    (local.set $sb (call $sign (local.get $b)))
    (if (i32.lt_s (local.get $sa) (local.get $sb)) (then (return (i32.const -1))))
    (if (i32.gt_s (local.get $sa) (local.get $sb)) (then (return (i32.const 1))))
    (if (i32.eqz (local.get $sa)) (then (return (i32.const 0))))
    (local.set $m (call $cmp_mag (local.get $a) (local.get $b)))
    (if (result i32) (i32.eq (local.get $sa) (i32.const 1)) (then (local.get $m)) (else (i32.sub (i32.const 0) (local.get $m)))))

  (func $mag_add (param $a i32) (param $b i32) (result i32)
    (local $dst i32) (local $la i32) (local $lb i32) (local $n i32) (local $i i32)
    (local $carry i64) (local $av i64) (local $bv i64) (local $sum i64)
    (local.set $la (call $len (local.get $a)))
    (local.set $lb (call $len (local.get $b)))
    (local.set $n (select (local.get $la) (local.get $lb) (i32.gt_u (local.get $la) (local.get $lb))))
    (local.set $dst (call $new (i32.add (local.get $n) (i32.const 1))))
    (call $set_len (local.get $dst) (local.get $n))
    (local.set $i (i32.const 0))
    (local.set $carry (i64.const 0))
    (block $done
      (loop $again
        (br_if $done (i32.ge_u (local.get $i) (local.get $n)))
        (local.set $av (if (result i64) (i32.lt_u (local.get $i) (local.get $la)) (then (i64.extend_i32_u (call $limb (local.get $a) (local.get $i)))) (else (i64.const 0))))
        (local.set $bv (if (result i64) (i32.lt_u (local.get $i) (local.get $lb)) (then (i64.extend_i32_u (call $limb (local.get $b) (local.get $i)))) (else (i64.const 0))))
        (local.set $sum (i64.add (i64.add (local.get $av) (local.get $bv)) (local.get $carry)))
        (call $set_limb (local.get $dst) (local.get $i) (i32.wrap_i64 (i64.and (local.get $sum) (global.get $MASK))))
        (local.set $carry (i64.shr_u (local.get $sum) (i64.const 30)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $again)))
    (if (i64.ne (local.get $carry) (i64.const 0))
      (then
        (call $set_limb (local.get $dst) (local.get $n) (i32.wrap_i64 (local.get $carry)))
        (call $set_len (local.get $dst) (i32.add (local.get $n) (i32.const 1)))))
    (local.get $dst))

  ;; Requiere |a|>=|b| y devuelve una magnitud no negativa.
  (func $mag_sub (param $a i32) (param $b i32) (result i32)
    (local $dst i32) (local $n i32) (local $lb i32) (local $i i32)
    (local $borrow i64) (local $av i64) (local $bv i64) (local $v i64)
    (if (i32.lt_s (call $cmp_mag (local.get $a) (local.get $b)) (i32.const 0)) (then unreachable))
    (local.set $n (call $len (local.get $a)))
    (local.set $lb (call $len (local.get $b)))
    (local.set $dst (call $new (i32.add (local.get $n) (i32.const 1))))
    (call $set_len (local.get $dst) (local.get $n))
    (local.set $i (i32.const 0))
    (local.set $borrow (i64.const 0))
    (block $done
      (loop $again
        (br_if $done (i32.ge_u (local.get $i) (local.get $n)))
        (local.set $av (i64.extend_i32_u (call $limb (local.get $a) (local.get $i))))
        (local.set $bv (if (result i64) (i32.lt_u (local.get $i) (local.get $lb)) (then (i64.extend_i32_u (call $limb (local.get $b) (local.get $i)))) (else (i64.const 0))))
        (local.set $v (i64.sub (i64.sub (local.get $av) (local.get $bv)) (local.get $borrow)))
        (if (i64.lt_s (local.get $v) (i64.const 0))
          (then (local.set $v (i64.add (local.get $v) (global.get $BASE))) (local.set $borrow (i64.const 1)))
          (else (local.set $borrow (i64.const 0))))
        (call $set_limb (local.get $dst) (local.get $i) (i32.wrap_i64 (local.get $v)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $again)))
    (if (i64.ne (local.get $borrow) (i64.const 0)) (then unreachable))
    (call $normalize (local.get $dst))
    (local.get $dst))

  (func $add (export "wide_add") (param $a i32) (param $b i32) (result i32)
    (local $sa i32) (local $sb i32) (local $m i32) (local $dst i32)
    (local.set $sa (call $sign (local.get $a)))
    (local.set $sb (call $sign (local.get $b)))
    (if (i32.eqz (local.get $sa)) (then (return (call $copy (local.get $b)))))
    (if (i32.eqz (local.get $sb)) (then (return (call $copy (local.get $a)))))
    (if (i32.eq (local.get $sa) (local.get $sb))
      (then
        (local.set $dst (call $mag_add (local.get $a) (local.get $b)))
        (call $set_sign (local.get $dst) (local.get $sa))
        (return (local.get $dst))))
    (local.set $m (call $cmp_mag (local.get $a) (local.get $b)))
    (if (i32.eqz (local.get $m)) (then (return (call $new (i32.const 1)))))
    (if (i32.gt_s (local.get $m) (i32.const 0))
      (then
        (local.set $dst (call $mag_sub (local.get $a) (local.get $b)))
        (call $set_sign (local.get $dst) (local.get $sa)))
      (else
        (local.set $dst (call $mag_sub (local.get $b) (local.get $a)))
        (call $set_sign (local.get $dst) (local.get $sb))))
    (local.get $dst))

  (func $neg (export "wide_neg") (param $a i32) (result i32)
    (local $dst i32)
    (local.set $dst (call $copy (local.get $a)))
    (call $set_sign (local.get $dst) (i32.sub (i32.const 0) (call $sign (local.get $dst))))
    (local.get $dst))

  (func $sub (export "wide_sub") (param $a i32) (param $b i32) (result i32)
    (local $mark i32) (local $nb i32) (local $dst i32)
    (local.set $mark (global.get $heap))
    (local.set $nb (call $neg (local.get $b)))
    (local.set $dst (call $add (local.get $a) (local.get $nb)))
    ;; No se restaura el área porque `dst` también fue asignado después de `mark`.
    (drop (local.get $mark))
    (local.get $dst))

  (func $add_small (export "wide_add_small") (param $a i32) (param $delta i32) (result i32)
    (local $b i32)
    (local.set $b (call $from_i64 (i64.extend_i32_s (local.get $delta))))
    (call $add (local.get $a) (local.get $b)))

  (func (export "wide_abs_diff") (param $a i32) (param $b i32) (result i32)
    (local $d i32)
    (local.set $d (call $sub (local.get $a) (local.get $b)))
    (if (i32.lt_s (call $sign (local.get $d)) (i32.const 0))
      (then (call $set_sign (local.get $d) (i32.const 1))))
    (local.get $d))

  ;; Residuo de la magnitud por un divisor i32; se usa en pruebas y en adaptadores pequeños.
  (func (export "wide_mag_mod_small") (param $a i32) (param $d i32) (result i32)
    (local $i i32) (local $r i64)
    (if (i32.le_u (local.get $d) (i32.const 0)) (then unreachable))
    (local.set $i (call $len (local.get $a)))
    (local.set $r (i64.const 0))
    (block $done
      (loop $again
        (br_if $done (i32.eqz (local.get $i)))
        (local.set $i (i32.sub (local.get $i) (i32.const 1)))
        (local.set $r
          (i64.rem_u
            (i64.add (i64.shl (local.get $r) (i64.const 30)) (i64.extend_i32_u (call $limb (local.get $a) (local.get $i))))
            (i64.extend_i32_u (local.get $d))))
        (br $again)))
    (i32.wrap_i64 (local.get $r)))

  ;; Prueba de más de 64 bits: 2^90 + 17 es mayor que 2^89 y conserva el miembro superior.
  (func (export "test_wide_beyond_i64") (result i32)
    (local $a i32) (local $b i32)
    (local.set $a (call $new (i32.const 4)))
    (call $set_limb (local.get $a) (i32.const 0) (i32.const 17))
    (call $set_limb (local.get $a) (i32.const 3) (i32.const 1))
    (call $set_len (local.get $a) (i32.const 4))
    (call $set_sign (local.get $a) (i32.const 1))
    (local.set $b (call $new (i32.const 3)))
    (call $set_limb (local.get $b) (i32.const 2) (i32.const 536870912))
    (call $set_len (local.get $b) (i32.const 3))
    (call $set_sign (local.get $b) (i32.const 1))
    (i32.and
      (i32.gt_s (call $cmp (local.get $a) (local.get $b)) (i32.const 0))
      (i32.eq (call $limb (local.get $a) (i32.const 3)) (i32.const 1))))

  (func (export "test_signed_cross_zero") (result i32)
    (local $a i32) (local $b i32) (local $d i32)
    (local.set $a (call $from_i64 (i64.const -7)))
    (local.set $b (call $from_i64 (i64.const 5)))
    (local.set $d (call $sub (local.get $b) (local.get $a)))
    (i32.and
      (i32.eq (call $sign (local.get $d)) (i32.const 1))
      (i32.and
        (i32.eq (call $len (local.get $d)) (i32.const 1))
        (i32.eq (call $limb (local.get $d) (i32.const 0)) (i32.const 12)))))
)
