package main

import (
	"testing"
)

func TestGetEnv(t *testing.T) {
	if GetEnv("BIND_HOST") != "0.0.0.0" {
		t.Fatal("Expected: default GetEnv(\"BIND_HOST\") == " + "dev")
	}

	if GetEnv("PORT") != "8000" {
		t.Fatal("Expected: default GetEnv(\"PORT\") == " + "8000")
	}
}

func TestFormatMessage(t *testing.T) {
	m := "🚀 ☸️  🐳 🐧\n🚀 ☸️  🐳 🐧"
	e := "\"" + name + "\": [\n" + "  🚀 ☸️  🐳 🐧\n  🚀 ☸️  🐳 🐧\n]"
	if FormatMessage(m) != e {
		t.Fatal("Expected: FormatMessage(\"" + m + "\") == \"" + e + "\"")
	}

	m = "🚀 🚀 ☸️  🐳 🐧\n🚀 🚀 🚀 ☸️  🐳 🐧\n🚀 🚀 🚀 🚀 ☸️  🐳 🐧"
	e = "\"" + name + "\": [\n" + "  🚀 🚀 ☸️  🐳 🐧\n  🚀 🚀 🚀 ☸️  🐳 🐧\n  🚀 🚀 🚀 🚀 ☸️  🐳 🐧\n]"
	if FormatMessage(m) != e {
		t.Fatal("Expected: FormatMessage(\"" + m + "\") == \"" + e + "\"")
	}
}
