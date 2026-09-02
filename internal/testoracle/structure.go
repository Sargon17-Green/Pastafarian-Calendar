package testoracle

import (
	"go-kotava-stage01/catalog"
	"math/big"
)

type Cutlet struct {
	NameIndex             int
	OpenIndex, CloseIndex *big.Int
	FirstDay, LastDay     *big.Int
}

type YearStructure struct {
	Year              Year
	CutletCount       int
	CutletPartition   []int
	CutletNameIndices []int
	Cutlets           []Cutlet
	MonthCount        int
	MonthLengths      []int
	MonthWeaving      []int
	MonthNameIndices  []int
}

func yearLengthInt(y Year) int {
	l := Sub(y.CloseDay, y.OpenDay)
	if l.Cmp(BI(5778)) > 0 || l.Sign() < 0 {
		panic("E_YEAR_LENGTH")
	}
	return int(l.Int64())
}
func gateGapCountInt(y Year) int {
	g := Sub(y.CloseIndex, y.OpenIndex)
	if g.Sign() < 0 || g.Cmp(BI(1000)) > 0 {
		panic("E_GATE_GAPS")
	}
	return int(g.Int64())
}

func chooseCutletCount(r SauceResult, y Year) int {
	gaps := gateGapCountInt(y)
	cands := []int{}
	for k := 6; k <= 17; k++ {
		if k <= gaps {
			cands = append(cands, k)
		}
	}
	if len(cands) == 0 {
		panic("E_CUTLET_COUNT_EMPTY")
	}
	a := AskBowl(r, 2, 20)
	rank := ChooseRank(a, BI(int64(len(cands))))
	return cands[int(rank.Int64())-1]
}

func chooseCutletPartition(g *GateBook, cDay *big.Int, r SauceResult, y Year, k int) []int {
	G := gateGapCountInt(y)
	required := 0
	if idx, ok := g.ExactIndex(cDay); ok && idx.Cmp(y.OpenIndex) > 0 && idx.Cmp(y.CloseIndex) < 0 {
		required = int(Sub(idx, y.OpenIndex).Int64())
	}
	f := NewCutletPartitionFamily(G, k, required)
	n := f.Count()
	if n.Sign() <= 0 {
		panic("E_CUTLET_PARTITION_EMPTY")
	}
	a := AskBowl(r, 2, 21)
	rank := ChooseRank(a, n)
	return f.Unrank1(rank)
}

func chooseCutletNames(r SauceResult, k int) []int {
	n := FallingFactorial(17, k)
	a := AskBowl(r, 5, 22)
	rank := ChooseRank(a, n)
	return UnrankDistinctIndices(17, k, rank)
}

func materializeCutlets(g *GateBook, y Year, partition, names []int) []Cutlet {
	cursor := C(y.OpenIndex)
	out := make([]Cutlet, len(partition))
	for i, p := range partition {
		open := C(cursor)
		close := Add(cursor, BI(int64(p)))
		out[i] = Cutlet{names[i], open, close, Add(g.EnsureIndex(open), BI(1)), g.EnsureIndex(close)}
		cursor = close
	}
	return out
}

func chooseMonthCount(r SauceResult, y Year) int {
	L := yearLengthInt(y)
	lo := (L + 122) / 123
	hi := L / 4
	if hi > 47 {
		hi = 47
	}
	if lo < 3 || lo > hi {
		panic("E_MONTH_COUNT_RANGE")
	}
	a := AskBowl(r, 3, 30)
	rank := ChooseRank(a, BI(int64(hi-lo+1)))
	return lo + int(rank.Int64()) - 1
}

func chooseMonthLengths(r SauceResult, y Year, k int) []int {
	f := NewBoundedFamily(yearLengthInt(y), k, 4, 123)
	n := f.Count()
	if n.Sign() <= 0 {
		panic("E_MONTH_LENGTH_EMPTY")
	}
	a := AskBowl(r, 3, 31)
	rank := ChooseRank(a, n)
	return f.Unrank1(rank)
}

func chooseMonthWeaving(r SauceResult, lengths []int) []int {
	f := NewWeavingFamily(lengths)
	n := f.Count()
	if n.Sign() <= 0 {
		panic("E_WEAVE_EMPTY")
	}
	a := AskBowl(r, 4, 32)
	rank := ChooseRank(a, n)
	return f.Unrank1(rank)
}

func chooseMonthNames(r SauceResult, k int) []int {
	n := FallingFactorial(47, k)
	a := AskBowl(r, 5, 33)
	rank := ChooseRank(a, n)
	return UnrankDistinctIndices(47, k, rank)
}

func BuildYearStructure(g *GateBook, cDay *big.Int, y Year) YearStructure {
	first := Add(y.OpenDay, BI(1))
	r := Sauce(cDay, first)
	kc := chooseCutletCount(r, y)
	part := chooseCutletPartition(g, cDay, r, y, kc)
	cn := chooseCutletNames(r, kc)
	cuts := materializeCutlets(g, y, part, cn)
	km := chooseMonthCount(r, y)
	ml := chooseMonthLengths(r, y, km)
	w := chooseMonthWeaving(r, ml)
	mn := chooseMonthNames(r, km)
	return YearStructure{y, kc, part, cn, cuts, km, ml, w, mn}
}

type DateResult struct {
	YearNumber  *big.Int
	CutletName  string
	DayInCutlet int
	MonthName   string
	DayInMonth  int
}

func CalendarDate(cDay, tDay *big.Int) DateResult {
	g := NewGateBook()
	y := g.FindTargetYear(cDay, tDay)
	s := BuildYearStructure(g, cDay, y)
	cutID := -1
	for i, c := range s.Cutlets {
		if c.FirstDay.Cmp(tDay) <= 0 && tDay.Cmp(c.LastDay) <= 0 {
			cutID = i
			break
		}
	}
	if cutID < 0 {
		panic("E_CUTLET_RESOLVE")
	}
	dayInCutlet := int(Add(Sub(tDay, s.Cutlets[cutID].FirstDay), BI(1)).Int64())
	offset := int(Sub(tDay, Add(y.OpenDay, BI(1))).Int64())
	if offset < 0 || offset >= len(s.MonthWeaving) {
		panic("E_MONTH_OFFSET")
	}
	monthID := s.MonthWeaving[offset]
	dayInMonth := 0
	for p := 0; p <= offset; p++ {
		if s.MonthWeaving[p] == monthID {
			dayInMonth++
		}
	}
	cutName, ok := catalog.CutletText(s.CutletNameIndices[cutID])
	if !ok {
		panic("E_CUTLET_CATALOG")
	}
	monthName, ok := catalog.MonthText(s.MonthNameIndices[monthID-1])
	if !ok {
		panic("E_MONTH_CATALOG")
	}
	return DateResult{C(y.Number), cutName, dayInCutlet, monthName, dayInMonth}
}
