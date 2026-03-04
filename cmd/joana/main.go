// Package main is the entry point for the Joana system
package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"joana.local/internal/orchestrator"
)

func main() {
	// Parse command line flags
	_ = flag.String("config", "./config/joana.yaml", "Path to configuration file") // Not used in prototype
	telegramToken := flag.String("telegram-token", "", "Telegram bot token (overrides config)")
	dbPath := flag.String("db", "./data/joana.db", "Path to SQLite database")
	debug := flag.Bool("debug", false, "Enable debug mode")
	flag.Parse()

	// Create data directory if it doesn't exist
	if err := os.MkdirAll("./data", 0755); err != nil {
		log.Fatalf("Failed to create data directory: %v", err)
	}

	// Create config directory if it doesn't exist
	if err := os.MkdirAll("./config", 0755); err != nil {
		log.Fatalf("Failed to create config directory: %v", err)
	}

	// Load configuration (simplified for prototype)
	// In production, would load from YAML file
	config := orchestrator.Config{
		MemoryDBPath:  *dbPath,
		TelegramToken: getTelegramToken(*telegramToken),
	}

	if config.TelegramToken == "" {
		log.Println("Warning: No Telegram token provided. Telegram channel will not be available.")
	}

	// Create orchestrator
	orc, err := orchestrator.NewOrchestrator(config)
	if err != nil {
		log.Fatalf("Failed to create orchestrator: %v", err)
	}

	// Set up signal handling for graceful shutdown
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// Start orchestrator
	log.Println("Starting Joana system...")
	log.Printf("Database: %s", *dbPath)
	log.Printf("Debug mode: %v", *debug)

	if err := orc.Start(ctx); err != nil {
		log.Fatalf("Failed to start orchestrator: %v", err)
	}

	// Print startup banner
	printBanner()

	// Print status
	status := orc.GetStatus()
	log.Printf("System status: %v", status)

	// Wait for shutdown signal
	go func() {
		<-sigChan
		log.Println("Shutdown signal received")
		cancel()
		
		// Give orchestrator time to shut down gracefully
		time.Sleep(2 * time.Second)
		os.Exit(0)
	}()

	// Keep main goroutine alive
	select {
	case <-ctx.Done():
		log.Println("Context cancelled, shutting down")
	}

	// Stop orchestrator gracefully
	log.Println("Stopping orchestrator...")
	if err := orc.Stop(ctx); err != nil {
		log.Printf("Error stopping orchestrator: %v", err)
	}

	log.Println("Joana system stopped")
}

// getTelegramToken retrieves Telegram token from flag or environment
func getTelegramToken(flagToken string) string {
	if flagToken != "" {
		return flagToken
	}
	
	// Try environment variable
	if envToken := os.Getenv("TELEGRAM_TOKEN"); envToken != "" {
		return envToken
	}
	
	// Try config file (simplified)
	if token, err := os.ReadFile("./config/telegram.token"); err == nil {
		return string(token)
	}
	
	return ""
}

// printBanner prints the startup banner
func printBanner() {
	banner := `
     ██╗ ██████╗  █████╗ ███╗   ██╗ █████╗ 
     ██║██╔═══██╗██╔══██╗████╗  ██║██╔══██╗
     ██║██║   ██║███████║██╔██╗ ██║███████║
██   ██║██║   ██║██╔══██║██║╚██╗██║██╔══██║
╚█████╔╝╚██████╔╝██║  ██║██║ ╚████║██║  ██║
 ╚════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝
                                           
   J.A.R.V.I.S.-inspired Cognitive System
          Version: 0.1.0 (Prototype)
`
	fmt.Println(banner)
	fmt.Println("System initialized with 5-layer reasoning engine")
	fmt.Println("6 operation modes: Standard, Autonomous, Crisis, Research, Learning, Background")
	fmt.Println("5-layer memory system: Working, Episodic, Semantic, Procedural, Operator")
	fmt.Println("")
}