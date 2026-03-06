#!/bin/bash
# ============================================================================
# JOANA - INSTALADOR TERMUX FIX (Protocolo Zero Erros)
# ============================================================================
# Script corrigido para Android/Termux com problemas de CGO
# 
# Uso: curl -O https://raw.githubusercontent.com/rmserver03/joana/main/install_termux_fix.sh
#      chmod +x install_termux_fix.sh
#      ./install_termux_fix.sh
# ============================================================================

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║            JOANA - INSTALADOR TERMUX CORRIGIDO               ║"
echo "║               (Para problemas de compilação)                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# PASSO 1: INSTALAR DEPENDÊNCIAS
# ============================================================================
echo "📦 PASSO 1: Instalando dependências..."
pkg update -y
pkg upgrade -y
pkg install -y git wget curl nano
pkg install -y golang clang make
pkg install -y python nodejs sqlite

echo "✅ Dependências instaladas"
echo ""

# ============================================================================
# PASSO 2: BAIXAR CÓDIGO
# ============================================================================
echo "📥 PASSO 2: Baixando código do GitHub..."
if [ -d "$HOME/joana" ]; then
    echo "📁 Diretório joana já existe. Atualizando..."
    cd "$HOME/joana"
    git pull origin main
else
    git clone https://github.com/rmserver03/joana.git "$HOME/joana"
fi

cd "$HOME/joana"
echo "✅ Código baixado/atualizado"
echo ""

# ============================================================================
# PASSO 3: CONFIGURAR AMBIENTE ANDROID
# ============================================================================
echo "⚙️ PASSO 3: Configurando ambiente Android..."
export CGO_ENABLED=0
export GOOS=linux
export GOARCH=arm64

echo "CGO_ENABLED=0 (desativado para Android)"
echo "GOOS=linux"
echo "GOARCH=arm64"
echo ""

# ============================================================================
# PASSO 4: COMPILAR VERSÃO SIMPLIFICADA
# ============================================================================
echo "🔨 PASSO 4: Compilando versão Android-compatível..."

# Verificar qual versão compilar
if [ -f "./cmd/joana_simple/main.go" ]; then
    echo "📄 Compilando versão simplificada (joana_simple)..."
    CGO_ENABLED=0 go build -o "$HOME/joana/joana" ./cmd/joana_simple/
elif [ -f "./cmd/joana_simple_fixed/main.go" ]; then
    echo "📄 Compilando versão simplificada corrigida..."
    CGO_ENABLED=0 go build -o "$HOME/joana/joana" ./cmd/joana_simple_fixed/
else
    echo "📄 Compilando versão principal (pode requerer clang)..."
    CGO_ENABLED=0 go build -o "$HOME/joana/joana" ./cmd/joana/
fi

if [ -f "$HOME/joana/joana" ]; then
    echo "✅ Binário compilado com sucesso: $HOME/joana/joana"
else
    echo "❌ Falha na compilação. Tentando abordagem alternativa..."
    
    # Abordagem alternativa: compilar sem módulos C
    cd "$HOME/joana"
    go mod download
    CGO_ENABLED=0 go build -tags nosqlite -o "$HOME/joana/joana" ./cmd/joana/
    
    if [ ! -f "$HOME/joana/joana" ]; then
        echo "❌❌ COMPILAÇÃO FALHOU"
        echo ""
        echo "SOLUÇÃO MANUAL:"
        echo "1. Instale todas as dependências:"
        echo "   pkg install golang clang make git"
        echo "2. Tente compilar manualmente:"
        echo "   cd ~/joana"
        echo "   CGO_ENABLED=0 go build ./cmd/joana_simple/"
        echo "3. Se ainda falhar, use o binário pré-compilado:"
        echo "   curl -O https://github.com/rmserver03/joana/releases/latest/download/joana_android"
        echo "   chmod +x joana_android"
        echo "   mv joana_android joana/joana"
        exit 1
    fi
fi

echo ""

# ============================================================================
# PASSO 5: CONFIGURAÇÃO INTERATIVA SIMPLES
# ============================================================================
echo "⚙️ PASSO 5: Configuração básica..."
mkdir -p "$HOME/.joana"
mkdir -p "$HOME/.joana/logs"

echo ""
echo "🔧 CONFIGURAÇÃO DO TELEGRAM BOT"
echo "Token do bot (obtenha com @BotFather):"
read -r TELEGRAM_TOKEN

