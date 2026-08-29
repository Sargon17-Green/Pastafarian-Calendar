(module
  ;; Selector normativo exacto. Los naturales de selección usan base 2^30.
  ;; 1100 miembros = 33000 bits. Es suficiente para todo N legal del calendario:
  ;; incluso 47^5778 < 2^32100, y el espacio amplio mínimo es menor que M*N < 2^32227.
  (memory (export "memory") 96)
  (global $BASE i64 (i64.const 1073741824))
  (global $MASK i64 (i64.const 1073741823))
  (global $MAXL i32 (i32.const 1100))
  (global $CELL i32 (i32.const 4416))

  (global $M i32 (i32.const 65536))
  (global $ONE i32 (i32.const 69952))
  (global $FIRST i32 (i32.const 74368))
  (global $CUR i32 (i32.const 78784))
  (global $N i32 (i32.const 83200))
  (global $Q i32 (i32.const 87616))
  (global $R i32 (i32.const 92032))
  (global $LIMIT i32 (i32.const 96448))
  (global $SPACE i32 (i32.const 100864))
  (global $WIDE i32 (i32.const 105280))
  (global $WEIGHT i32 (i32.const 109696))
  (global $DIGIT i32 (i32.const 114112))
  (global $TERM i32 (i32.const 118528))
  (global $TMP0 i32 (i32.const 122944))
  (global $TMP1 i32 (i32.const 127360))
  (global $TMP2 i32 (i32.const 131776))
  (global $TMP3 i32 (i32.const 136192))
  (global $SHIFTED i32 (i32.const 140608))
  (global $RESULT i32 (i32.const 145024))

  (func $len (param $p i32) (result i32) (i32.load (local.get $p)))
  (func $set_len (param $p i32) (param $n i32) (i32.store (local.get $p) (local.get $n)))
  (func $la (param $p i32) (param $i i32) (result i32)
    (i32.add (i32.add (local.get $p) (i32.const 4)) (i32.mul (local.get $i) (i32.const 4))))
  (func $limb (param $p i32) (param $i i32) (result i32) (i32.load (call $la (local.get $p) (local.get $i))))
  (func $set_limb (param $p i32) (param $i i32) (param $v i32)
    (if (i32.ge_u (local.get $i) (global.get $MAXL)) (then unreachable))
    (i32.store (call $la (local.get $p) (local.get $i)) (local.get $v)))
  (func $zero (param $p i32) (call $set_len (local.get $p) (i32.const 0)))
  (func $normalize (param $p i32)
    (local $n i32)
    (local.set $n (call $len (local.get $p)))
    (block $done (loop $again
      (br_if $done (i32.eqz (local.get $n)))
      (br_if $done (i32.ne (call $limb (local.get $p) (i32.sub (local.get $n) (i32.const 1))) (i32.const 0)))
      (local.set $n (i32.sub (local.get $n) (i32.const 1)))
      (br $again)))
    (call $set_len (local.get $p) (local.get $n)))
  (func $copy (param $dst i32) (param $src i32)
    (local $i i32) (local $n i32)
    (if (i32.eq (local.get $dst) (local.get $src)) (then (return)))
    (local.set $n (call $len (local.get $src)))
    (call $set_len (local.get $dst) (local.get $n))
    (local.set $i (i32.const 0))
    (block $done (loop $again
      (br_if $done (i32.ge_u (local.get $i) (local.get $n)))
      (call $set_limb (local.get $dst) (local.get $i) (call $limb (local.get $src) (local.get $i)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $again))))
  (func $from_u64 (param $p i32) (param $x i64)
    (local $n i32)
    (call $zero (local.get $p))
    (local.set $n (i32.const 0))
    (block $done (loop $again
      (br_if $done (i64.eqz (local.get $x)))
      (call $set_limb (local.get $p) (local.get $n) (i32.wrap_i64 (i64.and (local.get $x) (global.get $MASK))))
      (local.set $x (i64.shr_u (local.get $x) (i64.const 30)))
      (local.set $n (i32.add (local.get $n) (i32.const 1)))
      (br $again)))
    (call $set_len (local.get $p) (local.get $n)))
  (func $init_constants
    ;; M = 2^127-1 = [2^30-1,2^30-1,2^30-1,2^30-1,127] en base 2^30.
    (call $set_len (global.get $M) (i32.const 5))
    (call $set_limb (global.get $M) (i32.const 0) (i32.const 1073741823))
    (call $set_limb (global.get $M) (i32.const 1) (i32.const 1073741823))
    (call $set_limb (global.get $M) (i32.const 2) (i32.const 1073741823))
    (call $set_limb (global.get $M) (i32.const 3) (i32.const 1073741823))
    (call $set_limb (global.get $M) (i32.const 4) (i32.const 127))
    (call $from_u64 (global.get $ONE) (i64.const 1)))
  (func $cmp (param $a i32) (param $b i32) (result i32)
    (local $laa i32) (local $lb i32) (local $i i32) (local $av i32) (local $bv i32)
    (local.set $laa (call $len (local.get $a))) (local.set $lb (call $len (local.get $b)))
    (if (i32.lt_u (local.get $laa) (local.get $lb)) (then (return (i32.const -1))))
    (if (i32.gt_u (local.get $laa) (local.get $lb)) (then (return (i32.const 1))))
    (local.set $i (local.get $laa))
    (block $eq (loop $again
      (br_if $eq (i32.eqz (local.get $i)))
      (local.set $i (i32.sub (local.get $i) (i32.const 1)))
      (local.set $av (call $limb (local.get $a) (local.get $i)))
      (local.set $bv (call $limb (local.get $b) (local.get $i)))
      (if (i32.lt_u (local.get $av) (local.get $bv)) (then (return (i32.const -1))))
      (if (i32.gt_u (local.get $av) (local.get $bv)) (then (return (i32.const 1))))
      (br $again)))
    (i32.const 0))
  (func $add (param $dst i32) (param $a i32) (param $b i32)
    (local $na i32) (local $nb i32) (local $n i32) (local $i i32)
    (local $carry i64) (local $av i64) (local $bv i64) (local $s i64)
    (if (i32.eq (local.get $dst) (local.get $a)) (then (call $copy (global.get $TMP3) (local.get $a)) (local.set $a (global.get $TMP3))))
    (if (i32.eq (local.get $dst) (local.get $b)) (then (call $copy (global.get $TMP2) (local.get $b)) (local.set $b (global.get $TMP2))))
    (local.set $na (call $len (local.get $a))) (local.set $nb (call $len (local.get $b)))
    (local.set $n (select (local.get $na) (local.get $nb) (i32.gt_u (local.get $na) (local.get $nb))))
    (local.set $i (i32.const 0)) (local.set $carry (i64.const 0))
    (block $done (loop $again
      (br_if $done (i32.ge_u (local.get $i) (local.get $n)))
      (local.set $av (if (result i64) (i32.lt_u (local.get $i) (local.get $na)) (then (i64.extend_i32_u (call $limb (local.get $a) (local.get $i)))) (else (i64.const 0))))
      (local.set $bv (if (result i64) (i32.lt_u (local.get $i) (local.get $nb)) (then (i64.extend_i32_u (call $limb (local.get $b) (local.get $i)))) (else (i64.const 0))))
      (local.set $s (i64.add (i64.add (local.get $av) (local.get $bv)) (local.get $carry)))
      (call $set_limb (local.get $dst) (local.get $i) (i32.wrap_i64 (i64.and (local.get $s) (global.get $MASK))))
      (local.set $carry (i64.shr_u (local.get $s) (i64.const 30)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $again)))
    (if (i64.ne (local.get $carry) (i64.const 0))
      (then (call $set_limb (local.get $dst) (local.get $n) (i32.wrap_i64 (local.get $carry))) (local.set $n (i32.add (local.get $n) (i32.const 1)))))
    (call $set_len (local.get $dst) (local.get $n)))
  (func $sub (param $dst i32) (param $a i32) (param $b i32)
    ;; Requiere a>=b.
    (local $na i32) (local $nb i32) (local $i i32) (local $borrow i64) (local $av i64) (local $bv i64) (local $v i64)
    (if (i32.lt_s (call $cmp (local.get $a) (local.get $b)) (i32.const 0)) (then unreachable))
    (if (i32.eq (local.get $dst) (local.get $a)) (then (call $copy (global.get $TMP3) (local.get $a)) (local.set $a (global.get $TMP3))))
    (if (i32.eq (local.get $dst) (local.get $b)) (then (call $copy (global.get $TMP2) (local.get $b)) (local.set $b (global.get $TMP2))))
    (local.set $na (call $len (local.get $a))) (local.set $nb (call $len (local.get $b)))
    (local.set $i (i32.const 0)) (local.set $borrow (i64.const 0))
    (block $done (loop $again
      (br_if $done (i32.ge_u (local.get $i) (local.get $na)))
      (local.set $av (i64.extend_i32_u (call $limb (local.get $a) (local.get $i))))
      (local.set $bv (if (result i64) (i32.lt_u (local.get $i) (local.get $nb)) (then (i64.extend_i32_u (call $limb (local.get $b) (local.get $i)))) (else (i64.const 0))))
      (local.set $v (i64.sub (i64.sub (local.get $av) (local.get $bv)) (local.get $borrow)))
      (if (i64.lt_s (local.get $v) (i64.const 0))
        (then (local.set $v (i64.add (local.get $v) (global.get $BASE))) (local.set $borrow (i64.const 1)))
        (else (local.set $borrow (i64.const 0))))
      (call $set_limb (local.get $dst) (local.get $i) (i32.wrap_i64 (local.get $v)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $again)))
    (if (i64.ne (local.get $borrow) (i64.const 0)) (then unreachable))
    (call $set_len (local.get $dst) (local.get $na)) (call $normalize (local.get $dst)))
  (func $add_small (param $dst i32) (param $a i32) (param $x i32)
    (call $from_u64 (global.get $TMP0) (i64.extend_i32_u (local.get $x)))
    (call $add (local.get $dst) (local.get $a) (global.get $TMP0)))
  (func $sub_small (param $dst i32) (param $a i32) (param $x i32)
    (call $from_u64 (global.get $TMP0) (i64.extend_i32_u (local.get $x)))
    (call $sub (local.get $dst) (local.get $a) (global.get $TMP0)))
  (func $mul (param $dst i32) (param $a i32) (param $b i32)
    (local $na i32) (local $nb i32) (local $i i32) (local $j i32) (local $k i32)
    (local $carry i64) (local $cur i64) (local $prod i64)
    (if (i32.eq (local.get $dst) (local.get $a)) (then (call $copy (global.get $TMP3) (local.get $a)) (local.set $a (global.get $TMP3))))
    (if (i32.eq (local.get $dst) (local.get $b)) (then (call $copy (global.get $TMP2) (local.get $b)) (local.set $b (global.get $TMP2))))
    (local.set $na (call $len (local.get $a))) (local.set $nb (call $len (local.get $b)))
    (if (i32.gt_u (i32.add (local.get $na) (local.get $nb)) (global.get $MAXL)) (then unreachable))
    (call $zero (local.get $dst))
    (local.set $k (i32.const 0))
    (block $zd (loop $zl
      (br_if $zd (i32.ge_u (local.get $k) (i32.add (local.get $na) (local.get $nb))))
      (call $set_limb (local.get $dst) (local.get $k) (i32.const 0))
      (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $zl)))
    (call $set_len (local.get $dst) (i32.add (local.get $na) (local.get $nb)))
    (local.set $i (i32.const 0))
    (block $donei (loop $li
      (br_if $donei (i32.ge_u (local.get $i) (local.get $na)))
      (local.set $carry (i64.const 0)) (local.set $j (i32.const 0))
      (block $donej (loop $lj
        (br_if $donej (i32.ge_u (local.get $j) (local.get $nb)))
        (local.set $k (i32.add (local.get $i) (local.get $j)))
        (local.set $prod (i64.mul (i64.extend_i32_u (call $limb (local.get $a) (local.get $i))) (i64.extend_i32_u (call $limb (local.get $b) (local.get $j)))))
        (local.set $cur (i64.add (i64.add (i64.extend_i32_u (call $limb (local.get $dst) (local.get $k))) (local.get $prod)) (local.get $carry)))
        (call $set_limb (local.get $dst) (local.get $k) (i32.wrap_i64 (i64.and (local.get $cur) (global.get $MASK))))
        (local.set $carry (i64.shr_u (local.get $cur) (i64.const 30)))
        (local.set $j (i32.add (local.get $j) (i32.const 1))) (br $lj)))
      (local.set $k (i32.add (local.get $i) (local.get $nb)))
      (block $carrydone
        (loop $carryloop
          (br_if $carrydone (i64.eqz (local.get $carry)))
          (if (i32.ge_u (local.get $k) (global.get $MAXL)) (then unreachable))
          (local.set $cur (i64.add (i64.extend_i32_u (call $limb (local.get $dst) (local.get $k))) (local.get $carry)))
          (call $set_limb (local.get $dst) (local.get $k) (i32.wrap_i64 (i64.and (local.get $cur) (global.get $MASK))))
          (local.set $carry (i64.shr_u (local.get $cur) (i64.const 30)))
          (local.set $k (i32.add (local.get $k) (i32.const 1)))
          (br $carryloop)))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $li)))
    (call $normalize (local.get $dst)))
  (func $bitlen (param $a i32) (result i32)
    (local $n i32) (local $top i32) (local $bits i32)
    (local.set $n (call $len (local.get $a)))
    (if (i32.eqz (local.get $n)) (then (return (i32.const 0))))
    (local.set $top (call $limb (local.get $a) (i32.sub (local.get $n) (i32.const 1))))
    (local.set $bits (i32.const 0))
    (block $done (loop $again
      (br_if $done (i32.eqz (local.get $top)))
      (local.set $top (i32.shr_u (local.get $top) (i32.const 1)))
      (local.set $bits (i32.add (local.get $bits) (i32.const 1))) (br $again)))
    (i32.add (i32.mul (i32.sub (local.get $n) (i32.const 1)) (i32.const 30)) (local.get $bits)))
  (func $shift_left_bits (param $dst i32) (param $a i32) (param $bits i32)
    (local $word i32) (local $rem i32) (local $na i32) (local $i i32) (local $out i32)
    (local $v i64) (local $carry i64)
    (local.set $word (i32.div_u (local.get $bits) (i32.const 30)))
    (local.set $rem (i32.rem_u (local.get $bits) (i32.const 30)))
    (local.set $na (call $len (local.get $a)))
    (if (i32.gt_u (i32.add (i32.add (local.get $na) (local.get $word)) (i32.const 1)) (global.get $MAXL)) (then unreachable))
    (call $zero (local.get $dst))
    (local.set $i (i32.const 0))
    (block $zdone (loop $zl (br_if $zdone (i32.ge_u (local.get $i) (i32.add (i32.add (local.get $na) (local.get $word)) (i32.const 1)))) (call $set_limb (local.get $dst) (local.get $i) (i32.const 0)) (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $zl)))
    (local.set $carry (i64.const 0)) (local.set $i (i32.const 0))
    (block $done (loop $again
      (br_if $done (i32.ge_u (local.get $i) (local.get $na)))
      (local.set $v (i64.or (i64.shl (i64.extend_i32_u (call $limb (local.get $a) (local.get $i))) (i64.extend_i32_u (local.get $rem))) (local.get $carry)))
      (local.set $out (i32.add (local.get $i) (local.get $word)))
      (call $set_limb (local.get $dst) (local.get $out) (i32.wrap_i64 (i64.and (local.get $v) (global.get $MASK))))
      (local.set $carry (if (result i64) (i32.eqz (local.get $rem)) (then (i64.const 0)) (else (i64.shr_u (local.get $v) (i64.const 30)))))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $again)))
    (if (i64.ne (local.get $carry) (i64.const 0)) (then (call $set_limb (local.get $dst) (i32.add (local.get $na) (local.get $word)) (i32.wrap_i64 (local.get $carry))) (call $set_len (local.get $dst) (i32.add (i32.add (local.get $na) (local.get $word)) (i32.const 1)))) (else (call $set_len (local.get $dst) (i32.add (local.get $na) (local.get $word)))))
    (call $normalize (local.get $dst)))
  (func $set_bit (param $p i32) (param $bit i32)
    (local $w i32) (local $r i32) (local $n i32)
    (local.set $w (i32.div_u (local.get $bit) (i32.const 30))) (local.set $r (i32.rem_u (local.get $bit) (i32.const 30)))
    (if (i32.ge_u (local.get $w) (global.get $MAXL)) (then unreachable))
    (local.set $n (call $len (local.get $p)))
    (block $done (loop $again
      (br_if $done (i32.gt_u (local.get $n) (local.get $w)))
      (call $set_limb (local.get $p) (local.get $n) (i32.const 0))
      (local.set $n (i32.add (local.get $n) (i32.const 1))) (br $again)))
    (call $set_len (local.get $p) (local.get $n))
    (call $set_limb (local.get $p) (local.get $w) (i32.or (call $limb (local.get $p) (local.get $w)) (i32.shl (i32.const 1) (local.get $r)))))
  ;; División exacta general para los usos del selector, bajo la condición n < d*M.
  ;; Por ello el cociente tiene como máximo 127 bits y la búsqueda usa como máximo 127 desplazamientos.
  (func $divmod_q_lt_m (param $q i32) (param $r i32) (param $n i32) (param $d i32)
    (local $shift i32)
    (if (i32.eqz (call $len (local.get $d))) (then unreachable))
    (call $zero (local.get $q)) (call $copy (local.get $r) (local.get $n))
    (if (i32.lt_s (call $cmp (local.get $r) (local.get $d)) (i32.const 0)) (then (return)))
    (local.set $shift (i32.sub (call $bitlen (local.get $r)) (call $bitlen (local.get $d))))
    (if (i32.gt_u (local.get $shift) (i32.const 127)) (then unreachable))
    (block $done (loop $again
      (call $shift_left_bits (global.get $SHIFTED) (local.get $d) (local.get $shift))
      (if (i32.ge_s (call $cmp (local.get $r) (global.get $SHIFTED)) (i32.const 0))
        (then (call $sub (local.get $r) (local.get $r) (global.get $SHIFTED)) (call $set_bit (local.get $q) (local.get $shift))))
      (br_if $done (i32.eqz (local.get $shift)))
      (local.set $shift (i32.sub (local.get $shift) (i32.const 1)))
      (br $again))))
  (func $ring_step (param $x i32) (param $step i32)
    (if (i32.eq (local.get $step) (i32.const 1))
      (then (if (i32.eqz (call $cmp (local.get $x) (global.get $M))) (then (call $copy (local.get $x) (global.get $ONE))) (else (call $add_small (local.get $x) (local.get $x) (i32.const 1)))))
      (else (if (i32.eqz (call $cmp (local.get $x) (global.get $ONE))) (then (call $copy (local.get $x) (global.get $M))) (else (call $sub_small (local.get $x) (local.get $x) (i32.const 1)))))))
  (func $wide_ring_step (param $x i32) (param $space i32) (param $step i32)
    (if (i32.eq (local.get $step) (i32.const 1))
      (then (if (i32.eqz (call $cmp (local.get $x) (local.get $space))) (then (call $copy (local.get $x) (global.get $ONE))) (else (call $add_small (local.get $x) (local.get $x) (i32.const 1)))))
      (else (if (i32.eqz (call $cmp (local.get $x) (global.get $ONE))) (then (call $copy (local.get $x) (local.get $space))) (else (call $sub_small (local.get $x) (local.get $x) (i32.const 1)))))))
  (func $choose_short (param $first i32) (param $step i32) (param $n i32) (param $dst i32)
    ;; q=floor(M/N), limit=q*N. Como M < N*M, divmod_q_lt_m es válido.
    (call $divmod_q_lt_m (global.get $Q) (global.get $R) (global.get $M) (local.get $n))
    (call $mul (global.get $LIMIT) (global.get $Q) (local.get $n))
    (call $copy (global.get $CUR) (local.get $first))
    (block $accept (loop $again
      (br_if $accept (i32.le_s (call $cmp (global.get $CUR) (global.get $LIMIT)) (i32.const 0)))
      (call $ring_step (global.get $CUR) (local.get $step))
      (br $again)))
    ;; rango = ((x-1) mod N)+1.
    (call $sub_small (global.get $TMP0) (global.get $CUR) (i32.const 1))
    (call $divmod_q_lt_m (global.get $Q) (global.get $R) (global.get $TMP0) (local.get $n))
    (call $add_small (local.get $dst) (global.get $R) (i32.const 1)))
  (func $choose_wide (param $first i32) (param $step i32) (param $n i32) (param $dst i32)
    (local $places i32) (local $j i32)
    (call $copy (global.get $SPACE) (global.get $M))
    (local.set $places (i32.const 1))
    (block $pd (loop $pl
      (br_if $pd (i32.ge_s (call $cmp (global.get $SPACE) (local.get $n)) (i32.const 0)))
      (call $mul (global.get $SPACE) (global.get $SPACE) (global.get $M))
      (local.set $places (i32.add (local.get $places) (i32.const 1)))
      (br $pl)))
    ;; valor amplio = 1 + Σ dígito_j*M^j; los dígitos proceden del mismo anillo de respuestas.
    (call $copy (global.get $WIDE) (global.get $ONE))
    (call $copy (global.get $WEIGHT) (global.get $ONE))
    (call $copy (global.get $CUR) (local.get $first))
    (local.set $j (i32.const 0))
    (block $wd (loop $wl
      (br_if $wd (i32.ge_u (local.get $j) (local.get $places)))
      (call $sub_small (global.get $DIGIT) (global.get $CUR) (i32.const 1))
      (call $mul (global.get $TERM) (global.get $WEIGHT) (global.get $DIGIT))
      (call $add (global.get $WIDE) (global.get $WIDE) (global.get $TERM))
      (if (i32.lt_u (i32.add (local.get $j) (i32.const 1)) (local.get $places)) (then (call $mul (global.get $WEIGHT) (global.get $WEIGHT) (global.get $M))))
      (call $ring_step (global.get $CUR) (local.get $step))
      (local.set $j (i32.add (local.get $j) (i32.const 1)))
      (br $wl)))
    ;; espacio < N*M por minimalidad, así que q=floor(space/N)<M.
    (call $divmod_q_lt_m (global.get $Q) (global.get $R) (global.get $SPACE) (local.get $n))
    (call $mul (global.get $LIMIT) (global.get $Q) (local.get $n))
    (block $acc (loop $rej
      (br_if $acc (i32.le_s (call $cmp (global.get $WIDE) (global.get $LIMIT)) (i32.const 0)))
      (call $wide_ring_step (global.get $WIDE) (global.get $SPACE) (local.get $step))
      (br $rej)))
    (call $sub_small (global.get $TMP0) (global.get $WIDE) (i32.const 1))
    ;; valor amplio < espacio < N*M, por tanto floor((wide-1)/N)<M.
    (call $divmod_q_lt_m (global.get $Q) (global.get $R) (global.get $TMP0) (local.get $n))
    (call $add_small (local.get $dst) (global.get $R) (i32.const 1)))
  (func $choose (param $first i32) (param $step i32) (param $n i32) (param $dst i32)
    (if (i32.le_s (call $cmp (local.get $n) (global.get $M)) (i32.const 0))
      (then (call $choose_short (local.get $first) (local.get $step) (local.get $n) (local.get $dst)))
      (else (call $choose_wide (local.get $first) (local.get $step) (local.get $n) (local.get $dst)))))

  ;; ------- Pruebas -------
  (func (export "test_short_n1") (result i32)
    (call $init_constants) (call $from_u64 (global.get $FIRST) (i64.const 777)) (call $from_u64 (global.get $N) (i64.const 1))
    (call $choose (global.get $FIRST) (i32.const 1) (global.get $N) (global.get $RESULT))
    (i32.and (i32.eq (call $len (global.get $RESULT)) (i32.const 1)) (i32.eq (call $limb (global.get $RESULT) (i32.const 0)) (i32.const 1))))
  (func (export "test_short_rejection_from_m_backward") (result i32)
    (call $init_constants) (call $copy (global.get $FIRST) (global.get $M)) (call $from_u64 (global.get $N) (i64.const 10))
    (call $choose (global.get $FIRST) (i32.const -1) (global.get $N) (global.get $RESULT))
    (i32.and (i32.eq (call $len (global.get $RESULT)) (i32.const 1)) (i32.eq (call $limb (global.get $RESULT) (i32.const 0)) (i32.const 10))))
  (func (export "test_wide_m_plus_1") (result i32)
    (call $init_constants)
    (call $copy (global.get $FIRST) (global.get $ONE))
    (call $add_small (global.get $N) (global.get $M) (i32.const 1))
    (call $choose (global.get $FIRST) (i32.const 1) (global.get $N) (global.get $RESULT))
    (i32.eqz (call $cmp (global.get $RESULT) (global.get $N))))
  (func (export "test_wide_m_squared") (result i32)
    (call $init_constants)
    (call $copy (global.get $FIRST) (global.get $ONE))
    (call $mul (global.get $N) (global.get $M) (global.get $M))
    (call $choose (global.get $FIRST) (i32.const 1) (global.get $N) (global.get $RESULT))
    ;; Con first=1 y step=+1, valor amplio = M+1 en dos dígitos.
    (call $add_small (global.get $TMP0) (global.get $M) (i32.const 1))
    (i32.eqz (call $cmp (global.get $RESULT) (global.get $TMP0))))
  (global $BC_POS i32 (i32.const 149440))
  (global $BC_NEG i32 (i32.const 153856))
  (global $BC_A i32 (i32.const 158272))
  (global $BC_B i32 (i32.const 162688))
  (global $BC_TERM i32 (i32.const 167104))
  (global $BC_COUNT i32 (i32.const 171520))
  (global $BC_RANK i32 (i32.const 175936))
  (global $LENGTHS i32 (i32.const 180352))

  (func $mul_small (param $dst i32) (param $a i32) (param $x i32)
    (local $n i32) (local $i i32) (local $carry i64) (local $v i64)
    (if (i32.eq (local.get $dst) (local.get $a)) (then (call $copy (global.get $TMP3) (local.get $a)) (local.set $a (global.get $TMP3))))
    (if (i32.eqz (local.get $x)) (then (call $zero (local.get $dst)) (return)))
    (local.set $n (call $len (local.get $a))) (local.set $i (i32.const 0)) (local.set $carry (i64.const 0))
    (block $done (loop $again
      (br_if $done (i32.ge_u (local.get $i) (local.get $n)))
      (local.set $v (i64.add (i64.mul (i64.extend_i32_u (call $limb (local.get $a) (local.get $i))) (i64.extend_i32_u (local.get $x))) (local.get $carry)))
      (call $set_limb (local.get $dst) (local.get $i) (i32.wrap_i64 (i64.and (local.get $v) (global.get $MASK))))
      (local.set $carry (i64.shr_u (local.get $v) (i64.const 30)))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $again)))
    (if (i64.ne (local.get $carry) (i64.const 0))
      (then (call $set_limb (local.get $dst) (local.get $n) (i32.wrap_i64 (local.get $carry))) (local.set $n (i32.add (local.get $n) (i32.const 1)))))
    (call $set_len (local.get $dst) (local.get $n)))

  (func $div_small_exact (param $dst i32) (param $a i32) (param $d i32)
    (local $i i32) (local $r i64) (local $cur i64) (local $qv i64) (local $n i32)
    (if (i32.eqz (local.get $d)) (then unreachable))
    (if (i32.eq (local.get $dst) (local.get $a)) (then (call $copy (global.get $TMP3) (local.get $a)) (local.set $a (global.get $TMP3))))
    (local.set $n (call $len (local.get $a))) (call $set_len (local.get $dst) (local.get $n))
    (local.set $i (local.get $n)) (local.set $r (i64.const 0))
    (block $done (loop $again
      (br_if $done (i32.eqz (local.get $i)))
      (local.set $i (i32.sub (local.get $i) (i32.const 1)))
      (local.set $cur (i64.add (i64.shl (local.get $r) (i64.const 30)) (i64.extend_i32_u (call $limb (local.get $a) (local.get $i)))))
      (local.set $qv (i64.div_u (local.get $cur) (i64.extend_i32_u (local.get $d))))
      (local.set $r (i64.rem_u (local.get $cur) (i64.extend_i32_u (local.get $d))))
      (call $set_limb (local.get $dst) (local.get $i) (i32.wrap_i64 (local.get $qv)))
      (br $again)))
    (if (i64.ne (local.get $r) (i64.const 0)) (then unreachable))
    (call $normalize (local.get $dst)))

  (func $binomial (param $n i32) (param $k i32) (param $dst i32)
    (local $i i32) (local $kk i32)
    (if (i32.or (i32.lt_s (local.get $k) (i32.const 0)) (i32.gt_s (local.get $k) (local.get $n))) (then (call $zero (local.get $dst)) (return)))
    (local.set $kk (local.get $k))
    (if (i32.gt_u (local.get $kk) (i32.sub (local.get $n) (local.get $kk))) (then (local.set $kk (i32.sub (local.get $n) (local.get $kk)))))
    (call $from_u64 (local.get $dst) (i64.const 1))
    (local.set $i (i32.const 1))
    (block $done (loop $again
      (br_if $done (i32.gt_u (local.get $i) (local.get $kk)))
      (call $mul_small (local.get $dst) (local.get $dst) (i32.add (i32.sub (local.get $n) (local.get $kk)) (local.get $i)))
      (call $div_small_exact (local.get $dst) (local.get $dst) (local.get $i))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $again))))

  ;; Cuenta exactamente las composiciones acotadas en orden léxico; el orden no afecta a la cardinalidad.
  (func $count_bounded (param $total i32) (param $slots i32) (param $lo i32) (param $hi i32) (param $dst i32)
    (local $s i32) (local $w i32) (local $j i32) (local $maxj i32) (local $n2 i32)
    (if (i32.eqz (local.get $slots))
      (then (if (i32.eqz (local.get $total)) (then (call $from_u64 (local.get $dst) (i64.const 1))) (else (call $zero (local.get $dst)))) (return)))
    (if (i32.or (i32.lt_s (local.get $total) (i32.mul (local.get $slots) (local.get $lo))) (i32.gt_s (local.get $total) (i32.mul (local.get $slots) (local.get $hi))))
      (then (call $zero (local.get $dst)) (return)))
    (local.set $s (i32.sub (local.get $total) (i32.mul (local.get $slots) (local.get $lo))))
    (local.set $w (i32.add (i32.sub (local.get $hi) (local.get $lo)) (i32.const 1)))
    (local.set $maxj (i32.div_u (local.get $s) (local.get $w)))
    (if (i32.gt_u (local.get $maxj) (local.get $slots)) (then (local.set $maxj (local.get $slots))))
    (call $zero (global.get $BC_POS)) (call $zero (global.get $BC_NEG))
    (local.set $j (i32.const 0))
    (block $done (loop $again
      (br_if $done (i32.gt_u (local.get $j) (local.get $maxj)))
      (call $binomial (local.get $slots) (local.get $j) (global.get $BC_A))
      (local.set $n2 (i32.add (i32.sub (local.get $s) (i32.mul (local.get $j) (local.get $w))) (i32.sub (local.get $slots) (i32.const 1))))
      (call $binomial (local.get $n2) (i32.sub (local.get $slots) (i32.const 1)) (global.get $BC_B))
      (call $mul (global.get $BC_TERM) (global.get $BC_A) (global.get $BC_B))
      (if (i32.eqz (i32.and (local.get $j) (i32.const 1)))
        (then (call $add (global.get $BC_POS) (global.get $BC_POS) (global.get $BC_TERM)))
        (else (call $add (global.get $BC_NEG) (global.get $BC_NEG) (global.get $BC_TERM))))
      (local.set $j (i32.add (local.get $j) (i32.const 1))) (br $again)))
    (if (i32.lt_s (call $cmp (global.get $BC_POS) (global.get $BC_NEG)) (i32.const 0)) (then unreachable))
    (call $sub (local.get $dst) (global.get $BC_POS) (global.get $BC_NEG)))

  (func $unrank_bounded (param $total i32) (param $slots0 i32) (param $lo i32) (param $hi i32) (param $rank i32)
    (local $rem i32) (local $slots i32) (local $pos i32) (local $x i32)
    (local.set $rem (local.get $total)) (local.set $slots (local.get $slots0)) (local.set $pos (i32.const 0))
    (block $allDone (loop $positionLoop
      (br_if $allDone (i32.eqz (local.get $slots)))
      (local.set $x (local.get $lo))
      (block $chosen (loop $candidateLoop
        (br_if $chosen (i32.gt_u (local.get $x) (local.get $hi)))
        (call $count_bounded (i32.sub (local.get $rem) (local.get $x)) (i32.sub (local.get $slots) (i32.const 1)) (local.get $lo) (local.get $hi) (global.get $BC_COUNT))
        (if (i32.gt_s (call $cmp (local.get $rank) (global.get $BC_COUNT)) (i32.const 0))
          (then (call $sub (local.get $rank) (local.get $rank) (global.get $BC_COUNT)))
          (else
            (i32.store (i32.add (global.get $LENGTHS) (i32.mul (local.get $pos) (i32.const 4))) (local.get $x))
            (local.set $rem (i32.sub (local.get $rem) (local.get $x)))
            (local.set $slots (i32.sub (local.get $slots) (i32.const 1)))
            (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
            (br $chosen)))
        (local.set $x (i32.add (local.get $x) (i32.const 1)))
        (br $candidateLoop)))
      (if (i32.gt_u (local.get $x) (local.get $hi)) (then unreachable))
      (br $positionLoop)))
    (if (i32.ne (local.get $rem) (i32.const 0)) (then unreachable)))

  (func $init_fixture_stream31
    (call $set_len (global.get $FIRST) (i32.const 5))
    (call $set_limb (global.get $FIRST) (i32.const 0) (i32.const 664736626))
    (call $set_limb (global.get $FIRST) (i32.const 1) (i32.const 700344269))
    (call $set_limb (global.get $FIRST) (i32.const 2) (i32.const 975175940))
    (call $set_limb (global.get $FIRST) (i32.const 3) (i32.const 896679873))
    (call $set_limb (global.get $FIRST) (i32.const 4) (i32.const 71)))

  (func $build_fixture_lengths
    (call $init_constants) (call $init_fixture_stream31)
    (call $count_bounded (i32.const 4922) (i32.const 45) (i32.const 4) (i32.const 123) (global.get $N))
    (call $choose (global.get $FIRST) (i32.const -1) (global.get $N) (global.get $BC_RANK))
    (call $unrank_bounded (i32.const 4922) (i32.const 45) (i32.const 4) (i32.const 123) (global.get $BC_RANK)))

  (func (export "test_bounded_small") (result i32)
    ;; Composiciones de 9 en 2 partes, 4..5: solo [4,5] y [5,4].
    (call $count_bounded (i32.const 9) (i32.const 2) (i32.const 4) (i32.const 5) (global.get $BC_COUNT))
    (i32.and (i32.eq (call $len (global.get $BC_COUNT)) (i32.const 1)) (i32.eq (call $limb (global.get $BC_COUNT) (i32.const 0)) (i32.const 2))))
  (func (export "fixture_month_length_count_bitlen") (result i32)
    (call $count_bounded (i32.const 4922) (i32.const 45) (i32.const 4) (i32.const 123) (global.get $BC_COUNT))
    (call $bitlen (global.get $BC_COUNT)))
  (func (export "fixture_month_length_1") (result i32) (call $build_fixture_lengths) (i32.load (global.get $LENGTHS)))
  (func (export "fixture_month_length_2") (result i32) (call $build_fixture_lengths) (i32.load offset=4 (global.get $LENGTHS)))
  (func (export "fixture_month_length_45") (result i32) (call $build_fixture_lengths) (i32.load offset=176 (global.get $LENGTHS)))
  (func (export "fixture_month_lengths_sum") (result i32)
    (local $i i32) (local $s i32)
    (call $build_fixture_lengths) (local.set $i (i32.const 0)) (local.set $s (i32.const 0))
    (block $done (loop $again (br_if $done (i32.ge_u (local.get $i) (i32.const 45))) (local.set $s (i32.add (local.get $s) (i32.load (i32.add (global.get $LENGTHS) (i32.mul (local.get $i) (i32.const 4)))))) (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $again)))
    (local.get $s))
  ;; Conteo H exacto con dos filas alternas; misma recurrencia normativa reducida, sin tabla completa.
  (global $WS_LENGTHS i32 (i32.const 190000))
  (global $WS_RMAX i32 (i32.const 190256))
  (global $WS_ROW_A i32 (i32.const 1000000))
  (global $WS_ROW_B i32 (i32.const 22500000))
  (global $WS_COEFF i32 (i32.const 190512))
  (global $WS_ACC i32 (i32.const 194928))
  (global $WS_TERM i32 (i32.const 199344))
  (data (i32.const 190000)
    "\61\00\00\00\7a\00\00\00\71\00\00\00\74\00\00\00\5d\00\00\00"
    "\5a\00\00\00\6b\00\00\00\76\00\00\00\6d\00\00\00\63\00\00\00"
    "\6d\00\00\00\78\00\00\00\66\00\00\00\6f\00\00\00\77\00\00\00"
    "\78\00\00\00\77\00\00\00\70\00\00\00\70\00\00\00\62\00\00\00"
    "\78\00\00\00\78\00\00\00\7a\00\00\00\52\00\00\00\70\00\00\00"
    "\75\00\00\00\71\00\00\00\61\00\00\00\4d\00\00\00\67\00\00\00"
    "\7b\00\00\00\75\00\00\00\78\00\00\00\73\00\00\00\69\00\00\00"
    "\62\00\00\00\70\00\00\00\77\00\00\00\79\00\00\00\76\00\00\00"
    "\42\00\00\00\78\00\00\00\6d\00\00\00\6d\00\00\00\79\00\00\00")
  (func $ws_len (param $j i32) (result i32) (i32.load (i32.add (global.get $WS_LENGTHS) (i32.mul (local.get $j) (i32.const 4)))))
  (func $ws_rmax (param $a i32) (result i32) (i32.load (i32.add (global.get $WS_RMAX) (i32.mul (local.get $a) (i32.const 4)))))
  (func $ws_at (param $base i32) (param $r i32) (result i32) (i32.add (local.get $base) (i32.mul (local.get $r) (global.get $CELL))))
  (func $ws_prepare
    (local $a i32) (local $rm i32) (local $need i32) (local $cur i32)
    (local.set $a (i32.const 0)) (local.set $rm (i32.const 0))
    (block $done (loop $again
      (i32.store (i32.add (global.get $WS_RMAX) (i32.mul (local.get $a) (i32.const 4))) (local.get $rm))
      (br_if $done (i32.eq (local.get $a) (i32.const 45)))
      (local.set $rm (i32.add (local.get $rm) (i32.sub (call $ws_len (local.get $a)) (i32.const 1))))
      (local.set $a (i32.add (local.get $a) (i32.const 1)))
      (br $again)))
    (local.set $need (i32.div_u (i32.add (i32.add (global.get $WS_ROW_B) (i32.mul (i32.add (local.get $rm) (i32.const 1)) (global.get $CELL))) (i32.const 65535)) (i32.const 65536)))
    (local.set $cur (memory.size))
    (if (i32.gt_u (local.get $need) (local.get $cur)) (then (if (i32.eq (memory.grow (i32.sub (local.get $need) (local.get $cur))) (i32.const -1)) (then unreachable)))))
  ;; Operaciones calientes en línea: exactas, mismo base 2^30, sin llamadas por miembro.
  (func $ws_copy_fast (param $dst i32) (param $src i32)
    (local $n i32) (local $i i32)
    (local.set $n (i32.load (local.get $src))) (i32.store (local.get $dst) (local.get $n))
    (local.set $i (i32.const 0))
    (block $done (loop $again
      (br_if $done (i32.ge_u (local.get $i) (local.get $n)))
      (i32.store (i32.add (i32.add (local.get $dst) (i32.const 4)) (i32.mul (local.get $i) (i32.const 4)))
        (i32.load (i32.add (i32.add (local.get $src) (i32.const 4)) (i32.mul (local.get $i) (i32.const 4)))))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $again))))

  (func $ws_add_inplace_fast (param $acc i32) (param $x i32)
    (local $na i32) (local $nx i32) (local $n i32) (local $i i32)
    (local $carry i64) (local $av i64) (local $xv i64) (local $s i64)
    (local.set $na (i32.load (local.get $acc))) (local.set $nx (i32.load (local.get $x)))
    (local.set $n (select (local.get $na) (local.get $nx) (i32.gt_u (local.get $na) (local.get $nx))))
    (local.set $i (i32.const 0)) (local.set $carry (i64.const 0))
    (block $done (loop $again
      (br_if $done (i32.ge_u (local.get $i) (local.get $n)))
      (local.set $av (if (result i64) (i32.lt_u (local.get $i) (local.get $na))
        (then (i64.extend_i32_u (i32.load (i32.add (i32.add (local.get $acc) (i32.const 4)) (i32.mul (local.get $i) (i32.const 4)))))) (else (i64.const 0))))
      (local.set $xv (if (result i64) (i32.lt_u (local.get $i) (local.get $nx))
        (then (i64.extend_i32_u (i32.load (i32.add (i32.add (local.get $x) (i32.const 4)) (i32.mul (local.get $i) (i32.const 4)))))) (else (i64.const 0))))
      (local.set $s (i64.add (i64.add (local.get $av) (local.get $xv)) (local.get $carry)))
      (i32.store (i32.add (i32.add (local.get $acc) (i32.const 4)) (i32.mul (local.get $i) (i32.const 4))) (i32.wrap_i64 (i64.and (local.get $s) (global.get $MASK))))
      (local.set $carry (i64.shr_u (local.get $s) (i64.const 30)))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $again)))
    (if (i64.ne (local.get $carry) (i64.const 0))
      (then
        (i32.store (i32.add (i32.add (local.get $acc) (i32.const 4)) (i32.mul (local.get $n) (i32.const 4))) (i32.wrap_i64 (local.get $carry)))
        (local.set $n (i32.add (local.get $n) (i32.const 1)))))
    (i32.store (local.get $acc) (local.get $n)))

  (func $ws_mul_fast (param $dst i32) (param $big i32) (param $smallish i32)
    (local $na i32) (local $nb i32) (local $i i32) (local $j i32) (local $k i32) (local $n i32)
    (local $carry i64) (local $cur i64) (local $prod i64) (local $av i64) (local $bv i64)
    (local.set $na (i32.load (local.get $big))) (local.set $nb (i32.load (local.get $smallish)))
    (if (i32.or (i32.eqz (local.get $na)) (i32.eqz (local.get $nb))) (then (i32.store (local.get $dst) (i32.const 0)) (return)))
    (local.set $n (i32.add (local.get $na) (local.get $nb)))
    (if (i32.gt_u (local.get $n) (global.get $MAXL)) (then unreachable))
    (i32.store (local.get $dst) (local.get $n))
    (local.set $k (i32.const 0))
    (block $zd (loop $zl
      (br_if $zd (i32.ge_u (local.get $k) (local.get $n)))
      (i32.store (i32.add (i32.add (local.get $dst) (i32.const 4)) (i32.mul (local.get $k) (i32.const 4))) (i32.const 0))
      (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $zl)))
    ;; Se itera por el operando pequeño para reducir sobrecarga del bucle externo.
    (local.set $j (i32.const 0))
    (block $od (loop $outer
      (br_if $od (i32.ge_u (local.get $j) (local.get $nb)))
      (local.set $bv (i64.extend_i32_u (i32.load (i32.add (i32.add (local.get $smallish) (i32.const 4)) (i32.mul (local.get $j) (i32.const 4))))))
      (local.set $carry (i64.const 0)) (local.set $i (i32.const 0))
      (block $id (loop $inner
        (br_if $id (i32.ge_u (local.get $i) (local.get $na)))
        (local.set $k (i32.add (local.get $i) (local.get $j)))
        (local.set $av (i64.extend_i32_u (i32.load (i32.add (i32.add (local.get $big) (i32.const 4)) (i32.mul (local.get $i) (i32.const 4))))))
        (local.set $prod (i64.mul (local.get $av) (local.get $bv)))
        (local.set $cur (i64.add (i64.add (i64.extend_i32_u (i32.load (i32.add (i32.add (local.get $dst) (i32.const 4)) (i32.mul (local.get $k) (i32.const 4))))) (local.get $prod)) (local.get $carry)))
        (i32.store (i32.add (i32.add (local.get $dst) (i32.const 4)) (i32.mul (local.get $k) (i32.const 4))) (i32.wrap_i64 (i64.and (local.get $cur) (global.get $MASK))))
        (local.set $carry (i64.shr_u (local.get $cur) (i64.const 30)))
        (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $inner)))
      (local.set $k (i32.add (local.get $na) (local.get $j)))
      (block $cd (loop $cl
        (br_if $cd (i64.eqz (local.get $carry)))
        (local.set $cur (i64.add (i64.extend_i32_u (i32.load (i32.add (i32.add (local.get $dst) (i32.const 4)) (i32.mul (local.get $k) (i32.const 4))))) (local.get $carry)))
        (i32.store (i32.add (i32.add (local.get $dst) (i32.const 4)) (i32.mul (local.get $k) (i32.const 4))) (i32.wrap_i64 (i64.and (local.get $cur) (global.get $MASK))))
        (local.set $carry (i64.shr_u (local.get $cur) (i64.const 30)))
        (local.set $k (i32.add (local.get $k) (i32.const 1))) (br $cl)))
      (local.set $j (i32.add (local.get $j) (i32.const 1))) (br $outer)))
    ;; Normalización en línea.
    (block $nd (loop $nl
      (br_if $nd (i32.eqz (local.get $n)))
      (br_if $nd (i32.ne (i32.load (i32.add (i32.add (local.get $dst) (i32.const 4)) (i32.mul (i32.sub (local.get $n) (i32.const 1)) (i32.const 4)))) (i32.const 0)))
      (local.set $n (i32.sub (local.get $n) (i32.const 1))) (br $nl)))
    (i32.store (local.get $dst) (local.get $n)))

  (func $ws_build_fast (param $dst i32)
    (local $a i32) (local $r i32) (local $rm i32) (local $qv i32)
    (local $childBase i32) (local $parentBase i32) (local $tmpBase i32)
    (call $ws_prepare)
    (local.set $childBase (global.get $WS_ROW_A)) (local.set $parentBase (global.get $WS_ROW_B))
    (local.set $rm (call $ws_rmax (i32.const 45))) (local.set $r (i32.const 0))
    (block $bd (loop $bl
      (br_if $bd (i32.gt_u (local.get $r) (local.get $rm)))
      (i32.store (call $ws_at (local.get $childBase) (local.get $r)) (i32.const 1))
      (i32.store offset=4 (call $ws_at (local.get $childBase) (local.get $r)) (i32.const 1))
      (local.set $r (i32.add (local.get $r) (i32.const 1))) (br $bl)))
    (local.set $a (i32.const 44))
    (block $allDone (loop $rows
      (br_if $allDone (i32.lt_s (local.get $a) (i32.const 0)))
      (local.set $qv (call $ws_len (local.get $a))) (local.set $rm (call $ws_rmax (local.get $a)))
      (call $from_u64 (global.get $WS_COEFF) (i64.const 1)) (call $zero (global.get $WS_ACC))
      (local.set $r (i32.const 0))
      (block $rd (loop $cells
        (br_if $rd (i32.gt_u (local.get $r) (local.get $rm)))
        (call $ws_mul_fast (global.get $WS_TERM) (call $ws_at (local.get $childBase) (i32.add (i32.sub (local.get $qv) (i32.const 1)) (local.get $r))) (global.get $WS_COEFF))
        (call $ws_add_inplace_fast (global.get $WS_ACC) (global.get $WS_TERM))
        (call $ws_copy_fast (call $ws_at (local.get $parentBase) (local.get $r)) (global.get $WS_ACC))
        (if (i32.lt_u (local.get $r) (local.get $rm))
          (then
            (call $mul_small (global.get $WS_COEFF) (global.get $WS_COEFF) (i32.add (i32.sub (local.get $qv) (i32.const 1)) (local.get $r)))
            (call $div_small_exact (global.get $WS_COEFF) (global.get $WS_COEFF) (i32.add (local.get $r) (i32.const 1)))))
        (local.set $r (i32.add (local.get $r) (i32.const 1))) (br $cells)))
      (local.set $tmpBase (local.get $childBase)) (local.set $childBase (local.get $parentBase)) (local.set $parentBase (local.get $tmpBase))
      (local.set $a (i32.sub (local.get $a) (i32.const 1))) (br $rows)))
    (call $ws_copy_fast (local.get $dst) (call $ws_at (local.get $childBase) (i32.const 0))))

  (func (export "fixture_weaving_count_bitlen_fast") (result i32)
    (call $ws_build_fast (global.get $BC_COUNT)) (call $bitlen (global.get $BC_COUNT)))
  ;; Motor completo para el reconstrucción normativa por rango del entrelazado real.
  ;; La tabla H conserva exactamente la recurrencia reducida ya verificada;
  ;; se materializa solo en el oráculo de prueba para que cada prefijo tenga consulta O(1).
  (global $WF_OFFSETS i32 (i32.const 210000))
  (global $WF_REM i32 (i32.const 211000))
  (global $WF_PREFIX i32 (i32.const 212000))
  (global $WF_OUT i32 (i32.const 213000))
  (global $WF_COUNTS i32 (i32.const 233000))
  (global $WF_FIRSTPOS i32 (i32.const 234000))
  (global $WF_LASTPOS i32 (i32.const 235000))
  (global $WF_A i32 (i32.const 240000))
  (global $WF_BASE_A i32 (i32.const 244416))
  (global $WF_ACTIVE_TOTAL i32 (i32.const 248832))
  (global $WF_BASE_BLOCK i32 (i32.const 253248))
  (global $WF_CAND_BLOCK i32 (i32.const 257664))
  (global $WF_CAND_A i32 (i32.const 262080))
  (global $WF_FULL_BASE i32 (i32.const 50000000))

  (func $wf_is_one (param $p i32) (result i32)
    (i32.and
      (i32.eq (call $len (local.get $p)) (i32.const 1))
      (i32.eq (call $limb (local.get $p) (i32.const 0)) (i32.const 1))))

  (func $wf_offset (param $a i32) (result i32)
    (i32.load (i32.add (global.get $WF_OFFSETS) (i32.mul (local.get $a) (i32.const 4)))))

  (func $wf_at (param $a i32) (param $r i32) (result i32)
    (i32.add (call $wf_offset (local.get $a)) (i32.mul (local.get $r) (global.get $CELL))))

  (func $wf_prepare
    (local $a i32) (local $cursor i32) (local $need i32) (local $cur i32)
    ;; ws_prepare fija rmax[a] con la misma definición usada por el contador de dos filas.
    (call $ws_prepare)
    (local.set $cursor (global.get $WF_FULL_BASE))
    (local.set $a (i32.const 0))
    (block $done (loop $again
      (br_if $done (i32.gt_u (local.get $a) (i32.const 45)))
      (i32.store
        (i32.add (global.get $WF_OFFSETS) (i32.mul (local.get $a) (i32.const 4)))
        (local.get $cursor))
      (local.set $cursor
        (i32.add (local.get $cursor)
          (i32.mul (i32.add (call $ws_rmax (local.get $a)) (i32.const 1)) (global.get $CELL))))
      (local.set $a (i32.add (local.get $a) (i32.const 1)))
      (br $again)))
    (local.set $need (i32.div_u (i32.add (local.get $cursor) (i32.const 65535)) (i32.const 65536)))
    (local.set $cur (memory.size))
    (if (i32.gt_u (local.get $need) (local.get $cur))
      (then
        (if (i32.eq (memory.grow (i32.sub (local.get $need) (local.get $cur))) (i32.const -1))
          (then unreachable)))))

  (func $wf_build_full (param $dst i32)
    (local $a i32) (local $r i32) (local $rm i32) (local $qv i32)
    (local $child i32) (local $parent i32)
    (call $wf_prepare)
    ;; H_45(R)=1 para todo R admisible.
    (local.set $rm (call $ws_rmax (i32.const 45)))
    (local.set $r (i32.const 0))
    (block $bd (loop $bl
      (br_if $bd (i32.gt_u (local.get $r) (local.get $rm)))
      (i32.store (call $wf_at (i32.const 45) (local.get $r)) (i32.const 1))
      (i32.store offset=4 (call $wf_at (i32.const 45) (local.get $r)) (i32.const 1))
      (local.set $r (i32.add (local.get $r) (i32.const 1)))
      (br $bl)))
    (local.set $a (i32.const 44))
    (block $doneRows (loop $rows
      (br_if $doneRows (i32.lt_s (local.get $a) (i32.const 0)))
      (local.set $child (call $wf_offset (i32.add (local.get $a) (i32.const 1))))
      (local.set $parent (call $wf_offset (local.get $a)))
      (local.set $qv (call $ws_len (local.get $a)))
      (local.set $rm (call $ws_rmax (local.get $a)))
      (call $from_u64 (global.get $WS_COEFF) (i64.const 1))
      (call $zero (global.get $WS_ACC))
      (local.set $r (i32.const 0))
      (block $doneCells (loop $cells
        (br_if $doneCells (i32.gt_u (local.get $r) (local.get $rm)))
        (call $ws_mul_fast
          (global.get $WS_TERM)
          (i32.add (local.get $child)
            (i32.mul (i32.add (i32.sub (local.get $qv) (i32.const 1)) (local.get $r)) (global.get $CELL)))
          (global.get $WS_COEFF))
        (call $ws_add_inplace_fast (global.get $WS_ACC) (global.get $WS_TERM))
        (call $ws_copy_fast
          (i32.add (local.get $parent) (i32.mul (local.get $r) (global.get $CELL)))
          (global.get $WS_ACC))
        (if (i32.lt_u (local.get $r) (local.get $rm))
          (then
            (call $mul_small
              (global.get $WS_COEFF) (global.get $WS_COEFF)
              (i32.add (i32.sub (local.get $qv) (i32.const 1)) (local.get $r)))
            (call $div_small_exact
              (global.get $WS_COEFF) (global.get $WS_COEFF)
              (i32.add (local.get $r) (i32.const 1)))))
        (local.set $r (i32.add (local.get $r) (i32.const 1)))
        (br $cells)))
      (local.set $a (i32.sub (local.get $a) (i32.const 1)))
      (br $rows)))
    (call $ws_copy_fast (local.get $dst) (call $wf_at (i32.const 0) (i32.const 0))))

  (func $wf_mul_binom_inplace (param $p i32) (param $n i32) (param $k0 i32)
    (local $k i32) (local $i i32)
    (local.set $k (local.get $k0))
    (if (i32.gt_u (local.get $k) (i32.sub (local.get $n) (local.get $k)))
      (then (local.set $k (i32.sub (local.get $n) (local.get $k)))))
    (local.set $i (i32.const 1))
    (block $done (loop $again
      (br_if $done (i32.gt_u (local.get $i) (local.get $k)))
      (call $wf_mul_small_alias
        (local.get $p) (local.get $p)
        (i32.add (i32.sub (local.get $n) (local.get $k)) (local.get $i)))
      (call $wf_div_small_alias (local.get $p) (local.get $p) (local.get $i))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $again)))
  )

  (func $wf_set_stream32
    (call $set_len (global.get $FIRST) (i32.const 5))
    (call $set_limb (global.get $FIRST) (i32.const 0) (i32.const 856089706))
    (call $set_limb (global.get $FIRST) (i32.const 1) (i32.const 578030252))
    (call $set_limb (global.get $FIRST) (i32.const 2) (i32.const 714061183))
    (call $set_limb (global.get $FIRST) (i32.const 3) (i32.const 780012404))
    (call $set_limb (global.get $FIRST) (i32.const 4) (i32.const 91)))

  (func $wf_build_prefix (param $b i32) (param $a i32) (result i32)
    (local $j i32) (local $s i32)
    (local.set $j (local.get $b))
    (local.set $s (i32.const 0))
    (block $done (loop $again
      (br_if $done (i32.ge_u (local.get $j) (local.get $a)))
      (local.set $s
        (i32.add (local.get $s)
          (i32.load (i32.add (global.get $WF_REM) (i32.mul (local.get $j) (i32.const 4))))))
      (i32.store (i32.add (global.get $WF_PREFIX) (i32.mul (local.get $j) (i32.const 4))) (local.get $s))
      (local.set $j (i32.add (local.get $j) (i32.const 1)))
      (br $again)))
    (local.get $s))

  (func $wf_validate_output (result i32)
    (local $i i32) (local $p i32) (local $id i32) (local $c i32)
    (local $prevFirst i32) (local $prevLast i32)
    (local.set $i (i32.const 0))
    (block $zi (loop $zil
      (br_if $zi (i32.ge_u (local.get $i) (i32.const 45)))
      (i32.store (i32.add (global.get $WF_COUNTS) (i32.mul (local.get $i) (i32.const 4))) (i32.const 0))
      (i32.store (i32.add (global.get $WF_FIRSTPOS) (i32.mul (local.get $i) (i32.const 4))) (i32.const -1))
      (i32.store (i32.add (global.get $WF_LASTPOS) (i32.mul (local.get $i) (i32.const 4))) (i32.const -1))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $zil)))
    (local.set $p (i32.const 0))
    (block $pd (loop $pl
      (br_if $pd (i32.ge_u (local.get $p) (i32.const 4922)))
      (local.set $id (i32.sub (i32.load (i32.add (global.get $WF_OUT) (i32.mul (local.get $p) (i32.const 4)))) (i32.const 1)))
      (if (i32.ge_u (local.get $id) (i32.const 45)) (then (return (i32.const 0))))
      (local.set $c (i32.load (i32.add (global.get $WF_COUNTS) (i32.mul (local.get $id) (i32.const 4)))))
      (i32.store (i32.add (global.get $WF_COUNTS) (i32.mul (local.get $id) (i32.const 4))) (i32.add (local.get $c) (i32.const 1)))
      (if (i32.eq (i32.load (i32.add (global.get $WF_FIRSTPOS) (i32.mul (local.get $id) (i32.const 4)))) (i32.const -1))
        (then (i32.store (i32.add (global.get $WF_FIRSTPOS) (i32.mul (local.get $id) (i32.const 4))) (local.get $p))))
      (i32.store (i32.add (global.get $WF_LASTPOS) (i32.mul (local.get $id) (i32.const 4))) (local.get $p))
      (local.set $p (i32.add (local.get $p) (i32.const 1)))
      (br $pl)))
    (local.set $i (i32.const 0))
    (local.set $prevFirst (i32.const -1))
    (local.set $prevLast (i32.const -1))
    (block $vd (loop $vl
      (br_if $vd (i32.ge_u (local.get $i) (i32.const 45)))
      (if (i32.ne
            (i32.load (i32.add (global.get $WF_COUNTS) (i32.mul (local.get $i) (i32.const 4))))
            (call $ws_len (local.get $i)))
        (then (return (i32.const 0))))
      (if (i32.le_s
            (i32.load (i32.add (global.get $WF_FIRSTPOS) (i32.mul (local.get $i) (i32.const 4))))
            (local.get $prevFirst))
        (then (return (i32.const 0))))
      (if (i32.le_s
            (i32.load (i32.add (global.get $WF_LASTPOS) (i32.mul (local.get $i) (i32.const 4))))
            (local.get $prevLast))
        (then (return (i32.const 0))))
      (local.set $prevFirst (i32.load (i32.add (global.get $WF_FIRSTPOS) (i32.mul (local.get $i) (i32.const 4)))))
      (local.set $prevLast (i32.load (i32.add (global.get $WF_LASTPOS) (i32.mul (local.get $i) (i32.const 4)))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $vl)))
    (i32.const 1))

  (func (export "fixture_weaving_full_summary") (result i32 i32 i32 i32 i32 i32)
    (local $targetId i32) (local $p i32) (local $dayInMonth i32)
    (call $init_constants)
    (call $wf_set_stream32)
    (call $wp_build (global.get $N))
    (call $choose (global.get $FIRST) (i32.const -1) (global.get $N) (global.get $RESULT))
    (drop (call $wf_unrank3 (global.get $RESULT)))
    ;; Después de construir H, la memoria ya cubre el área auxiliar de 46 MB.
    (call $fi_build_partition)
    (call $fi_build_cutlet_names)
    (call $fi_build_month_names)
    (local.set $targetId (i32.load (i32.add (global.get $WF_OUT) (i32.mul (i32.const 2661) (i32.const 4)))))
    (local.set $p (i32.const 0))
    (local.set $dayInMonth (i32.const 0))
    (block $dd (loop $dl
      (br_if $dd (i32.gt_u (local.get $p) (i32.const 2661)))
      (if (i32.eq (i32.load (i32.add (global.get $WF_OUT) (i32.mul (local.get $p) (i32.const 4)))) (local.get $targetId))
        (then (local.set $dayInMonth (i32.add (local.get $dayInMonth) (i32.const 1)))))
      (local.set $p (i32.add (local.get $p) (i32.const 1)))
      (br $dl)))
    (call $wf_validate_output)
    (i32.load (global.get $WF_OUT))
    (local.get $targetId)
    (local.get $dayInMonth)
    (i32.load (i32.add (global.get $WF_OUT) (i32.mul (i32.const 4921) (i32.const 4))))
    (call $bitlen (global.get $N)))

  ;; Almacén empaquetado de H: cada natural ocupa solo 4+4*len bytes.
  ;; Las dos filas de trabajo siguen siendo las mismas; la tabla de punteros es solo de prueba.
  (global $WP_ROWOFF i32 (i32.const 270000))
  (global $WP_PTR_BASE i32 (i32.const 280000))
  (global $WP_ARENA_START i32 (i32.const 50000000))
  (global $WP_ARENA (mut i32) (i32.const 50000000))

  (func $wp_prepare_offsets
    (local $a i32) (local $cells i32)
    (call $ws_prepare)
    (local.set $a (i32.const 0))
    (local.set $cells (i32.const 0))
    (block $done (loop $again
      (br_if $done (i32.gt_u (local.get $a) (i32.const 45)))
      (i32.store (i32.add (global.get $WP_ROWOFF) (i32.mul (local.get $a) (i32.const 4))) (local.get $cells))
      (local.set $cells (i32.add (local.get $cells) (i32.add (call $ws_rmax (local.get $a)) (i32.const 1))))
      (local.set $a (i32.add (local.get $a) (i32.const 1)))
      (br $again)))
    ;; La tabla de punteros cabe por debajo de un megabyte para 45 meses y 4922 días.
    (if (i32.ge_u
          (i32.add (global.get $WP_PTR_BASE) (i32.mul (local.get $cells) (i32.const 4)))
          (global.get $WS_ROW_A))
      (then unreachable)))

  (func $wp_slot (param $a i32) (param $r i32) (result i32)
    (i32.add
      (global.get $WP_PTR_BASE)
      (i32.mul
        (i32.add
          (i32.load (i32.add (global.get $WP_ROWOFF) (i32.mul (local.get $a) (i32.const 4))))
          (local.get $r))
        (i32.const 4))))

  (func $wp_at (param $a i32) (param $r i32) (result i32)
    (i32.load (call $wp_slot (local.get $a) (local.get $r))))

  (func $wp_ensure (param $end i32)
    (local $curPages i32) (local $wantPages i32) (local $grow i32)
    (local.set $curPages (memory.size))
    (local.set $wantPages (i32.div_u (i32.add (local.get $end) (i32.const 65535)) (i32.const 65536)))
    (if (i32.gt_u (local.get $wantPages) (local.get $curPages))
      (then
        ;; Se crece con 256 páginas de holgura para no pedir memory.grow por cada pocos valores.
        (local.set $grow (i32.add (i32.sub (local.get $wantPages) (local.get $curPages)) (i32.const 256)))
        (if (i32.eq (memory.grow (local.get $grow)) (i32.const -1)) (then unreachable)))))

  (func $wp_pack (param $src i32) (result i32)
    (local $ptr i32) (local $end i32) (local $n i32) (local $i i32)
    (local.set $n (i32.load (local.get $src)))
    (local.set $ptr (global.get $WP_ARENA))
    (local.set $end (i32.add (local.get $ptr) (i32.add (i32.const 4) (i32.mul (local.get $n) (i32.const 4)))))
    (call $wp_ensure (local.get $end))
    (i32.store (local.get $ptr) (local.get $n))
    (local.set $i (i32.const 0))
    (block $done (loop $again
      (br_if $done (i32.ge_u (local.get $i) (local.get $n)))
      (i32.store
        (i32.add (i32.add (local.get $ptr) (i32.const 4)) (i32.mul (local.get $i) (i32.const 4)))
        (i32.load (i32.add (i32.add (local.get $src) (i32.const 4)) (i32.mul (local.get $i) (i32.const 4)))))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $again)))
    (global.set $WP_ARENA (local.get $end))
    (local.get $ptr))

  (func $wp_build (param $dst i32)
    (local $a i32) (local $r i32) (local $rm i32) (local $qv i32)
    (local $childBase i32) (local $parentBase i32) (local $tmpBase i32) (local $packed i32)
    (global.set $WP_ARENA (global.get $WP_ARENA_START))
    (call $wp_prepare_offsets)
    (local.set $childBase (global.get $WS_ROW_A))
    (local.set $parentBase (global.get $WS_ROW_B))
    ;; H_45(R)=1; todas esas entradas pueden compartir el mismo ONE inmutable.
    (local.set $rm (call $ws_rmax (i32.const 45)))
    (local.set $r (i32.const 0))
    (block $bd (loop $bl
      (br_if $bd (i32.gt_u (local.get $r) (local.get $rm)))
      (i32.store (call $ws_at (local.get $childBase) (local.get $r)) (i32.const 1))
      (i32.store offset=4 (call $ws_at (local.get $childBase) (local.get $r)) (i32.const 1))
      (i32.store (call $wp_slot (i32.const 45) (local.get $r)) (global.get $ONE))
      (local.set $r (i32.add (local.get $r) (i32.const 1)))
      (br $bl)))
    (local.set $a (i32.const 44))
    (block $allDone (loop $rows
      (br_if $allDone (i32.lt_s (local.get $a) (i32.const 0)))
      (local.set $qv (call $ws_len (local.get $a)))
      (local.set $rm (call $ws_rmax (local.get $a)))
      (call $from_u64 (global.get $WS_COEFF) (i64.const 1))
      (call $zero (global.get $WS_ACC))
      (local.set $r (i32.const 0))
      (block $rd (loop $cells
        (br_if $rd (i32.gt_u (local.get $r) (local.get $rm)))
        (call $ws_mul_fast
          (global.get $WS_TERM)
          (call $ws_at (local.get $childBase) (i32.add (i32.sub (local.get $qv) (i32.const 1)) (local.get $r)))
          (global.get $WS_COEFF))
        (call $ws_add_inplace_fast (global.get $WS_ACC) (global.get $WS_TERM))
        (call $ws_copy_fast (call $ws_at (local.get $parentBase) (local.get $r)) (global.get $WS_ACC))
        (local.set $packed (call $wp_pack (call $ws_at (local.get $parentBase) (local.get $r))))
        (i32.store (call $wp_slot (local.get $a) (local.get $r)) (local.get $packed))
        (if (i32.lt_u (local.get $r) (local.get $rm))
          (then
            (call $mul_small
              (global.get $WS_COEFF) (global.get $WS_COEFF)
              (i32.add (i32.sub (local.get $qv) (i32.const 1)) (local.get $r)))
            (call $div_small_exact
              (global.get $WS_COEFF) (global.get $WS_COEFF)
              (i32.add (local.get $r) (i32.const 1)))))
        (local.set $r (i32.add (local.get $r) (i32.const 1)))
        (br $cells)))
      (local.set $tmpBase (local.get $childBase))
      (local.set $childBase (local.get $parentBase))
      (local.set $parentBase (local.get $tmpBase))
      (local.set $a (i32.sub (local.get $a) (i32.const 1)))
      (br $rows)))
    (call $ws_copy_fast (local.get $dst) (call $wp_at (i32.const 0) (i32.const 0))))

  (func (export "fixture_packed_arena_bytes") (result i32)
    (call $init_constants)
    (call $wp_build (global.get $N))
    (i32.sub (global.get $WP_ARENA) (global.get $WP_ARENA_START)))
  ;; Operaciones sobre el mismo operando para la ruta caliente de la reconstrucción por rango. Exigen dst==a y conservan exactamente base 2^30.
  (func $wf_mul_small_alias (param $dst i32) (param $a i32) (param $x i32)
    (local $n i32) (local $i i32) (local $carry i64) (local $v i64)
    (if (i32.ne (local.get $dst) (local.get $a)) (then unreachable))
    (if (i32.eqz (local.get $x)) (then (i32.store (local.get $dst) (i32.const 0)) (return)))
    (local.set $n (i32.load (local.get $dst)))
    (local.set $i (i32.const 0))
    (local.set $carry (i64.const 0))
    (block $done (loop $again
      (br_if $done (i32.ge_u (local.get $i) (local.get $n)))
      (local.set $v
        (i64.add
          (i64.mul
            (i64.extend_i32_u (i32.load (i32.add (i32.add (local.get $dst) (i32.const 4)) (i32.mul (local.get $i) (i32.const 4)))))
            (i64.extend_i32_u (local.get $x)))
          (local.get $carry)))
      (i32.store
        (i32.add (i32.add (local.get $dst) (i32.const 4)) (i32.mul (local.get $i) (i32.const 4)))
        (i32.wrap_i64 (i64.and (local.get $v) (global.get $MASK))))
      (local.set $carry (i64.shr_u (local.get $v) (i64.const 30)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $again)))
    (if (i64.ne (local.get $carry) (i64.const 0))
      (then
        (if (i32.ge_u (local.get $n) (global.get $MAXL)) (then unreachable))
        (i32.store
          (i32.add (i32.add (local.get $dst) (i32.const 4)) (i32.mul (local.get $n) (i32.const 4)))
          (i32.wrap_i64 (local.get $carry)))
        (local.set $n (i32.add (local.get $n) (i32.const 1)))))
    (i32.store (local.get $dst) (local.get $n)))

  (func $wf_div_small_alias (param $dst i32) (param $a i32) (param $d i32)
    (local $n i32) (local $i i32) (local $r i64) (local $cur i64) (local $qv i64)
    (if (i32.or (i32.ne (local.get $dst) (local.get $a)) (i32.eqz (local.get $d))) (then unreachable))
    (local.set $n (i32.load (local.get $dst)))
    (local.set $i (local.get $n))
    (local.set $r (i64.const 0))
    (block $done (loop $again
      (br_if $done (i32.eqz (local.get $i)))
      (local.set $i (i32.sub (local.get $i) (i32.const 1)))
      (local.set $cur
        (i64.add
          (i64.shl (local.get $r) (i64.const 30))
          (i64.extend_i32_u (i32.load (i32.add (i32.add (local.get $dst) (i32.const 4)) (i32.mul (local.get $i) (i32.const 4))))))
      )
      (local.set $qv (i64.div_u (local.get $cur) (i64.extend_i32_u (local.get $d))))
      (local.set $r (i64.rem_u (local.get $cur) (i64.extend_i32_u (local.get $d))))
      (i32.store
        (i32.add (i32.add (local.get $dst) (i32.const 4)) (i32.mul (local.get $i) (i32.const 4)))
        (i32.wrap_i64 (local.get $qv)))
      (br $again)))
    (if (i64.ne (local.get $r) (i64.const 0)) (then unreachable))
    (block $norm (loop $nl
      (br_if $norm (i32.eqz (local.get $n)))
      (br_if $norm
        (i32.ne
          (i32.load (i32.add (i32.add (local.get $dst) (i32.const 4)) (i32.mul (i32.sub (local.get $n) (i32.const 1)) (i32.const 4))))
          (i32.const 0)))
      (local.set $n (i32.sub (local.get $n) (i32.const 1)))
      (br $nl)))
    (i32.store (local.get $dst) (local.get $n)))

  (func $wf_sub_alias (param $dst i32) (param $a i32) (param $b i32)
    (local $na i32) (local $nb i32) (local $i i32)
    (local $borrow i64) (local $av i64) (local $bv i64) (local $v i64)
    (if (i32.ne (local.get $dst) (local.get $a)) (then unreachable))
    (if (i32.lt_s (call $cmp (local.get $a) (local.get $b)) (i32.const 0)) (then unreachable))
    (local.set $na (i32.load (local.get $dst)))
    (local.set $nb (i32.load (local.get $b)))
    (local.set $i (i32.const 0))
    (local.set $borrow (i64.const 0))
    (block $done (loop $again
      (br_if $done (i32.ge_u (local.get $i) (local.get $na)))
      (local.set $av (i64.extend_i32_u (i32.load (i32.add (i32.add (local.get $dst) (i32.const 4)) (i32.mul (local.get $i) (i32.const 4))))))
      (local.set $bv
        (if (result i64) (i32.lt_u (local.get $i) (local.get $nb))
          (then (i64.extend_i32_u (i32.load (i32.add (i32.add (local.get $b) (i32.const 4)) (i32.mul (local.get $i) (i32.const 4))))))
          (else (i64.const 0))))
      (local.set $v (i64.sub (i64.sub (local.get $av) (local.get $bv)) (local.get $borrow)))
      (if (i64.lt_s (local.get $v) (i64.const 0))
        (then (local.set $v (i64.add (local.get $v) (global.get $BASE))) (local.set $borrow (i64.const 1)))
        (else (local.set $borrow (i64.const 0))))
      (i32.store
        (i32.add (i32.add (local.get $dst) (i32.const 4)) (i32.mul (local.get $i) (i32.const 4)))
        (i32.wrap_i64 (local.get $v)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br $again)))
    (if (i64.ne (local.get $borrow) (i64.const 0)) (then unreachable))
    (block $norm (loop $nl
      (br_if $norm (i32.eqz (local.get $na)))
      (br_if $norm
        (i32.ne
          (i32.load (i32.add (i32.add (local.get $dst) (i32.const 4)) (i32.mul (i32.sub (local.get $na) (i32.const 1)) (i32.const 4))))
          (i32.const 0)))
      (local.set $na (i32.sub (local.get $na) (i32.const 1)))
      (br $nl)))
    (i32.store (local.get $dst) (local.get $na)))

  ;; Reconstrucción equivalente por rango con sumas telescópicas de bloques.
  ;; Para los meses activos, C_k/A=P_k-P_{k-1}; por tanto, umbral_k=A*H(R-1)*P_k.
  (func $wf_unrank2 (param $rank i32) (result i32)
    (local $a i32) (local $b i32) (local $R i32) (local $pos i32)
    (local $j i32) (local $rj i32) (local $qv i32) (local $sum i32)
    (local $sCur i32) (local $sPrev i32) (local $selected i32) (local $hOne i32)
    (local.set $a (i32.const 0))
    (local.set $b (i32.const 0))
    (local.set $R (i32.const 0))
    (local.set $pos (i32.const 0))
    (call $from_u64 (global.get $WF_A) (i64.const 1))
    (local.set $j (i32.const 0))
    (block $zr (loop $zrl
      (br_if $zr (i32.ge_u (local.get $j) (i32.const 45)))
      (i32.store (i32.add (global.get $WF_REM) (i32.mul (local.get $j) (i32.const 4))) (i32.const 0))
      (local.set $j (i32.add (local.get $j) (i32.const 1)))
      (br $zrl)))

    (block $allDone (loop $positions
      (br_if $allDone (i32.ge_u (local.get $pos) (i32.const 4922)))
      (local.set $selected (i32.const -1))
      (local.set $hOne (i32.const 0))

      (if (i32.gt_u (local.get $R) (i32.const 0))
        (then
          ;; Total de todos los movimientos hacia meses ya abiertos.
          (local.set $hOne (call $wf_is_one (call $wp_at (local.get $a) (i32.sub (local.get $R) (i32.const 1)))))
          (if (call $wf_is_one (global.get $WF_A))
            (then (call $ws_copy_fast (global.get $WF_ACTIVE_TOTAL) (call $wp_at (local.get $a) (i32.sub (local.get $R) (i32.const 1)))))
            (else
              (if (local.get $hOne)
                (then (call $ws_copy_fast (global.get $WF_ACTIVE_TOTAL) (global.get $WF_A)))
                (else
                  (call $ws_mul_fast
                    (global.get $WF_ACTIVE_TOTAL)
                    (call $wp_at (local.get $a) (i32.sub (local.get $R) (i32.const 1)))
                    (global.get $WF_A))))))

          (if (i32.gt_s (call $cmp (local.get $rank) (global.get $WF_ACTIVE_TOTAL)) (i32.const 0))
            (then
              ;; Todos los meses activos preceden léxicamente al mes nuevo.
              (call $wf_sub_alias (local.get $rank) (local.get $rank) (global.get $WF_ACTIVE_TOTAL)))
            (else
              ;; La elección está entre los activos. P_K=1; se buscan umbrales hacia atrás.
              (local.set $sum (call $wf_build_prefix (local.get $b) (local.get $a)))
              (if (i32.ne (local.get $sum) (local.get $R)) (then unreachable))
              (call $ws_copy_fast (global.get $WF_BASE_BLOCK) (global.get $WF_ACTIVE_TOTAL))
              (if (i32.eqz (local.get $hOne))
                (then (call $ws_copy_fast (global.get $WF_BASE_A) (global.get $WF_A))))
              (local.set $j (i32.sub (local.get $a) (i32.const 1)))
              (block $chosen (loop $back
                (if (i32.eq (local.get $j) (local.get $b))
                  (then
                    (local.set $selected (local.get $j))
                    (if (local.get $hOne)
                      (then (call $ws_copy_fast (global.get $WF_A) (global.get $WF_BASE_BLOCK)))
                      (else (call $ws_copy_fast (global.get $WF_A) (global.get $WF_BASE_A))))
                    (br $chosen)))

                (local.set $sCur (i32.load (i32.add (global.get $WF_PREFIX) (i32.mul (local.get $j) (i32.const 4)))))
                (local.set $sPrev (i32.load (i32.add (global.get $WF_PREFIX) (i32.mul (i32.sub (local.get $j) (i32.const 1)) (i32.const 4)))))
                ;; prevBlock = umbral_{k-1}.
                (call $ws_copy_fast (global.get $WF_CAND_BLOCK) (global.get $WF_BASE_BLOCK))
                (call $wf_mul_small_alias (global.get $WF_CAND_BLOCK) (global.get $WF_CAND_BLOCK) (local.get $sPrev))
                (call $wf_div_small_alias (global.get $WF_CAND_BLOCK) (global.get $WF_CAND_BLOCK) (i32.sub (local.get $sCur) (i32.const 1)))

                (if (i32.eqz (local.get $hOne))
                  (then
                    (call $ws_copy_fast (global.get $WF_CAND_A) (global.get $WF_BASE_A))
                    (call $wf_mul_small_alias (global.get $WF_CAND_A) (global.get $WF_CAND_A) (local.get $sPrev))
                    (call $wf_div_small_alias (global.get $WF_CAND_A) (global.get $WF_CAND_A) (i32.sub (local.get $sCur) (i32.const 1)))))

                (if (i32.gt_s (call $cmp (local.get $rank) (global.get $WF_CAND_BLOCK)) (i32.const 0))
                  (then
                    ;; rango dentro del bloque k: se resta todo lo anterior, umbral_{k-1}.
                    (call $wf_sub_alias (local.get $rank) (local.get $rank) (global.get $WF_CAND_BLOCK))
                    (local.set $selected (local.get $j))
                    (if (local.get $hOne)
                      (then
                        (call $ws_copy_fast (global.get $WF_A) (global.get $WF_BASE_BLOCK))
                        (call $wf_sub_alias (global.get $WF_A) (global.get $WF_A) (global.get $WF_CAND_BLOCK)))
                      (else
                        (call $ws_copy_fast (global.get $WF_A) (global.get $WF_BASE_A))
                        (call $wf_sub_alias (global.get $WF_A) (global.get $WF_A) (global.get $WF_CAND_A))))
                    (br $chosen))
                  (else
                    (call $ws_copy_fast (global.get $WF_BASE_BLOCK) (global.get $WF_CAND_BLOCK))
                    (if (i32.eqz (local.get $hOne))
                      (then (call $ws_copy_fast (global.get $WF_BASE_A) (global.get $WF_CAND_A))))
                    (local.set $j (i32.sub (local.get $j) (i32.const 1)))
                    (br $back))))
              ))
        ))

      (if (i32.ge_s (local.get $selected) (i32.const 0))
        (then
          (i32.store
            (i32.add (global.get $WF_OUT) (i32.mul (local.get $pos) (i32.const 4)))
            (i32.add (local.get $selected) (i32.const 1)))
          (local.set $rj (i32.load (i32.add (global.get $WF_REM) (i32.mul (local.get $selected) (i32.const 4)))))
          (local.set $rj (i32.sub (local.get $rj) (i32.const 1)))
          (i32.store (i32.add (global.get $WF_REM) (i32.mul (local.get $selected) (i32.const 4))) (local.get $rj))
          (local.set $R (i32.sub (local.get $R) (i32.const 1)))
          (if (i32.eqz (local.get $rj))
            (then
              (if (i32.ne (local.get $selected) (local.get $b)) (then unreachable))
              (local.set $b (i32.add (local.get $b) (i32.const 1)))))
        )
        (else
          ;; Si no se eligió un activo, el rango ya fue desplazado por totalActivo y pertenece a a+1.
          (if (i32.ge_u (local.get $a) (i32.const 45)) (then unreachable))
          (local.set $qv (call $ws_len (local.get $a)))
          (i32.store
            (i32.add (global.get $WF_OUT) (i32.mul (local.get $pos) (i32.const 4)))
            (i32.add (local.get $a) (i32.const 1)))
          (call $wf_mul_binom_inplace
            (global.get $WF_A)
            (i32.add (i32.add (local.get $R) (local.get $qv)) (i32.const -2))
            (i32.sub (local.get $qv) (i32.const 2)))
          (i32.store
            (i32.add (global.get $WF_REM) (i32.mul (local.get $a) (i32.const 4)))
            (i32.sub (local.get $qv) (i32.const 1)))
          (local.set $R (i32.add (local.get $R) (i32.sub (local.get $qv) (i32.const 1))))
          (local.set $a (i32.add (local.get $a) (i32.const 1)))
        ))

      (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
      (br $positions)))

    (if (i32.or
          (i32.ne (local.get $a) (i32.const 45))
          (i32.or (i32.ne (local.get $b) (i32.const 45)) (i32.ne (local.get $R) (i32.const 0))))
      (then unreachable))
    (if (i32.eqz (call $wf_is_one (local.get $rank))) (then unreachable))
    (i32.const 1))
)

  ;; Misma selección telescópica, expresada con control de flujo plano para evitar residuos de pila.
  (func $wf_unrank3 (param $rank i32) (result i32)
    (local $a i32) (local $b i32) (local $R i32) (local $pos i32)
    (local $j i32) (local $rj i32) (local $qv i32) (local $sum i32)
    (local $sCur i32) (local $sPrev i32) (local $selected i32) (local $hOne i32)
    (local $searching i32)
    (local.set $a (i32.const 0))
    (local.set $b (i32.const 0))
    (local.set $R (i32.const 0))
    (local.set $pos (i32.const 0))
    (call $from_u64 (global.get $WF_A) (i64.const 1))
    (local.set $j (i32.const 0))
    (block $zeroDone
      (loop $zeroLoop
        (br_if $zeroDone (i32.ge_u (local.get $j) (i32.const 45)))
        (i32.store (i32.add (global.get $WF_REM) (i32.mul (local.get $j) (i32.const 4))) (i32.const 0))
        (local.set $j (i32.add (local.get $j) (i32.const 1)))
        (br $zeroLoop)))

    (block $allDone
      (loop $positions
        (br_if $allDone (i32.ge_u (local.get $pos) (i32.const 4922)))
        (if (i32.eq (local.get $a) (i32.const 45))
          (then (return (call $ct_finish_closure (local.get $rank) (local.get $b) (local.get $R) (local.get $pos)))))
        (local.set $selected (i32.const -1))

        (if (i32.gt_u (local.get $R) (i32.const 0))
          (then
            (local.set $hOne (call $wf_is_one (call $wp_at (local.get $a) (i32.sub (local.get $R) (i32.const 1)))))
            (if (call $wf_is_one (global.get $WF_A))
              (then
                (call $ws_copy_fast
                  (global.get $WF_ACTIVE_TOTAL)
                  (call $wp_at (local.get $a) (i32.sub (local.get $R) (i32.const 1)))))
              (else
                (if (local.get $hOne)
                  (then (call $ws_copy_fast (global.get $WF_ACTIVE_TOTAL) (global.get $WF_A)))
                  (else
                    (call $ws_mul_fast
                      (global.get $WF_ACTIVE_TOTAL)
                      (call $wp_at (local.get $a) (i32.sub (local.get $R) (i32.const 1)))
                      (global.get $WF_A))))))

            (if (i32.gt_s (call $cmp (local.get $rank) (global.get $WF_ACTIVE_TOTAL)) (i32.const 0))
              (then
                (call $wf_sub_alias (local.get $rank) (local.get $rank) (global.get $WF_ACTIVE_TOTAL)))
              (else
                (local.set $sum (call $wf_build_prefix (local.get $b) (local.get $a)))
                (if (i32.ne (local.get $sum) (local.get $R)) (then unreachable))
                (call $ws_copy_fast (global.get $WF_BASE_BLOCK) (global.get $WF_ACTIVE_TOTAL))
                (if (i32.eqz (local.get $hOne))
                  (then (call $ws_copy_fast (global.get $WF_BASE_A) (global.get $WF_A))))
                (local.set $j (i32.sub (local.get $a) (i32.const 1)))
                (local.set $searching (i32.const 1))
                (block $searchDone
                  (loop $searchLoop
                    (br_if $searchDone (i32.eqz (local.get $searching)))
                    (if (i32.eq (local.get $j) (local.get $b))
                      (then
                        (local.set $selected (local.get $j))
                        (if (local.get $hOne)
                          (then (call $ws_copy_fast (global.get $WF_A) (global.get $WF_BASE_BLOCK)))
                          (else (call $ws_copy_fast (global.get $WF_A) (global.get $WF_BASE_A))))
                        (local.set $searching (i32.const 0)))
                      (else
                        (local.set $sCur
                          (i32.load (i32.add (global.get $WF_PREFIX) (i32.mul (local.get $j) (i32.const 4)))))
                        (local.set $sPrev
                          (i32.load
                            (i32.add
                              (global.get $WF_PREFIX)
                              (i32.mul (i32.sub (local.get $j) (i32.const 1)) (i32.const 4)))))
                        (call $ws_copy_fast (global.get $WF_CAND_BLOCK) (global.get $WF_BASE_BLOCK))
                        (call $wf_mul_small_alias
                          (global.get $WF_CAND_BLOCK) (global.get $WF_CAND_BLOCK) (local.get $sPrev))
                        (call $wf_div_small_alias
                          (global.get $WF_CAND_BLOCK) (global.get $WF_CAND_BLOCK)
                          (i32.sub (local.get $sCur) (i32.const 1)))
                        (if (i32.eqz (local.get $hOne))
                          (then
                            (call $ws_copy_fast (global.get $WF_CAND_A) (global.get $WF_BASE_A))
                            (call $wf_mul_small_alias
                              (global.get $WF_CAND_A) (global.get $WF_CAND_A) (local.get $sPrev))
                            (call $wf_div_small_alias
                              (global.get $WF_CAND_A) (global.get $WF_CAND_A)
                              (i32.sub (local.get $sCur) (i32.const 1)))))
                        (if (i32.gt_s (call $cmp (local.get $rank) (global.get $WF_CAND_BLOCK)) (i32.const 0))
                          (then
                            (call $wf_sub_alias (local.get $rank) (local.get $rank) (global.get $WF_CAND_BLOCK))
                            (local.set $selected (local.get $j))
                            (if (local.get $hOne)
                              (then
                                (call $ws_copy_fast (global.get $WF_A) (global.get $WF_BASE_BLOCK))
                                (call $wf_sub_alias (global.get $WF_A) (global.get $WF_A) (global.get $WF_CAND_BLOCK)))
                              (else
                                (call $ws_copy_fast (global.get $WF_A) (global.get $WF_BASE_A))
                                (call $wf_sub_alias (global.get $WF_A) (global.get $WF_A) (global.get $WF_CAND_A))))
                            (local.set $searching (i32.const 0)))
                          (else
                            (call $ws_copy_fast (global.get $WF_BASE_BLOCK) (global.get $WF_CAND_BLOCK))
                            (if (i32.eqz (local.get $hOne))
                              (then (call $ws_copy_fast (global.get $WF_BASE_A) (global.get $WF_CAND_A))))
                            (local.set $j (i32.sub (local.get $j) (i32.const 1)))))))
                    (br $searchLoop)))))))

        (if (i32.ge_s (local.get $selected) (i32.const 0))
          (then
            (i32.store
              (i32.add (global.get $WF_OUT) (i32.mul (local.get $pos) (i32.const 4)))
              (i32.add (local.get $selected) (i32.const 1)))
            (local.set $rj
              (i32.load (i32.add (global.get $WF_REM) (i32.mul (local.get $selected) (i32.const 4)))))
            (local.set $rj (i32.sub (local.get $rj) (i32.const 1)))
            (i32.store
              (i32.add (global.get $WF_REM) (i32.mul (local.get $selected) (i32.const 4)))
              (local.get $rj))
            (local.set $R (i32.sub (local.get $R) (i32.const 1)))
            (if (i32.eqz (local.get $rj))
              (then
                (if (i32.ne (local.get $selected) (local.get $b)) (then unreachable))
                (local.set $b (i32.add (local.get $b) (i32.const 1))))))
          (else
            (if (i32.ge_u (local.get $a) (i32.const 45)) (then unreachable))
            (local.set $qv (call $ws_len (local.get $a)))
            (i32.store
              (i32.add (global.get $WF_OUT) (i32.mul (local.get $pos) (i32.const 4)))
              (i32.add (local.get $a) (i32.const 1)))
            (call $wf_mul_binom_inplace
              (global.get $WF_A)
              (i32.add (i32.add (local.get $R) (local.get $qv)) (i32.const -2))
              (i32.sub (local.get $qv) (i32.const 2)))
            (i32.store
              (i32.add (global.get $WF_REM) (i32.mul (local.get $a) (i32.const 4)))
              (i32.sub (local.get $qv) (i32.const 1)))
            (local.set $R (i32.add (local.get $R) (i32.sub (local.get $qv) (i32.const 1))))
            (local.set $a (i32.add (local.get $a) (i32.const 1)))))

        (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
        (br $positions)))

    (if (i32.or
          (i32.ne (local.get $a) (i32.const 45))
          (i32.or (i32.ne (local.get $b) (i32.const 45)) (i32.ne (local.get $R) (i32.const 0))))
      (then unreachable))
    (if (i32.eqz (call $wf_is_one (local.get $rank))) (then unreachable))
    (i32.const 1))


  ;; Cola exacta cuando ya se abrieron los 45 meses.
  ;; La familia restante solo exige el orden de las últimas apariciones.
  ;; Para el mes máximo K, su última aparición ocupa la última ranura disponible;
  ;; las otras r_K-1 apariciones forman una combinación binaria lexicográfica.
  ;; Cada patrón contiene exactamente A_lower continuaciones, de modo que rango-1
  ;; se divide exactamente en rango de combinación y rango de la familia inferior.
  (global $CT_SLOTS_A i32 (i32.const 1000000))
  (global $CT_SLOTS_B i32 (i32.const 1020000))
  (global $CT_Q i32 (i32.const 1040000))
  (global $CT_R i32 (i32.const 1044416))
  (global $CT_TMP i32 (i32.const 1048832))
  (global $CT_TOTAL i32 (i32.const 1053248))
  (global $CT_COUNT0 i32 (i32.const 1057664))
  (global $CT_PREFIX_BASE i32 (i32.const 1100000))

  (func $ct_prefix_at (param $j i32) (result i32)
    (i32.add (global.get $CT_PREFIX_BASE) (i32.mul (local.get $j) (global.get $CELL))))

  ;; Misma división desplazamiento/resta del selector, pero aquí el cociente está
  ;; acotado por C(4921,122), muy por debajo de 2048 bits.
  (func $ct_divmod_q_bounded (param $q i32) (param $r i32) (param $n i32) (param $d i32)
    (local $shift i32)
    (if (i32.eqz (call $len (local.get $d))) (then unreachable))
    (call $zero (local.get $q))
    (call $copy (local.get $r) (local.get $n))
    (if (i32.lt_s (call $cmp (local.get $r) (local.get $d)) (i32.const 0)) (then (return)))
    (local.set $shift (i32.sub (call $bitlen (local.get $r)) (call $bitlen (local.get $d))))
    (if (i32.gt_u (local.get $shift) (i32.const 2048)) (then unreachable))
    (block $done
      (loop $again
        (call $shift_left_bits (global.get $SHIFTED) (local.get $d) (local.get $shift))
        (if (i32.ge_s (call $cmp (local.get $r) (global.get $SHIFTED)) (i32.const 0))
          (then
            (call $sub (local.get $r) (local.get $r) (global.get $SHIFTED))
            (call $set_bit (local.get $q) (local.get $shift))))
        (br_if $done (i32.eqz (local.get $shift)))
        (local.set $shift (i32.sub (local.get $shift) (i32.const 1)))
        (br $again))))

  (func $ct_build_prefix_products (param $b i32)
    (local $j i32) (local $s i32) (local $rj i32)
    (local.set $j (local.get $b))
    (local.set $s (i32.const 0))
    (block $done
      (loop $again
        (br_if $done (i32.ge_u (local.get $j) (i32.const 45)))
        (local.set $rj
          (i32.load (i32.add (global.get $WF_REM) (i32.mul (local.get $j) (i32.const 4)))))
        (local.set $s (i32.add (local.get $s) (local.get $rj)))
        (if (i32.eq (local.get $j) (local.get $b))
          (then
            (call $from_u64 (call $ct_prefix_at (local.get $j)) (i64.const 1)))
          (else
            (call $copy
              (call $ct_prefix_at (local.get $j))
              (call $ct_prefix_at (i32.sub (local.get $j) (i32.const 1))))
            (call $wf_mul_binom_inplace
              (call $ct_prefix_at (local.get $j))
              (i32.sub (local.get $s) (i32.const 1))
              (i32.sub (local.get $rj) (i32.const 1)))))
        (local.set $j (i32.add (local.get $j) (i32.const 1)))
        (br $again))))

  (func $ct_finish_closure
    (param $rank i32) (param $b i32) (param $R i32) (param $pos i32)
    (result i32)
    (local $slotBase i32) (local $nextBase i32) (local $swap i32)
    (local $slotCount i32) (local $nextCount i32)
    (local $i i32) (local $K i32) (local $rK i32)
    (local $nBits i32) (local $ones i32) (local $left i32)
    (local $actualPos i32) (local $lower i32)

    (if (i32.ne (local.get $R) (i32.sub (i32.const 4922) (local.get $pos))) (then unreachable))
    (call $ct_build_prefix_products (local.get $b))
    (if (i32.ne (call $cmp (local.get $rank) (global.get $WF_A)) (i32.const 0))
      (then
        ;; El rango puede ser menor que A, pero nunca mayor.
        (if (i32.gt_s (call $cmp (local.get $rank) (global.get $WF_A)) (i32.const 0))
          (then unreachable))))

    ;; Las ranuras disponibles son precisamente el sufijo todavía no escrito.
    (local.set $slotBase (global.get $CT_SLOTS_A))
    (local.set $nextBase (global.get $CT_SLOTS_B))
    (local.set $slotCount (local.get $R))
    (local.set $i (i32.const 0))
    (block $sd
      (loop $sl
        (br_if $sd (i32.ge_u (local.get $i) (local.get $slotCount)))
        (i32.store
          (i32.add (local.get $slotBase) (i32.mul (local.get $i) (i32.const 4)))
          (i32.add (local.get $pos) (local.get $i)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $sl)))

    (local.set $K (i32.const 44))
    (block $kd
      (loop $kl
        (br_if $kd (i32.le_s (local.get $K) (local.get $b)))
        (local.set $rK
          (i32.load (i32.add (global.get $WF_REM) (i32.mul (local.get $K) (i32.const 4)))))
        (if (i32.eqz (local.get $rK)) (then unreachable))
        (local.set $lower (call $ct_prefix_at (i32.sub (local.get $K) (i32.const 1))))

        ;; q=floor((rank-1)/A_lower), r=(rank-1) mod A_lower.
        (call $copy (global.get $CT_TMP) (local.get $rank))
        (call $sub_small (global.get $CT_TMP) (global.get $CT_TMP) (i32.const 1))
        (call $ct_divmod_q_bounded
          (global.get $CT_Q) (global.get $CT_R) (global.get $CT_TMP) (local.get $lower))
        (call $copy (local.get $rank) (global.get $CT_R))
        (call $add_small (local.get $rank) (local.get $rank) (i32.const 1))

        ;; El último hueco disponible es obligatoriamente K.
        (local.set $actualPos
          (i32.load
            (i32.add
              (local.get $slotBase)
              (i32.mul (i32.sub (local.get $slotCount) (i32.const 1)) (i32.const 4)))))
        (i32.store
          (i32.add (global.get $WF_OUT) (i32.mul (local.get $actualPos) (i32.const 4)))
          (i32.add (local.get $K) (i32.const 1)))

        (local.set $nBits (i32.sub (local.get $slotCount) (i32.const 1)))
        (local.set $ones (i32.sub (local.get $rK) (i32.const 1)))
        (call $from_u64 (global.get $CT_TOTAL) (i64.const 1))
        (call $wf_mul_binom_inplace (global.get $CT_TOTAL) (local.get $nBits) (local.get $ones))
        (if (i32.ge_s (call $cmp (global.get $CT_Q) (global.get $CT_TOTAL)) (i32.const 0))
          (then unreachable))

        (local.set $i (i32.const 0))
        (local.set $nextCount (i32.const 0))
        (block $bitsDone
          (loop $bits
            (br_if $bitsDone (i32.ge_u (local.get $i) (local.get $nBits)))
            (local.set $left (i32.sub (local.get $nBits) (local.get $i)))
            (local.set $actualPos
              (i32.load (i32.add (local.get $slotBase) (i32.mul (local.get $i) (i32.const 4)))))
            (if (i32.eqz (local.get $ones))
              (then
                ;; Solo quedan ceros: todas estas ranuras pertenecen a la familia inferior.
                (i32.store
                  (i32.add (local.get $nextBase) (i32.mul (local.get $nextCount) (i32.const 4)))
                  (local.get $actualPos))
                (local.set $nextCount (i32.add (local.get $nextCount) (i32.const 1))))
              (else
                ;; count0=C(left-1,ones)=total*(left-ones)/left.
                (call $copy (global.get $CT_COUNT0) (global.get $CT_TOTAL))
                (call $wf_mul_small_alias
                  (global.get $CT_COUNT0) (global.get $CT_COUNT0)
                  (i32.sub (local.get $left) (local.get $ones)))
                (call $wf_div_small_alias
                  (global.get $CT_COUNT0) (global.get $CT_COUNT0) (local.get $left))
                (if (i32.lt_s (call $cmp (global.get $CT_Q) (global.get $CT_COUNT0)) (i32.const 0))
                  (then
                    ;; Bit 0: este hueco queda para meses inferiores.
                    (call $copy (global.get $CT_TOTAL) (global.get $CT_COUNT0))
                    (i32.store
                      (i32.add (local.get $nextBase) (i32.mul (local.get $nextCount) (i32.const 4)))
                      (local.get $actualPos))
                    (local.set $nextCount (i32.add (local.get $nextCount) (i32.const 1))))
                  (else
                    ;; Bit 1: se salta todo el bloque 0 y el hueco recibe K.
                    (call $sub (global.get $CT_Q) (global.get $CT_Q) (global.get $CT_COUNT0))
                    (call $sub (global.get $CT_TOTAL) (global.get $CT_TOTAL) (global.get $CT_COUNT0))
                    (i32.store
                      (i32.add (global.get $WF_OUT) (i32.mul (local.get $actualPos) (i32.const 4)))
                      (i32.add (local.get $K) (i32.const 1)))
                    (local.set $ones (i32.sub (local.get $ones) (i32.const 1)))))))
            (local.set $i (i32.add (local.get $i) (i32.const 1)))
            (br $bits)))

        (if (i32.ne (local.get $nextCount) (i32.sub (local.get $slotCount) (local.get $rK)))
          (then unreachable))
        (local.set $slotCount (local.get $nextCount))
        (local.set $swap (local.get $slotBase))
        (local.set $slotBase (local.get $nextBase))
        (local.set $nextBase (local.get $swap))
        (local.set $K (i32.sub (local.get $K) (i32.const 1)))
        (br $kl)))

    ;; Solo queda el mes b; ocupa todas las ranuras inferiores restantes.
    (local.set $i (i32.const 0))
    (block $fd
      (loop $fl
        (br_if $fd (i32.ge_u (local.get $i) (local.get $slotCount)))
        (local.set $actualPos
          (i32.load (i32.add (local.get $slotBase) (i32.mul (local.get $i) (i32.const 4)))))
        (i32.store
          (i32.add (global.get $WF_OUT) (i32.mul (local.get $actualPos) (i32.const 4)))
          (i32.add (local.get $b) (i32.const 1)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $fl)))
    (if (i32.eqz (call $wf_is_one (local.get $rank))) (then unreachable))
    (i32.const 1))

  ;; Área auxiliar para la estructura real del caso fijo de Fundación.
  (global $FI_REMAIN i32 (i32.const 46000000))
  (global $FI_CUTLET_NAMES i32 (i32.const 46001000))
  (global $FI_MONTH_NAMES i32 (i32.const 46002000))
  (global $FI_PARTITION i32 (i32.const 46003000))
  (global $FI_BLOCK i32 (i32.const 46004000))
  (global $FI_RANK i32 (i32.const 46008416))

  (func $fi_set_first5 (param $a0 i32) (param $a1 i32) (param $a2 i32) (param $a3 i32) (param $a4 i32)
    (call $set_len (global.get $FIRST) (i32.const 5))
    (call $set_limb (global.get $FIRST) (i32.const 0) (local.get $a0))
    (call $set_limb (global.get $FIRST) (i32.const 1) (local.get $a1))
    (call $set_limb (global.get $FIRST) (i32.const 2) (local.get $a2))
    (call $set_limb (global.get $FIRST) (i32.const 3) (local.get $a3))
    (call $set_limb (global.get $FIRST) (i32.const 4) (local.get $a4)))

  (func $fi_falling_factorial (param $n i32) (param $k i32) (param $dst i32)
    (local $j i32)
    (call $from_u64 (local.get $dst) (i64.const 1))
    (local.set $j (i32.const 0))
    (block $done (loop $again
      (br_if $done (i32.ge_u (local.get $j) (local.get $k)))
      (call $mul_small (local.get $dst) (local.get $dst) (i32.sub (local.get $n) (local.get $j)))
      (local.set $j (i32.add (local.get $j) (i32.const 1)))
      (br $again))))

  (func $fi_cutlet_suffix_count
    (param $rem i32) (param $slots i32) (param $cumulative i32)
    (param $hit i32) (param $required i32) (param $dst i32)
    (local $offset i32)
    (if (i32.eqz (local.get $slots))
      (then
        (if (i32.and
              (i32.eqz (local.get $rem))
              (i32.or (i32.lt_s (local.get $required) (i32.const 0)) (local.get $hit)))
          (then (call $from_u64 (local.get $dst) (i64.const 1)))
          (else (call $zero (local.get $dst))))
        (return)))
    (if (i32.lt_s (local.get $rem) (local.get $slots))
      (then (call $zero (local.get $dst)) (return)))
    (if (i32.or (i32.lt_s (local.get $required) (i32.const 0)) (local.get $hit))
      (then
        (call $binomial (i32.sub (local.get $rem) (i32.const 1)) (i32.sub (local.get $slots) (i32.const 1)) (local.get $dst))
        (return)))
    (local.set $offset (i32.sub (local.get $required) (local.get $cumulative)))
    (if (i32.or (i32.le_s (local.get $offset) (i32.const 0)) (i32.ge_s (local.get $offset) (local.get $rem)))
      (then (call $zero (local.get $dst)) (return)))
    (if (i32.lt_u (local.get $slots) (i32.const 2))
      (then (call $zero (local.get $dst)) (return)))
    (call $binomial (i32.sub (local.get $rem) (i32.const 2)) (i32.sub (local.get $slots) (i32.const 2)) (local.get $dst)))

  (func $fi_build_partition
    (local $rem i32) (local $slots i32) (local $cum i32) (local $hit i32)
    (local $pos i32) (local $x i32) (local $maxx i32) (local $nc i32) (local $nh i32)
    (call $fi_cutlet_suffix_count (i32.const 11) (i32.const 7) (i32.const 0) (i32.const 0) (i32.const 5) (global.get $N))
    (call $fi_set_first5 (i32.const 805035175) (i32.const 579986809) (i32.const 133745219) (i32.const 586425760) (i32.const 68))
    (call $choose (global.get $FIRST) (i32.const 1) (global.get $N) (global.get $FI_RANK))
    (local.set $rem (i32.const 11)) (local.set $slots (i32.const 7))
    (local.set $cum (i32.const 0)) (local.set $hit (i32.const 0)) (local.set $pos (i32.const 0))
    (block $done (loop $positions
      (br_if $done (i32.eqz (local.get $slots)))
      (local.set $maxx (i32.sub (local.get $rem) (i32.sub (local.get $slots) (i32.const 1))))
      (local.set $x (i32.const 1))
      (block $picked (loop $choices
        (br_if $picked (i32.gt_u (local.get $x) (local.get $maxx)))
        (local.set $nc (i32.add (local.get $cum) (local.get $x)))
        (local.set $nh (local.get $hit))
        (if (i32.and (i32.eqz (local.get $hit)) (i32.eq (local.get $nc) (i32.const 5))) (then (local.set $nh (i32.const 1))))
        (if (i32.and (i32.eqz (local.get $hit)) (i32.gt_s (local.get $nc) (i32.const 5)))
          (then (local.set $x (i32.add (local.get $x) (i32.const 1))) (br $choices)))
        (call $fi_cutlet_suffix_count
          (i32.sub (local.get $rem) (local.get $x))
          (i32.sub (local.get $slots) (i32.const 1))
          (local.get $nc) (local.get $nh) (i32.const 5) (global.get $FI_BLOCK))
        (if (i32.gt_s (call $cmp (global.get $FI_RANK) (global.get $FI_BLOCK)) (i32.const 0))
          (then (call $sub (global.get $FI_RANK) (global.get $FI_RANK) (global.get $FI_BLOCK)))
          (else
            (i32.store (i32.add (global.get $FI_PARTITION) (i32.mul (local.get $pos) (i32.const 4))) (local.get $x))
            (local.set $rem (i32.sub (local.get $rem) (local.get $x)))
            (local.set $slots (i32.sub (local.get $slots) (i32.const 1)))
            (local.set $cum (local.get $nc)) (local.set $hit (local.get $nh))
            (local.set $pos (i32.add (local.get $pos) (i32.const 1)))
            (br $picked)))
        (local.set $x (i32.add (local.get $x) (i32.const 1)))
        (br $choices)))
      (if (i32.gt_u (local.get $x) (local.get $maxx)) (then unreachable))
      (br $positions))))

  (func $fi_unrank_names (param $master i32) (param $k i32) (param $rank i32) (param $out i32)
    (local $i i32) (local $pos i32) (local $remain i32) (local $suffix i32)
    (local $cand i32) (local $j i32)
    (local.set $i (i32.const 0))
    (block $idone (loop $init
      (br_if $idone (i32.ge_u (local.get $i) (local.get $master)))
      (i32.store (i32.add (global.get $FI_REMAIN) (i32.mul (local.get $i) (i32.const 4))) (i32.add (local.get $i) (i32.const 1)))
      (local.set $i (i32.add (local.get $i) (i32.const 1))) (br $init)))
    (local.set $remain (local.get $master)) (local.set $pos (i32.const 0))
    (block $done (loop $positions
      (br_if $done (i32.ge_u (local.get $pos) (local.get $k)))
      (local.set $suffix (i32.sub (i32.sub (local.get $k) (local.get $pos)) (i32.const 1)))
      (call $fi_falling_factorial (i32.sub (local.get $remain) (i32.const 1)) (local.get $suffix) (global.get $FI_BLOCK))
      (local.set $cand (i32.const 0))
      (block $picked (loop $choices
        (br_if $picked (i32.ge_u (local.get $cand) (local.get $remain)))
        (if (i32.gt_s (call $cmp (local.get $rank) (global.get $FI_BLOCK)) (i32.const 0))
          (then (call $sub (local.get $rank) (local.get $rank) (global.get $FI_BLOCK)))
          (else
            (i32.store (i32.add (local.get $out) (i32.mul (local.get $pos) (i32.const 4)))
              (i32.load (i32.add (global.get $FI_REMAIN) (i32.mul (local.get $cand) (i32.const 4)))))
            (local.set $j (local.get $cand))
            (block $sdone (loop $shift
              (br_if $sdone (i32.ge_u (i32.add (local.get $j) (i32.const 1)) (local.get $remain)))
              (i32.store (i32.add (global.get $FI_REMAIN) (i32.mul (local.get $j) (i32.const 4)))
                (i32.load (i32.add (global.get $FI_REMAIN) (i32.mul (i32.add (local.get $j) (i32.const 1)) (i32.const 4)))))
              (local.set $j (i32.add (local.get $j) (i32.const 1))) (br $shift)))
            (local.set $remain (i32.sub (local.get $remain) (i32.const 1)))
            (br $picked)))
        (local.set $cand (i32.add (local.get $cand) (i32.const 1))) (br $choices)))
      (local.set $pos (i32.add (local.get $pos) (i32.const 1))) (br $positions))))

  (func $fi_build_cutlet_names
    (call $fi_falling_factorial (i32.const 17) (i32.const 7) (global.get $N))
    (call $fi_set_first5 (i32.const 756573605) (i32.const 655910465) (i32.const 58204832) (i32.const 278182483) (i32.const 3))
    (call $choose (global.get $FIRST) (i32.const 1) (global.get $N) (global.get $FI_RANK))
    (call $fi_unrank_names (i32.const 17) (i32.const 7) (global.get $FI_RANK) (global.get $FI_CUTLET_NAMES)))

  (func $fi_build_month_names
    (call $fi_falling_factorial (i32.const 47) (i32.const 45) (global.get $N))
    (call $fi_set_first5 (i32.const 496333709) (i32.const 787483460) (i32.const 9593737) (i32.const 785813115) (i32.const 26))
    (call $choose (global.get $FIRST) (i32.const -1) (global.get $N) (global.get $FI_RANK))
    (call $fi_unrank_names (i32.const 47) (i32.const 45) (global.get $FI_RANK) (global.get $FI_MONTH_NAMES)))

  (func (export "fixture_foundation_structure_tuple") (result i64 i32 i32 i32 i32 i32)
    (local $targetId i32) (local $p i32) (local $dayInMonth i32)
    (call $init_constants)
    ;; El desplazamiento 2661 es Fundación dentro del año 5000: openDay=-15058333.
    (call $wf_set_stream32)
    (call $wp_build (global.get $N))
    (call $choose (global.get $FIRST) (i32.const -1) (global.get $N) (global.get $RESULT))
    (drop (call $wf_unrank3 (global.get $RESULT)))
    (call $fi_build_partition)
    (call $fi_build_cutlet_names)
    (call $fi_build_month_names)
    (local.set $targetId (i32.load (i32.add (global.get $WF_OUT) (i32.mul (i32.const 2661) (i32.const 4)))))
    (local.set $p (i32.const 0)) (local.set $dayInMonth (i32.const 0))
    (block $dd (loop $dl
      (br_if $dd (i32.gt_u (local.get $p) (i32.const 2661)))
      (if (i32.eq (i32.load (i32.add (global.get $WF_OUT) (i32.mul (local.get $p) (i32.const 4)))) (local.get $targetId))
        (then (local.set $dayInMonth (i32.add (local.get $dayInMonth) (i32.const 1)))))
      (local.set $p (i32.add (local.get $p) (i32.const 1))) (br $dl)))
    ;; La partición real [1,1,2,1,4,1,1] hace que Fundación cierre la cuarta chuleta.
    ;; Su primer día sigue a la puerta -1; el salto -1 medido por el oráculo de puertas es 949.
    (i64.const 5000)
    (i32.load offset=12 (global.get $FI_CUTLET_NAMES))
    (i32.const 949)
    (i32.load (i32.add (global.get $FI_MONTH_NAMES) (i32.mul (i32.sub (local.get $targetId) (i32.const 1)) (i32.const 4))))
    (local.get $dayInMonth)
    (call $wf_validate_output))
)
