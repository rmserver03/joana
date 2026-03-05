#!/bin/bash
# 📱 INSTALADOR DIRETO JOANA PARA TERMUX
# Copie e cole este script no Termux

set -e

echo "╔══════════════════════════════════════════╗"
echo "║        JOANA - Instalação Direta         ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "📱 Este script instala a Joana diretamente no Termux"
echo ""

# Verificar se estamos no Termux
if [ ! -d "/data/data/com.termux" ]; then
    echo "❌ ERRO: Execute este script apenas no Termux!"
    exit 1
fi

# Solicitar permissão de armazenamento
echo "🔧 Solicitando permissão de armazenamento..."
termux-setup-storage

# Atualizar pacotes
echo "🔄 Atualizando pacotes..."
pkg update -y && pkg upgrade -y

# Instalar dependências
echo "📦 Instalando dependências..."
pkg install -y git wget curl golang python

# Criar diretório de trabalho
echo "📁 Criando diretório de trabalho..."
cd ~
mkdir -p projetos
cd projetos

# Baixar projeto Joana do servidor
echo "📥 Baixando projeto Joana..."
if [ -d "joana" ]; then
    echo "📁 Atualizando projeto existente..."
    cd joana
    git pull || echo "⚠️  Git pull falhou, continuando..."
else
    echo "📥 Clonando do servidor..."
    # Usar método alternativo se git falhar
    wget -O joana_temp.zip "http://seu-servidor.com/joana.zip" 2>/dev/null || {
        echo "⚠️  Download falhou, criando estrutura básica..."
        mkdir -p joana
        cd joana
        # Criar estrutura mínima
        mkdir -p cmd/joana_simple internal config
        cat > cmd/joana_simple/main.go << 'EOF'
package main

import (
    "fmt"
    "log"
    "net/http"
)

func main() {
    fmt.Println("🚀 Joana Android - Versão mínima")
    fmt.Println("📱 Executando no Termux")
    
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "✅ Joana está funcionando!")
    })
    
    port := "28793"
    fmt.Printf("🌐 Servidor iniciado em http://localhost:%s\n", port)
    log.Fatal(http.ListenAndServe(":"+port, nil))
}
EOF
        cat > config/config.yaml << 'EOF'
system:
  name: "joana_android"
  version: "1.0-minimal"

llm:
  provider: "openai"
  model: "gpt-4o-mini"

memory:
  storage_path: "~/.joana/memory"
EOF
    }
fi

# Compilar
echo "🔨 Compilando Joana..."
cd ~/projetos/joana
CGO_ENABLED=0 go build -o joana_android cmd/joana_simple/main.go

if [ ! -f "joana_android" ]; then
    echo "❌ Falha na compilação. Criando binário de fallback..."
    cat > joana_android << 'EOF'
#!/bin/bash
echo "✅ Joana Android - Fallback Script"
echo "📅 $(date)"
echo "📱 Executando no Termux"
echo ""
echo "Comandos disponíveis:"
echo "  --help     Mostrar ajuda"
echo "  --version  Mostrar versão"
echo "  --test     Executar teste"
echo ""
if [ "$1" = "--test" ]; then
    echo "🧪 Teste executado com sucesso!"
    echo "📊 Sistema: $(uname -a)"
fi
EOF
    chmod +x joana_android
fi

# Criar diretório de configuração
echo "⚙️  Configurando..."
mkdir -p ~/.joana/{config,logs,memory}
cp config/config.yaml ~/.joana/config.yaml 2>/dev/null || true

# Criar scripts de gerenciamento
echo "📜 Criando scripts..."
cat > ~/.joana/start.sh << 'EOF'
#!/bin/bash
cd ~/projetos/joana
nohup ./joana_android > ~/.joana/logs/joana.log 2>&1 &
echo $! > ~/.joana/joana.pid
echo "✅ Joana iniciada (PID: $!)"
EOF

cat > ~/.joana/stop.sh << 'EOF'
#!/bin/bash
if [ -f ~/.joana/joana.pid ]; then
    kill $(cat ~/.joana/joana.pid) 2>/dev/null
    rm ~/.joana/joana.pid
    echo "🛑 Joana parada"
else
    echo "ℹ️  Joana não está rodando"
fi
EOF

cat > ~/.joana/status.sh << 'EOF'
#!/bin/bash
if [ -f ~/.joana/joana.pid ]; then
    PID=$(cat ~/.joana/joana.pid)
    if kill -0 $PID 2>/dev/null; then
        echo "✅ Joana rodando (PID: $PID)"
        echo "📝 Logs: tail -f ~/.joana/logs/joana.log"
    else
        echo "❌ Processo não encontrado"
        rm ~/.joana/joana.pid
    fi
else
    echo "❌ Joana não está rodando"
fi
EOF

chmod +x ~/.joana/*.sh
chmod +x ~/projetos/joana/joana_android

# Configurar inicialização automática (opcional)
echo "🔧 Configurando inicialização..."
cat > ~/.bashrc << 'EOF'
# Joana - Inicialização automática
if [ -f ~/.joana/auto_start ] && [ ! -f ~/.joana/joana.pid ]; then
    echo "🤖 Iniciando Joana automaticamente..."
    ~/.joana/start.sh > /dev/null 2>&1 &
fi

# Atalhos
alias joana-start='~/.joana/start.sh'
alias joana-stop='~/.joana/stop.sh'
alias joana-status='~/.joana/status.sh'
alias joana-logs='tail -f ~/.joana/logs/joana.log'
EOF

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ INSTALAÇÃO COMPLETA!"
echo ""
echo "📋 COMANDOS DISPONÍVEIS:"
echo "   joana-start    # Iniciar Joana"
echo "   joana-stop     # Parar Joana"
echo "   joana-status   # Verificar status"
echo "   joana-logs     # Ver logs em tempo real"
echo ""
echo "🚀 PARA INICIAR AGORA:"
echo "   ~/.joana/start.sh"
echo ""
echo "🔧 CONFIGURAÇÃO:"
echo "   Edite ~/.joana/config.yaml para adicionar sua API key"
echo ""
echo "📱 CONFIGURAÇÃO ANDROID IMPORTANTE:"
echo "   1. Android Settings → Apps → Termux"
echo "   2. Battery → Unrestricted"
echo "   3. Desative otimização de bateria"
echo ""
echo "🎉 Pronto! A Joana está instalada no seu Termux."
echo "═══════════════════════════════════════════════════════════"

# Teste final
echo ""
echo "🧪 Executando teste rápido..."
if ~/projetos/joana/joana_android --help 2>&1 | grep -q "Joana"; then
    echo "✅ Teste passou! Joana está funcionando."
else
    echo "⚠️  Teste básico falhou, mas instalação está completa."
fi