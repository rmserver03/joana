// Package channels implements communication channels for Joana
package channels

import (
	"joana.local/pkg/types"
)

// Channel defines the interface for communication channels
type Channel interface {
	// Send sends a message through the channel
	Send(to string, message *types.Message) error

	// ReceiveMessages returns a channel for receiving incoming messages
	ReceiveMessages() <-chan *IncomingMessage

	// Start starts the channel
	Start() error

	// Stop stops the channel
	Stop() error

	// IsRunning returns true if the channel is running
	IsRunning() bool

	// GetName returns the channel name
	GetName() string
}

// IncomingMessage wraps raw and internal message formats
type IncomingMessage struct {
	RawMessage      interface{}
	InternalMessage *types.Message
}
