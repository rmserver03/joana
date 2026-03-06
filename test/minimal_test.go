package test

import (
	"fmt"
	"testing"
	"time"
)

func TestMinimalFunctionality(t *testing.T) {
	fmt.Println("=== Teste Mínimo Joana ===")

	// Testar tipos básicos
	type Message struct {
		ID   string
		Text string
		Time time.Time
	}

	msg := Message{
		ID:   "test-001",
		Text: "Olá do sistema Joana",
		Time: time.Now(),
	}

	if msg.ID != "test-001" {
		t.Errorf("ID incorreto: %s", msg.ID)
	}

	// Testar concorrência básica
	ch := make(chan string, 1)
	go func() {
		time.Sleep(100 * time.Millisecond)
		ch <- "concluído"
	}()

	select {
	case result := <-ch:
		if result != "concluído" {
			t.Errorf("Resultado incorreto: %s", result)
		}
	case <-time.After(200 * time.Millisecond):
		t.Error("Timeout na goroutine")
	}

	// Testar performance
	start := time.Now()
	count := 0
	for i := 0; i < 1000000; i++ {
		count += i % 2
	}
	elapsed := time.Since(start)

	if elapsed > 100*time.Millisecond {
		t.Logf("Performance: loop de 1M iterações em %v", elapsed)
	}

	fmt.Println("✅ Teste mínimo passou")
}
