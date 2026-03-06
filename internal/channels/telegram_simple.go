package channels

import (
	"context"
	"fmt"
	"log"
	"strconv"
	"time"

	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api/v5"
)

// TelegramChannelSimple implements a simple Telegram channel
type TelegramChannelSimple struct {
	bot     *tgbotapi.BotAPI
	updates tgbotapi.UpdatesChannel
	config  TelegramConfig
	running bool
}

// NewTelegramChannelSimple creates a new simple Telegram channel
func NewTelegramChannelSimple(config TelegramConfig) (*TelegramChannelSimple, error) {
	bot, err := tgbotapi.NewBotAPI(config.Token)
	if err != nil {
		return nil, fmt.Errorf("failed to create Telegram bot: %w", err)
	}

	bot.Debug = config.Debug
	log.Printf("✅ Telegram bot authorized as @%s", bot.Self.UserName)

	u := tgbotapi.NewUpdate(0)
	u.Timeout = config.Timeout

	updates := bot.GetUpdatesChan(u)

	return &TelegramChannelSimple{
		bot:     bot,
		updates: updates,
		config:  config,
		running: false,
	}, nil
}

// Start starts the Telegram channel
func (tc *TelegramChannelSimple) Start() error {
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
func (tc *TelegramChannelSimple) Stop() error {
	if !tc.running {
		return fmt.Errorf("channel not running")
	}

	tc.running = false
	log.Println("Telegram channel stopped")
	return nil
}

// processUpdates processes incoming Telegram updates
func (tc *TelegramChannelSimple) processUpdates(ctx context.Context) {
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

			chatID := update.Message.Chat.ID
			userID := update.Message.From.ID
			text := update.Message.Text
			username := update.Message.From.UserName

			log.Printf("📨 Telegram message from @%s (%d): %s", username, userID, text)

			// Send typing indicator
			tc.sendTypingIndicator(chatID)

			// Check authorization
			adminID, _ := strconv.ParseInt(tc.config.ChatID, 10, 64)
			if userID != adminID {
				log.Printf("⛔ Unauthorized user: @%s", username)
				msg := tgbotapi.NewMessage(chatID, "⛔ Não autorizado.")
				tc.bot.Send(msg)
				continue
			}

			// Process message
			tc.processMessage(chatID, userID, text, username)
		}
	}
}

// processMessage processes an authorized message
func (tc *TelegramChannelSimple) processMessage(chatID, userID int64, text, username string) {
	// Simulate thinking
	time.Sleep(1 * time.Second)

	// Simple response logic
	response := ""
	switch text {
	case "/start":
		response = "👋 Olá! Eu sou a Joana, sua assistente cognitiva.\nUse /help para ver comandos."
	case "/help":
		response = "🤖 Comandos disponíveis:\n/start - Iniciar conversa\n/help - Ajuda\n/status - Status do sistema\n\nEnvie qualquer mensagem para conversar!"
	case "/status":
		response = "✅ Sistema operacional\n🤖 Bot: @rmjoanaclaw_bot\n👤 Usuário: @" + username + "\n⏰ Online desde: " + time.Now().Format("15:04:05")
	default:
		response = "🤖 Recebi sua mensagem: \"" + text + "\"\nEstou em desenvolvimento, mas em breve serei mais útil!"
	}

	// Send response
	msg := tgbotapi.NewMessage(chatID, response)
	_, err := tc.bot.Send(msg)
	if err != nil {
		log.Printf("❌ Erro ao enviar resposta: %v", err)
	} else {
		log.Printf("✅ Resposta enviada para @%s", username)
	}
}

// sendTypingIndicator sends a typing indicator to the user
func (tc *TelegramChannelSimple) sendTypingIndicator(chatID int64) {
	chatAction := tgbotapi.NewChatAction(chatID, tgbotapi.ChatTyping)
	tc.bot.Send(chatAction)
}
