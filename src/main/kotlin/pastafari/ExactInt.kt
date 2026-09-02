package pastafari

class ExactInt private constructor(
    private val signum: Int,
    private val limbs: IntArray
) : Comparable<ExactInt> {
    companion object {
        private const val BASE = 1_000_000_000
        val ZERO = ExactInt(0, IntArray(0))
        val ONE = ExactInt(1, intArrayOf(1))

        fun of(value: Long): ExactInt {
            if (value == 0L) return ZERO
            if (value == Long.MIN_VALUE) return parse(value.toString())
            val s = if (value < 0) -1 else 1
            var x = if (value < 0) -value else value
            val out = ArrayList<Int>()
            while (x != 0L) {
                out.add((x % BASE).toInt())
                x /= BASE
            }
            return normalized(s, out.toIntArray())
        }

        fun parse(text: String): ExactInt {
            require(text.isNotEmpty()) { "E_EXACTINT_PARSE_EMPTY" }
            var p = 0
            var s = 1
            if (text[0] == '-') {
                s = -1
                p++
            } else if (text[0] == '+') {
                p++
            }
            require(p < text.length) { "E_EXACTINT_PARSE_SIGN" }
            var r = ZERO
            while (p < text.length) {
                val c = text[p]
                require(c in '0'..'9') { "E_EXACTINT_PARSE_DIGIT" }
                r = r.multiplyByInt(10) + of((c - '0').toLong())
                p++
            }
            return if (s < 0) -r else r
        }

        private fun normalized(sign: Int, raw: IntArray): ExactInt {
            var n = raw.size
            while (n > 0 && raw[n - 1] == 0) n--
            if (n == 0) return ZERO
            val copy = if (n == raw.size) raw.copyOf() else raw.copyOf(n)
            return ExactInt(if (sign < 0) -1 else 1, copy)
        }

        private fun compareMagnitude(a: IntArray, b: IntArray): Int {
            var asz = a.size
            var bsz = b.size
            while (asz > 0 && a[asz - 1] == 0) asz--
            while (bsz > 0 && b[bsz - 1] == 0) bsz--
            if (asz != bsz) return asz.compareTo(bsz)
            for (i in asz - 1 downTo 0) {
                if (a[i] != b[i]) return a[i].compareTo(b[i])
            }
            return 0
        }

        private fun addMagnitude(a: IntArray, b: IntArray): IntArray {
            val n = maxOf(a.size, b.size)
            val out = IntArray(n + 1)
            var carry = 0L
            for (i in 0 until n) {
                val av = if (i < a.size) a[i].toLong() else 0L
                val bv = if (i < b.size) b[i].toLong() else 0L
                val sum = av + bv + carry
                out[i] = (sum % BASE).toInt()
                carry = sum / BASE
            }
            out[n] = carry.toInt()
            return out
        }

        private fun subtractMagnitude(a: IntArray, b: IntArray): IntArray {
            val out = IntArray(a.size)
            var borrow = 0L
            for (i in a.indices) {
                val av = a[i].toLong()
                val bv = if (i < b.size) b[i].toLong() else 0L
                var v = av - bv - borrow
                if (v < 0) {
                    v += BASE.toLong()
                    borrow = 1
                } else {
                    borrow = 0
                }
                out[i] = v.toInt()
            }
            require(borrow == 0L) { "E_EXACTINT_SUB_MAG" }
            return out
        }

        private fun multiplyMagnitudeByInt(a: IntArray, m: Int): IntArray {
            if (m == 0 || a.isEmpty()) return IntArray(0)
            val out = IntArray(a.size + 1)
            var carry = 0L
            for (i in a.indices) {
                val cur = a[i].toLong() * m.toLong() + carry
                out[i] = (cur % BASE).toInt()
                carry = cur / BASE
            }
            out[a.size] = carry.toInt()
            return out
        }

        private fun shiftBaseAndAdd(a: IntArray, limb: Int): IntArray {
            if (a.isEmpty() && limb == 0) return IntArray(0)
            val out = IntArray(a.size + 1)
            out[0] = limb
            for (i in a.indices) out[i + 1] = a[i]
            return out
        }
    }

    fun sign(): Int = signum
    fun isZero(): Boolean = signum == 0
    fun abs(): ExactInt = if (signum >= 0) this else -this

    operator fun unaryMinus(): ExactInt = when (signum) {
        0 -> this
        1 -> ExactInt(-1, limbs.copyOf())
        else -> ExactInt(1, limbs.copyOf())
    }

    operator fun plus(other: ExactInt): ExactInt {
        if (signum == 0) return other
        if (other.signum == 0) return this
        if (signum == other.signum) {
            return normalized(signum, addMagnitude(limbs, other.limbs))
        }
        val cmp = compareMagnitude(limbs, other.limbs)
        return when {
            cmp == 0 -> ZERO
            cmp > 0 -> normalized(signum, subtractMagnitude(limbs, other.limbs))
            else -> normalized(other.signum, subtractMagnitude(other.limbs, limbs))
        }
    }

    operator fun minus(other: ExactInt): ExactInt = this + (-other)

    operator fun times(other: ExactInt): ExactInt {
        if (isZero() || other.isZero()) return ZERO
        val out = IntArray(limbs.size + other.limbs.size + 1)
        for (i in limbs.indices) {
            var carry = 0L
            for (j in other.limbs.indices) {
                val idx = i + j
                val cur = out[idx].toLong() + limbs[i].toLong() * other.limbs[j].toLong() + carry
                out[idx] = (cur % BASE).toInt()
                carry = cur / BASE
            }
            var idx = i + other.limbs.size
            while (carry != 0L) {
                val cur = out[idx].toLong() + carry
                out[idx] = (cur % BASE).toInt()
                carry = cur / BASE
                idx++
            }
        }
        return normalized(signum * other.signum, out)
    }

    fun square(): ExactInt = this * this

    fun multiplyByInt(value: Int): ExactInt {
        if (value == Int.MIN_VALUE) return this * of(value.toLong())
        if (value == 0 || isZero()) return ZERO
        val s = if (value < 0) -signum else signum
        val m = kotlin.math.abs(value)
        return normalized(s, multiplyMagnitudeByInt(limbs, m))
    }

    fun divRem(other: ExactInt): Pair<ExactInt, ExactInt> {
        require(!other.isZero()) { "E_EXACTINT_DIV_ZERO" }
        if (isZero()) return ZERO to ZERO
        val a = abs()
        val b = other.abs()
        if (a < b) return ZERO to this
        if (b == ONE) {
            val q = if (signum == other.signum) a else -a
            return q to ZERO
        }

        val qRaw = IntArray(a.limbs.size)
        var remMag = IntArray(0)
        for (i in a.limbs.indices.reversed()) {
            remMag = shiftBaseAndAdd(remMag, a.limbs[i])
            var lo = 0
            var hi = BASE - 1
            var best = 0
            while (lo <= hi) {
                val mid = lo + (hi - lo) / 2
                val prod = multiplyMagnitudeByInt(b.limbs, mid)
                val cmp = compareMagnitude(prod, remMag)
                if (cmp <= 0) {
                    best = mid
                    lo = mid + 1
                } else {
                    hi = mid - 1
                }
            }
            qRaw[i] = best
            if (best != 0) {
                remMag = subtractMagnitude(remMag, multiplyMagnitudeByInt(b.limbs, best))
                var n = remMag.size
                while (n > 0 && remMag[n - 1] == 0) n--
                if (n != remMag.size) remMag = remMag.copyOf(n)
            }
        }
        val q = normalized(if (signum == other.signum) 1 else -1, qRaw)
        val r = normalized(signum, remMag)
        return q to r
    }

    operator fun div(other: ExactInt): ExactInt = divRem(other).first
    operator fun rem(other: ExactInt): ExactInt = divRem(other).second

    fun euclideanMod(modulus: ExactInt): ExactInt {
        require(modulus > ZERO) { "E_EXACTINT_MODULUS" }
        val r = this % modulus
        return if (r.signum < 0) r + modulus else r
    }

    fun modInt(modulus: Int): Int {
        require(modulus > 0) { "E_EXACTINT_MOD_INT" }
        var rem = 0L
        for (i in limbs.indices.reversed()) {
            rem = (rem * BASE + limbs[i]) % modulus
        }
        val r = rem.toInt()
        return if (signum >= 0 || r == 0) r else modulus - r
    }

    fun toIntExact(): Int {
        val v = toLongExact()
        require(v in Int.MIN_VALUE.toLong()..Int.MAX_VALUE.toLong()) { "E_EXACTINT_TO_INT" }
        return v.toInt()
    }

    fun toLongExact(): Long {
        if (isZero()) return 0L
        var v = 0L
        for (i in limbs.indices.reversed()) {
            require(v <= (Long.MAX_VALUE - limbs[i]) / BASE) { "E_EXACTINT_TO_LONG" }
            v = v * BASE + limbs[i]
        }
        return if (signum < 0) -v else v
    }

    override fun compareTo(other: ExactInt): Int {
        if (signum != other.signum) return signum.compareTo(other.signum)
        if (signum == 0) return 0
        val cmp = compareMagnitude(limbs, other.limbs)
        return if (signum > 0) cmp else -cmp
    }

    override fun equals(other: Any?): Boolean {
        if (other !is ExactInt) return false
        return signum == other.signum && limbs.contentEquals(other.limbs)
    }

    override fun hashCode(): Int = 31 * signum + limbs.contentHashCode()

    override fun toString(): String {
        if (signum == 0) return "0"
        val sb = StringBuilder()
        if (signum < 0) sb.append('-')
        sb.append(limbs.last())
        for (i in limbs.size - 2 downTo 0) {
            sb.append(limbs[i].toString().padStart(9, '0'))
        }
        return sb.toString()
    }
}

operator fun ExactInt.plus(value: Long): ExactInt = this + ExactInt.of(value)
operator fun ExactInt.minus(value: Long): ExactInt = this - ExactInt.of(value)
operator fun ExactInt.times(value: Long): ExactInt = this * ExactInt.of(value)
operator fun Long.plus(value: ExactInt): ExactInt = ExactInt.of(this) + value
operator fun Long.minus(value: ExactInt): ExactInt = ExactInt.of(this) - value
operator fun Long.times(value: ExactInt): ExactInt = ExactInt.of(this) * value
