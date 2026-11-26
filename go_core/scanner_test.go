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

func TestParseTargetsIPv6(t *testing.T) {
	input := `
[2606:4700:1000::6812:1a]:443
2606:4700:1000::1 8443 DE
2606:4700:1000::/126
`
	targets := ParseTargetsText(input, "US", []int{443}, 8)
	if len(targets) != 6 {
		t.Fatalf("expected 6 unique IPv6 targets, got %d: %+v", len(targets), targets)
	}
	if targets[0].IP != "2606:4700:1000::6812:1a" || targets[0].Port != 443 {
		t.Fatalf("unexpected bracketed IPv6 parse: %+v", targets[0])
	}
	if targets[1].Country != "DE" || targets[1].Port != 8443 {
		t.Fatalf("unexpected IPv6 space-separated parse: %+v", targets[1])
	}
}

func TestEndpointBracketsIPv6(t *testing.T) {
	if got := Endpoint("2606:4700:1000::1", 443); got != "[2606:4700:1000::1]:443" {
		t.Fatalf("unexpected IPv6 endpoint: %s", got)
	}
	if got := Endpoint("1.1.1.1", 443); got != "1.1.1.1:443" {
		t.Fatalf("unexpected IPv4 endpoint: %s", got)
	}
}

func TestExpandCIDRIPv6(t *testing.T) {
	ips := ExpandCIDR("2606:4700:1000::/126", 8)
	if len(ips) != 4 {
		t.Fatalf("expected 4 distinct IPv6 hosts for /126, got %d: %v", len(ips), ips)
	}
	if ips[0] == ips[3] {
		t.Fatalf("expected distinct IPv6 hosts, got %v", ips)
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
