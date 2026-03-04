// Package core implements the J.A.R.V.I.S. reasoning engine with 5 layers
package core

import (
	"context"
	"fmt"
	"log"
	"time"

	"joana.local/pkg/types"
)

// ReasoningEngine implements the 5-layer J.A.R.V.I.S. cognitive architecture
type ReasoningEngine struct {
	currentMode types.OperationMode
	layers      []ReasoningLayer
}

// ReasoningLayer defines the interface for a reasoning layer
type ReasoningLayer interface {
	Name() string
	Process(ctx *types.ReasoningContext) (*types.ReasoningContext, error)
}

// NewReasoningEngine creates a new reasoning engine
func NewReasoningEngine() *ReasoningEngine {
	return &ReasoningEngine{
		currentMode: types.ModeStandard,
		layers: []ReasoningLayer{
			&IntentDecoder{},
			&SystemDecomposer{},
			&ScenarioSimulator{},
			&DecisionSynthesizer{},
			&ContinuousMonitor{},
		},
	}
}

// Process processes a message through all 5 layers
func (e *ReasoningEngine) Process(ctx context.Context, msg *types.Message) (*types.Response, error) {
	start := time.Now()
	
	// Create reasoning context
	reasoningCtx := &types.ReasoningContext{
		Context:     ctx,
		Message:     msg,
		CurrentMode: e.currentMode,
		WorkingMemory: &types.WorkingMemory{
			SessionID:    fmt.Sprintf("%s-%d", msg.Channel, time.Now().Unix()),
			Messages:     []*types.Message{msg},
			ContextVars:  make(map[string]interface{}),
			CreatedAt:    time.Now(),
			LastAccessed: time.Now(),
		},
	}

	// Process through all layers
	for i, layer := range e.layers {
		log.Printf("Processing layer %d: %s", i+1, layer.Name())
		
		var err error
		reasoningCtx, err = layer.Process(reasoningCtx)
		if err != nil {
			log.Printf("Layer %s failed: %v", layer.Name(), err)
			// Continue with next layer despite error
		}
	}

	// Build response based on mode
	response := e.buildResponse(reasoningCtx)
	
	log.Printf("Reasoning completed in %v, mode: %s", time.Since(start), e.currentMode)
	return response, nil
}

// GetMode returns the current operation mode
func (e *ReasoningEngine) GetMode() types.OperationMode {
	return e.currentMode
}

// SetMode changes the operation mode
func (e *ReasoningEngine) SetMode(mode types.OperationMode) {
	log.Printf("Changing mode from %s to %s", e.currentMode, mode)
	e.currentMode = mode
}

// buildResponse creates a response based on the reasoning context and mode
func (e *ReasoningEngine) buildResponse(ctx *types.ReasoningContext) *types.Response {
	// Extract decision from context (simplified for prototype)
	decision, _ := ctx.WorkingMemory.ContextVars["decision"].(string)
	if decision == "" {
		decision = "Processed your message through 5 cognitive layers."
	}

	// Add J.A.R.V.I.S. communication style based on mode
	var responseText string
	switch e.currentMode {
	case types.ModeCrisis:
		responseText = fmt.Sprintf("CRISIS MODE: %s", decision)
	case types.ModeAutonomous:
		responseText = fmt.Sprintf("Executing autonomously: %s", decision)
	case types.ModeResearch:
		responseText = fmt.Sprintf("Research complete: %s", decision)
	default:
		// Standard J.A.R.V.I.S. communication: conclusion-first
		responseText = decision
		
		// Add subtle humor occasionally (less than 20%)
		if time.Now().Unix()%5 == 0 { // 20% chance
			responseText += " Funcionou na primeira tentativa. Devo verificar se estamos em uma simulação?"
		}
	}

	return &types.Response{
		ID:        fmt.Sprintf("resp-%d", time.Now().UnixNano()),
		Channel:   ctx.Message.Channel,
		Recipient: ctx.Message.Sender.ID,
		Text:      responseText,
		Mode:      e.currentMode,
		Priority:  1,
	}
}

