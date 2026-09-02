package stageaudit

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"unicode"
)

func TestNoFuturePatchCodeInProduction(t *testing.T) {
	forbidden := []string{"oldRemainder", "oldDayTag", "oldDistance", "mutateStonesWrong", "legacyPrior", "orderAt46Latch", "biasedLegacyPick", "LEGACY_YEAR_MAX", "oldJumpGuess", "VirtualLegacyList", "legacyChooseEachDaySeparately", "oldContiguousMonthDayGuess"}
	for _, dir := range []string{"../catalog", "../monster"} {
		err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}
			if info.IsDir() || !strings.HasSuffix(path, ".go") {
				return nil
			}
			b, e := os.ReadFile(path)
			if e != nil {
				return e
			}
			s := string(b)
			for _, f := range forbidden {
				if strings.Contains(s, f) {
					t.Fatalf("E_FUTURE_PATCH:%s:%s", path, f)
				}
			}
			return nil
		})
		if err != nil {
			t.Fatal(err)
		}
	}
}

func TestProjectDocumentationHasNoHebrewScript(t *testing.T) {
	files := []string{"../README.md", "../SOURCE_LANGUAGE_CATALOG.md", "../SPAGHETTI_DEVELOPMENT_HISTORY.md", "../HANDOFF_STAGE_01.md"}
	for _, path := range files {
		b, err := os.ReadFile(path)
		if err != nil {
			t.Fatal(err)
		}
		for _, r := range string(b) {
			if unicode.In(r, unicode.Hebrew) {
				t.Fatalf("E_DOC_HEBREW:%s", path)
			}
		}
	}
}
