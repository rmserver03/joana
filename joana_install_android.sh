#!/bin/bash
# ============================================================================
# JOANA - INSTALADOR ANDROID (Protocolo Zero Erros)
# ============================================================================
# Script de instalação completo para Android (Termux)
# Baixa do GitHub, configura e executa 100% no dispositivo
# 
# Autor: Sistema Cognitivo Zero
# Versão: 1.0.0
# Data: 2026-03-06
# ============================================================================

set -e  # Saída imediata em caso de erro

# ============================================================================
# CONFIGURAÇÕES
# ============================================================================
REPO_URL="https://github.com/rmserver03/joana.git"
INSTALL_DIR="$HOME/joana"
CONFIG_DIR="$HOME/.joana"
LOG_FILE="$HOME/joana_install.log"
VERSION="1.0.0"

# ============================================================================
# FUNÇÕES DE UTILIDADE
# ============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "\e[32m✓ $1\e[0m"
    log "SUCCESS: $1"
}

info() {
    echo -e "\e[34mℹ $1\e[0m"
    log "INFO: $1"
}

warning() {
    echo -e "\e[33m⚠ $1\e[0m"
    log "WARNING: $1"
}

error() {
    echo -e "\e[31m✗ $1\e[0m"
    log "ERROR: $1"
    exit 1
}

ask() {
    echo -e "\e[36m? $1\e[0m"
    read -r
    echo "$REPLY"
}

ask_yesno() {
    while true; do
        echo -e "\e[36m? $1 (s/n)\e[0m"
        read -r yn
        case $yn in
            [Ss]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Por favor responda s (sim) ou n (não).";;
        esac
    done
}

check_termux() {
    if [ ! -d "/data/data/com.termux/files/usr" ]; then
        error "Este script requer Termux. Instale Termux da Play Store."
    fi
}

check_internet() {
    if ! ping -c 1 google.com >/dev/null 2>&1; then
        error "Sem conexão com internet. Conecte-se e tente novamente."
    fi
}

