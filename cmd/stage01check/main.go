package main

import (
	"encoding/json"
	"fmt"
	"go-kotava-stage01/catalog"
	"go-kotava-stage01/internal/testoracle"
	"go-kotava-stage01/monster"
	"math/big"
	"os"
)

type fixture struct {
	Version              string     `json:"version"`
	M                    string     `json:"m"`
	Foundation           string     `json:"foundation"`
	Tablets              string     `json:"tablets"`
	SauceFoundationBowls [6]string  `json:"sauce_foundation_bowls"`
	SauceFoundationOrder [6]int     `json:"sauce_foundation_order"`
	CutletCatalog        [17]string `json:"cutlet_catalog"`
	MonthCatalog         [47]string `json:"month_catalog"`
}

func makeFixture() fixture {
	r := testoracle.Sauce(testoracle.FoundationDay, testoracle.FoundationDay)
	f := fixture{Version: "stage01-v1", M: testoracle.M.String(), Foundation: testoracle.FoundationDay.String(), Tablets: testoracle.TabletsDay.String(), SauceFoundationOrder: r.OrderAtDrop46}
	for i := 0; i < 6; i++ {
		f.SauceFoundationBowls[i] = r.Bowls[i].String()
	}
	for i, e := range catalog.CutletEntries() {
		f.CutletCatalog[i] = e.Text
	}
	for i, e := range catalog.MonthEntries() {
		f.MonthCatalog[i] = e.Text
	}
	return f
}

func main() {
	if len(os.Args) == 2 && os.Args[1] == "-emit-fixture" {
		b, err := json.MarshalIndent(makeFixture(), "", "  ")
		if err != nil {
			panic(err)
		}
		fmt.Println(string(b))
		return
	}
	ctx, err := monster.CalendarDateSpaghetti(big.NewInt(-15055671), big.NewInt(-15055671))
	if err == nil || ctx == nil || ctx.Status != monster.StatusStoppedAtBootstrapBoundary {
		panic("E_STAGE01_CHECK")
	}
	if len(catalog.CutletEntries()) != 17 || len(catalog.MonthEntries()) != 47 {
		panic("E_STAGE01_CATALOG")
	}
	if testoracle.Save(testoracle.M).Cmp(testoracle.M) != 0 {
		panic("E_STAGE01_SAVE")
	}
	fmt.Println("STAGE01_GREEN")
}
