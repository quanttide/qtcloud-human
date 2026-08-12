// 人力资源云服务端：工时表 API。
package main

import (
	"log"
	"net/http"
	"os"

	"github.com/quanttide/qtcloud-human/src/provider/internal/handler"
	"github.com/quanttide/qtcloud-human/src/provider/internal/store"
)

func main() {
	ts := store.NewTimesheetStore()
	th := handler.NewTimesheetHandler(ts)

	mux := http.NewServeMux()
	mux.HandleFunc("GET /timesheets", th.List)
	mux.HandleFunc("POST /timesheets", th.Create)
	mux.HandleFunc("GET /timesheets/{id}", th.Get)
	mux.HandleFunc("PUT /timesheets/{id}", th.Update)
	mux.HandleFunc("DELETE /timesheets/{id}", th.Delete)
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(`{"status":"ok"}`))
	})

	addr := ":8080"
	if a := os.Getenv("LISTEN_ADDR"); a != "" {
		addr = a
	}
	log.Printf("qtcloud-human starting on %s", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatalf("server error: %v", err)
	}
}
