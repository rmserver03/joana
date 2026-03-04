// Package types defines shared types for the Joana system
package types

import (
	"context"
	"time"
)

// Message represents an incoming message from any channel
type Message struct {
	ID        string
	Channel   string
	Sender    Sender
	Text      string
	Timestamp time.Time
	Context   map[string]interface{}
}

// Sender represents a message sender
type Sender struct {
	ID       string
	Name     string
	IsAdmin  bool
	Metadata map[string]string
}

// Response represents a response to be sent
type Response struct {
	ID        string
	Channel   string
	Recipient string
	Text      string
	Mode      OperationMode
	Priority  int
}

// OperationMode represents the 6 J.A.R.V.I.S. operation modes
type OperationMode int

const (
	ModeStandard OperationMode = iota
	ModeAutonomous
	ModeCrisis
	ModeResearch
	ModeLearning
	ModeBackground
)

func (m OperationMode) String() string {
	return [...]string{
		"Standard",
		"Autonomous",
		"Crisis",
		"Research",
		"Learning",
		"Background",
	}[m]
}

// ReasoningContext contains context for the reasoning engine
type ReasoningContext struct {
	Context      context.Context
	Message      *Message
	CurrentMode  OperationMode
	WorkingMemory *WorkingMemory
	UserModel    *UserModel
}

// WorkingMemory represents the working memory layer
type WorkingMemory struct {
	SessionID    string
	Messages     []*Message
	ContextVars  map[string]interface{}
	CreatedAt    time.Time
	LastAccessed time.Time
}

// UserModel represents the operator memory layer (Rafael-specific)
type UserModel struct {
	UserID            string
	CognitiveStyle    string
	CommunicationPref CommunicationPreferences
	WorkPatterns      WorkPatterns
	DecisionPatterns  DecisionPatterns
	KnownBiases       []string
	ExpertiseAreas    []string
	RelationshipNetwork map[string]Relationship
}

// CommunicationPreferences defines user communication preferences
type CommunicationPreferences struct {
	DetailLevel   string
	Format        string
	Frequency     string
	Tone          string
}

// WorkPatterns defines user work patterns
type WorkPatterns struct {
	ProductiveHours []string
	EnergyCycles    []string
	FocusTimes      []string
}

// DecisionPatterns defines user decision patterns
type DecisionPatterns struct {
	Speed          string
	RiskAversion   float64
	PrimaryCriteria []string
}

// Relationship defines a relationship in the user's network
type Relationship struct {
	Name        string
	Role        string
	Importance  int
	Protocols   []string
}