package edgepulse

import (
	"context"
	"net"
	"strconv"
	"testing"
)

func TestParseTargetsText(t *testing.T) {
	input := `
# comment line
1.1.1.1:443
1.0.0.1 8443 DE
18.184.55.249,443,DE,AWS
162.158.82.0/30
1.1.1.1:443
`
	targets := ParseTargetsText(input, "US", []int{443}, 16)
	if len(targets) != 5 {
		t.Fatalf("expected 5 unique targets, got %d: %+v", len(targets), targets)
	}
	if targets[2].Country != "DE" || targets[2].Provider != "AWS" {
		t.Fatalf("unexpected CSV parse result: %+v", targets[2])
	}
}

func TestExpandCIDR(t *testing.T) {
	ips := ExpandCIDR("192.0.2.0/29", 10)
	if len(ips) != 6 {
		t.Fatalf("expected 6 usable hosts for /29, got %d", len(ips))
	}
}

func TestScannerLoopbackTCP(t *testing.T) {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen failed: %v", err)
	}
	defer ln.Close()

	go func() {
		for {
			c, err := ln.Accept()
			if err != nil {
				return
			}
			_ = c.Close()
		}
	}()

	host, portStr, _ := net.SplitHostPort(ln.Addr().String())
	port, _ := strconv.Atoi(portStr)

	cfg := DefaultScanConfig()
	cfg.Concurrency = 2
	cfg.ProbeCount = 2
	cfg.ProbeDelayMs = 5
	cfg.VerifyTLS = false
	cfg.VerifyTrace = false
	cfg.EnableSpeedTest = false

	sc := NewScanner(cfg)
	results := sc.Run(context.Background(), []ProxyTarget{
		{IP: host, Port: port, Country: "DE", Provider: "LoopbackTest"},
	}, nil)

	if len(results) != 1 || !results[0].Passed {
		t.Fatalf("expected loopback TCP scan to pass, got %+v", results)
	}
	if results[0].Score <= 0 {
		t.Fatalf("expected positive score, got %f", results[0].Score)
	}
}
