package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"joana.local/internal/channels"
)

func main() {
	log.Println("=== Joana Simple Fixed ===")
	log.Println("Versão: 1.0.0 (Telegram fix)")
	log.Println("Timestamp:", time.Now().Format("2006-01-02 15:04:05"))

	// Configuração
	token := os.Getenv("TELEGRAM_BOT_TOKEN")
	if token == "" {
		log.Fatal("TELEGRAM_BOT_TOKEN não definido")
	}

	log.Println("1. Inicializando Telegram Channel...")
	tgConfig := channels.TelegramConfig{
		Token:   token,
		ChatID:  "974346958",
		Timeout: 60,
		Debug:   true,
	}

	// Canal Telegram simples
	tgChannel, err := channels.NewTelegramChannelSimple(tgConfig)
	if err != nil {
		log.Fatal("Falha Telegram Channel:", err)
	}

	log.Println("2. Iniciando Telegram Channel...")
	if err := tgChannel.Start(); err != nil {
		log.Fatal("Falha ao iniciar Telegram:", err)
	}

	log.Println("✅ Sistema Joana iniciado com sucesso!")
	log.Println("🤖 Bot: @rmjoanaclaw_bot")
	log.Println("👤 Admin: 974346958")
	log.Println("📡 Aguardando mensagens...")

	// Aguardar sinal para encerrar
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	log.Println("Encerrando Joana...")
	tgChannel.Stop()
	log.Println("✅ Sistema encerrado.")
}
