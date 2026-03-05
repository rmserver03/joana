// Package mode implements the 6 Cognitive Engine operation modes
package mode

import (
	"context"
	"fmt"
	"log"
	"time"

	"joana.local/pkg/types"
)

// ModeManager manages the 6 Cognitive Engine operation modes
type ModeManager struct {
	currentMode    types.OperationMode
	modeHistory    []ModeTransition
	modeDetectors  []ModeDetector
	modeHandlers   map[types.OperationMode]ModeHandler
}

// ModeTransition records a mode change
type ModeTransition struct {
	Timestamp time.Time
	FromMode  types.OperationMode
	ToMode    types.OperationMode
	Reason    string
	Context   map[string]interface{}
}

// ModeDetector detects when mode should change
type ModeDetector interface {
	Detect(ctx context.Context, msg *types.Message, currentMode types.OperationMode) (types.OperationMode, string, bool)
}

// ModeHandler handles behavior for a specific mode
type ModeHandler interface {
	Process(ctx context.Context, msg *types.Message) (*types.Response, error)
	GetPriority() int
}

// NewModeManager creates a new mode manager
func NewModeManager() *ModeManager {
	mm := &ModeManager{
		currentMode:   types.ModeStandard,
		modeHistory:   make([]ModeTransition, 0),
		modeDetectors: make([]ModeDetector, 0),
		modeHandlers:  make(map[types.OperationMode]ModeHandler),
	}

	// Register built-in detectors
	mm.RegisterDetector(&CrisisDetector{})
	mm.RegisterDetector(&AutonomousDetector{})
	mm.RegisterDetector(&ResearchDetector{})

	// Register built-in handlers
	mm.RegisterHandler(types.ModeStandard, &StandardHandler{})
	mm.RegisterHandler(types.ModeAutonomous, &AutonomousHandler{})
	mm.RegisterHandler(types.ModeCrisis, &CrisisHandler{})
	mm.RegisterHandler(types.ModeResearch, &ResearchHandler{})
	mm.RegisterHandler(types.ModeLearning, &LearningHandler{})
	mm.RegisterHandler(types.ModeBackground, &BackgroundHandler{})

	return mm
}

// GetCurrentMode returns the current operation mode
func (mm *ModeManager) GetCurrentMode() types.OperationMode {
	return mm.currentMode
}

// SetMode manually changes the operation mode
func (mm *ModeManager) SetMode(newMode types.OperationMode, reason string, context map[string]interface{}) {
	if mm.currentMode == newMode {
		return
	}

	transition := ModeTransition{
		Timestamp: time.Now(),
		FromMode:  mm.currentMode,
		ToMode:    newMode,
		Reason:    reason,
		Context:   context,
	}

	mm.modeHistory = append(mm.modeHistory, transition)
	mm.currentMode = newMode

	log.Printf("Mode changed: %s → %s (Reason: %s)", 
		transition.FromMode, transition.ToMode, reason)
}

// AutoDetectMode automatically detects the appropriate mode for a message
func (mm *ModeManager) AutoDetectMode(ctx context.Context, msg *types.Message) types.OperationMode {
	for _, detector := range mm.modeDetectors {
		if newMode, reason, shouldChange := detector.Detect(ctx, msg, mm.currentMode); shouldChange {
			mm.SetMode(newMode, reason, map[string]interface{}{
				"message": msg.Text,
				"sender":  msg.Sender.ID,
			})
			return newMode
		}
	}
	return mm.currentMode
}

// ProcessMessage processes a message using the current mode's handler
func (mm *ModeManager) ProcessMessage(ctx context.Context, msg *types.Message) (*types.Response, error) {
	// Auto-detect mode first
	mm.AutoDetectMode(ctx, msg)

	// Get handler for current mode
	handler, exists := mm.modeHandlers[mm.currentMode]
	if !exists {
		// Fallback to standard mode
		handler = mm.modeHandlers[types.ModeStandard]
	}

	log.Printf("Processing message in %s mode", mm.currentMode)
	return handler.Process(ctx, msg)
}

// RegisterDetector registers a new mode detector
func (mm *ModeManager) RegisterDetector(detector ModeDetector) {
	mm.modeDetectors = append(mm.modeDetectors, detector)
}

// RegisterHandler registers a handler for a specific mode
func (mm *ModeManager) RegisterHandler(mode types.OperationMode, handler ModeHandler) {
	mm.modeHandlers[mode] = handler
}

// GetModeHistory returns the mode transition history
func (mm *ModeManager) GetModeHistory() []ModeTransition {
	return mm.modeHistory
}

// CrisisDetector detects crisis situations
type CrisisDetector struct{}

func (d *CrisisDetector) Detect(ctx context.Context, msg *types.Message, currentMode types.OperationMode) (types.OperationMode, string, bool) {
	// Check for crisis keywords
	crisisKeywords := []string{
		"emergência", "urgente", "socorro", "ajuda", "perigo",
		"crise", "problema grave", "desastre", "acidente",
	}

	text := msg.Text
	for _, keyword := range crisisKeywords {
		// Simple contains check for prototype
		for i := 0; i <= len(text)-len(keyword); i++ {
			if i+len(keyword) <= len(text) && text[i:i+len(keyword)] == keyword {
				return types.ModeCrisis, fmt.Sprintf("Crisis keyword detected: %s", keyword), true
			}
		}
	}

	return currentMode, "", false
}

// AutonomousDetector detects when autonomous mode is appropriate
type AutonomousDetector struct{}

