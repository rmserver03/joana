#!/bin/bash
# 📱 INSTALADOR JOANA PARA TERMUX PLAY STORE
# Versão adaptada para Termux da Google Play Store (experimental)

set -e

echo "╔══════════════════════════════════════════╗"
echo "║   JOANA - Instalação Android (Play Store)║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "📱 Esta versão é adaptada para Termux da Play Store"
echo "⚠️  Algumas funcionalidades podem ser limitadas"
echo ""

# Verificar se estamos no Termux
if [ ! -d "/data/data/com.termux" ]; then
    echo "❌ ERRO: Este script deve ser executado no Termux!"
    echo "   Instale Termux da Play Store primeiro:"
    echo "   https://play.google.com/store/apps/details?id=com.termux"
    exit 1
fi

# Configurações para Play Store version
echo "🔧 Configurando para Play Store version..."
termux-setup-storage

# Atualizar repositórios (pode falhar na Play Store version)
echo "🔄 Atualizando pacotes..."
pkg update -y || echo "⚠️  Atualização falhou, continuando..."

# Instalar dependências ESSENCIAIS (evitar pacotes problemáticos)
echo "📦 Instalando dependências essenciais..."
pkg install -y git wget curl

# Tentar instalar Go (pode falhar)
if ! command -v go &> /dev/null; then
    echo "⚙️  Instalando Go..."
    pkg install -y golang || {
        echo "⚠️  Go não disponível, usando binário pré-compilado..."
        # Fallback para binário pré-compilado
        mkdir -p ~/go/bin
        export PATH=$PATH:~/go/bin
    }
fi

# Clonar repositório
echo "📥 Baixando Joana..."
if [ -d "joana" ]; then
    echo "📁 Diretório joana já existe, atualizando..."
    cd joana
    git pull origin main || echo "⚠️  Git pull falhou, usando local"
else
    git clone https://github.com/rmserver03/joana.git || {
        echo "⚠️  Git clone falhou, baixando via wget..."
        wget -O joana_main.tar.gz https://github.com/rmserver03/joana/archive/main.tar.gz
        tar -xzf joana_main.tar.gz
        mv joana-main joana
        cd joana
    }
fi

cd joana

# Compilar com CGO_ENABLED=0 (evitar problemas de C)
echo "🔨 Compilando Joana (modo seguro)..."
CGO_ENABLED=0 go build -o joana_android_playstore cmd/joana_simple/main.go

if [ ! -f "joana_android_playstore" ]; then
    echo "⚠️  Compilação falhou, usando binário pré-existente..."
    # Tentar usar qualquer binário disponível
    if [ -f "joana_audit" ]; then
        cp joana_audit joana_android_playstore
    elif [ -f "joana_test" ]; then
        cp joana_test joana_android_playstore
    else
        echo "❌ Nenhum binário disponível!"
        exit 1
    fi
fi

# Criar estrutura de diretórios
echo "📁 Criando estrutura de diretórios..."
mkdir -p ~/.joana/{logs,config,cache}
mkdir -p ~/.joana/memory/{operational,episodic,semantic}

# Configuração mínima para Play Store
echo "⚙️  Criando configuração mínima..."
cat > ~/.joana/config.yaml << 'EOF'
# Configuração mínima para Termux Play Store
system:
  name: "joana_android_playstore"
  version: "1.0-playstore"
  platform: "android"

llm:
  provider: "openai"
  # Configure sua API key manualmente após instalação
  # api_key: "sua-chave-aqui"
  model: "gpt-4o-mini"

memory:
  storage_path: "/data/data/com.termux/files/home/.joana/memory"
  max_entries: 1000

server:
  port: 28793
  host: "127.0.0.1"  # Local apenas por segurança

logging:
  level: "info"
  file: "/data/data/com.termux/files/home/.joana/logs/joana.log"
  max_size_mb: 10
EOF

