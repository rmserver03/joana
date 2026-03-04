// Package orchestrator implements the central orchestrator for Joana
package orchestrator

import (
	"context"
	"fmt"
	"log"
	"sync"
	"time"

	"joana.local/internal/channels"
	"joana.local/internal/core"
	"joana.local/internal/memory"
	"joana.local/internal/mode"
	"joana.local/pkg/types"
)

// Orchestrator is the central orchestrator for the Joana system
type Orchestrator struct {
	reasoningEngine *core.ReasoningEngine
	memoryManager   *memory.MemoryManager
	modeManager     *mode.ModeManager
	channels        map[string]channels.Channel
	config          Config
	running         bool
	mu              sync.RWMutex
}

// Config holds orchestrator configuration
type Config struct {
	MemoryDBPath string
	TelegramToken string
}

// NewOrchestrator creates a new orchestrator
func NewOrchestrator(config Config) (*Orchestrator, error) {
	// Initialize memory manager
	memManager, err := memory.NewMemoryManager(config.MemoryDBPath)
	if err != nil {
		return nil, fmt.Errorf("failed to create memory manager: %w", err)
	}

	// Initialize reasoning engine
	reasoningEngine := core.NewReasoningEngine()

	// Initialize mode manager
	modeManager := mode.NewModeManager()

	o := &Orchestrator{
		reasoningEngine: reasoningEngine,
		memoryManager:   memManager,
		modeManager:     modeManager,
		channels:        make(map[string]channels.Channel),
		config:          config,
		running:         false,
	}

	return o, nil
}

// Start starts the orchestrator and all channels
func (o *Orchestrator) Start(ctx context.Context) error {
	o.mu.Lock()
	defer o.mu.Unlock()

	if o.running {
		return fmt.Errorf("orchestrator already running")
	}

	// Initialize Telegram channel if token provided
	if o.config.TelegramToken != "" {
		tgConfig := channels.TelegramConfig{
			Token:   o.config.TelegramToken,
			Timeout: 60,
			Debug:   false,
		}

		tgChannel, err := channels.NewTelegramChannel(tgConfig)
		if err != nil {
			return fmt.Errorf("failed to create Telegram channel: %w", err)
		}

		o.channels["telegram"] = tgChannel

		// Start Telegram channel
		if err := tgChannel.Start(); err != nil {
			return fmt.Errorf("failed to start Telegram channel: %w", err)
		}

		log.Println("Telegram channel initialized and started")
	}

	// Start message processing
	o.running = true
	go o.processMessages(ctx)

	log.Println("Orchestrator started successfully")
	return nil
}

// Stop stops the orchestrator and all channels
func (o *Orchestrator) Stop(ctx context.Context) error {
	o.mu.Lock()
	defer o.mu.Unlock()

	if !o.running {
		return fmt.Errorf("orchestrator not running")
	}

	// Stop all channels
	for name, channel := range o.channels {
		if err := channel.Stop(); err != nil {
			log.Printf("Failed to stop channel %s: %v", name, err)
		}
	}

	// Close memory manager
	if err := o.memoryManager.Close(); err != nil {
		log.Printf("Failed to close memory manager: %v", err)
	}

	o.running = false
	log.Println("Orchestrator stopped")

	return nil
}

// processMessages processes incoming messages from all channels
func (o *Orchestrator) processMessages(ctx context.Context) {
	// Collect message channels from all active channels
	messageChans := make([]<-chan *channels.IncomingMessage, 0, len(o.channels))
	
	for name, channel := range o.channels {
		msgChan := channel.ReceiveMessages()
		messageChans = append(messageChans, msgChan)
		log.Printf("Listening for messages from channel: %s", name)
	}

	// Process messages from all channels
	for o.running {
		select {
		case <-ctx.Done():
			o.running = false
			return
		
		default:
			// Check all message channels
			for _, msgChan := range messageChans {
				select {
				case incomingMsg := <-msgChan:
					if incomingMsg != nil && incomingMsg.InternalMessage != nil {
						go o.handleMessage(ctx, incomingMsg.InternalMessage)
					}
				default:
					// No message in this channel, continue
				}
			}
			
			// Small sleep to prevent CPU spinning
			time.Sleep(10 * time.Millisecond)
		}
	}
}

