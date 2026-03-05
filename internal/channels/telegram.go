// Package channels implements communication channels for Joana
package channels

import (
	"context"
	"fmt"
	"log"
	"strconv"
	"time"

	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api/v5"
	"joana.local/pkg/types"
)

// TelegramChannel implements the Telegram communication channel
type TelegramChannel struct {
	bot        *tgbotapi.BotAPI
	updates    tgbotapi.UpdatesChannel
	config     TelegramConfig
	running    bool
	orchestrator types.Orchestrator
}

// TelegramConfig holds Telegram configuration
type TelegramConfig struct {
	Token   string
	ChatID  string
	Timeout int
	Debug   bool
}

// NewTelegramChannel creates a new Telegram channel
func NewTelegramChannel(config TelegramConfig, orchestrator types.Orchestrator) (*TelegramChannel, error) {
	bot, err := tgbotapi.NewBotAPI(config.Token)
	if err != nil {
		return nil, fmt.Errorf("failed to create Telegram bot: %w", err)
	}

	bot.Debug = config.Debug
	log.Printf("✅ Telegram bot authorized as @%s", bot.Self.UserName)

	u := tgbotapi.NewUpdate(0)
	u.Timeout = config.Timeout

	updates := bot.GetUpdatesChan(u)

	return &TelegramChannel{
		bot:         bot,
		updates:     updates,
		config:      config,
		running:     false,
		orchestrator: orchestrator,
	}, nil
}

// GetName returns the channel name
func (tc *TelegramChannel) GetName() string {
	return "telegram"
}

// Start starts the Telegram channel
func (tc *TelegramChannel) Start() error {
	if tc.running {
		return fmt.Errorf("channel already running")
	}

	tc.running = true
	log.Println("🚀 Telegram channel started")

	// Start message processing in background
	ctx := context.Background()
	go tc.processUpdates(ctx)

	return nil
}

// Stop stops the Telegram channel
func (tc *TelegramChannel) Stop() error {
	if !tc.running {
		return fmt.Errorf("channel not running")
	}

	tc.running = false
	log.Println("Telegram channel stopped")
	return nil
}

// IsRunning returns true if the channel is running
func (tc *TelegramChannel) IsRunning() bool {
	return tc.running
}

// SendMessage sends a message through the Telegram channel
func (tc *TelegramChannel) SendMessage(chatID string, message string) error {
	id, err := strconv.ParseInt(chatID, 10, 64)
	if err != nil {
		return fmt.Errorf("invalid chat ID: %w", err)
	}

	msg := tgbotapi.NewMessage(id, message)
	_, err = tc.bot.Send(msg)
	return err
}

// processUpdates processes incoming Telegram updates
func (tc *TelegramChannel) processUpdates(ctx context.Context) {
	log.Println("📡 Telegram listening for messages...")
	
	for tc.running {
		select {
		case <-ctx.Done():
			tc.running = false
			return
		case update := <-tc.updates:
			if update.Message == nil {
				continue
			}

			chatID := strconv.FormatInt(update.Message.Chat.ID, 10)
			userID := strconv.FormatInt(update.Message.From.ID, 10)
			text := update.Message.Text
			username := update.Message.From.UserName

			log.Printf("📨 Telegram message from @%s (%s): %s", username, userID, text)

			// Send typing indicator
			tc.sendTypingIndicator(chatID)

			// Check authorization
			if !tc.isAuthorized(update.Message.From.ID) {
				log.Printf("⛔ Unauthorized user: %s", username)
				msg := tgbotapi.NewMessage(update.Message.Chat.ID, "⛔ Não autorizado.")
				tc.bot.Send(msg)
				continue
			}

			// Create message for orchestrator
			incomingMsg := types.IncomingMessage{
				Channel:   "telegram",
				ChatID:    chatID,
				UserID:    userID,
				Username:  username,
				Text:      text,
				Timestamp: time.Now(),
			}

			// Send to orchestrator for processing
			if tc.orchestrator != nil {
				go tc.orchestrator.ProcessMessage(incomingMsg)
			} else {
				log.Println("⚠️ No orchestrator available to process message")
			}
		}
	}
}

// sendTypingIndicator sends a typing indicator to the user
func (tc *TelegramChannel) sendTypingIndicator(chatID string) {
	id, err := strconv.ParseInt(chatID, 10, 64)
	if err != nil {
		return
	}
	
	chatAction := tgbotapi.NewChatAction(id, tgbotapi.ChatTyping)
	tc.bot.Send(chatAction)
}

// isAuthorized checks if a user is authorized
func (tc *TelegramChannel) isAuthorized(userID int64) bool {
	// For now, only allow the configured admin
	adminID, err := strconv.ParseInt(tc.config.ChatID, 10, 64)
	if err != nil {
		return false
	}
	
	return userID == adminID
}

// Helper function to convert string to int64
func toInt64(s string) int64 {
	result, _ := strconv.ParseInt(s, 10, 64)
	return result
}
