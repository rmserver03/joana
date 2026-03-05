#!/bin/bash
# INSTALAÇÃO AUTOMATIZADA DA JOANA - ONE-CLICK INSTALL
# Sistema unificado para Android/Termux, Linux e Windows/WSL
# Versão: 1.0.0

set -e  # Sai no primeiro erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detectar sistema operacional
detect_os() {
    log_info "Detectando sistema operacional..."
    
    if [[ -d /data/data/com.termux ]]; then
        OS="ANDROID_TERMUX"
        log_success "Android/Termux detectado"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            OS="LINUX_${ID^^}"
            log_success "Linux ($PRETTY_NAME) detectado"
        else
            OS="LINUX_UNKNOWN"
            log_warning "Linux detectado (distro desconhecida)"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="MACOS"
        log_success "macOS detectado"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="WINDOWS"
        log_success "Windows detectado"
    else
        OS="UNKNOWN"
        log_warning "Sistema operacional desconhecido"
    fi
}

# Verificar e instalar dependências
install_dependencies() {
    log_info "Verificando e instalando dependências para $OS..."
    
    case $OS in
        ANDROID_TERMUX)
            pkg update -y
            pkg install -y git wget curl python golang nodejs-lts sqlite openssl nano vim
            pip install --upgrade pip
            ;;
        LINUX_UBUNTU|LINUX_DEBIAN)
            sudo apt update
            sudo apt install -y git wget curl python3 python3-pip golang-go nodejs npm sqlite3 libsqlite3-dev openssl nano vim
            ;;
        LINUX_FEDORA|LINUX_CENTOS|LINUX_RHEL)
            sudo dnf install -y git wget curl python3 python3-pip golang nodejs npm sqlite sqlite-devel openssl nano vim
            ;;
        LINUX_ARCH|LINUX_MANJARO)
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm git wget curl python python-pip go nodejs npm sqlite openssl nano vim
            ;;
        MACOS)
            if ! command -v brew &> /dev/null; then
                log_error "Homebrew não encontrado. Instale em: https://brew.sh"
                exit 1
            fi
            brew update
            brew install git wget curl python go node sqlite openssl nano vim
            ;;
        WINDOWS)
            log_warning "Windows detectado - assumindo WSL ou Git Bash"
            log_info "Por favor, instale manualmente: Git, Python, Go, Node.js"
            log_info "Ou use WSL (Windows Subsystem for Linux)"
            ;;
        *)
            log_error "Sistema operacional não suportado: $OS"
            exit 1
            ;;
    esac
    
    log_success "Dependências verificadas/instaladas"
}

# Clonar/atualizar repositório
setup_repository() {
    log_info "Configurando repositório da Joana..."
    
    REPO_URL="https://github.com/rmserver03/joana.git"
    INSTALL_DIR="$HOME/joana"
    
    if [[ -d "$INSTALL_DIR/.git" ]]; then
        log_info "Repositório já existe, atualizando..."
        cd "$INSTALL_DIR"
        git pull origin main
    else
        log_info "Clonando repositório..."
        git clone "$REPO_URL" "$INSTALL_DIR"
        cd "$INSTALL_DIR"
    fi
    
    # Verificar integridade
    if [[ ! -f "go.mod" ]] || [[ ! -f "cmd/joana/main.go" ]]; then
        log_error "Repositório corrompido ou incompleto"
        exit 1
    fi
    
    log_success "Repositório configurado em: $INSTALL_DIR"
}

# Instalar Go dependencies
install_go_deps() {
    log_info "Instalando dependências Go..."
    
    if [[ "$OS" == "ANDROID_TERMUX" ]]; then
        export CGO_ENABLED=0
        export GOOS=linux
        export GOARCH=arm64
    fi
    
    go mod download
    go mod tidy
    
    log_success "Dependências Go instaladas"
}

# Instalar Python dependencies
install_python_deps() {
    log_info "Instalando dependências Python..."
    
    if [[ -f "requirements.txt" ]]; then
        pip install -r requirements.txt
    fi
    
    # Dependências mínimas para microserviço Google Sheets
    pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client flask
    
    log_success "Dependências Python instaladas"
}

# Compilar Joana
compile_joana() {
    log_info "Compilando Joana..."
    
    # Versão simplificada para Android
    if [[ "$OS" == "ANDROID_TERMUX" ]]; then
        CGO_ENABLED=0 go build -o joana_android cmd/joana_simple/main.go
        chmod +x joana_android
        log_success "Joana compilada (joana_android)"
    else
        go build -o joana cmd/joana/main.go
        chmod +x joana
        log_success "Joana compilada (joana)"
    fi
}

