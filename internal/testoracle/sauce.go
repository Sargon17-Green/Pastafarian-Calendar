package testoracle

import "math/big"

type Stone [5]*big.Int
type Bowls [6]*big.Int

type SauceResult struct {
	Bowls         Bowls
	OrderAtDrop46 [6]int
}

var stoneTable = buildStones()

func cloneStone(s Stone) Stone {
	var o Stone
	for i := range s {
		o[i] = C(s[i])
	}
	return o
}

func buildStones() [46]Stone {
	var table [46]Stone
	table[0] = Stone{BI(17), BI(29), BI(43), BI(71), BI(101)}
	for n := 2; n <= 46; n++ {
		o := table[n-2]
		var z Stone
		z[0] = Save(Add(Add(Square(o[0]), Mul(BI(3), o[1])), BI(int64(n))))
		z[1] = Save(Add(Add(Square(o[1]), Mul(BI(5), o[2])), o[0]))
		z[2] = Save(Add(Add(Square(o[2]), Mul(BI(7), o[3])), o[1]))
		z[3] = Save(Add(Add(Square(o[3]), Mul(BI(11), o[4])), o[2]))
		z[4] = Save(Add(Add(Square(o[4]), Mul(BI(13), o[0])), o[3]))
		table[n-1] = z
	}
	return table
}

var hiddenCoeff = [7][4]int64{
	{3, 4, 6, 8}, {5, 7, 10, 12}, {7, 10, 14, 16}, {9, 13, 18, 20},
	{11, 16, 22, 24}, {13, 19, 26, 28}, {15, 22, 30, 32},
}

var hiddenKinds = [7]int{0, 1, 2, 3, 4, 0, 1}

func buildHidden(counts WorkCounts) [7]*big.Int {
	var h [7]*big.Int
	for k := 0; k < 7; k++ {
		cf := hiddenCoeff[k]
		x := C(counts.Action)
		x = Add(x, Mul(BI(cf[0]), counts.Target))
		x = Add(x, Mul(BI(cf[1]), counts.Distance))
		x = Add(x, Mul(BI(cf[2]), counts.Connection))
		x = Add(x, Mul(BI(cf[3]), BI(int64(counts.Direction))))
		for j := 0; j < 5; j++ {
			x = Add(x, stoneTable[k][j])
		}
		x = Save(x)
		for g := 1; g <= 7; g++ {
			o := C(x)
			x = Save(Add(Add(Add(Square(o), Mul(BI(3), o)), stoneTable[k][hiddenKinds[g-1]]), BI(int64(g))))
		}
		h[k] = x
	}
	return h
}

var visibleGrinds = [11][5]int64{
	{3, 5, 7, 11, 0}, {5, 7, 11, 13, 1}, {7, 11, 13, 17, 2}, {11, 13, 17, 19, 3},
	{13, 17, 19, 23, 4}, {17, 19, 23, 29, 0}, {19, 23, 29, 31, 1}, {23, 29, 31, 37, 2},
	{29, 31, 37, 41, 3}, {31, 37, 41, 43, 4}, {37, 41, 43, 47, 0},
}

func buildVisible(counts WorkCounts, hidden [7]*big.Int) [46]*big.Int {
	var timeline [53]*big.Int
	for k := 1; k <= 7; k++ {
		timeline[7-k] = C(hidden[k-1])
	}
	var out [46]*big.Int
	for i := 1; i <= 46; i++ {
		idx := 6 + i
		p1 := timeline[idx-1]
		p3 := timeline[idx-3]
		p7 := timeline[idx-7]
		s := stoneTable[i-1]
		x := Mul(s[0], counts.Action)
		x = Add(x, Mul(s[1], counts.Target))
		x = Add(x, Mul(s[2], counts.Distance))
		x = Add(x, Mul(s[3], counts.Connection))
		x = Add(x, Mul(s[4], BI(int64(counts.Direction))))
		x = Add(x, p1)
		x = Add(x, Mul(BI(3), p3))
		x = Add(x, Mul(BI(5), p7))
		x = Save(Add(x, BI(int64(i))))
		for g := 0; g < 11; g++ {
			r := visibleGrinds[g]
			o := C(x)
			x = Square(o)
			x = Add(x, Mul(BI(r[0]), o))
			x = Add(x, Mul(BI(r[1]), p1))
			x = Add(x, Mul(BI(r[2]), p3))
			x = Add(x, Mul(BI(r[3]), p7))
			x = Save(Add(x, s[int(r[4])]))
		}
		timeline[idx] = x
		out[i-1] = x
	}
	return out
}

