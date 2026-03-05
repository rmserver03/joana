package types

import (
	"time"
)

// IncomingMessage represents a message from a communication channel
type IncomingMessage struct {
	Channel   string
	ChatID    string
	UserID    string
	Username  string
	Text      string
	Timestamp time.Time
}

// Orchestrator interface defines methods for message processing
type Orchestrator interface {
	ProcessMessage(msg IncomingMessage) error
}
