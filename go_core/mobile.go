package edgepulse

import (
	"context"
	"encoding/json"
	"fmt"
	"sync"
)

// MobileCallback is exported to Kotlin/Java via gomobile bind.
// All parameters use gomobile-safe primitive types (string).
type MobileCallback interface {
	OnProgress(progressJSON string)
	OnResult(resultJSON string)
	OnComplete(summaryJSON string)
	OnError(errorMessage string)
}

// Engine is the thread-safe mobile controller exported by gomobile bind.
type Engine struct {
	mu      sync.Mutex
	cancel  context.CancelFunc
	scanner *Scanner
	running bool
}

// NewEngine constructs a new Go scanning engine instance for Android.
func NewEngine() *Engine {
	return &Engine{}
}

// Version returns the native Go core version string.
func (e *Engine) Version() string {
	return "miliscanner-core/1.1.0"
}

// StartScan parses targetsJSON and configJSON and runs the scan asynchronously.
func (e *Engine) StartScan(targetsJSON string, configJSON string, cb MobileCallback) error {
	e.mu.Lock()
	if e.running {
		e.mu.Unlock()
		return fmt.Errorf("scan already running")
	}

	cfg := DefaultScanConfig()
	if configJSON != "" {
		if err := json.Unmarshal([]byte(configJSON), &cfg); err != nil {
			e.mu.Unlock()
			return fmt.Errorf("invalid config JSON: %w", err)
		}
	}

	var targets []ProxyTarget
	if err := json.Unmarshal([]byte(targetsJSON), &targets); err != nil {
		// Fallback: treat input as raw text lines / CSV / CIDR
		targets = ParseTargetsText(targetsJSON, "XX", cfg.DefaultPorts, cfg.MaxIPsPerCIDR)
	}
	if len(targets) == 0 {
		e.mu.Unlock()
		return fmt.Errorf("no valid targets provided")
	}

	ctx, cancel := context.WithCancel(context.Background())
	scanner := NewScanner(cfg)
	e.cancel = cancel
	e.scanner = scanner
	e.running = true
	e.mu.Unlock()

	go func() {
		defer func() {
			e.mu.Lock()
			e.running = false
			e.cancel = nil
			e.scanner = nil
			e.mu.Unlock()
		}()

		adapter := &mobileHandlerAdapter{cb: cb}
		results := scanner.Run(ctx, targets, adapter)
		if cb != nil {
			if data, err := json.Marshal(results); err == nil {
				cb.OnComplete(string(data))
			} else {
				cb.OnError(err.Error())
			}
		}
	}()

	return nil
}

// PauseScan pauses the active scan.
func (e *Engine) PauseScan() {
	e.mu.Lock()
	defer e.mu.Unlock()
	if e.scanner != nil {
		e.scanner.Pause()
	}
}

// ResumeScan resumes a paused scan.
func (e *Engine) ResumeScan() {
	e.mu.Lock()
	defer e.mu.Unlock()
	if e.scanner != nil {
		e.scanner.Resume()
	}
}

// StopScan cancels the active scan cleanly.
func (e *Engine) StopScan() {
	e.mu.Lock()
	defer e.mu.Unlock()
	if e.scanner != nil {
		e.scanner.Resume()
	}
	if e.cancel != nil {
		e.cancel()
	}
}

// IsRunning reports whether a scan is currently active.
func (e *Engine) IsRunning() bool {
	e.mu.Lock()
	defer e.mu.Unlock()
	return e.running
}

// ParseTargets converts raw text/CSV/CIDR into a JSON array of ProxyTarget.
func ParseTargets(raw string, defaultCountry string, defaultPort int, maxPerCIDR int) string {
	targets := ParseTargetsText(raw, defaultCountry, []int{defaultPort}, maxPerCIDR)
	b, err := json.Marshal(targets)
	if err != nil {
		return "[]"
	}
	return string(b)
}

type mobileHandlerAdapter struct {
	cb MobileCallback
}

func (a *mobileHandlerAdapter) OnProgress(p ScanProgress) {
	if a.cb == nil {
		return
	}
	if b, err := json.Marshal(p); err == nil {
		a.cb.OnProgress(string(b))
	}
}

func (a *mobileHandlerAdapter) OnResult(r ScanResult) {
	if a.cb == nil {
		return
	}
	if b, err := json.Marshal(r); err == nil {
		a.cb.OnResult(string(b))
	}
}
