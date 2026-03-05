#!/bin/bash
# install_android.sh - Script de instalação da Joana para Android (Termux)
# Versão: 1.0.0
# Autor: ZERO-J.A.R.V.I.S.
# GitHub: https://github.com/rmserver03/joana

set -e

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

# Verificar se estamos no Termux
check_termux() {
    if [ ! -d "/data/data/com.termux" ]; then
        log_error "Este script requer Termux no Android."
        log_error "Instale Termux da Play Store e execute novamente."
        exit 1
    fi
    log_success "Termux detectado."
}

# Atualizar pacotes
update_packages() {
    log_info "Atualizando pacotes Termux..."
    pkg update -y && pkg upgrade -y
    log_success "Pacotes atualizados."
}

# Instalar dependências
install_dependencies() {
    log_info "Instalando dependências..."
    pkg install -y golang git wget curl
    log_success "Dependências instaladas."
}

# Clonar repositório
clone_repository() {
    log_info "Clonando repositório da Joana..."
    if [ -d "joana" ]; then
        log_warning "Diretório 'joana' já existe. Atualizando..."
        cd joana && git pull && cd ..
    else
        git clone https://github.com/rmserver03/joana.git
    fi
    log_success "Repositório clonado/atualizado."
}

# Compilar Joana
compile_joana() {
    log_info "Compilando Joana..."
    cd joana
    go build -o joana_android cmd/joana_simple/main.go
    log_success "Joana compilada (joana_android)."
}

# Criar diretório de configuração
create_config_dir() {
    log_info "Criando diretório de configuração..."
    mkdir -p ~/.joana
    log_success "Diretório de configuração criado."
}

# Criar script de inicialização
create_startup_script() {
    log_info "Criando script de inicialização..."
    cat > ~/.joana/start_joana.sh << 'EOF'
#!/bin/bash
# Script para iniciar Joana no Android

JOANA_DIR="$HOME/joana"
LOG_FILE="$HOME/.joana/joana.log"
PID_FILE="$HOME/.joana/joana.pid"

# Verificar se já está rodando
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "Joana já está rodando (PID: $PID)"
        exit 0
    fi
fi

# Iniciar Joana
cd "$JOANA_DIR"
nohup ./joana_android > "$LOG_FILE" 2>&1 &
JOANA_PID=$!

# Salvar PID
echo "$JOANA_PID" > "$PID_FILE"
echo "Joana iniciada (PID: $JOANA_PID)"
echo "Logs: $LOG_FILE"
EOF

    chmod +x ~/.joana/start_joana.sh
    
    # Criar script de parada
    cat > ~/.joana/stop_joana.sh << 'EOF'
#!/bin/bash
# Script para parar Joana no Android

PID_FILE="$HOME/.joana/joana.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"
        echo "Joana parada (PID: $PID)"
        rm -f "$PID_FILE"
    else
        echo "Joana não está rodando"
        rm -f "$PID_FILE"
    fi
else
    echo "Joana não está rodando"
fi
EOF

    chmod +x ~/.joana/stop_joana.sh
    log_success "Scripts de inicialização criados."
}

# Criar serviço Termux (opcional)
create_termux_service() {
    log_info "Configurando serviço Termux (opcional)..."
    
    # Verificar se termux-services está instalado
    if ! pkg list-installed | grep -q termux-services; then
        log_warning "termux-services não instalado. Instalando..."
        pkg install -y termux-services
    fi
    
    # Criar serviço
    mkdir -p ~/.termux/boot
    cat > ~/.termux/boot/joana << 'EOF'
#!/data/data/com.termux/files/usr/bin/sh
# Serviço de inicialização da Joana para Termux

sleep 10  # Aguardar inicialização do Termux

# Iniciar Joana
$HOME/.joana/start_joana.sh
EOF

    chmod +x ~/.termux/boot/joana
    log_success "Serviço Termux configurado."
}

# Criar arquivo de configuração
create_config_file() {
    log_info "Criando arquivo de configuração..."
    cat > ~/.joana/config.yaml << 'EOF'
# Configuração da Joana para Android
server:
  port: 28793
  host: "0.0.0.0"

telegram:
  enabled: true
  # Token será configurado manualmente

memory:
  type: "sqlite"
  path: "$HOME/.joana/joana.db"

logging:
  level: "info"
  file: "$HOME/.joana/joana.log"
  max_size_mb: 10
  max_backups: 3

performance:
  max_goroutines: 10
  request_timeout_seconds: 30
EOF

    log_success "Arquivo de configuração criado."
}

