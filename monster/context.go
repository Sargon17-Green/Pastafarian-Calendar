package monster

import "math/big"

type Phase uint8

const (
	PhaseEntry Phase = iota
	PhaseValidate
	PhaseBootstrapStop
)

type Status uint8

const (
	StatusNew Status = iota
	StatusRunning
	StatusStoppedAtBootstrapBoundary
	StatusFailed
)

type Context struct {
	CalculationDay *big.Int
	TargetDay      *big.Int
	Phase          Phase
	Status         Status
	BranchTrace    []Phase
	Metrics        *Metrics
	Logs           *EventLog
	LastError      error
}

func NewContext(cDay, tDay *big.Int) *Context {
	return &Context{CalculationDay: new(big.Int).Set(cDay), TargetDay: new(big.Int).Set(tDay), Phase: PhaseEntry, Status: StatusNew, Metrics: NewMetrics(), Logs: NewEventLog()}
}
