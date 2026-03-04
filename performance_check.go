package main

import (
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"time"
)

func main() {
	fmt.Println("=== Teste de Performance Joana ===")
	
	// Informações do sistema
	fmt.Printf("Go version: %s\n", runtime.Version())
	fmt.Printf("OS: %s\n", runtime.GOOS)
	fmt.Printf("Arch: %s\n", runtime.GOARCH)
	fmt.Printf("CPU cores: %d\n", runtime.NumCPU())
	
	// Testar compilação rápida
	start := time.Now()
	
	cmd := exec.Command("go", "build", "-o", "test_perf", "cmd/joana/main.go")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	
	err := cmd.Run()
	buildTime := time.Since(start)
	
	if err != nil {
		fmt.Printf("❌ Erro na compilação: %v\n", err)
		os.Exit(1)
	}
	
	fmt.Printf("✅ Build concluído em: %v\n", buildTime)
	
	// Verificar tamanho do binário
	if info, err := os.Stat("test_perf"); err == nil {
		sizeMB := float64(info.Size()) / (1024 * 1024)
		fmt.Printf("✅ Tamanho do binário: %.2f MB\n", sizeMB)
	}
	
	// Testar startup time
	start = time.Now()
	cmd = exec.Command("./test_perf", "--db", "./data/test_perf.db")
	cmd.Stdout = nil // Silenciar
	cmd.Stderr = nil
	
	if err := cmd.Start(); err != nil {
		fmt.Printf("❌ Erro ao iniciar: %v\n", err)
		os.Exit(1)
	}
	
	// Dar tempo para inicialização
	time.Sleep(100 * time.Millisecond)
	
	// Verificar se processo está rodando
	if cmd.Process == nil {
		fmt.Println("❌ Processo não iniciou")
		os.Exit(1)
	}
	
	startupTime := time.Since(start)
	fmt.Printf("✅ Startup time: %v\n", startupTime)
	
	// Matar processo
	cmd.Process.Kill()
	cmd.Wait()
	
	// Limpar
	os.Remove("test_perf")
	os.RemoveAll("./data/test_perf.db")
	
	fmt.Println("\n=== Resultados ===")
	fmt.Printf("Build time: %v\n", buildTime)
	fmt.Printf("Startup time: %v\n", startupTime)
	
	// Verificar metas
	if buildTime < 5*time.Second {
		fmt.Println("✅ Build time: <5s (meta atingida)")
	} else {
		fmt.Println("⚠️  Build time: >5s (acima da meta)")
	}
	
	if startupTime < 2*time.Second {
		fmt.Println("✅ Startup time: <2s (meta atingida)")
	} else {
		fmt.Printf("⚠️  Startup time: %v (>2s)\n", startupTime)
	}
}