# Configurar ambiente
setup_environment() {
    log_info "Configurando ambiente..."
    
    # Criar diretórios necessários
    mkdir -p ~/.joana/{config,logs,data}
    mkdir -p ~/.joana/data/{memory,sessions,cache}
    
    # Copiar template .env se não existir
    if [[ ! -f ~/.joana/.env ]]; then
        if [[ -f ".env.template" ]]; then
            cp .env.template ~/.joana/.env
            log_info "Template .env copiado para ~/.joana/.env"
            log_info "Edite este arquivo com suas configurações: nano ~/.joana/.env"
        else
            log_warning "Template .env não encontrado, criando básico..."
            cat > ~/.joana/.env << 'EOF'
# CONFIGURAÇÕES DA JOANA
# Edite com suas chaves de API

# LLM API (obrigatório)
DEEPSEEK_API_KEY=""
# OU
OPENAI_API_KEY=""
# OU
ANTHROPIC_API_KEY=""

# Google APIs (opcional)
GOOGLE_SHEETS_ID=""
GOOGLE_DRIVE_FOLDER_ID=""

# WhatsApp (opcional)
WHATSAPP_API_KEY=""
WHATSAPP_INSTANCE_ID=""

# Telegram (opcional)
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""

# Configurações do sistema
LOG_LEVEL="info"
DATA_DIR="$HOME/.joana/data"
TZ="America/Sao_Paulo"
EOF
        fi
    fi
    
    # Configurar permissões
    chmod 600 ~/.joana/.env
    
    log_success "Ambiente configurado em ~/.joana/"
}

# Executar assistente de configuração interativo
run_setup_wizard() {
    log_info "Iniciando assistente de configuração interativo..."
    
    if [[ -f "setup_wizard.py" ]] && command -v python3 &> /dev/null; then
        python3 setup_wizard.py
    else
        log_warning "Assistente Python não disponível, configuração manual necessária"
        log_info "Edite o arquivo: nano ~/.joana/.env"
        log_info "Depois execute: ./joana (ou ./joana_android no Termux)"
    fi
}

# Criar scripts de serviço
create_service_scripts() {
    log_info "Criando scripts de serviço..."
    
    # Script de início
    cat > start_joana.sh << 'EOF'
#!/bin/bash
# Script para iniciar a Joana

cd "$(dirname "$0")"

# Carregar variáveis de ambiente
if [[ -f ~/.joana/.env ]]; then
    export $(grep -v '^#' ~/.joana/.env | xargs)
fi

# Iniciar Joana
if [[ -f "./joana_android" ]]; then
    ./joana_android
elif [[ -f "./joana" ]]; then
    ./joana
else
    echo "Erro: Executável da Joana não encontrado"
    exit 1
fi
EOF
    
    # Script de parada
    cat > stop_joana.sh << 'EOF'
#!/bin/bash
# Script para parar a Joana

pkill -f "joana" || true
pkill -f "google_sheets_server" || true
echo "Joana parada"
EOF
    
    # Script de status
    cat > status_joana.sh << 'EOF'
#!/bin/bash
# Script para verificar status da Joana

if pgrep -f "joana" > /dev/null; then
    echo "✅ Joana está rodando"
    ps aux | grep -E "(joana|google_sheets)" | grep -v grep
else
    echo "❌ Joana não está rodando"
fi
EOF
    
    chmod +x start_joana.sh stop_joana.sh status_joana.sh
    log_success "Scripts de serviço criados"
}

# Mostrar resumo da instalação
show_summary() {
    echo ""
    echo "========================================="
    echo "        INSTALAÇÃO DA JOANA COMPLETA     "
    echo "========================================="
    echo ""
    echo "✅ Sistema detectado: $OS"
    echo "✅ Dependências instaladas"
    echo "✅ Repositório configurado em: $(pwd)"
    echo "✅ Joana compilada e pronta"
    echo "✅ Ambiente configurado em: ~/.joana/"
    echo ""
    echo "📋 PRÓXIMOS PASSOS:"
    echo ""
    echo "1. Configure suas APIs:"
    echo "   nano ~/.joana/.env"
    echo ""
    echo "2. Inicie a Joana:"
    echo "   ./start_joana.sh"
    echo ""
    echo "3. Verifique status:"
    echo "   ./status_joana.sh"
    echo ""
    echo "4. Para parar:"
    echo "   ./stop_joana.sh"
    echo ""
    echo "🔧 Scripts disponíveis:"
    echo "   - start_joana.sh  (iniciar)"
    echo "   - stop_joana.sh   (parar)"
    echo "   - status_joana.sh (verificar)"
    echo ""
    echo "📚 Documentação:"
    echo "   Consulte README.md para detalhes"
    echo ""
    echo "========================================="
}

# Função principal
main() {
    echo ""
    echo "========================================="
    echo "    INSTALADOR AUTOMATIZADO DA JOANA     "
    echo "========================================="
    echo ""
    
    # 1. Detectar SO
    detect_os
    
    # 2. Instalar dependências
    install_dependencies
    
    # 3. Configurar repositório
    setup_repository
    
    # 4. Instalar dependências Go
    install_go_deps
    
    # 5. Instalar dependências Python
    install_python_deps
    
    # 6. Compilar Joana
    compile_joana
    
    # 7. Configurar ambiente
    setup_environment
    
    # 8. Criar scripts de serviço
    create_service_scripts
    
    # 9. Executar assistente interativo
    run_setup_wizard
    
    # 10. Mostrar resumo
    show_summary
    
    log_success "Instalação completa! 🎉"
}

# Executar função principal
main "$@"