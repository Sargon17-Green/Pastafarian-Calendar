package pastafari.math;

class BigInt {
    private var negative:Bool;
    private var digits:Array<Int>;

    private function new(negative:Bool, digits:Array<Int>) {
        this.negative = negative;
        this.digits = digits;
        normalize();
    }

    public static function zero():BigInt {
        return new BigInt(false, [0]);
    }

    public static function one():BigInt {
        return new BigInt(false, [1]);
    }

    public static function fromInt(value:Int):BigInt {
        return fromString(Std.string(value));
    }

    public static function fromString(value:String):BigInt {
        if (value == null || value.length == 0) {
            throw "Ogiltigt heltal";
        }
        var start = 0;
        var neg = false;
        var first = value.charAt(0);
        if (first == "-") {
            neg = true;
            start = 1;
        } else if (first == "+") {
            start = 1;
        }
        if (start >= value.length) {
            throw "Ogiltigt heltal";
        }
        var out = new Array<Int>();
        var i = value.length - 1;
        while (i >= start) {
            var c = value.charCodeAt(i);
            if (c < 48 || c > 57) {
                throw "Ogiltigt heltal";
            }
            out.push(c - 48);
            i--;
        }
        return new BigInt(neg, out);
    }

    public function copy():BigInt {
        return new BigInt(negative, digits.copy());
    }

    public function isZero():Bool {
        return digits.length == 1 && digits[0] == 0;
    }

    public function isNegative():Bool {
        return negative && !isZero();
    }

    public function abs():BigInt {
        return new BigInt(false, digits.copy());
    }

    public function negated():BigInt {
        if (isZero()) return zero();
        return new BigInt(!negative, digits.copy());
    }

    public function toString():String {
        var b = new StringBuf();
        if (isNegative()) b.add("-");
        var i = digits.length - 1;
        while (i >= 0) {
            b.addChar(48 + digits[i]);
            i--;
        }
        return b.toString();
    }

    public function toIntExact():Int {
        var s = toString();
        var v = Std.parseInt(s);
        if (v == null || Std.string(v) != s) {
            throw "Heltalet ryms inte i Int";
        }
        return v;
    }

    private function normalize():Void {
        while (digits.length > 1 && digits[digits.length - 1] == 0) {
            digits.pop();
        }
        if (digits.length == 0) digits.push(0);
        if (digits.length == 1 && digits[0] == 0) negative = false;
    }

    public static function compare(a:BigInt, b:BigInt):Int {
        if (a.isNegative() && !b.isNegative()) return -1;
        if (!a.isNegative() && b.isNegative()) return 1;
        var c = compareAbs(a, b);
        return a.isNegative() ? -c : c;
    }

    public static function compareAbs(a:BigInt, b:BigInt):Int {
        if (a.digits.length < b.digits.length) return -1;
        if (a.digits.length > b.digits.length) return 1;
        var i = a.digits.length - 1;
        while (i >= 0) {
            if (a.digits[i] < b.digits[i]) return -1;
            if (a.digits[i] > b.digits[i]) return 1;
            i--;
        }
        return 0;
    }

    public static function add(a:BigInt, b:BigInt):BigInt {
        if (a.isNegative() == b.isNegative()) {
            return new BigInt(a.isNegative(), addAbsDigits(a.digits, b.digits));
        }
        var cmp = compareAbs(a, b);
        if (cmp == 0) return zero();
        if (cmp > 0) return new BigInt(a.isNegative(), subAbsDigits(a.digits, b.digits));
        return new BigInt(b.isNegative(), subAbsDigits(b.digits, a.digits));
    }

    public static function sub(a:BigInt, b:BigInt):BigInt {
        return add(a, b.negated());
    }

    private static function div10Small(value:Int):Int {
        var q = 0;
        var r = value;
        while (r >= 10) {
            r -= 10;
            q++;
        }
        return q;
    }

    private static function halfSmall(value:Int):Int {
        return value >> 1;
    }

    private static function addAbsDigits(a:Array<Int>, b:Array<Int>):Array<Int> {
        var n = a.length > b.length ? a.length : b.length;
        var out = new Array<Int>();
        var carry = 0;
        var i = 0;
        while (i < n) {
            var x = i < a.length ? a[i] : 0;
            var y = i < b.length ? b[i] : 0;
            var s = x + y + carry;
            out.push(s % 10);
            carry = div10Small(s);
            i++;
        }
        if (carry != 0) out.push(carry);
        return out;
    }

    private static function subAbsDigits(a:Array<Int>, b:Array<Int>):Array<Int> {
        var out = new Array<Int>();
        var borrow = 0;
        var i = 0;
        while (i < a.length) {
            var x = a[i] - borrow;
            var y = i < b.length ? b[i] : 0;
            if (x < y) {
                x += 10;
                borrow = 1;
            } else {
                borrow = 0;
            }
            out.push(x - y);
            i++;
        }
        return out;
    }

