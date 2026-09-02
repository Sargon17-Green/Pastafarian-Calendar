package testoracle

import "math/big"

type AnswerStream struct {
	First *big.Int
	Step  int
}

func AskBowl(r SauceResult, queried, seal int) AnswerStream {
	pos := -1
	for i, id := range r.OrderAtDrop46 {
		if id == queried {
			pos = i
			break
		}
	}
	if pos < 0 {
		panic("E_QUERY_BOWL")
	}
	nextID := r.OrderAtDrop46[(pos+1)%6]
	firstBase := Add(Add(r.Bowls[queried-1], BI(int64(seal))), BI(181))
	first := Save(Add(Add(Square(firstBase), Mul(BI(179), r.Bowls[nextID-1])), BI(int64(seal))))
	dirBase := Add(Add(Add(first, BI(int64(seal))), BI(1)), BI(193))
	dn := Save(Add(Add(Square(dirBase), Mul(BI(193), first)), Mul(BI(197), r.Bowls[5])))
	step := -1
	if Mod(dn, BI(2)).Cmp(BI(1)) == 0 {
		step = 1
	}
	return AnswerStream{first, step}
}

func AnswerAt(s AnswerStream, k *big.Int) *big.Int {
	delta := Mul(BI(int64(s.Step)), k)
	return Add(Mod(Add(Sub(s.First, BI(1)), delta), M), BI(1))
}

func ChooseRank(s AnswerStream, N *big.Int) *big.Int {
	if N.Sign() <= 0 {
		panic("E_PICK_N")
	}
	if N.Cmp(M) <= 0 {
		return chooseShort(s, N)
	}
	return chooseWide(s, N)
}

func chooseShort(s AnswerStream, N *big.Int) *big.Int {
	limit := Mul(FloorDiv(M, N), N)
	k := BI(0)
	for {
		x := AnswerAt(s, k)
		if x.Cmp(limit) <= 0 {
			return Add(Mod(Sub(x, BI(1)), N), BI(1))
		}
		k = Add(k, BI(1))
	}
}

func chooseWide(s AnswerStream, N *big.Int) *big.Int {
	places := 1
	space := C(M)
	for space.Cmp(N) < 0 {
		places++
		space = Mul(space, M)
	}
	wide := BI(1)
	weight := BI(1)
	for j := 0; j < places; j++ {
		digit := Sub(AnswerAt(s, BI(int64(j))), BI(1))
		wide = Add(wide, Mul(digit, weight))
		weight = Mul(weight, M)
	}
	limit := Mul(FloorDiv(space, N), N)
	for wide.Cmp(limit) > 0 {
		wide = Add(Mod(Add(Sub(wide, BI(1)), BI(int64(s.Step))), space), BI(1))
	}
	return Add(Mod(Sub(wide, BI(1)), N), BI(1))
}
