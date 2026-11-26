package edgepulse

import (
	"bufio"
	"context"
	"crypto/tls"
	"fmt"
	"io"
	"math"
	"net"
	"net/http"
	"sort"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"
)

// ResultHandler receives streaming events during a scan.
type ResultHandler interface {
	OnProgress(p ScanProgress)
	OnResult(r ScanResult)
}

// Scanner executes high-concurrency TCP/TLS/Trace/Speed benchmarks.
type Scanner struct {
	cfg      ScanConfig
	pauseMu  sync.Mutex
	pauseCh  chan struct{}
	isPaused atomic.Bool
}

// NewScanner creates a Scanner with sanitized configuration.
func NewScanner(cfg ScanConfig) *Scanner {
	if cfg.Concurrency <= 0 {
		cfg.Concurrency = 32
	}
	if cfg.Concurrency > 500 {
		cfg.Concurrency = 500
	}
	if cfg.TimeoutMs <= 0 {
		cfg.TimeoutMs = 2500
	}
	if cfg.ProbeCount <= 0 {
		cfg.ProbeCount = 1
	}
	if cfg.ProbeCount > 10 {
		cfg.ProbeCount = 10
	}
	if cfg.SNI == "" {
		cfg.SNI = "speed.cloudflare.com"
	}
	if cfg.TraceHost == "" {
		cfg.TraceHost = cfg.SNI
	}
	if cfg.TracePath == "" {
		cfg.TracePath = "/cdn-cgi/trace"
	}
	if cfg.SpeedTestHost == "" {
		cfg.SpeedTestHost = "speed.cloudflare.com"
	}
	if cfg.SpeedTestBytes <= 0 {
		cfg.SpeedTestBytes = 524288
	}
	if cfg.SpeedTestPath == "" {
		cfg.SpeedTestPath = fmt.Sprintf("/__down?bytes=%d", cfg.SpeedTestBytes)
	}
	if cfg.SpeedTestTimeoutS <= 0 {
		cfg.SpeedTestTimeoutS = 8
	}
	return &Scanner{cfg: cfg}
}

// Pause halts worker goroutines cleanly until Resume is called.
func (s *Scanner) Pause() {
	s.pauseMu.Lock()
	defer s.pauseMu.Unlock()
	if !s.isPaused.Load() {
		s.pauseCh = make(chan struct{})
		s.isPaused.Store(true)
	}
}

// Resume unblocks paused worker goroutines.
func (s *Scanner) Resume() {
	s.pauseMu.Lock()
	defer s.pauseMu.Unlock()
	if s.isPaused.Load() && s.pauseCh != nil {
		close(s.pauseCh)
		s.pauseCh = nil
		s.isPaused.Store(false)
	}
}

func (s *Scanner) waitIfPaused(ctx context.Context) error {
	for s.isPaused.Load() {
		s.pauseMu.Lock()
		ch := s.pauseCh
		s.pauseMu.Unlock()
		if ch == nil {
			return nil
		}
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-ch:
		}
	}
	return ctx.Err()
}

