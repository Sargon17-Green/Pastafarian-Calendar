package monster

import "fmt"

type ErrorCode string

const (
	ErrStageNotIntegrated ErrorCode = "E_STAGE_NOT_INTEGRATED"
	ErrInvalidContext     ErrorCode = "E_INVALID_CONTEXT"
	ErrUnknownPhase       ErrorCode = "E_UNKNOWN_PHASE"
)

type MonsterError struct{ Code ErrorCode }

func (e MonsterError) Error() string { return string(e.Code) }
func wrap(code ErrorCode) error      { return fmt.Errorf("%w", MonsterError{code}) }
