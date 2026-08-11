package api

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func registerRecuritRoutes(h *HumanHandler) *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("POST /api/v1/qtrecurit/resumes", h.ImportResume)
	mux.HandleFunc("POST /api/v1/qtrecurit/interviews", h.CreateInterview)
	return mux
}

func TestResumeImport(t *testing.T) {
	s, cleanup := testSetup(t)
	defer cleanup()

	h := NewHumanHandler(s)
	mux := registerRecuritRoutes(h)

	t.Run("Import resume", func(t *testing.T) {
		body := `{"candidate_name":"Charlie","position":"Developer","stage":"new"}`
		req := httptest.NewRequest("POST", "/api/v1/qtrecurit/resumes", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusCreated {
			t.Fatalf("expected 201, got %d: %s", rec.Code, rec.Body.String())
		}

		var item map[string]any
		json.Unmarshal(rec.Body.Bytes(), &item)
		if item["candidate_name"] != "Charlie" {
			t.Errorf("expected candidate_name=Charlie, got %v", item["candidate_name"])
		}
	})

	t.Run("Missing candidate name returns 400", func(t *testing.T) {
		body := `{}`
		req := httptest.NewRequest("POST", "/api/v1/qtrecurit/resumes", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if rec.Code != http.StatusBadRequest {
			t.Errorf("expected 400, got %d", rec.Code)
		}
	})
}

func TestInterviewCreate(t *testing.T) {
	s, cleanup := testSetup(t)
	defer cleanup()

	h := NewHumanHandler(s)
	mux := registerRecuritRoutes(h)

	t.Run("Create interview", func(t *testing.T) {
		body := `{"candidate":"Charlie","interviewer":"Alice","date":"2026-06-20"}`
		req := httptest.NewRequest("POST", "/api/v1/qtrecurit/interviews", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if rec.Code != http.StatusCreated {
			t.Fatalf("expected 201, got %d: %s", rec.Code, rec.Body.String())
		}
	})

	t.Run("Missing candidate returns 400", func(t *testing.T) {
		body := `{}`
		req := httptest.NewRequest("POST", "/api/v1/qtrecurit/interviews", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if rec.Code != http.StatusBadRequest {
			t.Errorf("expected 400, got %d", rec.Code)
		}
	})
}
