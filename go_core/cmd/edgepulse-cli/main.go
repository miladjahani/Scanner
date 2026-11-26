package main

import (
	"context"
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"

	edgepulse "github.com/edgepulse-scanner/core"
)

type cliHandler struct{}

func (c *cliHandler) OnProgress(p edgepulse.ScanProgress) {
	fmt.Fprintf(os.Stderr, "\r[%s] %d/%d | Passed: %d | Best: %dms (%s)   ",
		p.Phase, p.Completed, p.Total, p.Passed, p.BestPingMs, p.BestIP)
}

func (c *cliHandler) OnResult(r edgepulse.ScanResult) {}

func main() {
	inFile := flag.String("in", "", "Path to input file (IP:Port, CSV, or CIDR per line)")
	outFile := flag.String("out", "results.csv", "Output file path (.csv, .json, or .txt)")
	country := flag.String("country", "XX", "Default country code for untagged IPs")
	concurrency := flag.Int("c", 64, "Number of concurrent workers")
	timeoutMs := flag.Int("timeout", 2500, "Timeout per probe in ms")
	probes := flag.Int("probes", 3, "TCP probes per IP")
	sni := flag.String("sni", "speed.cloudflare.com", "TLS SNI hostname")
	trace := flag.Bool("trace", true, "Verify Cloudflare /cdn-cgi/trace")
	speed := flag.Bool("speed", false, "Run download speed test on top IPs")
	topN := flag.Int("top", 15, "Number of top IPs to speed test")
	maxLat := flag.Int("max-lat", 1200, "Max average latency in ms")
	flag.Parse()

	if *inFile == "" {
		fmt.Fprintln(os.Stderr, "Usage: edgepulse-cli -in proxies.txt [-out results.csv] [-c 64] [-speed]")
		os.Exit(1)
	}

	rawBytes, err := os.ReadFile(*inFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to read %s: %v\n", *inFile, err)
		os.Exit(1)
	}

	cfg := edgepulse.DefaultScanConfig()
	cfg.Concurrency = *concurrency
	cfg.TimeoutMs = *timeoutMs
	cfg.ProbeCount = *probes
	cfg.SNI = *sni
	cfg.TraceHost = *sni
	cfg.VerifyTrace = *trace
	cfg.EnableSpeedTest = *speed
	cfg.SpeedTestTopN = *topN
	cfg.MaxLatencyMs = *maxLat

	targets := edgepulse.ParseTargetsText(string(rawBytes), *country, cfg.DefaultPorts, cfg.MaxIPsPerCIDR)
	fmt.Fprintf(os.Stderr, "Loaded %d unique targets. Starting EdgePulse Go Scanner...\n", len(targets))

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	scanner := edgepulse.NewScanner(cfg)
	results := scanner.Run(ctx, targets, &cliHandler{})
	fmt.Fprintln(os.Stderr, "\nScan complete.")

	if err := writeOutput(*outFile, results); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to write output: %v\n", err)
		os.Exit(1)
	}
	fmt.Fprintf(os.Stderr, "Saved %d results to %s\n", len(results), *outFile)
}

func writeOutput(path string, results []edgepulse.ScanResult) error {
	lower := strings.ToLower(path)
	if strings.HasSuffix(lower, ".json") {
		b, err := json.MarshalIndent(results, "", "  ")
		if err != nil {
			return err
		}
		return os.WriteFile(path, b, 0644)
	}
	if strings.HasSuffix(lower, ".txt") {
		var lines []string
		for _, r := range results {
			if r.Passed {
				lines = append(lines, fmt.Sprintf("%s:%d", r.IP, r.Port))
			}
		}
		return os.WriteFile(path, []byte(strings.Join(lines, "\n")+"\n"), 0644)
	}

	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()

	w := csv.NewWriter(f)
	_ = w.Write([]string{"IP", "Port", "Country", "Provider", "Passed", "AvgMs", "JitterMs", "LossPct", "Colo", "DownloadMbps", "Score"})
	for _, r := range results {
		_ = w.Write([]string{
			r.IP,
			strconv.Itoa(r.Port),
			r.Country,
			r.Provider,
			strconv.FormatBool(r.Passed),
			strconv.FormatInt(r.AvgLatencyMs, 10),
			strconv.FormatInt(r.JitterMs, 10),
			fmt.Sprintf("%.1f", r.PacketLossPct),
			r.Colo,
			fmt.Sprintf("%.2f", r.DownloadMbps),
			fmt.Sprintf("%.1f", r.Score),
		})
	}
	w.Flush()
	return w.Error()
}
