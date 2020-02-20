package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/user"
	"runtime"
	"strings"
	"time"

	"github.com/gorilla/mux"

	"rsc.io/quote/v3"
)

// const variables
const (
	f          = "info.txt"
	name       = "anz-technical-zeyu"
	ms         = "🚀 ☸️  🐳 🐧 (time is %s, golang version: %s, %s)"
	versionURL = "/version"
)

// response struct to be used for /version endpoint
type response struct {
	Version     string `json:"version"`
	CommitSha   string `json:"lastcommitsha"`
	Description string `json:"description"`
	Message     string `json:"message"`
}

// GetEnv gets environment variable with fallback value if not exists
func GetEnv(key string) string {
	defaultValues := map[string]string{
		"PORT":      "8000",
		"BIND_HOST": "0.0.0.0",
	}

	value, exists := os.LookupEnv(key)
	if !exists {
		value, _ = defaultValues[key]
	}

	return value
}

// FormatMessage formats input message nicely
func FormatMessage(msg string) string {
	_msg := strings.Split(msg, "\n")

	for i, m := range _msg {
		_msg[i] = "  " + m
	}

	_msg = append(append([]string{"\"" + name + "\"" + ": ["}, _msg...), "]")
	return strings.Join(_msg, "\n")
}

func main() {
	fmt.Printf("starting http server (%s)", GetEnv("BIND_HOST")+":"+GetEnv("PORT"))

	r := mux.NewRouter()
	r.HandleFunc("/", helloworld)
	r.HandleFunc("/go", goquote)
	r.HandleFunc("/opt", opttruth)
	r.HandleFunc(versionURL, version)

	s := &http.Server{
		Handler:      r,
		Addr:         GetEnv("BIND_HOST") + ":" + GetEnv("PORT"),
		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}

	log.Fatal(s.ListenAndServe())
}

func helloworld(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, quote.HelloV3())
}

func goquote(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, quote.GoV3())
}

func opttruth(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, quote.GoV3())
}

func version(w http.ResponseWriter, r *http.Request) {
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

	w.WriteHeader(http.StatusOK)

	u, err := user.Current()

	res := response{}
	res.Version = version
	res.CommitSha = sha
	res.Description = description

	if err == nil {
		if u.Uid == "0" || u.Gid == "0" {
			res.Message = fmt.Sprintf(ms, time.Now().UTC().Format(time.RFC3339), runtime.Version(), fmt.Sprintf("my name is %s {Username: %s, Uid: %s, Gid: %s}, if there're vulnerability in this application, it's possible to exploit this host through me", u.Name, u.Username, u.Uid, u.Gid))
			resJSON, _ := json.MarshalIndent(res, "", "  ")
			fmt.Fprintf(w, FormatMessage(string(resJSON)))
		} else {
			res.Message = fmt.Sprintf(ms, time.Now().UTC().Format(time.RFC3339), runtime.Version(), fmt.Sprintf("my name is %s {Username: %s, Uid: %s, Gid: %s}, i don't have root permission, don't waste time to hack this host through me", u.Name, u.Username, u.Uid, u.Gid))
			resJSON, _ := json.MarshalIndent(res, "", "  ")
			fmt.Fprintf(w, FormatMessage(string(resJSON)))
		}
	} else {
		res.Message = fmt.Sprintf(ms, time.Now().UTC().Format(time.RFC3339), runtime.Version(), "i don't know who i am, it's unlikely to hack this host through me")
		resJSON, _ := json.MarshalIndent(res, "", "  ")
		fmt.Fprintf(w, FormatMessage(string(resJSON)))
	}
}