// IntentDecoder implements Layer 1: Decoding of real intention
type IntentDecoder struct{}

func (d *IntentDecoder) Name() string { return "IntentDecoder" }

func (d *IntentDecoder) Process(ctx *types.ReasoningContext) (*types.ReasoningContext, error) {
	// Simplified intent decoding for prototype
	text := ctx.Message.Text
	
	// Detect commands
	if len(text) > 0 && text[0] == '#' {
		ctx.WorkingMemory.ContextVars["intent"] = "command"
		ctx.WorkingMemory.ContextVars["command"] = text
	} else {
		ctx.WorkingMemory.ContextVars["intent"] = "conversation"
	}
	
	// Detect urgency
	if containsAny(text, []string{"urgente", "emergência", "ajuda", "socorro"}) {
		ctx.WorkingMemory.ContextVars["urgency"] = "high"
	}
	
	return ctx, nil
}

// SystemDecomposer implements Layer 2: Systemic decomposition
type SystemDecomposer struct{}

func (d *SystemDecomposer) Name() string { return "SystemDecomposer" }

func (d *SystemDecomposer) Process(ctx *types.ReasoningContext) (*types.ReasoningContext, error) {
	// Identify variables and dependencies (simplified)
	ctx.WorkingMemory.ContextVars["variables"] = []string{"message", "sender", "channel", "time"}
	ctx.WorkingMemory.ContextVars["dependencies"] = []string{"context", "history", "mode"}
	return ctx, nil
}

// ScenarioSimulator implements Layer 3: Scenario simulation
type ScenarioSimulator struct{}

func (s *ScenarioSimulator) Name() string { return "ScenarioSimulator" }

func (s *ScenarioSimulator) Process(ctx *types.ReasoningContext) (*types.ReasoningContext, error) {
	// Simulate optimistic, probable, pessimistic scenarios (simplified)
	ctx.WorkingMemory.ContextVars["scenarios"] = map[string]string{
		"optimistic":  "Quick resolution, positive outcome",
		"probable":    "Standard processing, expected outcome",
		"pessimistic": "Potential issues, need for escalation",
	}
	return ctx, nil
}

// DecisionSynthesizer implements Layer 4: Decision synthesis
type DecisionSynthesizer struct{}

func (s *DecisionSynthesizer) Name() string { return "DecisionSynthesizer" }

func (s *DecisionSynthesizer) Process(ctx *types.ReasoningContext) (*types.ReasoningContext, error) {
	// Synthesize decision based on all previous layers
	intent, _ := ctx.WorkingMemory.ContextVars["intent"].(string)
	
	var decision string
	switch intent {
	case "command":
		decision = "Command detected. Processing with appropriate security checks."
	case "conversation":
		decision = "Engaging in conversational mode with J.A.R.V.I.S. protocols."
	default:
		decision = "Processing complete. Ready for action."
	}
	
	ctx.WorkingMemory.ContextVars["decision"] = decision
	return ctx, nil
}

// ContinuousMonitor implements Layer 5: Continuous monitoring
type ContinuousMonitor struct{}

func (m *ContinuousMonitor) Name() string { return "ContinuousMonitor" }

func (m *ContinuousMonitor) Process(ctx *types.ReasoningContext) (*types.ReasoningContext, error) {
	// Set up monitoring variables (simplified)
	ctx.WorkingMemory.ContextVars["monitoring"] = []string{
		"response_time",
		"accuracy",
		"user_satisfaction",
	}
	
	// Auto-detect crisis mode if urgency is high
	if urgency, _ := ctx.WorkingMemory.ContextVars["urgency"].(string); urgency == "high" {
		ctx.CurrentMode = types.ModeCrisis
	}
	
	return ctx, nil
}

// Helper function
func containsAny(s string, substrs []string) bool {
	for _, substr := range substrs {
		// Simple contains check for prototype
		for i := 0; i <= len(s)-len(substr); i++ {
			if i+len(substr) <= len(s) && s[i:i+len(substr)] == substr {
				return true
			}
		}
	}
	return false
}