    public static function mul(a:BigInt, b:BigInt):BigInt {
        if (a.isZero() || b.isZero()) return zero();
        var result = new Array<Int>();
        var size = a.digits.length + b.digits.length + 1;
        var z = 0;
        while (z < size) {
            result.push(0);
            z++;
        }
        var i = 0;
        while (i < a.digits.length) {
            var carry = 0;
            var j = 0;
            while (j < b.digits.length) {
                var pos = i + j;
                var v = result[pos] + a.digits[i] * b.digits[j] + carry;
                result[pos] = v % 10;
                carry = div10Small(v);
                j++;
            }
            var pos2 = i + b.digits.length;
            while (carry > 0) {
                var v2 = result[pos2] + carry;
                result[pos2] = v2 % 10;
                carry = div10Small(v2);
                pos2++;
            }
            i++;
        }
        return new BigInt(a.isNegative() != b.isNegative(), result);
    }

    public static function mulInt(a:BigInt, b:Int):BigInt {
        return mul(a, fromInt(b));
    }

    public static function square(a:BigInt):BigInt {
        return mul(a, a);
    }

    public static function absDiff(a:BigInt, b:BigInt):BigInt {
        var d = sub(a, b);
        return d.isNegative() ? d.negated() : d;
    }

    public static function min(a:BigInt, b:BigInt):BigInt {
        return compare(a, b) <= 0 ? a.copy() : b.copy();
    }

    public static function max(a:BigInt, b:BigInt):BigInt {
        return compare(a, b) >= 0 ? a.copy() : b.copy();
    }

    private static function mulAbsByDigit(a:BigInt, digit:Int):BigInt {
        if (digit < 0 || digit > 9) throw "Ogiltig decimalsiffra";
        if (digit == 0 || a.isZero()) return zero();
        var out = new Array<Int>();
        var carry = 0;
        var i = 0;
        while (i < a.digits.length) {
            var v = a.digits[i] * digit + carry;
            out.push(v % 10);
            carry = div10Small(v);
            i++;
        }
        while (carry > 0) {
            out.push(carry % 10);
            carry = div10Small(carry);
        }
        return new BigInt(false, out);
    }

    private static function shiftDecimalAndAddDigit(a:BigInt, digit:Int):BigInt {
        if (digit < 0 || digit > 9) throw "Ogiltig decimalsiffra";
        if (a.isZero()) return new BigInt(false, [digit]);
        var out = a.digits.copy();
        out.unshift(digit);
        return new BigInt(false, out);
    }

    private static function divModAbs(a:BigInt, b:BigInt):{q:BigInt, r:BigInt} {
        if (b.isZero()) throw "Division med noll";
        var aa = a.abs();
        var bb = b.abs();
        if (compareAbs(aa, bb) < 0) return {q: zero(), r: aa};
        var quotientBigEndian = new Array<Int>();
        var rem = zero();
        var i = aa.digits.length - 1;
        while (i >= 0) {
            rem = shiftDecimalAndAddDigit(rem, aa.digits[i]);
            var lo = 0;
            var hi = 9;
            var best = 0;
            while (lo <= hi) {
                var mid = halfSmall(lo + hi);
                var probe = mulAbsByDigit(bb, mid);
                if (compareAbs(probe, rem) <= 0) {
                    best = mid;
                    lo = mid + 1;
                } else {
                    hi = mid - 1;
                }
            }
            quotientBigEndian.push(best);
            if (best != 0) rem = sub(rem, mulAbsByDigit(bb, best));
            i--;
        }
        while (quotientBigEndian.length > 1 && quotientBigEndian[0] == 0) {
            quotientBigEndian.shift();
        }
        quotientBigEndian.reverse();
        return {q: new BigInt(false, quotientBigEndian), r: rem};
    }

    public static function floorDiv(a:BigInt, b:BigInt):BigInt {
        if (b.isZero()) throw "Division med noll";
        if (b.isNegative()) return floorDiv(a.negated(), b.negated());
        var dm = divModAbs(a, b);
        if (!a.isNegative()) return dm.q;
        if (dm.r.isZero()) return dm.q.negated();
        return add(dm.q, one()).negated();
    }

    public static function modEuclid(a:BigInt, d:BigInt):BigInt {
        if (d.isZero() || d.isNegative()) throw "Modulen måste vara positiv";
        var dm = divModAbs(a, d);
        if (!a.isNegative() || dm.r.isZero()) return dm.r;
        return sub(d, dm.r);
    }

    public static function pow(base:BigInt, exponent:Int):BigInt {
        if (exponent < 0) throw "Negativ exponent stöds inte";
        var r = one();
        var b = base.copy();
        var e = exponent;
        while (e > 0) {
            if ((e & 1) == 1) r = mul(r, b);
            e = e >> 1;
            if (e > 0) b = mul(b, b);
        }
        return r;
    }
}
