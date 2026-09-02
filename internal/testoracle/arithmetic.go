package testoracle

import "math/big"

var M = func() *big.Int {
	x := new(big.Int).Lsh(big.NewInt(1), 127)
	return x.Sub(x, big.NewInt(1))
}()

var TabletsDay = big.NewInt(-278522)
var FoundationDay = big.NewInt(-15055671)

func BI(x int64) *big.Int             { return big.NewInt(x) }
func C(x *big.Int) *big.Int           { return new(big.Int).Set(x) }
func Add(a, b *big.Int) *big.Int      { return new(big.Int).Add(a, b) }
func Sub(a, b *big.Int) *big.Int      { return new(big.Int).Sub(a, b) }
func Mul(a, b *big.Int) *big.Int      { return new(big.Int).Mul(a, b) }
func Abs(a *big.Int) *big.Int         { return new(big.Int).Abs(a) }
func Square(a *big.Int) *big.Int      { return Mul(a, a) }
func Mod(a, d *big.Int) *big.Int      { return new(big.Int).Mod(a, d) }
func FloorDiv(a, b *big.Int) *big.Int { return new(big.Int).Div(a, b) }

func Save(x *big.Int) *big.Int {
	v := Sub(x, BI(1))
	v.Mod(v, M)
	return v.Add(v, BI(1))
}

func CeilDivNonNegative(a, b *big.Int) *big.Int {
	return FloorDiv(Add(a, Sub(b, BI(1))), b)
}

func Wrap1(position, size int) int {
	r := (position - 1) % size
	if r < 0 {
		r += size
	}
	return r + 1
}

func cmpInt(a *big.Int, b int64) int { return a.Cmp(BI(b)) }
