package catalog

import "testing"

func TestCatalogIndexStability(t *testing.T) {
	cuts := CutletEntries()
	mons := MonthEntries()
	if len(cuts) != 17 || len(mons) != 47 {
		t.Fatalf("E_CATALOG_SIZE")
	}
	seen := map[string]bool{}
	for i, e := range cuts {
		if e.CanonicalIndex != i+1 || e.Text == "" || seen[e.Text] {
			t.Fatalf("E_CUTLET_CATALOG")
		}
		seen[e.Text] = true
	}
	seen = map[string]bool{}
	for i, e := range mons {
		if e.CanonicalIndex != i+1 || e.Text == "" || seen[e.Text] {
			t.Fatalf("E_MONTH_CATALOG")
		}
		seen[e.Text] = true
	}
}

func TestCatalogIsReturnedByValue(t *testing.T) {
	cuts := CutletEntries()
	cuts[0].Text = "X"
	if got, _ := CutletText(1); got != "iyekot" {
		t.Fatalf("E_CUTLET_MUTATION")
	}
	mons := MonthEntries()
	mons[0].Text = "X"
	if got, _ := MonthText(1); got != "kuritca" {
		t.Fatalf("E_MONTH_MUTATION")
	}
}