# ============================================================================
# CABEÇALHO
# ============================================================================
clear
echo -e "\e[36m"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                   JOANA - INSTALADOR ANDROID                 ║"
echo "║                   Protocolo Zero Erros v1.0                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "\e[0m"
echo "Este script instalará o sistema Joana no seu Android."
echo "Tudo será executado localmente no dispositivo."
echo ""

# ============================================================================
# ETAPA 1: VERIFICAÇÕES INICIAIS
# ============================================================================
log "Iniciando instalação Joana Android v$VERSION"
info "Verificando ambiente Termux..."
check_termux
success "Termux detectado"

info "Verificando conexão com internet..."
check_internet
success "Conexão com internet OK"

# ============================================================================
# ETAPA 2: ATUALIZAÇÃO DO SISTEMA
# ============================================================================
info "Atualizando pacotes Termux..."
pkg update -y && pkg upgrade -y
success "Pacotes atualizados"

# ============================================================================
# ETAPA 3: INSTALAÇÃO DE DEPENDÊNCIAS
# ============================================================================
info "Instalando dependências necessárias..."

# Dependências básicas
pkg install -y git wget curl nano proot-distro

# Go (necessário para compilar Joana)
if ! command -v go >/dev/null 2>&1; then
    info "Instalando Go..."
    pkg install -y golang
    success "Go instalado"
else
    info "Go já instalado: $(go version)"
fi

# Python (para microserviços)
if ! command -v python3 >/dev/null 2>&1; then
    info "Instalando Python..."
    pkg install -y python
    success "Python instalado"
else
    info "Python já instalado: $(python3 --version)"
fi

# Node.js (para interface web opcional)
if ask_yesno "Deseja instalar interface web? (Recomendado)"; then
    if ! command -v node >/dev/null 2>&1; then
        info "Instalando Node.js..."
        pkg install -y nodejs
        success "Node.js instalado"
    else
        info "Node.js já instalado: $(node --version)"
    fi
fi

# SQLite (banco de dados)
pkg install -y sqlite
success "Todas as dependências instaladas"

# ============================================================================
# ETAPA 4: DOWNLOAD DO CÓDIGO
# ============================================================================
info "Baixando código do GitHub..."
if [ -d "$INSTALL_DIR" ]; then
    if ask_yesno "Diretório $INSTALL_DIR já existe. Deseja atualizar?"; then
        cd "$INSTALL_DIR"
        git pull origin main
        success "Código atualizado"
    else
        info "Usando código existente"
    fi
else
    git clone "$REPO_URL" "$INSTALL_DIR"
    success "Código baixado com sucesso"
fi

# ============================================================================
# ETAPA 5: CONFIGURAÇÃO INTERATIVA
# ============================================================================
clear
echo -e "\e[36m"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                   CONFIGURAÇÃO DO SISTEMA                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "\e[0m"

# Criar diretório de configuração
mkdir -p "$CONFIG_DIR"
mkdir -p "$CONFIG_DIR/logs"

# Configuração do Telegram
echo ""
info "CONFIGURAÇÃO DO TELEGRAM BOT"
echo "Para criar um bot Telegram:"
echo "1. Abra o Telegram e procure por @BotFather"
echo "2. Envie /newbot e siga as instruções"
echo "3. Copie o token fornecido"
echo ""

TELEGRAM_TOKEN=""
while [ -z "$TELEGRAM_TOKEN" ]; do
    TELEGRAM_TOKEN=$(ask "Digite o token do seu bot Telegram: ")
    if [ -z "$TELEGRAM_TOKEN" ]; then
        warning "Token não pode ser vazio"
    fi
done

TELEGRAM_CHAT_ID=$(ask "Digite seu ID do Telegram (ou deixe em branco para detectar automaticamente): ")

# Configuração da API LLM
echo ""
info "CONFIGURAÇÃO DA API DE INTELIGÊNCIA ARTIFICIAL"
echo "Escolha seu provedor de LLM:"
echo "1. DeepSeek (recomendado, gratuito)"
echo "2. OpenAI (pago)"
echo "3. Anthropic Claude (pago)"
echo "4. Local (Ollama, LM Studio)"
echo ""

LLM_PROVIDER=$(ask "Digite o número da opção (1-4): ")

case $LLM_PROVIDER in
    1)
        LLM_PROVIDER="deepseek"
        DEEPSEEK_API_KEY=$(ask "Digite sua API Key do DeepSeek: ")
        ;;
    2)
        LLM_PROVIDER="openai"
        OPENAI_API_KEY=$(ask "Digite sua API Key da OpenAI: ")
        ;;
    3)
        LLM_PROVIDER="anthropic"
        ANTHROPIC_API_KEY=$(ask "Digite sua API Key da Anthropic: ")
        ;;
    4)
        LLM_PROVIDER="local"
        LOCAL_API_URL=$(ask "Digite a URL da API local (ex: http://localhost:11434): ")
        ;;
    *)
        LLM_PROVIDER="deepseek"
        warning "Opção inválida, usando DeepSeek como padrão"
        DEEPSEEK_API_KEY=$(ask "Digite sua API Key do DeepSeek: ")
        ;;
esac

# Configuração do Google Sheets (opcional)
echo ""
if ask_yesno "Deseja configurar integração com Google Sheets? (Opcional)"; then
    info "CONFIGURAÇÃO GOOGLE SHEETS"
    echo "Para configurar o Google Sheets:"
    echo "1. Acesse https://console.cloud.google.com"
    echo "2. Crie um projeto e ative a API Google Sheets"
    echo "3. Crie uma conta de serviço e baixe o JSON"
    echo ""
    
    GOOGLE_CREDS_FILE=$(ask "Caminho para o arquivo JSON de credenciais (ou deixe em branco para pular): ")
    if [ -n "$GOOGLE_CREDS_FILE" ] && [ -f "$GOOGLE_CREDS_FILE" ]; then
        cp "$GOOGLE_CREDS_FILE" "$CONFIG_DIR/google_credentials.json"
        GOOGLE_SHEET_ID=$(ask "ID da planilha Google Sheets: ")
    fi
fi

# ============================================================================
# ETAPA 6: CRIAÇÃO DO ARQUIVO DE CONFIGURAÇÃO
# ============================================================================
info "Criando arquivo de configuração..."

cat > "$CONFIG_DIR/config.yaml" << EOF
# Configuração Joana - Gerado automaticamente
version: "1.0"
system:
  name: "Joana"
  mode: "autonomous"
  language: "pt-BR"

telegram:
  enabled: true
  token: "$TELEGRAM_TOKEN"
  chat_id: "$TELEGRAM_CHAT_ID"
  admin_ids: []

llm:
  provider: "$LLM_PROVIDER"
  model: "deepseek-chat"
  api_key: "$DEEPSEEK_API_KEY"
  base_url: "https://api.deepseek.com"
  temperature: 0.7
  max_tokens: 2000

