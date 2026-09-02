package monster

import "sync"

type Metrics struct {
	mu     sync.Mutex
	values map[string]uint64
}

func NewMetrics() *Metrics          { return &Metrics{values: map[string]uint64{}} }
func (m *Metrics) Bump(code string) { m.mu.Lock(); m.values[code]++; m.mu.Unlock() }
func (m *Metrics) Snapshot() map[string]uint64 {
	m.mu.Lock()
	defer m.mu.Unlock()
	o := map[string]uint64{}
	for k, v := range m.values {
		o[k] = v
	}
	return o
}

type EventLog struct {
	mu     sync.Mutex
	events []string
}

func NewEventLog() *EventLog        { return &EventLog{} }
func (l *EventLog) Add(code string) { l.mu.Lock(); l.events = append(l.events, code); l.mu.Unlock() }
func (l *EventLog) Snapshot() []string {
	l.mu.Lock()
	defer l.mu.Unlock()
	return append([]string(nil), l.events...)
}
