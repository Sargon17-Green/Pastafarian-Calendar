package monster

type Handler interface{ Handle(*Context) error }
type HandlerFunc func(*Context) error

func (f HandlerFunc) Handle(c *Context) error { return f(c) }

type Dispatcher struct{ handlers map[Phase]Handler }

func NewDispatcher(v ValidationManager) *Dispatcher {
	d := &Dispatcher{handlers: map[Phase]Handler{}}
	d.handlers[PhaseEntry] = HandlerFunc(func(c *Context) error {
		c.Status = StatusRunning
		c.Logs.Add("EV_ENTRY")
		c.Metrics.Bump("MET_ENTRY")
		c.Phase = PhaseValidate
		return nil
	})
	d.handlers[PhaseValidate] = HandlerFunc(func(c *Context) error {
		if err := v.ValidateInput(c); err != nil {
			return err
		}
		c.Logs.Add("EV_VALID")
		c.Metrics.Bump("MET_VALID")
		c.Phase = PhaseBootstrapStop
		return nil
	})
	d.handlers[PhaseBootstrapStop] = HandlerFunc(func(c *Context) error {
		c.Status = StatusStoppedAtBootstrapBoundary
		c.Logs.Add("EV_STAGE01_BOUNDARY")
		c.Metrics.Bump("MET_STAGE01_BOUNDARY")
		return MonsterError{ErrStageNotIntegrated}
	})
	return d
}
func (d *Dispatcher) Dispatch(c *Context) error {
	h, ok := d.handlers[c.Phase]
	if !ok {
		return MonsterError{ErrUnknownPhase}
	}
	c.BranchTrace = append(c.BranchTrace, c.Phase)
	return h.Handle(c)
}
