package monster

import "math/big"

type Manager struct {
	Dispatcher *Dispatcher
	Validator  ValidationManager
}

func NewManager() *Manager { v := ValidationManager{}; return &Manager{NewDispatcher(v), v} }
func (m *Manager) Execute(cDay, tDay *big.Int) (*Context, error) {
	ctx := NewContext(cDay, tDay)
	for {
		err := m.Dispatcher.Dispatch(ctx)
		if err != nil {
			ctx.LastError = err
			if me, ok := err.(MonsterError); ok && me.Code == ErrStageNotIntegrated {
				return ctx, err
			}
			ctx.Status = StatusFailed
			return ctx, err
		}
	}
}
func CalendarDateSpaghetti(cDay, tDay *big.Int) (*Context, error) {
	return NewManager().Execute(cDay, tDay)
}
