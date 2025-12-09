package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"runtime"
	"time"
)

type HealthResponse struct {
	Status    string    `json:"status"`
	Service   string    `json:"service"`
	Timestamp time.Time `json:"timestamp"`
}

type User struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
}

type Item struct {
	ID    int     `json:"id"`
	Name  string  `json:"name"`
	Price float64 `json:"price"`
}

func main() {
	port := getEnv("PORT", "8080")
	
	http.HandleFunc("/", homeHandler)
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/ready", readyHandler)
	http.HandleFunc("/api/users", usersHandler)
	http.HandleFunc("/api/items", itemsHandler)
	http.HandleFunc("/api/env", envHandler)
	
	log.Printf("Go service starting on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func homeHandler(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}
	
	response := map[string]interface{}{
		"message": "Welcome to Go Service",
		"endpoints": []string{
			"/health",
			"/ready",
			"/api/users",
			"/api/items",
			"/api/env",
		},
		"service": "go-service",
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	response := HealthResponse{
		Status:    "UP",
		Service:   "go-service",
		Timestamp: time.Now(),
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func readyHandler(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"status": "READY",
		"ready":  true,
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func usersHandler(w http.ResponseWriter, r *http.Request) {
	users := []User{
		{ID: 1, Name: "Alice", Email: "alice@example.com"},
		{ID: 2, Name: "Bob", Email: "bob@example.com"},
		{ID: 3, Name: "Charlie", Email: "charlie@example.com"},
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"users": users})
}

func itemsHandler(w http.ResponseWriter, r *http.Request) {
	items := []Item{
		{ID: 1, Name: "Go Book", Price: 39.99},
		{ID: 2, Name: "Go Mug", Price: 15.49},
		{ID: 3, Name: "Go Sticker", Price: 2.99},
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"items": items})
}

func envHandler(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"goVersion":   runtime.Version(),
		"numCPU":      runtime.NumCPU(),
		"goroutines":  runtime.NumGoroutine(),
		"environment": getEnv("ENV", "development"),
		"hostname":    getEnv("HOSTNAME", "unknown"),
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}