// handleMessage handles a single incoming message
func (o *Orchestrator) handleMessage(ctx context.Context, msg *types.Message) {
	startTime := time.Now()
	log.Printf("Handling message from %s: %s", msg.Sender.Name, msg.Text)

	// Update working memory
	sessionID := fmt.Sprintf("%s-%s", msg.Channel, msg.Sender.ID)
	o.memoryManager.UpdateWorkingMemory(sessionID, msg)

	// Get or create user model (not used in this function but kept for future expansion)
	_, err := o.memoryManager.GetOperatorModel(msg.Sender.ID)
	if err != nil {
		log.Printf("Failed to get user model: %v", err)
		// Could create default user model here if needed
	}

	// Process through reasoning engine
	response, err := o.reasoningEngine.Process(ctx, msg)
	if err != nil {
		log.Printf("Reasoning engine failed: %v", err)
		response = &types.Response{
			ID:        fmt.Sprintf("err-%d", time.Now().UnixNano()),
			Channel:   msg.Channel,
			Recipient: msg.Sender.ID,
			Text:      "Erro no processamento. Por favor, tente novamente.",
			Mode:      types.ModeStandard,
			Priority:  1,
		}
	}

	// Store episodic event
	o.memoryManager.StoreEpisodicEvent(
		"message_processed",
		fmt.Sprintf("Processed message from %s: %s", msg.Sender.Name, msg.Text),
		map[string]interface{}{
			"response_time_ms": time.Since(startTime).Milliseconds(),
			"mode":             response.Mode.String(),
			"channel":          msg.Channel,
		},
		1, // Normal importance
	)

	// Send response through appropriate channel
	if err := o.sendResponse(response); err != nil {
		log.Printf("Failed to send response: %v", err)
	}

	// Update user model based on interaction
	o.updateUserModel(msg, response, time.Since(startTime))

	log.Printf("Message handling completed in %v", time.Since(startTime))
}

// sendResponse sends a response through the appropriate channel
func (o *Orchestrator) sendResponse(response *types.Response) error {
	channel, exists := o.channels[response.Channel]
	if !exists {
		return fmt.Errorf("channel not found: %s", response.Channel)
	}

	// Convert response to message
	msg := &types.Message{
		ID:        response.ID,
		Channel:   response.Channel,
		Sender: types.Sender{
			ID:      "joana",
			Name:    "Joana",
			IsAdmin: true,
		},
		Text:      response.Text,
		Timestamp: time.Now(),
		Context: map[string]interface{}{
			"mode":     response.Mode.String(),
			"priority": response.Priority,
		},
	}

	return channel.Send(response.Recipient, msg)
}

// updateUserModel updates the user model based on interaction
func (o *Orchestrator) updateUserModel(msg *types.Message, response *types.Response, processingTime time.Duration) {
	// Get current user model
	userModel, err := o.memoryManager.GetOperatorModel(msg.Sender.ID)
	if err != nil {
		log.Printf("Failed to get user model for update: %v", err)
		return
	}

	// Update cognitive style based on interaction patterns
	// This is simplified for prototype
	if processingTime < 100*time.Millisecond {
		userModel.CognitiveStyle = "quick_decision"
	} else if processingTime > 1*time.Second {
		userModel.CognitiveStyle = "analytical"
	} else {
		userModel.CognitiveStyle = "balanced"
	}

	// Update the model in memory
	if err := o.memoryManager.UpdateOperatorModel(msg.Sender.ID, userModel); err != nil {
		log.Printf("Failed to update user model: %v", err)
	}
}

// GetStatus returns the current status of the orchestrator
func (o *Orchestrator) GetStatus() map[string]interface{} {
	o.mu.RLock()
	defer o.mu.RUnlock()

	status := map[string]interface{}{
		"running":    o.running,
		"channels":   len(o.channels),
		"mode":       o.reasoningEngine.GetMode().String(),
		"started_at": time.Now().Format(time.RFC3339),
	}

	// Add channel details
	channelDetails := make(map[string]interface{})
	for name := range o.channels {
		channelDetails[name] = "active"
	}
	status["channel_details"] = channelDetails

	return status
}

// SetMode changes the operation mode
func (o *Orchestrator) SetMode(newMode types.OperationMode) {
	o.reasoningEngine.SetMode(newMode)
	log.Printf("Orchestrator mode changed to: %s", newMode)
}

// GetMode returns the current operation mode
func (o *Orchestrator) GetMode() types.OperationMode {
	return o.reasoningEngine.GetMode()
}