// Run executes the full scan pipeline across all targets and returns sorted results.
func (s *Scanner) Run(ctx context.Context, targets []ProxyTarget, handler ResultHandler) []ScanResult {
	startTime := time.Now()
	total := len(targets)
	if total == 0 {
		if handler != nil {
			handler.OnProgress(ScanProgress{Phase: "completed"})
		}
		return nil
	}

	jobs := make(chan ProxyTarget, total)
	for _, t := range targets {
		jobs <- t
	}
	close(jobs)

	var (
		wg        sync.WaitGroup
		mu        sync.Mutex
		results   = make([]ScanResult, 0, total)
		completed int
		passed    int
		failed    int
		bestPing  int64 = math.MaxInt64
		bestIP    string
	)

	workerCount := s.cfg.Concurrency
	if workerCount > total {
		workerCount = total
	}

	emitProgress := func(phase string) {
		if handler == nil {
			return
		}
		bp := bestPing
		if bp == math.MaxInt64 {
			bp = 0
		}
		handler.OnProgress(ScanProgress{
			Total:      total,
			Completed:  completed,
			Passed:     passed,
			Failed:     failed,
			BestPingMs: bp,
			BestIP:     bestIP,
			ElapsedMs:  time.Since(startTime).Milliseconds(),
			Phase:      phase,
			IsPaused:   s.isPaused.Load(),
		})
	}

	for i := 0; i < workerCount; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for target := range jobs {
				if err := s.waitIfPaused(ctx); err != nil {
					return
				}
				if ctx.Err() != nil {
					return
				}

				res := s.probeTarget(ctx, target)

				mu.Lock()
				results = append(results, res)
				completed++
				if res.Passed {
					passed++
					if res.AvgLatencyMs > 0 && res.AvgLatencyMs < bestPing {
						bestPing = res.AvgLatencyMs
						bestIP = fmt.Sprintf("%s:%d", res.IP, res.Port)
					}
				} else {
					failed++
				}
				if handler != nil {
					handler.OnResult(res)
				}
				emitProgress("scanning")
				mu.Unlock()
			}
		}()
	}

	wg.Wait()

	// Phase 2: Optional download speed test on best passing candidates
	if s.cfg.EnableSpeedTest && ctx.Err() == nil {
		var passingIdx []int
		for i := range results {
			if results[i].Passed {
				passingIdx = append(passingIdx, i)
			}
		}
		sort.Slice(passingIdx, func(i, j int) bool {
			return results[passingIdx[i]].AvgLatencyMs < results[passingIdx[j]].AvgLatencyMs
		})
		if s.cfg.SpeedTestTopN > 0 && len(passingIdx) > s.cfg.SpeedTestTopN {
			passingIdx = passingIdx[:s.cfg.SpeedTestTopN]
		}

		if len(passingIdx) > 0 {
			var speedSum float64
			var speedCount int
			speedSem := make(chan struct{}, 4) // Keep speed test concurrency low for accurate Mbps
			var swg sync.WaitGroup

			for _, idx := range passingIdx {
				if err := s.waitIfPaused(ctx); err != nil {
					break
				}
				if ctx.Err() != nil {
					break
				}
				swg.Add(1)
				speedSem <- struct{}{}
				go func(resultIndex int) {
					defer swg.Done()
					defer func() { <-speedSem }()

					res := &results[resultIndex]
					mbps := s.measureDownloadMbps(ctx, res.IP, res.Port)

					mu.Lock()
					res.DownloadMbps = math.Round(mbps*100) / 100
					if s.cfg.MinDownloadMbps > 0 && res.DownloadMbps < s.cfg.MinDownloadMbps {
						res.Passed = false
						res.FailReason = fmt.Sprintf("speed %.2f < %.2f Mbps", res.DownloadMbps, s.cfg.MinDownloadMbps)
						passed--
						failed++
					}
					res.Score = ComputeScore(*res)
					if mbps > 0 {
						speedSum += mbps
						speedCount++
					}
					if handler != nil {
						handler.OnResult(*res)
						avgSpd := 0.0
						if speedCount > 0 {
							avgSpd = math.Round((speedSum/float64(speedCount))*100) / 100
						}
						bp := bestPing
						if bp == math.MaxInt64 {
							bp = 0
						}
						handler.OnProgress(ScanProgress{
							Total:      total,
							Completed:  completed,
							Passed:     passed,
							Failed:     failed,
							BestPingMs: bp,
							BestIP:     bestIP,
							AvgSpeed:   avgSpd,
							ElapsedMs:  time.Since(startTime).Milliseconds(),
							Phase:      "speedtest",
							IsPaused:   s.isPaused.Load(),
						})
					}
					mu.Unlock()
				}(idx)
			}
			swg.Wait()
		}
	}

	sort.Slice(results, func(i, j int) bool {
		if results[i].Passed != results[j].Passed {
			return results[i].Passed
		}
		if results[i].Score != results[j].Score {
			return results[i].Score > results[j].Score
		}
		return results[i].AvgLatencyMs < results[j].AvgLatencyMs
	})

	finalPhase := "completed"
	if ctx.Err() != nil {
		finalPhase = "cancelled"
	}
	emitProgress(finalPhase)
	return results
}

