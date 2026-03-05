#!/bin/bash
# install_android_simple.sh - Instalação simplificada da Joana para Android
# URL: https://raw.githubusercontent.com/rmserver03/joana/main/install_android_simple.sh

echo "📱 Instalando Joana para Android..."
echo "======================================"

# Verificar Termux
if [ ! -d "/data/data/com.termux" ]; then
    echo "❌ ERRO: Este script requer Termux no Android."
    echo "📥 Instale Termux da Play Store primeiro."
    exit 1
fi

echo "✅ Termux detectado"

# Atualizar pacotes
echo "🔄 Atualizando pacotes..."
pkg update -y && pkg upgrade -y

# Instalar dependências
echo "📦 Instalando dependências..."
pkg install -y golang git

# Clonar repositório
echo "📥 Clonando repositório..."
if [ -d "joana" ]; then
    echo "📁 Diretório já existe, atualizando..."
    cd joana && git pull && cd ..
else
    git clone https://github.com/rmserver03/joana.git
fi

# Compilar
echo "🔨 Compilando Joana..."
cd joana
go build -o joana_android cmd/joana_simple/main.go

# Criar diretório de configuração
echo "⚙️ Criando configuração..."
mkdir -p ~/.joana

# Script de inicialização
echo "📝 Criando scripts..."
cat > ~/.joana/start.sh << 'EOF'
#!/bin/bash
cd ~/joana
nohup ./joana_android > ~/.joana/joana.log 2>&1 &
echo $! > ~/.joana/joana.pid
echo "✅ Joana iniciada (PID: $(cat ~/.joana/joana.pid))"
echo "📋 Logs: tail -f ~/.joana/joana.log"
EOF

cat > ~/.joana/stop.sh << 'EOF'
#!/bin/bash
if [ -f ~/.joana/joana.pid ]; then
    kill $(cat ~/.joana/joana.pid) 2>/dev/null
    rm ~/.joana/joana.pid
    echo "✅ Joana parada"
else
    echo "ℹ️ Joana não está rodando"
fi
EOF

chmod +x ~/.joana/start.sh ~/.joana/stop.sh

# Configuração básica
cat > ~/.joana/config.yaml << 'EOF'
# Configuração da Joana para Android
server:
  port: 28793
  host: "0.0.0.0"

telegram:
  enabled: true
  # Adicione seu token aqui: token: "SEU_TOKEN"

logging:
  level: "info"
  file: "$HOME/.joana/joana.log"
EOF

echo ""
echo "======================================"
echo "✅ INSTALAÇÃO CONCLUÍDA!"
echo ""
echo "📂 Diretórios:"
echo "   ~/joana/          - Código fonte"
echo "   ~/.joana/         - Configuração"
echo ""
echo "🚀 Comandos:"
echo "   ~/.joana/start.sh   - Iniciar Joana"
echo "   ~/.joana/stop.sh    - Parar Joana"
echo "   tail -f ~/.joana/joana.log - Ver logs"
echo ""
echo "🔧 Próximos passos:"
echo "   1. Obter token do @BotFather no Telegram"
echo "   2. Editar ~/.joana/config.yaml"
echo "   3. Adicionar: token: \"SEU_TOKEN\""
echo "   4. Executar: ~/.joana/start.sh"
echo ""
echo "📚 Documentação: https://github.com/rmserver03/joana"
echo "======================================"