package edgepulse

import (
	"bufio"
	"encoding/binary"
	"net"
	"strconv"
	"strings"
)

// ProxyTarget represents a single IP:Port endpoint with optional country/provider metadata.
type ProxyTarget struct {
	IP       string `json:"ip"`
	Port     int    `json:"port"`
	Country  string `json:"country"`
	Provider string `json:"provider"`
}

// ScanConfig holds every configurable scanner parameter exposed to the Android/Flutter UI.
type ScanConfig struct {
	// Concurrency & Timing
	Concurrency   int `json:"concurrency"`     // Parallel worker goroutines (1..500)
	TimeoutMs     int `json:"timeout_ms"`      // Per-probe connect/TLS/HTTP timeout in ms
	ProbeCount    int `json:"probe_count"`     // Number of TCP probes per IP for avg/jitter/loss
	ProbeDelayMs  int `json:"probe_delay_ms"`  // Delay between consecutive probes in ms
	MaxIPsPerCIDR int `json:"max_ips_per_cidr"` // Cap when expanding CIDR blocks

	// Protocol, Ports & TLS
	DefaultPorts     []int  `json:"default_ports"`      // Fallback ports when input has no port
	VerifyTLS        bool   `json:"verify_tls"`         // Perform TLS handshake check
	SNI              string `json:"sni"`                // TLS Server Name Indication
	ALPN             string `json:"alpn"`               // Comma-separated ALPNs e.g. "h2,http/1.1"
	MinTLSVersion    string `json:"min_tls_version"`    // "1.2" or "1.3"
	InsecureSkipCert bool   `json:"insecure_skip_cert"` // Skip cert chain verification for raw IPs

	// Cloudflare Trace Verification
	VerifyTrace bool   `json:"verify_trace"` // Request /cdn-cgi/trace over TLS
	TraceHost   string `json:"trace_host"`   // Host header for trace (e.g. cloudflare.com)
	TracePath   string `json:"trace_path"`   // Path for trace (default /cdn-cgi/trace)

	// Speed Test
	EnableSpeedTest   bool   `json:"enable_speed_test"`    // Run HTTP download speed test on passing IPs
	SpeedTestBytes    int    `json:"speed_test_bytes"`     // Payload size in bytes (e.g. 524288 = 512KB)
	SpeedTestHost     string `json:"speed_test_host"`      // e.g. speed.cloudflare.com
	SpeedTestPath     string `json:"speed_test_path"`      // e.g. /__down?bytes=524288
	SpeedTestTopN     int    `json:"speed_test_top_n"`     // 0 = test all passing, >0 = speed-test only best N
	SpeedTestTimeoutS int    `json:"speed_test_timeout_s"` // Timeout for download test in seconds

	// Quality Thresholds & Filters
	MaxLatencyMs     int      `json:"max_latency_ms"`     // Drop results slower than this (0 = no limit)
	MaxJitterMs      int      `json:"max_jitter_ms"`      // Drop results with jitter above this (0 = no limit)
	MaxPacketLossPct float64  `json:"max_packet_loss_pct"` // Drop results with loss % above this
	MinDownloadMbps  float64  `json:"min_download_mbps"`  // Drop results below this speed (0 = no limit)
	AllowedColos     []string `json:"allowed_colos"`      // Optional IATA colo whitelist (e.g. ["FRA","AMS"])
	RequireCFTrace   bool     `json:"require_cf_trace"`   // Require valid Cloudflare colo in trace
}

// DefaultScanConfig returns balanced defaults suitable for mobile networks.
func DefaultScanConfig() ScanConfig {
	return ScanConfig{
		Concurrency:       48,
		TimeoutMs:         2500,
		ProbeCount:        3,
		ProbeDelayMs:      80,
		MaxIPsPerCIDR:     256,
		DefaultPorts:      []int{443},
		VerifyTLS:         true,
		SNI:               "speed.cloudflare.com",
		ALPN:              "h2,http/1.1",
		MinTLSVersion:     "1.2",
		InsecureSkipCert:  true,
		VerifyTrace:       true,
		TraceHost:         "speed.cloudflare.com",
		TracePath:         "/cdn-cgi/trace",
		EnableSpeedTest:   false,
		SpeedTestBytes:    524288,
		SpeedTestHost:     "speed.cloudflare.com",
		SpeedTestPath:     "/__down?bytes=524288",
		SpeedTestTopN:     15,
		SpeedTestTimeoutS: 8,
		MaxLatencyMs:      1200,
		MaxJitterMs:       400,
		MaxPacketLossPct:  35.0,
		MinDownloadMbps:   0,
		AllowedColos:      nil,
		RequireCFTrace:    false,
	}
}

