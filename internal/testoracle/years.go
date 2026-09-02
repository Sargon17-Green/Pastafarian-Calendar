package testoracle

import (
	"math/big"
	"sort"
)

type GateBook struct {
	gates    map[string]*big.Int
	minKnown *big.Int
	maxKnown *big.Int
}

func NewGateBook() *GateBook {
	g := map[string]*big.Int{"0": C(FoundationDay)}
	return &GateBook{g, BI(0), BI(0)}
}

func (g *GateBook) get(i *big.Int) *big.Int { return C(g.gates[i.String()]) }
func (g *GateBook) set(i, v *big.Int)       { g.gates[i.String()] = C(v) }

func (g *GateBook) gap(step *big.Int) *big.Int {
	mag := Abs(step)
	q := Add(FoundationDay, mag)
	if step.Sign() < 0 {
		q = Sub(FoundationDay, mag)
	}
	r := Sauce(FoundationDay, q)
	a := AskBowl(r, 1, 1)
	pick := ChooseRank(a, BI(922))
	return Add(BI(41), pick)
}

func (g *GateBook) EnsureIndex(k *big.Int) *big.Int {
	if k.Cmp(g.maxKnown) > 0 {
		n := Add(g.maxKnown, BI(1))
		for n.Cmp(k) <= 0 {
			prev := Sub(n, BI(1))
			g.set(n, Add(g.get(prev), g.gap(n)))
			g.maxKnown = C(n)
			n = Add(n, BI(1))
		}
	}
	if k.Cmp(g.minKnown) < 0 {
		n := Sub(g.minKnown, BI(1))
		for n.Cmp(k) >= 0 {
			next := Add(n, BI(1))
			g.set(n, Sub(g.get(next), g.gap(n)))
			g.minKnown = C(n)
			n = Sub(n, BI(1))
		}
	}
	return g.get(k)
}

func (g *GateBook) EnsureCover(low, high *big.Int) {
	for g.get(g.minKnown).Cmp(low) > 0 {
		g.EnsureIndex(Sub(g.minKnown, BI(1)))
	}
	for g.get(g.maxKnown).Cmp(high) < 0 {
		g.EnsureIndex(Add(g.maxKnown, BI(1)))
	}
}

func (g *GateBook) IndexAtOrBefore(day *big.Int) *big.Int {
	g.EnsureCover(day, day)
	lo := C(g.minKnown)
	hi := C(g.maxKnown)
	for lo.Cmp(hi) < 0 {
		mid := FloorDiv(Add(Add(lo, hi), BI(1)), BI(2))
		if g.get(mid).Cmp(day) <= 0 {
			lo = mid
		} else {
			hi = Sub(mid, BI(1))
		}
	}
	return lo
}

func (g *GateBook) ExactIndex(day *big.Int) (*big.Int, bool) {
	i := g.IndexAtOrBefore(day)
	if g.get(i).Cmp(day) == 0 {
		return i, true
	}
	return nil, false
}

type Year struct {
	Number                *big.Int
	OpenIndex, CloseIndex *big.Int
	OpenDay, CloseDay     *big.Int
}

type pair struct {
	open, close *big.Int
	length      *big.Int
}

func (g *GateBook) validPair(open, close *big.Int) bool {
	if Sub(close, open).Cmp(BI(6)) < 0 {
		return false
	}
	l := Sub(g.get(close), g.get(open))
	return l.Cmp(BI(252)) >= 0 && l.Cmp(BI(5778)) <= 0
}

func (g *GateBook) makeYear(number, open, close *big.Int) Year {
	return Year{C(number), C(open), C(close), g.get(open), g.get(close)}
}

func (g *GateBook) Year5000(cDay *big.Int) Year {
	g.EnsureCover(Sub(cDay, BI(5778)), Add(cDay, BI(5778)))
	list := []pair{}
	for i := C(g.minKnown); i.Cmp(g.maxKnown) < 0; i = Add(i, BI(1)) {
		for j := Add(i, BI(1)); j.Cmp(g.maxKnown) <= 0; j = Add(j, BI(1)) {
			if !g.validPair(i, j) {
				continue
			}
			oi, cj := g.get(i), g.get(j)
			if !(oi.Cmp(cDay) < 0 && cDay.Cmp(cj) <= 0) {
				continue
			}
			list = append(list, pair{C(i), C(j), Sub(cj, oi)})
		}
	}
	sort.Slice(list, func(a, b int) bool {
		c := list[a].length.Cmp(list[b].length)
		if c != 0 {
			return c < 0
		}
		return g.get(list[a].open).Cmp(g.get(list[b].open)) < 0
	})
	if len(list) == 0 {
		panic("E_YEAR5000_EMPTY")
	}
	r := Sauce(cDay, cDay)
	a := AskBowl(r, 1, 10)
	rank := ChooseRank(a, BI(int64(len(list))))
	p := list[int(rank.Int64())-1]
	return g.makeYear(BI(5000), p.open, p.close)
}

func (g *GateBook) NextYear(cDay *big.Int, known Year) Year {
	open := C(known.CloseIndex)
	g.EnsureCover(g.get(g.minKnown), Add(g.get(open), BI(5778)))
	type cand struct{ idx, length *big.Int }
	list := []cand{}
	for j := Add(open, BI(1)); ; j = Add(j, BI(1)) {
		g.EnsureIndex(j)
		l := Sub(g.get(j), g.get(open))
		if l.Cmp(BI(5778)) > 0 {
			break
		}
		if g.validPair(open, j) {
			list = append(list, cand{C(j), l})
		}
	}
	sort.SliceStable(list, func(a, b int) bool { return list[a].length.Cmp(list[b].length) < 0 })
	if len(list) == 0 {
		panic("E_NEXT_YEAR_EMPTY")
	}
	r := Sauce(cDay, g.get(open))
	a := AskBowl(r, 1, 11)
	rank := ChooseRank(a, BI(int64(len(list))))
	close := list[int(rank.Int64())-1].idx
	return g.makeYear(Add(known.Number, BI(1)), open, close)
}

func (g *GateBook) PreviousYear(cDay *big.Int, known Year) Year {
	close := C(known.OpenIndex)
	g.EnsureCover(Sub(g.get(close), BI(5778)), g.get(g.maxKnown))
	type cand struct{ idx, length *big.Int }
	list := []cand{}
	for i := Sub(close, BI(1)); ; i = Sub(i, BI(1)) {
		g.EnsureIndex(i)
		l := Sub(g.get(close), g.get(i))
		if l.Cmp(BI(5778)) > 0 {
			break
		}
		if g.validPair(i, close) {
			list = append(list, cand{C(i), l})
		}
	}
	sort.SliceStable(list, func(a, b int) bool { return list[a].length.Cmp(list[b].length) < 0 })
	if len(list) == 0 {
		panic("E_PREV_YEAR_EMPTY")
	}
	r := Sauce(cDay, g.get(close))
	a := AskBowl(r, 1, 12)
	rank := ChooseRank(a, BI(int64(len(list))))
	open := list[int(rank.Int64())-1].idx
	return g.makeYear(Sub(known.Number, BI(1)), open, close)
}

func (g *GateBook) FindTargetYear(cDay, tDay *big.Int) Year {
	y := g.Year5000(cDay)
	for tDay.Cmp(y.CloseDay) > 0 {
		y = g.NextYear(cDay, y)
	}
	for tDay.Cmp(y.OpenDay) <= 0 {
		y = g.PreviousYear(cDay, y)
	}
	return y
}
