package testoracle

import (
	"math/big"
	"strconv"
	"strings"
)

func FallingFactorial(n, k int) *big.Int {
	r := BI(1)
	for j := 0; j < k; j++ {
		r = Mul(r, BI(int64(n-j)))
	}
	return r
}

func UnrankDistinctIndices(n, k int, rank1 *big.Int) []int {
	remaining := make([]int, n)
	for i := range remaining {
		remaining[i] = i + 1
	}
	r := C(rank1)
	out := make([]int, 0, k)
	for pos := 0; pos < k; pos++ {
		block := FallingFactorial(len(remaining)-1, k-pos-1)
		for ci := 0; ci < len(remaining); ci++ {
			if r.Cmp(block) > 0 {
				r = Sub(r, block)
				continue
			}
			out = append(out, remaining[ci])
			remaining = append(remaining[:ci], remaining[ci+1:]...)
			break
		}
	}
	return out
}

type BoundedFamily struct {
	Total, Slots, Lo, Hi int
	memo                 map[[2]int]*big.Int
}

func NewBoundedFamily(total, slots, lo, hi int) *BoundedFamily {
	return &BoundedFamily{total, slots, lo, hi, map[[2]int]*big.Int{}}
}
func (f *BoundedFamily) count(rem, k int) *big.Int {
	if k == 0 {
		if rem == 0 {
			return BI(1)
		}
		return BI(0)
	}
	if rem < k*f.Lo || rem > k*f.Hi {
		return BI(0)
	}
	key := [2]int{rem, k}
	if v, ok := f.memo[key]; ok {
		return C(v)
	}
	t := BI(0)
	for x := f.Lo; x <= f.Hi; x++ {
		t = Add(t, f.count(rem-x, k-1))
	}
	f.memo[key] = C(t)
	return t
}
func (f *BoundedFamily) Count() *big.Int { return f.count(f.Total, f.Slots) }
func (f *BoundedFamily) Unrank1(rank *big.Int) []int {
	r := C(rank)
	rem := f.Total
	out := make([]int, 0, f.Slots)
	for pos := 0; pos < f.Slots; pos++ {
		for x := f.Lo; x <= f.Hi; x++ {
			c := f.count(rem-x, f.Slots-pos-1)
			if r.Cmp(c) > 0 {
				r = Sub(r, c)
			} else {
				out = append(out, x)
				rem -= x
				break
			}
		}
	}
	return out
}

type CutletPartitionFamily struct {
	G, K     int
	Required int
	memo     map[string]*big.Int
}

func NewCutletPartitionFamily(g, k, required int) *CutletPartitionFamily {
	return &CutletPartitionFamily{g, k, required, map[string]*big.Int{}}
}
func (f *CutletPartitionFamily) key(rem, slots, cum int, hit bool) string {
	return strconv.Itoa(rem) + ":" + strconv.Itoa(slots) + ":" + strconv.Itoa(cum) + ":" + strconv.FormatBool(hit)
}
func (f *CutletPartitionFamily) count(rem, slots, cum int, hit bool) *big.Int {
	if slots == 0 {
		if rem != 0 {
			return BI(0)
		}
		if f.Required == 0 || hit {
			return BI(1)
		}
		return BI(0)
	}
	if rem < slots {
		return BI(0)
	}
	key := f.key(rem, slots, cum, hit)
	if v, ok := f.memo[key]; ok {
		return C(v)
	}
	t := BI(0)
	maxX := rem - (slots - 1)
	for x := 1; x <= maxX; x++ {
		nc := cum + x
		nh := hit
		if f.Required != 0 && !hit {
			if nc == f.Required {
				nh = true
			} else if nc > f.Required {
				continue
			}
		}
		t = Add(t, f.count(rem-x, slots-1, nc, nh))
	}
	f.memo[key] = C(t)
	return t
}
func (f *CutletPartitionFamily) Count() *big.Int { return f.count(f.G, f.K, 0, false) }
func (f *CutletPartitionFamily) Unrank1(rank *big.Int) []int {
	r := C(rank)
	rem, slots, cum, hit := f.G, f.K, 0, false
	out := make([]int, 0, f.K)
	for slots > 0 {
		maxX := rem - (slots - 1)
		for x := 1; x <= maxX; x++ {
			nc := cum + x
			nh := hit
			if f.Required != 0 && !hit {
				if nc == f.Required {
					nh = true
				} else if nc > f.Required {
					continue
				}
			}
			block := f.count(rem-x, slots-1, nc, nh)
			if r.Cmp(block) > 0 {
				r = Sub(r, block)
			} else {
				out = append(out, x)
				rem -= x
				slots--
				cum = nc
				hit = nh
				break
			}
		}
	}
	return out
}

type WeaveState struct {
	Remain         []int
	Opened, Closed int
}
type WeavingFamily struct {
	Lengths []int
	memo    map[string]*big.Int
}

func NewWeavingFamily(lengths []int) *WeavingFamily {
	return &WeavingFamily{append([]int(nil), lengths...), map[string]*big.Int{}}
}
func (f *WeavingFamily) key(s WeaveState) string {
	var b strings.Builder
	b.WriteString(strconv.Itoa(s.Opened))
	b.WriteByte(':')
	b.WriteString(strconv.Itoa(s.Closed))
	for _, v := range s.Remain {
		b.WriteByte(':')
		b.WriteString(strconv.Itoa(v))
	}
	return b.String()
}
func (f *WeavingFamily) initial() WeaveState {
	return WeaveState{append([]int(nil), f.Lengths...), 0, 0}
}
func (f *WeavingFamily) legal(s WeaveState, j int) bool {
	idx := j - 1
	if s.Remain[idx] == 0 {
		return false
	}
	opened := s.Remain[idx] < f.Lengths[idx]
	if !opened && j != s.Opened+1 {
		return false
	}
	if s.Remain[idx] == 1 && j != s.Closed+1 {
		return false
	}
	return true
}
func (f *WeavingFamily) move(s WeaveState, j int) WeaveState {
	n := WeaveState{append([]int(nil), s.Remain...), s.Opened, s.Closed}
	idx := j - 1
	if n.Remain[idx] == f.Lengths[idx] {
		n.Opened = j
	}
	n.Remain[idx]--
	if n.Remain[idx] == 0 {
		n.Closed = j
	}
	return n
}
func (f *WeavingFamily) count(s WeaveState) *big.Int {
	done := true
	for _, v := range s.Remain {
		if v != 0 {
			done = false
			break
		}
	}
	if done {
		return BI(1)
	}
	k := f.key(s)
	if v, ok := f.memo[k]; ok {
		return C(v)
	}
	t := BI(0)
	for j := 1; j <= len(f.Lengths); j++ {
		if f.legal(s, j) {
			t = Add(t, f.count(f.move(s, j)))
		}
	}
	f.memo[k] = C(t)
	return t
}
func (f *WeavingFamily) Count() *big.Int { return f.count(f.initial()) }
func (f *WeavingFamily) Unrank1(rank *big.Int) []int {
	r := C(rank)
	s := f.initial()
	total := 0
	for _, v := range f.Lengths {
		total += v
	}
	out := make([]int, 0, total)
	for len(out) < total {
		for j := 1; j <= len(f.Lengths); j++ {
			if !f.legal(s, j) {
				continue
			}
			n := f.move(s, j)
			b := f.count(n)
			if r.Cmp(b) > 0 {
				r = Sub(r, b)
			} else {
				out = append(out, j)
				s = n
				break
			}
		}
	}
	return out
}