// ScanResult holds detailed benchmark metrics for a single scanned ProxyTarget.
type ScanResult struct {
	IP             string  `json:"ip"`
	Port           int     `json:"port"`
	Country        string  `json:"country"`
	Provider       string  `json:"provider"`
	Passed         bool    `json:"passed"`
	FailReason     string  `json:"fail_reason,omitempty"`
	MinLatencyMs   int64   `json:"min_latency_ms"`
	AvgLatencyMs   int64   `json:"avg_latency_ms"`
	MaxLatencyMs   int64   `json:"max_latency_ms"`
	JitterMs       int64   `json:"jitter_ms"`
	PacketLossPct  float64 `json:"packet_loss_pct"`
	TLSHandshakeMs int64   `json:"tls_handshake_ms"`
	TLSVersion     string  `json:"tls_version,omitempty"`
	NegotiatedALPN string  `json:"negotiated_alpn,omitempty"`
	TraceOK        bool    `json:"trace_ok"`
	Colo           string  `json:"colo,omitempty"`
	TraceLoc       string  `json:"trace_loc,omitempty"`
	TraceIP        string  `json:"trace_ip,omitempty"`
	DownloadMbps   float64 `json:"download_mbps"`
	Score          float64 `json:"score"`
	TimestampUnix  int64   `json:"timestamp_unix"`
}

// ScanProgress reports real-time scanning counters to the Flutter UI.
type ScanProgress struct {
	Total       int     `json:"total"`
	Completed   int     `json:"completed"`
	Passed      int     `json:"passed"`
	Failed      int     `json:"failed"`
	BestPingMs  int64   `json:"best_ping_ms"`
	BestIP      string  `json:"best_ip"`
	AvgSpeed    float64 `json:"avg_speed_mbps"`
	ElapsedMs   int64   `json:"elapsed_ms"`
	Phase       string  `json:"phase"` // "scanning", "speedtest", "completed", "cancelled"
	IsPaused    bool    `json:"is_paused"`
}

// Endpoint renders an IPv4 or IPv6 host:port pair, bracketing IPv6 literals.
func Endpoint(ip string, port int) string {
	return net.JoinHostPort(strings.Trim(ip, "[]"), strconv.Itoa(port))
}

