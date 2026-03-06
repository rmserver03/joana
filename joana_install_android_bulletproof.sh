#!/bin/bash
# JOANA INSTALL - VERSÃO BULLETPROOF (À PROVA DE FALHAS)
# Commit: 5ccd3b6 - EMERGENCY PATCH

set -e  # Para em qualquer erro

# Cores (apenas para visual, não interferem)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções simplificadas e robustas
error() { echo -e "\${RED}✗ \$1\${NC}" >&2; exit 1; }
success() { echo -e "\${GREEN}✓ \$1\${NC}" >&2; }
warning() { echo -e "\${YELLOW}⚠ \$1\${NC}" >&2; }
info() { echo -e "\${BLUE}ℹ \$1\${NC}" >&2; }

# ask() BULLETPROOF - nunca falha
ask() {
    while true; do
        printf "? %s " "\$1" >&2
        read -r input
        # Remove TUDO que não é caractere normal
        clean_input=\$(echo "\$input" | tr -cd '[:print:]' | xargs)
        if [ -n "\$clean_input" ]; then
            echo "\$clean_input"
            return 0
        fi
    done
}

# ask_yesno BULLETPROOF
ask_yesno() {
    while true; do
        printf "? %s (s/n) " "\$1" >&2
        read -r yn
        case "\$yn" in
            [Ss]* ) return 0;;
            [Nn]* ) return 1;;
            * ) ;; # Silenciosamente repete
        esac
    done
}

# --- INÍCIO DA INSTALAÇÃO ---
clear
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                INSTALAÇÃO JOANA - BULLETPROOF                ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# 1. Telegram (SIMPLIFICADO)
info "CONFIGURAÇÃO DO TELEGRAM BOT"
TELEGRAM_TOKEN=\$(ask "Cole seu token do BotFather (ex: 123456:ABCdef): ")
# Aceita QUALQUER token, sem validação
success "Token Telegram recebido"

TELEGRAM_CHAT_ID=\$(ask "Seu ID do Telegram (deixe vazio para auto): ")
[ -n "\$TELEGRAM_CHAT_ID" ] && success "ID Telegram: \$TELEGRAM_CHAT_ID"

# 2. LLM (SIMPLIFICADO)
info "CONFIGURAÇÃO DA API DE INTELIGÊNCIA ARTIFICIAL"
echo "1. DeepSeek (recomendado)"
echo "2. OpenAI"
echo "3. Anthropic"
echo "4. Local"
echo "5. Cloud"
echo "6. Pular"
echo ""

LLM_CHOICE=\$(ask "Opção (1-6, padrão=1): ")
# Fallback automático
LLM_CHOICE=\${LLM_CHOICE:-1}
LLM_CHOICE=\$(echo "\$LLM_CHOICE" | tr -cd '0-9')
[ -z "\$LLM_CHOICE" ] && LLM_CHOICE=1

case "\$LLM_CHOICE" in
    1)
        LLM_PROVIDER="deepseek"
        DEEPSEEK_API_KEY=\$(ask "API Key DeepSeek: ")
        [ -n "\$DEEPSEEK_API_KEY" ] && success "API Key recebida"
        ;;
    2|3|4|5)
        LLM_PROVIDER="\${LLM_CHOICE}"
        warning "Configuração manual necessária após instalação"
        ;;
    *)
        LLM_PROVIDER="deepseek"
        info "Usando DeepSeek como padrão"
        ;;
esac

# 3. Google Sheets (OPCIONAL)
if ask_yesno "Configurar Google Sheets? (Recomendado: NÃO)"; then
    GOOGLE_SHEETS_ID=\$(ask "ID da planilha: ")
    [ -n "\$GOOGLE_SHEETS_ID" ] && success "Planilha configurada"
else
    info "Google Sheets pulado"
fi

# 4. GERAR CONFIG.YAML (SIMPLIFICADO)
CONFIG_DIR="\$HOME/.config/joana"
mkdir -p "\$CONFIG_DIR"

cat > "\$CONFIG_DIR/config.yaml" << YAML
# Configuração Joana - Gerado automaticamente
telegram:
  token: "\${TELEGRAM_TOKEN}"
  chat_id: "\${TELEGRAM_CHAT_ID}"

llm:
  provider: "\${LLM_PROVIDER}"
  api_key: "\${DEEPSEEK_API_KEY}"
  model: "deepseek-chat"

google_sheets:
  enabled: \$( [ -n "\${GOOGLE_SHEETS_ID}" ] && echo "true" || echo "false" )
  spreadsheet_id: "\${GOOGLE_SHEETS_ID}"

logging:
  level: "info"
  file: "\$HOME/.cache/joana/joana.log"
YAML

success "✅ Configuração gerada em \$CONFIG_DIR/config.yaml"

# 5. INSTALAÇÃO DE DEPENDÊNCIAS
info "Instalando dependências..."
pkg update -y && pkg upgrade -y
pkg install -y python nodejs git curl wget

# 6. CLONAR/ATUALIZAR REPOSITÓRIO
INSTALL_DIR="\$HOME/joana"
if [ -d "\$INSTALL_DIR" ]; then
    cd "\$INSTALL_DIR" && git pull
else
    git clone https://github.com/rmserver03/joana.git "\$INSTALL_DIR"
fi

# 7. CONFIGURAR SERVIÇO
cat > "\$HOME/start_joana.sh" << 'SERVICE'
#!/bin/bash
cd "\$HOME/joana"
python3 -m pip install -r requirements.txt
python3 joana.py
SERVICE
chmod +x "\$HOME/start_joana.sh"

# 8. CONCLUSÃO
success "🎉 INSTALAÇÃO COMPLETA BULLETPROOF!"
echo ""
echo "Próximos passos:"
echo "1. Iniciar Joana: bash \$HOME/start_joana.sh"
echo "2. Envie '/start' para seu bot no Telegram"
echo "3. Aproveite!"
echo ""
echo "Config salva em: \$CONFIG_DIR/config.yaml"
echo "Logs em: \$HOME/.cache/joana/joana.log"

