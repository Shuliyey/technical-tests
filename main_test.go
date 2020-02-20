package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"os"
	"reflect"
	"strings"
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

func TestVersionHandlerStatusCode(t *testing.T) {
	req, err := http.NewRequest("GET", "/version", nil)

	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(version)

	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Expecting \"version\" handler to return status code %d, returned status code %d instead.", http.StatusOK, rr.Code)
	}
}

func TestVersionHandlerResponse(t *testing.T) {
	req, err := http.NewRequest("GET", "/version", nil)

	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(version)

	handler.ServeHTTP(rr, req)

	var r map[string]interface{}

	if err := json.Unmarshal([]byte("{"+string(rr.Body.Bytes())+"}"), &r); err != nil {
		t.Errorf("Expecting \"version\" handler to return response in json format, returned (%s) instead", string(rr.Body.Bytes()))
	}

	info, err := ioutil.ReadFile(f)

	if err != nil {
		fmt.Printf("error reading file (%s), err: %s, exiting ...", f, err.Error())
		fmt.Println()
		os.Exit(1)
	}

	_info := strings.Split(string(info), "\n")
	version := _info[0]
	sha := _info[1]
	description := _info[2]

	rInfo := reflect.ValueOf(r[name]).Index(0).Interface().(map[string]interface{})

	if version != rInfo["version"] {
		t.Errorf("Expecting \"version\" handler response to returned version: %s, returned version: %s instead", version, rInfo["version"])
	}

	if sha != rInfo["lastcommitsha"] {
		t.Errorf("Expecting \"version\" handler response to returned lastcommitsha: %s, returned lastcommitsha: %s instead", sha, rInfo["lastcommitsha"])
	}

	if description != rInfo["description"] {
		t.Errorf("Expecting \"version\" handler response to returned description: %s, returned description: %s instead", description, rInfo["description"])
	}

}
