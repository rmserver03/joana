#!/bin/bash
# INSTALAÇÃO SUPER SIMPLES PARA TERMUX
# Um comando só: curl ... | bash

echo "📱 INSTALAÇÃO JOANA PARA TERMUX"
echo "================================"

# Atualizar pacotes
echo "[1/7] Atualizando pacotes..."
pkg update -y
pkg upgrade -y

# Instalar dependências básicas
echo "[2/7] Instalando dependências..."
pkg install -y git wget curl golang python nodejs-lts sqlite openssl nano

# Configurar Go
echo "[3/7] Configurando Go..."
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"
mkdir -p "$GOPATH"

# Baixar projeto
echo "[4/7] Baixando Joana..."
if [ -d "joana" ]; then
    cd joana
    git pull origin main
else
    git clone https://github.com/rmserver03/joana.git
    cd joana
fi

# Compilar versão Android
echo "[5/7] Compilando para Android..."
CGO_ENABLED=0 go build -o joana_android cmd/joana_simple/main.go
chmod +x joana_android

# Configuração mínima
echo "[6/7] Criando configuração..."
mkdir -p ~/.joana

cat > ~/.joana/.env << 'EOF'
# JOANA - CONFIGURAÇÃO MÍNIMA
# Edite com sua chave da DeepSeek

LLM_PROVIDER=deepseek
DEEPSEEK_API_KEY=sua_chave_aqui

# Telegram (opcional)
TELEGRAM_BOT_TOKEN=seu_token_aqui
TELEGRAM_ADMIN_ID=974346958

# Sistema
TZ=America/Sao_Paulo
LOG_LEVEL=info
EOF

# Script de inicialização
echo "[7/7] Criando script de inicialização..."
cat > start_joana.sh << 'EOF'
#!/bin/bash
cd ~/joana

# Verificar API key
if grep -q "sua_chave_aqui" ~/.joana/.env; then
    echo "⚠️  CONFIGURE SUA API KEY PRIMEIRO!"
    echo "Edite: nano ~/.joana/.env"
    echo "Substitua 'sua_chave_aqui' pela sua chave da DeepSeek"
    exit 1
fi

# Carregar configuração
export $(grep -v '^#' ~/.joana/.env | xargs)

echo "🚀 Iniciando Joana..."
./joana_android
EOF

chmod +x start_joana.sh

# Instruções finais
echo ""
echo "✅ INSTALAÇÃO CONCLUÍDA!"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "1. Configure sua API key:"
echo "   nano ~/.joana/.env"
echo "   (substitua 'sua_chave_aqui' pela sua chave da DeepSeek)"
echo ""
echo "2. Inicie o sistema:"
echo "   ./start_joana.sh"
echo ""
echo "3. Para parar: Ctrl+C"
echo ""
echo "4. Para ver status:"
echo "   ps aux | grep joana"
echo ""
echo "💡 DICA: Se quiser Telegram, configure o token no mesmo arquivo .env"
echo "   Token do bot: converse com @BotFather"
echo "   Admin ID: 974346958"
echo ""
echo "🔄 Para atualizar:"
echo "   cd ~/joana && git pull && ./install_termux_super_simple.sh"