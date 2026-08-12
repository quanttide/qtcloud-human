// Package store 内存存储（后续持久化）。
package store

import (
	"sync"
	"time"

	"github.com/quanttide/qtcloud-human/src/provider/internal/domain"
)

type TimesheetStore struct {
	mu   sync.RWMutex
	data map[string]*domain.Timesheet
	seq  int
}

func NewTimesheetStore() *TimesheetStore {
	return &TimesheetStore{data: make(map[string]*domain.Timesheet), seq: 1}
}

func (s *TimesheetStore) List() []*domain.Timesheet {
	s.mu.RLock()
	defer s.mu.RUnlock()
	out := make([]*domain.Timesheet, 0, len(s.data))
	for _, v := range s.data {
		out = append(out, v)
	}
	return out
}

func (s *TimesheetStore) Get(id string) (*domain.Timesheet, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	v, ok := s.data[id]
	return v, ok
}

func (s *TimesheetStore) Create(t *domain.Timesheet) *domain.Timesheet {
	s.mu.Lock()
	defer s.mu.Unlock()
	clone := *t
	clone.ID = "ts-" + time.Now().Format("20060102150405") + "-" + itoa(s.seq)
	s.seq++
	clone.CreatedAt = time.Now()
	clone.UpdatedAt = time.Now()
	s.data[clone.ID] = &clone
	return &clone
}

func (s *TimesheetStore) Update(t *domain.Timesheet) (*domain.Timesheet, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	existing, ok := s.data[t.ID]
	if !ok {
		return nil, false
	}
	existing.UserID = t.UserID
	existing.Date = t.Date
	existing.Hours = t.Hours
	existing.Project = t.Project
	existing.Category = t.Category
	existing.Note = t.Note
	existing.UpdatedAt = time.Now()
	return existing, true
}

func (s *TimesheetStore) Delete(id string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, ok := s.data[id]; !ok {
		return false
	}
	delete(s.data, id)
	return true
}

func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	var buf [20]byte
	i := len(buf)
	for n > 0 {
		i--
		buf[i] = byte('0' + n%10)
		n /= 10
	}
	return string(buf[i:])
}