echo ""
echo "🤖 CONFIGURAÇÃO DA API DEEPSEEK (recomendado, gratuito)"
echo "API Key do DeepSeek (obtenha em https://platform.deepseek.com):"
read -r DEEPSEEK_API_KEY

# Criar config.yaml simplificado
cat > "$HOME/.joana/config.yaml" << EOF
system:
  name: "Joana"
  mode: "autonomous"
  language: "pt-BR"

telegram:
  enabled: true
  token: "$TELEGRAM_TOKEN"
  admin_ids: []

llm:
  provider: "deepseek"
  model: "deepseek-chat"
  api_key: "$DEEPSEEK_API_KEY"
  base_url: "https://api.deepseek.com"

memory:
  type: "sqlite"
  path: "$HOME/.joana/joana.db"

logging:
  level: "info"
  file: "$HOME/.joana/logs/joana.log"
EOF

echo "✅ Configuração criada: $HOME/.joana/config.yaml"
echo ""

# ============================================================================
# PASSO 6: CRIAR SCRIPTS DE CONTROLE
# ============================================================================
echo "📜 PASSO 6: Criando scripts de controle..."

# start_joana.sh
cat > "$HOME/start_joana.sh" << 'EOF'
#!/bin/bash
cd "$HOME/joana"
nohup ./joana --config "$HOME/.joana/config.yaml" > "$HOME/.joana/logs/console.log" 2>&1 &
echo $! > "$HOME/.joana/joana.pid"
echo "Joana iniciada (PID: $(cat $HOME/.joana/joana.pid))"
echo "Logs: tail -f $HOME/.joana/logs/console.log"
EOF

# stop_joana.sh
cat > "$HOME/stop_joana.sh" << 'EOF'
#!/bin/bash
if [ -f "$HOME/.joana/joana.pid" ]; then
    kill $(cat "$HOME/.joana/joana.pid") 2>/dev/null
    rm -f "$HOME/.joana/joana.pid"
    echo "Joana parada"
else
    echo "Joana não está em execução"
fi
EOF

# joana_status.sh
cat > "$HOME/joana_status.sh" << 'EOF'
#!/bin/bash
if [ -f "$HOME/.joana/joana.pid" ]; then
    PID=$(cat "$HOME/.joana/joana.pid")
    if ps -p $PID > /dev/null 2>&1; then
        echo "✅ Joana está rodando (PID: $PID)"
        echo "📊 Últimas linhas do log:"
        tail -5 "$HOME/.joana/logs/console.log"
    else
        echo "❌ Joana não está rodando (PID morto)"
        rm -f "$HOME/.joana/joana.pid"
    fi
else
    echo "❌ Joana não está rodando"
fi
EOF

chmod +x "$HOME/start_joana.sh" "$HOME/stop_joana.sh" "$HOME/joana_status.sh"
echo "✅ Scripts criados: start_joana.sh, stop_joana.sh, joana_status.sh"
echo ""

# ============================================================================
# PASSO 7: TESTE INICIAL
# ============================================================================
echo "🧪 PASSO 7: Testando instalação..."
if "$HOME/joana/joana" --version 2>&1 | grep -q "Joana\|version"; then
    echo "✅ Teste de versão bem-sucedido"
else
    echo "⚠️  Não foi possível verificar versão, mas o binário existe"
fi

echo ""

# ============================================================================
# PASSO 8: RESUMO FINAL
# ============================================================================
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    INSTALAÇÃO CONCLUÍDA!                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "🎉 JOANA ESTÁ INSTALADA NO SEU ANDROID!"
echo ""
echo "📋 RESUMO:"
echo "• Binário:      $HOME/joana/joana"
echo "• Configuração: $HOME/.joana/config.yaml"
echo "• Logs:         $HOME/.joana/logs/"
echo ""
echo "🚀 COMANDOS:"
echo "• Iniciar:      ./start_joana.sh"
echo "• Parar:        ./stop_joana.sh"
echo "• Status:       ./joana_status.sh"
echo "• Logs:         tail -f ~/.joana/logs/console.log"
echo ""
echo "🤖 COMO USAR:"
echo "1. Inicie: ./start_joana.sh"
echo "2. No Telegram, converse com seu bot"
echo "3. Comandos admin começam com #rm"
echo ""
echo "🔧 SE PRECISAR DE AJUDA:"
echo "• Verifique logs: tail -f ~/.joana/logs/console.log"
echo "• Reinstale dependências: pkg install golang clang"
echo "• Atualize código: cd ~/joana && git pull"
echo ""
echo "📞 BOM USO!"
echo ""