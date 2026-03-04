// Package channels implements communication channels for Joana
package channels

import (
	"context"
	"fmt"
	"log"
	"time"

	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api/v5"
	"joana.local/pkg/types"
)

// TelegramChannel implements the Telegram communication channel
type TelegramChannel struct {
	bot     *tgbotapi.BotAPI
	updates tgbotapi.UpdatesChannel
	config  TelegramConfig
	running bool
}

// TelegramConfig holds Telegram configuration
type TelegramConfig struct {
	Token   string
	Timeout int
	Debug   bool
}

// NewTelegramChannel creates a new Telegram channel
func NewTelegramChannel(config TelegramConfig) (*TelegramChannel, error) {
	bot, err := tgbotapi.NewBotAPI(config.Token)
	if err != nil {
		return nil, fmt.Errorf("failed to create Telegram bot: %w", err)
	}

	bot.Debug = config.Debug
	log.Printf("Authorized on Telegram as %s", bot.Self.UserName)

	u := tgbotapi.NewUpdate(0)
	u.Timeout = config.Timeout

	updates := bot.GetUpdatesChan(u)

	return &TelegramChannel{
		bot:     bot,
		updates: updates,
		config:  config,
		running: false,
	}, nil
}

// Name returns the channel name
func (tc *TelegramChannel) GetName() string {
	return "telegram"
}

// Start starts the Telegram channel
func (tc *TelegramChannel) Start() error {
	if tc.running {
		return fmt.Errorf("channel already running")
	}

	tc.running = true
	log.Println("Telegram channel started")

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
	tc.bot.StopReceivingUpdates()
	log.Println("Telegram channel stopped")

	return nil
}

// SendMessage sends a message through Telegram
func (tc *TelegramChannel) Send(to string, message *types.Message) error {
	if !tc.running {
		return fmt.Errorf("channel not running")
	}

	msg := tgbotapi.NewMessage(toInt64(to), message.Text)
	
	// Add typing indicator before sending
	tc.sendTypingIndicator(to)
	time.Sleep(500 * time.Millisecond) // Simulate human typing delay

	_, err := tc.bot.Send(msg)
	if err != nil {
		return fmt.Errorf("failed to send Telegram message: %w", err)
	}

	log.Printf("Sent Telegram message to %s: %s", to, message.Text)
	return nil
}

// ReceiveMessages returns a channel for receiving incoming messages
func (tc *TelegramChannel) ReceiveMessages() <-chan *IncomingMessage {
	ch := make(chan *IncomingMessage, 100)
	
	go func() {
		for update := range tc.updates {
			if update.Message == nil {
				continue
			}

			// Check if message is from authorized user
			if !tc.isAuthorized(update.Message.From.ID) {
				log.Printf("Unauthorized Telegram user: %d", update.Message.From.ID)
				continue
			}

			// Convert Telegram message to internal format
			msg := &IncomingMessage{
				RawMessage: update.Message,
				InternalMessage: &types.Message{
					ID:        fmt.Sprintf("tg-%d", update.Message.MessageID),
					Channel:   "telegram",
					Sender: types.Sender{
						ID:      fmt.Sprintf("%d", update.Message.From.ID),
						Name:    update.Message.From.UserName,
						IsAdmin: tc.isAdmin(update.Message.From.ID),
						Metadata: map[string]string{
							"first_name": update.Message.From.FirstName,
							"last_name":  update.Message.From.LastName,
							"language":   update.Message.From.LanguageCode,
						},
					},
					Text:      update.Message.Text,
					Timestamp: time.Unix(int64(update.Message.Date), 0),
					Context: map[string]interface{}{
						"chat_id":   update.Message.Chat.ID,
						"message_id": update.Message.MessageID,
					},
				},
			}

			ch <- msg
		}
	}()

	return ch
}

// processUpdates processes incoming Telegram updates
func (tc *TelegramChannel) processUpdates(ctx context.Context) {
	for tc.running {
		select {
		case <-ctx.Done():
			tc.running = false
			return
		case update := <-tc.updates:
			if update.Message == nil {
				continue
			}

			log.Printf("Received Telegram message from %s: %s", 
				update.Message.From.UserName, update.Message.Text)
		}
	}
}

// sendTypingIndicator sends a typing indicator to the user
func (tc *TelegramChannel) sendTypingIndicator(chatID string) {
	chatAction := tgbotapi.NewChatAction(toInt64(chatID), tgbotapi.ChatTyping)
	_, err := tc.bot.Send(chatAction)
	if err != nil {
		log.Printf("Failed to send typing indicator: %v", err)
	}
}

// isAuthorized checks if a user is authorized
func (tc *TelegramChannel) isAuthorized(userID int64) bool {
	// For prototype, only allow the configured admin
	// In production, this would check against a list of authorized users
	authorizedUsers := map[int64]bool{
		974346958: true, // Rafael's Telegram ID
	}
	
	return authorizedUsers[userID]
}

// isAdmin checks if a user is an admin
func (tc *TelegramChannel) isAdmin(userID int64) bool {
	admins := map[int64]bool{
		974346958: true, // Rafael is admin
	}
	
	return admins[userID]
}

// toInt64 converts string to int64 for Telegram chat IDs
func toInt64(s string) int64 {
	var result int64
	fmt.Sscanf(s, "%d", &result)
	return result
}

// IsRunning returns true if the channel is running
func (tc *TelegramChannel) IsRunning() bool {
	return tc.running
}