package monster

import (
	"math/big"
	"testing"
)

func TestBootstrapBoundaryAndOwnership(t *testing.T) {
	c := big.NewInt(-15055671)
	x := big.NewInt(-15055670)
	a, ea := CalendarDateSpaghetti(c, x)
	b, eb := CalendarDateSpaghetti(c, x)
	if ea == nil || eb == nil || ea.Error() != string(ErrStageNotIntegrated) || eb.Error() != string(ErrStageNotIntegrated) {
		t.Fatalf("E_STAGE01_BOUNDARY")
	}
	if a == b || a.Metrics == b.Metrics || a.Logs == b.Logs {
		t.Fatalf("E_CONTEXT_SHARED")
	}
	a.CalculationDay.SetInt64(9)
	if b.CalculationDay.Int64() == 9 {
		t.Fatalf("E_INPUT_ALIAS")
	}
	if a.Status != StatusStoppedAtBootstrapBoundary || b.Status != StatusStoppedAtBootstrapBoundary {
		t.Fatalf("E_STATUS")
	}
}