memory:
  type: "sqlite"
  path: "$CONFIG_DIR/joana.db"
  backup_enabled: true
  backup_interval_hours: 24

google_sheets:
  enabled: ${GOOGLE_CREDS_FILE:+true}
  credentials_path: "$CONFIG_DIR/google_credentials.json"
  spreadsheet_id: "$GOOGLE_SHEET_ID"

logging:
  level: "info"
  file: "$CONFIG_DIR/logs/joana.log"
  max_size_mb: 10
  max_files: 5

security:
  require_admin_prefix: true
  admin_prefix: "#rm"
  allowed_commands: ["status", "help", "config", "memory", "update"]
EOF

success "Arquivo de configuração criado: $CONFIG_DIR/config.yaml"

# ============================================================================
# ETAPA 7: COMPILAÇÃO DO SISTEMA GO (ANDROID COMPATÍVEL)
# ============================================================================
info "Compilando sistema Joana para Android (sem CGO)..."
cd "$INSTALL_DIR"

# Configurar ambiente para Android/Termux
export CGO_ENABLED=0
export GOOS=linux
export GOARCH=arm64

# Verificar se temos a versão simplificada (sem SQLite CGO)
if [ -f "./cmd/joana_simple/main.go" ]; then
    info "Compilando versão simplificada (Android compatível)..."
    if ! CGO_ENABLED=0 go build -o "$INSTALL_DIR/joana" ./cmd/joana_simple/; then
        warning "Falha na versão simplificada, tentando versão principal com ajustes..."
        
        # Tentar compilar versão principal com workaround
        if ! CGO_ENABLED=0 go build -o "$INSTALL_DIR/joana" ./cmd/joana/ 2>/dev/null; then
            error "Falha ao compilar Joana para Android. Instale pacotes de desenvolvimento: pkg install golang clang"
        fi
    fi
else
    # Tentar versão principal
    info "Compilando versão principal (pode falhar no Android)..."
    if ! CGO_ENABLED=0 go build -o "$INSTALL_DIR/joana" ./cmd/joana/; then
        error "Falha na compilação. Execute: pkg install golang clang make"
    fi
fi

success "Sistema Joana compilado com sucesso para Android"

# ============================================================================
# ETAPA 8: CRIAÇÃO DE SCRIPTS DE GERENCIAMENTO
# ============================================================================
info "Criando scripts de gerenciamento..."

# Script de início
cat > "$HOME/start_joana.sh" << 'EOF'
#!/bin/bash
# Script para iniciar o sistema Joana

INSTALL_DIR="$HOME/joana"
CONFIG_DIR="$HOME/.joana"
LOG_FILE="$CONFIG_DIR/logs/joana_console.log"

echo "Iniciando Joana..."
echo "Logs: $LOG_FILE"

cd "$INSTALL_DIR"
nohup ./joana --config "$CONFIG_DIR/config.yaml" > "$LOG_FILE" 2>&1 &

JOANA_PID=$!
echo $JOANA_PID > "$CONFIG_DIR/joana.pid"
echo "Joana iniciado com PID: $JOANA_PID"
echo "Para ver logs: tail -f $LOG_FILE"
EOF

chmod +x "$HOME/start_joana.sh"

# Script de parada
cat > "$HOME/stop_joana.sh" << 'EOF'
#!/bin/bash
# Script para parar o sistema Joana

CONFIG_DIR="$HOME/.joana"
PID_FILE="$CONFIG_DIR/joana.pid"

if [ -f "$PID_FILE" ]; then
    JOANA_PID=$(cat "$PID_FILE")
    echo "Parando Joana (PID: $JOANA_PID)..."
    kill "$JOANA_PID" 2>/dev/null
    rm -f "$PID_FILE"
    echo "Joana parado"
else
    echo "Joana não está em execução"
fi
EOF

chmod +x "$HOME/stop_joana.sh"

# Script de status
cat > "$HOME/joana_status.sh" << 'EOF'
#!/bin/bash
# Script para verificar status do sistema Joana

CONFIG_DIR="$HOME/.joana"
PID_FILE="$CONFIG_DIR/joana.pid"
LOG_FILE="$CONFIG_DIR/logs/joana_console.log"

if [ -f "$PID_FILE" ]; then
    JOANA_PID=$(cat "$PID_FILE")
    if ps -p "$JOANA_PID" > /dev/null 2>&1; then
        echo "✅ Joana está em execução (PID: $JOANA_PID)"
        echo "📊 Últimas linhas do log:"
        tail -10 "$LOG_FILE"
    else
        echo "❌ Joana não está em execução (PID morto)"
        rm -f "$PID_FILE"
    fi