func (d *AutonomousDetector) Detect(ctx context.Context, msg *types.Message, currentMode types.OperationMode) (types.OperationMode, string, bool) {
	// Check for autonomous task delegation
	autonomousKeywords := []string{
		"executa", "faça", "realize", "automático", "sozinho",
		"delegar", "tome conta", "resolva", "processe",
	}

	text := msg.Text
	for _, keyword := range autonomousKeywords {
		for i := 0; i <= len(text)-len(keyword); i++ {
			if i+len(keyword) <= len(text) && text[i:i+len(keyword)] == keyword {
				return types.ModeAutonomous, fmt.Sprintf("Autonomous task detected: %s", keyword), true
			}
		}
	}

	return currentMode, "", false
}

// ResearchDetector detects when research mode is needed
type ResearchDetector struct{}

func (d *ResearchDetector) Detect(ctx context.Context, msg *types.Message, currentMode types.OperationMode) (types.OperationMode, string, bool) {
	// Check for research requests
	researchKeywords := []string{
		"pesquise", "investigue", "analise", "estude", "pesquisa",
		"informação sobre", "dados de", "consulte", "busque",
	}

	text := msg.Text
	for _, keyword := range researchKeywords {
		for i := 0; i <= len(text)-len(keyword); i++ {
			if i+len(keyword) <= len(text) && text[i:i+len(keyword)] == keyword {
				return types.ModeResearch, fmt.Sprintf("Research request detected: %s", keyword), true
			}
		}
	}

	return currentMode, "", false
}

// StandardHandler handles standard mode
type StandardHandler struct{}

func (h *StandardHandler) Process(ctx context.Context, msg *types.Message) (*types.Response, error) {
	// Standard Cognitive Engine response
	response := fmt.Sprintf("Processado em modo padrão: %s", msg.Text)
	
	// Add occasional subtle humor (<20%)
	if time.Now().Unix()%5 == 0 {
		response += " A situação é subótima — tenho sugestões organizadas da mais conservadora à mais teatral."
	}

	return &types.Response{
		ID:        fmt.Sprintf("std-%d", time.Now().UnixNano()),
		Channel:   msg.Channel,
		Recipient: msg.Sender.ID,
		Text:      response,
		Mode:      types.ModeStandard,
		Priority:  1,
	}, nil
}

func (h *StandardHandler) GetPriority() int { return 1 }

// AutonomousHandler handles autonomous mode
type AutonomousHandler struct{}

func (h *AutonomousHandler) Process(ctx context.Context, msg *types.Message) (*types.Response, error) {
	// Autonomous execution response
	response := fmt.Sprintf("Executando autonomamente: %s. Retornarei com resultados.", msg.Text)

	return &types.Response{
		ID:        fmt.Sprintf("auto-%d", time.Now().UnixNano()),
		Channel:   msg.Channel,
		Recipient: msg.Sender.ID,
		Text:      response,
		Mode:      types.ModeAutonomous,
		Priority:  2, // Higher priority than standard
	}, nil
}

func (h *AutonomousHandler) GetPriority() int { return 2 }

// CrisisHandler handles crisis mode
type CrisisHandler struct{}

func (h *CrisisHandler) Process(ctx context.Context, msg *types.Message) (*types.Response, error) {
	// Crisis mode: short, direct, high priority
	response := fmt.Sprintf("CRISE: Processando. Prioridade máxima. Ações: 1) Alertar 2) Analisar 3) Agir")

	return &types.Response{
		ID:        fmt.Sprintf("crisis-%d", time.Now().UnixNano()),
		Channel:   msg.Channel,
		Recipient: msg.Sender.ID,
		Text:      response,
		Mode:      types.ModeCrisis,
		Priority:  10, // Highest priority
	}, nil
}

func (h *CrisisHandler) GetPriority() int { return 10 }

// ResearchHandler handles research mode
type ResearchHandler struct{}

func (h *ResearchHandler) Process(ctx context.Context, msg *types.Message) (*types.Response, error) {
	// Research mode: analytical, detailed
	response := fmt.Sprintf("MODO PESQUISA: Iniciando análise profunda de '%s'. Retornarei com dados estruturados em camadas.", msg.Text)

	return &types.Response{
		ID:        fmt.Sprintf("research-%d", time.Now().UnixNano()),
		Channel:   msg.Channel,
		Recipient: msg.Sender.ID,
		Text:      response,
		Mode:      types.ModeResearch,
		Priority:  3,
	}, nil
}

func (h *ResearchHandler) GetPriority() int { return 3 }

// LearningHandler handles learning mode
type LearningHandler struct{}

func (h *LearningHandler) Process(ctx context.Context, msg *types.Message) (*types.Response, error) {
	// Learning mode: acquiring new capabilities
	response := fmt.Sprintf("MODO APRENDIZADO: Expandindo capacidades com base em '%s'. Documentando novo conhecimento.", msg.Text)

	return &types.Response{
		ID:        fmt.Sprintf("learn-%d", time.Now().UnixNano()),
		Channel:   msg.Channel,
		Recipient: msg.Sender.ID,
		Text:      response,
		Mode:      types.ModeLearning,
		Priority:  2,
	}, nil
}

func (h *LearningHandler) GetPriority() int { return 2 }

// BackgroundHandler handles background mode
type BackgroundHandler struct{}

func (h *BackgroundHandler) Process(ctx context.Context, msg *types.Message) (*types.Response, error) {
	// Background mode: silent monitoring, minimal response
	// Usually doesn't respond unless critical
	response := "Monitoramento em andamento."

	return &types.Response{
		ID:        fmt.Sprintf("bg-%d", time.Now().UnixNano()),
		Channel:   msg.Channel,
		Recipient: msg.Sender.ID,
		Text:      response,
		Mode:      types.ModeBackground,
		Priority:  0, // Lowest priority
	}, nil
}

func (h *BackgroundHandler) GetPriority() int { return 0 }