// ParseTargetsText parses flexible input lines:
//   - "1.2.3.4:443"
//   - "1.2.3.4 443"
//   - "1.2.3.4,443,DE,Hetzner"
//   - "162.158.82.0/24"
//   - "[2606:4700:1000::1]:443"
//   - "2606:4700:1000::/48"
func ParseTargetsText(raw string, defaultCountry string, defaultPorts []int, maxPerCIDR int) []ProxyTarget {
	if len(defaultPorts) == 0 {
		defaultPorts = []int{443}
	}
	if maxPerCIDR <= 0 {
		maxPerCIDR = 256
	}
	seen := make(map[string]struct{})
	var out []ProxyTarget

	addTarget := func(ip string, port int, cc, prov string) {
		ip = strings.Trim(strings.TrimSpace(ip), "[]")
		parsed := net.ParseIP(ip)
		if parsed == nil || port <= 0 || port > 65535 {
			return
		}
		ip = parsed.String()
		key := Endpoint(ip, port)
		if _, ok := seen[key]; ok {
			return
		}
		seen[key] = struct{}{}
		if cc == "" {
			cc = defaultCountry
		}
		out = append(out, ProxyTarget{
			IP:       ip,
			Port:     port,
			Country:  strings.ToUpper(strings.TrimSpace(cc)),
			Provider: strings.TrimSpace(prov),
		})
	}

	sc := bufio.NewScanner(strings.NewReader(raw))
	for sc.Scan() {
		line := strings.TrimSpace(sc.Text())
		if line == "" || strings.HasPrefix(line, "#") || strings.HasPrefix(line, "//") {
			continue
		}

		// CSV format: IP,Port,Country,Provider
		if strings.Contains(line, ",") {
			parts := strings.Split(line, ",")
			ip := strings.TrimSpace(parts[0])
			port := defaultPorts[0]
			if len(parts) >= 2 {
				if p, err := strconv.Atoi(strings.TrimSpace(parts[1])); err == nil {
					port = p
				}
			}
			cc := defaultCountry
			if len(parts) >= 3 {
				cc = strings.TrimSpace(parts[2])
			}
			prov := ""
			if len(parts) >= 4 {
				prov = strings.TrimSpace(strings.Join(parts[3:], ","))
			}
			addTarget(ip, port, cc, prov)
			continue
		}

		// CIDR expansion: e.g. 162.158.82.0/24
		if strings.Contains(line, "/") {
			ips := ExpandCIDR(line, maxPerCIDR)
			for _, ip := range ips {
				for _, p := range defaultPorts {
					addTarget(ip, p, defaultCountry, "CIDR")
				}
			}
			continue
		}

		// IP:Port format (IPv4 or [IPv6]:Port)
		if host, portStr, err := net.SplitHostPort(line); err == nil {
			if p, err := strconv.Atoi(portStr); err == nil {
				addTarget(host, p, defaultCountry, "")
				continue
			}
		}

		// Space-separated: "1.2.3.4 443" or "1.2.3.4 443 DE"
		fields := strings.Fields(line)
		if len(fields) >= 2 {
			if p, err := strconv.Atoi(fields[1]); err == nil {
				cc := defaultCountry
				if len(fields) >= 3 {
					cc = fields[2]
				}
				addTarget(fields[0], p, cc, "")
				continue
			}
		}

		// Bare IP
		if net.ParseIP(fields[0]) != nil {
			for _, p := range defaultPorts {
				addTarget(fields[0], p, defaultCountry, "")
			}
		}
	}
	return out
}

// ExpandCIDR expands an IPv4 or IPv6 CIDR block into up to maxCount usable host IPs.
func ExpandCIDR(cidr string, maxCount int) []string {
	_, ipNet, err := net.ParseCIDR(strings.TrimSpace(cidr))
	if err != nil {
		return nil
	}
	if ipv4 := ipNet.IP.To4(); ipv4 == nil {
		return expandCIDR6(ipNet, maxCount)
	} else {
		return expandCIDR4(ipNet, maxCount)
	}
}

// expandCIDR6 samples an IPv6 block, which is far too large to enumerate.
func expandCIDR6(ipNet *net.IPNet, maxCount int) []string {
	base := ipNet.IP.To16()
	if base == nil {
		return nil
	}
	if maxCount <= 0 {
		maxCount = 256
	}
	current := make(net.IP, net.IPv6len)
	copy(current, base)
	var ips []string
	for i := 0; i < maxCount; i++ {
		next := make(net.IP, net.IPv6len)
		copy(next, current)
		ips = append(ips, next.String())
		// Advance by one address.
		for j := net.IPv6len - 1; j >= 0; j-- {
			current[j]++
			if current[j] != 0 {
				break
			}
		}
		if !ipNet.Contains(current) {
			break
		}
	}
	return ips
}

func expandCIDR4(ipNet *net.IPNet, maxCount int) []string {
	ipv4 := ipNet.IP.To4()
	if ipv4 == nil {
		return nil
	}
	maskOnes, maskBits := ipNet.Mask.Size()
	if maskBits != 32 {
		return nil
	}
	totalHosts := 1 << uint(32-maskOnes)
	start := binary.BigEndian.Uint32(ipv4)

	var ips []string
	// Skip network and broadcast addresses for /30 and larger blocks
	firstOffset := 0
	lastOffset := totalHosts - 1
	if totalHosts > 2 {
		firstOffset = 1
		lastOffset = totalHosts - 2
	}

	step := 1
	usable := lastOffset - firstOffset + 1
	if usable > maxCount && maxCount > 0 {
		step = usable / maxCount
		if step < 1 {
			step = 1
		}
	}

	for offset := firstOffset; offset <= lastOffset && (maxCount <= 0 || len(ips) < maxCount); offset += step {
		ipUint := start + uint32(offset)
		ip := make(net.IP, 4)
		binary.BigEndian.PutUint32(ip, ipUint)
		ips = append(ips, ip.String())
	}
	return ips
}