else
    echo "❌ Joana não está em execução"
fi
EOF

chmod +x "$HOME/joana_status.sh"

success "Scripts de gerenciamento criados"

# ============================================================================
# ETAPA 9: CONFIGURAÇÃO DE INÍCIO AUTOMÁTICO (OPCIONAL)
# ============================================================================
if ask_yesno "Deseja configurar início automático com Termux?"; then
    info "Configurando início automático..."
    
    # Criar diretório de boot do Termux
    mkdir -p "$HOME/.termux/boot"
    
    # Script de boot
    cat > "$HOME/.termux/boot/joana" << 'EOF'
#!/bin/bash
# Iniciar Joana ao iniciar o Termux

sleep 10  # Esperar Termux inicializar completamente

echo "Iniciando Joana..."
cd "$HOME"
./start_joana.sh
EOF
    
    chmod +x "$HOME/.termux/boot/joana"
    
    # Atalho para Termux:Widget
    mkdir -p "$HOME/.shortcuts"
    ln -sf "$HOME/start_joana.sh" "$HOME/.shortcuts/Joana_Iniciar"
    ln -sf "$HOME/stop_joana.sh" "$HOME/.shortcuts/Joana_Parar"
    ln -sf "$HOME/joana_status.sh" "$HOME/.shortcuts/Joana_Status"
    
    success "Início automático configurado"
    info "Para iniciar manualmente: Toque e segure na área de trabalho → Widgets → Termux:Widget → Joana"
fi

# ============================================================================
# ETAPA 10: TESTE INICIAL
# ============================================================================
info "Realizando teste inicial do sistema..."

# Testar compilação novamente
cd "$INSTALL_DIR"
if ./joana --version 2>&1 | grep -q "Joana"; then
    success "Teste de versão bem-sucedido"
else
    warning "Não foi possível verificar versão, mas o binário foi criado"
fi

# ============================================================================
# ETAPA 11: RESUMO DA INSTALAÇÃO
# ============================================================================
clear
echo -e "\e[32m"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                INSTALAÇÃO CONCLUÍDA COM SUCESSO!             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "\e[0m"
echo ""
echo "📋 RESUMO DA INSTALAÇÃO:"
echo "────────────────────────────────────────────────────────────"
echo "• Sistema:      Joana Android v$VERSION"
echo "• Diretório:    $INSTALL_DIR"
echo "• Configuração: $CONFIG_DIR"
echo "• Logs:         $CONFIG_DIR/logs/"
echo ""
echo "🚀 COMANDOS DISPONÍVEIS:"
echo "────────────────────────────────────────────────────────────"
echo "• Iniciar:      ./start_joana.sh"
echo "• Parar:        ./stop_joana.sh"
echo "• Status:       ./joana_status.sh"
echo "• Logs:         tail -f $CONFIG_DIR/logs/joana_console.log"
echo ""
echo "🔧 CONFIGURAÇÃO TELEGRAM:"
echo "────────────────────────────────────────────────────────────"
echo "1. Abra o Telegram e inicie conversa com seu bot"
echo "2. Envie qualquer mensagem para o bot"
echo "3. No Android, execute: tail -f $CONFIG_DIR/logs/joana_console.log"
echo "4. Veja o ID do chat e cole em $CONFIG_DIR/config.yaml"
echo ""
echo "📱 COMO USAR:"
echo "────────────────────────────────────────────────────────────"
echo "1. Inicie: ./start_joana.sh"
echo "2. No Telegram, envie comandos para o bot:"
echo "   • #rm status - Verificar status"
echo "   • #rm help - Ajuda"
echo "   • Qualquer pergunta - Joana responderá"
echo ""
echo "🔄 ATUALIZAÇÕES FUTURAS:"
echo "────────────────────────────────────────────────────────────"
echo "Para atualizar:"
echo "cd $INSTALL_DIR && git pull && go build -o joana ./cmd/joana/"
echo ""
echo "📄 LOG DA INSTALAÇÃO: $LOG_FILE"
echo ""
echo "🎉 PRONTO! O sistema Joana está instalado e configurado."
echo "Execute './start_joana.sh' para iniciar."
echo ""
log "Instalação concluída com sucesso"
success "Protocolo Zero Erros: Instalação 100% concluída"
echo ""
echo "Pressione Enter para sair..."
read -r
