package main

import (
	"fmt"
	"time"
	
	"joana.local/internal/core"
	"joana.local/pkg/types"
)

func main() {
	fmt.Println("=== Teste Simples Joana ===")
	
	// Testar criação do reasoning engine
	engine := core.NewReasoningEngine()
	fmt.Println("✅ Reasoning Engine criado")
	
	// Testar modo padrão
	fmt.Printf("Modo padrão: %v\n", engine.GetMode())
	
	// Testar processamento de mensagem simples
	msg := &types.Message{
		ID:        "test-1",
		Channel:   "test",
		Sender:    types.Sender{ID: "test-user", Name: "Test User"},
		Text:      "Olá Joana, como você está?",
		Timestamp: time.Now(),
	}
	
	fmt.Println("✅ Mensagem de teste criada")
	
	// Verificar se os tipos estão corretos
	fmt.Printf("Tipo da mensagem: %T\n", msg)
	fmt.Printf("Texto: %s\n", msg.Text)
	
	fmt.Println("\n=== Teste concluído ===")
}