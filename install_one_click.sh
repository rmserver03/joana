#!/bin/bash
# INSTALAÇÃO ONE-CLICK JOANA
# Sistema completo em um único script
# Compatível com: Android/Termux, Linux, macOS, Windows/WSL

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                INSTALAÇÃO ONE-CLICK JOANA                    ║"
    echo "║          Sistema de IA autônomo - Rafael Maciel              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

detect_os() {
    case "$(uname -s)" in
        Linux*)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                OS="$NAME"
                if [ "$ID" = "android" ] || [ "$(uname -o)" = "Android" ]; then
                    OS="Android/Termux"
                fi
            else
                OS="Linux"
            fi
            ;;
        Darwin*)
            OS="macOS"
            ;;
        CYGWIN*|MINGW32*|MSYS*|MINGW*)
            OS="Windows"
            ;;
        *)
            OS="Unknown"
            ;;
    esac
    echo "$OS"
}

install_dependencies() {
    local os="$1"
    
    case "$os" in
        "Android/Termux")
            print_step "Instalando dependências para Android/Termux..."
            pkg update -y
            pkg install -y git wget curl golang python python-pip nodejs-lts sqlite openssl nano
            
            # Verificar se é Termux Play Store (pip bloqueado)
            if ! pip --version > /dev/null 2>&1; then
                print_warning "Termux Play Store detectado - pip bloqueado"
                print_warning "Usando configuração manual..."
            fi
            ;;
        "Linux"|"Ubuntu"|"Debian")
            print_step "Instalando dependências para Linux..."
            sudo apt update
            sudo apt install -y git wget curl golang python3 python3-pip nodejs npm sqlite3 openssl nano
            ;;
        "macOS")
            print_step "Instalando dependências para macOS..."
            if ! command -v brew &> /dev/null; then
                print_error "Homebrew não encontrado. Instale primeiro: https://brew.sh"
                exit 1
            fi
            brew install git wget curl go python node sqlite openssl nano
            ;;
        "Windows")
            print_warning "Windows detectado - usando WSL ou Git Bash"
            print_warning "Recomendo usar WSL2 (Ubuntu) para melhor compatibilidade"
            exit 1
            ;;
        *)
            print_error "Sistema operacional não suportado: $os"
            exit 1
            ;;
    esac
}

clone_repository() {
    print_step "Baixando projeto Joana do GitHub..."
    
    if [ -d "joana" ]; then
        print_warning "Diretório 'joana' já existe. Atualizando..."
        cd joana
        git pull origin main
    else
        git clone https://github.com/rmserver03/joana.git
        cd joana
    fi
    
    print_step "Projeto baixado com sucesso!"
    echo "Tamanho: $(du -sh . | cut -f1)"
    echo "Arquivos: $(find . -type f | wc -l)"
}

setup_environment() {
    print_step "Configurando ambiente..."
    
    # Criar diretório de configuração
    mkdir -p ~/.joana
    
    # Configurar Go
    if [ -z "$GOPATH" ]; then
        export GOPATH="$HOME/go"
        export PATH="$PATH:$GOPATH/bin"
        mkdir -p "$GOPATH"
        print_step "GOPATH configurado: $GOPATH"
    fi
    
    # Verificar Go
    if ! go version > /dev/null 2>&1; then
        print_error "Go não encontrado. Instale Go primeiro."
        exit 1
    fi
    
    print_step "Go versão: $(go version)"
}

compile_system() {
    print_step "Compilando sistema Joana..."
    
    # Versão simplificada (sem CGO para Android)
    if [ "$OS" = "Android/Termux" ]; then
        print_step "Compilando versão Android (sem CGO)..."
        CGO_ENABLED=0 go build -o joana_simple cmd/joana_simple/main.go
        chmod +x joana_simple
    else
        print_step "Compilando versão completa..."
        go build -o joana cmd/joana/main.go
        chmod +x joana
    fi
    
    # Verificar binário
    if [ -f "joana_simple" ] || [ -f "joana" ]; then
        print_step "Sistema compilado com sucesso!"
    else
        print_error "Falha na compilação"
        exit 1
    fi
}

run_setup_wizard() {
    print_step "Iniciando assistente de configuração..."
    
    # Verificar se Python está disponível
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
    else
        print_warning "Python não encontrado. Usando configuração manual..."
        manual_configuration
        return
    fi
    
    # Verificar se o assistente existe
    if [ -f "setup_wizard.py" ]; then
        $PYTHON_CMD setup_wizard.py
    else
        print_warning "Assistente não encontrado. Baixando..."
        wget -q https://raw.githubusercontent.com/rmserver03/joana/main/setup_wizard.py
        if [ -f "setup_wizard.py" ]; then
            $PYTHON_CMD setup_wizard.py
        else
            print_warning "Não foi possível baixar o assistente. Usando configuração manual..."
            manual_configuration
        fi
    fi
}

