package testoracle

import (
	"encoding/json"
	"os"
	"testing"
)

type vectorFile struct {
	M                    string    `json:"m"`
	Foundation           string    `json:"foundation"`
	Tablets              string    `json:"tablets"`
	SauceFoundationBowls [6]string `json:"sauce_foundation_bowls"`
	SauceFoundationOrder [6]int    `json:"sauce_foundation_order"`
}

func TestConstantsAndExactArithmetic(t *testing.T) {
	if Sub(TabletsDay, FoundationDay).String() != "14777149" {
		t.Fatalf("E_ANCHOR_DISTANCE")
	}
	if M.String() != "170141183460469231731687303715884105727" {
		t.Fatalf("E_M")
	}
	if Save(M).Cmp(M) != 0 || Save(Mul(BI(2), M)).Cmp(M) != 0 || Save(Add(M, BI(1))).Cmp(BI(1)) != 0 {
		t.Fatalf("E_SAVE")
	}
	if DayCount(FoundationDay).Cmp(BI(1)) != 0 || DayCount(Sub(FoundationDay, BI(1))).Cmp(BI(2)) != 0 || DayCount(Add(FoundationDay, BI(1))).Cmp(BI(3)) != 0 {
		t.Fatalf("E_DAY_COUNT")
	}
	w := Work(Sub(FoundationDay, BI(1)), Add(FoundationDay, BI(1)))
	if w.Action.Cmp(BI(2)) != 0 || w.Target.Cmp(BI(3)) != 0 || w.Distance.Cmp(BI(3)) != 0 || w.Connection.Cmp(BI(5)) != 0 || w.Direction != 3 {
		t.Fatalf("E_WORK_COUNTS")
	}
}

func TestStoneSnapshotAndPermutation(t *testing.T) {
	s := stoneTable[1]
	want := []int64{378, 1073, 2375, 6195, 10493}
	for i, v := range want {
		if s[i].Cmp(BI(v)) != 0 {
			t.Fatalf("E_STONE_02")
		}
	}
	if BowlOrderFromDrop(BI(1)) != ([6]int{1, 2, 3, 4, 5, 6}) {
		t.Fatalf("E_PERM_1")
	}
	if BowlOrderFromDrop(BI(720)) != ([6]int{6, 5, 4, 3, 2, 1}) {
		t.Fatalf("E_PERM_720")
	}
}

func TestFamilies(t *testing.T) {
	b := NewBoundedFamily(7, 2, 2, 5)
	if b.Count().Cmp(BI(4)) != 0 {
		t.Fatalf("E_BOUNDED_COUNT")
	}
	if got := b.Unrank1(BI(3)); len(got) != 2 || got[0] != 4 || got[1] != 3 {
		t.Fatalf("E_BOUNDED_UNRANK")
	}
	c := NewCutletPartitionFamily(6, 3, 3)
	if c.Count().Cmp(BI(4)) != 0 {
		t.Fatalf("E_CUTLET_FILTER_COUNT")
	}
	w := NewWeavingFamily([]int{2, 2})
	if w.Count().Cmp(BI(2)) != 0 {
		t.Fatalf("E_WEAVE_COUNT")
	}
	a := w.Unrank1(BI(1))
	z := w.Unrank1(BI(2))
	if len(a) != 4 || a[0] != 1 || a[1] != 1 || a[2] != 2 || a[3] != 2 || len(z) != 4 || z[0] != 1 || z[1] != 2 || z[2] != 1 || z[3] != 2 {
		t.Fatalf("E_WEAVE_UNRANK")
	}
	if FallingFactorial(17, 17).Sign() <= 0 || len(UnrankDistinctIndices(17, 17, BI(1))) != 17 {
		t.Fatalf("E_NAME_UNRANK")
	}
}

func TestFoundationSauceFixture(t *testing.T) {
	b, err := os.ReadFile("../../testdata/stage01_vectors.json")
	if err != nil {
		t.Fatal(err)
	}
	var v vectorFile
	if err := json.Unmarshal(b, &v); err != nil {
		t.Fatal(err)
	}
	if v.M != M.String() || v.Foundation != FoundationDay.String() || v.Tablets != TabletsDay.String() {
		t.Fatalf("E_FIXTURE_CONSTANTS")
	}
	r := Sauce(FoundationDay, FoundationDay)
	for i := 0; i < 6; i++ {
		if r.Bowls[i].String() != v.SauceFoundationBowls[i] {
			t.Fatalf("E_FIXTURE_BOWL")
		}
	}
	if r.OrderAtDrop46 != v.SauceFoundationOrder {
		t.Fatalf("E_FIXTURE_ORDER")
	}
}

func TestWideAndShortSelectionBounds(t *testing.T) {
	s := AnswerStream{BI(1), 1}
	if ChooseRank(s, BI(1)).Cmp(BI(1)) != 0 {
		t.Fatalf("E_SHORT_ONE")
	}
	if ChooseRank(s, M).Cmp(BI(1)) != 0 {
		t.Fatalf("E_SHORT_M")
	}
	if ChooseRank(s, Add(M, BI(1))).Sign() <= 0 || ChooseRank(s, Add(M, BI(1))).Cmp(Add(M, BI(1))) > 0 {
		t.Fatalf("E_WIDE")
	}
}
