package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gorilla/mux"

	"rsc.io/quote/v3"
)

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

func main() {
	fmt.Println("starting http server ")
	r := mux.NewRouter()
	r.HandleFunc("/", helloworld)
	r.HandleFunc("/go", goquote)
	r.HandleFunc("/opt", opttruth)
	r.HandleFunc("/version", version)

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

}
