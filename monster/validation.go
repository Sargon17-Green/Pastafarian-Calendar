package monster

type ValidationManager struct{}

func (v ValidationManager) ValidateInput(ctx *Context) error {
	if ctx == nil || ctx.CalculationDay == nil || ctx.TargetDay == nil {
		return MonsterError{ErrInvalidContext}
	}
	return nil
}
