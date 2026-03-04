// Package memory implements the 5-layer J.A.R.V.I.S. memory system
package memory

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	_ "github.com/mattn/go-sqlite3"
	"joana.local/pkg/types"
)

// MemoryManager manages all 5 memory layers
type MemoryManager struct {
	db           *sql.DB
	workingCache map[string]*types.WorkingMemory
}

// NewMemoryManager creates a new memory manager
func NewMemoryManager(dbPath string) (*MemoryManager, error) {
	db, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Initialize database schema
	if err := initSchema(db); err != nil {
		return nil, fmt.Errorf("failed to initialize schema: %w", err)
	}

	return &MemoryManager{
		db:           db,
		workingCache: make(map[string]*types.WorkingMemory),
	}, nil
}

// initSchema creates the database tables for all memory layers
func initSchema(db *sql.DB) error {
	// Episodic memory: significant events
	_, err := db.Exec(`
		CREATE TABLE IF NOT EXISTS episodic_memory (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			timestamp DATETIME NOT NULL,
			event_type TEXT NOT NULL,
			description TEXT NOT NULL,
			context_json TEXT,
			importance INTEGER DEFAULT 1,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		return fmt.Errorf("failed to create episodic_memory: %w", err)
	}

	// Semantic memory: factual knowledge
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS semantic_memory (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			domain TEXT NOT NULL,
			key TEXT NOT NULL,
			value TEXT NOT NULL,
			confidence REAL DEFAULT 1.0,
			source TEXT,
			last_accessed DATETIME,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			UNIQUE(domain, key)
		)
	`)
	if err != nil {
		return fmt.Errorf("failed to create semantic_memory: %w", err)
	}

	// Procedural memory: optimized routines
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS procedural_memory (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			skill_name TEXT NOT NULL,
			pattern_json TEXT NOT NULL,
			success_rate REAL DEFAULT 0.0,
			execution_count INTEGER DEFAULT 0,
			avg_duration_ms INTEGER,
			last_used DATETIME,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		return fmt.Errorf("failed to create procedural_memory: %w", err)
	}

	// Operator memory: Rafael-specific model
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS operator_memory (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			user_id TEXT NOT NULL UNIQUE,
			cognitive_style TEXT,
			communication_prefs_json TEXT,
			work_patterns_json TEXT,
			decision_patterns_json TEXT,
			known_biases_json TEXT,
			expertise_areas_json TEXT,
			relationship_network_json TEXT,
			last_updated DATETIME,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		return fmt.Errorf("failed to create operator_memory: %w", err)
	}

	log.Println("Memory schema initialized successfully")
	return nil
}

// GetWorkingMemory retrieves or creates working memory for a session
func (m *MemoryManager) GetWorkingMemory(sessionID string) *types.WorkingMemory {
	if wm, exists := m.workingCache[sessionID]; exists {
		wm.LastAccessed = time.Now()
		return wm
	}

	// Create new working memory
	wm := &types.WorkingMemory{
		SessionID:    sessionID,
		Messages:     []*types.Message{},
		ContextVars:  make(map[string]interface{}),
		CreatedAt:    time.Now(),
		LastAccessed: time.Now(),
	}
	m.workingCache[sessionID] = wm
	return wm
}

// UpdateWorkingMemory updates working memory with new message
func (m *MemoryManager) UpdateWorkingMemory(sessionID string, msg *types.Message) {
	wm := m.GetWorkingMemory(sessionID)
	wm.Messages = append(wm.Messages, msg)
	wm.LastAccessed = time.Now()
	
	// Keep only last 100 messages to prevent memory bloat
	if len(wm.Messages) > 100 {
		wm.Messages = wm.Messages[len(wm.Messages)-100:]
	}
}

// StoreEpisodicEvent stores a significant event in episodic memory
func (m *MemoryManager) StoreEpisodicEvent(eventType, description string, context map[string]interface{}, importance int) error {
	contextJSON := "{}" // Simplified for prototype
	if context != nil {
		// In real implementation, serialize to JSON
		contextJSON = fmt.Sprintf("%v", context)
	}

	_, err := m.db.Exec(`
		INSERT INTO episodic_memory (timestamp, event_type, description, context_json, importance)
		VALUES (?, ?, ?, ?, ?)
	`, time.Now(), eventType, description, contextJSON, importance)
	
	if err != nil {
		return fmt.Errorf("failed to store episodic event: %w", err)
	}
	
	log.Printf("Stored episodic event: %s - %s", eventType, description)
	return nil
}