manual_configuration() {
    print_step "Configuração manual..."
    
    cat > ~/.joana/.env << 'EOF'
# CONFIGURAÇÃO JOANA - EDITAR COM SUAS CHAVES
LLM_PROVIDER=deepseek
DEEPSEEK_API_KEY=sua_chave_aqui

# Telegram (opcional)
TELEGRAM_BOT_TOKEN=seu_token_aqui
TELEGRAM_ADMIN_ID=974346958

# Sistema
TZ=America/Sao_Paulo
LOG_LEVEL=info
EOF
    
    echo -e "${YELLOW}"
    echo "══════════════════════════════════════════════════════════════"
    echo "CONFIGURAÇÃO MANUAL CRIADA: ~/.joana/.env"
    echo ""
    echo "EDIÇÃO NECESSÁRIA:"
    echo "1. Abra o arquivo: nano ~/.joana/.env"
    echo "2. Substitua 'sua_chave_aqui' pela sua chave da DeepSeek"
    echo "3. (Opcional) Configure Telegram se quiser"
    echo "4. Salve: Ctrl+X, Y, Enter"
    echo "══════════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

create_service_scripts() {
    print_step "Criando scripts de serviço..."
    
    # Script de inicialização
    cat > start_joana.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"

# Carregar configuração
if [ -f ~/.joana/.env ]; then
    export $(grep -v '^#' ~/.joana/.env | xargs)
fi

# Verificar API key
if [ -z "$DEEPSEEK_API_KEY" ] || [ "$DEEPSEEK_API_KEY" = "sua_chave_aqui" ]; then
    echo "ERRO: Configure sua API key em ~/.joana/.env"
    echo "Edite: nano ~/.joana/.env"
    exit 1
fi

# Iniciar sistema
echo "🚀 Iniciando Joana..."
if [ -f "joana_simple" ]; then
    ./joana_simple
elif [ -f "joana" ]; then
    ./joana
else
    echo "ERRO: Binário não encontrado. Execute ./install_one_click.sh primeiro."
    exit 1
fi
EOF
    
    # Script de status
    cat > status_joana.sh << 'EOF'
#!/bin/bash
echo "=== STATUS JOANA ==="
echo "Diretório: $(pwd)"
echo "Configuração: ~/.joana/.env"
echo ""
echo "Processos ativos:"
ps aux | grep -E "(joana|joana_simple)" | grep -v grep || echo "Nenhum processo ativo"
echo ""
echo "Últimos logs:"
tail -n 10 ~/.joana/logs/*.log 2>/dev/null || echo "Nenhum log encontrado"
EOF
    
    # Script de parada
    cat > stop_joana.sh << 'EOF'
#!/bin/bash
echo "Parando Joana..."
pkill -f "joana" || true
pkill -f "joana_simple" || true
echo "✅ Sistema parado"
EOF
    
    chmod +x start_joana.sh status_joana.sh stop_joana.sh
    print_step "Scripts de serviço criados: start_joana.sh, status_joana.sh, stop_joana.sh"
}

show_instructions() {
    echo -e "${GREEN}"
    echo "══════════════════════════════════════════════════════════════"
    echo "✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
    echo "══════════════════════════════════════════════════════════════"
    echo -e "${NC}"
    
    echo "📁 Diretório: $(pwd)"
    echo ""
    echo "📋 PRÓXIMOS PASSOS:"
    echo ""
    
    if [ -f "~/.joana/.env" ] && grep -q "sua_chave_aqui" ~/.joana/.env; then
        echo "1. ${YELLOW}CONFIGURAR API KEY:${NC}"
        echo "   nano ~/.joana/.env"
        echo "   Substitua 'sua_chave_aqui' pela sua chave da DeepSeek"
        echo ""
    fi
    
    echo "2. ${GREEN}INICIAR SISTEMA:${NC}"
    echo "   ./start_joana.sh"
    echo ""
    echo "3. ${BLUE}VERIFICAR STATUS:${NC}"
    echo "   ./status_joana.sh"
    echo ""
    echo "4. ${BLUE}PARAR SISTEMA:${NC}"
    echo "   ./stop_joana.sh"
    echo ""
    
    echo "🔧 COMANDOS ÚTEIS:"
    echo "   Editar configuração: nano ~/.joana/.env"
    echo "   Ver logs: tail -f ~/.joana/logs/*.log"
    echo "   Atualizar: git pull && ./install_one_click.sh"
    echo ""
    
    echo "📱 TELEGRAM (opcional):"
    echo "   Se configurou Telegram, converse com @BotFather"
    echo "   Token: configurado em ~/.joana/.env"
    echo "   Admin: 974346958 (Rafael Maciel)"
    echo ""
    
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo "Sistema pronto para uso! Qualquer problema, execute novamente:"
    echo "./install_one_click.sh"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
}

# MAIN EXECUTION
main() {
    print_header
    
    # Detectar SO
    OS=$(detect_os)
    print_step "Sistema detectado: $OS"
    
    # Instalar dependências
    install_dependencies "$OS"
    
    # Baixar projeto
    clone_repository
    
    # Configurar ambiente
    setup_environment
    
    # Compilar
    compile_system
    
    # Configurar
    run_setup_wizard
    
    # Criar scripts de serviço
    create_service_scripts
    
    # Mostrar instruções
    show_instructions
}

# Executar
main "$@"