# Criar README Android
create_android_readme() {
    log_info "Criando README para Android..."
    cat > ~/joana/README_ANDROID.md << 'EOF'
# Joana para Android (Termux)

## 📱 Instalação Automática

Execute no Termux:
```bash
curl -s https://raw.githubusercontent.com/rmserver03/joana/main/install_android.sh | bash
```

## 📋 Instalação Manual

1. **Instalar Termux** (Play Store)
2. **Abrir Termux** e executar:
```bash
pkg update && pkg upgrade
pkg install golang git
git clone https://github.com/rmserver03/joana.git
cd joana
go build -o joana_android cmd/joana_simple/main.go
```

## 🚀 Uso

### Iniciar Joana:
```bash
cd ~/joana
./joana_android
```

### Scripts de gerenciamento:
```bash
# Iniciar em background
~/.joana/start_joana.sh

# Parar
~/.joana/stop_joana.sh

# Ver logs
tail -f ~/.joana/joana.log
```

## 🔧 Configuração

### Token Telegram:
1. Obter token do BotFather
2. Editar `~/.joana/config.yaml`
3. Adicionar: `token: "SEU_TOKEN_AQUI"`

### Serviço automático (inicialização com Termux):
```bash
# Habilitar serviço
sv-enable joana

# Ver status
sv-status joana
```

## 📊 Recursos Consumidos

| Recurso | Consumo |
|---------|---------|
| RAM | 48-100MB |
| CPU | <5% |
| Armazenamento | ~15MB |
| Bateria | Impacto mínimo |

## 🚨 Solução de Problemas

### Joana não inicia:
```bash
# Verificar logs
cat ~/.joana/joana.log

# Recompilar
cd ~/joana && go build -o joana_android cmd/joana_simple/main.go
```

### Termux suspende o processo:
1. Configurar Termux para não otimizar bateria
2. Usar `termux-wake-lock` para manter ativo
3. Configurar serviço com `termux-services`

### Sem conexão:
```bash
# Verificar internet
ping -c 3 google.com

# Verificar portas
netstat -tuln | grep 28793
```

## 🔗 Links Úteis

- [Repositório GitHub](https://github.com/rmserver03/joana)
- [Documentação Completa](https://github.com/rmserver03/joana/blob/main/README.md)
- [Termux Wiki](https://wiki.termux.com)

## 📞 Suporte

Problemas? Abra uma issue no GitHub ou contate via Telegram.
```

    log_success "README Android criado."
EOF
}

# Testar instalação
test_installation() {
    log_info "Testando instalação..."
    
    # Verificar binário
    if [ -f ~/joana/joana_android ]; then
        log_success "Binário Joana encontrado."
    else
        log_error "Binário Joana não encontrado."
        exit 1
    fi
    
    # Verificar scripts
    if [ -f ~/.joana/start_joana.sh ]; then
        log_success "Script de inicialização encontrado."
    else
        log_error "Script de inicialização não encontrado."
        exit 1
    fi
    
    log_success "Teste de instalação concluído."
}

# Mostrar resumo
show_summary() {
    echo ""
    echo "========================================="
    echo "        INSTALAÇÃO CONCLUÍDA!           "
    echo "========================================="
    echo ""
    echo "📱 Joana instalada com sucesso no Android"
    echo ""
    echo "📂 Diretórios criados:"
    echo "   • ~/joana/           - Código fonte"
    echo "   • ~/.joana/          - Configuração"
    echo "   • ~/.termux/boot/    - Serviço (opcional)"
    echo ""
    echo "🚀 Comandos disponíveis:"
    echo "   • ~/.joana/start_joana.sh  - Iniciar Joana"
    echo "   • ~/.joana/stop_joana.sh   - Parar Joana"
    echo "   • tail -f ~/.joana/joana.log - Ver logs"
    echo ""
    echo "🔧 Próximos passos:"
    echo "   1. Configurar token Telegram em ~/.joana/config.yaml"
    echo "   2. Iniciar: ~/.joana/start_joana.sh"
    echo "   3. Verificar: tail -f ~/.joana/joana.log"
    echo ""
    echo "📚 Documentação: ~/joana/README_ANDROID.md"
    echo ""
    echo "========================================="
}

# Fluxo principal
main() {
    log_info "Iniciando instalação da Joana para Android..."
    echo ""
    
    check_termux
    update_packages
    install_dependencies
    clone_repository
    compile_joana
    create_config_dir
    create_startup_script
    create_termux_service
    create_config_file
    create_android_readme
    test_installation
    show_summary
}

# Executar
main