func (s *Scanner) probeTarget(ctx context.Context, target ProxyTarget) ScanResult {
	res := ScanResult{
		IP:            target.IP,
		Port:          target.Port,
		Country:       target.Country,
		Provider:      target.Provider,
		TimestampUnix: time.Now().Unix(),
	}

	addr := net.JoinHostPort(target.IP, strconv.Itoa(target.Port))
	timeout := time.Duration(s.cfg.TimeoutMs) * time.Millisecond

	// Step 1: Multi-probe TCP connect for min/avg/max latency, jitter, and packet loss
	var samples []int64
	for i := 0; i < s.cfg.ProbeCount; i++ {
		if ctx.Err() != nil {
			res.FailReason = "cancelled"
			return res
		}
		d := net.Dialer{Timeout: timeout}
		t0 := time.Now()
		conn, err := d.DialContext(ctx, "tcp", addr)
		if err == nil {
			samples = append(samples, time.Since(t0).Milliseconds())
			_ = conn.Close()
		}
		if i+1 < s.cfg.ProbeCount && s.cfg.ProbeDelayMs > 0 {
			select {
			case <-ctx.Done():
				res.FailReason = "cancelled"
				return res
			case <-time.After(time.Duration(s.cfg.ProbeDelayMs) * time.Millisecond):
			}
		}
	}

	lossPct := float64(s.cfg.ProbeCount-len(samples)) / float64(s.cfg.ProbeCount) * 100.0
	res.PacketLossPct = math.Round(lossPct*10) / 10

	if len(samples) == 0 {
		res.FailReason = "tcp_timeout"
		return res
	}

	var sum, minL, maxL int64
	minL = math.MaxInt64
	for _, v := range samples {
		sum += v
		if v < minL {
			minL = v
		}
		if v > maxL {
			maxL = v
		}
	}
	avgL := sum / int64(len(samples))

	var jitterSum int64
	for i := 1; i < len(samples); i++ {
		diff := samples[i] - samples[i-1]
		if diff < 0 {
			diff = -diff
		}
		jitterSum += diff
	}
	var jitter int64
	if len(samples) > 1 {
		jitter = jitterSum / int64(len(samples)-1)
	}

	res.MinLatencyMs = minL
	res.AvgLatencyMs = avgL
	res.MaxLatencyMs = maxL
	res.JitterMs = jitter

	if s.cfg.MaxLatencyMs > 0 && avgL > int64(s.cfg.MaxLatencyMs) {
		res.FailReason = fmt.Sprintf("latency %dms > %dms", avgL, s.cfg.MaxLatencyMs)
		return res
	}
	if s.cfg.MaxJitterMs > 0 && jitter > int64(s.cfg.MaxJitterMs) {
		res.FailReason = fmt.Sprintf("jitter %dms > %dms", jitter, s.cfg.MaxJitterMs)
		return res
	}
	if s.cfg.MaxPacketLossPct >= 0 && res.PacketLossPct > s.cfg.MaxPacketLossPct {
		res.FailReason = fmt.Sprintf("loss %.1f%% > %.1f%%", res.PacketLossPct, s.cfg.MaxPacketLossPct)
		return res
	}

	// Step 2: Optional TLS handshake & Cloudflare cdn-cgi/trace verification
	if s.cfg.VerifyTLS || s.cfg.VerifyTrace {
		tlsCfg := s.buildTLSConfig()
		dialer := &net.Dialer{Timeout: timeout}
		t0 := time.Now()
		rawConn, err := dialer.DialContext(ctx, "tcp", addr)
		if err != nil {
			res.FailReason = "tls_dial_failed"
			return res
		}
		_ = rawConn.SetDeadline(time.Now().Add(timeout))
		tlsConn := tls.Client(rawConn, tlsCfg)
		if err := tlsConn.HandshakeContext(ctx); err != nil {
			_ = rawConn.Close()
			res.FailReason = "tls_handshake_failed"
			return res
		}
		res.TLSHandshakeMs = time.Since(t0).Milliseconds()
		state := tlsConn.ConnectionState()
		res.TLSVersion = tlsVersionName(state.Version)
		res.NegotiatedALPN = state.NegotiatedProtocol

		if s.cfg.VerifyTrace {
			traceMap, err := fetchTraceOverConn(tlsConn, s.cfg.TraceHost, s.cfg.TracePath)
			if err == nil && traceMap["colo"] != "" {
				res.TraceOK = true
				res.Colo = traceMap["colo"]
				res.TraceLoc = traceMap["loc"]
				res.TraceIP = traceMap["ip"]
			}
		}
		_ = tlsConn.Close()

		if s.cfg.RequireCFTrace && !res.TraceOK {
			res.FailReason = "cf_trace_failed"
			return res
		}
		if len(s.cfg.AllowedColos) > 0 && res.Colo != "" {
			matched := false
			for _, c := range s.cfg.AllowedColos {
				if strings.EqualFold(strings.TrimSpace(c), res.Colo) {
					matched = true
					break
				}
			}
			if !matched {
				res.FailReason = fmt.Sprintf("colo %s filtered", res.Colo)
				return res
			}
		}
	}

	res.Passed = true
	res.Score = ComputeScore(res)
	return res
}

