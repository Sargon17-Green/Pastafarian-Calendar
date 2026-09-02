package testoracle

import "math/big"

type WorkCounts struct {
	Action, Target, Distance, Connection *big.Int
	Direction                            int
}

func DayCount(day *big.Int) *big.Int {
	c := day.Cmp(FoundationDay)
	if c == 0 {
		return BI(1)
	}
	if c > 0 {
		return Add(Mul(BI(2), Sub(day, FoundationDay)), BI(1))
	}
	return Mul(BI(2), Sub(FoundationDay, day))
}

func Work(cDay, tDay *big.Int) WorkCounts {
	c := DayCount(cDay)
	t := DayCount(tDay)
	d := Add(Abs(Sub(tDay, cDay)), BI(1))
	dir := 2
	if tDay.Cmp(cDay) < 0 {
		dir = 1
	}
	if tDay.Cmp(cDay) > 0 {
		dir = 3
	}
	return WorkCounts{c, t, d, Add(c, t), dir}
}