// GetEpisodicEvents retrieves episodic events by type and time range
func (m *MemoryManager) GetEpisodicEvents(eventType string, startTime, endTime time.Time) ([]map[string]interface{}, error) {
	query := `
		SELECT timestamp, event_type, description, context_json, importance
		FROM episodic_memory
		WHERE timestamp BETWEEN ? AND ?
	`
	if eventType != "" {
		query += " AND event_type = ?"
	}
	query += " ORDER BY timestamp DESC LIMIT 100"

	var rows *sql.Rows
	var err error
	
	if eventType != "" {
		rows, err = m.db.Query(query, startTime, endTime, eventType)
	} else {
		rows, err = m.db.Query(query, startTime, endTime)
	}
	
	if err != nil {
		return nil, fmt.Errorf("failed to query episodic events: %w", err)
	}
	defer rows.Close()

	var events []map[string]interface{}
	for rows.Next() {
		var timestamp time.Time
		var eventType, description, contextJSON string
		var importance int
		
		if err := rows.Scan(&timestamp, &eventType, &description, &contextJSON, &importance); err != nil {
			return nil, fmt.Errorf("failed to scan episodic event: %w", err)
		}
		
		events = append(events, map[string]interface{}{
			"timestamp":   timestamp,
			"event_type":  eventType,
			"description": description,
			"context":     contextJSON,
			"importance":  importance,
		})
	}

	return events, nil
}

// StoreSemanticKnowledge stores factual knowledge in semantic memory
func (m *MemoryManager) StoreSemanticKnowledge(domain, key, value, source string, confidence float64) error {
	_, err := m.db.Exec(`
		INSERT OR REPLACE INTO semantic_memory 
		(domain, key, value, confidence, source, last_accessed)
		VALUES (?, ?, ?, ?, ?, ?)
	`, domain, key, value, confidence, source, time.Now())
	
	if err != nil {
		return fmt.Errorf("failed to store semantic knowledge: %w", err)
	}
	
	log.Printf("Stored semantic knowledge: %s/%s = %s", domain, key, value)
	return nil
}

// GetSemanticKnowledge retrieves knowledge from semantic memory
func (m *MemoryManager) GetSemanticKnowledge(domain, key string) (string, float64, error) {
	var value string
	var confidence float64
	
	err := m.db.QueryRow(`
		SELECT value, confidence FROM semantic_memory
		WHERE domain = ? AND key = ?
	`, domain, key).Scan(&value, &confidence)
	
	if err == sql.ErrNoRows {
		return "", 0.0, nil
	}
	if err != nil {
		return "", 0.0, fmt.Errorf("failed to query semantic knowledge: %w", err)
	}
	
	// Update last accessed time
	m.db.Exec(`UPDATE semantic_memory SET last_accessed = ? WHERE domain = ? AND key = ?`,
		time.Now(), domain, key)
	
	return value, confidence, nil
}

// UpdateOperatorModel updates the operator (Rafael) memory model
func (m *MemoryManager) UpdateOperatorModel(userID string, model *types.UserModel) error {
	// Simplified for prototype - just store basic info
	_, err := m.db.Exec(`
		INSERT OR REPLACE INTO operator_memory 
		(user_id, cognitive_style, last_updated)
		VALUES (?, ?, ?)
	`, userID, model.CognitiveStyle, time.Now())
	
	if err != nil {
		return fmt.Errorf("failed to update operator model: %w", err)
	}
	
	log.Printf("Updated operator model for user: %s", userID)
	return nil
}

// GetOperatorModel retrieves the operator memory model
func (m *MemoryManager) GetOperatorModel(userID string) (*types.UserModel, error) {
	var cognitiveStyle string
	var lastUpdated time.Time
	
	err := m.db.QueryRow(`
		SELECT cognitive_style, last_updated FROM operator_memory
		WHERE user_id = ?
	`, userID).Scan(&cognitiveStyle, &lastUpdated)
	
	if err == sql.ErrNoRows {
		// Return default model
		return &types.UserModel{
			UserID:         userID,
			CognitiveStyle: "analytical", // Default assumption
		}, nil
	}
	if err != nil {
		return nil, fmt.Errorf("failed to query operator model: %w", err)
	}
	
	return &types.UserModel{
		UserID:         userID,
		CognitiveStyle: cognitiveStyle,
	}, nil
}

// Close closes the memory manager and database connection
func (m *MemoryManager) Close() error {
	if m.db != nil {
		return m.db.Close()
	}
	return nil
}

// Cleanup removes old working memory sessions
func (m *MemoryManager) Cleanup(maxAge time.Duration) {
	cutoff := time.Now().Add(-maxAge)
	for sessionID, wm := range m.workingCache {
		if wm.LastAccessed.Before(cutoff) {
			delete(m.workingCache, sessionID)
			log.Printf("Cleaned up old working memory session: %s", sessionID)
		}
	}
}