func permutationUnrank1(rank int, items []int) []int {
	remaining := append([]int(nil), items...)
	out := make([]int, 0, len(items))
	rank0 := rank - 1
	fact := func(n int) int {
		v := 1
		for i := 2; i <= n; i++ {
			v *= i
		}
		return v
	}
	for len(remaining) > 0 {
		block := fact(len(remaining) - 1)
		q := 0
		if block > 0 {
			q = rank0 / block
			rank0 %= block
		}
		out = append(out, remaining[q])
		remaining = append(remaining[:q], remaining[q+1:]...)
	}
	return out
}

func BowlOrderFromDrop(v *big.Int) [6]int {
	r := Mod(Sub(v, BI(1)), BI(720)).Int64() + 1
	x := permutationUnrank1(int(r), []int{1, 2, 3, 4, 5, 6})
	return [6]int{x[0], x[1], x[2], x[3], x[4], x[5]}
}

func initialBowls(c WorkCounts) Bowls {
	p := [6]int64{17, 19, 23, 29, 31, 37}
	var b Bowls
	for id := 1; id <= 6; id++ {
		s := C(c.Action)
		s = Add(s, Mul(c.Target, BI(int64(id))))
		s = Add(s, c.Distance)
		s = Add(s, c.Connection)
		s = Add(s, BI(int64(c.Direction)))
		s = Add(s, BI(p[id-1]*p[id-1]))
		b[id-1] = Save(Add(Square(s), BI(int64(id))))
	}
	return b
}

func cloneBowls(b Bowls) Bowls {
	var o Bowls
	for i := range b {
		o[i] = C(b[i])
	}
	return o
}

func applyDrops(b Bowls, visible [46]*big.Int) (Bowls, [6]int) {
	stoneByPos := [6]int{0, 1, 2, 3, 4, 0}
	var latched [6]int
	for i := 1; i <= 46; i++ {
		drop := visible[i-1]
		order := BowlOrderFromDrop(drop)
		old := cloneBowls(b)
		var pour [6]*big.Int
		pour[0] = Save(Add(Add(Square(drop), Mul(stoneTable[i-1][0], old[order[0]-1])), BI(int64(3*i))))
		pour[1] = Save(Add(Add(Square(drop), Mul(stoneTable[i-1][1], old[order[1]-1])), BI(int64(5*i))))
		pour[2] = Save(Add(Add(Square(drop), Mul(stoneTable[i-1][2], old[order[2]-1])), BI(int64(7*i))))
		for p := 3; p < 6; p++ {
			pour[p] = BI(0)
		}
		var next Bowls
		for pos := 1; pos <= 6; pos++ {
			id := order[pos-1]
			prev := order[Wrap1(pos-1, 6)-1]
			nextID := order[Wrap1(pos+1, 6)-1]
			s := C(old[id-1])
			s = Add(s, Mul(BI(2), old[prev-1]))
			s = Add(s, Mul(BI(3), old[nextID-1]))
			s = Add(s, pour[pos-1])
			s = Add(s, drop)
			s = Add(s, stoneTable[i-1][stoneByPos[pos-1]])
			next[id-1] = Save(Add(Add(Square(s), Mul(BI(5), Mul(old[prev-1], old[nextID-1]))), BI(int64(i*pos))))
		}
		b = next
		if i == 46 {
			latched = order
		}
	}
	return b, latched
}

func postStir12(b Bowls) Bowls {
	for stir := 1; stir <= 12; stir++ {
		old := cloneBowls(b)
		sum := BI(int64(149 * stir))
		for i := 0; i < 6; i++ {
			sum = Add(sum, old[i])
		}
		saved := Save(sum)
		rank := int(Mod(Sub(saved, BI(1)), BI(720)).Int64() + 1)
		x := permutationUnrank1(rank, []int{1, 2, 3, 4, 5, 6})
		order := [6]int{x[0], x[1], x[2], x[3], x[4], x[5]}
		var next Bowls
		for pos := 1; pos <= 6; pos++ {
			id := order[pos-1]
			prev := order[Wrap1(pos-1, 6)-1]
			nextID := order[Wrap1(pos+1, 6)-1]
			s := C(old[id-1])
			s = Add(s, Mul(BI(3), old[prev-1]))
			s = Add(s, Mul(BI(5), old[nextID-1]))
			s = Add(s, saved)
			s = Add(s, BI(int64(stir+pos*pos)))
			next[id-1] = Save(Add(Square(s), Mul(BI(7), Mul(old[prev-1], old[nextID-1]))))
		}
		b = next
	}
	return b
}

func Sauce(cDay, tDay *big.Int) SauceResult {
	counts := Work(cDay, tDay)
	hidden := buildHidden(counts)
	visible := buildVisible(counts, hidden)
	b := initialBowls(counts)
	b, order := applyDrops(b, visible)
	b = postStir12(b)
	return SauceResult{b, order}
}
