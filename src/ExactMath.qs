namespace Pastafari.ExactMath {
    import Std.Convert.IntAsBigInt;
    import Std.Convert.BigIntAsInt;

    function BI(value : Int) : BigInt {
        return IntAsBigInt(value);
    }

    function M() : BigInt {
        return (1L <<< 127) - 1L;
    }

    function RegularMod(value : BigInt, divisor : BigInt) : BigInt {
        if divisor < 1L {
            fail "除数は正でなければなりません。";
        }
        mutable r = value % divisor;
        if r < 0L {
            r += divisor;
        }
        return r;
    }

    function FloorDiv(value : BigInt, divisor : BigInt) : BigInt {
        if divisor < 1L {
            fail "除数は正でなければなりません。";
        }
        let q = value / divisor;
        let r = value % divisor;
        if value < 0L and r != 0L {
            return q - 1L;
        }
        return q;
    }

    function CeilDivNonNegative(value : BigInt, divisor : BigInt) : BigInt {
        if value < 0L or divisor < 1L {
            fail "切り上げ除算の引数が不正です。";
        }
        return FloorDiv(value + divisor - 1L, divisor);
    }

    function Save(value : BigInt) : BigInt {
        return 1L + RegularMod(value - 1L, M());
    }

    function AbsL(value : BigInt) : BigInt {
        if value < 0L {
            return -value;
        }
        return value;
    }

    function MinI(a : Int, b : Int) : Int {
        if a < b { return a; }
        return b;
    }

    function MaxI(a : Int, b : Int) : Int {
        if a > b { return a; }
        return b;
    }

    function MinL(a : BigInt, b : BigInt) : BigInt {
        if a < b { return a; }
        return b;
    }

    function MaxL(a : BigInt, b : BigInt) : BigInt {
        if a > b { return a; }
        return b;
    }

    function Wrap1(position : Int, size : Int) : Int {
        if size < 1 {
            fail "循環サイズは正でなければなりません。";
        }
        mutable r = (position - 1) % size;
        if r < 0 { r += size; }
        return r + 1;
    }

    function Factorial(n : Int) : BigInt {
        if n < 0 {
            fail "階乗の引数は負にできません。";
        }
        mutable out = 1L;
        for i in 2..n {
            out *= BI(i);
        }
        return out;
    }

    function FallingFactorial(n : Int, k : Int) : BigInt {
        if k < 0 or n < k {
            fail "下降階乗の引数が不正です。";
        }
        mutable out = 1L;
        for j in 0..k-1 {
            out *= BI(n - j);
        }
        return out;
    }

    function ToIntExact(value : BigInt) : Int {
        return BigIntAsInt(value);
    }
}