func (s *Scanner) buildTLSConfig() *tls.Config {
	minVer := uint16(tls.VersionTLS12)
	if s.cfg.MinTLSVersion == "1.3" {
		minVer = tls.VersionTLS13
	}
	var nextProtos []string
	for _, p := range strings.Split(s.cfg.ALPN, ",") {
		p = strings.TrimSpace(p)
		if p != "" {
			nextProtos = append(nextProtos, p)
		}
	}
	if len(nextProtos) == 0 {
		nextProtos = []string{"http/1.1"}
	}
	return &tls.Config{
		ServerName:         s.cfg.SNI,
		InsecureSkipVerify: s.cfg.InsecureSkipCert,
		MinVersion:         minVer,
		NextProtos:         nextProtos,
	}
}

func fetchTraceOverConn(conn net.Conn, host, path string) (map[string]string, error) {
	reqStr := fmt.Sprintf("GET %s HTTP/1.1\r\nHost: %s\r\nUser-Agent: EdgePulseScanner/1.0\r\nConnection: close\r\n\r\n", path, host)
	if _, err := conn.Write([]byte(reqStr)); err != nil {
		return nil, err
	}
	reader := bufio.NewReader(conn)
	resp, err := http.ReadResponse(reader, nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 8192))
	if err != nil {
		return nil, err
	}
	kv := make(map[string]string)
	for _, line := range strings.Split(string(body), "\n") {
		if idx := strings.IndexByte(line, '='); idx > 0 {
			kv[strings.TrimSpace(line[:idx])] = strings.TrimSpace(line[idx+1:])
		}
	}
	return kv, nil
}

func (s *Scanner) measureDownloadMbps(ctx context.Context, ip string, port int) float64 {
	addr := net.JoinHostPort(ip, strconv.Itoa(port))
	transport := &http.Transport{
		TLSClientConfig: s.buildTLSConfig(),
		DialContext: func(dctx context.Context, network, _ string) (net.Conn, error) {
			d := net.Dialer{Timeout: time.Duration(s.cfg.TimeoutMs) * time.Millisecond}
			return d.DialContext(dctx, "tcp", addr)
		},
		DisableKeepAlives: true,
	}
	client := &http.Client{
		Transport: transport,
		Timeout:   time.Duration(s.cfg.SpeedTestTimeoutS) * time.Second,
	}
	url := fmt.Sprintf("https://%s%s", s.cfg.SpeedTestHost, s.cfg.SpeedTestPath)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return 0
	}
	req.Header.Set("User-Agent", "EdgePulseScanner/1.0")

	t0 := time.Now()
	resp, err := client.Do(req)
	if err != nil {
		return 0
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 400 {
		return 0
	}

	n, err := io.Copy(io.Discard, io.LimitReader(resp.Body, int64(s.cfg.SpeedTestBytes)*2))
	if err != nil && n == 0 {
		return 0
	}
	elapsed := time.Since(t0).Seconds()
	if elapsed <= 0 {
		return 0
	}
	// Megabits per second
	return (float64(n) * 8.0) / (elapsed * 1_000_000.0)
}

// ComputeScore calculates a 0..100 composite quality score.
func ComputeScore(r ScanResult) float64 {
	if !r.Passed {
		return 0
	}
	// Latency component (0..50): 0ms = 50, 1000ms+ = 0
	latScore := math.Max(0, 50.0*(1.0-float64(r.AvgLatencyMs)/1000.0))
	// Jitter component (0..15): 0ms = 15, 300ms+ = 0
	jitScore := math.Max(0, 15.0*(1.0-float64(r.JitterMs)/300.0))
	// Packet loss component (0..15): 0% = 15, 50%+ = 0
	lossScore := math.Max(0, 15.0*(1.0-r.PacketLossPct/50.0))
	// Trace verification bonus (0..10)
	traceScore := 0.0
	if r.TraceOK {
		traceScore = 10.0
	}
	// Download speed bonus (0..10): 50 Mbps+ = 10
	spdScore := math.Min(10.0, (r.DownloadMbps/50.0)*10.0)

	total := latScore + jitScore + lossScore + traceScore + spdScore
	return math.Round(total*10) / 10
}

func tlsVersionName(v uint16) string {
	switch v {
	case tls.VersionTLS13:
		return "TLS 1.3"
	case tls.VersionTLS12:
		return "TLS 1.2"
	case tls.VersionTLS11:
		return "TLS 1.1"
	case tls.VersionTLS10:
		return "TLS 1.0"
	default:
		return "Unknown"
	}
}
