import std/strutils

type
  BigInt* = object
    sign*: int8
    limbs*: seq[uint32]

const
  LimbBits = 30
  LimbBase = 1'u64 shl LimbBits
  LimbMask = LimbBase - 1'u64

proc normalize(a: var BigInt) =
  while a.limbs.len > 0 and a.limbs[^1] == 0'u32:
    a.limbs.setLen(a.limbs.len - 1)
  if a.limbs.len == 0:
    a.sign = 0

proc zeroBigInt*(): BigInt =
  BigInt(sign: 0, limbs: @[])

proc oneBigInt*(): BigInt =
  BigInt(sign: 1, limbs: @[1'u32])

proc initBigInt*(x: int64): BigInt =
  if x == 0:
    return zeroBigInt()
  result.sign = if x < 0: -1 else: 1
  var magnitude: uint64
  if x < 0:
    magnitude = uint64(-(x + 1)) + 1'u64
  else:
    magnitude = uint64(x)
  while magnitude != 0'u64:
    result.limbs.add(uint32(magnitude and LimbMask))
    magnitude = magnitude shr LimbBits
  result.normalize()

proc initBigInt*(x: int): BigInt =
  initBigInt(int64(x))

proc initBigIntUnsigned*(x: uint64): BigInt =
  if x == 0'u64:
    return zeroBigInt()
  result.sign = 1
  var magnitude = x
  while magnitude != 0'u64:
    result.limbs.add(uint32(magnitude and LimbMask))
    magnitude = magnitude shr LimbBits
  result.normalize()

proc isZero*(a: BigInt): bool =
  a.sign == 0

proc absBigInt*(a: BigInt): BigInt =
  result = a
  if result.sign < 0:
    result.sign = 1

proc cmpAbs(a, b: BigInt): int =
  if a.limbs.len < b.limbs.len:
    return -1
  if a.limbs.len > b.limbs.len:
    return 1
  if a.limbs.len == 0:
    return 0
  for i in countdown(a.limbs.len - 1, 0):
    if a.limbs[i] < b.limbs[i]:
      return -1
    if a.limbs[i] > b.limbs[i]:
      return 1
  0

proc cmp*(a, b: BigInt): int =
  if a.sign < b.sign:
    return -1
  if a.sign > b.sign:
    return 1
  if a.sign == 0:
    return 0
  let c = cmpAbs(a, b)
  if a.sign > 0: c else: -c

proc `==`*(a, b: BigInt): bool =
  cmp(a, b) == 0

proc `<`*(a, b: BigInt): bool = cmp(a, b) < 0
proc `<=`*(a, b: BigInt): bool = cmp(a, b) <= 0
proc `>`*(a, b: BigInt): bool = cmp(a, b) > 0
proc `>=`*(a, b: BigInt): bool = cmp(a, b) >= 0

proc addAbs(a, b: BigInt): BigInt =
  let n = max(a.limbs.len, b.limbs.len)
  result.sign = 1
  result.limbs = newSeq[uint32](n)
  var carry = 0'u64
  for i in 0..<n:
    let av = if i < a.limbs.len: uint64(a.limbs[i]) else: 0'u64
    let bv = if i < b.limbs.len: uint64(b.limbs[i]) else: 0'u64
    let total = av + bv + carry
    result.limbs[i] = uint32(total and LimbMask)
    carry = total shr LimbBits
  if carry != 0'u64:
    result.limbs.add(uint32(carry))
  result.normalize()

proc subAbs(a, b: BigInt): BigInt =
  result.sign = 1
  result.limbs = newSeq[uint32](a.limbs.len)
  var borrow = 0'i64
  for i in 0..<a.limbs.len:
    let av = int64(a.limbs[i])
    let bv = if i < b.limbs.len: int64(b.limbs[i]) else: 0'i64
    var value = av - bv - borrow
    if value < 0:
      value += int64(LimbBase)
      borrow = 1
    else:
      borrow = 0
    result.limbs[i] = uint32(value)
  result.normalize()

proc `-`*(a: BigInt): BigInt =
  result = a
  result.sign = -result.sign

proc `+`*(a, b: BigInt): BigInt =
  if a.sign == 0:
    return b
  if b.sign == 0:
    return a
  if a.sign == b.sign:
    result = addAbs(a, b)
    result.sign = a.sign
    return
  let c = cmpAbs(a, b)
  if c == 0:
    return zeroBigInt()
  if c > 0:
    result = subAbs(a, b)
    result.sign = a.sign
  else:
    result = subAbs(b, a)
    result.sign = b.sign
  result.normalize()

proc `-`*(a, b: BigInt): BigInt =
  a + (-b)

proc `*`*(a, b: BigInt): BigInt =
  if a.sign == 0 or b.sign == 0:
    return zeroBigInt()
  result.sign = a.sign * b.sign
  result.limbs = newSeq[uint32](a.limbs.len + b.limbs.len + 1)
  for i in 0..<a.limbs.len:
    var carry = 0'u64
    for j in 0..<b.limbs.len:
      let idx = i + j
      let total = uint64(result.limbs[idx]) +
                  uint64(a.limbs[i]) * uint64(b.limbs[j]) + carry
      result.limbs[idx] = uint32(total and LimbMask)
      carry = total shr LimbBits
    var idx = i + b.limbs.len
    while carry != 0'u64:
      let total = uint64(result.limbs[idx]) + carry
      result.limbs[idx] = uint32(total and LimbMask)
      carry = total shr LimbBits
      inc idx
  result.normalize()

proc `+`*(a: BigInt, b: int): BigInt = a + initBigInt(b)
proc `+`*(a: int, b: BigInt): BigInt = initBigInt(a) + b
proc `-`*(a: BigInt, b: int): BigInt = a - initBigInt(b)
proc `-`*(a: int, b: BigInt): BigInt = initBigInt(a) - b
proc `*`*(a: BigInt, b: int): BigInt = a * initBigInt(b)
proc `*`*(a: int, b: BigInt): BigInt = initBigInt(a) * b
proc `+`*(a: BigInt, b: int64): BigInt = a + initBigInt(b)
proc `-`*(a: BigInt, b: int64): BigInt = a - initBigInt(b)
proc `*`*(a: BigInt, b: int64): BigInt = a * initBigInt(b)

proc shl1(a: var BigInt) =
  if a.sign == 0:
    return
  var carry = 0'u64
  for i in 0..<a.limbs.len:
    let total = uint64(a.limbs[i]) * 2'u64 + carry
    a.limbs[i] = uint32(total and LimbMask)
    carry = total shr LimbBits
  if carry != 0'u64:
    a.limbs.add(uint32(carry))

proc addOneAbs(a: var BigInt) =
  if a.sign == 0:
    a.sign = 1
    a.limbs = @[1'u32]
    return
  var carry = 1'u64
  var i = 0
  while carry != 0'u64 and i < a.limbs.len:
    let total = uint64(a.limbs[i]) + carry
    a.limbs[i] = uint32(total and LimbMask)
    carry = total shr LimbBits
    inc i
  if carry != 0'u64:
    a.limbs.add(uint32(carry))

proc bitLengthAbs(a: BigInt): int =
  if a.sign == 0:
    return 0
  var top = a.limbs[^1]
  var bits = 0
  while top != 0'u32:
    inc bits
    top = top shr 1
  (a.limbs.len - 1) * LimbBits + bits

proc bitAtAbs(a: BigInt, bitIndex: int): bool =
  if bitIndex < 0:
    return false
  let limbIndex = bitIndex div LimbBits
  let bitInLimb = bitIndex mod LimbBits
  if limbIndex >= a.limbs.len:
    return false
  ((a.limbs[limbIndex] shr bitInLimb) and 1'u32) == 1'u32

proc setBitAbs(a: var BigInt, bitIndex: int) =
  let limbIndex = bitIndex div LimbBits
  let bitInLimb = bitIndex mod LimbBits
  if a.limbs.len <= limbIndex:
    a.limbs.setLen(limbIndex + 1)
  a.limbs[limbIndex] = a.limbs[limbIndex] or (1'u32 shl bitInLimb)
  a.sign = 1

proc divModAbs(a, b: BigInt): tuple[q, r: BigInt] =
  if b.sign == 0:
    raise newException(DivByZeroDefect, "E_BIGINT_DIV_ZERO")
  let aa = absBigInt(a)
  let bb = absBigInt(b)
  if cmpAbs(aa, bb) < 0:
    return (zeroBigInt(), aa)
  var q = zeroBigInt()
  var r = zeroBigInt()
  let bits = bitLengthAbs(aa)
  for bitIndex in countdown(bits - 1, 0):
    r.shl1()
    if bitAtAbs(aa, bitIndex):
      r.addOneAbs()
    if cmpAbs(r, bb) >= 0:
      r = subAbs(r, bb)
      q.setBitAbs(bitIndex)
  q.normalize()
  r.normalize()
  (q, r)

proc floorDiv*(a, b: BigInt): BigInt =
  if b.sign <= 0:
    raise newException(ValueError, "E_BIGINT_FLOORDIV_DIVISOR")
  if a.sign == 0:
    return zeroBigInt()
  let (qAbs, rAbs) = divModAbs(absBigInt(a), b)
  if a.sign > 0:
    return qAbs
  if rAbs.isZero:
    return -qAbs
  -(qAbs + oneBigInt())

proc regularMod*(a, d: BigInt): BigInt =
  if d.sign <= 0:
    raise newException(ValueError, "E_BIGINT_MOD_DIVISOR")
  if a.sign == 0:
    return zeroBigInt()
  let (_, rAbs) = divModAbs(absBigInt(a), d)
  if a.sign > 0 or rAbs.isZero:
    return rAbs
  d - rAbs

proc regularMod*(a: BigInt, d: int): BigInt =
  regularMod(a, initBigInt(d))

proc floorDiv*(a: BigInt, b: int): BigInt =
  floorDiv(a, initBigInt(b))

proc powBigInt*(base: BigInt, exponent: int): BigInt =
  if exponent < 0:
    raise newException(ValueError, "E_BIGINT_NEGATIVE_EXPONENT")
  var e = exponent
  var factor = base
  result = oneBigInt()
  while e > 0:
    if (e and 1) == 1:
      result = result * factor
    e = e shr 1
    if e > 0:
      factor = factor * factor

proc pow2BigInt*(exponent: int): BigInt =
  if exponent < 0:
    raise newException(ValueError, "E_BIGINT_NEGATIVE_EXPONENT")
  if exponent == 0:
    return oneBigInt()
  result.sign = 1
  let limbIndex = exponent div LimbBits
  let bitInLimb = exponent mod LimbBits
  result.limbs = newSeq[uint32](limbIndex + 1)
  result.limbs[limbIndex] = 1'u32 shl bitInLimb
  result.normalize()

proc toInt64*(a: BigInt): int64 =
  if a.sign == 0:
    return 0
  var magnitude = 0'u64
  if a.limbs.len > 3:
    raise newException(OverflowDefect, "E_BIGINT_TO_INT64")
  for i in countdown(a.limbs.len - 1, 0):
    if magnitude > (high(uint64) shr LimbBits):
      raise newException(OverflowDefect, "E_BIGINT_TO_INT64")
    magnitude = (magnitude shl LimbBits) + uint64(a.limbs[i])
  if a.sign > 0:
    if magnitude > uint64(high(int64)):
      raise newException(OverflowDefect, "E_BIGINT_TO_INT64")
    return int64(magnitude)
  let negativeLimit = uint64(high(int64)) + 1'u64
  if magnitude > negativeLimit:
    raise newException(OverflowDefect, "E_BIGINT_TO_INT64")
  if magnitude == negativeLimit:
    return low(int64)
  -int64(magnitude)

proc toInt*(a: BigInt): int =
  let v = a.toInt64()
  if v < int64(low(int)) or v > int64(high(int)):
    raise newException(OverflowDefect, "E_BIGINT_TO_INT")
  int(v)

proc divModSmallAbs(a: BigInt, d: uint32): tuple[q: BigInt, r: uint32] =
  if d == 0'u32:
    raise newException(DivByZeroDefect, "E_BIGINT_DIV_ZERO")
  if a.sign == 0:
    return (zeroBigInt(), 0'u32)
  result.q.sign = 1
  result.q.limbs = newSeq[uint32](a.limbs.len)
  var rem = 0'u64
  for i in countdown(a.limbs.len - 1, 0):
    let cur = rem * LimbBase + uint64(a.limbs[i])
    result.q.limbs[i] = uint32(cur div uint64(d))
    rem = cur mod uint64(d)
  result.q.normalize()
  result.r = uint32(rem)

proc `$`*(a: BigInt): string =
  if a.sign == 0:
    return "0"
  var work = absBigInt(a)
  var chunks: seq[uint32] = @[]
  const DecimalBase = 1_000_000_000'u32
  while not work.isZero:
    let (q, r) = divModSmallAbs(work, DecimalBase)
    chunks.add(r)
    work = q
  result = if a.sign < 0: "-" else: ""
  result.add($chunks[^1])
  if chunks.len >= 2:
    for i in countdown(chunks.len - 2, 0):
      result.add(align($chunks[i], 9, '0'))

proc parseBigInt*(s: string): BigInt =
  let text = s.strip()
  if text.len == 0:
    raise newException(ValueError, "E_BIGINT_PARSE")
  var i = 0
  var negative = false
  if text[0] == '-':
    negative = true
    i = 1
  elif text[0] == '+':
    i = 1
  if i >= text.len:
    raise newException(ValueError, "E_BIGINT_PARSE")
  result = zeroBigInt()
  while i < text.len:
    let ch = text[i]
    if ch < '0' or ch > '9':
      raise newException(ValueError, "E_BIGINT_PARSE")
    result = result * 10 + (ord(ch) - ord('0'))
    inc i
  if negative and not result.isZero:
    result.sign = -1

proc absDiff*(a, b: BigInt): BigInt =
  absBigInt(a - b)

proc `<`*(a: BigInt, b: int): bool = a < initBigInt(b)
proc `<=`*(a: BigInt, b: int): bool = a <= initBigInt(b)
proc `>`*(a: BigInt, b: int): bool = a > initBigInt(b)
proc `>=`*(a: BigInt, b: int): bool = a >= initBigInt(b)
proc `==`*(a: BigInt, b: int): bool = a == initBigInt(b)
proc `<`*(a: int, b: BigInt): bool = initBigInt(a) < b
proc `<=`*(a: int, b: BigInt): bool = initBigInt(a) <= b
proc `>`*(a: int, b: BigInt): bool = initBigInt(a) > b
proc `>=`*(a: int, b: BigInt): bool = initBigInt(a) >= b
proc `==`*(a: int, b: BigInt): bool = initBigInt(a) == b

proc `<`*(a: BigInt, b: int64): bool = a < initBigInt(b)
proc `<=`*(a: BigInt, b: int64): bool = a <= initBigInt(b)
proc `>`*(a: BigInt, b: int64): bool = a > initBigInt(b)
proc `>=`*(a: BigInt, b: int64): bool = a >= initBigInt(b)
proc `==`*(a: BigInt, b: int64): bool = a == initBigInt(b)