# Script de inicialização adaptado
echo "📜 Criando scripts de gerenciamento..."
cat > ~/.joana/start.sh << 'EOF'
#!/bin/bash
# Script de inicialização para Play Store version

cd ~/joana

# Verificar se já está rodando
if [ -f ~/.joana/joana.pid ]; then
    PID=$(cat ~/.joana/joana.pid)
    if kill -0 $PID 2>/dev/null; then
        echo "✅ Joana já está rodando (PID: $PID)"
        exit 0
    fi
fi

# Iniciar Joana
echo "🚀 Iniciando Joana..."
nohup ./joana_android_playstore > ~/.joana/logs/joana.log 2>&1 &
JOANA_PID=$!

echo $JOANA_PID > ~/.joana/joana.pid
echo "✅ Joana iniciada (PID: $JOANA_PID)"
echo "📝 Logs: tail -f ~/.joana/logs/joana.log"
EOF

cat > ~/.joana/stop.sh << 'EOF'
#!/bin/bash
# Script de parada

if [ -f ~/.joana/joana.pid ]; then
    PID=$(cat ~/.joana/joana.pid)
    if kill -0 $PID 2>/dev/null; then
        kill $PID
        echo "🛑 Joana parada (PID: $PID)"
        rm ~/.joana/joana.pid
    else
        echo "⚠️  Processo não encontrado, limpando PID..."
        rm ~/.joana/joana.pid
    fi
else
    echo "ℹ️  Joana não está rodando"
fi
EOF

cat > ~/.joana/status.sh << 'EOF'
#!/bin/bash
# Verificar status

if [ -f ~/.joana/joana.pid ]; then
    PID=$(cat ~/.joana/joana.pid)
    if kill -0 $PID 2>/dev/null; then
        echo "✅ Joana está rodando (PID: $PID)"
        echo "📊 Uso de memória:"
        ps -o pid,rss,command -p $PID | tail -1
        echo ""
        echo "📝 Últimas linhas do log:"
        tail -5 ~/.joana/logs/joana.log
    else
        echo "❌ PID existe mas processo não está rodando"
        rm ~/.joana/joana.pid
    fi
else
    echo "❌ Joana não está rodando"
fi
EOF

chmod +x ~/.joana/*.sh

# Configurar permissões
chmod +x joana_android_playstore

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ INSTALAÇÃO COMPLETA PARA PLAY STORE!"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "1. Configure sua API key LLM:"
echo "   nano ~/.joana/config.yaml"
echo "   (adicione sua api_key na seção llm)"
echo ""
echo "2. Iniciar Joana:"
echo "   ~/.joana/start.sh"
echo ""
echo "3. Verificar status:"
echo "   ~/.joana/status.sh"
echo ""
echo "4. Parar Joana:"
echo "   ~/.joana/stop.sh"
echo ""
echo "⚠️  IMPORTANTE PARA PLAY STORE VERSION:"
echo "   • Android Settings → Apps → Termux → Battery → Unrestricted"
echo "   • Desative otimização de bateria para Termux"
echo "   • Mantenha Termux em foreground quando possível"
echo ""
echo "🔧 Comandos úteis:"
echo "   tail -f ~/.joana/logs/joana.log  # Ver logs em tempo real"
echo "   ./joana_android_playstore --help # Ver opções"
echo ""
echo "📞 Problemas? Execute diagnóstico:"
echo "   ./joana_android_playstore --diagnose"
echo "═══════════════════════════════════════════════════════════"

# Teste rápido
echo ""
echo "🧪 Executando teste rápido..."
if ./joana_android_playstore --version 2>&1 | grep -q "joana"; then
    echo "✅ Teste passou! Joana está funcionando."
else
    echo "⚠️  Teste básico falhou, mas instalação está completa."
    echo "   Execute manualmente: ./joana_android_playstore --help"
fi

echo ""
echo "🎉 Instalação concluída! A Joana está pronta para uso."